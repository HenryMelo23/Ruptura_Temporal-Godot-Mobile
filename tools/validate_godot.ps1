[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [int]$SmokeFrames = 300,
    [string]$Scene = "",
    [string[]]$Scripts = @(),
    [switch]$ChangedOnly,
    [switch]$Deep,
    [switch]$SkipSmoke,
    [switch]$VerboseOutput,
    [int]$LogTailLines = 80
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

    $cmdLine = "`"$Godot`" " + (($Arguments | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join ' ') + " > `"$logPath`" 2>&1"
    $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$cmdLine`"" -NoNewWindow -PassThru -Wait
    $exitCode = $proc.ExitCode
    $output = @()
    if (Test-Path -LiteralPath $logPath) {
        $output = Get-Content -LiteralPath $logPath -Encoding UTF8
        if ($VerboseOutput -or $Name -eq "00_godot_version") {
            $output | ForEach-Object { Write-Host $_ }
        }
    }

    if ($exitCode -ne 0) {
        $output | Select-Object -Last $LogTailLines | ForEach-Object { Write-Host $_ }
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
        $output | Select-Object -Last $LogTailLines | ForEach-Object { Write-Host $_ }
        throw "$Name did not emit the required success marker '$RequiredPattern'. Log: $logPath"
    }

    if ($RequiredPattern) {
        $marker = $output | Select-String -Pattern $RequiredPattern | Select-Object -First 1
        if ($marker) {
            Write-Host $marker.Line
        }
    } elseif (-not $VerboseOutput -and $Name -ne "00_godot_version") {
        Write-Host "    OK (log: $logPath)"
    }
}

function Test-GodotIgnoredPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $directory = Split-Path -Parent $Path
    while ($directory -and $directory.StartsWith($ProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        if (Test-Path -LiteralPath (Join-Path $directory ".gdignore")) {
            return $true
        }
        if ($directory -eq $ProjectRoot) {
            break
        }
        $parent = Split-Path -Parent $directory
        if ($parent -eq $directory) {
            break
        }
        $directory = $parent
    }
    return $false
}

function Convert-ToGodotResourcePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ($Path.StartsWith("res://")) {
        return $Path.Replace('\', '/')
    }

    $fullPath = $Path
    if (-not [System.IO.Path]::IsPathRooted($fullPath)) {
        $fullPath = Join-Path $ProjectRoot $fullPath
    }

    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        return $null
    }

    $resolvedPath = (Resolve-Path -LiteralPath $fullPath).Path
    if (-not $resolvedPath.StartsWith($ProjectRoot)) {
        return $null
    }

    $relative = $resolvedPath.Substring($ProjectRoot.Length).TrimStart(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    return "res://$($relative.Replace('\', '/'))"
}

function Get-ChangedGDScripts {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        Write-Warning "git was not found; -ChangedOnly cannot discover changed scripts."
        return @()
    }

    Push-Location $ProjectRoot
    try {
        $tracked = @(& git -c core.autocrlf=false diff --name-only --diff-filter=ACMRTUXB HEAD -- "*.gd" 2>$null)
        $untracked = @(& git -c core.autocrlf=false ls-files --others --exclude-standard -- "*.gd" 2>$null)
        return @($tracked + $untracked | Where-Object { $_ } | Sort-Object -Unique)
    } finally {
        Pop-Location
    }
}

function Get-ValidationScriptList {
    $scriptMap = [ordered]@{}
    $requestedScripts = @(
        foreach ($scriptValue in @($Scripts)) {
            foreach ($scriptPath in ([string]$scriptValue -split ',')) {
                $normalizedPath = $scriptPath.Trim()
                if ($normalizedPath) {
                    $normalizedPath
                }
            }
        }
    )

    if ($ChangedOnly) {
        foreach ($changedPath in Get-ChangedGDScripts) {
            $resourcePath = Convert-ToGodotResourcePath -Path $changedPath
            if ($resourcePath) {
                $scriptMap[$resourcePath] = $true
            }
        }
    }

    foreach ($scriptPath in $requestedScripts) {
        $resourcePath = Convert-ToGodotResourcePath -Path $scriptPath
        if ($resourcePath) {
            $scriptMap[$resourcePath] = $true
        }
    }

    if ($Deep -and -not $ChangedOnly -and $requestedScripts.Count -eq 0) {
        $allScripts = @(Get-ChildItem -LiteralPath $ProjectRoot -Filter "*.gd" -File -Recurse |
            Where-Object {
                $_.FullName -notmatch '[\\/]\.godot[\\/]' -and
                $_.FullName -notmatch '[\\/]\.git[\\/]' -and
                $_.FullName -notmatch '[\\/]\.agent_logs[\\/]' -and
                $_.FullName -notmatch '[\\/]\.codex[\\/]' -and
                $_.FullName -notmatch '[\\/]android[\\/]' -and
                $_.FullName -notmatch '[\\/]builds[\\/]' -and
                -not (Test-GodotIgnoredPath -Path $_.FullName)
            } |
            Sort-Object FullName)

        foreach ($script in $allScripts) {
            $resourcePath = Convert-ToGodotResourcePath -Path $script.FullName
            if ($resourcePath) {
                $scriptMap[$resourcePath] = $true
            }
        }
    }

    return @($scriptMap.Keys)
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

$scriptsToParse = @(Get-ValidationScriptList)
if ($scriptsToParse.Count -gt 0) {
    Write-Host ("`n==> 03_parse_scripts count={0} changedOnly={1} deep={2}" -f $scriptsToParse.Count, [bool]$ChangedOnly, [bool]$Deep)
    $index = 0
    foreach ($resourcePath in $scriptsToParse) {
        $index++
        $relative = $resourcePath.Substring("res://".Length)
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
