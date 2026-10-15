extends SceneTree

const AssetController = preload("res://scripts/systems/assets/runtime_asset_controller.gd")

var game: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("STARTING RUNTIME_ASSET_CONTROLLER_SMOKE")
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	_check(main_scene != null, "Main.tscn must load")
	game = main_scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	game.gfx_memory_saver = true
	for phase in range(1, 8):
		AssetController.prepare_phase(game, phase, "res://assets/sprites/", true)
		for key_value in AssetController.phase_keys(phase):
			var key: String = String(key_value)
			if phase == 3 and key.begins_with("boss3_anim_") and key not in ["boss3_anim_idle", "boss3_anim_walk", "boss3_anim_entry"]:
				_check(not game.textures.has(key), "memory saver retained optional %s" % key)
				continue
			_check(game.textures.has(key), "phase %d did not load %s" % [phase, key])
			_check(_valid_texture_value(game.textures[key]), "phase %d loaded invalid %s" % [phase, key])
		for other_phase in range(1, 8):
			if other_phase == phase:
				continue
			for other_key_value in AssetController.phase_keys(other_phase):
				_check(not game.textures.has(String(other_key_value)), "phase %d retained phase %d key %s" % [phase, other_phase, other_key_value])

	AssetController.prepare_phase(game, 1, "res://assets/sprites/", true)
	_check((game.textures.get("boss1_idle", []) as Array).size() == 2, "memory saver must retain compact Boss 1 idle")
	_check((game.textures.get("boss1_bubble", []) as Array).size() == 2, "memory saver must retain compact Boss 1 attacks")
	_check((game.textures.get("boss1_death", []) as Array).size() == 3, "memory saver must retain Boss 1 death endpoints")
	_check(not game.textures.has("boss7_fly"), "phase transition must release inactive boss art")
	_check(game._ensure_runtime_texture("boss7_fly"), "catalog on-demand load must resolve a future boss")
	_check(_valid_texture_value(game.textures.get("boss7_fly")), "catalog on-demand texture must be valid")

	game.manifest_preview_atlases.clear()
	game.manifest_preview_atlas_lru.clear()
	for index in range(2):
		var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		var texture := ImageTexture.create_from_image(image)
		var cache_key := "mobile_%d" % index
		game.manifest_preview_atlases[cache_key] = texture
		game.manifest_preview_atlas_lru.append(cache_key)
	game._trim_manifest_preview_atlas_cache()
	_check(game.manifest_preview_atlases.size() == 1, "low-memory preview cache must retain one atlas")

	if game.has_method("_cleanup_runtime_resources"):
		game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	main_scene = null
	for _frame in range(4):
		await process_frame
	print("RUNTIME_ASSET_CONTROLLER_SMOKE_OK phases=7 compact_boss1=true catalog_lazy=true preview_cache=1")
	quit(0)


func _valid_texture_value(value: Variant) -> bool:
	if value is Texture2D:
		return true
	if value is Array and not value.is_empty():
		return value.all(func(frame): return frame is Texture2D)
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("RUNTIME_ASSET_CONTROLLER_SMOKE_FAIL: " + message)
	print("RUNTIME_ASSET_CONTROLLER_SMOKE_FAIL: " + message)
	quit(1)
