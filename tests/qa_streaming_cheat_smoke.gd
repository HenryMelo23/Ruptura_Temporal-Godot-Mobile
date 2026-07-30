extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("QA_STREAMING_CHEAT_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.qa_streaming_unlocked = false
	game.qa_streaming_enabled = false
	game.qa_streaming_status = ""
	game._apply_graphics_settings()
	_check(not game.qa_streaming_unlocked, "streaming should start locked")
	_check(not game.qa_streaming_enabled, "streaming should not auto-enable")
	_check(not game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_stream_quality"), "quality option should be hidden before CHANZADA")
	_check(not game._menu_rects(Vector2(1280, 720)).has("stream"), "hub stream button should be hidden before CHANZADA")

	game.gameplay_cheat_text = "CHANZADA"
	_check(game._try_unlock_retornante_cheat(), "CHANZADA should unlock QA streaming")
	_check(game.qa_streaming_unlocked, "CHANZADA should set streaming unlock flag")
	_check(not game.qa_streaming_enabled, "CHANZADA should not start streaming by itself")
	_check(game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_stream_quality"), "quality option should appear after CHANZADA")
	_check(game._menu_rects(Vector2(1280, 720)).has("stream"), "hub stream button should appear after CHANZADA")
	_check(not game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_streaming"), "legacy settings toggle should stay removed")

	game.qa_streaming_quality_mode = "180p"
	_check(game._sanitize_qa_stream_quality_mode(game.qa_streaming_quality_mode) == "360p", "invalid quality should clamp to 360p")
	game.qa_streaming_quality_mode = "360p"
	game._cycle_qa_stream_quality_mode(1)
	_check(game.qa_streaming_quality_mode == "720p", "quality should cycle from 360p to 720p")
	game.gfx_memory_saver = true
	game._apply_graphics_settings()
	_check(game.qa_streaming_quality_mode == "360p", "memory saver should clamp streaming to 360p")

	game._toggle_qa_streaming_from_menu()
	_check(game.qa_streaming_session_id == "", "headless smoke must not create real stream sessions")
	_check(not game.qa_streaming_enabled, "headless start should disable the pending stream")
	_check(game.qa_streaming_status.find("headless") >= 0, "headless start should explain why no stream opened")

	print("QA_STREAMING_CHEAT_SMOKE_OK unlocked=true hidden_until_cheat=true")
	game.queue_free()
	await process_frame
	quit()
