extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MULTIPLAYER_PHASE_TRANSFER_VOTE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.is_multiplayer = true
	game.online_lobby_connected_count = 2
	game.mode = "game"
	game.current_phase = 1
	game.player_pos = Vector2(800, 450)
	game.phase_fragment = {
		"pos": game.player_pos,
		"next_phase": 2,
		"pulse": 0.0,
		"life": 0.0
	}
	game._update_phase_fragment(0.016)
	_check(game.mode == "game", "multiplayer phase transfer started without consensus")
	_check(not game.phase_fragment.is_empty(), "multiplayer phase fragment disappeared before consensus")
	_check(game.phase_mp_request_outgoing and game.phase_mp_target == 2 and game.phase_mp_action == "phase", "phase vote request was not started")

	game._clear_phase_mp_request()
	game._start_phase_mp_request_overlay(true, 5, "phase")
	var accepted: bool = game._handle_phase_mp_overlay_press(game._phase_mp_accept_rect(Vector2(1280, 720)).get_center(), Vector2(1280, 720))
	_check(accepted and game.phase_mp_request_outgoing and not game.phase_mp_request_incoming, "phase accept overlay did not move to waiting state")

	game.is_multiplayer = false
	game.mode = "game"
	game.current_phase = 1
	game.pending_phase = 0
	game.phase_fragment = {
		"pos": game.player_pos,
		"next_phase": 2,
		"pulse": 0.0,
		"life": 0.0
	}
	game._update_phase_fragment(0.016)
	_check(game.mode == "phase_transition" and game.pending_phase == 2, "single player phase transfer no longer starts directly")
	_check(game.phase_fragment.is_empty(), "single player phase fragment was not consumed")

	print("MULTIPLAYER_PHASE_TRANSFER_VOTE_SMOKE_OK gated=true accept_overlay=true single_player_direct=true")
	game.queue_free()
	await process_frame
	quit(0)
