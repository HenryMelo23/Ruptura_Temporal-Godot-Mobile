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
	game._add_boss_pincer_tenaz()
	assert(game.boss_attacks.size() == 1)
	var attack: Dictionary = game.boss_attacks[0]
	assert(String(attack.get("kind", "")) == "pincer_tenaz")
	assert(String(attack.get("event_id", "")).begins_with(game.BOSS1_PINCER_TENAZ_EVENT_PREFIX))
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
	game._update_boss_attacks(0.5)
	assert(game.boss_attacks.is_empty())
	return {"event_id": String(attack.get("event_id", "")), "gap": float(attack.get("gap", 0.0))}


func _run() -> void:
	game._start_game()
	var solo: Dictionary = _run_one_party_size(1)
	var duo: Dictionary = _run_one_party_size(2)
	var trio: Dictionary = _run_one_party_size(3)
	assert(float(duo["gap"]) < float(solo["gap"]))
	assert(float(trio["gap"]) < float(duo["gap"]))

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

	game.boss_ready = true
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game._start_boss_call_local()
	game._update_boss_call(game.BOSS_CALL_COUNTDOWN + 0.01)
	assert(game.boss_attacks.is_empty())

	print("BOSS1_PINCER_TENAZ_SMOKE_OK solo_duo_trio=true fixed_paths=true alternate_target=true fallback_same_target=true idempotent_hit=true snapshot=true cleanup=true")
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(4):
		await process_frame
	quit(0)
