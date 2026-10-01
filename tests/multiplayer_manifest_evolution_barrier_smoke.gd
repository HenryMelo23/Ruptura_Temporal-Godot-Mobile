extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MULTIPLAYER_MANIFEST_EVOLUTION_BARRIER_FAIL " + message)
	quit(1)


func _remote_state(pos: Vector2, name: String) -> Dictionary:
	return {
		"pos": pos,
		"render_pos": pos,
		"velocity": Vector2.ZERO,
		"hp": 450.0,
		"hp_max": 450.0,
		"alive": true,
		"dead": false,
		"eliminated": false,
		"stealthed": false,
		"has_snapshot": true,
		"name": name
	}


func _setup_multiplayer(remote_ids: Array) -> void:
	game._start_game()
	game.mode = "game"
	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = true
	game.online_local_spectator = false
	game.online_lobby_connected_count = remote_ids.size() + 1
	game.is_dead = false
	game.player_hp_max = 500.0
	game.player_hp = 500.0
	game.player_pos = Vector2(640, 360)
	game.net_players_by_peer.clear()
	var offset := 0
	for peer_id in remote_ids:
		game.net_players_by_peer[int(peer_id)] = _remote_state(Vector2(860 + offset * 90, 430), "P%d" % int(peer_id))
		offset += 1
	game._reset_manifest_evolution_state()
	game.mode = "game"


func _ready_count() -> int:
	var count := 0
	for peer_id in game.manifest_evolution_barrier_expected_peers:
		if bool(game.manifest_evolution_barrier_ready_by_peer.get(peer_id, false)):
			count += 1
	return count


func _open_barrier() -> int:
	game._open_manifest_evolution_choice(Vector2(700, 400))
	_check(game.manifest_evolution_barrier_active, "barrier did not start")
	_check(game.mode == "manifest_evolution", "local player did not receive evolution choice")
	_check(game.manifest_evolution_options.size() == 3, "evolution options were not opened")
	return int(game.manifest_evolution_barrier_id)


func _remote_ready(peer_id: int, barrier_id: int = -1) -> void:
	var target_id: int = barrier_id if barrier_id >= 0 else int(game.manifest_evolution_barrier_id)
	game._mark_manifest_evolution_barrier_ready(peer_id, target_id)
	game._commit_manifest_evolution_barrier_if_ready()


func _assert_waiting_freezes_world() -> void:
	game.spawn_timer = 3.75
	game.game_time = 41.0
	game.boss_attack_timer = 2.4
	game.phase_transition_timer = 1.7
	game.enemies = [{"uid": 910, "kind": game.ENEMY_COMMON, "pos": Vector2(900, 420), "hp": 20.0, "target_peer_id": 0}]
	var enemy_pos: Vector2 = Vector2(game.enemies[0]["pos"])
	game._process(0.75)
	_check(game.mode == "manifest_evolution_waiting", "waiting barrier resumed during local process")
	_check(is_equal_approx(game.spawn_timer, 3.75), "enemy spawn timer advanced while waiting")
	_check(is_equal_approx(game.game_time, 41.0), "run timer advanced while waiting")
	_check(is_equal_approx(game.boss_attack_timer, 2.4), "boss timer advanced while waiting")
	_check(is_equal_approx(game.phase_transition_timer, 1.7), "phase timer advanced while waiting")
	_check(Vector2(game.enemies[0]["pos"]) == enemy_pos, "enemy advanced while waiting")


func _run_host_ready_first() -> void:
	_setup_multiplayer([42])
	_open_barrier()
	game._choose_manifest_evolution(0)
	_check(game.mode == "manifest_evolution_waiting", "host resumed before client readiness")
	_assert_waiting_freezes_world()
	_remote_ready(42)
	_check(game.mode == "game", "host did not resume after client readiness")
	_check(not game.manifest_evolution_barrier_active, "barrier stayed active after all ready")


func _run_client_ready_first() -> void:
	_setup_multiplayer([42])
	_open_barrier()
	_remote_ready(42)
	_check(game.mode == "manifest_evolution", "client readiness closed host choice early")
	game._choose_manifest_evolution(0)
	_check(game.mode == "game", "all-ready barrier did not resume after host choice")


func _run_two_clients_and_duplicate_ready() -> void:
	_setup_multiplayer([42, 43])
	_open_barrier()
	_check(game.manifest_evolution_barrier_expected_peers.size() == 3, "two-client barrier did not expect three participants")
	_remote_ready(42)
	_remote_ready(42)
	_check(_ready_count() == 1, "duplicate ready changed barrier count")
	game._choose_manifest_evolution(0)
	_check(game.mode == "manifest_evolution_waiting", "barrier resumed before second client")
	_remote_ready(43)
	_check(game.mode == "game", "two-client barrier did not resume after all ready")


func _run_latency_reordering() -> void:
	_setup_multiplayer([42])
	var barrier_id := _open_barrier()
	game._choose_manifest_evolution(0)
	game._rpc_manifest_evolution_barrier_resume(barrier_id - 1)
	_check(game.mode == "manifest_evolution_waiting", "stale resume closed current barrier")
	game._rpc_manifest_evolution_barrier_open(barrier_id, game.manifest_evolution_barrier_expected_peers, "ev1", game.manifest_evolution_options, Vector2(720, 420), "game")
	_check(game.mode == "manifest_evolution_waiting", "duplicate open restored an old choice")
	_remote_ready(42, barrier_id)
	_check(game.mode == "game", "current resume did not close reordered barrier")


func _run_disconnect_during_barrier() -> void:
	_setup_multiplayer([42, 43])
	_open_barrier()
	_remote_ready(42)
	game._choose_manifest_evolution(0)
	_check(game.mode == "manifest_evolution_waiting", "barrier resumed before disconnect policy")
	game._refresh_manifest_evolution_barrier_after_disconnect(43)
	_check(game.mode == "game", "disconnect did not remove peer from barrier")


func _run_new_evolution_after_previous_barrier() -> void:
	_setup_multiplayer([42])
	var first_id := _open_barrier()
	game._choose_manifest_evolution(0)
	_remote_ready(42, first_id)
	_check(game.mode == "game", "first evolution did not resume")
	var second_id := _open_barrier()
	_check(second_id > first_id, "new evolution reused old barrier id")
	_check(game.mode == "manifest_evolution", "new evolution did not open after previous barrier")
	game._rpc_manifest_evolution_barrier_resume(first_id)
	_check(game.mode == "manifest_evolution", "stale previous resume closed new evolution")
	game._choose_manifest_evolution(0)
	_remote_ready(42, second_id)
	_check(game.mode == "game", "new evolution barrier did not complete")


func _run() -> void:
	await process_frame
	_run_host_ready_first()
	_run_client_ready_first()
	_run_two_clients_and_duplicate_ready()
	_run_latency_reordering()
	_run_disconnect_during_barrier()
	_run_new_evolution_after_previous_barrier()
	print("MULTIPLAYER_MANIFEST_EVOLUTION_BARRIER_SMOKE_OK host_first client_first two_clients duplicate_ready reordering disconnect repeat")
	quit(0)
