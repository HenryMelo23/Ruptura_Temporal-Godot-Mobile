extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("QA_FRAME_STREAM_REMOVED_FAIL " + message)
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
	game.qa_streaming_frame_url = "http://127.0.0.1:9/streams/removed/frame"
	game._reset_qa_streaming_runtime()

	_check(not game.qa_streaming_unlocked, "reset should clear legacy unlocks")
	_check(not game.qa_streaming_enabled, "reset should clear legacy enabled state")
	_check(not game.qa_streaming_frame_active, "reset should clear active frame mode")
	_check(game.qa_streaming_frame_url == "", "reset should clear frame URL")

	game.qa_streaming_unlocked = true
	game.qa_streaming_enabled = true
	game._start_qa_streaming_session()
	_check(game.qa_streaming_session_id == "", "start must not open removed streaming sessions")
	_check(game.qa_streaming_frame_url == "", "start must not keep frame URL")
	_check(not game.qa_streaming_frame_active, "start must not activate frame streaming")
	_check(game._capture_qa_stream_frame().is_empty(), "capture must return empty when streaming is removed")
	game._send_qa_stream_frame()
	_check(game.qa_streaming_frame_count == 0, "send must not count frames when streaming is removed")

	print("QA_FRAME_STREAM_REMOVED_OK disabled=true network=false")
	quit()
