---
name: godot-at-icons
description: Use @icons when adding consistent custom icons to Godot node scripts or editor tooling.
---

# @icons

Use this addon for editor node icons and the built-in SVG picker. It is an editor convenience, not a runtime UI icon system.

## Dependency

The project should contain `res://addons/at-icons/plugin.cfg` and have the `@icons` plugin enabled in Project Settings. If it is missing, install the `@icons` release from the Godot Asset Library into the project root, then enable the plugin. Keep the addon's license with the copied files.

## Usage

Add an icon annotation before a custom class declaration:

```gdscript
@icon("res://addons/at-icons/node/bunny.svg")
class_name MyNode
extends Node
```

Pick icons that communicate the node's role and preserve the project's existing editor language. Reopen the affected scene after changing an annotation so the editor refreshes the icon. Do not add these SVGs to gameplay HUDs or make gameplay depend on the editor plugin.

## Validation

Open the project in Godot, confirm the `@icons` dock loads, and reopen one scene containing an annotated script. For CI or headless runs, only verify that the addon is not registered as a runtime autoload and that changed scripts parse.
