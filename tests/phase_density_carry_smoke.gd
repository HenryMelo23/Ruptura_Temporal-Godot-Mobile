extends SceneTree

const EnemyManagerScript = preload("res://scripts/systems/enemy_manager.gd")

class FakeGame:
	extends Node

	const ENEMY_MAX_BASE := 6
	const PHASE1_LIMIT_BREAK_TIME := 960.0
	const PHASE1_LIMIT_KILLS_PER_EXTRA := 30
	const PHASE2_COMMON_LIMIT := 6
	const PHASE2_KAMIKAZE_LIMIT := 2
	const PHASE2_PYRO_LIMIT := 1
	const PHASE2_KAMIKAZE_UNLOCK_TIME := 120.0
	const PHASE2_PYRO_UNLOCK_TIME := 300.0
	const PHASE3_COMMON_ONLY_TIME := 80.0
	const PHASE3_GUARDIAO_UNLOCK_TIME := 180.0
	const PHASE3_LIMIT_EARLY := 5
	const PHASE3_LIMIT_MID := 6
	const PHASE3_LIMIT_FULL := 7
	const PHASE4_ADAPT_TIME := 140.0
	const PHASE4_LIMIT_EARLY := 3
	const PHASE4_LIMIT_FULL := 4
	const PHASE7_ENEMY_LIMIT_BASE := 7
	const PHASE7_LIMIT_BREAK_TIME := 960.0
	const PHASE7_LIMIT_KILLS_PER_EXTRA := 50

	var current_phase := 1
	var phase_elapsed := 0.0
	var enemies_killed := 0
	var phase1_limit_break_kills_start := -1
	var mp_bonus := 0
	var enemies: Array = []

	func _multiplayer_enemy_limit_bonus() -> int:
		return mp_bonus

	func _long_run_enemy_limit_bonus() -> int:
		return 0

	func _phase_elapsed_time() -> float:
		return phase_elapsed


var manager: EnemyManager
var fake: FakeGame


func _initialize() -> void:
	manager = EnemyManagerScript.new()
	fake = FakeGame.new()
	root.add_child(fake)
	root.add_child(manager)
	manager.bind_game(fake)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PHASE_DENSITY_CARRY_FAIL " + message)
	quit(1)


func _enter_phase(phase: int, previous_cap: int, elapsed: float = 0.0, mp_bonus: int = 0) -> void:
	fake.current_phase = phase
	fake.phase_elapsed = elapsed
	fake.mp_bonus = mp_bonus
	fake.phase1_limit_break_kills_start = -1
	manager.prepare_phase_density_carry(previous_cap)


func _run() -> void:
	await process_frame

	fake.current_phase = 1
	fake.phase_elapsed = 0.0
	fake.mp_bonus = 0
	manager.prepare_phase_density_carry(100)
	_check(manager.get_enemy_limit() == fake.ENEMY_MAX_BASE, "phase1_changed")

	_enter_phase(2, 10)
	_check(manager.get_enemy_limit() == 7, "phase2_10_to_7")
	_check(manager.phase_density_native_entry_cap == fake.PHASE2_COMMON_LIMIT, "phase2_native_entry_wrong")

	_enter_phase(2, 100)
	_check(manager.get_enemy_limit() == 70, "phase2_100_to_70")

	fake.phase_elapsed = fake.PHASE2_PYRO_UNLOCK_TIME + 1.0
	_check(manager.get_enemy_limit() == 73, "phase2_time_growth_not_preserved")

	fake.enemies.resize(100)
	_check(manager.get_enemy_limit() == 73, "alive_enemy_count_changed_density_cap")

	_enter_phase(3, manager.get_enemy_limit())
	_check(manager.get_enemy_limit() == 51, "multiple_transition_not_70_percent")
	fake.phase_elapsed = fake.PHASE3_GUARDIAO_UNLOCK_TIME + 1.0
	_check(manager.get_enemy_limit() == 53, "phase3_growth_delta_not_preserved")

	_enter_phase(6, 100)
	_check(manager.get_enemy_limit() == 70, "phase6_100_to_70")
	fake.phase_elapsed = fake.PHASE1_LIMIT_BREAK_TIME + 1.0
	fake.enemies_killed = 300
	_check(manager.get_enemy_limit() == 70, "phase6_break_initial_should_not_jump")
	fake.enemies_killed = 360
	_check(manager.get_enemy_limit() == 72, "phase6_kill_growth_not_preserved")

	_enter_phase(2, 20, 0.0, 3)
	_check(manager.get_enemy_limit() == 14, "multiplayer_initial_scaling_changed")
	fake.phase_elapsed = fake.PHASE2_PYRO_UNLOCK_TIME + 1.0
	_check(manager.get_enemy_limit() == 17, "multiplayer_growth_delta_changed")

	_enter_phase(2, 1)
	_check(manager.get_enemy_limit() == 1, "global_min_cap_not_preserved")

	print("PHASE_DENSITY_CARRY_OK phase1=true ten_to_seven=true hundred_to_seventy=true growth=true multi=true alive_count_ignored=true")
	quit(0)
