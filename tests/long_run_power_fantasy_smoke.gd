extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("LONG_RUN_POWER_FANTASY_SMOKE_FAIL " + message)
	quit(1)


func _set_minute(minute: float, phase: int = 1, phase_elapsed: float = -1.0) -> void:
	game.current_phase = phase
	game.time_alive = minute * 60.0
	game.phase_started_at = game.time_alive - (phase_elapsed if phase_elapsed >= 0.0 else game.time_alive)
	game.phase1_limit_break_kills_start = -1
	game.enemies_killed = 120


func _run() -> void:
	game._start_game()
	game.is_multiplayer = false
	game.mode = "game"
	game.enemies.clear()
	game.enemy_bullets.clear()

	_set_minute(15.0)
	var point_mult_15: float = game._long_run_point_multiplier()
	var hp_growth_15: float = game._long_run_enemy_hp_growth_multiplier()
	var spawn_15: float = game._enemy_spawn_interval()
	_check(is_equal_approx(point_mult_15, 4.2), "0-15 construction economy changed unexpectedly")
	_check(is_equal_approx(hp_growth_15, 1.0), "0-15 enemy HP growth should keep baseline")

	_set_minute(30.0)
	var point_mult_30: float = game._long_run_point_multiplier()
	var hp_growth_30: float = game._long_run_enemy_hp_growth_multiplier()
	var spawn_30: float = game._enemy_spawn_interval()
	_check(point_mult_30 > point_mult_15, "15-30 economy did not accelerate")
	_check(is_equal_approx(hp_growth_30, 1.0), "rupture mark should not pre-nerf enemy HP growth")
	_check(spawn_30 < spawn_15, "spawn cadence did not ramp into rupture")

	_set_minute(45.0)
	var point_mult_45: float = game._long_run_point_multiplier()
	var hp_growth_45: float = game._long_run_enemy_hp_growth_multiplier()
	var spawn_45: float = game._enemy_spawn_interval()
	_check(is_equal_approx(point_mult_45, game.POINT_REWARD_MAX_MULT), "40-45 good build economy should hit cap")
	_check(is_equal_approx(hp_growth_45, game.LONG_RUN_ENEMY_HP_GROWTH_BROKEN_MULT), "45m HP growth taper mismatch")
	_check(spawn_45 < spawn_30, "45m spawn cadence should be denser than rupture")

	_set_minute(60.0)
	var hp_growth_60: float = game._long_run_enemy_hp_growth_multiplier()
	var spawn_60: float = game._enemy_spawn_interval()
	_check(is_equal_approx(game._long_run_point_multiplier(), game.POINT_REWARD_MAX_MULT), "60m economy should stay capped for endless")
	_check(is_equal_approx(hp_growth_60, game.LONG_RUN_ENEMY_HP_GROWTH_ENDLESS_MULT), "60m endless HP growth taper mismatch")
	_check(spawn_60 < spawn_45, "60m endless spawn cadence should stay denser")

	_set_minute(29.9, 2, game.PHASE2_PYRO_UNLOCK_TIME)
	var phase2_cap_before: int = game._enemy_limit()
	_set_minute(45.0, 2, game.PHASE2_PYRO_UNLOCK_TIME)
	var phase2_cap_45: int = game._enemy_limit()
	_set_minute(60.0, 2, game.PHASE2_PYRO_UNLOCK_TIME)
	var phase2_cap_60: int = game._enemy_limit()
	_check(phase2_cap_before == game.PHASE2_COMMON_LIMIT + game.PHASE2_KAMIKAZE_LIMIT + game.PHASE2_PYRO_LIMIT, "pre-rupture cap should keep current phase 2 baseline")
	_check(phase2_cap_45 == phase2_cap_before + game.LONG_RUN_ENEMY_LIMIT_BROKEN_BONUS, "45m cap bonus mismatch")
	_check(phase2_cap_60 == phase2_cap_before + game.LONG_RUN_ENEMY_LIMIT_ENDLESS_BONUS, "60m cap bonus mismatch")

	_set_minute(45.0)
	var enemy := {"points": 20}
	_check(game._points_for_enemy(enemy) == 320, "45m point reward should reflect capped power fantasy economy")
	_check(game._long_run_enemy_limit_bonus() == game.LONG_RUN_ENEMY_LIMIT_BROKEN_BONUS, "45m density bonus mismatch")

	print("LONG_RUN_POWER_FANTASY_SMOKE_OK economy=%.2f/%.2f/%.2f hp_growth=%.2f/%.2f spawn=%.2f/%.2f/%.2f caps=%d/%d/%d" % [point_mult_15, point_mult_30, point_mult_45, hp_growth_45, hp_growth_60, spawn_30, spawn_45, spawn_60, phase2_cap_before, phase2_cap_45, phase2_cap_60])
	game.mode = "menu"
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.visible = false
	game.set_process(false)
	game.set_physics_process(false)
	game._cleanup_runtime_resources()
	for i in range(4):
		await process_frame
	root.remove_child(game)
	game.free()
	game = null
	await process_frame
	await process_frame
	quit(0)
