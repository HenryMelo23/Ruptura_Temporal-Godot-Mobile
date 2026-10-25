extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _remote_state(pos: Vector2, alive: bool = true) -> Dictionary:
	return {
		"has_snapshot": true,
		"pos": pos,
		"velocity": Vector2.ZERO,
		"hp": 450.0 if alive else 0.0,
		"hp_max": 450.0,
		"dead": not alive,
		"eliminated": not alive,
		"alive": alive
	}


func _prepare(party_size: int) -> void:
	game._advance_to_phase(4)
	game.mode = "game"
	game.current_phase = 4
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 25000.0
	game.boss_hp = game.boss_hp_max
	game.boss_entry_timer = 0.0
	game.boss4_ultimate_active = false
	game.boss4_stun_timer = 0.0
	game.player_hp = game.player_hp_max
	game.is_dead = false
	game.online_local_spectator = false
	game.player_pos = Vector2(480.0, 430.0)
	game.phase4_enemy_hazards.clear()
	game.phase4_instability_pulse_controller.reset()
	game.net_players_by_peer.clear()
	game.is_multiplayer = party_size > 1
	game.is_host = party_size > 1
	game.online_room_owner = party_size > 1
	game.online_lobby_connected_count = party_size
	game.online_lobby_active_player_count = party_size
	if party_size >= 2:
		game.net_players_by_peer[2] = _remote_state(Vector2(820.0, 390.0))
	if party_size >= 3:
		game.net_players_by_peer[3] = _remote_state(Vector2(1060.0, 560.0))
	game._reset_boss_party_scaling_context(4)
	game._ensure_boss_party_scaling_context(4)
	game.boss4_instability_fissure_controller.reset()
	for step in range(8):
		game.player_pos += Vector2(12.0, 3.0)
		if party_size >= 2:
			game.net_players_by_peer[2]["pos"] = Vector2(820.0 - step * 8.0, 390.0 + step * 5.0)
		if party_size >= 3:
			game.net_players_by_peer[3]["pos"] = Vector2(1060.0 - step * 4.0, 560.0 - step * 9.0)
		game.boss4_instability_fissure_controller.update(0.17, true)


func _fissures() -> Array:
	return game.phase4_enemy_hazards.filter(func(value): return String(Dictionary(value).get("source", "")) == "boss4_instability_fissure")


func _assert_segments_safe_from_current_targets(fissures: Array) -> void:
	var targets: Array = game._combat_targets()
	for value in fissures:
		var fissure := Dictionary(value)
		var a := Vector2(fissure.get("a", Vector2.ZERO))
		var b := Vector2(fissure.get("b", Vector2.ZERO))
		assert(a.x >= 84.0 and a.y >= 82.0 and a.x <= game.WORLD_SIZE.x - 84.0 and a.y <= game.WORLD_SIZE.y - 82.0)
		assert(b.x >= 84.0 and b.y >= 82.0 and b.x <= game.WORLD_SIZE.x - 84.0 and b.y <= game.WORLD_SIZE.y - 82.0)
		for target_value in targets:
			var target := Dictionary(target_value)
			if int(target.get("peer_id", 0)) != int(fissure.get("target_peer", 0)):
				continue
			assert(game._distance_to_segment(Vector2(target.get("pos", Vector2.ZERO)), a, b) >= game.boss4_instability_fissure_controller.DIRECT_CLEARANCE - 1.0)


func _test_party_scaling_and_target_rotation() -> void:
	for party_size in [1, 2, 3]:
		_prepare(party_size)
		var spawned: int = game.boss4_instability_fissure_controller.force_cast_for_test()
		assert(spawned == party_size + 1)
		var fissures := _fissures()
		assert(fissures.size() == party_size + 1)
		var group_id := String(Dictionary(fissures[0]).get("group_event_id", ""))
		var event_ids: Dictionary = {}
		var target_ids: Dictionary = {}
		for value in fissures:
			var fissure := Dictionary(value)
			assert(String(fissure.get("group_event_id", "")) == group_id)
			assert(int(fissure.get("started_ms", 0)) > 0)
			event_ids[String(fissure.get("event_id", ""))] = true
			target_ids[int(fissure.get("target_peer", 0))] = true
			assert(float(fissure.get("warning", 0.0)) >= 0.8)
		assert(event_ids.size() == fissures.size())
		assert(target_ids.size() == party_size)
		assert(is_equal_approx(float(Dictionary(fissures[0]).get("safe_width", 0.0)), 72.0 + float(party_size - 1) * 12.0))
		_assert_segments_safe_from_current_targets(fissures)
		assert(not bool(game.phase4_instability_pulse_controller.active_snapshot().get("active", false)))


func _test_reachable_cadence_and_state_blocks() -> void:
	_prepare(1)
	game.boss4_attack_timer = 999.0
	game.boss4_secondary_timer = 999.0
	game.boss4_meteor_event_timer = 999.0
	game.boss4_ultimate_cooldown = 999.0
	game.boss4_instability_fissure_controller.reset()
	# The dedicated fissure controller still owns its cadence contract. Boss 4's
	# high-level FSM now decides when that attack is eligible in live combat.
	game.boss4_instability_fissure_controller.update(5.4, true)
	assert(_fissures().is_empty())
	game.boss4_instability_fissure_controller.update(0.2, true)
	assert(_fissures().size() == 2)

	game.phase4_enemy_hazards.clear()
	game.boss4_instability_fissure_controller.reset()
	game.boss4_ultimate_active = true
	game._update_boss_phase4(6.0)
	assert(_fissures().is_empty())
	game.boss4_ultimate_active = false


func _test_edge_clearance() -> void:
	_prepare(1)
	game.phase4_enemy_hazards.clear()
	game.boss4_instability_fissure_controller.reset()
	for index in range(7):
		game.player_pos = Vector2(90.0 + float(index) * 2.0, 90.0 + float(index))
		game.boss4_instability_fissure_controller.update(0.17, true)
	assert(game.boss4_instability_fissure_controller.force_cast_for_test() == 2)
	_assert_segments_safe_from_current_targets(_fissures())


func _single_test_hazard() -> Dictionary:
	_prepare(1)
	assert(game.boss4_instability_fissure_controller.force_cast_for_test() == 2)
	var hazard := Dictionary(_fissures()[0]).duplicate(true)
	hazard["a"] = Vector2(300.0, 450.0)
	hazard["b"] = Vector2(900.0, 450.0)
	hazard["safe_a"] = Vector2(100.0, 100.0)
	hazard["safe_b"] = Vector2(1500.0, 100.0)
	hazard["teleport"] = false
	hazard["age"] = float(hazard.get("warning", 1.05)) - 0.02
	hazard["life"] = 2.0
	hazard["max"] = 2.0
	hazard["impact"] = false
	hazard["hit"] = {}
	game.phase4_enemy_hazards = [hazard]
	game.player_pos = Vector2(600.0, 450.0)
	return hazard


func _test_warning_safe_corridor_and_single_hit() -> void:
	var hazard := _single_test_hazard()
	var hp_before: float = game.player_hp
	game._update_phase4_enemy_hazards(0.01)
	assert(is_equal_approx(game.player_hp, hp_before))
	game._update_phase4_enemy_hazards(0.02)
	var expected_damage := int(game.player_hp_max * 0.075 + 34.0)
	assert(is_equal_approx(game.player_hp, hp_before - expected_damage))
	var hp_after_hit: float = game.player_hp
	game._update_phase4_enemy_hazards(0.2)
	assert(is_equal_approx(game.player_hp, hp_after_hit))

	hazard = _single_test_hazard()
	hazard["safe_a"] = Vector2(300.0, 450.0)
	hazard["safe_b"] = Vector2(900.0, 450.0)
	hazard["age"] = float(hazard.get("warning", 1.05)) + 0.01
	game.phase4_enemy_hazards = [hazard]
	hp_before = game.player_hp
	game._update_phase4_enemy_hazards(0.01)
	assert(is_equal_approx(game.player_hp, hp_before))


func _test_fixed_party_death_revive_disconnect() -> void:
	_prepare(3)
	game.net_players_by_peer[2] = _remote_state(Vector2(760.0, 420.0), false)
	game.boss4_instability_fissure_controller.reset()
	assert(game.boss4_instability_fissure_controller.force_cast_for_test() == 4)
	var target_ids: Array = _fissures().map(func(value): return int(Dictionary(value).get("target_peer", 0)))
	assert(not target_ids.has(2) and target_ids.has(3))
	assert(game.boss_party_scaling_size == 3)

	game.phase4_enemy_hazards.clear()
	game.net_players_by_peer[2] = _remote_state(Vector2(760.0, 420.0), true)
	game.boss4_instability_fissure_controller.reset()
	assert(game.boss4_instability_fissure_controller.force_cast_for_test() == 4)
	target_ids = _fissures().map(func(value): return int(Dictionary(value).get("target_peer", 0)))
	assert(target_ids.has(2))

	game.phase4_enemy_hazards.clear()
	game.net_players_by_peer.erase(3)
	game.online_lobby_connected_count = 2
	game.online_lobby_active_player_count = 2
	game.boss4_instability_fissure_controller.reset()
	assert(game.boss4_instability_fissure_controller.force_cast_for_test() == 4)
	target_ids = _fissures().map(func(value): return int(Dictionary(value).get("target_peer", 0)))
	assert(not target_ids.has(3))
	assert(game.boss_party_scaling_size == 3)

	game.phase4_enemy_hazards.clear()
	game.net_players_by_peer[3] = _remote_state(Vector2(1080.0, 520.0), true)
	game.online_lobby_connected_count = 3
	game.online_lobby_active_player_count = 3
	game.boss4_instability_fissure_controller.reset()
	assert(game.boss4_instability_fissure_controller.force_cast_for_test() == 4)
	target_ids = _fissures().map(func(value): return int(Dictionary(value).get("target_peer", 0)))
	assert(target_ids.has(3))


func _test_host_snapshot_replica_and_cleanup() -> void:
	_prepare(2)
	assert(game.boss4_instability_fissure_controller.force_cast_for_test() == 3)
	var authority_fissures := _fissures().duplicate(true)
	var packet: Dictionary = game._pack_net_boss_visuals()
	var wire: Variant = bytes_to_var(var_to_bytes(packet))
	assert(wire is Dictionary)
	game.phase4_enemy_hazards.clear()
	game.is_host = false
	game.online_room_owner = false
	game._apply_remote_boss_visual_snapshot(wire)
	var replica_fissures := _fissures()
	assert(replica_fissures.size() == authority_fissures.size())
	assert(String(Dictionary(replica_fissures[0]).get("event_id", "")) == String(Dictionary(authority_fissures[0]).get("event_id", "")))
	var replica := Dictionary(replica_fissures[0])
	replica["a"] = Vector2(300.0, 450.0)
	replica["b"] = Vector2(900.0, 450.0)
	replica["safe_a"] = Vector2(100.0, 100.0)
	replica["safe_b"] = Vector2(1500.0, 100.0)
	replica["age"] = float(replica.get("warning", 1.05)) + 0.01
	game.phase4_enemy_hazards = [replica]
	game.player_pos = Vector2(600.0, 450.0)
	var hp_before: float = game.player_hp
	game._update_phase4_enemy_hazards(0.05)
	assert(is_equal_approx(game.player_hp, hp_before))

	game.is_host = true
	game.online_room_owner = true
	game._clear_boss_runtime_hazards()
	assert(_fissures().is_empty())
	game.phase4_enemy_hazards = authority_fissures
	game._advance_to_phase(5)
	assert(_fissures().is_empty())


func _run() -> void:
	game._start_game()
	_test_party_scaling_and_target_rotation()
	_test_reachable_cadence_and_state_blocks()
	_test_edge_clearance()
	_test_warning_safe_corridor_and_single_hit()
	_test_fixed_party_death_revive_disconnect()
	_test_host_snapshot_replica_and_cleanup()
	print("BOSS4_INSTABILITY_FISSURES_SMOKE_OK cadence=5.5/12 counts=2/3/4 recent_path=true safe_corridor=true warning=1.05 ultimate_block=true single_hit=true host_client=true death_revive_reconnect=true cleanup=true")
	game.boss4_instability_fissure_controller.reset()
	game.mode = "menu"
	game.visible = false
	game.set_process(false)
	game.set_physics_process(false)
	game._cleanup_runtime_resources()
	for _frame in range(4):
		await process_frame
	root.remove_child(game)
	game.free()
	game = null
	for _frame in range(3):
		await process_frame
	quit(0)
