extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare_phase4() -> void:
	game._advance_to_phase(4)
	game.mode = "game"
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game.player_hp = game.player_hp_max
	game.is_dead = false
	game.player_pos = game.WORLD_SIZE * 0.5
	game.net_players_by_peer.clear()
	game.phase4_enemy_hazards.clear()
	game.phase4_instability_pulse_controller.reset()


func _assert_fragments_safe(snapshot: Dictionary) -> void:
	var fragments: Array = Array(snapshot.get("fragments", []))
	assert(fragments.size() == game.phase4_instability_pulse_controller.FRAGMENT_COUNT)
	for value in fragments:
		var position: Vector2 = Vector2(Dictionary(value).get("pos", Vector2.ZERO))
		var margin: Vector2 = game.phase4_instability_pulse_controller.FRAGMENT_SAFE_MARGIN
		assert(position.x >= margin.x and position.x <= game.WORLD_SIZE.x - margin.x)
		assert(position.y >= margin.y and position.y <= game.WORLD_SIZE.y - margin.y)


func _collect_all() -> void:
	for _index in range(game.phase4_instability_pulse_controller.FRAGMENT_COUNT):
		var snapshot: Dictionary = game.phase4_instability_pulse_controller.active_snapshot()
		var target: Dictionary = {}
		for value in Array(snapshot.get("fragments", [])):
			var fragment: Dictionary = Dictionary(value)
			if not bool(fragment.get("collected", false)):
				target = fragment
				break
		assert(not target.is_empty())
		game.player_pos = Vector2(target.get("pos", game.player_pos))
		game.phase4_instability_pulse_controller.update(0.01, true)


func _test_cadence_motion_success_and_idempotency() -> void:
	_prepare_phase4()
	game.time_alive = game.phase_started_at + game.phase4_instability_pulse_controller.FIRST_START_PHASE_TIME - 0.1
	game.phase4_instability_pulse_controller.update(0.05, true)
	assert(not game.phase4_instability_pulse_controller.is_active())
	game.time_alive += 0.2
	game.phase4_instability_pulse_controller.update(0.05, true)
	assert(game.phase4_instability_pulse_controller.is_active())
	var before: Dictionary = game.phase4_instability_pulse_controller.active_snapshot()
	_assert_fragments_safe(before)
	var positions_before: Array = Array(before.get("fragments", [])).map(func(value): return Vector2(Dictionary(value).get("pos", Vector2.ZERO)))
	game.phase4_instability_pulse_controller.update(0.5, true)
	var moved: Dictionary = game.phase4_instability_pulse_controller.active_snapshot()
	_assert_fragments_safe(moved)
	var moved_count: int = 0
	for index in range(positions_before.size()):
		if positions_before[index].distance_to(Vector2(Dictionary(Array(moved.get("fragments", []))[index]).get("pos", Vector2.ZERO))) > 1.0:
			moved_count += 1
	assert(moved_count == game.phase4_instability_pulse_controller.FRAGMENT_COUNT)
	var score_before: int = game.score_total
	_collect_all()
	var success: Dictionary = game.phase4_instability_pulse_controller.active_snapshot()
	assert(String(success.get("result", "")) == "success")
	assert(int(success.get("collected_count", 0)) == 3)
	assert(is_zero_approx(float(success.get("pulse_instability", -1.0))))
	assert(game.score_total >= score_before + game.phase4_instability_pulse_controller.REWARD_POINTS)
	assert(game.phase4_instability_pulse_controller.player_move_speed_multiplier() > 1.0)
	var score_after: int = game.score_total
	game.phase4_instability_pulse_controller.update(0.2, true)
	assert(game.score_total == score_after)


func _test_failure_pressure_and_boss_instability_isolation() -> void:
	_prepare_phase4()
	game.boss4_instability = 37.0
	assert(game.phase4_instability_pulse_controller.force_start_for_test())
	game.player_pos = Vector2(45.0, 45.0)
	game.phase4_instability_pulse_controller.update(game.phase4_instability_pulse_controller.PULSE_DURATION + 0.1, true)
	var failed: Dictionary = game.phase4_instability_pulse_controller.active_snapshot()
	assert(String(failed.get("result", "")) == "failure")
	assert(float(failed.get("pulse_instability", 0.0)) > game.phase4_instability_pulse_controller.INITIAL_INSTABILITY)
	assert(is_equal_approx(game.boss4_instability, 37.0))
	var pressure: Array = game.phase4_enemy_hazards.filter(func(value): return String(Dictionary(value).get("source", "")) == "phase4_instability_pulse")
	assert(pressure.size() == 3)
	assert(pressure.filter(func(value): return String(Dictionary(value).get("kind", "")) == "vector").size() == 1)
	assert(pressure.filter(func(value): return String(Dictionary(value).get("kind", "")) == "rift").size() == 2)


func _test_cleanup_and_boss_block() -> void:
	_prepare_phase4()
	game.boss_active = true
	assert(not game.phase4_instability_pulse_controller.force_start_for_test())
	game.boss_active = false
	assert(game.phase4_instability_pulse_controller.force_start_for_test())
	game._despawn_enemies_for_boss_call()
	assert(not game.phase4_instability_pulse_controller.is_active())
	_prepare_phase4()
	assert(game.phase4_instability_pulse_controller.force_start_for_test())
	game._advance_to_phase(5)
	assert(not game.phase4_instability_pulse_controller.is_active())


func _test_multiplayer_snapshot_and_single_collect() -> void:
	_prepare_phase4()
	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = true
	game.net_players_by_peer[2] = {"has_snapshot": true, "pos": Vector2(640.0, 420.0), "velocity": Vector2.ZERO, "hp": 450.0, "hp_max": 450.0, "dead": false, "eliminated": false, "alive": true}
	assert(game.phase4_instability_pulse_controller.force_start_for_test())
	var initial: Dictionary = game.phase4_instability_pulse_controller.active_snapshot()
	var first_pos: Vector2 = Vector2(Dictionary(Array(initial.get("fragments", []))[0]).get("pos", Vector2.ZERO))
	game.player_pos = first_pos
	game.net_players_by_peer[2]["pos"] = first_pos
	game.phase4_instability_pulse_controller.update(0.01, true)
	var collected: Dictionary = game.phase4_instability_pulse_controller.active_snapshot()
	assert(int(collected.get("collected_count", 0)) == 1)
	game.phase4_instability_pulse_controller.update(0.01, true)
	assert(int(game.phase4_instability_pulse_controller.active_snapshot().get("collected_count", 0)) == 1)
	var packet: Dictionary = game._pack_net_boss_visuals()
	var wire: Variant = bytes_to_var(var_to_bytes(packet))
	assert(wire is Dictionary)
	assert(Dictionary(wire).has("phase4_instability_pulse"))
	game.phase4_instability_pulse_controller.reset()
	game.is_host = false
	game.online_room_owner = false
	var score_before: int = game.score_total
	game._apply_remote_boss_visual_snapshot(wire)
	var replica: Dictionary = game.phase4_instability_pulse_controller.active_snapshot()
	assert(String(replica.get("event_id", "")) == String(collected.get("event_id", "")))
	assert(int(replica.get("collected_count", 0)) == 1)
	game.phase4_instability_pulse_controller.update(5.0, false)
	assert(int(game.phase4_instability_pulse_controller.active_snapshot().get("collected_count", 0)) == 1)
	assert(game.score_total == score_before)
	game.is_multiplayer = false


func _run() -> void:
	game._start_game()
	_test_cadence_motion_success_and_idempotency()
	_test_failure_pressure_and_boss_instability_isolation()
	_test_cleanup_and_boss_block()
	_test_multiplayer_snapshot_and_single_collect()
	print("PHASE4_INSTABILITY_PULSE_SMOKE_OK count=3 cadence=120 movement=true bounds=true success=true failure=true cleanup=true host_client=true no_double_collect=true boss4_isolated=true")
	game.phase4_instability_pulse_controller.reset()
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(4):
		await process_frame
	quit(0)
