extends SceneTree

var game: Node

func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _run() -> void:
	game._start_game()

	print("[TEST] Verifying Boss Stats Scaling (+10% Defense, +35% HP)...")

	# Base HP check (Phase 1 / Base Constant)
	print("  - BOSS_BASE_HP constant: %.1f (expected: 4860.0)" % game.BOSS_BASE_HP)
	assert(is_equal_approx(game.BOSS_BASE_HP, 4860.0), "BOSS_BASE_HP should be 4860.0")

	# BOSS_ARMOR check
	print("  - BOSS_ARMOR constant: %.4f (expected: 0.5280)" % game.BOSS_ARMOR)
	assert(is_equal_approx(game.BOSS_ARMOR, 0.528), "BOSS_ARMOR should be 0.528")

	# Phase HP checks (assuming 0 score / kills for base values)
	game.score_total = 0
	game.enemies_killed = 0

	var hp1 = game._boss_hp_for_phase(1)
	print("  - Phase 1 Boss HP: %.1f (expected: 4860.0)" % hp1)
	assert(is_equal_approx(hp1, 4860.0), "Phase 1 HP mismatch")

	var hp2 = game._boss_hp_for_phase(2)
	print("  - Phase 2 Boss HP: %.1f (expected: 8910.0)" % hp2)
	assert(is_equal_approx(hp2, 8910.0), "Phase 2 HP mismatch")

	var hp3 = game._boss_hp_for_phase(3)
	print("  - Phase 3 Boss HP: %.1f (expected: 17280.0)" % hp3)
	assert(is_equal_approx(hp3, 17280.0), "Phase 3 HP mismatch")

	var hp4 = game._boss_hp_for_phase(4)
	print("  - Phase 4 Boss HP: %.1f (expected: 25380.0)" % hp4)
	assert(is_equal_approx(hp4, 25380.0), "Phase 4 HP mismatch")

	var hp5 = game._boss_hp_for_phase(5)
	print("  - Phase 5 Boss HP: %.1f (expected: 35100.0)" % hp5)
	assert(is_equal_approx(hp5, 35100.0), "Phase 5 HP mismatch")

	var hp6 = game._boss_hp_for_phase(6)
	print("  - Phase 6 Boss HP: %.1f (expected: 4860.0)" % hp6)
	assert(is_equal_approx(hp6, 4860.0), "Phase 6 HP mismatch")

	print("ALL_BOSS_STATS_SCALING_TESTS_OK")
	quit(0)
