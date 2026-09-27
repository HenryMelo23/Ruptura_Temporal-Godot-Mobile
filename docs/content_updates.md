# Incremental content updates

This project uses Godot-native cumulative PCK patches for ordinary script,
scene, resource, audio, shader, data, UI, gameplay, boss, and AI changes.
Do not replace this with APK/EXE binary diffs.

## Current baseline

The authoritative baseline contract is:

- file: `assets/updates/content_base.json`
- base version: `2.0.41`
- base version code: `24100`

The previous shipped `2.0.40` binaries cannot be used as a safe content-update
baseline in this checkout because the exact immutable Android and Windows base
PCK files for that release are not available here. The next full release,
`2.0.41`, is therefore the clean incremental-update boundary.

When preparing that full release, export and preserve the immutable base PCKs:

```powershell
& $GodotBin --headless --path . --export-pack "Android" "builds/2.0.41/base/android.pck"
& $GodotBin --headless --path . --export-pack "Windows Desktop" "builds/2.0.41/base/windows.pck"
```

Those base PCKs must match the released APK/EXE. Do not regenerate them later
and pretend they are the original shipped baseline.

## Build a content patch

Each content patch is cumulative against the immutable base, so players may skip
older content releases and install the newest patch directly.

Android:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_content_patch.ps1 `
  -GodotBin $GodotBin `
  -Preset "Android" `
  -BasePack "builds/2.0.41/base/android.pck" `
  -OutputPack "builds/content/ruptura_content_2.0.41_c001_android.pck" `
  -PrivateKey $PrivateKey
```

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_content_patch.ps1 `
  -GodotBin $GodotBin `
  -Preset "Windows Desktop" `
  -BasePack "builds/2.0.41/base/windows.pck" `
  -OutputPack "builds/content/ruptura_content_2.0.41_c001_windows.pck" `
  -PrivateKey $PrivateKey
```

The builder reads `assets/updates/content_base.json`, validates that project and
export metadata agree with it, exports with `--export-patch`, signs the PCK, and
writes `<pack>.json` metadata containing filename, size, SHA-256, RSA signature,
platform, and required base version code.

## Publish content

Publishing accepts one platform or both. Filenames are immutable and duplicates
for the same platform are rejected.

Android only:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\publish_content_update.ps1 `
  -GodotBin $GodotBin `
  -ContentVersion "2.0.41-content.1" `
  -ContentVersionCode 1 `
  -PackPaths "builds/content/ruptura_content_2.0.41_c001_android.pck" `
  -Credential $Credential
```

Both platforms:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\publish_content_update.ps1 `
  -GodotBin $GodotBin `
  -ContentVersion "2.0.41-content.1" `
  -ContentVersionCode 1 `
  -PackPaths "builds/content/ruptura_content_2.0.41_c001_android.pck","builds/content/ruptura_content_2.0.41_c001_windows.pck" `
  -Credential $Credential
```

## Client flow

On boot, `scripts/boot.gd` mounts the verified installed content state before
loading `Main.tscn`. The game then checks `/updates/content/latest`, downloads
only the current platform's compatible PCK, verifies size, SHA-256 and RSA
signature, promotes the `.part` file atomically, writes `content_state.json`, and
uses the patch after restart.

Interrupted downloads remain as `.pck.part`. The client resumes with
`Range: bytes=<offset>-` when the server supports it. A failed or corrupted
download never replaces the active verified PCK.

## Full APK/EXE updates

A full application release is still required for Godot/runtime changes, Android
native plugins, GDExtension/native libraries, permissions, package/signing
configuration, bootstrap/update-loader changes, and any other native
configuration incompatible with the current baseline.

## Establishing a future baseline

1. Bump `assets/updates/content_base.json`.
2. Bump `project.godot`, `scripts/main_runtime_state.gd`, and export preset
   version metadata to match.
3. Ship a full APK/EXE release.
4. Export and preserve the exact immutable base PCKs for that release.
5. Build all later content patches against those preserved base PCKs.
