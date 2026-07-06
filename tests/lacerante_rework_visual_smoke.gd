extends SceneTree

var game: Node


func _save_view(file_name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	var output = "res://.codex/" + file_name
	assert(image.save_png(output) == OK)
	print("LACERANTE_REWORK_VISUAL_OK " + ProjectSettings.globalize_path(output))


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	game.selected_manifestation = 1
	game._start_game()
	game.manifestation_key = "lacerante"
	game.selected_manifestation = 1
	game.player_pos = Vector2(1280, 720)
	game.last_facing = Vector2.RIGHT
	game.spawn_timer = 9999.0
	game.boss_dead = true
	game.enemies.clear()
	for offset in [Vector2(112, 0), Vector2(-92, 58), Vector2(18, -126)]:
		game._spawn_enemy(game.ENEMY_PROJECTOR, game.player_pos + offset)
		var enemy: Dictionary = game.enemies[-1]
		enemy["hp"] = 800.0
		enemy["max_hp"] = 800.0
		enemy["stun"] = 999.0
	game.lacerante_coagula = 1234
	game.lacerante_coagulum_pulse = 1.0
	game.time_alive = 30.0
	game.last_lacerante_empower_time = 25.0
	game.lacerante_empowered_ready = true
	game.last_skill_time = -999.0
	game._use_skill()
	for slash in game.slashes:
		if String(slash.get("kind", "")) == "lacerante_spin":
			slash["life"] = 0.31
	await _save_view("lacerante_rework_1280x720.png")
	game._open_manifest_select()
	game.selected_manifestation = 1
	game.manifest_scroll_pos = 1.0
	await _save_view("lacerante_manifest_screen_1280x720.png")
	game.manifest_preview_open = true
	game.manifest_preview_kind = "skill"
	game.manifest_preview_time = 0.34
	await _save_view("lacerante_preview_q_1280x720.png")
	quit(0)
