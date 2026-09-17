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
    [string]$ExePath,

    [string[]]$Notes = @(),
    [switch]$Mandatory,
    [string]$Server = '72.61.217.238',
    [int]$ManagerPort = 8090,
    [string]$RemoteUpdatePath = '/opt/ruptura/Ruptura_Temporal-Godot-Mobile/server/updates/windows',
    [PSCredential]$Credential
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$exe = Get-Item -LiteralPath $ExePath
$safeVersion = $Version -replace '[^0-9A-Za-z._-]', '_'
$remoteFileName = "Ruptura_Temporal_$safeVersion.exe"
$sha256 = (Get-FileHash -LiteralPath $exe.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
$publishedAt = [DateTime]::UtcNow.ToString('o')
$manifest = [ordered]@{
    version = $Version
    version_code = $VersionCode
    filename = $remoteFileName
    sha256 = $sha256
    size = [int64]$exe.Length
    notes = @($Notes | Select-Object -First 8)
    mandatory = [bool]$Mandatory
    published_at = $publishedAt
}

$presetPath = Join-Path $projectRoot 'export_presets.cfg'
if (Test-Path -LiteralPath $presetPath) {
    $preset = Get-Content -LiteralPath $presetPath -Raw
    $windowsBlock = [regex]::Match($preset, '(?s)\[preset\.1\.options\](.*?)(?:\r?\n\[preset\.|\z)').Groups[1].Value
    $productVersion = [regex]::Match($windowsBlock, '(?m)^application/product_version="([^"]+)"').Groups[1].Value
    if ($productVersion -and -not $productVersion.StartsWith(($Version -replace '([A-Za-z])$', ''))) {
        Write-Warning "O preset Windows informa product_version $productVersion, diferente de $Version. Continuando porque o nome do artefato e o GAME_VERSION mandam na atualizacao."
    }
}

if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
    throw 'O modulo Posh-SSH e necessario para publicar a atualizacao.'
}
Import-Module Posh-SSH
if ($null -eq $Credential) {
    $Credential = Get-Credential -UserName 'root' -Message 'Credencial do servidor Ruptura'
}

$tempRoot = Join-Path $projectRoot '.agent_logs\windows_update_publish'
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

    Set-SCPItem -ComputerName $Server -Credential $Credential -Path $exe.FullName -Destination $stagingPath -AcceptKey -Force
    Set-SCPItem -ComputerName $Server -Credential $Credential -Path $manifestPath -Destination $stagingPath -AcceptKey -Force

    $activateCommand = @(
        'set -e',
        "cd '$RemoteUpdatePath'",
        "test ""`$(stat -c %s 'staging/$($exe.Name)')"" = '$($exe.Length)'",
        "test ""`$(sha256sum 'staging/$($exe.Name)' | awk '{print `$1}')"" = '$sha256'",
        "mv -f 'staging/$($exe.Name)' '$remoteFileName'",
        "mv -f 'staging/latest.json.next' 'latest.json'",
        "chown ruptura:ruptura '$remoteFileName' 'latest.json'",
        "chmod 0644 '$remoteFileName' 'latest.json'"
    ) -join "`n"
    $activate = Invoke-SSHCommand -SessionId $session.SessionId -Command $activateCommand
    if ($activate.ExitStatus -ne 0) {
        throw "Falha ao ativar atualizacao Windows: $($activate.Error -join [Environment]::NewLine)"
    }
} finally {
    Remove-SSHSession -SessionId $session.SessionId | Out-Null
}

$publicUri = "http://${Server}:$ManagerPort/updates/windows/latest?version_code=$($VersionCode - 1)"
$published = Invoke-RestMethod -Uri $publicUri -TimeoutSec 30
if (-not $published.available -or [int]$published.version_code -ne $VersionCode -or $published.sha256 -ne $sha256) {
    throw 'O endpoint publico nao confirmou a versao Windows publicada.'
}

$trackedDir = Join-Path $projectRoot 'server\updates\windows'
New-Item -ItemType Directory -Force -Path $trackedDir | Out-Null
$trackedManifest = Join-Path $trackedDir 'latest.json'
[IO.File]::WriteAllText($trackedManifest, $manifestJson, [Text.UTF8Encoding]::new($false))

[pscustomobject]@{
    Version = $Version
    VersionCode = $VersionCode
    SizeMB = [math]::Round($exe.Length / 1MB, 2)
    Sha256 = $sha256
    ManifestUrl = $publicUri
    DownloadUrl = $published.exe_url
} | Format-List
