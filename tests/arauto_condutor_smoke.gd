extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _card_total() -> int:
	var total := 0
	for value in game.cards_bought.values():
		total += int(value)
	return total


func _run() -> void:
	game._start_game()
	game.current_phase = 1
	game.mode = "game"
	game.time_alive = game.ARAUTO_SPAWN_TIME
	game.player_pos = Vector2(760, 450)
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_damage = 40.0
	game.enemy_base_hp = 40.0
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(200, 220))
	game._try_spawn_arauto()
	assert(game._arauto_active())
	assert(game.arauto_spawned)
	var echo_count: int = int(game._count_arauto_echoes())
	assert(echo_count >= game.ARAUTO_ECHO_MIN and echo_count <= game.ARAUTO_ECHO_MAX)
	assert(game.enemies.size() == echo_count)
	assert(game.enemies.all(func(enemy): return bool(enemy.get("eco_vinculado", false)) and float(enemy.get("max_hp", 0.0)) >= game.enemy_base_hp * 1.55))

	game.arauto["entry_timer"] = 0.0
	var hp_before: float = float(game.arauto["hp"])
	game._damage_arauto(100.0, "eletrica", false)
	var reduced_damage: float = hp_before - float(game.arauto["hp"])
	assert(reduced_damage >= 19.0 and reduced_damage <= 21.0)

	game.enemies.clear()
	game.arauto["pos"] = Vector2(400, 420)
	game.arauto["facing"] = 1.0
	game.arauto["gaze_target"] = Vector2(760, 430)
	game.player_pos = Vector2(760, 430)
	game.player_hp = 1000
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(560, 422))
	var echo: Dictionary = game.enemies[0]
	echo["eco_vinculado"] = true
	echo["hp"] = 120.0
	echo["max_hp"] = 120.0
	game._resolve_arauto_gaze(false)
	assert(game.player_hp == 1000)
	assert(game.enemies.size() == 0)
	assert(game.arauto_rays.size() > 0)
	assert(bool(game.arauto_rays[game.arauto_rays.size() - 1].get("blocked", false)))

	game.arauto["hp"] = 1.0
	game._damage_arauto(99999.0, "eletrica", false)
	assert(not game._arauto_active())
	assert(game.arauto_card_drops.size() == game.ARAUTO_CARD_REWARD_COUNT)

	var cards_before := _card_total()
	game.player_pos = Vector2(game.arauto_card_drops[0]["pos"])
	game._update_arauto_card_drops(0.05)
	assert(_card_total() == cards_before + 1)

	print("ARAUTO_CONDUTOR_SMOKE_OK spawn=8min ecos=%d-%d reduction=80 gaze_block=true drops=4 collect=true" % [game.ARAUTO_ECHO_MIN, game.ARAUTO_ECHO_MAX])
	quit(0)
