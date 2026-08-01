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
	_check(FileAccess.file_exists(game.STARTUP_THANKS_TEXTURE_PATH), "image file missing")
	_check(is_equal_approx(game.STARTUP_THANKS_HOLD_TIME, 5.0), "thanks screen hold time should be 5s")
	_check(game.textures.get("startup_thanks", null) != null, "image texture not loaded")
	_check(game._startup_thanks_active(), "thanks screen should start active")

	game._update_startup_thanks(game.STARTUP_THANKS_HOLD_TIME - 0.05)
	_check(game._startup_thanks_active(), "thanks screen ended before hold time")
	_check(not game.startup_thanks_fading, "thanks screen started fading too early")

	game._skip_startup_thanks()
	_check(game.startup_thanks_fading, "skip did not start fade")
	game._update_startup_thanks(game.STARTUP_THANKS_FADE_TIME + 0.01)
	_check(not game._startup_thanks_active(), "thanks screen did not finish after fade")

	game._startup_thanks_reset()
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = Vector2(320, 180)
	_check(game._handle_startup_thanks_input(tap), "touch event was not captured")
	_check(game.startup_thanks_fading, "touch did not start fade")
	print("STARTUP_THANKS_SMOKE_OK hold=5.0 fade=0.5 touch_skip=true")
	game.queue_free()
	await process_frame
	game = null
	quit(0)
