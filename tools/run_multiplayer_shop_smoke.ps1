[CmdletBinding()]
param([string]$GodotBin = $env:GODOT_BIN, [int]$Port = 4697)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logs = Join-Path $projectRoot '.agent_logs/shop_wire'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot '.codex') | Out-Null
if (-not $GodotBin -or -not (Test-Path -LiteralPath $GodotBin)) { throw 'Informe -GodotBin.' }
$processes = @()
try {
    foreach ($role in @('server', 'host', 'client')) {
        $result = Join-Path $projectRoot ".codex/shop_wire_$role.txt"
        if (Test-Path -LiteralPath $result) { Remove-Item -LiteralPath $result }
    }
    foreach ($role in @('server', 'host', 'client')) {
        $arguments = @('--headless', '--path', ('"{0}"' -f $projectRoot), '--script', 'res://tests/multiplayer_shop_wire_smoke.gd', '--', "--role=$role", "--port=$Port")
        $process = Start-Process -FilePath $GodotBin -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput "$logs/$role.out.log" -RedirectStandardError "$logs/$role.err.log"
        # Keep the process handle available for ExitCode after the child exits.
        $null = $process.Handle
        $processes += $process
        Start-Sleep -Milliseconds 800
    }
    $deadline = [datetime]::UtcNow.AddSeconds(45)
    do {
        $running = @($processes | Where-Object { -not $_.HasExited })
        if ($running.Count -eq 0) { break }
        Start-Sleep -Milliseconds 200
    } while ([datetime]::UtcNow -lt $deadline)
    if ($running.Count -gt 0) { throw "Shop smoke timeout. Logs: $logs" }
    foreach ($role in @('server', 'host', 'client')) {
        if (-not (Test-Path -LiteralPath (Join-Path $projectRoot ".codex/shop_wire_$role.txt"))) { throw "Missing result: $role" }
    }
    $errors = Get-ChildItem -LiteralPath $logs -Filter '*.log' | Select-String -Pattern 'SCRIPT ERROR:|ERROR:|FAIL'
    if ($errors) { throw ($errors.Line -join "`n") }
    foreach ($process in $processes) {
        $process.WaitForExit()
        if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) {
            throw "Shop process $($process.Id) failed: exit=$($process.ExitCode). Logs: $logs"
        }
    }
    Write-Output 'MULTIPLAYER_SHOP_WIRE_OK purchase=true independent_balance=true waiting=true consensus=true'
} finally {
    foreach ($process in $processes) {
        if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
    }
}
