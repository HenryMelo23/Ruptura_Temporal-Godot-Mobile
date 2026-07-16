extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _assert_phase1_pool(at_time: float, allowed: Array, iterations := 80) -> void:
	game.current_phase = 1
	game.time_alive = at_time
	game.enemies.clear()
	for i in range(iterations):
		var kind: String = game._choose_enemy_type()
		assert(allowed.has(kind), "unexpected phase1 enemy %s at %.1fs" % [kind, at_time])


func _run() -> void:
	game.mode = "game"
	game.is_multiplayer = false
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.player_pos = Vector2(640, 360)
	game.player_hp_max = 1000
	game.player_hp = 1000

	_assert_phase1_pool(179.0, [game.ENEMY_COMMON])
	_assert_phase1_pool(360.0, [game.ENEMY_COMMON, game.ENEMY_STALKER])
	_assert_phase1_pool(480.0, [game.ENEMY_COMMON, game.ENEMY_STALKER, game.ENEMY_PROJECTOR])
	_assert_phase1_pool(600.0, [game.ENEMY_COMMON, game.ENEMY_STALKER, game.ENEMY_PROJECTOR, game.ENEMY_SHIELD_REFLECTOR, game.ENEMY_CRYSTAL])
	_assert_phase1_pool(780.0, [game.ENEMY_COMMON, game.ENEMY_STALKER, game.ENEMY_PROJECTOR, game.ENEMY_SHIELD_REFLECTOR, game.ENEMY_CRYSTAL, game.ENEMY_CURATER])
	_assert_phase1_pool(930.0, [game.ENEMY_COMMON, game.ENEMY_STALKER, game.ENEMY_PROJECTOR, game.ENEMY_SHIELD_REFLECTOR, game.ENEMY_CRYSTAL, game.ENEMY_CURATER, game.ENEMY_COUT_ATTACK_SPEED])

	game.current_phase = 1
	game.time_alive = game.PHASE1_LIMIT_BREAK_TIME - 1.0
	game.enemies_killed = 80
	game.phase1_limit_break_kills_start = -1
	assert(game._enemy_limit() == game.ENEMY_MAX_BASE)
	game.time_alive = game.PHASE1_LIMIT_BREAK_TIME
	game.enemies_killed = 40
	assert(game._enemy_limit() == game.ENEMY_MAX_BASE)
	game.enemies_killed = 69
	assert(game._enemy_limit() == game.ENEMY_MAX_BASE)
	game.enemies_killed = 70
	assert(game._enemy_limit() == game.ENEMY_MAX_BASE + 1)

	game.current_phase = 2
	game.phase_started_at = 100.0
	game.time_alive = game.phase_started_at + 239.0
	assert(game._enemy_limit() == game.PHASE2_COMMON_LIMIT)
	for i in range(30):
		assert(game._choose_phase2_enemy_type() == game.ENEMY_COMMON)
	game.time_alive = game.phase_started_at + game.PHASE2_KAMIKAZE_UNLOCK_TIME
	assert(game._enemy_limit() == game.PHASE2_COMMON_LIMIT + game.PHASE2_KAMIKAZE_LIMIT)
	game.time_alive = game.phase_started_at + game.PHASE2_PYRO_UNLOCK_TIME
	assert(game._enemy_limit() == game.PHASE2_COMMON_LIMIT + game.PHASE2_KAMIKAZE_LIMIT + game.PHASE2_PYRO_LIMIT)

	game.current_phase = 3
	game.phase_started_at = 200.0
	game.time_alive = game.phase_started_at + 120.0
	assert(game._enemy_limit() == game.PHASE3_LIMIT_EARLY)
	for i in range(30):
		assert(game._choose_enemy_type() == game.ENEMY_COMMON)
	game.time_alive = game.phase_started_at + game.PHASE3_INCENSARIO_UNLOCK_TIME
	assert(game._enemy_limit() == game.PHASE3_LIMIT_MID)
	game.time_alive = game.phase_started_at + game.PHASE3_GUARDIAO_UNLOCK_TIME
	assert(game._enemy_limit() == game.PHASE3_LIMIT_FULL)

	game.current_phase = 4
	game.phase_started_at = 300.0
	game.time_alive = game.phase_started_at + 90.0
	assert(game._enemy_limit() == game.PHASE4_LIMIT_EARLY)
	game.time_alive = game.phase_started_at + game.PHASE4_ADAPT_TIME
	assert(game._enemy_limit() == game.PHASE4_LIMIT_FULL)

	game.current_phase = 2
	game.phase_started_at = 100.0
	game.enemies.clear()
	for i in range(4):
		game._spawn_enemy(game.ENEMY_COMMON, Vector2(120 + i * 24, 160))
		game.enemies[i]["uid"] = i + 1
		game.enemies[i]["shoot_cd"] = 0.0
	game.time_alive = game.phase_started_at
	assert(game._phase2_common_penguin_can_shoot(game.enemies[0]))
	assert(game._phase2_common_penguin_can_shoot(game.enemies[1]))
	assert(not game._phase2_common_penguin_can_shoot(game.enemies[2]))
	assert(not game._phase2_common_penguin_can_shoot(game.enemies[3]))
	game.time_alive = game.phase_started_at + 2.4
	assert(not game._phase2_common_penguin_can_shoot(game.enemies[0]))
	assert(not game._phase2_common_penguin_can_shoot(game.enemies[1]))
	assert(game._phase2_common_penguin_can_shoot(game.enemies[2]))
	assert(game._phase2_common_penguin_can_shoot(game.enemies[3]))

	game.player_hp = 1000
	game.player_silence_timer = 0.0
	game.enemy_far_damage = 20.0
	game._apply_arauto_silence_hit(game.player_pos, game.ARAUTO_SILENCE_RADIUS, false)
	assert(game.player_silence_timer > 0.0)
	assert(game.player_hp < 1000)

	game.cards_bought.clear()
	var locked_reward: Array = game._pick_boss_reward_cards(game.BOSS_REWARD_CARD_COUNT, game.BOSS_REWARD_RARE_COUNT)
	assert(locked_reward.size() == game.BOSS_REWARD_CARD_COUNT)
	assert(locked_reward.all(func(card): return not game._is_rare_card(card)))
	game.cards_bought["Sorte"] = 1
	var unlocked_reward: Array = game._pick_boss_reward_cards(game.BOSS_REWARD_CARD_COUNT, game.BOSS_REWARD_RARE_COUNT)
	assert(unlocked_reward.size() == game.BOSS_REWARD_CARD_COUNT)
	assert(unlocked_reward.filter(func(card): return game._is_rare_card(card)).size() == game.BOSS_REWARD_RARE_COUNT)

	print("BALANCE_PROGRESSION_SMOKE_OK phase1_gates=true phase2_limits=true phase3_ramp=true phase4_ramp=true penguin_alternation=true arauto_silence=true boss_reward=true")
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
