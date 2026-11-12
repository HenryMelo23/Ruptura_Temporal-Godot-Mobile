extends SceneTree

var game: Node

func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _run() -> void:
	game._start_game()

	print("[TEST] Verifying drastic boss durability scaling...")

	# Base HP check (Phase 1 / Base Constant)
	print("  - BOSS_BASE_HP constant: %.1f (expected: 4860.0)" % game.BOSS_BASE_HP)
	assert(is_equal_approx(game.BOSS_BASE_HP, 4860.0), "BOSS_BASE_HP should be 4860.0")

	# BOSS_ARMOR check
	print("  - BOSS_ARMOR constant: %.4f (expected: 0.5280)" % game.BOSS_ARMOR)
	assert(is_equal_approx(game.BOSS_ARMOR, 0.528), "BOSS_ARMOR should be 0.528")

	# Phase HP checks (assuming 0 score / kills for base values)
	game.score_total = 0
	game.enemies_killed = 0

	var base_by_phase := {
		1: float(game.BOSS_BASE_HP),
		2: 8910.0,
		3: 17280.0,
		4: 25380.0,
		5: 35100.0,
		6: float(game.BOSS_BASE_HP) * float(game.BOSS6_HP_SCALE),
		7: float(game.BOSS_BASE_HP) * float(game.BOSS7_HP_SCALE)
	}
	for phase in range(1, 8):
		var hp: float = game._boss_hp_for_phase(phase)
		var durability: float = game._boss_phase_durability_multiplier(phase)
		var expected: float = float(base_by_phase[phase]) * durability
		print("  - Phase %d Boss HP: %.1f (durability x%.2f)" % [phase, hp, durability])
		assert(is_equal_approx(hp, expected), "Phase %d HP mismatch" % phase)
		assert(durability >= 3.0, "Phase %d durability is not drastic" % phase)

	print("ALL_BOSS_STATS_SCALING_TESTS_OK phases=7 min_durability=3.0")
	quit(0)
