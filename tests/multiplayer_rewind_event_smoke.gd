extends SceneTree


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.is_multiplayer = true
	game.online_connected = true
	game.current_phase = 1
	game.mode = "game"
	game.net_players_by_peer[42] = {
		"pos": Vector2(620, 380),
		"render_pos": Vector2(620, 380),
		"hp": 120.0,
		"hp_max": 300.0,
		"has_snapshot": true,
		"name": "QA"
	}

	game._rpc_temporal_rewind_event("rewind_test_remote", 42, Vector2(620, 380), Vector2(240, 260), 210.0, 2, Vector2(460, 300), 1.0)
	_check(game.net_remote_rewind_visuals.size() == 1, "remote rewind visual was not registered")
	game._rpc_temporal_rewind_event("rewind_test_remote", 42, Vector2(620, 380), Vector2(240, 260), 210.0, 2, Vector2(460, 300), 1.0)
	_check(game.net_remote_rewind_visuals.size() == 1, "duplicate rewind event created a second visual")
	game._update_network_rewind_visuals(0.50)
	var mid_state: Dictionary = game.net_players_by_peer[42]
	var mid_pos := Vector2(mid_state.get("render_pos", Vector2.ZERO))
	_check(mid_pos.distance_to(Vector2(620, 380)) > 20.0, "remote rewind did not move the visual replica")
	_check(mid_pos.distance_to(Vector2(240, 260)) > 20.0, "remote rewind snapped instantly instead of interpolating")
	game._update_network_rewind_visuals(0.60)
	var final_state: Dictionary = game.net_players_by_peer[42]
	_check(Vector2(final_state.get("pos", Vector2.ZERO)).distance_to(Vector2(240, 260)) < 0.5, "remote rewind did not end at official position")
	_check(is_equal_approx(float(final_state.get("hp", 0.0)), 210.0), "remote rewind did not store official HP")

	game.player_pos = Vector2(500, 500)
	game.player_hp = 80
	game.player_hp_max = 300
	game._rpc_temporal_rewind_event("rewind_test_local", 1, Vector2(500, 500), Vector2(180, 180), 190.0, 1, Vector2(460, 300), 1.0)
	_check(game.player_pos.distance_to(Vector2(180, 180)) < 0.5, "local affected peer did not apply official rewind result")
	_check(game.player_hp == 190, "local affected peer did not apply official rewind HP")

	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	for i in range(4):
		await process_frame
	print("MULTIPLAYER_REWIND_EVENT_SMOKE_OK dedupe=true remote_visual=true local_apply=true")
	quit(0)
