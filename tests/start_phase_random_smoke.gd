extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("START_PHASE_RANDOM_SMOKE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check_initial_phase_bias() -> void:
	game.force_phase6_start = false
	game.forced_initial_phase = 0
	game._set_initial_phase_bias(6, 1.0, false)
	game.rng.seed = 101
	_check(int(game._pick_initial_phase()) == 6, "phase bias should force phase 6 at 100 percent")
	game._set_initial_phase_bias(1, 1.0, false)
	game.rng.seed = 202
	_check(int(game._pick_initial_phase()) == 1, "phase bias should force phase 1 at 100 percent")
	game.run_finalized_result = ""
	game.time_alive = 8.0
	game.boss_dead = false
	game.initial_phase_current_run = 6
	game.initial_phase_current_recorded = false
	game._record_initial_phase_attempt_before_new_run()
	_check(int(game.initial_phase_bias_target) == 6, "quick exit should bias the same initial phase")
	_check(is_equal_approx(float(game.initial_phase_bias_strength), float(game.INITIAL_PHASE_QUICK_EXIT_BIAS)), "quick exit bias strength mismatch")
	game._set_initial_phase_bias(0, 0.0, false)
	game.initial_phase_current_recorded = true


func _check_phase_route_and_boss_hp() -> void:
	game.score_total = 900
	game.enemies_killed = 27
	var phase1_hp := float(game._boss_hp_for_phase(1))
	var phase6_hp := float(game._boss_hp_for_phase(6))
	_check(phase6_hp >= phase1_hp, "phase 6 boss hp should not be lower than phase 1 scaling")
	var region_names: Dictionary = {}
	for phase_id in game.DIMENSION_ROUTE_POOL + [game.DIMENSION_FINAL_PHASE]:
		var region_name: String = String(game._phase_region_name(int(phase_id)))
		_check(region_name != "" and not region_name.begins_with("FASE"), "map still uses a numbered phase label")
		region_names[region_name] = true
	_check(region_names.size() == 7, "map region names are not unique")
	game.rng.seed = 7781
	game._begin_initial_phase_tracking(6)
	_check(Array(game.dimension_route_queue).size() == 3, "initial cycle did not queue three additional maps")
	var cycle: Array[int] = [6]
	for queued in game.dimension_route_queue:
		cycle.append(int(queued))
	_check(cycle.all(func(value): return int(value) in game.DIMENSION_ROUTE_POOL and int(value) != game.DIMENSION_FINAL_PHASE), "cycle selected Umbra or an invalid map")
	var unique_cycle: Dictionary = {}
	for phase_value in cycle:
		unique_cycle[phase_value] = true
	_check(unique_cycle.size() == 4, "cycle repeated a map before the fourth boss")
	for index in range(cycle.size()):
		game._register_dimension_phase_completed(cycle[index])
		if index < cycle.size() - 1:
			_check(not game._should_offer_dimension_choice_after_boss(cycle[index]), "portals opened before four bosses")
			_check(int(game._consume_next_phase_after_boss(cycle[index])) == cycle[index + 1], "queued random route was not consumed in order")
	_check(game._should_offer_dimension_choice_after_boss(cycle.back()), "fourth defeated boss did not open the two route portals")


func _check_forced_initial_phase_cheats() -> void:
	var expected_names := {
		1: "CARANGUEJO COSMICO GIGANTE",
		2: "SENTINELA GLACIAL",
		3: "PAI-RATO",
		4: "NEXO ANFIBIO",
		5: "UMBRA",
		6: "MATRIARCA DA CHAGA",
		7: "FENIX"
	}
	for phase in range(1, 8):
		game.gameplay_cheat_text = "FASE%d" % phase
		_check(game._try_unlock_retornante_cheat(), "FASE%d cheat was not accepted" % phase)
		_check(int(game.forced_initial_phase) == phase, "FASE%d did not set forced initial phase" % phase)
		_check(bool(game.force_phase6_start) == (phase == 6), "legacy phase6 flag mismatch for FASE%d" % phase)
		game._start_game()
		_check(int(game.current_phase) == phase, "FASE%d did not start on requested phase" % phase)
		_check(String(game.boss_name) == String(expected_names[phase]), "FASE%d boss name mismatch" % phase)
		_check(game.enemies.size() >= 1, "FASE%d did not spawn initial enemies" % phase)
		_check(game._current_map_texture() != null, "FASE%d map texture missing" % phase)
		if phase == 7:
			_check(not bool(game.boss_ready), "FASE7 should start without boss call")
			_check(String(game.enemies[0].get("type", "")) == game.ENEMY_CINERIDO, "FASE7 should start with Cinerido")
	game.gameplay_cheat_text = "FASE3"
	_check(game._try_unlock_retornante_cheat(), "FASE3 cheat was not accepted before phase6 replace")
	game.gameplay_cheat_text = "FASE6"
	_check(game._try_unlock_retornante_cheat(), "FASE6 replace was not accepted")
	_check(int(game.forced_initial_phase) == 6, "FASE6 should replace previous forced phase before toggle check")
	game.gameplay_cheat_text = "FASE6"
	_check(game._try_unlock_retornante_cheat(), "FASE6 second toggle was not accepted")
	_check(int(game.forced_initial_phase) == 0, "FASE6 did not toggle itself off")
	game.gameplay_cheat_text = "FASE3"
	_check(game._try_unlock_retornante_cheat(), "FASE3 cheat was not accepted before auto reset")
	game.gameplay_cheat_text = "FASEAUTO"
	_check(game._try_unlock_retornante_cheat(), "FASEAUTO cheat was not accepted")
	_check(int(game.forced_initial_phase) == 0, "FASEAUTO did not clear forced phase")
	_check(not bool(game.force_phase6_start), "FASEAUTO did not clear legacy phase6 flag")


func _run() -> void:
	await process_frame
	_check_initial_phase_bias()
	_check_phase_route_and_boss_hp()
	_check_forced_initial_phase_cheats()
	game.force_phase6_start = false
	game.forced_initial_phase = 0
	game._set_initial_phase_bias(0, 0.0, false)
	var seen_phases: Dictionary = {}
	for seed_value in range(1, 96):
		game.rng.seed = int(seed_value * 7919 + 17)
		game._start_game()
		var phase := int(game.current_phase)
		_check(phase in game.INITIAL_PHASE_ROLL_POOL and phase != 5, "unexpected initial phase %d" % phase)
		_check(is_equal_approx(float(game.phase_started_at), 0.0), "initial phase timer should start at zero")
		_check(Array(game.dimension_route_queue).size() == 3, "new run did not prebuild the four-map cycle")
		seen_phases[phase] = true
		if phase == 1:
			_check(String(game.boss_name) == "CARANGUEJO COSMICO GIGANTE", "phase 1 boss name mismatch")
			_check(is_equal_approx(float(game.boss_hp_max), float(game.BOSS_BASE_HP)), "phase 1 boss hp mismatch")
			_check(game.enemies.size() == 1, "phase 1 should start with one enemy")
			_check(String(game.enemies[0].get("type", "")) == game.ENEMY_COMMON, "phase 1 initial enemy should be common")
		else:
			_check(game._current_map_texture() != null, "random initial map texture missing")
		if seen_phases.size() == game.INITIAL_PHASE_ROLL_POOL.size():
			break

	for expected_phase in game.INITIAL_PHASE_ROLL_POOL:
		_check(seen_phases.has(expected_phase), "eligible initial map %d was never rolled" % expected_phase)
	_check(not seen_phases.has(5), "Umbra was rolled as an initial map")
	print("START_PHASE_RANDOM_SMOKE_OK phases=[1,2,3,4,6,7] cycle=4 umbra_after_cycle=true forced=[1,2,3,4,5,6,7]")
	game._set_initial_phase_bias(0, 0.0, true)
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	for i in range(4):
		await process_frame
	quit(0)
