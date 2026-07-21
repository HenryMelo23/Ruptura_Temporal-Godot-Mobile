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
	_check(is_equal_approx(phase6_hp, phase1_hp), "phase 6 boss hp should match phase 1 scaling")
	game.run_initial_phase = 6
	game.run_phase6_completed = false
	_check(int(game._next_phase_after_boss(6)) == 1, "initial phase 6 should transition to phase 1")
	_check(int(game._next_phase_after_boss(1)) == 2, "phase 1 should transition to phase 2")
	_check(int(game._next_phase_after_boss(2)) == 3, "phase 2 after initial phase 6 should transition to phase 3")
	game.run_initial_phase = 1
	game.run_phase6_completed = false
	_check(int(game._next_phase_after_boss(1)) == 2, "initial phase 1 should transition to phase 2")
	_check(int(game._next_phase_after_boss(2)) == 6, "phase 2 should insert phase 6 when it was not the initial phase")
	_check(int(game._next_phase_after_boss(6)) == 3, "inserted phase 6 should transition to phase 3 without loop")


func _check_forced_initial_phase_cheats() -> void:
	var expected_names := {
		1: "CARANGUEJO COSMICO GIGANTE",
		2: "SENTINELA GLACIAL",
		3: "PAI-RATO",
		4: "NEXO DA RUPTURA",
		5: "UMBRA",
		6: "MATRIARCA DA CHAGA"
	}
	for phase in range(1, 7):
		game.gameplay_cheat_text = "FASE%d" % phase
		_check(game._try_unlock_retornante_cheat(), "FASE%d cheat was not accepted" % phase)
		_check(int(game.forced_initial_phase) == phase, "FASE%d did not set forced initial phase" % phase)
		_check(bool(game.force_phase6_start) == (phase == 6), "legacy phase6 flag mismatch for FASE%d" % phase)
		game._start_game()
		_check(int(game.current_phase) == phase, "FASE%d did not start on requested phase" % phase)
		_check(String(game.boss_name) == String(expected_names[phase]), "FASE%d boss name mismatch" % phase)
		_check(game.enemies.size() >= 1, "FASE%d did not spawn initial enemies" % phase)
		_check(game._current_map_texture() != null, "FASE%d map texture missing" % phase)
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
	var seen_phase_1 := false
	var seen_phase_6 := false
	for seed_value in range(1, 96):
		game.rng.seed = int(seed_value * 7919 + 17)
		game._start_game()
		var phase := int(game.current_phase)
		_check(phase == 1 or phase == 6, "unexpected initial phase %d" % phase)
		_check(is_equal_approx(float(game.phase_started_at), 0.0), "initial phase timer should start at zero")
		if phase == 1:
			seen_phase_1 = true
			_check(String(game.boss_name) == "CARANGUEJO COSMICO GIGANTE", "phase 1 boss name mismatch")
			_check(is_equal_approx(float(game.boss_hp_max), float(game.BOSS_BASE_HP)), "phase 1 boss hp mismatch")
			_check(game.enemies.size() == 1, "phase 1 should start with one enemy")
			_check(String(game.enemies[0].get("type", "")) == game.ENEMY_COMMON, "phase 1 initial enemy should be common")
		else:
			seen_phase_6 = true
			_check(String(game.boss_name) == "MATRIARCA DA CHAGA", "phase 6 boss name mismatch")
			_check(is_equal_approx(float(game.boss_hp_max), float(game._boss_hp_for_phase(6))), "phase 6 boss hp mismatch")
			_check(game.boss_pos == Vector2(game.WORLD_SIZE.x + 220.0, game.WORLD_SIZE.y * 0.36), "phase 6 boss start pos mismatch")
			_check(game.enemies.size() == 1, "phase 6-1 should start with one enemy")
			_check(String(game.enemies[0].get("type", "")) == game.ENEMY_LODARIO, "phase 6-1 initial enemy should be Lodario")
			_check(is_equal_approx(float(game.enemies[0].get("max_hp", 0.0)), float(game.ENEMY_BASE_HP)), "phase 6-1 Lodario should use phase 1 common hp")
			_check(game._boss_texture() != null, "phase 6 boss texture missing")
			_check(game._current_map_texture() != null, "phase 6 map texture missing")
		if seen_phase_1 and seen_phase_6:
			break

	_check(seen_phase_1, "phase 1 was not rolled")
	_check(seen_phase_6, "phase 6 was not rolled")
	print("START_PHASE_RANDOM_SMOKE_OK phases=[1,6] forced=[1,2,3,4,5,6]")
	game._set_initial_phase_bias(0, 0.0, true)
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	for i in range(4):
		await process_frame
	quit(0)
