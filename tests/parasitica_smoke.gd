extends SceneTree

## Parasitica (kit 2026-11): marca de 8s, larvas ate 5, E sem hospedeiro nao gasta
## recarga, Verme-Rei com alvo comum + chefe + Arauto suportando larvas.

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.set_process(false)
	game.manifestation_key = "parasitica"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_damage = 100.0
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(700, 430))
	var enemy = game.enemies[0]
	enemy["hp"] = 1000.0
	enemy["max_hp"] = 1000.0

	# ATK implanta larva e renova a marca de 8s; maximo 5.
	game._apply_bullet_effect({"kind": "parasitica", "damage": 20.0, "pos": enemy["pos"]}, enemy)
	assert(int(enemy["seeds"]) == 1)
	assert(is_equal_approx(float(enemy["parasite_mark_time"]), 8.0))
	for i in range(8):
		game._apply_bullet_effect({"kind": "parasitica", "damage": 1.0, "pos": enemy["pos"]}, enemy)
	assert(int(enemy["seeds"]) == 5)
	game._update_enemy_dots(enemy, 7.9)
	assert(int(enemy["seeds"]) == 5)
	game._update_enemy_dots(enemy, 0.2)
	assert(int(enemy["seeds"]) == 0)
	assert(float(enemy["parasite_mark_time"]) == 0.0)

	# E sem larvas: nao cria rei e nao consome recarga.
	var cooldown_before = game.last_secondary_time
	game._use_secondary_skill()
	assert(game.last_secondary_time == cooldown_before)
	assert(not game._parasitica().king_active())

	# Chefe e Arauto suportam larvas e viram hospedeiros.
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp = 1000.0
	game.boss_hp_max = 1000.0
	game.boss_pos = Vector2(930, 410)
	game.boss_parasite_seeds = 3
	game.boss_parasite_mark_time = 8.0
	game.arauto = {"active": true, "hp": 1000.0, "max_hp": 1000.0, "pos": Vector2(1020, 460), "seeds": 2, "parasite_mark_time": 8.0, "aura_null": 0.0, "aura_wound": 0.0}
	var host: Dictionary = game._parasitica().best_host()
	assert(String(host["ref"]["kind"]) == "boss")
	game.last_secondary_time = -999.0
	game._use_secondary_skill()
	assert(game._parasitica().king_active())
	assert(game.boss_parasite_seeds == 0)
	assert(int(game._parasitica().king["consumed"]) == 3)

	print("PARASITICA_SMOKE_OK mark=8.0 max_larvae=5 e_without_host_free=true boss_host=true")
	root.remove_child(game)
	game.free()
	quit(0)
