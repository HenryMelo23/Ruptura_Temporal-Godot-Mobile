param(
	[string]$Version = "",
	[string]$GodotExe = "",
	[int]$ExportTimeoutMinutes = 18,
	[switch]$Release
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$MainScript = Join-Path $ProjectRoot "scripts\main.gd"
$PresetFile = Join-Path $ProjectRoot "export_presets.cfg"
$PresetName = "Android"
$LogsDir = Join-Path $ProjectRoot ".agent_logs"
$ExpectedAndroidPackageName = "org.rupturatemporal.godotmobile"

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

	$match = [regex]::Match($VersionName, '^(\d+)\.(\d+)\.(\d+)([A-Za-z]?)$')
	if (-not $match.Success) {
		return 1
	}
	$major = [int]$match.Groups[1].Value
	$minor = [int]$match.Groups[2].Value
	$patch = [int]$match.Groups[3].Value
	$suffix = $match.Groups[4].Value
	$baseCode = ($major * 100) + ($minor * 10) + $patch
	if ($suffix) {
		$suffixCode = [int][char]($suffix.ToLowerInvariant()) - [int][char]'a' + 1
		return ($baseCode * 100) + $suffixCode
	}
	return ($baseCode * 100)
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
	$updatedPackageName = $false
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
		if ($inAndroidOptions -and $line -match '^package/unique_name=') {
			$lines[$index] = 'package/unique_name="' + $ExpectedAndroidPackageName + '"'
			$updatedPackageName = $true
			continue
		}
	}

	if (-not ($updatedExportPath -and $updatedVersionCode -and $updatedVersionName -and $updatedPackageName)) {
		throw "Nao consegui atualizar o preset Android em export_presets.cfg."
	}

	$content = ($lines -join [Environment]::NewLine) + [Environment]::NewLine
	$utf8NoBom = New-Object System.Text.UTF8Encoding $False
	[System.IO.File]::WriteAllText($PresetFile, $content, $utf8NoBom)
}

function ConvertTo-GradlePropertiesPath {
	param([string]$Path)

	return $Path.Replace("\", "/").Replace(":", "\:")
}

function Ensure-AndroidLocalProperties {
	$candidates = @(@(
		(Join-Path $ProjectRoot "toolchain\android-sdk"),
		$env:ANDROID_SDK_ROOT,
		$env:ANDROID_HOME,
		"$env:LOCALAPPDATA\Android\Sdk"
	) | Where-Object { $_ -and (Test-Path -LiteralPath $_) })

	if (-not $candidates -or $candidates.Count -eq 0) {
		Write-Host "Aviso: Android SDK nao encontrado para android/local.properties; seguindo com configuracao do Godot."
		return
	}

	$sdkPath = (Resolve-Path -LiteralPath $candidates[0]).Path
	$androidDir = Join-Path $ProjectRoot "android"
	$localProperties = Join-Path $androidDir "local.properties"
	New-Item -ItemType Directory -Force -Path $androidDir | Out-Null

	$content = "sdk.dir=$(ConvertTo-GradlePropertiesPath -Path $sdkPath)" + [Environment]::NewLine
	$utf8NoBom = New-Object System.Text.UTF8Encoding $False
	[System.IO.File]::WriteAllText($localProperties, $content, $utf8NoBom)
	Write-Host "Android SDK fixado em android/local.properties: $sdkPath"
}

function Test-ApkLooksComplete {
	param([string]$Path)

	if (-not (Test-Path -LiteralPath $Path)) {
		return $false
	}

	$apkInfo = Get-Item -LiteralPath $Path
	if ($apkInfo.Length -lt 150MB) {
		return $false
	}

	try {
		Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
		$zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
		try {
			$hasManifest = $false
			$hasGodotLib = $false
			$hasGameAssets = $false
			foreach ($entry in $zip.Entries) {
				if ($entry.FullName -eq "AndroidManifest.xml") { $hasManifest = $true }
				if ($entry.FullName -match '^lib/[^/]+/libgodot_android\.so$') { $hasGodotLib = $true }
				if ($entry.FullName -match '^assets/\.godot/(imported|exported)/') { $hasGameAssets = $true }
				if ($hasManifest -and $hasGodotLib -and $hasGameAssets) {
					return $true
				}
			}
		}
		finally {
			$zip.Dispose()
		}
	}
	catch {
		return $false
	}

	return $false
}

function Stop-ProcessTree {
	param([int]$ProcessId)

	$children = @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$ProcessId" -ErrorAction SilentlyContinue)
	foreach ($child in $children) {
		Stop-ProcessTree -ProcessId ([int]$child.ProcessId)
	}
	Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
}

function Invoke-GodotExportWithWatchdog {
	param(
		[string]$GodotPath,
		[string[]]$Arguments,
		[string]$LogPath,
		[int]$TimeoutMinutes,
		[string]$ExpectedOutputPath = ""
	)

	$timeoutSeconds = [Math]::Max(60, $TimeoutMinutes * 60)
	$outPath = $LogPath
	$errPath = $LogPath + ".err"
	if (Test-Path -LiteralPath $outPath) { Remove-Item -LiteralPath $outPath -Force }
	if (Test-Path -LiteralPath $errPath) { Remove-Item -LiteralPath $errPath -Force }

	Write-Host ""
	Write-Host "Exportando com watchdog de $TimeoutMinutes min..."
	Write-Host ("Comando: {0} {1}" -f $GodotPath, ($Arguments -join " "))
	Write-Host "Log: $outPath"

	$process = Start-Process -FilePath $GodotPath -ArgumentList $Arguments -WorkingDirectory $ProjectRoot -RedirectStandardOutput $outPath -RedirectStandardError $errPath -PassThru -WindowStyle Hidden
	$started = Get-Date
	$lastSize = -1
	$lastArtifactSize = -1
	$artifactStableSince = $null
	while (-not $process.HasExited) {
		Start-Sleep -Seconds 10
		$elapsed = [int]((Get-Date) - $started).TotalSeconds
		$currentSize = 0
		if (Test-Path -LiteralPath $outPath) {
			$currentSize = (Get-Item -LiteralPath $outPath).Length
		}
		$status = "rodando"
		if ($currentSize -eq $lastSize) {
			$status = "sem nova saida"
		}
		$lastSize = $currentSize
		Write-Host ("Godot export {0}s/{1}s - {2} - log {3:N1} KB" -f $elapsed, $timeoutSeconds, $status, ($currentSize / 1KB))
		if ($ExpectedOutputPath -and (Test-Path -LiteralPath $ExpectedOutputPath)) {
			$artifactInfo = Get-Item -LiteralPath $ExpectedOutputPath
			$artifactSize = $artifactInfo.Length
			if ($artifactSize -eq $lastArtifactSize) {
				if ($null -eq $artifactStableSince) {
					$artifactStableSince = Get-Date
				}
				if (((Get-Date) - $artifactStableSince).TotalSeconds -ge 20 -and (Test-ApkLooksComplete -Path $ExpectedOutputPath)) {
					Write-Host "APK final detectado, completo e estavel; encerrando processo Godot headless preso apos exportacao."
					Stop-ProcessTree -ProcessId $process.Id
					return
				}
			} else {
				$artifactStableSince = $null
				$lastArtifactSize = $artifactSize
			}
		}
		if ($elapsed -ge $timeoutSeconds) {
			Stop-ProcessTree -ProcessId $process.Id
			throw "Exportacao travou ou excedeu $TimeoutMinutes min. Processo encerrado. Veja o log: $outPath"
		}
	}

	$process.WaitForExit()
	$process.Refresh()
	if ((Test-Path -LiteralPath $errPath) -and (Get-Item -LiteralPath $errPath).Length -gt 0) {
		Get-Content -LiteralPath $errPath -Tail 80 | Add-Content -LiteralPath $outPath
	}
	if (Test-Path -LiteralPath $outPath) {
		Get-Content -LiteralPath $outPath -Tail 120
	}
	if ($null -eq $process.ExitCode) {
		if ($ExpectedOutputPath -and (Test-ApkLooksComplete -Path $ExpectedOutputPath)) {
			Write-Host "Godot encerrou sem ExitCode acessivel; APK completo validado pelo watchdog."
			return
		}
		throw "Godot encerrou sem ExitCode e sem APK completo. Log: $outPath"
	}
	if ($process.ExitCode -ne 0) {
		throw "Godot retornou codigo $($process.ExitCode) durante a exportacao. Log: $outPath"
	}
}

if (-not $Version) {
	$Version = Read-GameVersion
}

if ($Version -notmatch '^\d+\.\d+\.\d+[A-Za-z]?$') {
	throw "Versao invalida: $Version. Use o formato 2.0.11 ou 2.0.28a."
}

$GodotPath = Resolve-GodotExe -RequestedPath $GodotExe
$BuildDir = Join-Path $ProjectRoot ("builds\" + $Version)
$ApkName = "ruptura_temporal_mobile_$Version.apk"
$ApkPath = Join-Path $BuildDir $ApkName
$RelativeApkPath = "builds/$Version/$ApkName"
$VersionCode = Get-VersionCode -VersionName $Version

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null
Ensure-AndroidLocalProperties
Update-AndroidPreset -VersionName $Version -RelativeExportPath $RelativeApkPath -VersionCode $VersionCode

Write-Host "Projeto: $ProjectRoot"
Write-Host "Versao: $Version"
Write-Host "Pasta: $BuildDir"
Write-Host "APK: $ApkPath"
Write-Host "Godot: $GodotPath"
Write-Host "Timeout: $ExportTimeoutMinutes min"

$exportMode = "--export-debug"
if ($Release) {
	$exportMode = "--export-release"
}

$PreviousApkPath = "$ApkPath.previous"
if (Test-Path -LiteralPath $PreviousApkPath) {
	Remove-Item -LiteralPath $PreviousApkPath -Force
}
if (Test-Path -LiteralPath $ApkPath) {
	Rename-Item -LiteralPath $ApkPath -NewName (Split-Path -Leaf $PreviousApkPath) -Force
	Write-Host "APK anterior preservado temporariamente: $PreviousApkPath"
}
if (Test-Path -LiteralPath "$ApkPath.idsig") {
	Remove-Item -LiteralPath "$ApkPath.idsig" -Force
}

Push-Location $ProjectRoot
try {
	$exportLog = Join-Path $LogsDir ("build_apk_{0}.log" -f ($Version -replace '[^0-9A-Za-z_.-]', '_'))
	Invoke-GodotExportWithWatchdog -GodotPath $GodotPath -Arguments @("--headless", "--path", $ProjectRoot, $exportMode, $PresetName, $ApkPath) -LogPath $exportLog -TimeoutMinutes $ExportTimeoutMinutes -ExpectedOutputPath $ApkPath
}
catch {
	if (-not (Test-Path -LiteralPath $ApkPath) -and (Test-Path -LiteralPath $PreviousApkPath)) {
		Rename-Item -LiteralPath $PreviousApkPath -NewName (Split-Path -Leaf $ApkPath) -Force
		Write-Host "APK anterior restaurado apos falha de exportacao."
	}
	throw
}
finally {
	Pop-Location
}

if ((Test-Path -LiteralPath $ApkPath) -and (Test-Path -LiteralPath $PreviousApkPath)) {
	Remove-Item -LiteralPath $PreviousApkPath -Force
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
