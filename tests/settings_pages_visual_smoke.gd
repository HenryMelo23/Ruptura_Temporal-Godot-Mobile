extends SceneTree

const OUT_DIR := "res://.codex"

var game: Node


func _fail(message: String) -> void:
	push_error("SETTINGS_PAGES_VISUAL_FAIL " + message)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.settings_previous_mode = "menu"
	game.ui_platform_override = "desktop"
	game.ui_platform_override_unlocked = true
	game.qa_streaming_unlocked = false

	await _capture_mode("settings", Vector2i(1280, 720), "settings_hub_1280x720.png")
	await _capture_mode("settings_keys", Vector2i(1280, 720), "settings_keys_1280x720.png")
	await _capture_mode("settings_gameplay", Vector2i(1280, 720), "settings_gameplay_1280x720.png")
	await _capture_mode("settings_audio", Vector2i(1280, 720), "settings_audio_1280x720.png")
	await _capture_mode("settings_graphics", Vector2i(1280, 720), "settings_graphics_1280x720.png")
	await _capture_mode("settings_audio", Vector2i(960, 540), "settings_audio_960x540.png")

	_check_audio_drag(Vector2(1280, 720))

	print("SETTINGS_PAGES_VISUAL_OK captures=6 hitboxes=true audio_drag=true")
	game.queue_free()
	await process_frame
	quit(0)


func _capture_mode(target_mode: String, viewport: Vector2i, file_name: String) -> void:
	root.size = viewport
	game.mode = target_mode
	game.settings_selected = 0
	game.audio_slider_drag_index = -1
	_check_layouts(Vector2(viewport), target_mode)
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null, "null capture " + file_name)
	_check(image.get_width() == viewport.x and image.get_height() == viewport.y, "wrong capture size " + file_name)
	_check(image.get_used_rect().size.x > viewport.x * 0.72 and image.get_used_rect().size.y > viewport.y * 0.62, "blank capture " + file_name)
	_check(image.save_png(OUT_DIR + "/" + file_name) == OK, "could not save " + file_name)


func _check_layouts(viewport: Vector2, target_mode: String) -> void:
	var rects: Dictionary = {}
	match target_mode:
		"settings":
			rects = game._settings_rects(viewport)
		"settings_keys":
			rects = game._keyboard_settings_rects(viewport)
		"settings_gameplay":
			rects = game._gameplay_preferences_rects(viewport)
		"settings_audio":
			rects = game._audio_settings_rects(viewport)
		"settings_graphics":
			rects = game._graphics_settings_rects(viewport)
		_:
			return
	for key in rects.keys():
		var rect: Rect2 = rects[key]
		_check(rect.size.x > 24.0 and rect.size.y > 24.0, "%s tiny rect %s" % [target_mode, key])
		_check(rect.position.x >= -1.0 and rect.position.y >= -1.0, "%s offscreen start %s" % [target_mode, key])
		_check(rect.end.x <= viewport.x + 1.0 and rect.end.y <= viewport.y + 1.0, "%s offscreen end %s" % [target_mode, key])
	var keys: Array = rects.keys()
	for i in range(keys.size()):
		for j in range(i + 1, keys.size()):
			var a_key: String = String(keys[i])
			var b_key: String = String(keys[j])
			if a_key == "panel" or b_key == "panel":
				continue
			_check(not Rect2(rects[a_key]).intersects(Rect2(rects[b_key]), true), "%s overlap %s/%s" % [target_mode, a_key, b_key])


func _check_audio_drag(viewport: Vector2) -> void:
	root.size = Vector2i(viewport)
	game.mode = "settings_audio"
	game.vol_music = 0.1
	var rects: Dictionary = game._audio_settings_rects(viewport)
	var panel: Rect2 = rects["panel"]
	var slider: Rect2 = game._audio_slider_rect(panel, 1)
	game._handle_audio_settings_touch(Vector2(slider.position.x + slider.size.x * 0.82, slider.get_center().y), viewport)
	_check(game.audio_slider_drag_index == 1, "music slider did not enter drag")
	_check(game.vol_music > 0.75 and game.vol_music < 0.9, "music slider did not set from press")
	game._update_audio_slider_from_pos(Vector2(slider.position.x + slider.size.x * 0.28, slider.get_center().y), viewport)
	_check(game.vol_music > 0.2 and game.vol_music < 0.35, "music slider did not update from drag")
	game.audio_slider_drag_index = -1
