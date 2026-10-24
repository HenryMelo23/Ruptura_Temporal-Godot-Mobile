extends SceneTree

const OUT_MOBILE := "res://.agent_logs/parasitica_skill_mobile_hold_960x540.png"
const OUT_DESKTOP := "res://.agent_logs/parasitica_skill_desktop_hold_960x540.png"

var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _capture(path: String) -> void:
	for frame in range(6):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != Vector2i(960, 540) or image.save_png(path) != OK:
		push_error("PARASITICA_SKILL_AIM_VISUAL_FAIL %s expected=960x540 actual=%s window=%s" % [path, image.get_size() if image != null else Vector2i.ZERO, root.size])
		quit(1)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("PARASITICA_SKILL_AIM_VISUAL requires a renderer")
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
	game.player_pos = Vector2(720.0, 460.0)
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

	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	game._update_button_layout(Vector2(960, 540))
	var skill_center: Vector2 = game.buttons["skill"].get_center()
	game._handle_touch_press(31, skill_center, Vector2(960, 540))
	game._handle_touch_drag(31, skill_center + Vector2(60.0, -20.0), Vector2(960, 540))
	await _capture(OUT_MOBILE)
	game._cancel_touch_index(31)

	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game._update_button_layout(Vector2(960, 540))
	game.get_viewport().warp_mouse(Vector2(610.0, 220.0))
	game._begin_desktop_aim("skill", game._key_input_binding(KEY_Q), true)
	await _capture(OUT_DESKTOP)

	print("PARASITICA_SKILL_AIM_VISUAL_OK mobile_hold=960x540 desktop_hold=960x540 reticle=true")
	game._cleanup_runtime_resources()
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
