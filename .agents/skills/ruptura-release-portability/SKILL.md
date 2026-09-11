---
name: ruptura-release-portability
description: Use for Ruptura Temporal version bumps, GitHub preservation, APK/EXE exports, updater publishing, release notes, fonts, and asset portability across machines.
---

# Ruptura Release Portability

Use this skill when the user asks to push to GitHub, prepare APK/EXE, publish an update, preserve work between desktop and notebook, fix missing fonts/assets in builds, or update server download metadata.

## Git Preservation

- Start with `git status --short --branch`.
- Commit only the files required for the current request.
- Never use force push unless the user explicitly asks and the remote divergence has been inspected.
- If the user says not to publish an update to players, push code/artifacts metadata only as requested and do not update public release endpoints.

## Version/Export Checklist

When building a release, align:

- `project.godot` version text.
- `export_presets.cfg` version/code/package metadata.
- APK and Windows output names under `builds/<version>/`.
- Updater metadata such as `latest.json` or server upload scripts, when publishing is explicitly requested.
- Release notes must omit hidden/cheat/online details when the user asks not to advertise them.

## Asset Portability Checklist

Before saying another PC/mobile build will match the desktop, verify real assets, not just local cache:

```powershell
git ls-files | rg "\.(ttf|otf|fnt|font|png|jpg|webp|mp3|ogg|wav|tscn|tres|res)$"
git status --short
git check-ignore -v <path>
```

- Fonts must be committed as real files and referenced by exported resources or load paths.
- Audio/images must not live only in local downloads, temp folders, `.godot`, `.import`, `.agent_logs`, or `.codex`.
- If adding root-level assets, update `.gitignore` exceptions deliberately.
- When export problems mention missing resources, inspect the complete Godot log and fix the path/resource instead of copying files blindly.

## Validation

- Docs/skill-only preservation: `git diff --check`.
- Asset or export setting changes: run focused resource parse plus `tools/validate_godot.ps1 -Deep`.
- APK/EXE export: verify output exists, size is nonzero, and the expected version appears in the app/update metadata.
- Public update: verify endpoint returns the new metadata/hash after upload.
