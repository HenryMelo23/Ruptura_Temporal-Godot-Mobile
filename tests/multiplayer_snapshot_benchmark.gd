extends SceneTree

const ENEMY_COUNT := 120
const BULLET_COUNT := 80
const ITERATIONS := 400


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.enemies.clear()
	game.enemy_bullets.clear()

	for index in range(ENEMY_COUNT):
		game.enemies.append({
			"uid": 10000 + index,
			"type": game.ENEMY_COMMON,
			"pos": Vector2(120.0 + index * 7.0, 240.0 + index * 3.0),
			"hp": 180.0,
			"max_hp": 180.0,
			"phase": float(index) * 0.1,
			"hit_cd": 0.0,
			"stun": 0.0,
			"shield_flash": 0.0,
			"bit": index % 2,
			"state": "hunting",
			"facing_dir": Vector2.RIGHT,
			"last_move_dir": Vector2.RIGHT,
			"invisible": false,
			"alpha": 1.0,
			"seeds": index % 5,
			"parasite_mark_time": 0.0,
			"tesla_shock": 0.0
		})

	for index in range(BULLET_COUNT):
		game.enemy_bullets.append({
			"pos": Vector2(300.0 + index * 4.0, 460.0),
			"dir": Vector2.RIGHT,
			"life": 4.0,
			"damage": 20,
			"type": "atirador",
			"radius": 24.0,
			"phase": float(index) * 0.2,
			"speed_mult": 1.0
		})

	for _warmup in range(20):
		game._pack_net_enemies()
		game._pack_net_enemy_bullets()

	var started_us := Time.get_ticks_usec()
	var enemy_payload := PackedFloat32Array()
	var bullet_payload := PackedFloat32Array()
	for _iteration in range(ITERATIONS):
		enemy_payload = game._pack_net_enemies()
		bullet_payload = game._pack_net_enemy_bullets()
	var elapsed_us := Time.get_ticks_usec() - started_us
	var payload_bytes := var_to_bytes([enemy_payload, bullet_payload]).size()
	var average_ms := float(elapsed_us) / 1000.0 / float(ITERATIONS)

	print("MULTIPLAYER_SNAPSHOT_BENCHMARK enemies=%d bullets=%d iterations=%d avg_ms=%.4f payload_bytes=%d" % [
		ENEMY_COUNT,
		BULLET_COUNT,
		ITERATIONS,
		average_ms,
		payload_bytes
	])
	root.remove_child(game)
	game.free()
	quit(0)
