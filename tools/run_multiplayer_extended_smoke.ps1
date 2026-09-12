[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logDir = Join-Path $projectRoot '.agent_logs\multiplayer_extended'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

if (-not $GodotBin -or -not (Test-Path -LiteralPath $GodotBin -PathType Leaf)) {
    throw 'Informe um executavel Godot valido em -GodotBin ou GODOT_BIN.'
}

function Invoke-MultiplayerCase {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Script,
        [Parameter(Mandatory = $true)][int]$Port,
        [Parameter(Mandatory = $true)][string]$ResultPrefix,
        [Parameter(Mandatory = $true)][string[]]$RequiredResults,
        [Parameter(Mandatory = $true)][string]$ErrorFile,
        [string]$ServerMarker = ''
    )

    Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tests') -Filter "$ResultPrefix*.txt" -File -ErrorAction SilentlyContinue |
        Remove-Item -Force
    Get-ChildItem -LiteralPath $logDir -Filter "$Name*.log" -File -ErrorAction SilentlyContinue |
        Remove-Item -Force

    $processes = @()
    try {
        foreach ($role in @('server', 'host', 'client')) {
            $stdout = Join-Path $logDir "${Name}_${role}.out.log"
            $stderr = Join-Path $logDir "${Name}_${role}.err.log"
            $arguments = @(
                '--headless',
                '--path', ('"{0}"' -f $projectRoot),
                '--script', "res://tests/$Script",
                '--',
                "--role=$role",
                "--port=$Port"
            )
            $startArgs = @{
                FilePath = $GodotBin
                ArgumentList = $arguments
                RedirectStandardOutput = $stdout
                RedirectStandardError = $stderr
                PassThru = $true
            }
            if ($IsWindows) {
                $startArgs.WindowStyle = 'Hidden'
            }
            $processes += Start-Process @startArgs
            if ($role -eq 'server') {
                Start-Sleep -Milliseconds 1200
            }
        }

        $deadline = [DateTime]::UtcNow.AddSeconds(55)
        $complete = $false
        do {
            $errorPath = Join-Path $projectRoot "tests\$ErrorFile"
            if (Test-Path -LiteralPath $errorPath) {
                throw (Get-Content -LiteralPath $errorPath -Raw)
            }
            $complete = $true
            foreach ($suffix in $RequiredResults) {
                $resultPath = Join-Path $projectRoot "tests\${ResultPrefix}${suffix}.txt"
                if (-not (Test-Path -LiteralPath $resultPath)) {
                    $complete = $false
                }
            }
            if ($ServerMarker) {
                $serverLog = Get-Content -LiteralPath (Join-Path $logDir "${Name}_server.out.log") -Raw -ErrorAction SilentlyContinue
                if ($serverLog -notmatch [regex]::Escape($ServerMarker)) {
                    $complete = $false
                }
            }
            if ($complete) {
                break
            }
            Start-Sleep -Milliseconds 250
        } while ([DateTime]::UtcNow -lt $deadline)

        if (-not $complete) {
            $logs = Get-ChildItem -LiteralPath $logDir -Filter "$Name*.log" -File |
                ForEach-Object { "--- $($_.Name) ---`n$(Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue)" }
            throw "$Name nao concluiu.`n$($logs -join [Environment]::NewLine)"
        }

        $errorPattern = '(?i)SCRIPT ERROR:|ERROR:|Parse Error:|RPC configuration mismatch|Invalid packet|Unable to send packet'
        $errors = Get-ChildItem -LiteralPath $logDir -Filter "$Name*.log" -File |
            Select-String -Pattern $errorPattern
        if ($errors) {
            throw "$Name encontrou erros:`n$($errors.Line -join [Environment]::NewLine)"
        }
        Write-Host "MULTIPLAYER_${Name}_OK"
    } finally {
        foreach ($process in $processes) {
            try {
                $process.Refresh()
                if (-not $process.HasExited) {
                    Stop-Process -Id $process.Id -Force
                }
            } catch {
            }
        }
    }
}

Invoke-MultiplayerCase -Name 'GAMEPLAY_AUTHORITY' `
    -Script 'multiplayer_gameplay_authority_smoke.gd' -Port 4611 `
    -ResultPrefix 'gameplay_authority_' -RequiredResults @('host_result', 'client_result') `
    -ErrorFile 'gameplay_authority_error.txt' -ServerMarker '[SERVER] GAMEPLAY_AUTHORITY_OK'

Invoke-MultiplayerCase -Name 'ABILITY_VISUAL' `
    -Script 'multiplayer_ability_visual_smoke.gd' -Port 4612 `
    -ResultPrefix 'ability_visual_' -RequiredResults @('server_result', 'host_result', 'client_result') `
    -ErrorFile 'ability_visual_error.txt'

Invoke-MultiplayerCase -Name 'ROOM_LIFECYCLE' `
    -Script 'multiplayer_room_lifecycle_smoke.gd' -Port 4613 `
    -ResultPrefix 'room_lifecycle_' -RequiredResults @('server_result', 'host_result', 'client_result') `
    -ErrorFile 'room_lifecycle_error.txt'

Write-Host 'MULTIPLAYER_EXTENDED_BATTERY_OK authority=true visuals=true lifecycle=true'
