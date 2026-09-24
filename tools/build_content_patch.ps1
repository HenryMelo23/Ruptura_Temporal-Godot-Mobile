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
$base = (Resolve-Path -LiteralPath $BasePack).Path
$output = [IO.Path]::GetFullPath($OutputPack)
if ($output -eq $base) { throw 'Output must not overwrite the base pack.' }
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
    required_game_version_code = 23800
    platform = $(if ($Preset -eq 'Android') { 'android' } else { 'windows' })
} | ConvertTo-Json | Set-Content -LiteralPath ($output + '.json') -Encoding UTF8
Write-Output "CONTENT_PATCH_READY $output"
