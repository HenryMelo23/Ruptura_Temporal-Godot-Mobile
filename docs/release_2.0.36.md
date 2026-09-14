# Release 2.0.36 and incremental content

## Migration boundary

2.0.35 downloaded PCKs after Main was already loaded. It cannot reliably replace
Main's cached script or preload graph, even after reopening. Its public server
had no content manifest. Existing installations therefore need the 2.0.36 base
APK/EXE once. This release preserves Android package identity and signing key.
Android's installation confirmation is still required for that base upgrade.

Later script/resource updates can use signed cumulative PCK patches. They download
in the menu, retain unchanged assets, and activate on the next launch before Main
loads. Deletions are supported by Godot's native patch format. Patches are specific
to Android or Windows and the exact base code 23600. Engine, native plugins,
permissions, bootstrap, autoload, signing key and project configuration changes
still require a new base binary. Do not promise that every future update is a PCK.

The shop changes and online transport fixes are included in the full 2.0.36 base.
Do not publish a redundant content pack to installations already containing them.

## Patch workflow

Immutable bases: `builds/2.0.36/base/android.pck` and `windows.pck`.
Keep these exact files; never regenerate them to stand in for a shipped baseline.
Each new patch compares against its original base, not the previous patch, so
players can skip releases. Do not enable binary delta encoding for this workflow.

1. Change scripts/resources without changing the bootstrap/native application.
2. Test source, multiplayer flows and visual changes.
3. Run `tools/build_content_patch.ps1` once per platform, supplying `-GodotBin`,
   `-Preset`, `-BasePack`, unique versioned `-OutputPack` and `-PrivateKey`.
4. Test each patch mounted over its exported base, including removed resources.
5. Run `tools/publish_content_update.ps1` with both `-PackPaths`, increasing
   `-ContentVersionCode`, `-ContentVersion`, `-Notes`, `-GodotBin`, `-Credential`.
6. Verify both public content endpoints and an installed client's download/restart.

Public key: `assets/updates/content_public.pem` (must travel with source/builds).
Private key is outside the repository in the operator's Codex keys directory.
Never commit or package the private key. Transfer it separately and securely when
moving release signing to another computer. SHA-256 plus an RSA signature is
checked before staging and again before mounting; HTTP transport alone is not
trusted to supply executable scripts. Interrupted downloads do not replace the
active state. A complete verified set is committed via atomic state-file rename.

## Validation commands

- `tools/validate_godot.ps1 -Deep`
- `tests/content_update_smoke.gd`: trusted manifest, signature requirement, foreign
  URL and path traversal rejection, downloaded byte verification.
- `tests/content_patch_boot_smoke.gd`: signed real PCK, additions, replacements,
  removals and script loading before use; invalid signature/base rejected.
- `node server/content_update_smoke.js`: platform/base filtering and version checks.
- `tools/run_multiplayer_shop_smoke.ps1`: real local server/host/client purchase,
  independent balance, waiting and consensus.
- APK `apksigner verify --print-certs` and `aapt dump badging`; compare with 2.0.35.
- Run exported Windows game and check its complete logs.

No Android device was attached to ADB during this release. APK signing, contents
and metadata can be verified locally, but that does not prove on-device gameplay.

## Source changes

Shop details: `docs/shop_workshop_2026-09-12.md`.
Transport details: `docs/multiplayer_transport_2026-09-12.md`.
Release changes: boot/main, `scripts/systems/content_pack_state.gd`, public key,
project/export versions, relay content filtering, content signing/build/publish
tools and focused tests. Removed an enabled editor-only addon reference whose
directory was missing; no gameplay addon was removed.

Godot reference: https://docs.godotengine.org/en/stable/tutorials/export/exporting_pcks.html
