extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("UMBRA_AUTOATTACK_PROJECTILE_FAIL " + message)
	quit(1)


func _approx(actual: float, expected: float, tolerance: float = 0.01) -> bool:
	return absf(actual - expected) <= tolerance


func _catch_time_running_away(distance: float, projectile_speed: float, runner_speed: float) -> float:
	var relative_speed: float = projectile_speed - runner_speed
	if relative_speed <= 0.0:
		return INF
	return distance / relative_speed


func _setup_umbra() -> void:
	game.is_multiplayer = false
	game.online_connected = false
	game.current_phase = 5
	game.mode = "game"
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 35100.0
	game.boss_hp = 30000.0
	game.boss_pos = Vector2(1050, 450)
	game.player_pos = Vector2(620, 450)
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_speed = game.PLAYER_BASE_SPEED
	game.phase5_player_history.clear()
	game.enemy_bullets.clear()
	game.boss5_cadence_bonus = 0.0


func _run() -> void:
	await process_frame
	game._start_game()
	_setup_umbra()

	var previous_speed: float = game.BOSS5_PROJECTILE_SPEED_PREVIOUS_REFERENCE
	var chosen_speed: float = game.BOSS5_PROJECTILE_SPEED
	_check(_approx(previous_speed, 372.0), "previous speed reference changed")
	_check(_approx(chosen_speed, previous_speed * 1.5), "chosen speed should be the x1.5 playtest step")
	_check(chosen_speed >= game.PLAYER_BASE_SPEED * 1.9 and chosen_speed <= game.PLAYER_BASE_SPEED * 2.1, "chosen speed is not near 2x player walk speed")

	var distance: float = 430.0
	var old_catch: float = _catch_time_running_away(distance, previous_speed, game.PLAYER_BASE_SPEED)
	var step_125: float = _catch_time_running_away(distance, previous_speed * 1.25, game.PLAYER_BASE_SPEED)
	var step_150: float = _catch_time_running_away(distance, previous_speed * 1.5, game.PLAYER_BASE_SPEED)
	var step_175: float = _catch_time_running_away(distance, previous_speed * 1.75, game.PLAYER_BASE_SPEED)
	_check(old_catch > 4.2, "old projectile unexpectedly catches a running player inside lifetime")
	_check(step_125 < 4.2, "x1.25 hypothesis would still not catch within lifetime")
	_check(step_150 < step_125 and step_175 < step_150, "playtest hypotheses are not ordered")
	_check(step_150 > 1.35 and step_150 < 1.75, "x1.5 step is not in the intended reaction window")

	game._fire_umbra_projectile()
	_check(game.enemy_bullets.size() == 1, "umbra attack did not spawn one projectile")
	var spawned: Dictionary = game.enemy_bullets[0]
	_check(String(spawned.get("type", "")) == "umbra_plasma", "wrong projectile type")
	_check(_approx(float(spawned.get("speed_mult", 0.0)) * 210.0, chosen_speed), "projectile speed_mult does not match configured speed")
	_check(_approx(float(spawned.get("life", 0.0)), 4.2), "projectile lifetime changed")
	_check(_approx(float(spawned.get("radius", 0.0)), 16.0), "projectile hitbox changed")

	_setup_umbra()
	game.enemy_bullets.append({
		"pos": game.player_pos + Vector2(-25.0, 0.0),
		"dir": Vector2.RIGHT,
		"life": 1.0,
		"damage": 30.0,
		"phase": 0.0,
		"type": "umbra_plasma",
		"speed_mult": game.BOSS5_PROJECTILE_SPEED / 210.0,
		"radius": 16.0
	})
	var hp_before_segment: int = game.player_hp
	game._update_enemy_bullets(0.08)
	_check(game.player_hp < hp_before_segment, "fast umbra projectile skipped local segment collision")
	_check(game.boss5_cadence_bonus > 0.0, "valid umbra projectile hit did not increase cadence")

	_setup_umbra()
	game.enemy_bullets.append({
		"pos": game.player_pos + Vector2(-25.0, 80.0),
		"dir": Vector2.RIGHT,
		"life": 1.0,
		"damage": 30.0,
		"phase": 0.0,
		"type": "umbra_plasma",
		"speed_mult": game.BOSS5_PROJECTILE_SPEED / 210.0,
		"radius": 16.0
	})
	var hp_before_miss: int = game.player_hp
	game._update_enemy_bullets(0.08)
	_check(game.player_hp == hp_before_miss, "missed umbra projectile damaged player")
	_check(_approx(game.boss5_cadence_bonus, 0.0), "missed umbra projectile increased cadence")

	print("UMBRA_AUTOATTACK_PROJECTILE_OK previous=%.0f chosen=%.0f player=%.0f catch_old=%.2f catch_x1_5=%.2f segment=true cadence=true" % [previous_speed, chosen_speed, game.PLAYER_BASE_SPEED, old_catch, step_150])
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _i in range(3):
		await process_frame
	quit(0)
