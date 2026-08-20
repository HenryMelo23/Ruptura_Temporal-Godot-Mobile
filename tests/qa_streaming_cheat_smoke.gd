extends SceneTree

var game: Node
var config_path := "user://hud_config.save"
var had_config := false
var config_backup := ""


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_restore_config()
	push_error("QA_STREAMING_CHEAT_FAIL " + message)
	quit(1)


func _backup_config() -> void:
	had_config = FileAccess.file_exists(config_path)
	if had_config:
		var file := FileAccess.open(config_path, FileAccess.READ)
		if file != null:
			config_backup = file.get_as_text()
			file.close()


func _restore_config() -> void:
	if had_config:
		var file := FileAccess.open(config_path, FileAccess.WRITE)
		if file != null:
			file.store_string(config_backup)
			file.close()
	else:
		var absolute := ProjectSettings.globalize_path(config_path)
		if FileAccess.file_exists(config_path):
			DirAccess.remove_absolute(absolute)


func _initialize() -> void:
	_backup_config()
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.qa_streaming_unlocked = false
	game.qa_streaming_enabled = false
	game.qa_streaming_status = ""
	game._apply_graphics_settings()
	_check(game.QA_STREAMING_FEATURE_ENABLED, "streaming feature flag should be enabled")
	_check(not game.qa_streaming_unlocked, "streaming should start locked")
	_check(not game.qa_streaming_enabled, "streaming should not auto-enable")
	_check(not game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_stream_quality"), "quality option should be hidden before CHANZADA")
	_check(not game._menu_rects(Vector2(1280, 720)).has("stream"), "hub stream button should be hidden before CHANZADA")

	var fake_config := FileAccess.open(config_path, FileAccess.WRITE)
	_check(fake_config != null, "could not create fake persisted config")
	fake_config.store_string("qa_streaming_unlocked=true\nqa_streaming_enabled=true\nqa_streaming_quality=720p\n")
	fake_config.close()
	game.qa_streaming_unlocked = false
	game.qa_streaming_enabled = true
	game._load_config()
	_check(game.qa_streaming_unlocked, "persisted CHANZADA unlock should be restored")
	_check(not game.qa_streaming_enabled, "persisted active streaming must not auto-start")
	_check(game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_stream_quality"), "quality option should show after persisted CHANZADA")
	_check(game._menu_rects(Vector2(1280, 720)).has("stream"), "hub stream button should show after persisted CHANZADA")

	game._reset_qa_streaming_runtime()
	_check(not game.qa_streaming_unlocked, "hard reset should clear CHANZADA unlock")

	game.gameplay_cheat_text = "CHANZADA"
	_check(game._try_unlock_retornante_cheat(), "CHANZADA should unlock match streaming")
	_check(game.qa_streaming_unlocked, "CHANZADA should set streaming unlock flag")
	_check(not game.qa_streaming_enabled, "CHANZADA should not auto-enable streaming")
	_check(game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_stream_quality"), "quality option should show after CHANZADA")
	_check(game._menu_rects(Vector2(1280, 720)).has("stream"), "hub stream button should show after CHANZADA")
	_check(not game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_streaming"), "legacy settings toggle should stay removed")
	var stream_subtitle := String(game._qa_stream_menu_subtitle()).to_lower()
	_check(stream_subtitle.contains("liberado") or stream_subtitle.contains("transmiss") or stream_subtitle.contains("viewport"), "menu subtitle should describe available stream")
	game._finish_startup_thanks()
	game.mode = "menu"
	await _capture("stream_menu_unlocked_1280x720.png", Vector2i(1280, 720))
	await _capture("stream_menu_unlocked_960x540.png", Vector2i(960, 540))

	game.qa_streaming_quality_mode = "180p"
	_check(game._sanitize_qa_stream_quality_mode(game.qa_streaming_quality_mode) == "360p", "invalid quality should clamp to 360p")

	if DisplayServer.get_name() == "headless":
		game._toggle_qa_streaming_from_menu()
		_check(game.qa_streaming_session_id == "", "headless smoke must not create real stream sessions")
		_check(not game.qa_streaming_enabled, "streaming toggle should remain disabled")
		_check(game.qa_streaming_status == "Streaming: headless indisponivel", "headless should report unavailable streaming")

	game.qa_streaming_unlocked = true
	game.qa_streaming_enabled = true
	game.qa_streaming_in_flight = true
	game.qa_streaming_frame_active = true
	game.qa_streaming_status = "Streaming: viewport ativo"
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not game.qa_streaming_in_flight, "focus out should cancel pending stream session immediately")
	_check(not game.qa_streaming_frame_active, "focus out should stop frame streaming immediately")
	_check(not game.qa_streaming_enabled, "focus out should clear streaming enabled state")

	print("QA_STREAMING_CHEAT_SMOKE_OK unlocked=true persisted=true focus_stop=true")
	game.queue_free()
	await process_frame
	_restore_config()
	quit()


func _capture(file_name: String, viewport: Vector2i) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_size(viewport)
	await process_frame
	await process_frame
	var image: Image = root.get_viewport().get_texture().get_image()
	_check(image != null and image.get_width() == viewport.x and image.get_height() == viewport.y, "invalid capture " + file_name)
	var dir := DirAccess.open("res://")
	if dir != null:
		dir.make_dir_recursive(".codex")
	var path := ProjectSettings.globalize_path("res://.codex/" + file_name)
	_check(image.save_png(path) == OK, "could not save capture " + file_name)
