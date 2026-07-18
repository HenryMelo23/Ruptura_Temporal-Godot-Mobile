extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("QA_STREAMING_REMOVED_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.qa_streaming_unlocked = true
	game.qa_streaming_enabled = true
	game.qa_streaming_status = "Streaming: antigo"
	game._apply_graphics_settings()
	_check(not game.qa_streaming_unlocked, "streaming unlock flag should be forced off")
	_check(not game.qa_streaming_enabled, "streaming should be forced off before CHANZADA")
	_check(game.qa_streaming_status == "", "streaming status should be cleared")
	_check(not game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_streaming"), "streaming option should be hidden")
	_check(not game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_stream_quality"), "streaming quality option should be hidden")

	game.gameplay_cheat_text = "CHANZADA"
	_check(game._try_unlock_retornante_cheat(), "CHANZADA should be accepted as a removed legacy code")
	_check(not game.qa_streaming_unlocked, "CHANZADA must not unlock streaming")
	_check(not game.qa_streaming_enabled, "CHANZADA must not enable streaming")
	_check(game.qa_streaming_status == "", "CHANZADA must not leave streaming status")
	_check(not game._gameplay_preferences_rects(Vector2(1280, 720)).has("qa_streaming"), "streaming option should stay hidden after CHANZADA")

	game._start_qa_streaming_session()
	_check(game.qa_streaming_session_id == "", "removed streaming must not create session ids")
	_check(not game.qa_streaming_frame_active, "removed streaming must not activate frame loop")
	_check(game._capture_qa_stream_frame().is_empty(), "removed streaming must not capture viewport frames")

	print("QA_STREAMING_REMOVED_SMOKE_OK hidden=true session=false frames=false")
	quit()
