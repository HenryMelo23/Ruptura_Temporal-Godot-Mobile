extends SceneTree

const OUT_DIR := "res://.agent_logs/parasitica_fire_runtime"

var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _capture(path: String) -> void:
	for frame in range(5):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != Vector2i(960, 540) or image.save_png(path) != OK:
		push_error("PARASITICA_FIRE_FRAMES_VISUAL_FAIL %s actual=%s" % [path, image.get_size() if image != null else Vector2i.ZERO])
		quit(1)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("PARASITICA_FIRE_FRAMES_VISUAL requires a renderer")
		quit(1)
		return
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.run_tutorial_enabled = false
	game._start_game()
	game._finish_startup_thanks()
	game.mode = "game"
	game.manifestation_key = "parasitica"
	game.selected_manifestation = game._manifestation_index_for_key("parasitica", -1)
	game.player_pos = Vector2(480.0, 320.0)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.gfx_screen_shake = false
	game.mobile_adaptive_visual_budget = false
	game.time_alive = 50.0
	game.process_mode = Node.PROCESS_MODE_DISABLED
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	await process_frame
	root.min_size = Vector2i.ZERO
	root.content_scale_size = Vector2i.ZERO
	DisplayServer.window_set_size(Vector2i(960, 540))
	await create_timer(0.35).timeout
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	game.last_attack_time = -999.0
	await _capture(OUT_DIR + "/idle_960x540.png")
	var fire_directions: Array[Dictionary] = [
		{"name": "east", "direction": Vector2.RIGHT},
		{"name": "north", "direction": Vector2.UP},
		{"name": "northeast", "direction": Vector2(1.0, -1.0).normalized()},
		{"name": "northwest", "direction": Vector2(-1.0, -1.0).normalized()},
		{"name": "south", "direction": Vector2.DOWN},
		{"name": "southeast", "direction": Vector2(1.0, 1.0).normalized()},
		{"name": "southwest", "direction": Vector2(-1.0, 1.0).normalized()},
	]
	for fire_direction in fire_directions:
		for frame_index in range(2):
			game.player_attack_visual_dir = Vector2(fire_direction["direction"])
			game.last_attack_time = game.time_alive - game.PLAYER_FIRE_FRAME_SECONDS * (0.2 if frame_index == 0 else 1.2)
			await _capture("%s/%s_%d_960x540.png" % [OUT_DIR, fire_direction["name"], frame_index])

	print("PARASITICA_FIRE_FRAMES_VISUAL_OK idle=960x540 fire_frames=14x960x540 draw_height=84")
	game._cleanup_runtime_resources()
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
