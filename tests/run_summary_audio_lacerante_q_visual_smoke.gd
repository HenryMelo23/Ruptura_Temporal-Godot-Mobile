extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _save_view(file_name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.get_width() < 1280 or image.get_height() < 720:
		push_error("RUN_SUMMARY_VISUAL_FAIL invalid capture " + file_name)
		quit(1)
		return
	var output = "res://.codex/" + file_name
	if image.save_png(output) != OK:
		push_error("RUN_SUMMARY_VISUAL_FAIL could not save " + file_name)
		quit(1)
		return
	print("RUN_SUMMARY_VISUAL_OK " + ProjectSettings.globalize_path(output))


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	game.selected_manifestation = 1
	game._start_game()
	game.startup_thanks_done = true
	game.startup_thanks_timer = 0.0
	game.startup_thanks_fading = false
	game.manifestation_key = "lacerante"
	game.time_alive = 754.0
	game.enemies_killed = 287
	game.run_points_earned = 18420
	game.run_points_spent = 7600
	game.current_phase = 2
	game.cards_bought[game.CARDS[0]["name"]] = 12
	game.cards_bought[game.CARDS[1]["name"]] = 7
	game.mode = "game_over"
	await _save_view("run_summary_game_over_1280x720.png")

	game.current_phase = 3
	game.mode = "victory"
	await _save_view("run_summary_victory_1280x720.png")

	game.vol_master = 1.0
	game.vol_music = 0.7
	game.vol_sfx = 0.4
	game.vol_shots = 0.0
	game.mode = "settings_audio"
	await _save_view("audio_shots_setting_1280x720.png")

	game.mode = "game"
	game.player_pos = Vector2(1280, 720)
	game.enemies.clear()
	game.spawn_timer = 9999.0
	game.boss_dead = true
	game.last_skill_time = -999.0
	game._use_skill()
	for slash in game.slashes:
		if String(slash.get("kind", "")) == "lacerante_spin":
			slash["life"] = game.LACERANTE_Q_DURATION * 0.52
	await _save_view("lacerante_q_five_rotations_1280x720.png")
	quit(0)
