extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("ELETRICA_KINETIC_WAVE_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.manifestation_key = "eletrica"
	game.selected_manifestation = 0
	game.player_pos = Vector2(420, 450)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 100.0
	game.last_skill_time = -100.0
	game.enemies.clear()
	game.bullets.clear()
	game.eletrica_waves.clear()
	game.eletrica_chains.clear()
	game.shockwaves.clear()
	game.boss_active = false

	game._spawn_enemy(game.ENEMY_COMMON, Vector2(560, 450))
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(735, 450))
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(920, 450))
	for enemy in game.enemies:
		enemy["hp"] = 180.0
		enemy["max_hp"] = 180.0
	var hp_before: float = float(game.enemies[0]["hp"])

	var target: Vector2 = game._cast_eletrica_kinetic_wave(Vector2(900, 450))
	_check(target.x > game.player_pos.x, "wave target should point forward")
	_check(game.eletrica_waves.size() == 1, "wave should be spawned")
	_check(game.eletrica_recoil_velocity.x < 0.0, "wave should apply opposite recoil")

	for i in range(18):
		game._update_eletrica_waves(1.0 / 60.0)
		game._update_eletrica_chains(1.0 / 60.0)
		if game.eletrica_chains.size() > 0:
			break
	_check(game.eletrica_waves.is_empty(), "wave should be consumed on first enemy impact")
	_check(game.eletrica_chains.size() == 1, "chain should spawn on impact")
	var chain: Dictionary = game.eletrica_chains[0]
	_check(Array(chain.get("targets", [])).size() == 3, "chain should BFS through nearby enemies")
	_check(Array(chain.get("links", [])).size() >= 2, "chain should keep electric links")

	for i in range(72):
		game._update_eletrica_chains(1.0 / 60.0)
	_check(float(game.enemies[0]["hp"]) < hp_before, "chain tick should damage reached enemy")
	_check(float(game.enemies[0].get("stun", 0.0)) >= game.ELETRICA_WAVE_CHAIN_STUN, "chain should stun reached enemy")
	_check(is_equal_approx(game._skill_cooldown(), 10.0), "electric Q cooldown should mirror Game Base 10000ms")

	game.queue_free()
	await process_frame
	print("ELETRICA_KINETIC_WAVE_SMOKE_OK targets=%d links=%d cooldown=10.0" % [Array(chain.get("targets", [])).size(), Array(chain.get("links", [])).size()])
	quit(0)
