[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$ManagerUrl = 'http://72.61.217.238:8090'
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logDir = Join-Path $projectRoot '.agent_logs\public_relay'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

if (-not $GodotBin -or -not (Test-Path -LiteralPath $GodotBin -PathType Leaf)) {
    throw 'Informe um executavel Godot valido em -GodotBin ou GODOT_BIN.'
}

function Invoke-PublicLobbyScenario {
    param([string]$Scenario)

    foreach ($role in @('host', 'client')) {
        Remove-Item -LiteralPath (Join-Path $projectRoot "tests\lobby_${Scenario}_${role}_result.txt") -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $logDir "${Scenario}_${role}.out.log") -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $logDir "${Scenario}_${role}.err.log") -Force -ErrorAction SilentlyContinue
    }

    $room = Invoke-RestMethod -Method Post -Uri "$ManagerUrl/rooms" -ContentType 'application/json' `
        -Body ('{"name":"PublicSmoke-' + $Scenario + '"}') -TimeoutSec 20
    $roomCode = [string]$room.code
    $relayHost = [string]$room.host
    $relayPort = [int]$room.port
    $processes = @()

    try {
        foreach ($role in @('host', 'client')) {
            if ($role -eq 'client') {
                Invoke-RestMethod -Method Post -Uri "$ManagerUrl/rooms/$roomCode/join" `
                    -ContentType 'application/json' -Body '{}' -TimeoutSec 10 | Out-Null
            }
            $stdout = Join-Path $logDir "${Scenario}_${role}.out.log"
            $stderr = Join-Path $logDir "${Scenario}_${role}.err.log"
            $arguments = @(
                '--headless',
                '--path', ('"{0}"' -f $projectRoot),
                '--script', 'res://tests/multiplayer_lobby_integration_smoke.gd',
                '--',
                "--role=$role",
                "--scenario=$Scenario",
                "--host=$relayHost",
                "--port=$relayPort",
                '--external-server'
            )
            $processes += Start-Process -FilePath $GodotBin -ArgumentList $arguments `
                -RedirectStandardOutput $stdout -RedirectStandardError $stderr `
                -WindowStyle Hidden -PassThru
            Start-Sleep -Milliseconds 650
        }

        $deadline = [DateTime]::UtcNow.AddSeconds(45)
        $complete = $false
        do {
            $complete = $true
            foreach ($role in @('host', 'client')) {
                if (-not (Test-Path -LiteralPath (Join-Path $projectRoot "tests\lobby_${Scenario}_${role}_result.txt"))) {
                    $complete = $false
                }
            }
            if ($complete) {
                break
            }
            Start-Sleep -Milliseconds 250
        } while ([DateTime]::UtcNow -lt $deadline)

        if (-not $complete) {
            $logs = Get-ChildItem -LiteralPath $logDir -Filter "$Scenario*.log" -File |
                ForEach-Object { "--- $($_.Name) ---`n$(Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue)" }
            throw "Relay publico nao concluiu $Scenario.`n$($logs -join [Environment]::NewLine)"
        }

        $errorPattern = '(?i)SCRIPT ERROR:|ERROR:|Parse Error:|RPC configuration mismatch|Invalid packet|Unable to send packet'
        $errors = Get-ChildItem -LiteralPath $logDir -Filter "$Scenario*.log" -File |
            Select-String -Pattern $errorPattern
        if ($errors) {
            throw "Relay publico encontrou erros em $Scenario`: $($errors.Line -join '; ')"
        }
        Write-Host "PUBLIC_RELAY_SCENARIO_OK scenario=$Scenario room=$roomCode host=$relayHost port=$relayPort"
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
        try {
            Invoke-RestMethod -Method Delete -Uri "$ManagerUrl/rooms/$roomCode" -TimeoutSec 10 | Out-Null
        } catch {
        }
    }
}

$health = Invoke-RestMethod -Uri "$ManagerUrl/health" -TimeoutSec 10
if (-not $health.ok) {
    throw 'Relay publico nao esta saudavel antes do teste.'
}

Invoke-PublicLobbyScenario -Scenario 'ready'
Invoke-PublicLobbyScenario -Scenario 'spectator'

$health = Invoke-RestMethod -Uri "$ManagerUrl/health" -TimeoutSec 10
if (-not $health.ok) {
    throw 'Relay publico nao esta saudavel depois do teste.'
}
Write-Host "PUBLIC_RELAY_BATTERY_OK ready=true spectator=true standby=$($health.standby)"
