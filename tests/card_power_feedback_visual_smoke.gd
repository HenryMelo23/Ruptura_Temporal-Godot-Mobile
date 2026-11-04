extends SceneTree

const OUTPUT_DIR := "res://.codex/card_power_feedback"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("CARD_POWER_FEEDBACK_VISUAL_FAIL " + message)
	quit(1)


func _capture(filename: String, expected_size: Vector2i) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_check(image != null, "missing_image_%s" % filename)
	_check(image.get_size() == expected_size, "wrong_size_%s_expected_%s_actual_%s" % [filename, expected_size, image.get_size()])
	var path: String = ProjectSettings.globalize_path(OUTPUT_DIR.path_join(filename))
	_check(image.save_png(path) == OK, "save_failed_%s" % filename)


func _populate_feedback(center: Vector2) -> void:
	game.player_pos = center
	game.effects.clear()
	game.common_card_effects = [
		{"kind": "card_power_acquired", "pos": center, "life": 0.62, "max": 0.92, "radius": 104.0, "power": 1.65, "color": Color(0.24, 0.72, 1.0)},
		{"kind": "card_speed_trail", "pos": center + Vector2(-130.0, 42.0), "from": center + Vector2(-240.0, 42.0), "life": 0.21, "max": 0.28, "radius": 52.0, "stacks": 5, "color": Color(0.0, 1.0, 0.78)},
		{"kind": "card_power_hit", "pos": center + Vector2(225.0, -70.0), "origin": center, "life": 0.25, "max": 0.34, "radius": 54.0, "stacks": 5, "color": Color(1.0, 0.3, 0.22)},
		{"kind": "card_critical_hit", "pos": center + Vector2(220.0, 78.0), "life": 0.31, "max": 0.42, "radius": 64.0, "stacks": 6, "color": Color(1.0, 0.82, 0.18)},
		{"kind": "card_lifesteal", "pos": center + Vector2(-230.0, -88.0), "target": center, "life": 0.27, "max": 0.36, "radius": 40.0, "heal": 12, "color": Color(0.95, 0.1, 0.34)},
		{"kind": "card_defense_block", "pos": center + Vector2(-62.0, 4.0), "life": 0.29, "max": 0.38, "radius": 64.0, "blocked": 44.0, "color": Color(0.58, 0.86, 1.0)},
		{"kind": "card_overkill", "pos": center + Vector2(330.0, 10.0), "life": 0.34, "max": 0.48, "radius": 78.0, "power": 0.8, "color": Color(1.0, 0.48, 0.18)},
		{"kind": "enemy_threat_impact", "pos": center + Vector2(-310.0, 70.0), "life": 0.4, "max": 0.55, "radius": 72.0, "source": "visual_smoke", "color": Color(1.0, 0.16, 0.12)},
	]
	game._add_text("PODER  TEMPESTADE x6", center + Vector2(0.0, -132.0), Color(0.24, 0.72, 1.0), 1.05, 20)
	game._add_text("CRITICO!", center + Vector2(220.0, 22.0), Color(1.0, 0.82, 0.18), 0.85, 18)
	game._add_text("AMEACA", center + Vector2(-310.0, 8.0), Color(1.0, 0.36, 0.18), 0.85, 17)
	_check(game.common_card_effects.size() == 8, "feedback_setup_incomplete")


func _initialize() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(1280, 720)
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
	game.mode = "game"
	game.run_tutorial_enabled = false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)

	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game.gfx_memory_saver = false
	_populate_feedback(Vector2(640.0, 360.0))
	await _capture("card_power_feedback_1280x720.png", Vector2i(1280, 720))

	root.size = Vector2i(960, 540)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game.gfx_memory_saver = true
	_populate_feedback(Vector2(480.0, 270.0))
	await _capture("card_power_feedback_memory_saver_960x540.png", Vector2i(960, 540))

	print("CARD_POWER_FEEDBACK_VISUAL_OK desktop=true mobile_landscape=true memory_saver=true primitives_only=true output=%s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for index in range(4):
		await process_frame
	quit(0)
