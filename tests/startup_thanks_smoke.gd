extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("STARTUP_THANKS_SMOKE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_force_startup_teaser_for_test()
	_check(game._startup_thanks_frame_exists(1), "first teaser frame missing")
	_check(game._startup_thanks_frame_exists(game.STARTUP_THANKS_FRAME_COUNT), "last teaser frame missing")
	_check(game._resource_or_file_exists(game.STARTUP_THANKS_AUDIO_PATH), "teaser audio file missing")
	_check(game.startup_thanks_frame_view != null, "teaser frame view was not created")
	_check(game.startup_thanks_teaser_available, "teaser frame player was not loaded")
	_check(game._startup_thanks_active(), "startup teaser should start active")

	game._update_startup_thanks(0.25)
	_check(game._startup_thanks_active(), "startup teaser ended before video finish")
	_check(not game.startup_thanks_fading, "startup teaser started fading too early")
	_check(game.startup_thanks_frame_index >= 1, "teaser did not advance to a real frame")

	game._update_startup_thanks(game._startup_thanks_duration() + 0.01)
	_check(game.startup_thanks_fading, "teaser duration did not start fade")
	game._update_startup_thanks(game.STARTUP_THANKS_FADE_TIME + 0.01)
	_check(not game._startup_thanks_active(), "startup teaser did not finish after fade")

	game._startup_thanks_reset()
	_force_startup_teaser_for_test()
	game._skip_startup_thanks()
	_check(game.startup_thanks_fading, "skip did not start fade")
	game._update_startup_thanks(game.STARTUP_THANKS_FADE_TIME + 0.01)
	_check(not game._startup_thanks_active(), "startup teaser did not finish after skip fade")

	game._startup_thanks_reset()
	_force_startup_teaser_for_test()
	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	var skip_count_before: int = int(game.startup_thanks_skip_count)
	var disabled_before: bool = bool(game.startup_video_disabled)
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = Vector2(320, 180)
	_check(game._handle_startup_thanks_input(tap), "touch event was not captured")
	_check(game.startup_thanks_holding, "touch did not start holding state")
	game._update_startup_thanks(game.STARTUP_THANKS_SKIP_HOLD_TIME + 0.05)
	_check(game.startup_thanks_fading, "holding touch did not start fade after 3s hold")
	_check(game.startup_thanks_skip_count == skip_count_before + 1, "skip count did not increment after 3s hold")
	game.startup_thanks_skip_count = skip_count_before
	game.startup_video_disabled = disabled_before
	game._save_startup_video_config()

	game._startup_thanks_reset()
	_force_startup_teaser_for_test()
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = Vector2(320, 180)
	_check(game._handle_startup_thanks_input(mouse), "desktop mouse event was not captured")
	_check(not game.startup_thanks_holding, "desktop left-click should not start teaser hold")
	var wrong_key := InputEventKey.new()
	wrong_key.keycode = KEY_SPACE
	wrong_key.pressed = true
	_check(game._handle_startup_thanks_input(wrong_key), "desktop non-esc key was not captured")
	_check(not game.startup_thanks_holding, "desktop non-esc key should not start teaser hold")
	var desktop_skip_count_before: int = int(game.startup_thanks_skip_count)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	_check(game._handle_startup_thanks_input(esc), "desktop esc key was not captured")
	_check(game.startup_thanks_holding, "desktop esc did not start teaser hold")
	game._update_startup_thanks(game.STARTUP_THANKS_SKIP_HOLD_TIME + 0.05)
	_check(game.startup_thanks_fading, "desktop esc hold did not start fade after 3s hold")
	_check(game.startup_thanks_skip_count == desktop_skip_count_before + 1, "desktop esc hold did not increment skip count")
	game.startup_thanks_skip_count = desktop_skip_count_before
	game.startup_video_disabled = disabled_before
	game._save_startup_video_config()
	print("STARTUP_THANKS_SMOKE_OK teaser=true fade=0.5 touch_hold=true esc_hold=true")
	game._finish_startup_thanks()
	game.queue_free()
	for i in range(4):
		await process_frame
	game = null
	quit(0)


func _force_startup_teaser_for_test() -> void:
	game.startup_thanks_skip_count = 0
	game.startup_video_disabled = false
	game.startup_thanks_done = false
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	game.startup_thanks_frame_index = 1
	game.startup_thanks_teaser_available = game._resource_or_file_exists(game.STARTUP_THANKS_AUDIO_PATH) and game._startup_thanks_frame_exists(1)
	if game.startup_thanks_frame_view != null:
		game.startup_thanks_frame_view.visible = true
		game.startup_thanks_frame_view.texture = game._get_startup_thanks_frame_texture(1)
