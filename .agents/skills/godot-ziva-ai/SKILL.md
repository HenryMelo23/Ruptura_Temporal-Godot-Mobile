---
name: godot-ziva-ai
description: Use Ziva when a signed-in AI agent needs live Godot editor context, scene authoring, screenshots, or project-aware QA.
---

# Ziva for Godot

Ziva is an editor-side native extension and sidecar. Use it for project-aware inspection, scene/node edits, screenshots, and iterative visual QA while preserving the project's existing architecture.

## Dependency and portable installation

The expected file is `res://addons/ziva_agent/ziva_agent.gdextension`. On Linux or macOS, close Godot and install the current plugin with:

```bash
curl -fsSL https://ziva.sh/install.sh | bash
$HOME/.ziva/bin/ziva-installer install /absolute/path/to/Ruptura_Temporal-Godot-Mobile --plugin-version latest --godot-path /opt/godot/Godot_v4.7.2-stable_linux.x86_64 --no-download-godot
```

On Windows, use the PowerShell installer from https://ziva.sh/docs and pass the project path plus the installed Godot executable. The installer is the source of truth for platform binaries; do not copy a Linux native library to another OS.

## Operational constraints

Sign in from the Ziva dock before requesting agent actions; an installed dock without an API key can start but cannot complete cloud requests. Keep the native package out of Git when it is a large platform-specific download (this project keeps it locally ignored by `addons/ziva_agent/.gdignore` for stable CI/mobile imports). Remove that marker only on a machine where the editor integration is desired. Never store API keys or session data in the repository.

Use the editor's undo/checkpoint flow, inspect screenshots after visual edits, and run the project's Godot tests after code or scene changes. Ziva is never required for a playable export.

## Validation

Confirm the editor opens with the extension enabled on the target machine, the Ziva dock reports a healthy local sidecar, and a read-only project inspection succeeds. For headless or CI validation, leave Ziva ignored and run the normal Godot import and scene smoke tests.
