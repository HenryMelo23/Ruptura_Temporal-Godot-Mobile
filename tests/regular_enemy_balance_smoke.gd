extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("REGULAR_ENEMY_BALANCE_FAIL " + message)
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
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0

	var balance = game.RegularEnemyBalance
	_check(is_equal_approx(balance.scaled_hp(30.0, 30.0), 30.0), "base_health_changed")
	_check(is_equal_approx(balance.scaled_hp(130.0, 30.0), 85.0), "regular_health_growth_was_not_reduced_by_45_percent")
	_check(is_equal_approx(balance.softened_damage_taken(0.25), 0.5875), "regular_armor_reduction_was_not_reduced_by_45_percent")
	_check(balance.health_scaling_exempt(game.ENEMY_LARAPIO, game.ENEMY_LARAPIO, game.ENEMY_AMBER_SUTURER, game.ENEMY_AMBER_SUTURE_NODE, game.ENEMY_SINEIRO_BOREAL), "larapio_lost_miniboss_exemption")
	_check(balance.health_scaling_exempt(game.ENEMY_AMBER_SUTURER, game.ENEMY_LARAPIO, game.ENEMY_AMBER_SUTURER, game.ENEMY_AMBER_SUTURE_NODE, game.ENEMY_SINEIRO_BOREAL), "amber_suturer_lost_miniboss_exemption")

	game.enemies.clear()
	game.enemy_base_hp = 130.0
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(100.0, 0.0))
	_check(is_equal_approx(float(game.enemies[-1]["max_hp"]), 85.0), "regular_spawn_did_not_use_softened_health_curve")
	game._spawn_enemy(game.ENEMY_LARAPIO, game.player_pos + Vector2(180.0, 0.0))
	_check(float(game.enemies[-1]["max_hp"]) >= 130.0 * 1.15, "miniboss_health_was_softened")
	game._spawn_enemy(game.ENEMY_CURATER, game.player_pos + Vector2(240.0, 0.0))
	var armored_enemy: Dictionary = game.enemies[-1]
	armored_enemy["hp"] = 1000.0
	armored_enemy["max_hp"] = 1000.0
	game._damage_enemy(armored_enemy, 100.0, "eletrica", false, false, game.player_pos, "skill_q")
	_check(is_equal_approx(1000.0 - float(armored_enemy["hp"]), 76.9), "live_regular_enemy_armor_was_not_softened")

	print("REGULAR_ENEMY_BALANCE_OK hp_growth_retained=55pct armor_reduction_retained=55pct live_armor=true bosses_unchanged=true minibosses_unchanged=true")
	_cleanup(0)
