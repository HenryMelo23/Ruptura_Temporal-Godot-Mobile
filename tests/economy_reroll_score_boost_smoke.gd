extends SceneTree


var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("ECONOMY_REROLL_SCORE_BOOST_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"
	game.score = 500
	game._open_shop(false)
	_check(game.shop_rerolls == game.SHOP_FREE_REROLLS_PER_VISIT, "shop did not grant three free rerolls")
	var score_before: int = game.score
	for _i in range(game.SHOP_FREE_REROLLS_PER_VISIT):
		game._reroll_shop()
		game.shop_controller.reset()
	_check(game.score == score_before, "free rerolls charged points")
	_check(game.shop_rerolls == 0, "free reroll counter mismatch")
	game._reroll_shop()
	game.shop_controller.reset()
	_check(game.score == score_before - game.SHOP_PAID_REROLL_BASE_COST, "first paid reroll cost mismatch")
	_check(game.shop_paid_rerolls == 1, "first paid reroll was not counted")
	game._reroll_shop()
	game.shop_controller.reset()
	_check(game.score == score_before - game.SHOP_PAID_REROLL_BASE_COST - (game.SHOP_PAID_REROLL_BASE_COST + game.SHOP_PAID_REROLL_INTEREST), "second paid reroll interest mismatch")
	_check(game._shop_reroll_label().contains("PTS"), "paid reroll label does not expose point cost")

	game.mode = "game"
	game.enemies.clear()
	game.score = 0
	game.run_points_earned = 0
	game.score_boost_timer = 0.0
	game.rng.seed = 404
	var pickup_pos: Vector2 = game.player_pos + Vector2(20, 0)
	game.score_boost_pickups = [{"pos": pickup_pos, "life": 5.0, "phase": 0.0}]
	game._update_score_boost_pickups(0.1)
	_check(game.score_boost_timer > 9.0, "score boost pickup did not activate")
	var enemy := {
		"uid": 7701,
		"type": game.ENEMY_COMMON,
		"pos": game.player_pos + Vector2(96, 0),
		"hp": 1.0,
		"max_hp": 10.0,
		"points": 20,
		"speed": 0.0,
		"damage": 1.0
	}
	game.enemies.append(enemy)
	game._kill_enemy(enemy)
	_check(game.score >= 70, "score boost did not roughly double boosted enemy points")
	_check(game.run_points_earned == game.score, "boosted reward did not register as earned points")

	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	for _i in range(4):
		await process_frame
	print("ECONOMY_REROLL_SCORE_BOOST_OK free=3 paid_interest=true boost=true")
	quit(0)
