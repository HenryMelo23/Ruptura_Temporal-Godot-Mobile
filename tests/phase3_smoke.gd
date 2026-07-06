extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._advance_to_phase(3)
	assert(game.current_phase == 3)
	assert(game._current_map_texture() != null)
	assert(game.current_music == "Fase3-1.mp3" or game.current_music == "Fase3-2.mp3" or game.current_music == "Esgoto.mp3")

	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(300, 300))
	game._spawn_enemy(game.ENEMY_INCENSARIO, Vector2(600, 300))
	game._spawn_enemy(game.ENEMY_GUARDIAO, Vector2(900, 300))
	assert(game._enemy_type_count(game.ENEMY_DEVOTO) >= 1)
	assert(game._enemy_type_count(game.ENEMY_INCENSARIO) >= 1)
	assert(game._enemy_type_count(game.ENEMY_GUARDIAO) >= 1)

	game.boss_active = true
	game.boss_hp_max = 8200.0
	game.boss_hp = game.boss_hp_max * 0.84
	game.boss_entry_timer = 0.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game._update_boss_phase3(0.016)
	assert(game.boss3_events.has("cheese85"))
	assert(not game.phase3_cheeses.is_empty())

	var cheese = game.phase3_cheeses[0]
	game._damage_phase3_cheeses_at(cheese["pos"], 9999.0, 4.0)
	assert(game.boss3_faith == 35.0)

	game.boss_hp = game.boss_hp_max * 0.59
	game._update_boss_phase3(0.016)
	assert(game.boss3_events.has("cheese60"))
	assert(game._enemy_type_count(game.ENEMY_DEVOTO) >= 3)

	game.boss_hp = game.boss_hp_max * 0.24
	game._update_boss_phase3(0.016)
	assert(game.boss3_events.has("ritual"))
	assert(game.boss3_ritual_timer > 0.0)
	assert(game.phase3_cheeses.size() == 3)
	game.locked_target_kind = "cheese"
	game.locked_target_uid = int(game.phase3_cheeses[0]["uid"])
	assert(game._locked_attack_target_pos() == Vector2(game.phase3_cheeses[0]["pos"]))

	game._start_boss3_rain()
	game._update_boss3_attacks(0.70)
	assert(game.enemy_bullets.size() >= 3)
	game.boss_attacks.clear()
	game.boss3_ritual_timer = 0.0
	game.boss3_consume_uid = -1
	game.boss3_miasma_timer = 0.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(130, 0)
	game.player_hp_max = 1000
	game.player_hp = 1000
	game._start_boss3_faith_test()
	assert(game.boss3_faith_test_pulses_left == 15)
	game._update_boss3_faith_test(0.30)
	assert(game.boss_attacks.any(func(a): return a.get("kind") == "faith_pulse"))
	game._update_boss3_attacks(0.25)
	assert(game.boss3_faith_link_timer > 0.0)
	assert(game.controls_inverted_timer > 0.0)
	assert(game.player_hp == 750)
	assert(not game.boss_attacks.any(func(a): return a.get("kind") == "rat_charge"))

	game.current_phase = 2
	game.boss_dead = false
	game.boss_active = true
	game.boss_hp = 1.0
	game._damage_boss(999999.0, "eletrica")
	assert(int(game.phase_fragment.get("next_phase", 0)) == 3)
	game.current_phase = 3
	game.boss_dead = false
	game.boss_active = true
	game.boss_hp = 1.0
	game._damage_boss(999999.0, "eletrica")
	assert(int(game.phase_fragment.get("next_phase", 0)) == 4)

	print("PHASE3_SMOKE_OK enemies=%d cheeses=%d projectiles=%d faith=%d" % [game.enemies.size(), game.phase3_cheeses.size(), game.enemy_bullets.size(), int(game.boss3_faith)])
	quit(0)
