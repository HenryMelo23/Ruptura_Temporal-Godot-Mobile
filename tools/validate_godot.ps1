[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [int]$SmokeFrames = 300,
    [string]$Scene = "",
    [switch]$Deep,
    [switch]$SkipSmoke
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ProjectFile = Join-Path $ProjectRoot "project.godot"
$LogsDir = Join-Path $ProjectRoot ".agent_logs"

if (-not (Test-Path -LiteralPath $ProjectFile)) {
    throw "project.godot was not found at: $ProjectFile"
}

New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null

function Resolve-GodotBinary {
    param([string]$RequestedBinary)

    if ($RequestedBinary) {
        if (Test-Path -LiteralPath $RequestedBinary) {
            return (Resolve-Path -LiteralPath $RequestedBinary).Path
        }

        $requestedCommand = Get-Command $RequestedBinary -ErrorAction SilentlyContinue
        if ($requestedCommand) {
            return $requestedCommand.Source
        }

        throw "GODOT_BIN/GodotBin does not point to an executable: $RequestedBinary"
    }

    foreach ($candidate in @("godot", "godot4", "godot-mono")) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    throw "Godot was not found. Add it to PATH or set GODOT_BIN to the Godot editor executable."
}

$Godot = Resolve-GodotBinary -RequestedBinary $GodotBin

$ErrorPatterns = @(
    '(?i)\bSCRIPT ERROR:',
    '(?i)(^|\s)ERROR:',
    '(?i)\bParse Error:',
    '(?i)^E\s+\d+:\d+:\d+(?:\.\d+)?:',
    '(?i)Failed loading resource',
    '(?i)Failed to load script',
    '(?i)Cannot open file',
    '(?i)Invalid call\.',
    '(?i)Invalid access to (?:property|index)',
    '(?i)Node not found:',
    '(?i)Assertion failed',
    '(?i)Segmentation fault',
    '(?i)CrashHandlerException'
)

function Invoke-LoggedStep {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowErrorText,
        [string]$RequiredPattern = ""
    )

    $safeName = $Name -replace '[^A-Za-z0-9_.-]', '_'
    $logPath = Join-Path $LogsDir ("{0}.log" -f $safeName)

    Write-Host "`n==> $Name"
    Write-Host ("    {0} {1}" -f $Godot, ($Arguments -join ' '))

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = @(& $Godot @Arguments 2>&1 | ForEach-Object { $_.ToString() })
    $ErrorActionPreference = $oldPreference
    $exitCode = $LASTEXITCODE
    $output | Set-Content -LiteralPath $logPath -Encoding UTF8
    $output | ForEach-Object { Write-Host $_ }

    if ($exitCode -ne 0) {
        throw "$Name failed with exit code $exitCode. Log: $logPath"
    }

    if (-not $AllowErrorText) {
        $matches = @($output | Select-String -Pattern $ErrorPatterns | Where-Object { $_.Line -notmatch 'resources still in use at exit' })
        if ($matches.Count -gt 0) {
            $summary = ($matches | Select-Object -First 12 | ForEach-Object { $_.Line }) -join "`n"
            throw "$Name emitted Godot error text.`n$summary`nLog: $logPath"
        }
    }

    if ($RequiredPattern -and -not ($output | Select-String -Pattern $RequiredPattern -Quiet)) {
        throw "$Name did not emit the required success marker '$RequiredPattern'. Log: $logPath"
    }
}

Invoke-LoggedStep -Name "00_godot_version" -Arguments @("--version") -AllowErrorText
Invoke-LoggedStep -Name "01_project_import" -Arguments @(
    "--headless", "--path", $ProjectRoot, "--import", "--verbose"
)

$HasCSharp = (Test-Path -LiteralPath (Join-Path $ProjectRoot "*.csproj")) -or
    (@(Get-ChildItem -LiteralPath $ProjectRoot -Filter "*.csproj" -File -ErrorAction SilentlyContinue).Count -gt 0) -or
    (@(Get-ChildItem -LiteralPath $ProjectRoot -Filter "*.cs" -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/]\.godot[\\/]' }).Count -gt 0)

if ($HasCSharp) {
    Invoke-LoggedStep -Name "02_build_csharp" -Arguments @(
        "--headless", "--path", $ProjectRoot, "--build-solutions", "--quit", "--verbose"
    )
}

if ($Deep) {
    $scripts = @(Get-ChildItem -LiteralPath $ProjectRoot -Filter "*.gd" -File -Recurse |
        Where-Object {
            $_.FullName -notmatch '[\\/]\.godot[\\/]' -and
            $_.FullName -notmatch '[\\/]\.git[\\/]' -and
            $_.FullName -notmatch '[\\/]android[\\/]' -and
            $_.FullName -notmatch '[\\/]builds[\\/]'
        } |
        Sort-Object FullName)

    $index = 0
    foreach ($script in $scripts) {
        $index++
        $relative = $script.FullName
        if ($relative.StartsWith($ProjectRoot)) {
            $relative = $relative.Substring($ProjectRoot.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
        }
        $relative = $relative.Replace('\', '/')
        $resourcePath = "res://$relative"
        $stepName = "03_parse_{0:D4}_{1}" -f $index, ($relative -replace '[^A-Za-z0-9_.-]', '_')
        Invoke-LoggedStep -Name $stepName -Arguments @(
            "--headless", "--path", $ProjectRoot, "--script", $resourcePath, "--check-only"
        )
    }
}

if (-not $SkipSmoke) {
    $userArguments = @("--frames=$SmokeFrames")
    if ($Scene) {
        $userArguments += "--scene=$Scene"
    }

    Invoke-LoggedStep -Name "04_smoke_test" -Arguments (@(
        "--headless", "--path", $ProjectRoot, "--debug",
        "--script", "res://tools/agent_smoke_test.gd", "--"
    ) + $userArguments) -RequiredPattern "AGENT_SMOKE_TEST_OK"
}

Write-Host "`nGODOT VALIDATION PASSED"
Write-Host "Project: $ProjectRoot"
Write-Host "Logs:    $LogsDir"
