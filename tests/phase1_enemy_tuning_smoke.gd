extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("PHASE1_ENEMY_TUNING_FAIL " + message)
	_cleanup(1)


func _cleanup(code: int) -> void:
	if game != null:
		game.mode = "menu"
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.set_physics_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.boss_active = false
	game.time_alive = 0.0

	_check(is_equal_approx(game.PROJECTOR_ATTACK_RANGE, 420.0), "projector_range_is_not_50_percent_larger")
	_check(is_equal_approx(game.STALKER_OPACITY_MULT, 0.75), "stalker_opacity_is_not_reduced_by_25_percent")
	_check(is_equal_approx(game.CRYSTAL_DAMAGE_TAKEN_MULT, 0.50), "crystal_armor_multiplier_is_wrong")

	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_CRYSTAL, game.player_pos + Vector2(120.0, 0.0))
	var crystal: Dictionary = game.enemies[-1]
	crystal["hp"] = 1000.0
	crystal["max_hp"] = 1000.0
	game._damage_enemy(crystal, 100.0, "eletrica", false, false, game.player_pos, "skill_q")
	var expected_crystal_damage: float = 100.0 * game.RegularEnemyBalance.softened_damage_taken(game.CRYSTAL_DAMAGE_TAKEN_MULT)
	_check(is_equal_approx(1000.0 - float(crystal["hp"]), expected_crystal_damage), "crystal_live_armor_did_not_increase")

	game.enemies.clear()
	game.enemy_bullets.clear()
	game._spawn_enemy(game.ENEMY_PROJECTOR, game.player_pos + Vector2(400.0, 0.0))
	var projector: Dictionary = game.enemies[-1]
	projector["shoot_cd"] = 0.0
	game._update_projector(projector, 0.1)
	_check(bool(projector.get("parado", false)), "projector_did_not_engage_inside_420_pixels")
	_check(game.enemy_bullets.size() == 1, "projector_did_not_fire_inside_420_pixels")
	projector["pos"] = game.player_pos + Vector2(421.0, 0.0)
	projector["shoot_cd"] = 0.0
	game.enemy_bullets.clear()
	game._update_projector(projector, 0.1)
	_check(not bool(projector.get("parado", true)), "projector_engaged_beyond_420_pixels")
	_check(game.enemy_bullets.is_empty(), "projector_fired_beyond_420_pixels")

	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_STALKER, game.player_pos + Vector2(100.0, 0.0))
	var stalker: Dictionary = game.enemies[-1]
	_check(is_equal_approx(float(stalker.get("alpha", 1.0)), 0.75), "stalker_spawn_opacity_is_wrong")
	stalker["phase"] = 0.0
	stalker["sprint_active"] = false
	stalker["sprint_timer"] = 0.0
	game._update_stalker(stalker, 0.0)
	_check(is_equal_approx(float(stalker["alpha"]), 0.75), "visible_stalker_opacity_is_wrong")
	stalker["pos"] = game.player_pos + Vector2(400.0, 0.0)
	game._update_stalker(stalker, 0.0)
	_check(is_equal_approx(float(stalker["alpha"]), 0.39), "hidden_stalker_opacity_is_not_reduced_proportionally")

	print("PHASE1_ENEMY_TUNING_OK crystal_damage_taken=%.3f projector_range=%.0f stalker_alpha=%.2f" % [expected_crystal_damage / 100.0, game.PROJECTOR_ATTACK_RANGE, game.STALKER_OPACITY_MULT])
	game.mode = "menu"
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	game = null
	for index in range(4):
		await process_frame
	quit(0)
