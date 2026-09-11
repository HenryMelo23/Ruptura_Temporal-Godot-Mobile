extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game._advance_to_phase(5)
	assert(game.current_phase == 5)
	assert(game._current_map_texture() != null)
	assert(game.textures.get("boss5", []).size() >= 2)
	assert(game.textures.get("boss5_shield", []).size() >= 2)
	assert(game.textures.get("boss5_damage", []).size() >= 5)
	assert(game.boss_name == "UMBRA")
	assert(game._enemy_limit() == 5)
	assert(game.enemies.size() == 2)

	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 22000.0
	game.boss_hp = game.boss_hp_max
	game.boss_pos = Vector2(1050, 430)
	game.player_pos = Vector2(620, 450)
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_defense = 0.0
	game._load_umbra_mobile_memory()
	assert(game.boss5_mobile_weights.has("ATAQUE"))
	assert(game._umbra_available_actions().has("ATAQUE"))
	var decision := String(game._umbra_choose_action())
	assert(decision != "")

	game.enemy_bullets.clear()
	game._spawn_umbra_action("ATAQUE")
	assert(game.enemy_bullets.size() == 1)
	assert(String(game.enemy_bullets[0].get("type", "")) == "umbra_plasma")

	game.phase5_telegraphs.clear()
	game._spawn_umbra_action("TELEPORTE")
	assert(game.phase5_telegraphs.size() == 1)
	var target := Vector2(game.phase5_telegraphs[0]["to"])
	game._update_phase5_telegraphs(game.BOSS5_TELEPORT_DELAY + 0.05)
	assert(game.boss_pos.distance_to(target) < 1.0)

	game.phase5_hazards.clear()
	game._spawn_umbra_action("VORTICE")
	assert(game.phase5_hazards.any(func(h): return String(h.get("kind", "")) == "vortex"))
	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(110, 0)
	var before_hp: int = int(game.player_hp)
	game.phase5_hazards[0]["tick"] = 0.0
	game._update_phase5_hazards(0.02)
	assert(game.player_hp < before_hp)

	game.phase5_rats.clear()
	game._spawn_umbra_rats(3)
	assert(game.phase5_rats.size() == 3)
	var rat_pos := Vector2(game.phase5_rats[0]["pos"])
	game._update_phase5_rats(0.16)
	assert(Vector2(game.phase5_rats[0]["pos"]) != rat_pos)

	game.phase5_hazards.clear()
	game.phase5_rats.clear()
	game.boss5_transmute_cooldown = 0.0
	game.boss5_last_dimension = ""
	game._transmute_umbra_dimension("TRANSMUTAR_NECROSE")
	assert(game.boss5_dimension == "necrose")
	assert(game.boss5_dimension_timer > 29.0)
	var necrose_actions: Array = game._umbra_available_actions()
	assert(necrose_actions.has("MIASMA"))
	assert(not necrose_actions.has("VORTICE"))
	assert(not necrose_actions.has("PRISAO"))
	game.phase5_hazards.clear()
	game.phase5_rats.clear()
	game.boss5_dimension_timer = 0.0
	game._update_boss_phase5(0.02)
	assert(game.boss5_dimension == "base")

	game.boss_hp = 1.0
	game._damage_boss(999999.0, "eletrica")
	assert(game.mode == "victory")

	print("PHASE5_UMBRA_SMOKE_OK map=true assets=true memory=true decisions=true skills=true victory=true")
	quit(0)
