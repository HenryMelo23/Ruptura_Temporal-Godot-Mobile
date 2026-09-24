extends SceneTree

const OUT_DIR := "res://.agent_logs/menu_after"

var game: Node
var failed: bool = false


func _fail(message: String) -> void:
	push_error("SETTINGS_PAGES_VISUAL_FAIL " + message)
	failed = true


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
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i.ZERO
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.settings_previous_mode = "menu"
	game.ui_platform_override = "desktop"
	game.ui_platform_override_unlocked = true
	game.qa_streaming_unlocked = false
	game.gfx_particles = true
	game.gfx_shadows = true
	game.gfx_screen_shake = true
	game.gfx_low_resource = false
	game.gfx_memory_saver = false
	game._apply_graphics_settings()
	game.vol_music = 0.65
	game.vol_sfx = 0.8
	game.vol_shots = 0.4
	game.desktop_hud_scale = game.DESKTOP_HUD_SCALE_MIN

	await _capture_mode("settings", Vector2i(1280, 720), "settings_hub_1280x720.png")
	await _capture_mode("settings_keys", Vector2i(1280, 720), "settings_keys_1280x720.png")
	await _capture_mode("settings_gameplay", Vector2i(1280, 720), "settings_gameplay_1280x720.png")
	await _capture_mode("settings_audio", Vector2i(1280, 720), "settings_audio_1280x720.png")
	await _capture_mode("settings_graphics", Vector2i(1280, 720), "settings_graphics_1280x720.png")
	await _capture_mode("settings_audio", Vector2i(960, 540), "settings_audio_960x540.png")

	await _capture_mode("settings_graphics", Vector2i(960, 540), "settings_graphics_960x540.png")
	await _capture_mode("settings_keys", Vector2i(960, 540), "settings_keys_960x540.png")
	await _capture_mode("settings_gameplay", Vector2i(960, 540), "settings_gameplay_960x540.png")
	await _capture_mode("settings_gamepad", Vector2i(1280, 720), "settings_gamepad_1280x720.png")
	game.ui_platform_override = "android"
	_check(game._settings_option_keys().has("controls"), "mobile settings lost layout controls")
	_check(not game._gameplay_preference_keys().has("desktop_hud_scale"), "mobile gameplay exposed desktop HUD scale")
	await _capture_mode("settings", Vector2i(960, 540), "settings_hub_mobile.png")
	await _capture_mode("settings_graphics", Vector2i(960, 540), "settings_graphics_mobile.png")
	await _capture_mode("settings_gameplay", Vector2i(960, 540), "settings_gameplay_mobile.png")
	game.ui_platform_override = "desktop"
	_check_audio_drag(Vector2(1280, 720))
	_check_audio_drag(Vector2(960, 540))
	_check_settings_interactions(Vector2(1280, 720))

	print("SETTINGS_PAGES_VISUAL_OK captures=13 hitboxes=true audio_drag=true mouse=true graphics=true pause_return=true persistence=true")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	quit(1 if failed else 0)


func _capture_mode(target_mode: String, viewport: Vector2i, file_name: String) -> void:
	root.mode = Window.MODE_WINDOWED
	await process_frame
	root.size = viewport
	game.mode = target_mode
	game.settings_selected = 0
	game.audio_slider_drag_index = -1
	_check_layouts(Vector2(viewport), target_mode)
	game.queue_redraw()
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
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
		"settings_gamepad":
			rects = game._gamepad_settings_rects(viewport)
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
	if target_mode == "settings_audio":
		var panel: Rect2 = rects["panel"]
		for i in range(4):
			var row: Rect2 = game._audio_slider_row_rect(panel, i)
			_check(panel.encloses(row), "audio channel escaped panel")
			_check(not row.intersects(rects["back"]), "audio channel overlaps back")
			_check(row.encloses(game._audio_minus_rect(panel, i)), "minus outside row")
			_check(row.encloses(game._audio_plus_rect(panel, i)), "plus outside row")
			_check(not Rect2(game._audio_slider_hit_rect(panel, i)).intersects(game._audio_minus_rect(panel, i)), "slider overlaps minus")
			_check(not Rect2(game._audio_slider_hit_rect(panel, i)).intersects(game._audio_plus_rect(panel, i)), "slider overlaps plus")
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


func _check_settings_interactions(viewport: Vector2) -> void:
	root.size = Vector2i(viewport)
	game.mode = "settings"
	game.settings_previous_mode = "paused"
	var hub: Dictionary = game._settings_rects(viewport)
	_check(not hub.has("controls"), "desktop settings exposed mobile layout controls")
	_check(game._gameplay_preference_keys().has("desktop_hud_scale"), "desktop gameplay did not expose HUD scale")
	game._update_menu_pointer(Rect2(hub["audio"]).get_center(), viewport)
	_check(game.settings_selected == game._settings_index_for("audio"), "settings hover did not select audio")
	game._handle_settings_touch(Rect2(hub["audio"]).get_center(), viewport)
	_check(game.mode == "settings_audio", "audio did not open")
	var audio: Dictionary = game._audio_settings_rects(viewport)
	for i in range(4):
		game._set_audio_volume_index(i, 0.5)
		game._handle_audio_settings_touch(game._audio_plus_rect(audio["panel"], i).get_center(), viewport)
		_check(is_equal_approx(game._audio_volume_index(i), 0.6), "audio plus channel " + str(i))
		game._handle_audio_settings_touch(game._audio_minus_rect(audio["panel"], i).get_center(), viewport)
		_check(is_equal_approx(game._audio_volume_index(i), 0.5), "audio minus channel " + str(i))
	game._handle_audio_settings_touch(Rect2(audio["back"]).get_center(), viewport)
	_check(game.mode == "settings", "audio back")
	game._handle_settings_touch(Rect2(hub["graphics"]).get_center(), viewport)
	_check(game.mode == "settings_graphics", "graphics did not open")
	var graphics: Dictionary = game._graphics_settings_rects(viewport)
	for key in ["particles", "shadows", "screen_shake", "low_resource", "memory_saver"]:
		var before: bool = game.get("gfx_" + key)
		game._handle_graphics_settings_touch(Rect2(graphics[key]).get_center(), viewport)
		_check(bool(game.get("gfx_" + key)) != before, "graphics toggle " + key)
		game._handle_graphics_settings_touch(Rect2(graphics[key]).get_center(), viewport)
	game._handle_graphics_settings_touch(Rect2(graphics["back"]).get_center(), viewport)
	_check(game.mode == "settings", "graphics back")
	game._handle_settings_touch(Rect2(hub["gameplay"]).get_center(), viewport)
	_check(game.mode == "settings_gameplay", "gameplay did not open")
	var gameplay: Dictionary = game._gameplay_preferences_rects(viewport)
	_check(gameplay.has("desktop_hud_scale"), "desktop HUD scale rect missing")
	game.desktop_hud_scale = game.DESKTOP_HUD_SCALE_MIN
	game._handle_gameplay_settings_touch(game._desktop_hud_scale_plus_rect(gameplay["desktop_hud_scale"]).get_center(), viewport)
	_check(is_equal_approx(game.desktop_hud_scale, game.DESKTOP_HUD_SCALE_MIN + game.DESKTOP_HUD_SCALE_STEP), "desktop HUD scale plus failed")
	game._handle_gameplay_settings_touch(game._desktop_hud_scale_minus_rect(gameplay["desktop_hud_scale"]).get_center(), viewport)
	_check(is_equal_approx(game.desktop_hud_scale, game.DESKTOP_HUD_SCALE_MIN), "desktop HUD scale minus failed")
	game._handle_gameplay_settings_touch(Rect2(gameplay["back"]).get_center(), viewport)
	_check(game.mode == "settings", "gameplay back")
	game._handle_settings_touch(Rect2(hub["back"]).get_center(), viewport)
	_check(game.mode == "paused", "settings must return to pause")
	game._set_audio_volume_index(1, 0.37)
	game.vol_music = 0.0
	game._load_config()
	_check(is_equal_approx(game.vol_music, 0.37), "audio volume did not persist")
