extends SceneTree

var game: Node


func _fail(message: String) -> void:
	push_error("MULTIPLAYER_REVIVE_TARGETING_FAIL " + message)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _remote_state(pos: Vector2, name: String = "ALIADO") -> Dictionary:
	return {
		"pos": pos,
		"render_pos": pos,
		"last_pos": pos,
		"velocity": Vector2.ZERO,
		"move": Vector2.ZERO,
		"hp": 450.0,
		"hp_max": 450.0,
		"dead": false,
		"eliminated": false,
		"alive": true,
		"stealthed": false,
		"has_snapshot": true,
		"name": name
	}


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare_game() -> void:
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.is_multiplayer = true
	game.is_host = true
	game.online_connected = false
	game.online_lobby_connected_count = 2
	game.online_lobby_active_player_count = 2
	game._start_game()
	game.mode = "game"
	game.player_hp_max = 500.0
	game.player_hp = 500.0
	game.player_pos = Vector2(160.0, 260.0)
	game.net_players_by_peer = {42: _remote_state(Vector2(880.0, 420.0), "CLIENTE")}


func _mark_remote_dead(peer_id: int, death_pos: Vector2) -> void:
	var state: Dictionary = _remote_state(death_pos, "CLIENTE")
	state["hp"] = 0.0
	state["dead"] = true
	state["eliminated"] = true
	state["alive"] = false
	game.net_players_by_peer[peer_id] = state
	game._rpc_player_death_state(peer_id, true)
	_check(game._targetable_remote_peer_ids().is_empty(), "dead remote peer remained targetable")
	var corpse_enemy := {
		"uid": 2000 + peer_id,
		"type": game.ENEMY_COMMON,
		"pos": death_pos + Vector2(16.0, 0.0),
		"target_peer_id": peer_id
	}
	var target_pos: Vector2 = game._get_enemy_target_pos(corpse_enemy)
	_check(int(corpse_enemy.get("target_peer_id", 0)) != peer_id, "enemy retained remote corpse as target")
	_check(target_pos.distance_squared_to(death_pos) > 4.0, "enemy kept moving toward remote corpse position")


func _revive_remote_from_host(peer_id: int, death_pos: Vector2, revive_pos: Vector2, hp: float) -> void:
	game._clear_team_revival_state()
	_mark_remote_dead(peer_id, death_pos)
	game._start_team_revival_for_dead(peer_id, death_pos, "CLIENTE", false)
	game._activate_team_revival_altars()
	game.net_players_by_peer[peer_id]["pos"] = revive_pos
	game.net_players_by_peer[peer_id]["render_pos"] = death_pos
	game.net_players_by_peer[peer_id]["velocity"] = Vector2(-600.0, 0.0)
	game._complete_team_revival(game.REVIVE_PAY_POINTS, hp, game._mp_unique_id())
	var state: Dictionary = game.net_players_by_peer[peer_id]
	_check(not bool(state.get("dead", true)), "remote peer stayed dead after host revive")
	_check(not bool(state.get("eliminated", true)), "remote peer stayed eliminated after host revive")
	_check(bool(state.get("alive", false)), "remote peer did not publish alive after host revive")
	_check(Vector2(state.get("pos", Vector2.ZERO)).is_equal_approx(revive_pos), "host revive did not publish the current remote position")
	_check(Vector2(state.get("render_pos", Vector2.ZERO)).is_equal_approx(revive_pos), "host revive kept stale render position")
	_check(Vector2(state.get("velocity", Vector2.ONE)).is_zero_approx(), "host revive kept stale movement")
	var history: Array = game.net_player_history_by_peer.get(peer_id, [])
	_check(history.size() == 1 and Vector2(Dictionary(history[0]).get("pos", Vector2.ZERO)).is_equal_approx(revive_pos), "revive did not replace rewind/history cache")
	var revived_enemy := {
		"uid": 3000 + peer_id,
		"type": game.ENEMY_COMMON,
		"pos": revive_pos + Vector2(90.0, 0.0),
		"target_peer_id": peer_id
	}
	_check(game._get_enemy_target_pos(revived_enemy).is_equal_approx(revive_pos), "remote target did not become eligible after revive")
	game._rpc_remote_player_state_light(peer_id, death_pos, 0, 450, true, 1, 0, game.NET_ANIM_DAMAGE, 0, false, 90)
	state = game.net_players_by_peer[peer_id]
	_check(Vector2(state.get("pos", Vector2.ZERO)).is_equal_approx(revive_pos), "late dead RPC restored the old corpse position")
	_check(not bool(state.get("dead", true)), "late dead RPC restored eliminated state")


func _revive_local_host_from_client(death_pos: Vector2, revive_pos: Vector2) -> void:
	game._clear_team_revival_state()
	game.player_pos = death_pos
	game.player_hp = 0.0
	game.is_dead = true
	game._start_team_revival_for_dead(game._mp_unique_id(), death_pos, "HOST", false)
	game._activate_team_revival_altars()
	game.player_pos = revive_pos
	var corpse_enemy := {
		"uid": 4100,
		"type": game.ENEMY_COMMON,
		"pos": death_pos + Vector2(18.0, 0.0),
		"target_peer_id": game._mp_unique_id()
	}
	_check(not game._target_pos_is_local_player(game._get_enemy_target_pos(corpse_enemy)), "enemy kept local corpse target while host was dead")
	game._complete_team_revival(game.REVIVE_PAY_LIFE, 240.0, 42)
	_check(not game.is_dead and game.player_hp > 0.0, "host did not revive after client payment")
	_check(game.player_pos.is_equal_approx(revive_pos), "host revive did not keep the confirmed revive position")
	var revived_enemy := {
		"uid": 4101,
		"type": game.ENEMY_COMMON,
		"pos": revive_pos + Vector2(82.0, 0.0),
		"target_peer_id": game._mp_unique_id()
	}
	_check(game._get_enemy_target_pos(revived_enemy).is_equal_approx(revive_pos), "local host did not become targetable after revive")


func _run() -> void:
	await process_frame
	_prepare_game()

	var death_positions := [Vector2(740.0, 360.0), Vector2(420.0, 610.0), Vector2(1120.0, 300.0)]
	var revive_positions := [Vector2(920.0, 470.0), Vector2(530.0, 520.0), Vector2(1040.0, 620.0)]
	for index in range(death_positions.size()):
		_revive_remote_from_host(42, death_positions[index], revive_positions[index], 180.0 + float(index) * 25.0)

	var eliminated_only: Dictionary = _remote_state(Vector2(900.0, 280.0), "ELIMINADO")
	eliminated_only["eliminated"] = true
	eliminated_only["alive"] = false
	game.net_players_by_peer[43] = eliminated_only
	_check(not game._targetable_remote_peer_ids(true).has(43), "eliminated remote peer was targetable without dead flag")

	_revive_local_host_from_client(Vector2(260.0, 220.0), Vector2(340.0, 380.0))

	print("MULTIPLAYER_REVIVE_TARGETING_REGRESSION_OK cycles=3 host_client=true target_filter=true stale_rpc=true")
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(4):
		await process_frame
	quit(0)
