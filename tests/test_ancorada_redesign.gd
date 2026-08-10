extends SceneTree

var game: Node

func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _check(condition: bool, msg: String) -> void:
	if not condition:
		printerr("[FAIL] " + msg)
		assert(false, msg)

func _run() -> void:
	game._start_game()
	game.manifestation_key = "ancorada"
	print("[TEST] Testing ANCORADA Redesign Mechanics...")

	# 1. Test Passive LASTRO accumulation
	game.lastro_stacks = 0
	game.lastro_points = 0
	game._add_lastro_points(1, "basic_attack")
	_check(game.lastro_points == 1 and game.lastro_stacks == 0, "1 point should equal 0 stacks, 1 point")

	game._add_lastro_points(3, "basic_attack") # total 4 points
	_check(game.lastro_stacks == 1 and game.lastro_points == 0, "4 points should convert to 1 stack")

	game._add_lastro_points(16, "test") # total 5 stacks (20 points)
	_check(game.lastro_stacks == 5 and game.lastro_points == 0, "20 points should convert to 5 stacks")

	# Test overflow cap
	game._add_lastro_points(10, "test")
	_check(game.lastro_stacks == 5 and game.lastro_points == 0, "LASTRO stacks should be capped at 5")

	# 2. Test Knockback Resistance
	var kb_mult_0 = game._inercia_knockback_multiplier()
	_check(is_equal_approx(kb_mult_0, 0.80), "L5 knockback mult should be 0.80 (20% resistance)")
	game.lastro_stacks = 0
	var kb_mult_5 = game._inercia_knockback_multiplier()
	_check(is_equal_approx(kb_mult_5, 1.0), "L0 knockback mult should be 1.0 (0% resistance)")

	# 3. Test LASTRO Decay
	game.lastro_stacks = 5
	game.lastro_points = 2
	game.lastro_decay_timer = 0.0

	# At 7.9s -> No decay
	game._update_lastro_decay(7.9)
	_check(game.lastro_stacks == 5 and game.lastro_points == 2, "Decay should not start before 8.0s")

	# At 8.1s -> Partial points zeroed, timer entered decay
	game._update_lastro_decay(0.2) # total 8.1s
	_check(game.lastro_points == 0, "Partial points should be zeroed after 8s")

	# At 10.1s -> 1 stack lost (4 stacks remaining)
	game._update_lastro_decay(2.0)
	_check(game.lastro_stacks == 4, "Should lose 1 stack after 2s interval in decay (expected 4)")

	# Hitting enemy interrupts decay
	game._add_lastro_points(1, "basic_attack")
	_check(game.lastro_decay_timer == 0.0, "Adding Lastro points should reset decay timer")

	# 4. Test HAB1 QUEDA DE CONTRAPESO Execution
	game.lastro_stacks = 4
	game.player_pos = Vector2(500, 500)
	var aim_target = Vector2(750, 420)
	game._trigger_hab1_ancorada(aim_target)
	_check(game.hab1_ancorada_active == true, "HAB1 should be active after trigger")
	_check(game.hab1_ancorada_cast_lastro == 4, "HAB1 should capture cast_lastro = 4")
	_check(game.hab1_ancorada_cast_pos == aim_target, "HAB1 should drop anchor at exact aimed target (750, 420)")

	# Player moves, cast_pos should remain fixed
	game.player_pos = Vector2(800, 800)
	_check(game.hab1_ancorada_cast_pos == aim_target, "HAB1 cast_pos should not move with player")

	# Update timer to impact at 0.38s
	game._update_hab1_ancorada(0.39)
	_check(game.hab1_ancorada_impact_done == true, "Impact should be done at 0.38s")
	_check(game.lastro_stacks == 0, "Impact should consume all LASTRO stacks")

	# 5. Verify old standing still passive is neutralized
	game.ancorada_prev_pos = Vector2(100, 100)
	game.player_pos = Vector2(100, 100) # completely stationary
	game._update_ancorada_standing_still(10.0)
	_check(game.ancorada_crit_bonus == 0.0, "Old standing still crit bonus should be neutralized (0.0)")

	print("ALL_ANCORADA_REDESIGN_TESTS_OK")
	quit(0)
