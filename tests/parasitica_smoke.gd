extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.manifestation_key = "parasitica"
	game.player_damage = 100.0
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(700, 430))
	var enemy = game.enemies[0]
	enemy["hp"] = 1000.0
	enemy["max_hp"] = 1000.0

	game._apply_bullet_effect({"kind": "parasitica", "damage": 20.0, "pos": enemy["pos"]}, enemy)
	assert(int(enemy["seeds"]) == 1)
	assert(is_equal_approx(float(enemy["parasite_mark_time"]), 6.0))
	game._update_enemy_dots(enemy, 5.9)
	assert(int(enemy["seeds"]) == 1)
	game._update_enemy_dots(enemy, 0.2)
	assert(int(enemy["seeds"]) == 0)
	assert(float(enemy["parasite_mark_time"]) == 0.0)

	var cooldown_before = game.last_secondary_time
	game._use_secondary_skill()
	assert(game.last_secondary_time == cooldown_before)
	assert(game.manifestation_secondaries.is_empty())

	enemy["hp"] = 1000.0
	enemy["seeds"] = 2
	enemy["parasite_mark_time"] = 6.0
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp = 1000.0
	game.boss_hp_max = 1000.0
	game.boss_pos = Vector2(930, 410)
	game.boss_parasite_seeds = 2
	game.boss_parasite_mark_time = 6.0
	game._spawn_secondary_parasitica()
	assert(game.manifestation_secondaries.size() == 1)
	var secondary = game.manifestation_secondaries[0]
	assert(secondary["targets"].size() == 2)
	assert(float(enemy["parasite_mark_time"]) == 0.0)
	assert(game.boss_parasite_mark_time == 0.0)

	game._update_secondary_parasitica(secondary, 2.0)
	game._update_secondary_parasitica(secondary, 0.01)
	assert(is_equal_approx(float(enemy["parasite_slow_time"]), 0.20))
	for tick in range(8):
		game._update_secondary_parasitica(secondary, 1.0)
	var expected = 1000.0 * pow(0.95, 8)
	assert(abs(float(enemy["hp"]) - expected) < 0.05)
	assert(abs(game.boss_hp - expected) < 0.05)
	assert(secondary["targets"].all(func(target): return bool(target["done"])))

	enemy["hp"] = 1000.0
	enemy["seeds"] = 0
	enemy["parasite_mark_time"] = 0.0
	game.boss_active = false
	game.last_facing = Vector2.RIGHT
	enemy["pos"] = game.player_pos + Vector2.RIGHT * 285.0
	game.last_skill_time = -999.0
	game._use_skill()
	assert(game.parasite_spit_zones.size() == 1)
	game._update_parasite_spit_zones(0.5)
	game._update_parasite_spit_zones(0.01)
	assert(abs(float(enemy["hp"]) - 958.0) < 0.05)
	assert(int(enemy["seeds"]) == 1)
	assert(is_equal_approx(float(enemy["parasite_mark_time"]), 6.0))

	print("PARASITICA_SMOKE_OK mark=6.0 slow=20%% feast_hp=%.2f q_area_hp=%.2f" % [expected, float(enemy["hp"])])
	quit(0)
