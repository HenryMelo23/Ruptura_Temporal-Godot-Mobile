extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare_boss_stage(party_size: int, enraged: bool = false) -> void:
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.boss_hp_max = 6000.0
	game.boss_hp = game.boss_hp_max * (0.2 if enraged else 0.7)
	game.boss_party_scaling_phase = 1
	game.boss_party_scaling_size = party_size
	game.boss_party_scaling_hazard_bonus = party_size - 1
	game.boss_party_scaling_tempo_coeff = 1.0
	game.boss_stage_approaching = false
	game.boss_transition_waves.clear()
	game._start_boss_stage()
	game.boss_stage_safe_angle = 0.0
	game._update_boss_stage(game.boss_stage_duration - 0.01)


func _run() -> void:
	game._start_game()
	game.run_tutorial_enabled = false
	game.player_hp_max = 450.0
	game.player_hp = 450.0

	for party_size in [1, 2, 3]:
		_prepare_boss_stage(party_size)
		var expected_count: int = game.BOSS_STAGE_WAVE_COUNT + party_size - 1
		assert(game.boss_transition_waves.size() == expected_count)
		var ids: Dictionary = {}
		var angles: Array = []
		for wave in game.boss_transition_waves:
			assert(bool(wave.get("siege_tide", false)))
			assert(int(wave.get("party_size", 0)) == party_size)
			assert(float(wave.get("warning", 0.0)) >= 0.8)
			assert(String(wave.get("event_id", "")).begins_with(game.BOSS1_SIEGE_TIDE_EVENT_PREFIX))
			assert(not ids.has(String(wave.get("event_id", ""))))
			ids[String(wave.get("event_id", ""))] = true
			angles.append(float(wave.get("open_angle", 0.0)))
		assert(ids.size() == expected_count)
		if party_size > 1:
			assert(float(game.boss_transition_waves[1].get("age", 0.0)) < 0.0)
			assert(float(game.boss_transition_waves[1].get("desync", 0.0)) > 0.0)
		var before_angles: Array = angles.duplicate()
		game._update_boss_transition_waves(0.25)
		for index in range(game.boss_transition_waves.size()):
			assert(is_equal_approx(float(game.boss_transition_waves[index].get("open_angle", 0.0)), before_angles[index]))

	_prepare_boss_stage(1)
	var wave: Dictionary = game.boss_transition_waves[0]
	wave["age"] = float(wave["warning"])
	wave["radius"] = 220.0
	game.player_pos = game.boss_pos + Vector2.DOWN * 220.0
	game.player_hp = game.player_hp_max
	game._update_boss_transition_waves(0.0)
	var expected_damage: int = int(game.player_hp_max * game.BOSS_STAGE_WAVE_DAMAGE_RATE + game.BOSS_STAGE_WAVE_DAMAGE_FLAT)
	assert(is_equal_approx(game.player_hp, game.player_hp_max - expected_damage))
	var after_first_hit: float = game.player_hp
	game._update_boss_transition_waves(0.0)
	assert(is_equal_approx(game.player_hp, after_first_hit))

	game.boss_active = false
	game.boss_ready = true
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game._start_boss_call_local()
	game._update_boss_call(game.BOSS_CALL_COUNTDOWN + 0.01)
	assert(game.boss_transition_waves.is_empty())

	_prepare_boss_stage(3, true)
	assert(game.boss_transition_waves.size() == game.BOSS_STAGE_ENRAGED_WAVE_COUNT + 2)
	assert(game.boss_transition_waves.all(func(item): return bool(item.get("enraged", false))))
	assert(game.boss_transition_waves.all(func(item): return int(item.get("party_size", 0)) == 3))
	var visual_packet: Dictionary = game._pack_net_boss_visuals()
	var round_trip: Variant = bytes_to_var(var_to_bytes(visual_packet))
	assert(round_trip is Dictionary)
	var synced_waves: Array = Array(round_trip.get("boss_transition_waves", []))
	assert(synced_waves.size() == game.boss_transition_waves.size())
	assert(String(synced_waves[0].get("event_id", "")) == String(game.boss_transition_waves[0].get("event_id", "")))
	assert(int(synced_waves[0].get("seed", -1)) == int(game.boss_transition_waves[0].get("seed", -2)))

	print("BOSS1_SIEGE_TIDE_SMOKE_OK solo=4 duo=5 trio=6 enraged_trio=7 warning=%.2f damage=%d" % [
		game.BOSS1_SIEGE_TIDE_WARNING,
		expected_damage
	])
	quit(0)
