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
	_check(game._startup_thanks_frame_exists(1), "first teaser frame missing")
	_check(game._startup_thanks_frame_exists(game.STARTUP_THANKS_FRAME_COUNT), "last teaser frame missing")
	_check(FileAccess.file_exists(game.STARTUP_THANKS_AUDIO_PATH), "teaser audio file missing")
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
	game._skip_startup_thanks()
	_check(game.startup_thanks_fading, "skip did not start fade")
	game._update_startup_thanks(game.STARTUP_THANKS_FADE_TIME + 0.01)
	_check(not game._startup_thanks_active(), "startup teaser did not finish after skip fade")

	game._startup_thanks_reset()
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = Vector2(320, 180)
	_check(game._handle_startup_thanks_input(tap), "touch event was not captured")
	_check(game.startup_thanks_fading, "touch did not start fade")
	print("STARTUP_THANKS_SMOKE_OK teaser=true fade=0.5 touch_skip=true")
	game._finish_startup_thanks()
	game.queue_free()
	for i in range(4):
		await process_frame
	game = null
	quit(0)
