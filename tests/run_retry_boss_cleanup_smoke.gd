extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("RUN_RETRY_BOSS_CLEANUP_SMOKE_FAIL " + message)
	_cleanup(1)


func _cleanup(code := 0) -> void:
	if game != null:
		game.mode = "menu"
		game.enemies.clear()
		game.enemy_bullets.clear()
		game.boss_attacks.clear()
		game.visible = false
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)


func _run() -> void:
	game.is_multiplayer = false
	game.dedicated_server_mode = false
	game.selected_manifestation = 0
	game.selected_aura = 1
	game._start_game()
	game.current_phase = 1
	game.mode = "game"
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_pos = Vector2(900, 360)
	game.boss_hp_max = 100.0
	game.boss_hp = 1.0
	game.boss_attacks.append({"kind": "test_temporal_wave", "life": 9.0})
	game.boss_transition_waves.append({"life": 9.0})
	game.enemy_bullets.append({"type": "test_boss_bullet", "pos": Vector2(120, 120), "life": 9.0})
	game._damage_boss(999.0, "smoke", false, false)
	_check(game.boss_dead, "boss did not die")
	_check(not game.boss_active, "boss stayed active")
	_check(game.boss_attacks.is_empty(), "boss attacks were not cleaned")
	_check(game.boss_transition_waves.is_empty(), "transition waves were not cleaned")
	_check(game.enemy_bullets.is_empty(), "boss bullets were not cleaned")
	_check(game.spawn_timer <= 0.01, "spawn timer was not resumed")

	game._start_game()
	game.mode = "game"
	game.player_pos = Vector2(456, 321)
	game.player_hp_max = 450.0
	game.player_hp = 123.0
	game.score = 1234
	game.card_cost = 500
	game.time_alive = 487.0
	game.run_damage_to_enemies = 321.0
	game.run_damage_to_boss_by_phase[2] = 654.0
	game.run_boss_reached[2] = true
	game.run_behavior_shots_fired = 44
	var death_pos: Vector2 = game.player_pos
	game._capture_retry_run_snapshot()
	game.is_dead = true
	game.player_hp = 0.0
	game.mode = "game_over"
	_check(game._retry_available(), "retry should be available after snapshot")
	_check(game._use_run_retry(), "retry failed")
	_check(game.mode == "game", "retry did not return to game")
	_check(not game.is_dead, "retry left player dead")
	_check(game.player_pos.distance_to(death_pos) < 0.1, "retry did not restore death position")
	_check(is_equal_approx(float(game.player_hp), float(game.player_hp_max) * 0.70), "first retry hp ratio is wrong")
	_check(game.score == 0, "first retry did not remove carried points")
	_check(game.run_retry_invulnerability_timer > 4.8, "retry invulnerability was not applied")
	_check(game.time_alive >= 487.0, "retry reset run timer")
	_check(is_equal_approx(float(game.run_damage_to_enemies), 321.0), "retry reset enemy damage telemetry")
	_check(is_equal_approx(float(game.run_damage_to_boss_by_phase.get(2, 0.0)), 654.0), "retry reset boss damage telemetry")
	_check(bool(game.run_boss_reached.get(2, false)), "retry reset boss reached telemetry")
	_check(game.run_behavior_shots_fired == 44, "retry reset behavior telemetry")

	print("RUN_RETRY_BOSS_CLEANUP_SMOKE_OK boss_cleanup=true retry=true telemetry=true hp=%.1f score=%d" % [game.player_hp, game.score])
	_cleanup(0)
