param(
	[string]$Version = "",
	[string]$GodotExe = "",
	[switch]$Release
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$MainScript = Join-Path $ProjectRoot "scripts\main.gd"
$PresetFile = Join-Path $ProjectRoot "export_presets.cfg"
$PresetName = "Android"

function Read-GameVersion {
	if (-not (Test-Path -LiteralPath $MainScript)) {
		throw "Nao encontrei scripts\main.gd para ler GAME_VERSION."
	}
	$content = Get-Content -LiteralPath $MainScript -Raw
	$match = [regex]::Match($content, 'const\s+GAME_VERSION\s*:=\s*"([^"]+)"')
	if (-not $match.Success) {
		throw "Nao consegui encontrar const GAME_VERSION em scripts\main.gd."
	}
	return $match.Groups[1].Value
}

function Resolve-GodotExe {
	param([string]$RequestedPath)

	if ($RequestedPath -and (Test-Path -LiteralPath $RequestedPath)) {
		return (Resolve-Path -LiteralPath $RequestedPath).Path
	}
	if ($env:GODOT_EXE -and (Test-Path -LiteralPath $env:GODOT_EXE)) {
		return (Resolve-Path -LiteralPath $env:GODOT_EXE).Path
	}

	$candidates = @(
		"$env:USERPROFILE\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe",
		"$env:USERPROFILE\Downloads\Godot_v4.6.3-stable_win64_console.exe",
		"$ProjectRoot\Godot_v4.6.3-stable_win64_console.exe"
	)
	foreach ($candidate in $candidates) {
		if (Test-Path -LiteralPath $candidate) {
			return (Resolve-Path -LiteralPath $candidate).Path
		}
	}

	$found = Get-ChildItem -Path "$env:USERPROFILE\Downloads" -Filter "Godot*_console.exe" -Recurse -ErrorAction SilentlyContinue |
		Sort-Object LastWriteTime -Descending |
		Select-Object -First 1
	if ($found) {
		return $found.FullName
	}

	throw "Nao encontrei o executavel console do Godot. Passe -GodotExe 'C:\caminho\Godot...console.exe' ou defina GODOT_EXE."
}

function Get-VersionCode {
	param([string]$VersionName)

	$parts = $VersionName.Split(".")
	if ($parts.Count -lt 3) {
		return 1
	}
	$major = [int]$parts[0]
	$minor = [int]$parts[1]
	$patch = [int]$parts[2]
	return ($major * 100) + ($minor * 10) + $patch
}

function Update-AndroidPreset {
	param(
		[string]$VersionName,
		[string]$RelativeExportPath,
		[int]$VersionCode
	)

	if (-not (Test-Path -LiteralPath $PresetFile)) {
		throw "Nao encontrei export_presets.cfg."
	}

	$lines = Get-Content -LiteralPath $PresetFile
	$inAndroidPreset = $false
	$inAndroidOptions = $false
	$updatedExportPath = $false
	$updatedVersionCode = $false
	$updatedVersionName = $false
	$normalizedExportPath = $RelativeExportPath.Replace("\", "/")

	for ($index = 0; $index -lt $lines.Count; $index++) {
		$line = $lines[$index]
		if ($line -eq "[preset.0]") {
			$inAndroidPreset = $true
			$inAndroidOptions = $false
			continue
		}
		if ($line -eq "[preset.0.options]") {
			$inAndroidPreset = $false
			$inAndroidOptions = $true
			continue
		}
		if ($line -match '^\[preset\.\d+(\.options)?\]$' -and $line -ne "[preset.0]" -and $line -ne "[preset.0.options]") {
			$inAndroidPreset = $false
			$inAndroidOptions = $false
			continue
		}

		if ($inAndroidPreset -and $line -match '^export_path=') {
			$lines[$index] = 'export_path="' + $normalizedExportPath + '"'
			$updatedExportPath = $true
			continue
		}
		if ($inAndroidOptions -and $line -match '^version/code=') {
			$lines[$index] = 'version/code=' + $VersionCode
			$updatedVersionCode = $true
			continue
		}
		if ($inAndroidOptions -and $line -match '^version/name=') {
			$lines[$index] = 'version/name="' + $VersionName + '"'
			$updatedVersionName = $true
			continue
		}
	}

	if (-not ($updatedExportPath -and $updatedVersionCode -and $updatedVersionName)) {
		throw "Nao consegui atualizar o preset Android em export_presets.cfg."
	}

	$content = ($lines -join [Environment]::NewLine) + [Environment]::NewLine
	$utf8NoBom = New-Object System.Text.UTF8Encoding $False
	[System.IO.File]::WriteAllText($PresetFile, $content, $utf8NoBom)
}

if (-not $Version) {
	$Version = Read-GameVersion
}

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
	throw "Versao invalida: $Version. Use o formato 2.0.11."
}

$GodotPath = Resolve-GodotExe -RequestedPath $GodotExe
$BuildDir = Join-Path $ProjectRoot ("builds\" + $Version)
$ApkName = "ruptura_temporal_mobile_$Version.apk"
$ApkPath = Join-Path $BuildDir $ApkName
$RelativeApkPath = "builds/$Version/$ApkName"
$VersionCode = Get-VersionCode -VersionName $Version

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
Update-AndroidPreset -VersionName $Version -RelativeExportPath $RelativeApkPath -VersionCode $VersionCode

Write-Host "Projeto: $ProjectRoot"
Write-Host "Versao: $Version"
Write-Host "Pasta: $BuildDir"
Write-Host "APK: $ApkPath"
Write-Host "Godot: $GodotPath"

$exportMode = "--export-debug"
if ($Release) {
	$exportMode = "--export-release"
}

Push-Location $ProjectRoot
try {
	& $GodotPath --headless --path $ProjectRoot $exportMode $PresetName $ApkPath
	if ($LASTEXITCODE -ne 0) {
		throw "Godot retornou codigo $LASTEXITCODE durante a exportacao."
	}
}
finally {
	Pop-Location
}

if (-not (Test-Path -LiteralPath $ApkPath)) {
	throw "Exportacao terminou, mas o APK nao foi encontrado em $ApkPath."
}

$apkInfo = Get-Item -LiteralPath $ApkPath
Write-Host ""
Write-Host "APK criado/substituido com sucesso:"
Write-Host $apkInfo.FullName
Write-Host ("Tamanho: {0:N2} MB" -f ($apkInfo.Length / 1MB))

$idsigPath = "$ApkPath.idsig"
if (Test-Path -LiteralPath $idsigPath) {
	$idsigInfo = Get-Item -LiteralPath $idsigPath
	Write-Host "IDSIG: $($idsigInfo.FullName)"
}
