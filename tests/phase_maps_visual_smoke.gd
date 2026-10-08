extends SceneTree

const MAP_PHASES := [1, 2, 3, 4, 5, 6, 7, 9]
var game: Node2D
var output_dir := "res://.agent_logs/phase_maps/before"
var failed := false


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			output_dir = argument.trim_prefix("--out=")
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("PHASE_MAPS_VISUAL_FAIL " + message)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("PHASE_MAPS_VISUAL_FAIL requires a rendering display")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.startup_thanks_done = true
	game.startup_thanks_frame_view.hide()
	game.mode = "game"
	game.player_pos = game.WORLD_SIZE * 0.5
	game.player_hp = game.player_hp_max
	game.time_alive = 8.0
	game.screen_shake_timer = 0.0
	game.boss_active = false
	game.enemies.clear()
	game.show_fps_counter = false
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	for mobile in [false, true]:
		var size := Vector2i(960, 540) if mobile else Vector2i(1280, 720)
		root.size = size
		DisplayServer.window_set_size(size)
		await process_frame
		await process_frame
		game.ui_platform_override = game.UI_PLATFORM_ANDROID if mobile else game.UI_PLATFORM_DESKTOP
		game.gfx_low_resource = mobile
		for phase in MAP_PHASES:
			game.current_phase = 5 if phase == 9 else phase
			game.boss5_dimension = "rastro" if phase == 9 else "base"
			game.phase5_transmute_active = false
			var texture: Texture2D = game._current_map_texture()
			_check(texture != null, "missing map %d" % phase)
			game.queue_redraw()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var capture := root.get_texture().get_image()
			_check(capture != null and not capture.is_empty(), "empty screenshot")
			_check(capture.get_size() == size, "unexpected screenshot dimensions")
			var path := "%s/phase_%d_%s.png" % [output_dir, phase, "mobile" if mobile else "desktop"]
			_check(capture.save_png(path) == OK, "cannot save " + path)
			print("PHASE_MAP_CAPTURE ", path)
			game.rng.seed = 37
			for offset in [Vector2(-210, -90), Vector2(220, 80), Vector2(-110, 160)]:
				game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + offset)
			game.queue_redraw()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			_check(root.get_texture().get_image().save_png(path.trim_suffix(".png") + "_enemies.png") == OK, "enemy readability capture")
			game.enemies.clear()
	if is_instance_valid(game.phase_map_layer):
		var layer: Node2D = game.phase_map_layer
		game.current_phase = 5
		game.phase5_transmute_old_tex = game._get_texture("map_phase_5")
		game.phase5_transmute_new_tex = game._get_texture("map_phase_2")
		game.boss5_dimension = "gravidade"
		game.phase5_transmute_active = true
		for progress in [0.0, 0.25, 0.5, 0.75, 1.0]:
			game.phase5_transmute_timer = progress * game.phase5_transmute_duration
			game.queue_redraw()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			_check(not layer.visible, "animated base overlaps UMBRA transition")
			_check(root.get_texture().get_image().save_png("%s/transmute_%03d.png" % [output_dir, int(progress * 100)]) == OK, "transition capture")
		game.phase5_transmute_active = false
		game.queue_redraw()
		await process_frame
		await process_frame
		_check(layer.visible, "animated surface did not resume after transition")
		_check(game.phase_map_layer == layer, "phase switch created another renderer")
		game.mode = "menu"
		game.queue_redraw()
		await process_frame
		await process_frame
		_check(not layer.visible, "map leaked into menu")
	game.queue_free()
	await process_frame
	await process_frame
	print("PHASE_MAPS_VISUAL_", "FAIL" if failed else "OK", " maps=8 sizes=1280x720,960x540")
	quit(1 if failed else 0)
