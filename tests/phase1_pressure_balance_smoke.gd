extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PHASE1_PRESSURE_BALANCE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _common_share(at_time: float, iterations: int = 1200) -> float:
	game.current_phase = 1
	game.phase_started_at = 0.0
	game.time_alive = at_time
	game.enemies.clear()
	game.rng.seed = int(at_time * 10.0) + 71
	var common_count := 0
	for index in range(iterations):
		if game._choose_enemy_type() == game.ENEMY_COMMON:
			common_count += 1
	return float(common_count) / float(iterations)


func _run() -> void:
	await process_frame
	game._start_game()
	game.is_multiplayer = false
	game.current_phase = 1
	game.phase_started_at = 0.0
	game.enemy_manager.phase_density_carry_cap = 0
	game.enemy_manager.phase_density_native_entry_cap = 0
	game.phase1_limit_break_kills_start = -1
	_check(game.PHASE1_LIMIT_BREAK_TIME == 600.0, "enemy limit still breaks after 600 seconds")

	game.time_alive = game.PHASE1_LIMIT_BREAK_TIME - 1.0
	game.enemies_killed = 300
	_check(game._enemy_limit() == game.ENEMY_MAX_BASE, "enemy cap grew before the break")
	game.time_alive = game.PHASE1_LIMIT_BREAK_TIME
	game.enemies_killed = 300
	_check(game._enemy_limit() == game.ENEMY_MAX_BASE, "enemy cap jumped at the break")
	game.enemies_killed += game.PHASE1_LIMIT_KILLS_PER_EXTRA
	_check(game._enemy_limit() == game.ENEMY_MAX_BASE + 1, "enemy cap did not grow after post-break kills")

	for probe_time in [360.0, 480.0, 600.0, 780.0]:
		var common_share := _common_share(probe_time)
		_check(common_share < 0.5, "common errantes remained the majority at %.0fs: %.1f%%" % [probe_time, common_share * 100.0])

	print("PHASE1_PRESSURE_BALANCE_OK limit_break=600 special_majority=true")
	quit(0)
