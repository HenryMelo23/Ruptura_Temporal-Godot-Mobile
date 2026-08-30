[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [string]$ManagerUrl = 'http://72.61.217.238:8090',
    [int]$PingBudgetMs = 50,
    [switch]$SkipRelayVersionCheck
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logDir = Join-Path $projectRoot '.agent_logs\public_gameplay'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

if (-not $GodotBin -or -not (Test-Path -LiteralPath $GodotBin -PathType Leaf)) {
    throw 'Informe um executavel Godot valido em -GodotBin ou GODOT_BIN.'
}

function Assert-RelayProjectMatches {
    param($Health)
    if ($SkipRelayVersionCheck) {
        return
    }
    $localHash = (Get-FileHash -LiteralPath (Join-Path $projectRoot 'scripts\main.gd') -Algorithm SHA256).Hash.ToLowerInvariant()
    $remoteHash = ''
    if ($Health.PSObject.Properties.Name -contains 'project' -and $Health.project) {
        $remoteHash = [string]$Health.project.mainGdSha256
    }
    if (-not $remoteHash) {
        throw 'Relay publico nao informa hash do projeto. Publique server/relay_manager.js e o projeto no VPS antes do gameplay smoke publico.'
    }
    if ($remoteHash -ne $localHash) {
        throw "Relay publico esta com scripts/main.gd diferente. local=$localHash remoto=$remoteHash. Rode tools/publish_relay_project.ps1 antes do gameplay smoke publico."
    }
}

Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tests') -Filter 'gameplay_authority_*result.txt' -File -ErrorAction SilentlyContinue |
    Remove-Item -Force
Remove-Item -LiteralPath (Join-Path $projectRoot 'tests\gameplay_authority_error.txt') -Force -ErrorAction SilentlyContinue
Get-ChildItem -LiteralPath $logDir -Filter '*.log' -File -ErrorAction SilentlyContinue |
    Remove-Item -Force

$roomCode = ''
$processes = @()
try {
    $health = Invoke-RestMethod -Uri "$ManagerUrl/health" -TimeoutSec 10
    if (-not $health.ok) {
        throw 'Relay publico nao esta saudavel antes do gameplay smoke.'
    }
    Assert-RelayProjectMatches -Health $health

    $room = Invoke-RestMethod -Method Post -Uri "$ManagerUrl/rooms" `
        -ContentType 'application/json' -Body '{"name":"PublicGameplaySmoke"}' -TimeoutSec 20
    $roomCode = [string]$room.code
    $relayHost = [string]$room.host
    $relayPort = [int]$room.port
    Invoke-RestMethod -Method Post -Uri "$ManagerUrl/rooms/$roomCode/join" `
        -ContentType 'application/json' -Body '{}' -TimeoutSec 10 | Out-Null

    Write-Host "PUBLIC_GAMEPLAY_ROOM code=$roomCode host=$relayHost port=$relayPort"

    foreach ($role in @('host', 'client')) {
        $stdout = Join-Path $logDir "$role.out.log"
        $stderr = Join-Path $logDir "$role.err.log"
        $arguments = @(
            '--headless',
            '--path', ('"{0}"' -f $projectRoot),
            '--script', 'res://tests/multiplayer_gameplay_authority_smoke.gd',
            '--',
            "--role=$role",
            "--host=$relayHost",
            "--port=$relayPort",
            "--ping-budget=$PingBudgetMs"
        )
        $processes += Start-Process -FilePath $GodotBin -ArgumentList $arguments `
            -RedirectStandardOutput $stdout -RedirectStandardError $stderr `
            -WindowStyle Hidden -PassThru
        Start-Sleep -Milliseconds 650
    }

    $deadline = [DateTime]::UtcNow.AddSeconds(65)
    $complete = $false
    do {
        $errorPath = Join-Path $projectRoot 'tests\gameplay_authority_error.txt'
        if (Test-Path -LiteralPath $errorPath) {
            throw (Get-Content -LiteralPath $errorPath -Raw)
        }
        $complete =
            (Test-Path -LiteralPath (Join-Path $projectRoot 'tests\gameplay_authority_host_result.txt')) -and
            (Test-Path -LiteralPath (Join-Path $projectRoot 'tests\gameplay_authority_client_result.txt'))
        if ($complete) {
            break
        }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)

    if (-not $complete) {
        $logs = Get-ChildItem -LiteralPath $logDir -Filter '*.log' -File |
            ForEach-Object { "--- $($_.Name) ---`n$(Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue)" }
        throw "Relay publico nao concluiu gameplay authority.`n$($logs -join [Environment]::NewLine)"
    }

    $joinedLogs = (Get-ChildItem -LiteralPath $logDir -Filter '*.out.log' -File |
        ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue }) -join "`n"
    Write-Host $joinedLogs

    $stablePings = @()
    foreach ($match in [regex]::Matches($joinedLogs, 'ping_min_ms=(\d+)')) {
        $stablePings += [int]$match.Groups[1].Value
    }
    $lastPings = @()
    foreach ($match in [regex]::Matches($joinedLogs, 'ping_ms=(\d+)')) {
        $lastPings += [int]$match.Groups[1].Value
    }
    if ($stablePings.Count -gt 0) {
        $maxStablePing = ($stablePings | Measure-Object -Maximum).Maximum
        Write-Host "PUBLIC_GAMEPLAY_PING_STABLE_MS max=$maxStablePing values=$($stablePings -join ',') last=$($lastPings -join ',') budget=$PingBudgetMs"
        if ($maxStablePing -gt $PingBudgetMs) {
            throw "Relay publico acima do budget de ping estavel: max=${maxStablePing}ms budget=${PingBudgetMs}ms last=$($lastPings -join ',')"
        }
    } else {
        throw 'Gameplay smoke nao registrou ping_min_ms nos logs.'
    }

    $errors = Get-ChildItem -LiteralPath $logDir -Filter '*.log' -File |
        Select-String -Pattern '(?i)SCRIPT ERROR:|ERROR:|Parse Error:|RPC configuration mismatch|Invalid packet|Unable to send packet'
    if ($errors) {
        throw "Relay publico encontrou erros nos logs:`n$($errors.Line -join [Environment]::NewLine)"
    }

    Write-Host 'PUBLIC_GAMEPLAY_AUTHORITY_OK host=true client=true'
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
    if ($roomCode -ne '') {
        try {
            Invoke-RestMethod -Method Delete -Uri "$ManagerUrl/rooms/$roomCode" -TimeoutSec 10 | Out-Null
        } catch {
        }
    }
}
