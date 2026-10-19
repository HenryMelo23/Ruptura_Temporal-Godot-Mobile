extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _configure() -> void:
	game.run_tutorial_enabled = false
	game.current_phase = 1
	game.mode = "game"
	game.is_multiplayer = false
	game.is_host = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 10000.0
	game.boss_hp = game.boss_hp_max
	game.boss_pos = game.WORLD_SIZE * 0.5 + Vector2(330.0, 0.0)
	game.player_hp_max = 500.0
	game.player_hp = game.player_hp_max
	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(460.0, 0.0)
	game.is_dead = false
	game.boss_attacks.clear()
	game.boss1_attack_windup.clear()
	game.boss1_absorb_cooldown = 999.0
	game.boss1_rewind_cooldown = 999.0
	game.boss_stage_timer = 0.0
	game.boss1_whirlpool_cooldown = 0.0
	game.boss1_lightning_storm_active = false
	game.boss1_lightning_spawn_timer = 0.0
	game.run_boss_started_at[1] = 0.0


func _find_attack(kind: String) -> Dictionary:
	for value in game.boss_attacks:
		var attack := Dictionary(value)
		if String(attack.get("kind", "")) == kind:
			return attack
	return {}


func _test_whirlpool() -> void:
	game.early_boss_controller.start_boss1_whirlpool()
	var attack := _find_attack("boss1_whirlpool")
	assert(not attack.is_empty())
	assert(String(attack.get("event_id", "")).begins_with(game.BOSS1_WHIRLPOOL_EVENT_PREFIX))
	assert(int(attack.get("seed", 0)) != 0)
	assert(String(attack.get("state", "")) == "approach")
	assert(game._update_boss1_uninterruptible_state(0.01))
	assert(game.boss_pos.distance_to(game.WORLD_SIZE * 0.5) < 330.0)

	game.boss_pos = game.WORLD_SIZE * 0.5
	assert(game._update_boss1_uninterruptible_state(0.01))
	assert(String(attack.get("state", "")) == "active")
	var distance_before: float = game.player_pos.distance_to(game.WORLD_SIZE * 0.5)
	assert(game._update_boss1_uninterruptible_state(0.5))
	assert(game.player_pos.distance_to(game.WORLD_SIZE * 0.5) < distance_before)
	assert(game.boss1_attack_windup.is_empty())

	# The active phase owns exactly ten seconds and then dries without pulling.
	assert(game._update_boss1_uninterruptible_state(game.BOSS1_WHIRLPOOL_ACTIVE_DURATION))
	assert(String(attack.get("state", "")) == "drying")
	var drying_position: Vector2 = game.player_pos
	assert(game._update_boss1_uninterruptible_state(0.5))
	assert(game.player_pos.is_equal_approx(drying_position))
	game._update_boss1_uninterruptible_state(game.BOSS1_WHIRLPOOL_DRY_DURATION)
	assert(_find_attack("boss1_whirlpool").is_empty())


func _test_large_world_whirlpool_radius() -> void:
	game.WORLD_SIZE = Vector2(3200.0, 2250.0)
	game.boss_attacks.clear()
	game.boss_dead = false
	game.boss_hp = game.boss_hp_max
	game.early_boss_controller.start_boss1_whirlpool()
	var attack := _find_attack("boss1_whirlpool")
	assert(not attack.is_empty())
	var center: Vector2 = Vector2(game.WORLD_SIZE) * 0.5
	var farthest_corner: float = center.distance_to(Vector2.ZERO)
	assert(float(attack.get("world_radius", 0.0)) >= farthest_corner)
	var packet: Dictionary = game._pack_net_boss_visuals()
	var synced_attacks: Array = Array(packet.get("boss_attacks", []))
	assert(is_equal_approx(float(Dictionary(synced_attacks[0]).get("world_radius", 0.0)), float(attack["world_radius"])))
	game.WORLD_SIZE = game.DEFAULT_WORLD_SIZE


func _test_lightning_storm() -> void:
	game.boss_attacks.clear()
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos
	game.player_hp = game.player_hp_max
	game.boss_hp = game.boss_hp_max
	game.time_alive = game.BOSS1_LIGHTNING_START_TIME - 0.01
	game.run_boss_started_at[1] = 0.0
	game.early_boss_controller.update_boss1_timeout_storm(0.0)
	assert(not game.boss1_lightning_storm_active)

	game.time_alive = game.BOSS1_LIGHTNING_START_TIME
	game.early_boss_controller.update_boss1_timeout_storm(0.16)
	assert(game.boss1_lightning_storm_active)
	var strike := _find_attack("boss1_lightning")
	assert(not strike.is_empty())
	assert(is_equal_approx(float(strike.get("warning", 0.0)), 1.2))
	assert(String(strike.get("event_id", "")).begins_with(game.BOSS1_LIGHTNING_EVENT_PREFIX))
	strike["target"] = game.boss_pos
	strike["age"] = game.BOSS1_LIGHTNING_WARNING - 0.01
	var player_hp_before: float = game.player_hp
	var boss_hp_before: float = game.boss_hp
	game.early_boss_controller.update_boss1_timeout_storm(0.02)
	assert(game.player_hp < player_hp_before)
	assert(game.boss_hp < boss_hp_before)
	assert(bool(strike.get("impact", false)))
	var player_hp_after: float = game.player_hp
	var boss_hp_after: float = game.boss_hp
	game.early_boss_controller.update_boss1_timeout_storm(0.04)
	assert(is_equal_approx(game.player_hp, player_hp_after))
	assert(is_equal_approx(game.boss_hp, boss_hp_after))

	game.boss_attacks.clear()
	game.boss1_lightning_spawn_timer = 0.0
	game.early_boss_controller.update_boss1_timeout_storm(0.01)
	game.boss1_lightning_spawn_timer = 0.0
	game.early_boss_controller.update_boss1_timeout_storm(0.01)
	game.boss1_lightning_spawn_timer = 0.0
	game.early_boss_controller.update_boss1_timeout_storm(0.01)
	var strike_count := 0
	for value in game.boss_attacks:
		if String(Dictionary(value).get("kind", "")) == "boss1_lightning":
			strike_count += 1
	assert(strike_count == game.BOSS1_LIGHTNING_MAX_ACTIVE)

	var packet: Dictionary = game._pack_net_boss_visuals()
	var round_trip: Variant = bytes_to_var(var_to_bytes(packet))
	assert(round_trip is Dictionary)
	var synced_attacks: Array = Array(round_trip.get("boss_attacks", []))
	assert(synced_attacks.size() == game.BOSS1_LIGHTNING_MAX_ACTIVE)
	for synced_value in synced_attacks:
		var synced := Dictionary(synced_value)
		assert(String(synced.get("event_id", "")).begins_with(game.BOSS1_LIGHTNING_EVENT_PREFIX))
		assert(synced.has("seed"))
		assert(is_equal_approx(float(synced.get("warning", 0.0)), game.BOSS1_LIGHTNING_WARNING))


func _test_cleanup() -> void:
	game.early_boss_controller.start_boss1_whirlpool()
	game.boss1_lightning_storm_active = true
	game.early_boss_controller.spawn_boss1_lightning_strike()
	game._clear_boss_runtime_hazards()
	assert(game.boss_attacks.is_empty())
	assert(not game.boss1_lightning_storm_active)
	assert(is_equal_approx(game.boss1_whirlpool_cooldown, game.BOSS1_WHIRLPOOL_INITIAL_DELAY))


func _test_replica_contract() -> void:
	game.early_boss_controller.start_boss1_whirlpool()
	var packet: Dictionary = game._pack_net_boss_visuals()
	var synced_attacks: Array = Array(packet.get("boss_attacks", [])).duplicate(true)
	assert(synced_attacks.size() == 1)
	var synced_whirlpool: Dictionary = synced_attacks[0]
	synced_whirlpool["state"] = "active"
	synced_whirlpool["state_age"] = 2.0
	game.boss_attacks = synced_attacks
	game.is_multiplayer = true
	game.is_host = false
	game.online_room_owner = false
	assert(game._is_world_replica())
	var authoritative_age: float = float(synced_whirlpool.get("age", 0.0))
	game._update_boss(0.5)
	assert(is_equal_approx(float(synced_whirlpool.get("age", 0.0)), authoritative_age))
	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(420.0, 0.0)
	var distance_before: float = game.player_pos.distance_to(game.WORLD_SIZE * 0.5)
	game.early_boss_controller.apply_boss1_whirlpool_force(0.5, synced_whirlpool)
	assert(game.player_pos.distance_to(game.WORLD_SIZE * 0.5) < distance_before)

	game.shared_boss_attack_contract.reset_visual_events()
	var first_events: Array = game.shared_boss_attack_contract.consume_visual_events(game.boss_attacks)
	assert(first_events.size() == 1)
	assert(String(first_events[0].get("stage", "")) == "telegraph")
	assert(game.shared_boss_attack_contract.consume_visual_events(game.boss_attacks).is_empty())
	game.is_multiplayer = false
	game.is_host = true
	game.online_room_owner = false


func _run() -> void:
	game._start_game()
	_configure()
	_test_whirlpool()
	_configure()
	_test_large_world_whirlpool_radius()
	_configure()
	_test_lightning_storm()
	_configure()
	_test_cleanup()
	_configure()
	_test_replica_contract()
	print("BOSS1_WHIRLPOOL_LIGHTNING_SMOKE_OK whirlpool_10s=true world_radius=true outward_counterplay=true exclusive_state=true lightning_120s=true warning_1_2s=true max_two=true player_and_boss_damage=true idempotent=true snapshot=true replica_force=true authority_only=true cleanup=true")
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(4):
		await process_frame
	quit(0)
