extends SceneTree

var game: Node

func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _run() -> void:
	game._start_game()
	game._advance_to_phase(4)
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_pos = game.boss4_entry_target
	game.player_hp_max = 1000.0
	game.player_hp = 1000.0
	game.player_defense = 0.0
	game.player_pos = Vector2(620, 450)

	assert(is_equal_approx(game.BOSS4_ATTACK_INTERVAL, 2.8))
	assert(is_equal_approx(game.BOSS4_COMET_LIFETIME, 3.0))
	assert(is_equal_approx(game.BOSS4_SECONDARY_COOLDOWN, 15.0))
	assert(is_equal_approx(game.BOSS4_SECONDARY_WARNING, 0.5))
	assert(is_equal_approx(game.BOSS4_ULTIMATE_COOLDOWN, 54.0))
	assert(is_equal_approx(game.BOSS4_ULTIMATE_RAY_INTERVAL, 1.35))
	assert(is_equal_approx(game.BOSS4_ULTIMATE_RAY_WARNING, 0.45))
	assert(game.BOSS4_METEOR_COUNT == 3)

	game._spawn_boss4_comet()
	assert(game.enemy_bullets.size() == 1)
	assert(String(game.enemy_bullets[0].get("type", "")) == "boss4_comet")
	assert(is_equal_approx(float(game.enemy_bullets[0].get("life", 0.0)), 3.0))
	var comet_dir_before: Vector2 = Vector2(game.enemy_bullets[0]["dir"])
	game.player_pos = Vector2(820, 320)
	game._update_enemy_bullets(0.15)
	assert(Vector2(game.enemy_bullets[0]["dir"]).distance_to(comet_dir_before) > 0.0001)
	game.enemy_bullets.clear()

	game.phase4_enemy_hazards.clear()
	game._start_boss4_secondary()
	assert(game.boss4_secondary_active)
	assert(game.phase4_enemy_hazards.filter(func(h): return String(h.get("kind", "")) == "boss4_bubble").size() == 7)
	game._update_phase4_enemy_hazards(0.25)
	assert(float(game.phase4_enemy_hazards[0].get("age", 0.0)) > 0.0)
	game._update_boss4_secondary(8.0)
	assert(not game.boss4_secondary_active)

	game.phase4_enemy_hazards.clear()
	game.boss4_meteor_event_started = false
	game.boss4_meteor_event_timer = 0.0
	game._update_boss4_meteorites(0.01)
	assert(game.boss4_meteorites.size() == 3)
	game._update_boss4_meteorites(game.BOSS4_METEOR_WARNING + 0.05)
	assert(game.boss4_meteorites.all(func(m): return bool(m.get("impacted", false))))
	assert(game.phase4_enemy_hazards.any(func(h): return String(h.get("kind", "")) == "boss4_meteor_shockwave"))
	game._update_boss4_meteorites(game.BOSS4_METEOR_ARM_TIME + 0.05)
	assert(game.boss4_meteorites.any(func(m): return bool(m.get("draining", false))))
	assert(game.boss4_meteor_damage_bonus > 0.0)
	var drain_bonus_before: float = game.boss4_meteor_damage_bonus
	game._update_boss4_meteorites(0.50)
	assert(game.boss4_meteor_damage_bonus > drain_bonus_before)
	for meteor in game.boss4_meteorites:
		game._damage_phase4_planet_at(Vector2(meteor["pos"]), 9999.0, 80.0)
	game._update_boss4_meteorites(0.05)
	assert(game.boss4_meteorites.is_empty())

	game.phase4_enemy_hazards.clear()
	game.boss4_strike_sequence.clear()
	game.boss4_ultimate_active = false
	game._start_boss4_ultimate()
	assert(game.boss4_ultimate_active)
	game._update_boss4_ultimate(0.01)
	var rays: Array = game.phase4_enemy_hazards.filter(func(h): return String(h.get("kind", "")) == "boss4_ultimate_ray")
	assert(rays.size() == 1)
	rays[0]["pos"] = game.player_pos
	game._update_phase4_enemy_hazards(game.BOSS4_ULTIMATE_RAY_WARNING + 0.02)
	assert(bool(rays[0].get("triggered", false)))
	assert(not game.boss4_strike_sequence.is_empty())
	for i in range(12):
		game._update_boss4_strike_sequence(0.12)
	assert(game.boss4_strike_sequence.is_empty())
	game._finish_boss4_ultimate(true)
	assert(not game.boss4_ultimate_active)
	assert(is_equal_approx(game.boss4_ultimate_cooldown, game.BOSS4_ULTIMATE_COOLDOWN))

	print("BOSS4_NEXUS_MECHANICS_SMOKE_OK comet=true secondary_7_bubbles=true meteor_3=true drain=true lightning=true ultimate_20s=true strike=true")
	quit(0)
