extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare_phase3() -> void:
	game._advance_to_phase(3)
	game.mode = "game"
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game.player_hp = game.player_hp_max
	game.is_dead = false
	game.player_pos = game.WORLD_SIZE * 0.5
	game.enemies.clear()
	game.phase3_miasma_zones.clear()
	game.net_players_by_peer.clear()
	game.phase3_ritual_pulse_controller.reset()


func _marked_devotees() -> Array:
	return game.enemies.filter(func(enemy): return bool(Dictionary(enemy).get("phase3_ritual_marked", false)))


func _circle_for_devotee(enemy: Dictionary) -> Dictionary:
	var snapshot: Dictionary = game.phase3_ritual_pulse_controller.active_snapshot()
	for value in Array(snapshot.get("circles", [])):
		var circle: Dictionary = value
		if int(circle.get("id", -1)) == int(enemy.get("phase3_ritual_circle_id", -2)):
			return circle
	return {}


func _assert_circles_in_bounds(snapshot: Dictionary, expected_count: int) -> void:
	var circles: Array = Array(snapshot.get("circles", []))
	assert(circles.size() == expected_count)
	for value in circles:
		var circle: Dictionary = value
		var pos: Vector2 = Vector2(circle.get("pos", Vector2.ZERO))
		assert(pos.x >= 135.0 and pos.x <= game.WORLD_SIZE.x - 135.0)
		assert(pos.y >= 125.0 and pos.y <= game.WORLD_SIZE.y - 125.0)


func _test_success_and_devotee_lifecycle() -> void:
	_prepare_phase3()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(420.0, 330.0))
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(1080.0, 570.0))
	game._spawn_enemy(game.ENEMY_INCENSARIO, Vector2(260.0, 220.0))
	game._spawn_enemy(game.ENEMY_GUARDIAO, Vector2(1320.0, 680.0))
	assert(game.phase3_ritual_pulse_controller.force_start_for_test())
	var snapshot: Dictionary = game.phase3_ritual_pulse_controller.active_snapshot()
	_assert_circles_in_bounds(snapshot, 2)
	assert(_marked_devotees().size() == 2)
	assert(game._enemy_type_count(game.ENEMY_INCENSARIO) == 1)
	assert(game._enemy_type_count(game.ENEMY_GUARDIAO) == 1)

	var moving_devotee: Dictionary = _marked_devotees()[0]
	var moving_circle: Dictionary = _circle_for_devotee(moving_devotee)
	moving_devotee["pos"] = Vector2(moving_circle["pos"]) + Vector2(170.0, 0.0)
	var distance_before: float = Vector2(moving_devotee["pos"]).distance_to(Vector2(moving_circle["pos"]))
	game._update_phase3_enemy(moving_devotee, 0.2)
	assert(Vector2(moving_devotee["pos"]).distance_to(Vector2(moving_circle["pos"])) < distance_before)

	# Killing one marked Devoto before it reaches the circle disrupts that
	# circle but does not duplicate the objective reward.
	var score_before: int = game.score_total
	var first_devotee: Dictionary = _marked_devotees()[0]
	game._kill_enemy(first_devotee)
	snapshot = game.phase3_ritual_pulse_controller.active_snapshot()
	assert(Array(snapshot.get("circles", [])).any(func(value): return bool(Dictionary(value).get("disrupted", false))))
	assert(String(snapshot.get("result", "active")) == "active")
	var remaining: Array = _marked_devotees()
	assert(remaining.size() == 1)
	game._kill_enemy(Dictionary(remaining[0]))
	snapshot = game.phase3_ritual_pulse_controller.active_snapshot()
	assert(String(snapshot.get("result", "")) == "success")
	assert(int(snapshot.get("reward", 0)) == 2 * game.phase3_ritual_pulse_controller.REWARD_POINTS_PER_CIRCLE)
	assert(game.score_total >= score_before + int(snapshot.get("reward", 0)))
	var score_after_success: int = game.score_total
	game.phase3_ritual_pulse_controller.on_enemy_defeated(first_devotee)
	assert(game.score_total == score_after_success)


func _test_failure_pressure() -> void:
	_prepare_phase3()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(420.0, 330.0))
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(1080.0, 570.0))
	assert(game.phase3_ritual_pulse_controller.force_start_for_test())
	for value in _marked_devotees():
		var devotee: Dictionary = value
		var circle: Dictionary = _circle_for_devotee(devotee)
		devotee["pos"] = Vector2(circle.get("pos", devotee.get("pos", Vector2.ZERO)))
		game._update_phase3_enemy(devotee, game.phase3_ritual_pulse_controller.CHANNEL_DURATION + 0.05)
	game.phase3_ritual_pulse_controller.update(0.01, true)
	var snapshot: Dictionary = game.phase3_ritual_pulse_controller.active_snapshot()
	assert(String(snapshot.get("result", "")) == "failure")
	assert(game.phase3_miasma_zones.size() == 2)
	for zone_value in game.phase3_miasma_zones:
		var zone: Dictionary = zone_value
		assert(is_equal_approx(float(zone.get("radius", 0.0)), game.phase3_ritual_pulse_controller.FAILURE_MIASMA_RADIUS))
		assert(float(zone.get("life", 0.0)) > 0.0)


func _test_prevention_until_timeout_succeeds() -> void:
	_prepare_phase3()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(180.0, 180.0))
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(1420.0, 720.0))
	assert(game.phase3_ritual_pulse_controller.force_start_for_test())
	for value in _marked_devotees():
		Dictionary(value)["stun"] = game.phase3_ritual_pulse_controller.RITUAL_DURATION + 1.0
	var score_before: int = game.score_total
	game.phase3_ritual_pulse_controller.update(game.phase3_ritual_pulse_controller.RITUAL_DURATION + 0.01, true)
	var snapshot: Dictionary = game.phase3_ritual_pulse_controller.active_snapshot()
	assert(String(snapshot.get("result", "")) == "success")
	assert(String(snapshot.get("result_reason", "")) == "ritual_timeout")
	assert(game.score_total >= score_before + int(snapshot.get("reward", 0)))


func _test_cleanup_paths() -> void:
	_prepare_phase3()
	assert(game.phase3_ritual_pulse_controller.force_start_for_test())
	game._despawn_enemies_for_boss_call()
	assert(not game.phase3_ritual_pulse_controller.is_active())
	assert(_marked_devotees().is_empty())

	_prepare_phase3()
	assert(game.phase3_ritual_pulse_controller.force_start_for_test())
	game._advance_to_phase(4)
	assert(not game.phase3_ritual_pulse_controller.is_active())


func _test_multiplayer_snapshot() -> void:
	_prepare_phase3()
	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = true
	game.online_lobby_connected_count = 3
	game.net_players_by_peer[2] = {"has_snapshot": true, "pos": Vector2(620.0, 410.0), "velocity": Vector2.ZERO, "hp": 450.0, "hp_max": 450.0, "dead": false, "eliminated": false, "alive": true}
	game.net_players_by_peer[3] = {"has_snapshot": true, "pos": Vector2(980.0, 490.0), "velocity": Vector2.ZERO, "hp": 450.0, "hp_max": 450.0, "dead": false, "eliminated": false, "alive": true}
	assert(game.phase3_ritual_pulse_controller.force_start_for_test())
	var host_snapshot: Dictionary = game.phase3_ritual_pulse_controller.active_snapshot()
	_assert_circles_in_bounds(host_snapshot, 3)
	assert(_marked_devotees().size() == 3)
	var packet: Dictionary = game._pack_net_boss_visuals()
	var round_trip: Variant = bytes_to_var(var_to_bytes(packet))
	assert(round_trip is Dictionary)
	var wire_snapshot: Dictionary = Dictionary(round_trip.get("phase3_ritual_pulse", {}))
	assert(String(wire_snapshot.get("event_id", "")) == String(host_snapshot.get("event_id", "")))
	assert(Array(wire_snapshot.get("circles", [])).size() == 3)

	game.phase3_ritual_pulse_controller.reset()
	game.is_host = false
	game.online_room_owner = false
	assert(game._is_world_replica())
	var score_before: int = game.score_total
	game._apply_remote_boss_visual_snapshot(round_trip)
	var replica_snapshot: Dictionary = game.phase3_ritual_pulse_controller.active_snapshot()
	assert(String(replica_snapshot.get("event_id", "")) == String(host_snapshot.get("event_id", "")))
	assert(Array(replica_snapshot.get("devotees", [])).size() == 3)
	var progress_before: float = float(replica_snapshot.get("overall_progress", 0.0))
	game.phase3_ritual_pulse_controller.update(5.0, false)
	assert(is_equal_approx(float(game.phase3_ritual_pulse_controller.active_snapshot().get("overall_progress", 0.0)), progress_before))
	game._apply_remote_boss_visual_snapshot(round_trip)
	assert(game.score_total == score_before)
	game.is_multiplayer = false


func _test_normal_phase3_unchanged_outside_pulse() -> void:
	_prepare_phase3()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(500.0, 400.0))
	var devotee: Dictionary = game.enemies[-1]
	var miasma_before: int = game.phase3_miasma_zones.size()
	devotee["miasma_cd"] = 0.0
	game._update_phase3_enemy(devotee, 0.02)
	assert(game.phase3_miasma_zones.size() == miasma_before + 1)
	assert(not bool(devotee.get("phase3_ritual_marked", false)))


func _run() -> void:
	game._start_game()
	_test_success_and_devotee_lifecycle()
	_test_failure_pressure()
	_test_prevention_until_timeout_succeeds()
	_test_cleanup_paths()
	_test_multiplayer_snapshot()
	_test_normal_phase3_unchanged_outside_pulse()
	print("PHASE3_RITUAL_PULSE_SMOKE_OK start=true progress=true success=true prevented_timeout=true failure=true devotee_killed_early=true cleanup=true host_client=true normal_phase3=true")
	game.phase3_ritual_pulse_controller.reset()
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(4):
		await process_frame
	quit(0)
