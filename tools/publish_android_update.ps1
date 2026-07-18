[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+[A-Za-z]?$')]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 2147483647)]
    [int]$VersionCode,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ApkPath,

    [string[]]$Notes = @(),
    [switch]$Mandatory,
    [string]$Server = '72.61.217.238',
    [int]$ManagerPort = 8090,
    [string]$RemoteUpdatePath = '/opt/ruptura/Ruptura_Temporal-Godot-Mobile/server/updates/android',
    [PSCredential]$Credential
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$apk = Get-Item -LiteralPath $ApkPath
$safeVersion = $Version -replace '[^0-9A-Za-z._-]', '_'
$remoteFileName = "ruptura_temporal_mobile_$safeVersion.apk"
$sha256 = (Get-FileHash -LiteralPath $apk.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
$publishedAt = [DateTime]::UtcNow.ToString('o')
$manifest = [ordered]@{
    version = $Version
    version_code = $VersionCode
    filename = $remoteFileName
    sha256 = $sha256
    size = [int64]$apk.Length
    notes = @($Notes | Select-Object -First 8)
    mandatory = [bool]$Mandatory
    published_at = $publishedAt
}

$presetPath = Join-Path $projectRoot 'export_presets.cfg'
if (Test-Path -LiteralPath $presetPath) {
    $preset = Get-Content -LiteralPath $presetPath -Raw
    $presetVersion = [regex]::Match($preset, '(?m)^version/name="([^"]+)"').Groups[1].Value
    $presetCode = [regex]::Match($preset, '(?m)^version/code=(\d+)').Groups[1].Value
    if ($presetVersion -and $presetVersion -ne $Version) {
        throw "O preset Android esta em $presetVersion, mas a publicacao pediu $Version. Gere o APK com a mesma versao."
    }
    if ($presetCode -and [int]$presetCode -ne $VersionCode) {
        throw "O preset Android usa versionCode $presetCode, mas a publicacao pediu $VersionCode."
    }
}

if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
    throw 'O modulo Posh-SSH e necessario para publicar a atualizacao.'
}
Import-Module Posh-SSH
if ($null -eq $Credential) {
    $Credential = Get-Credential -UserName 'root' -Message 'Credencial do servidor Ruptura'
}

$tempRoot = Join-Path $projectRoot '.agent_logs\android_update_publish'
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
$manifestPath = Join-Path $tempRoot 'latest.json.next'
$manifestJson = $manifest | ConvertTo-Json -Depth 5
[IO.File]::WriteAllText($manifestPath, $manifestJson, [Text.UTF8Encoding]::new($false))

$session = New-SSHSession -ComputerName $Server -Credential $Credential -AcceptKey -Force
try {
    $stagingPath = "$RemoteUpdatePath/staging"
    $prepare = Invoke-SSHCommand -SessionId $session.SessionId -Command "install -d -m 0755 '$RemoteUpdatePath' '$stagingPath'"
    if ($prepare.ExitStatus -ne 0) {
        throw "Falha ao preparar pasta remota: $($prepare.Error -join [Environment]::NewLine)"
    }

    Set-SCPItem -ComputerName $Server -Credential $Credential -Path $apk.FullName -Destination $stagingPath -AcceptKey -Force
    Set-SCPItem -ComputerName $Server -Credential $Credential -Path $manifestPath -Destination $stagingPath -AcceptKey -Force

    $activateCommand = @"
set -e
cd '$RemoteUpdatePath'
test "`$(stat -c %s 'staging/$($apk.Name)')" = '$($apk.Length)'
test "`$(sha256sum 'staging/$($apk.Name)' | awk '{print `$1}')" = '$sha256'
mv -f 'staging/$($apk.Name)' '$remoteFileName'
mv -f 'staging/latest.json.next' 'latest.json'
chown ruptura:ruptura '$remoteFileName' 'latest.json'
chmod 0644 '$remoteFileName' 'latest.json'
"@
    $activate = Invoke-SSHCommand -SessionId $session.SessionId -Command $activateCommand
    if ($activate.ExitStatus -ne 0) {
        throw "Falha ao ativar atualizacao: $($activate.Error -join [Environment]::NewLine)"
    }
} finally {
    Remove-SSHSession -SessionId $session.SessionId | Out-Null
}

$publicUri = "http://${Server}:$ManagerPort/updates/android/latest?version_code=$($VersionCode - 1)"
$published = Invoke-RestMethod -Uri $publicUri -TimeoutSec 30
if (-not $published.available -or [int]$published.version_code -ne $VersionCode -or $published.sha256 -ne $sha256) {
    throw 'O endpoint publico nao confirmou a versao publicada.'
}

$trackedManifest = Join-Path $projectRoot 'server\updates\android\latest.json'
[IO.File]::WriteAllText($trackedManifest, $manifestJson, [Text.UTF8Encoding]::new($false))

[pscustomobject]@{
    Version = $Version
    VersionCode = $VersionCode
    SizeMB = [math]::Round($apk.Length / 1MB, 2)
    Sha256 = $sha256
    ManifestUrl = $publicUri
    DownloadUrl = $published.apk_url
} | Format-List
