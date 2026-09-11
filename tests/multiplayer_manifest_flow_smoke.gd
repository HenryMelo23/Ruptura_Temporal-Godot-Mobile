extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _finish_ok(message: String) -> void:
	print(message)
	if is_instance_valid(game):
		game._cleanup_runtime_resources()
		game.textures.clear()
		game.audio_streams.clear()
		root.remove_child(game)
		game.free()
		game = null
	for i in range(4):
		await process_frame
	quit(0)


func _advance_manifest(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		var dt: float = min(0.05, seconds - elapsed)
		game._update_manifest_selection_flow(dt)
		elapsed += dt


func _run() -> void:
	game.is_multiplayer = true
	game.is_host = true
	game._start_multiplayer_manifest()
	_check(game.mode == "manifest_mp", "multiplayer selection did not open manifest_mp")
	_check(game.manifest_select_stage == game.MANIFEST_STAGE_MANIFESTATION, "multiplayer selection must start at manifestation stage")
	_check(not game.mp_local_ready and not game.mp_remote_ready, "multiplayer ready flags must start false")

	game._set_selected_manifestation(2, false)
	game._confirm_manifest_mp_selection()
	_check(game.mode == "manifest_mp", "confirming manifestation should not start the game")
	_check(game.manifest_select_stage == game.MANIFEST_STAGE_TRANSITION, "confirming manifestation should reveal the spectrum")
	_check(not game.mp_local_ready, "manifestation confirmation must not mark final ready")

	_advance_manifest(game.MANIFEST_SPECTRUM_TRANSITION_TIME + 0.05)
	_check(game.manifest_select_stage == game.MANIFEST_STAGE_AURA, "spectrum transition did not finish in multiplayer mode")
	_check(not game.mp_local_ready, "arriving at spectrum should still wait for final confirmation")

	game._set_selected_aura(3, false)
	game.mp_remote_ready = false
	game._confirm_manifest_mp_selection()
	_check(game.mp_local_ready, "confirming spectrum should mark local ready")
	_check(game.mode == "manifest_mp", "game started before the partner confirmed spectrum")
	game._confirm_manifest_mp_selection()
	_check(not game.mp_local_ready and game.mode == "manifest_mp", "ready button should cancel final ready before host start")
	game._set_selected_manifestation(4, false)
	game._return_manifest_mp_to_manifestation()
	_check(game.manifest_select_stage == game.MANIFEST_STAGE_MANIFESTATION, "cancel ready should allow returning to manifestation selection")
	game._set_selected_manifestation(2, false)
	game._start_spectrum_reveal()
	_advance_manifest(game.MANIFEST_SPECTRUM_TRANSITION_TIME + 0.05)
	game._set_selected_aura(3, false)
	game._confirm_manifest_mp_selection()

	game.mode = "manifest_mp"
	game.mp_local_ready = true
	game.mp_remote_ready = true
	game.online_lobby_connected_count = 2
	game.mp_manifest_state_by_peer = {
		42: {"stage": game.MANIFEST_STAGE_AURA, "manifestation": 1, "aura": 2, "ready": true}
	}
	game.manifest_select_stage = game.MANIFEST_STAGE_AURA
	_check(game._manifest_mp_start_available(), "host start button should unlock when all players are ready")
	game._apply_manifest_mp_remote_state(42, game.MANIFEST_STAGE_AURA, 1, 2, 2.0, true, true)
	_check(game.mode == "manifest_mp", "all ready should wait for manual host start")
	game._request_manifest_mp_start()
	_check(game.mode == "game", "host manual start did not begin the game")
	_check(String(game.aura_state.get("name", "")) == String(game.AURAS[3]["name"]), "multiplayer start did not keep the selected spectrum")

	await _finish_ok("MULTIPLAYER_MANIFEST_FLOW_SMOKE_OK manual_host_start=true cancel_ready=true")
