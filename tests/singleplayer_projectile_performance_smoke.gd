extends SceneTree

const ENEMY_COUNT := 240
const BULLET_COUNT := 120
const SIMULATION_FRAMES := 180

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("SINGLEPLAYER_PROJECTILE_PERFORMANCE_FAIL " + message)
	_cleanup(1)


func _cleanup(code := 0) -> void:
	if game != null:
		game.mode = "menu"
		game.visible = false
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)


func _enemy(index: int) -> Dictionary:
	return {
		"uid": index + 1,
		"type": game.ENEMY_STALKER,
		"pos": Vector2(900.0 + float(index % 20) * 38.0, 680.0 + float(index / 20) * 34.0),
		"hp": 100.0,
		"max_hp": 100.0,
		"phase": 0.0
	}


func _bullet(index: int) -> Dictionary:
	return {
		"uid": "perf:%d" % index,
		"pos": Vector2(120.0 + float(index % 12), 120.0 + float(index / 12)),
		"origin": Vector2(120.0, 120.0),
		"dir": Vector2.ZERO,
		"speed": 0.0,
		"life": 20.0,
		"max_life": 20.0,
		"age": 0.0,
		"phase": 0.0,
		"trail_cd": 100.0,
		"damage": 10.0,
		"player_damage": 10.0,
		"kind": "eletrica",
		"source_category": "basic_attack",
		"pierce": false,
		"hits": {},
		"ricochets": 0,
		"durability": 0.0,
		"fly_sfx_cd": 100.0
	}


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.is_multiplayer = false
	game.online_connected = false
	game.dedicated_server_mode = false
	game.boss_active = false
	game.enemies.clear()
	game.bullets.clear()
	for index in ENEMY_COUNT:
		game.enemies.append(_enemy(index))
	for index in BULLET_COUNT:
		game.bullets.append(_bullet(index))

	# Warm caches and exclude one-time setup from the measurement.
	game._update_bullets(0.001)
	var started := Time.get_ticks_usec()
	for _frame in SIMULATION_FRAMES:
		game._update_bullets(0.001)
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var frame_ms := elapsed_ms / float(SIMULATION_FRAMES)
	_check(game.bullets.size() == BULLET_COUNT, "fixture projectiles were unexpectedly removed")
	_check(frame_ms < 8.0, "projectile collision exceeded the single-player frame budget: %.3fms" % frame_ms)

	game.enemies.clear()
	game.bullets.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(165.0, 128.0))
	var target: Dictionary = game.enemies[0]
	var hp_before := float(target["hp"])
	var collision_bullet := _bullet(999)
	collision_bullet["pos"] = Vector2(127.0, 128.0)
	collision_bullet["damage"] = 15.0
	game.bullets.append(collision_bullet)
	game._update_bullets(0.001)
	_check(float(target["hp"]) < hp_before, "nearby-cell projectile collision was lost")
	print("SINGLEPLAYER_PROJECTILE_PERFORMANCE_OK total_ms=%.2f frame_ms=%.3f enemies=%d bullets=%d frames=%d" % [elapsed_ms, frame_ms, game.enemies.size(), game.bullets.size(), SIMULATION_FRAMES])
	_cleanup(0)
