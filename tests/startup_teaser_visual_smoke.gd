extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("STARTUP_TEASER_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name().to_lower().contains("headless"):
		print("STARTUP_TEASER_VISUAL_OK headless_skip")
		quit(0)
		return
	for i in range(90):
		await process_frame
	_check(game._startup_thanks_active(), "startup teaser should still be visible after 90 frames")
	_check(game.startup_thanks_frame_view != null and game.startup_thanks_frame_view.visible, "teaser frame view is not visible")
	var outputs := []
	outputs.append(await _capture_at_time(3.0, "res://.codex/startup_teaser_03s.png"))
	outputs.append(await _capture_at_time(12.0, "res://.codex/startup_teaser_12s.png"))
	outputs.append(await _capture_at_time(28.0, "res://.codex/startup_teaser_28s.png"))
	print("STARTUP_TEASER_VISUAL_OK " + ", ".join(outputs))
	game.queue_free()
	await process_frame
	game = null
	quit(0)


func _capture_at_time(seconds: float, output: String) -> String:
	game.startup_thanks_timer = seconds
	game.startup_thanks_fading = false
	game._update_startup_thanks(0.0)
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() > 0 and image.get_height() > 0, "could not capture viewport image")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	_check(image.save_png(output) == OK, "could not save startup teaser screenshot")
	return ProjectSettings.globalize_path(output)
