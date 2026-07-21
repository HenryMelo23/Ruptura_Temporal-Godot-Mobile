[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logDir = Join-Path $projectRoot '.agent_logs\lobby_integration'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

if (-not $GodotBin) {
    throw 'Informe -GodotBin ou defina GODOT_BIN.'
}
if (-not (Test-Path -LiteralPath $GodotBin -PathType Leaf)) {
    throw "Godot nao encontrado: $GodotBin"
}

function Remove-ScenarioArtifacts {
    param([string]$Scenario)

    foreach ($role in @('server', 'host', 'client')) {
        Remove-Item -LiteralPath (Join-Path $projectRoot "tests\lobby_${Scenario}_${role}_result.txt") -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $logDir "${Scenario}_${role}.out.log") -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $logDir "${Scenario}_${role}.err.log") -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-LobbyScenario {
    param(
        [Parameter(Mandatory = $true)][string]$Scenario,
        [Parameter(Mandatory = $true)][int]$Port
    )

    Remove-ScenarioArtifacts -Scenario $Scenario
    $processes = @()
    try {
        foreach ($role in @('server', 'host', 'client')) {
            $stdout = Join-Path $logDir "${Scenario}_${role}.out.log"
            $stderr = Join-Path $logDir "${Scenario}_${role}.err.log"
            $arguments = @(
                '--headless',
                '--path', ('"{0}"' -f $projectRoot),
                '--script', 'res://tests/multiplayer_lobby_integration_smoke.gd',
                '--',
                "--role=$role",
                "--scenario=$Scenario",
                "--port=$Port"
            )
            $process = Start-Process -FilePath $GodotBin -ArgumentList $arguments -RedirectStandardOutput $stdout -RedirectStandardError $stderr -WindowStyle Hidden -PassThru
            $processes += $process
            if ($role -eq 'server') {
                Start-Sleep -Milliseconds 1200
            }
        }

        $deadline = [DateTime]::UtcNow.AddSeconds(45)
        do {
            $complete = $true
            foreach ($role in @('server', 'host', 'client')) {
                if (-not (Test-Path -LiteralPath (Join-Path $projectRoot "tests\lobby_${Scenario}_${role}_result.txt"))) {
                    $complete = $false
                }
            }
            if ($complete) {
                break
            }
            Start-Sleep -Milliseconds 250
        } while ([DateTime]::UtcNow -lt $deadline)

        foreach ($role in @('server', 'host', 'client')) {
            $resultPath = Join-Path $projectRoot "tests\lobby_${Scenario}_${role}_result.txt"
            if (-not (Test-Path -LiteralPath $resultPath)) {
                $stdout = Get-Content -LiteralPath (Join-Path $logDir "${Scenario}_${role}.out.log") -Raw -ErrorAction SilentlyContinue
                $stderr = Get-Content -LiteralPath (Join-Path $logDir "${Scenario}_${role}.err.log") -Raw -ErrorAction SilentlyContinue
                throw "Cenario $Scenario sem resultado de $role.`nSTDOUT:`n$stdout`nSTDERR:`n$stderr"
            }
            Write-Host (Get-Content -LiteralPath $resultPath -Raw)
        }
        Write-Host "LOBBY_SCENARIO_OK $Scenario"
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

function Invoke-ThreePlayerFlow {
    $roles = @('server', 'host', 'client', 'client2')
    foreach ($role in $roles) {
        Remove-Item -LiteralPath (Join-Path $projectRoot "tests\${role}_result.txt") -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $logDir "flow_${role}.out.log") -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $logDir "flow_${role}.err.log") -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath (Join-Path $projectRoot 'tests\integration_error.txt') -Force -ErrorAction SilentlyContinue

    $processes = @()
    try {
        foreach ($role in $roles) {
            $stdout = Join-Path $logDir "flow_${role}.out.log"
            $stderr = Join-Path $logDir "flow_${role}.err.log"
            $arguments = @(
                '--headless',
                '--path', ('"{0}"' -f $projectRoot),
                '--script', 'res://tests/multiplayer_integration_smoke.gd',
                '--',
                "--role=$role",
                '--port=4593'
            )
            $process = Start-Process -FilePath $GodotBin -ArgumentList $arguments -RedirectStandardOutput $stdout -RedirectStandardError $stderr -WindowStyle Hidden -PassThru
            $processes += $process
            if ($role -eq 'server') {
                Start-Sleep -Milliseconds 1200
            }
        }

        $deadline = [DateTime]::UtcNow.AddSeconds(70)
        do {
            $complete = $true
            foreach ($role in $roles) {
                if (-not (Test-Path -LiteralPath (Join-Path $projectRoot "tests\${role}_result.txt"))) {
                    $complete = $false
                }
            }
            if ($complete) {
                break
            }
            if (Test-Path -LiteralPath (Join-Path $projectRoot 'tests\integration_error.txt')) {
                throw (Get-Content -LiteralPath (Join-Path $projectRoot 'tests\integration_error.txt') -Raw)
            }
            Start-Sleep -Milliseconds 250
        } while ([DateTime]::UtcNow -lt $deadline)

        foreach ($role in $roles) {
            $resultPath = Join-Path $projectRoot "tests\${role}_result.txt"
            if (-not (Test-Path -LiteralPath $resultPath)) {
                $stdout = Get-Content -LiteralPath (Join-Path $logDir "flow_${role}.out.log") -Raw -ErrorAction SilentlyContinue
                $stderr = Get-Content -LiteralPath (Join-Path $logDir "flow_${role}.err.log") -Raw -ErrorAction SilentlyContinue
                throw "Fluxo de tres jogadores sem resultado de $role.`nSTDOUT:`n$stdout`nSTDERR:`n$stderr"
            }
        }
        Write-Host 'MULTIPLAYER_THREE_PLAYER_FLOW_OK lobby=true manifest=true spectrum=true game=true'
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

Invoke-LobbyScenario -Scenario 'ready' -Port 4591
Invoke-LobbyScenario -Scenario 'spectator' -Port 4592
Invoke-ThreePlayerFlow

$errorPattern = '(?i)SCRIPT ERROR:|ERROR:|Parse Error:|RPC configuration mismatch|Invalid packet|MULTIPLAYER_LOBBY_INTEGRATION_FAIL'
$errors = Get-ChildItem -LiteralPath $logDir -Filter '*.log' -File |
    Select-String -Pattern $errorPattern
if ($errors) {
    throw "A bateria encontrou erros nos logs:`n$($errors.Line -join [Environment]::NewLine)"
}

Write-Host 'MULTIPLAYER_LOBBY_BATTERY_OK ready=true spectator=true'
