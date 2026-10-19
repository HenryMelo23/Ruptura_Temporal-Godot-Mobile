extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _configure(party_size: int) -> void:
	game.current_phase = 1
	game.mode = "game"
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 5000.0
	game.boss_hp = 3200.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_hp_max = 450.0
	game.player_hp = game.player_hp_max
	game.player_pos = game.boss_pos + Vector2(180.0, 0.0)
	game.is_dead = false
	game.boss_attacks.clear()
	game.net_players_by_peer.clear()
	game.boss_target_peer_id = 0
	game.boss_target_switch_timer = 0.0
	game.boss_party_scaling_phase = 1
	game.boss_party_scaling_size = party_size
	game.boss_party_scaling_hazard_bonus = party_size - 1
	game.boss_party_scaling_tempo_coeff = [1.0, 1.12, 1.22][party_size - 1]
	for peer_id in range(2, party_size + 1):
		game.net_players_by_peer[peer_id] = {
			"has_snapshot": true,
			"pos": game.boss_pos + Vector2(-150.0 + peer_id * 32.0, 120.0),
			"velocity": Vector2(-18.0, 0.0),
			"hp": 450.0,
			"hp_max": 450.0,
			"dead": false,
			"eliminated": false,
			"alive": true,
			"stealthed": false
		}


func _run_one_party_size(party_size: int) -> Dictionary:
	_configure(party_size)
	assert(game.early_boss_controller != null)
	assert(game.early_boss_controller.has_method("add_boss1_pincer_tenaz"))
	assert(game.early_boss_controller.has_method("update_boss1_pincer_tenaz"))
	game._add_boss_pincer_tenaz()
	assert(game.boss_attacks.size() == 1)
	var attack: Dictionary = game.boss_attacks[0]
	assert(String(attack.get("kind", "")) == "pincer_tenaz")
	assert(String(attack.get("event_id", "")).begins_with(game.BOSS1_PINCER_TENAZ_EVENT_PREFIX))
	assert(int(attack.get("started_ms", 0)) > 0)
	assert(not bool(attack.get("impact", true)))
	assert(int(attack.get("party_size", 0)) == party_size)
	assert(float(attack.get("warning", 0.0)) >= 0.8)
	assert(float(attack.get("gap", 0.0)) <= game.BOSS1_PINCER_TENAZ_GAP + 0.01)
	var first_peer_id: int = int(attack.get("first_target_peer_id", 0))
	var first_end: Vector2 = Vector2(attack.get("first_end", Vector2.ZERO))
	var first_dir: Vector2 = Vector2(attack.get("first_dir", Vector2.ZERO))

	game._update_boss_attacks(float(attack["warning"]) + 0.01)
	assert(String(attack.get("state", "")) == "dash_first")
	game.player_pos = game.boss_pos + Vector2(-260.0, 210.0)
	game._update_boss_attacks(0.22)
	assert(String(attack.get("state", "")) == "dash_first")
	assert(Vector2(attack["first_end"]).distance_to(first_end) <= 0.001)
	assert(Vector2(attack["first_dir"]).distance_to(first_dir) <= 0.001)
	game._update_boss_attacks(1.0)
	assert(String(attack.get("state", "")) == "gap")

	game._update_boss_attacks(float(attack["gap"]) + 0.01)
	assert(String(attack.get("state", "")) == "telegraph_second")
	var second_peer_id: int = int(attack.get("second_target_peer_id", 0))
	if party_size > 1:
		assert(second_peer_id != first_peer_id)
	else:
		assert(second_peer_id == first_peer_id)
	var second_end: Vector2 = Vector2(attack.get("second_end", Vector2.ZERO))
	game._update_boss_attacks(float(attack["warning"]) + 0.01)
	assert(String(attack.get("state", "")) == "dash_second")
	game.player_pos = game.boss_pos + Vector2(260.0, -210.0)
	game._update_boss_attacks(0.28)
	assert(String(attack.get("state", "")) == "dash_second")
	assert(Vector2(attack["second_end"]).distance_to(second_end) <= 0.001)
	game._update_boss_attacks(1.0)
	assert(String(attack.get("state", "")) == "recovery")
	assert(bool(attack.get("impact", false)))
	game._update_boss_attacks(0.5)
	assert(game.boss_attacks.is_empty())
	return {"event_id": String(attack.get("event_id", "")), "gap": float(attack.get("gap", 0.0))}


func _set_target_alive(peer_id: int, alive: bool) -> void:
	if peer_id == game._mp_unique_id():
		game.is_dead = not alive
		game.player_hp = game.player_hp_max if alive else 0.0
		return
	var state: Dictionary = game.net_players_by_peer.get(peer_id, {})
	state["has_snapshot"] = true
	state["hp"] = 450.0 if alive else 0.0
	state["dead"] = not alive
	state["eliminated"] = not alive
	state["alive"] = alive
	game.net_players_by_peer[peer_id] = state


func _test_target_lifecycle() -> void:
	# If the alternate target dies before the second warning, the live first
	# target is used again. Reviving the alternate makes it eligible again.
	_configure(2)
	game._add_boss_pincer_tenaz()
	var attack: Dictionary = game.boss_attacks[0]
	var first_peer_id: int = int(attack.get("first_target_peer_id", 0))
	var alternate_peer_id: int = int(attack.get("second_target_peer_id", 0))
	assert(first_peer_id != alternate_peer_id)
	_set_target_alive(alternate_peer_id, false)
	game._boss1_pincer_resolve_second_leg(attack)
	assert(int(attack.get("second_target_peer_id", 0)) == first_peer_id)
	_set_target_alive(alternate_peer_id, true)
	game._boss1_pincer_resolve_second_leg(attack)
	assert(int(attack.get("second_target_peer_id", 0)) == alternate_peer_id)

	# A disconnected target is not retained. A later reconnect becomes a valid
	# alternate without changing the in-flight first trajectory.
	_configure(3)
	var local_peer_id: int = game._mp_unique_id()
	var lifecycle_attack: Dictionary = {
		"first_target_peer_id": local_peer_id,
		"first_target_pos": game.player_pos
	}
	game.net_players_by_peer.erase(2)
	_set_target_alive(3, false)
	game._boss1_pincer_resolve_second_leg(lifecycle_attack)
	assert(int(lifecycle_attack.get("second_target_peer_id", 0)) == local_peer_id)
	game.net_players_by_peer[2] = {
		"has_snapshot": true,
		"pos": game.boss_pos + Vector2(-120.0, 80.0),
		"velocity": Vector2(22.0, 0.0),
		"hp": 450.0,
		"hp_max": 450.0,
		"dead": false,
		"eliminated": false,
		"alive": true,
		"stealthed": false
	}
	game._boss1_pincer_resolve_second_leg(lifecycle_attack)
	assert(int(lifecycle_attack.get("second_target_peer_id", 0)) == 2)


func _test_replica_and_visual_idempotency() -> void:
	_configure(1)
	game._add_boss_pincer_tenaz()
	var attack: Dictionary = game.boss_attacks[0]
	var state_before: String = String(attack.get("state", ""))
	var state_age_before: float = float(attack.get("state_age", 0.0))
	game.is_multiplayer = true
	game.is_host = false
	game.online_room_owner = false
	assert(game._is_world_replica())
	game._update_boss(0.5)
	assert(String(attack.get("state", "")) == state_before)
	assert(is_equal_approx(float(attack.get("state_age", 0.0)), state_age_before))
	game.is_multiplayer = false

	game.shared_boss_attack_contract.reset_visual_events()
	var first_events: Array = game.shared_boss_attack_contract.consume_visual_events([attack])
	assert(first_events.size() == 1)
	assert(String(first_events[0].get("stage", "")) == "telegraph")
	assert(game.shared_boss_attack_contract.consume_visual_events([attack]).is_empty())
	attack["impact"] = true
	var impact_events: Array = game.shared_boss_attack_contract.consume_visual_events([attack])
	assert(impact_events.size() == 1)
	assert(String(impact_events[0].get("stage", "")) == "impact")
	assert(game.shared_boss_attack_contract.consume_visual_events([attack]).is_empty())


func _run() -> void:
	game._start_game()
	var solo: Dictionary = _run_one_party_size(1)
	var duo: Dictionary = _run_one_party_size(2)
	var trio: Dictionary = _run_one_party_size(3)
	assert(float(duo["gap"]) < float(solo["gap"]))
	assert(float(trio["gap"]) < float(duo["gap"]))
	_test_target_lifecycle()
	_test_replica_and_visual_idempotency()

	_configure(1)
	game.player_pos = game.boss_pos + Vector2(180.0, 0.0)
	game._add_boss_pincer_tenaz()
	var damage_attack: Dictionary = game.boss_attacks[0]
	game._update_boss_attacks(float(damage_attack["warning"]) + 0.01)
	game.player_pos = game.boss_pos + Vector2(90.0, 0.0)
	game._update_boss_attacks(0.2)
	var expected_damage: int = int(game.player_hp_max * 0.18 + 85)
	assert(is_equal_approx(game.player_hp, game.player_hp_max - expected_damage))
	var hp_after_hit: float = game.player_hp
	game._update_boss_attacks(0.1)
	assert(is_equal_approx(game.player_hp, hp_after_hit))

	var packet: Dictionary = game._pack_net_boss_visuals()
	var round_trip: Variant = bytes_to_var(var_to_bytes(packet))
	assert(round_trip is Dictionary)
	var synced_attacks: Array = Array(round_trip.get("boss_attacks", []))
	assert(synced_attacks.size() == game.boss_attacks.size())
	assert(String(synced_attacks[0].get("event_id", "")) == String(damage_attack.get("event_id", "")))
	assert(int(synced_attacks[0].get("seed", -1)) == int(damage_attack.get("seed", -2)))
	assert(int(synced_attacks[0].get("started_ms", 0)) == int(damage_attack.get("started_ms", -1)))
	assert(bool(synced_attacks[0].get("impact", false)) == bool(damage_attack.get("impact", false)))

	game.boss_ready = true
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game._start_boss_call_local()
	game._update_boss_call(game.BOSS_CALL_COUNTDOWN + 0.01)
	assert(game.boss_attacks.is_empty())

	print("BOSS1_PINCER_TENAZ_SMOKE_OK solo_duo_trio=true fixed_paths=true alternate_target=true death_revive=true disconnect_reconnect=true authority_only=true idempotent_hit=true idempotent_fx=true snapshot=true cleanup=true")
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(4):
		await process_frame
	quit(0)
