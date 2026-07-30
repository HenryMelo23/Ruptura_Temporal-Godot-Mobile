extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("QA_FRAME_STREAM_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.qa_stream_base_url = OS.get_environment("QA_STREAM_SMOKE_BASE_URL").strip_edges()
	game.qa_streaming_unlocked = true
	game.qa_streaming_enabled = true
	game.qa_streaming_frame_active = true
	game.qa_streaming_frame_url = "http://127.0.0.1:9/streams/test/frame"
	game._reset_qa_streaming_runtime(false)

	_check(game.qa_streaming_unlocked, "soft reset should preserve CHANZADA unlock")
	_check(game.qa_streaming_enabled, "soft reset should preserve the pending menu request")
	_check(not game.qa_streaming_frame_active, "soft reset should clear active frame mode")
	_check(game.qa_streaming_frame_url == "", "soft reset should clear frame URL")

	game._reset_qa_streaming_runtime()
	_check(not game.qa_streaming_unlocked, "hard reset should clear CHANZADA unlock")

	game.qa_streaming_unlocked = true
	game.qa_streaming_enabled = true
	game.qa_streaming_quality_mode = "720p"
	_check(game._qa_stream_target_size() == Vector2i(1280, 720), "720p target size mismatch")
	_check(is_equal_approx(game._qa_stream_target_fps(), 10.0), "desktop fallback should stay capped for CPU/bandwidth")
	_check(game._qa_stream_max_in_flight() == 1, "frame stream should keep a single in-flight request")
	game._start_qa_streaming_session()
	_check(game.qa_streaming_session_id == "", "headless smoke must not open stream sessions")
	_check(not game.qa_streaming_frame_active, "headless smoke must not activate frame streaming")
	_check(game._capture_qa_stream_frame().is_empty(), "headless capture should not allocate frames")
	game._send_qa_stream_frame()
	_check(game.qa_streaming_frame_count == 0, "headless send should not count frames")

	print("QA_FRAME_STREAM_SMOKE_OK modes=360p,720p headless_safe=true")
	game.queue_free()
	await process_frame
	quit()
