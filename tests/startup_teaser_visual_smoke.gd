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
	await process_frame
	_force_startup_teaser_for_test()
	for i in range(90):
		await process_frame
	_check(game._startup_thanks_active(), "startup teaser should still be visible after 90 frames")
	_check(game.startup_thanks_frame_view != null and game.startup_thanks_frame_view.visible, "teaser frame view is not visible")
	var outputs := []
	outputs.append(await _capture_at_time(3.0, "res://.codex/startup_teaser_03s.png"))
	outputs.append(await _capture_at_time(12.0, "res://.codex/startup_teaser_12s.png"))
	outputs.append(await _capture_at_time(28.0, "res://.codex/startup_teaser_28s.png"))
	outputs.append(await _capture_hold_indicator(false, "res://.codex/startup_teaser_hold_mobile.png"))
	outputs.append(await _capture_hold_indicator(true, "res://.codex/startup_teaser_hold_desktop.png"))
	print("STARTUP_TEASER_VISUAL_OK " + ", ".join(outputs))
	game.queue_free()
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
	game.startup_thanks_teaser_available = FileAccess.file_exists(game.STARTUP_THANKS_AUDIO_PATH) and game._startup_thanks_frame_exists(1)
	if game.startup_thanks_frame_view != null:
		game.startup_thanks_frame_view.visible = true
		game.startup_thanks_frame_view.texture = game._get_startup_thanks_frame_texture(1)


func _capture_at_time(seconds: float, output: String) -> String:
	game.startup_thanks_timer = seconds
	game.startup_thanks_fading = false
	game._update_startup_thanks(0.0)
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() > 0 and image.get_height() > 0, "could not capture viewport image")
	_check(_image_matches_teaser_frame(image, game.startup_thanks_frame_index), "captured viewport is not showing the startup teaser frame")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	_check(image.save_png(output) == OK, "could not save startup teaser screenshot")
	return ProjectSettings.globalize_path(output)


func _capture_hold_indicator(desktop: bool, output: String) -> String:
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP if desktop else game.UI_PLATFORM_ANDROID
	game.startup_thanks_timer = 4.0
	game.startup_thanks_fading = false
	game.startup_thanks_holding = true
	game.startup_thanks_hold_timer = game.STARTUP_THANKS_SKIP_HOLD_TIME * 0.5
	game.startup_thanks_hold_pos = Vector2(640, 360)
	game._update_startup_thanks(0.0)
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() > 0 and image.get_height() > 0, "could not capture hold indicator image")
	_check(_image_matches_teaser_frame(image, game.startup_thanks_frame_index, false), "hold indicator capture is not showing the startup teaser frame")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	_check(image.save_png(output) == OK, "could not save hold indicator screenshot")
	game.startup_thanks_holding = false
	game.startup_thanks_hold_timer = 0.0
	return ProjectSettings.globalize_path(output)


func _image_matches_teaser_frame(captured: Image, frame_index: int, include_center: bool = true) -> bool:
	var expected_tex: Texture2D = game._get_startup_thanks_frame_texture(frame_index)
	if expected_tex == null:
		return false
	var expected := expected_tex.get_image()
	if expected == null:
		return false
	var sample_points := [
		Vector2(0.25, 0.25),
		Vector2(0.75, 0.35),
		Vector2(0.35, 0.72),
		Vector2(0.82, 0.78),
	]
	if include_center:
		sample_points.append(Vector2(0.5, 0.5))
	var total_diff := 0.0
	for point in sample_points:
		var captured_pos := Vector2i(
			clampi(int(point.x * float(captured.get_width() - 1)), 0, captured.get_width() - 1),
			clampi(int(point.y * float(captured.get_height() - 1)), 0, captured.get_height() - 1)
		)
		var expected_pos := Vector2i(
			clampi(int(point.x * float(expected.get_width() - 1)), 0, expected.get_width() - 1),
			clampi(int(point.y * float(expected.get_height() - 1)), 0, expected.get_height() - 1)
		)
		var a := captured.get_pixelv(captured_pos)
		var b := expected.get_pixelv(expected_pos)
		total_diff += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
	return total_diff / float(sample_points.size()) < 0.18
