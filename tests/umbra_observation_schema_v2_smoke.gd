extends SceneTree

const Schema = preload("res://scripts/systems/umbra_observation_schema.gd")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("UMBRA_OBSERVATION_SCHEMA_V2_FAIL " + message)
	quit(1)


func _snapshot(players: Array) -> Dictionary:
	return {
		"umbra_hp_ratio": 0.5,
		"umbra_position_x": 800.0,
		"umbra_position_y": 450.0,
		"umbra_velocity_x": -320.0,
		"umbra_velocity_y": 220.0,
		"umbra_current_action": 6.0,
		"umbra_damage_recent": 240.0,
		"umbra_cooldown_vortice": 12.0,
		"players": players,
		"space_hazard_vortex": 1.0,
		"space_route_pressure": 0.5,
		"combat_projectile_pressure": 0.75,
		"history_player_distance_delta": -0.5,
		"multiplayer_player_count": players.size()
	}


func _assert_normalized(observation: Dictionary, label: String) -> void:
	var error := Schema.validate_observation(observation)
	_check(error == "", label + " invalid: " + error)
	var names: Array = Array(observation.get("feature_schema", []))
	_check(names.size() == observation.get("input_size", -1), label + " schema/input mismatch")
	var seen: Dictionary = {}
	for name_value in names:
		var name := String(name_value)
		_check(not seen.has(name), label + " duplicate " + name)
		seen[name] = true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var solo_players := [{"valid": true, "alive": true, "pos": Vector2(400, 300), "velocity": Vector2(80, -40), "hp": 75.0, "hp_max": 100.0, "cards": 8.0, "damage": 320.0, "manifestation": "eletrica", "stunned": false, "silenced": false, "action_recent": 1.0}]
	var solo_a := Schema.build_from_snapshot(_snapshot(solo_players))
	var solo_b := Schema.build_from_snapshot(_snapshot(solo_players))
	_assert_normalized(solo_a, "solo")
	_check(solo_a == solo_b, "same fixture was not deterministic")
	_check(int(solo_a.get("schema_version", -1)) == Schema.SCHEMA_VERSION, "schema version missing")
	_check(Array(solo_a.get("valid_player_mask", [])).size() == Schema.MAX_PLAYER_SLOTS, "solo mask size")
	_check(Array(solo_a.get("valid_player_mask", [])) == [1.0, 0.0, 0.0], "solo mask ordering")

	var multiplayer_players := solo_players.duplicate(true)
	multiplayer_players.append({"valid": true, "alive": true, "pos": Vector2(1150, 600), "velocity": Vector2(-120, 20), "hp": 30.0, "hp_max": 120.0, "cards": 13.0, "damage": 650.0, "manifestation": "prismatica", "stunned": true, "silenced": false, "action_recent": 0.5})
	multiplayer_players.append({"valid": true, "alive": false, "pos": Vector2(900, 120), "velocity": Vector2.ZERO, "hp": 0.0, "hp_max": 100.0, "cards": 4.0, "damage": 150.0, "manifestation": "necronada", "stunned": false, "silenced": true, "action_recent": 0.0})
	var multiplayer := Schema.build_from_snapshot(_snapshot(multiplayer_players))
	_assert_normalized(multiplayer, "multiplayer")
	_check(Array(multiplayer.get("valid_player_mask", [])) == [1.0, 1.0, 1.0], "multiplayer slot mask")
	_check(Array(multiplayer.get("feature_schema", [])).has("players.slot_2.alive"), "third ordered slot missing")
	_check(Array(multiplayer.get("feature_schema", [])).has("multiplayer.slot_2_valid"), "third multiplayer mask missing")

	var baseline := Schema.build_from_snapshot({})
	_assert_normalized(baseline, "baseline dummy")
	_check(Array(baseline.get("values", [])).size() == Array(solo_a.get("values", [])).size(), "baseline changed shape")

	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.boss_hp = 400.0
	game.boss_hp_max = 800.0
	game.boss_pos = Vector2(800, 450)
	game.player_pos = Vector2(400, 300)
	game.net_players_by_peer = {7: {"alive": true, "pos": Vector2(1100, 500), "hp": 50.0, "hp_max": 100.0, "velocity": Vector2(30, 0)}}
	var runtime_observation := Schema.build_from_runtime(game)
	_assert_normalized(runtime_observation, "runtime")
	_check(Array(runtime_observation.get("valid_player_mask", [])) == [1.0, 1.0, 0.0], "runtime peer slots were not ordered/masked")
	game._cleanup_runtime_resources()
	root.remove_child(game)
	await process_frame
	game.queue_free()
	for _frame in range(3):
		await process_frame
	print("UMBRA_OBSERVATION_SCHEMA_V2_OK features=%d slots=%d deterministic=true baseline=true multiplayer=true" % [int(solo_a.get("input_size", 0)), Schema.MAX_PLAYER_SLOTS])
	quit(0)
