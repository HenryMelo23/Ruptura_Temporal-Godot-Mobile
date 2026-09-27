[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GodotBin,
    [Parameter(Mandatory)][ValidateSet('Android','Windows Desktop')][string]$Preset,
    [Parameter(Mandatory)][string]$BasePack,
    [Parameter(Mandatory)][string]$OutputPack,
    [Parameter(Mandatory)][string]$PrivateKey
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$baseContractPath = Join-Path $root 'assets/updates/content_base.json'
$baseContract = Get-Content -LiteralPath $baseContractPath -Raw | ConvertFrom-Json
$baseVersion = [string]$baseContract.base_version
$baseVersionCode = [int]$baseContract.base_version_code
if ([string]::IsNullOrWhiteSpace($baseVersion) -or $baseVersionCode -le 0) { throw 'Invalid content baseline contract.' }
$projectText = Get-Content -LiteralPath (Join-Path $root 'project.godot') -Raw
if ($projectText -notmatch "config/version=`"$([regex]::Escape($baseVersion))`"") { throw "Project version does not match content baseline $baseVersion." }
$exportText = Get-Content -LiteralPath (Join-Path $root 'export_presets.cfg') -Raw
if ($exportText -notmatch "version/code=$baseVersionCode") { throw "Export version code does not match content baseline $baseVersionCode." }
$base = (Resolve-Path -LiteralPath $BasePack).Path
$output = [IO.Path]::GetFullPath($OutputPack)
if ($output -eq $base) { throw 'Output must not overwrite the base pack.' }
if ([IO.Path]::GetFileName($output) -notmatch '^[A-Za-z0-9_.-]+\.pck$') { throw 'Output pack filename must be safe and immutable.' }
New-Item -ItemType Directory -Force -Path (Split-Path $output) | Out-Null
# Always compare to the immutable release base: each patch is cumulative.
& $GodotBin --headless --path $root --export-patch $Preset $output --patches $base
if ($LASTEXITCODE -ne 0) { throw 'Patch export failed.' }
& $GodotBin --headless --path $root --script res://tools/content_sign.gd -- sign $PrivateKey $output
if ($LASTEXITCODE -ne 0) { throw 'Patch signing failed.' }
[ordered]@{
    filename = [IO.Path]::GetFileName($output)
    size = (Get-Item -LiteralPath $output).Length
    sha256 = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant()
    signature = (Get-Content -LiteralPath ($output + '.sig') -Raw).Trim()
    required_game_version_code = $baseVersionCode
    platform = $(if ($Preset -eq 'Android') { 'android' } else { 'windows' })
} | ConvertTo-Json | Set-Content -LiteralPath ($output + '.json') -Encoding UTF8
Write-Output "CONTENT_PATCH_READY $output"
