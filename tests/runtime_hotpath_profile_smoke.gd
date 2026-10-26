extends SceneTree

const ITERATIONS := 60

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.set_process(false)
	game.set_physics_process(false)
	game.spawn_timer = 9999.0
	game.player_hp_max = 1000000.0
	game.player_hp = game.player_hp_max
	game.enemies.clear()
	for index in range(96):
		var col := index % 16
		var row := index / 16
		game._spawn_enemy(game.ENEMY_COMMON, Vector2(280.0 + float(col) * 88.0, 180.0 + float(row) * 92.0))
		game.enemies[-1]["speed"] = 0.0
		game.enemies[-1]["damage"] = 0.0
	game.bullets.clear()
	for index in range(72):
		var angle := float(index) * TAU / 72.0
		game.bullets.append({
			"uid": "profile:%d" % index,
			"pos": game.player_pos + Vector2.from_angle(angle) * (90.0 + float(index % 5) * 12.0),
			"origin": game.player_pos,
			"dir": Vector2.ZERO,
			"speed": 0.0,
			"life": 30.0,
			"max_life": 30.0,
			"age": 0.0,
			"phase": angle,
			"trail_cd": 100.0,
			"damage": 0.0,
			"player_damage": 0.0,
			"kind": "eletrica",
			"source_category": "basic_attack",
			"pierce": true,
			"hits": {},
			"ricochets": 0,
			"durability": 0.0,
			"fly_sfx_cd": 100.0,
			"color": Color(0.22, 0.82, 1.0),
		})

	game.runtime_performance_controller.force_stage_for_test(0)
	var enemy_update_us := _measure(func(): game._update_enemies(1.0 / 60.0))
	var separation_full_us := _measure(func(): game._apply_entity_separation(1.0 / 60.0))
	var bullet_update_us := _measure(func(): game._update_bullets(1.0 / 60.0))
	game.runtime_performance_controller.force_stage_for_test(2)
	var separation_emergency_us := _measure(func(): game._apply_entity_separation(1.0 / 60.0))
	print("RUNTIME_HOTPATH_PROFILE_OK enemies=96 bullets=72 iterations=%d enemy_update_mean_us=%.1f bullet_update_mean_us=%.1f separation_full_mean_us=%.1f separation_emergency_mean_us=%.1f" % [
		ITERATIONS,
		enemy_update_us,
		bullet_update_us,
		separation_full_us,
		separation_emergency_us,
	])
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	quit(0)


func _measure(callable: Callable) -> float:
	var started := Time.get_ticks_usec()
	for _iteration in range(ITERATIONS):
		callable.call()
	return float(Time.get_ticks_usec() - started) / float(ITERATIONS)
