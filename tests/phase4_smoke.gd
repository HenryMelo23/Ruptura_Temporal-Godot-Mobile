extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game._advance_to_phase(4)
	assert(game.current_phase == 4)
	assert(game._current_map_texture() != null)
	assert(game.boss_name == "NEXO DA RUPTURA")
	assert(game._enemy_limit() == 4)
	assert(game.enemies.size() == 2)
	assert(game._enemy_texture(game.enemies[0]) != null)
	var phase4_kinds = [game.ENEMY_NEXUS_CARTOGRAPHER, game.ENEMY_NEXUS_CHRONOPHAGE, game.ENEMY_NEXUS_REFRACTOR, game.ENEMY_NEXUS_WEAVER, game.ENEMY_NEXUS_ECHO]
	assert(game.enemies.all(func(enemy): return String(enemy["type"]) in phase4_kinds))

	game.enemy_bullets.clear()
	game.enemy_bullets.append({"pos": Vector2(200, 200), "dir": Vector2.RIGHT, "life": 3.0, "damage": 250.0, "phase": 0.0, "type": "phase4_magic", "speed_mult": 1.0})
	assert(game.enemy_bullets.size() == 1)
	assert(game.enemy_bullets[0]["type"] == "phase4_magic")
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_defense = 0.0
	game.player_pos = Vector2(500, 450)
	var previous_player_pos: Vector2 = game.player_pos
	game.enemy_bullets[0]["pos"] = game.player_pos
	game._update_enemy_bullets(0.01)
	assert(game.player_hp < 1000)
	assert(game.player_pos != previous_player_pos)

	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 14500.0
	game.boss_hp = game.boss_hp_max
	game.boss_pos = game.boss4_entry_target
	game.phase4_planets.clear()
	game.boss4_attack_timer = 0.0
	game._update_boss_phase4(0.01)
	assert(game.phase4_planets.size() == 1)
	assert(game.phase4_planets[0]["hp"] == game.BOSS4_PLANET_HP)
	var planet_pos: Vector2 = game.phase4_planets[0]["pos"]
	game._update_phase4_environment(0.10)
	assert(game.phase4_planets[0]["pos"] != planet_pos)
	assert(game._damage_phase4_planet_at(game.phase4_planets[0]["pos"], 9999.0, 60.0))
	game._update_phase4_environment(0.01)
	assert(game.phase4_planets.is_empty())
	assert(game.phase4_null_zones.is_empty())

	game._spawn_boss4_planet()
	game.phase4_planets[0]["life"] = 0.01
	game.phase4_planets[0]["pos"] = Vector2(760, 420)
	game.player_pos = Vector2(120, 120)
	game._update_phase4_environment(0.02)
	assert(game.phase4_planets.is_empty())
	assert(game.phase4_null_zones.size() == 1)
	game.player_pos = game.phase4_null_zones[0]["pos"]
	game.player_hp = 1000
	game.phase4_null_zones[0]["tick"] = 0.0
	game._update_phase4_environment(0.01)
	assert(game.player_hp == 900)

	game.phase4_null_zones.clear()
	game.enemies.clear()
	game.petro_active = true
	game.petro_pos = game.boss_pos
	game.petro_fire_timer = 0.0
	game.petro_hp = game.petro_hp_max
	var boss_hp_before: float = game.boss_hp
	game._update_petrov(0.01)
	assert(game.boss_hp < boss_hp_before)
	assert(game.petro_hp < game.petro_hp_max)

	game.current_phase = 3
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp = 1.0
	game._damage_boss(999999.0, "eletrica")
	assert(int(game.phase_fragment.get("next_phase", 0)) == 4)
	game._advance_to_phase(4)
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp = 1.0
	game._damage_boss(999999.0, "eletrica")
	assert(int(game.phase_fragment.get("next_phase", 0)) == 5)

	print("PHASE4_SMOKE_OK map=true enemies=true teleport=true planet=true vortex=true petro=true transition=true phase5_fragment=true")
	quit(0)
