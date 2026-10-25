extends SceneTree

const OUTPUT_DIR := "res://.agent_logs/point_boost_visual"

var game: Node
var failed := false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("POINT_BOOST_VISUAL_FAIL " + message)


func _capture(filename: String, expected_size: Vector2i) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_check(image != null, "missing image " + filename)
	_check(image.get_size() == expected_size, "wrong viewport " + filename)
	_check(image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR.path_join(filename))) == OK, "save failed " + filename)


func _set_viewport(size: Vector2i, platform: String) -> void:
	root.size = size
	root.content_scale_size = size
	DisplayServer.window_set_size(size)
	game.ui_platform_override_unlocked = true
	game.ui_platform_override = platform


func _initialize() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	game._finish_startup_thanks()
	game._start_game()
	game.set_process(false)
	game.run_tutorial_enabled = false
	game.mode = "game"
	game.vol_master = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(1600, 1100)
	game.enemies.clear()
	game.heal_orbs.clear()
	game.time_alive = 360.0
	game._spawn_gameplay_orb(game.POINT_BOOST_PICKUP_KIND, game.player_pos + Vector2(185, 35), {"collect_radius": 66.0, "artifact": true, "spawn_time": 359.0}, 0, 16.0)
	game.heal_orbs[-1]["life"] = 15.0
	_set_viewport(Vector2i(1280, 720), "desktop")
	await _capture("pickup_desktop_1280x720.png", Vector2i(1280, 720))
	game.time_alive = 361.1
	await _capture("pickup_idle_pulse_1280x720.png", Vector2i(1280, 720))

	game.heal_orbs.clear()
	game.point_boost_pickup_controller.reset()
	_check(game.point_boost_pickup_controller.activate(1, true), "could not activate visual HUD state")
	await _capture("buff_hud_desktop_1280x720.png", Vector2i(1280, 720))
	game.point_boost_pickup_controller.update(9.5, true)
	await _capture("buff_hud_final_warning_1280x720.png", Vector2i(1280, 720))

	_set_viewport(Vector2i(960, 540), "android")
	await _capture("buff_hud_android_960x540.png", Vector2i(960, 540))
	game.point_boost_pickup_controller.reset()
	game.heal_orbs.clear()
	game.time_alive = 364.0
	game._spawn_gameplay_orb(game.POINT_BOOST_PICKUP_KIND, game.player_pos + Vector2(150, 35), {"collect_radius": 66.0, "artifact": true, "spawn_time": 363.0}, 0, 16.0)
	game.heal_orbs[-1]["life"] = 15.0
	await _capture("pickup_android_960x540.png", Vector2i(960, 540))

	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	if not failed:
		print("POINT_BOOST_VISUAL_SMOKE_OK pickup medal idle pulse shadow desktop android hud timer warning")
	quit(1 if failed else 0)
