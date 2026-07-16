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
	game.qa_streaming_enabled = true
	game.qa_streaming_status = "Streaming: antigo"
	game._apply_graphics_settings()
	_check(not game.qa_streaming_enabled, "streaming should be forced off before CHANZADA")
	_check(not game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_streaming"), "streaming option should be hidden before CHANZADA")

	game.gameplay_cheat_text = "CHANZADA"
	_check(game._try_unlock_retornante_cheat(), "CHANZADA should unlock streaming")
	_check(game.qa_streaming_unlocked, "streaming unlock flag was not set")
	_check(game.qa_streaming_enabled, "streaming should be enabled after CHANZADA")
	_check(game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_streaming"), "streaming option should appear after CHANZADA")
	_check(game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_stream_quality"), "streaming quality option should appear after CHANZADA")
	_check(game._qa_stream_target_size() == Vector2i(640, 360), "default stream profile should be balanced 360p")
	game._cycle_qa_stream_quality_mode(-1)
	_check(game.qa_streaming_quality_mode == "720p", "quality selector should cycle to 720p")
	_check(game._qa_stream_target_size() == Vector2i(1280, 720), "720p profile should use 1280x720")
	game._cycle_qa_stream_quality_mode(1)
	game._cycle_qa_stream_quality_mode(1)
	_check(game.qa_streaming_quality_mode == "180p", "quality selector should cycle to 180p")
	_check(game._qa_stream_target_size() == Vector2i(320, 180), "180p profile should use 320x180")

	game.gfx_memory_saver = true
	game._apply_graphics_settings()
	_check(game.qa_streaming_enabled, "memory saver should not disable an unlocked stream")
	_check(game._qa_stream_target_size() == Vector2i(320, 180), "memory saver should preserve the selected stream quality")
	_check(game._qa_stream_max_in_flight() == 1, "180p should minimize streaming request pressure")
	_check(game._qa_stream_jpeg_quality() == 0.58, "180p should use the low jpeg pressure profile")

	print("QA_STREAMING_CHEAT_SMOKE_OK profile=%dx%d fps=%.0f" % [game._qa_stream_target_size().x, game._qa_stream_target_size().y, game._qa_stream_target_fps()])
	quit()
