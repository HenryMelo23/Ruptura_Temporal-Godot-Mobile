extends SceneTree

const OUTPUT_DIR := "res://.codex/phase1_enemy_tuning"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PHASE1_ENEMY_TUNING_VISUAL_FAIL " + message)
	quit(1)


func _capture(filename: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_check(image != null, "missing_image")
	_check(image.get_size() == Vector2i(960, 540), "wrong_size")
	var path: String = ProjectSettings.globalize_path(OUTPUT_DIR.path_join(filename))
	_check(image.save_png(path) == OK, "save_failed")


func _initialize() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(960, 540)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	game._finish_startup_thanks()
	game._start_game()
	game.set_process(false)
	game.set_physics_process(false)
	game.mode = "game"
	game.run_tutorial_enabled = false
	game.time_alive = 0.0
	game.player_pos = Vector2(480.0, 270.0)
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_STALKER, game.player_pos + Vector2(150.0, 0.0))
	var stalker: Dictionary = game.enemies[-1]
	stalker["phase"] = 0.0
	stalker["bit"] = 0
	stalker["sprint_active"] = false
	stalker["sprint_timer"] = 0.0
	game._update_stalker(stalker, 0.0)
	_check(is_equal_approx(float(stalker.get("alpha", 1.0)), 0.75), "stalker_alpha_not_75_percent")
	var tuned_alpha: float = float(stalker["alpha"])
	stalker["alpha"] = 1.0
	await _capture("stalker_before_960x540.png")
	stalker["alpha"] = tuned_alpha
	await _capture("stalker_after_960x540.png")
	print("PHASE1_ENEMY_TUNING_VISUAL_OK alpha=%.2f output=%s" % [float(stalker.get("alpha", 1.0)), ProjectSettings.globalize_path(OUTPUT_DIR)])
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for index in range(4):
		await process_frame
	quit(0)
