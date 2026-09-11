param(
    [string]$RunsUrl = "http://72.61.217.238:8090/runs",
    [int]$MinSeconds = 300
)

$ErrorActionPreference = "Stop"

function Percentile($Values, [double]$P) {
    $vals = @($Values | Where-Object { $null -ne $_ } | ForEach-Object { [double]$_ } | Sort-Object)
    if ($vals.Count -eq 0) { return 0 }
    $idx = [Math]::Min($vals.Count - 1, [Math]::Max(0, [int][Math]::Floor(($vals.Count - 1) * $P)))
    return [Math]::Round($vals[$idx], 2)
}

$response = Invoke-WebRequest -Uri $RunsUrl -UseBasicParsing -TimeoutSec 20
$snapshot = $response.Content | ConvertFrom-Json
$runs = @($snapshot.runs) | Where-Object { [double]$_.durationSeconds -ge $MinSeconds }

Write-Output "Runs elegiveis (>=$MinSeconds s): $($runs.Count)"
Write-Output ("Duracao: p50={0}s p75={1}s p90={2}s max={3}s" -f `
    (Percentile ($runs | ForEach-Object durationSeconds) 0.50), `
    (Percentile ($runs | ForEach-Object durationSeconds) 0.75), `
    (Percentile ($runs | ForEach-Object durationSeconds) 0.90), `
    (Percentile ($runs | ForEach-Object durationSeconds) 1.00))
Write-Output ("Fase: p50={0} p75={1} max={2}" -f `
    (Percentile ($runs | ForEach-Object phase) 0.50), `
    (Percentile ($runs | ForEach-Object phase) 0.75), `
    (Percentile ($runs | ForEach-Object phase) 1.00))
Write-Output ("Abates: p50={0} p75={1} p90={2}" -f `
    (Percentile ($runs | ForEach-Object kills) 0.50), `
    (Percentile ($runs | ForEach-Object kills) 0.75), `
    (Percentile ($runs | ForEach-Object kills) 0.90))
Write-Output ("Cartas: p50={0} p75={1} p90={2}" -f `
    (Percentile ($runs | ForEach-Object cardsTotal) 0.50), `
    (Percentile ($runs | ForEach-Object cardsTotal) 0.75), `
    (Percentile ($runs | ForEach-Object cardsTotal) 0.90))
Write-Output ("Dano em boss: p50={0} p75={1} p90={2}" -f `
    (Percentile ($runs | ForEach-Object bossDamage) 0.50), `
    (Percentile ($runs | ForEach-Object bossDamage) 0.75), `
    (Percentile ($runs | ForEach-Object bossDamage) 0.90))

Write-Output ""
Write-Output "Manifestacoes:"
$runs |
    Group-Object manifestationKey |
    Sort-Object Count -Descending |
    Select-Object -First 12 |
    ForEach-Object {
        $avgDur = [Math]::Round((($_.Group | Measure-Object durationSeconds -Average).Average), 1)
        $avgBoss = [Math]::Round((($_.Group | Measure-Object bossDamage -Average).Average), 1)
        Write-Output ("- {0}: runs={1} duracao_media={2}s boss_media={3}" -f $_.Name, $_.Count, $avgDur, $avgBoss)
    }

Write-Output ""
Write-Output "Maiores fontes de dano recebido:"
$runs |
    ForEach-Object { @($_.damageThreats) } |
    Where-Object { $_ } |
    Group-Object name |
    Sort-Object { ($_.Group | Measure-Object damage -Sum).Sum } -Descending |
    Select-Object -First 12 |
    ForEach-Object {
        $damage = [Math]::Round((($_.Group | Measure-Object damage -Sum).Sum), 0)
        $hits = [Math]::Round((($_.Group | Measure-Object hits -Sum).Sum), 0)
        Write-Output ("- {0}: dano={1} hits={2}" -f $_.Name, $damage, $hits)
    }
