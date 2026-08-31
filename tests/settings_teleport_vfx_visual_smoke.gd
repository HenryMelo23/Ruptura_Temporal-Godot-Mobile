extends SceneTree

const OUT_DIR := "res://.codex"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("SETTINGS_TELEPORT_VFX_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.mode = "settings"
	game.settings_previous_mode = "menu"
	game.settings_selected = game._settings_index_for("graphics")
	await _capture("settings_rework_1280x720.png")

	game._start_game()
	game.mode = "game"
	game.is_multiplayer = false
	game.qa_streaming_enabled = false
	game.time_alive = 30.0
	game.player_pos = Vector2(300, 360)
	game.last_facing = Vector2.RIGHT
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(460, 340))
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(560, 390))
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(690, 350))
	for enemy in game.enemies:
		enemy["hp"] = 5000.0
		enemy["max_hp"] = 5000.0
		enemy["stun"] = 999.0

	_prepare_tp_effects(["eletrica", "necronada", "lacerante", "ancorada", "parasitica"])
	await _capture("teleport_vfx_pack_a_1280x720.png")
	_prepare_tp_effects(["gravitante", "prismatica", "cartografica", "contratual", "mnesica"])
	await _capture("teleport_vfx_pack_b_1280x720.png")

	print("SETTINGS_TELEPORT_VFX_VISUAL_OK settings=true teleports=10 captures=3")
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	game.queue_free()
	for i in range(4):
		await process_frame
	quit(0)


func _prepare_tp_effects(keys: Array) -> void:
	game.tp_effects.clear()
	game.slashes.clear()
	game.prisms.clear()
	game.carto_tp_window = 0.0
	game.tp_cooldown_pending = false
	game.tp_cooldown_release_time = -1.0
	game.tp_cooldown_override = -1.0
	var start := Vector2(240, 250)
	for i in range(keys.size()):
		var key := String(keys[i])
		var origin := start + Vector2(0, float(i) * 58.0)
		var destination := origin + Vector2(330, 0)
		game.player_pos = origin
		game.manifestation_key = key
		if key == "lacerante":
			game.slashes.append({"a": origin, "b": destination, "life": 3.0, "max": 3.0, "color": Color(1.0, 0.1, 0.18), "width": 42.0, "kind": "lacerante_tp"})
		if key == "cartografica":
			game._start_cartografica_teleport_pin(origin, destination)
		else:
			game._start_manifestation_teleport_effect(origin, destination)
	for effect in game.tp_effects:
		effect["life"] = float(effect.get("max", effect.get("life", 0.5))) * 0.52


func _capture(file_name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless":
		print("SETTINGS_TELEPORT_VFX_CAPTURE logic_only=true file=", file_name)
		return
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == 1280 and image.get_height() == 720, "invalid capture " + file_name)
	_check(image.get_used_rect().size.x > 1000 and image.get_used_rect().size.y > 600, "blank capture " + file_name)
	_check(image.save_png(OUT_DIR + "/" + file_name) == OK, "could not save " + file_name)
