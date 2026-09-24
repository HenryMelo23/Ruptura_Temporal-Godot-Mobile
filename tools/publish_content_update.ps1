[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GodotBin,
    [Parameter(Mandatory)][int]$ContentVersionCode,
    [Parameter(Mandatory)][string]$ContentVersion,
    [Parameter(Mandatory)][string[]]$PackPaths,
    [Parameter(Mandatory)][PSCredential]$Credential,
    [string[]]$Notes = @(),
    [string]$Server = '72.61.217.238'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$remote = '/opt/ruptura/Ruptura_Temporal-Godot-Mobile/server/updates/content'
$packs = @()
foreach ($path in $PackPaths) {
    $file = Get-Item -LiteralPath $path
    $entry = Get-Content -LiteralPath ($file.FullName + '.json') -Raw | ConvertFrom-Json
    if ($entry.filename -ne $file.Name -or $file.Name -notmatch '^[A-Za-z0-9_.-]+\.pck$') { throw 'Invalid pack filename.' }
    if ($entry.required_game_version_code -ne 23800 -or $entry.platform -notin @('android','windows')) { throw 'Invalid base or platform.' }
    if ($entry.sha256 -ne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant() -or $entry.size -ne $file.Length) { throw 'Pack integrity mismatch.' }
    if ($entry.signature -ne (Get-Content -LiteralPath ($file.FullName + '.sig') -Raw).Trim()) { throw 'Signature metadata mismatch.' }
    & $GodotBin --headless --path $root --script res://tools/content_sign.gd -- verify (Join-Path $root 'assets/updates/content_public.pem') $file.FullName
    if ($LASTEXITCODE -ne 0) { throw 'Signature verification failed.' }
    $packs += $entry
}
if ($packs.Count -ne 2 -or @($packs.platform | Select-Object -Unique).Count -ne 2) { throw 'Provide one cumulative pack per platform.' }
$manifest = [ordered]@{ content_version=$ContentVersion; content_version_code=$ContentVersionCode; packs=$packs; notes=$Notes; published_at=[DateTime]::UtcNow.ToString('o') }
$stage = Join-Path $root '.agent_logs/content_publish'
New-Item -ItemType Directory -Force -Path $stage | Out-Null
$manifestPath = Join-Path $stage 'latest.json.next'
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Import-Module Posh-SSH
$session = New-SSHSession -ComputerName $Server -Credential $Credential -AcceptKey
try {
    $prepare = Invoke-SSHCommand -SessionId $session.SessionId -Command "install -d -m 0755 '$remote/staging'"
    if ($prepare.ExitStatus -ne 0) { throw 'Cannot prepare remote content directory.' }
    foreach ($path in $PackPaths) {
        $file = Get-Item -LiteralPath $path
        $entry = $packs | Where-Object filename -EQ $file.Name
        Set-SCPItem -ComputerName $Server -Credential $Credential -Path $file.FullName -Destination "$remote/staging" -AcceptKey
        $result = Invoke-SSHCommand -SessionId $session.SessionId -Command "set -e; test ! -e '$remote/$($file.Name)'; test `"`$(sha256sum '$remote/staging/$($file.Name)' | cut -d ' ' -f 1)`" = '$($entry.sha256)'; mv '$remote/staging/$($file.Name)' '$remote/$($file.Name)'; chmod 644 '$remote/$($file.Name)'"
        if ($result.ExitStatus -ne 0) { throw 'Remote hash mismatch or filename already published. Use immutable filenames.' }
    }
    Set-SCPItem -ComputerName $Server -Credential $Credential -Path $manifestPath -Destination "$remote/staging" -AcceptKey
    $result = Invoke-SSHCommand -SessionId $session.SessionId -Command "mv '$remote/staging/latest.json.next' '$remote/latest.json'; chmod 644 '$remote/latest.json'"
    if ($result.ExitStatus -ne 0) { throw 'Cannot activate manifest.' }
} finally { Remove-SSHSession -SessionId $session.SessionId | Out-Null }
foreach ($platform in @('android','windows')) {
    $reply = Invoke-RestMethod "http://${Server}:8090/updates/content/latest?version_code=23800&platform=$platform"
    if (-not $reply.available -or $reply.content_version_code -ne $ContentVersionCode) { throw 'Public content endpoint verification failed.' }
}
Write-Output "CONTENT_PUBLISHED $ContentVersion"
