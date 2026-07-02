extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.manifestation_key = "gravitante"
	game.player_damage = 100.0
	game.enemies.clear()
	game.bullets.clear()
	var center = Vector2(800, 450)
	game._spawn_enemy(game.ENEMY_COMMON, center + Vector2(80, 0))
	game._spawn_enemy(game.ENEMY_COMMON, center + Vector2(280, 0))
	for enemy in game.enemies:
		enemy["hp"] = 5000.0
		enemy["max_hp"] = 5000.0
		enemy["speed"] = 0.0

	var secondary = {
		"kind": "gravitante",
		"life": game.SECONDARY_GRAVITANTE_DURATION * 0.5,
		"max": game.SECONDARY_GRAVITANTE_DURATION,
		"center": center,
		"pulse_tick": 0.0,
		"captured": 0,
		"orbital_bonus": 0,
		"finalized": false
	}
	game._update_secondary_gravitante(secondary, 0.10)
	var inner_hp = float(game.enemies[0]["hp"])
	var edge_hp = float(game.enemies[1]["hp"])
	_check(int(secondary["captured"]) == 2, "expected two captured enemies")
	_check(float(secondary["spin_speed"]) > 300.0, "spin speed did not scale up")
	_check(edge_hp < inner_hp, "edge enemy should receive more gravitante damage")

	game._spawn_enemy(game.ENEMY_COMMON, center + Vector2(160, 0))
	game.enemies[2]["hp"] = 5000.0
	game.enemies[2]["max_hp"] = 5000.0
	var spin_before = float(secondary["spin_speed"])
	secondary["pulse_tick"] = 1.0
	game._update_secondary_gravitante(secondary, 0.05)
	_check(int(secondary["captured"]) == 3, "expected three captured enemies after adding one")
	_check(float(secondary["spin_speed"]) > spin_before, "spin speed should increase with captured enemies")

	game.orbitals.clear()
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, center + Vector2(120, 0))
	game._spawn_enemy(game.ENEMY_COMMON, center + Vector2(480, 0))
	var near_enemy = game.enemies[0]
	var far_enemy = game.enemies[1]
	near_enemy["hp"] = 1000.0
	far_enemy["hp"] = 1000.0
	game.orbitals.append({
		"target_kind": "enemy",
		"enemy_uid": -999,
		"origin_pos": center,
		"angle": 0.0,
		"life": 4.0,
		"tick": 0.0,
		"damage": 20.0
	})
	game._update_orbitals(0.1)
	_check(int(game.orbitals[0]["enemy_uid"]) == int(near_enemy["uid"]), "orbital should transfer only to nearby enemy")
	game.enemies.erase(near_enemy)
	game._update_orbitals(0.1)
	_check(float(game.orbitals[0]["life"]) <= 0.35, "orbital should expire instead of jumping to a distant enemy")

	game.orbitals.clear()
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 5000.0
	game.boss_hp = 5000.0
	game.boss_pos = center
	game.orbitals.append({
		"target_kind": "boss",
		"enemy_uid": -1,
		"origin_pos": center,
		"angle": 0.0,
		"life": 4.0,
		"tick": 0.0,
		"damage": 40.0
	})
	var boss_hp_before = game.boss_hp
	game._update_orbitals(0.1)
	_check(game.boss_hp < boss_hp_before, "gravitante orbital passive should damage the boss")

	print("GRAVITANTE_SMOKE_OK captured=%d spin=%.2f edge_damage_stronger=true transfer_radius=%.0f boss_passive=true" % [int(secondary["captured"]), float(secondary["spin_speed"]), game.GRAVITANTE_ORBITAL_TRANSFER_RADIUS])
	quit(0)
