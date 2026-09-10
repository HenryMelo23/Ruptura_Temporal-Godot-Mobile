---
name: godot-ai-mcp
description: Use the Godot AI addon when an MCP client must inspect or author Godot scenes, nodes, scripts, materials, particles, or screenshots.
---

# Godot AI MCP

Use this addon as an editor bridge for an MCP-compatible assistant. It is tooling only: never make the game, exported build, or save data depend on its runtime helpers.

## Dependency and portable installation

The expected files are `res://addons/godot_ai/plugin.cfg` and the upstream `Godot AI` release. If the addon is absent, follow the current installation instructions at https://github.com/hi-godot/godot-ai and install `uv` using the platform command documented there, then copy the addon's `addons/godot_ai` directory into the project. Enable it in Project Settings → Plugins and configure the MCP client from the addon dock.

Before enabling an addon snapshot, parse/import the project. Generated client or custom-tool scripts must come from the same release; do not mix files from different snapshots. If parse errors or socket conflicts appear, disable the plugin and remove its autoload entry while keeping the files available for a clean reinstall.

## Project-specific state

This repository keeps an older Godot AI snapshot available but disabled because its generated client scripts were inconsistent. The project uses Ziva or another MCP client separately. Do not re-enable `godot_ai` automatically; first install a compatible release and run the full Godot validation ladder.

## Validation

With the plugin enabled, open the editor, verify the dock can connect to the MCP client, and exercise one read-only scene inspection before authoring changes. After any authored change, run project import, affected-scene smoke, and visual QA. Never commit API keys, local sockets, or client credentials.
