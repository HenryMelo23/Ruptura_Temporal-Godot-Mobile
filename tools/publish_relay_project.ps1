[CmdletBinding()]
param(
    [string]$Server = '72.61.217.238',
    [string]$RemoteProjectPath = '/opt/ruptura/Ruptura_Temporal-Godot-Mobile',
    [string]$ServiceName = 'ruptura-relay',
    [PSCredential]$Credential,
    [switch]$WithAssets,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$stageRoot = Join-Path $projectRoot '.agent_logs\relay_project_publish'
$payloadRoot = Join-Path $stageRoot 'payload'
$archivePath = Join-Path $stageRoot 'ruptura_relay_project.zip'
$remoteArchive = '/tmp/ruptura_relay_project.zip'

$excludeDirs = @(
    '.git',
    '.godot',
    '.agent_logs',
    '.agents',
    '.codex',
    '.gemini',
    '__pycache__',
    'android',
    'builds',
    'debug',
    'dev',
    'docs',
    'export_templates',
    'Game Base',
    'scratch',
    'tests',
    'toolchain',
    'tools',
    'server\node_modules'
)

$includeRoots = @(
    'addons',
    'feature_profiles',
    'scenes',
    'script_templates',
    'scripts',
    'server',
    'shaders',
    'text_editor_themes',
    'vfx'
)

if ($WithAssets) {
    $includeRoots += @(
        'assets',
        'img',
        'puras',
        'Songs',
        'Sounds'
    )
}

$includeRootFileExtensions = @(
    '.cfg',
    '.gd',
    '.godot',
    '.import',
    '.json',
    '.tres',
    '.tscn',
    '.uid'
)

if ($WithAssets) {
    $includeRootFileExtensions += @(
        '.mp3',
        '.ogg',
        '.png',
        '.wav',
        '.webp'
    )
}

function Test-ExcludedPath {
    param([string]$RelativePath)
    $normalized = $RelativePath.Replace('/', '\').TrimStart('\')
    if ($normalized -eq 'Game Base\memoria_predatoria_umbra.json') {
        return $false
    }
    if ($normalized.StartsWith('server\updates\')) {
        return $true
    }
    foreach ($exclude in $excludeDirs) {
        if ($normalized -eq $exclude -or $normalized.StartsWith($exclude + '\')) {
            return $true
        }
    }
    return $false
}

function Test-IncludedPath {
    param([string]$RelativePath)
    $normalized = $RelativePath.Replace('/', '\').TrimStart('\')
    if ($normalized -eq 'Game Base\memoria_predatoria_umbra.json') {
        return $true
    }
    $parts = $normalized -split '\\', 2
    if ($parts.Count -gt 1 -and $includeRoots -contains $parts[0]) {
        return $true
    }
    if ($parts.Count -eq 1) {
        $extension = [IO.Path]::GetExtension($normalized).ToLowerInvariant()
        return $includeRootFileExtensions -contains $extension
    }
    return $false
}

function Get-RelativePathCompat {
    param(
        [string]$BasePath,
        [string]$FullPath
    )
    $baseUri = [Uri]((Resolve-Path -LiteralPath $BasePath).Path.TrimEnd('\') + '\')
    $fullUri = [Uri](Resolve-Path -LiteralPath $FullPath).Path
    return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($fullUri).ToString()).Replace('/', '\')
}

Remove-Item -LiteralPath $payloadRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $archivePath -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $payloadRoot | Out-Null

$files = Get-ChildItem -LiteralPath $projectRoot -Recurse -File | Where-Object {
    $relative = Get-RelativePathCompat -BasePath $projectRoot -FullPath $_.FullName
    (Test-IncludedPath -RelativePath $relative) -and -not (Test-ExcludedPath -RelativePath $relative)
}

foreach ($file in $files) {
    $relative = Get-RelativePathCompat -BasePath $projectRoot -FullPath $file.FullName
    $target = Join-Path $payloadRoot $relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target -Force
}

Compress-Archive -Path (Join-Path $payloadRoot '*') -DestinationPath $archivePath -Force
$hash = (Get-FileHash -LiteralPath (Join-Path $projectRoot 'scripts\main.gd') -Algorithm SHA256).Hash.ToLowerInvariant()
$archive = Get-Item -LiteralPath $archivePath

if ($DryRun) {
    [pscustomobject]@{
        Archive = $archive.FullName
        SizeMB = [math]::Round($archive.Length / 1MB, 2)
        Files = $files.Count
        MainGdSha256 = $hash
        RemoteProjectPath = $RemoteProjectPath
        ServiceName = $ServiceName
        WithAssets = [bool]$WithAssets
    } | Format-List
    return
}

if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
    throw 'O modulo Posh-SSH e necessario para publicar o projeto do relay.'
}
Import-Module Posh-SSH
if ($null -eq $Credential) {
    $Credential = Get-Credential -UserName 'root' -Message 'Credencial do servidor Ruptura'
}

$session = New-SSHSession -ComputerName $Server -Credential $Credential -AcceptKey -Force
try {
    Set-SCPItem -ComputerName $Server -Credential $Credential -Path $archive.FullName -Destination '/tmp' -AcceptKey -Force
    $command = @"
set -e
install -d -m 0755 '$RemoteProjectPath'
cd '$RemoteProjectPath'
unzip -oq '$remoteArchive'
if [ -f server/package.json ]; then
  cd server
  npm install --omit=dev
  cd ..
fi
chown -R ruptura:ruptura '$RemoteProjectPath'
systemctl restart '$ServiceName'
sleep 2
systemctl is-active --quiet '$ServiceName'
rm -f '$remoteArchive'
"@
    $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $command
    if ($result.ExitStatus -ne 0) {
        throw "Falha ao publicar relay: $($result.Error -join [Environment]::NewLine)"
    }
} finally {
    Remove-SSHSession -SessionId $session.SessionId | Out-Null
}

$health = Invoke-RestMethod -Uri "http://${Server}:8090/health" -TimeoutSec 20
$remoteHash = ''
if ($health.PSObject.Properties.Name -contains 'project' -and $health.project) {
    $remoteHash = [string]$health.project.mainGdSha256
}
if ($remoteHash -ne $hash) {
    throw "O relay reiniciou, mas o hash remoto nao bate. local=$hash remoto=$remoteHash"
}

[pscustomobject]@{
    Published = $true
    Server = $Server
    RemoteProjectPath = $RemoteProjectPath
    MainGdSha256 = $hash
    ServiceName = $ServiceName
} | Format-List
