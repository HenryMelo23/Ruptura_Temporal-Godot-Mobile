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

	_check(game.QA_STREAMING_FEATURE_ENABLED, "streaming feature flag should be enabled")
	_check(game.qa_streaming_unlocked, "soft reset should preserve CHANZADA unlock")
	_check(game.qa_streaming_enabled, "soft reset should preserve pending menu request")
	_check(not game.qa_streaming_frame_active, "soft reset should clear active frame mode")
	_check(game.qa_streaming_frame_url == "", "soft reset should clear frame URL")

	game._reset_qa_streaming_runtime()
	_check(not game.qa_streaming_unlocked, "hard reset should clear CHANZADA unlock")
	_check(not game.qa_streaming_enabled, "hard reset should clear pending menu request")

	game.qa_streaming_unlocked = true
	game.qa_streaming_enabled = true
	game.qa_streaming_quality_mode = "720p"
	_check(game._qa_stream_target_size() == Vector2i(1280, 720), "720p target size mismatch")
	_check(is_equal_approx(game._qa_stream_target_fps(), 60.0), "desktop fallback should target 60 fps")
	_check(float(game.QA_NATIVE_STREAM_MODE_FPS.get("360p", 0.0)) == 60.0, "Android 360p should remain 60fps for Samsung A QA")
	_check(float(game.QA_NATIVE_STREAM_MODE_FPS.get("720p", 60.0)) <= 30.0, "Android 720p should be capped to protect mid-range phones")
	_check(int(game.QA_NATIVE_STREAM_MODE_BITRATE.get("720p", 8000000)) <= 3200000, "Android 720p bitrate should stay mobile-safe")
	_check(game._qa_stream_max_in_flight() >= 8, "frame stream should allow enough parallel uploads for 60fps")
	_check(game._qa_stream_bitrate() >= 8000000, "720p fallback bitrate should not regress to low quality")
	_check(game._qa_stream_jpeg_quality() >= 0.66, "720p fallback quality should not regress")
	game._start_qa_streaming_session()
	_check(game.qa_streaming_session_id == "", "headless smoke must not open stream sessions")
	_check(not game.qa_streaming_frame_active, "headless smoke must not activate frame streaming")
	_check(not game.qa_streaming_enabled, "headless stream start should disable pending request")
	_check(game._capture_qa_stream_frame().is_empty(), "headless capture should not allocate frames")
	game._send_qa_stream_frame()
	_check(game.qa_streaming_frame_count == 0, "headless send should not count frames")

	print("QA_FRAME_STREAM_SMOKE_OK modes=360p,720p enabled=true headless_safe=true")
	game._cleanup_runtime_resources()
	if game.music_player != null:
		game.music_player.stop()
		game.music_player.stream = null
	if game.rain_audio_player != null:
		game.rain_audio_player.stop()
		game.rain_audio_player.stream = null
	for player in game.sfx_players:
		if player != null:
			player.stop()
			player.stream = null
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(4):
		await process_frame
	quit()
