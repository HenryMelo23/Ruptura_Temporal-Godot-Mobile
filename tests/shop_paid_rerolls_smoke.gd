extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("SHOP_PAID_REROLLS_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _settle_shop_animation() -> void:
	game.shop_presentation.update(1.0)


func _open_test_shop(score: int, cost: int, multiplayer: bool = false) -> void:
	game.mode = "game"
	game.previous_mode = "game"
	game.shop_last_manual_open_time = -999.0
	game.shop_recent_manual_open_count = 0
	game.shop_last_exit_had_purchase = false
	game.shop_telemetry_enabled = false
	game.is_multiplayer = multiplayer
	game.score = score
	game.card_cost = cost
	game._open_shop(false)
	_check(game.mode == "shop", "shop did not open")
	_check(game.shop_rerolls == game.SHOP_FREE_REROLLS_PER_VISIT, "free rerolls did not reset on visit")
	_check(game.shop_paid_rerolls_this_visit == 0, "paid rerolls did not reset on visit")
	_check(game.shop_cards.size() > 0, "shop did not generate cards")


func _consume_free_rerolls() -> void:
	var starting_score: int = game.score
	for i in range(game.SHOP_FREE_REROLLS_PER_VISIT):
		var before_index: int = game.shop_reroll_index
		game._reroll_shop()
		_check(game.shop_reroll_index == before_index + 1, "free reroll did not increment reroll index")
		_settle_shop_animation()
	_check(game.shop_rerolls == 0, "free rerolls did not stop at zero")
	_check(game.score == starting_score, "free rerolls changed score")
	_check(game.shop_paid_rerolls_this_visit == 0, "free rerolls changed paid counter")


func _run() -> void:
	await process_frame
	game._start_game()
	game.run_tutorial_enabled = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game._set_shop_rng_seed(90210)
	game.rng.seed = 90210

	game.card_cost = 120
	game.shop_paid_rerolls_this_visit = 0
	_check(game.shop_controller.next_paid_reroll_cost() == 24, "early paid reroll cost drifted")
	game.card_cost = 500
	game.shop_paid_rerolls_this_visit = 0
	_check(game.shop_controller.next_paid_reroll_cost() == 100, "mid paid reroll cost drifted")
	game.card_cost = 2500
	game.shop_paid_rerolls_this_visit = 0
	_check(game.shop_controller.next_paid_reroll_cost() == 500, "late paid reroll cost drifted")
	game.card_cost = 500
	game.shop_paid_rerolls_this_visit = 10
	_check(game.shop_controller.next_paid_reroll_cost() == 1500, "paid reroll cap drifted")

	_open_test_shop(1600, 500)
	_consume_free_rerolls()
	var spent_before: int = game.run_points_spent
	game._reroll_shop()
	_check(game.score == 1500, "first paid reroll did not charge 20 percent of card_cost")
	_check(game.run_points_spent == spent_before + 100, "first paid reroll did not count as spent points")
	_check(game.shop_paid_rerolls_this_visit == 1, "first paid reroll did not increment paid count")
	_settle_shop_animation()
	game._reroll_shop()
	_check(game.score == 1340, "second paid reroll did not apply growing 1.6x cost")
	_check(game.shop_paid_rerolls_this_visit == 2, "second paid reroll did not increment paid count")
	_settle_shop_animation()
	var blocked_score: int = game.score
	var blocked_index: int = game.shop_reroll_index
	var blocked_paid: int = game.shop_paid_rerolls_this_visit
	game.score = game.shop_controller.next_paid_reroll_cost() - 1
	game._reroll_shop()
	_check(game.shop_reroll_index == blocked_index, "insufficient score still rerolled")
	_check(game.shop_paid_rerolls_this_visit == blocked_paid, "insufficient score changed paid count")
	_check(game.score == game.shop_controller.next_paid_reroll_cost() - 1, "insufficient score was charged")
	game.score = blocked_score

	var payload: Dictionary = game._build_minimal_telemetry_payload("RerollSmoke")
	var rerolls: Array = Dictionary(payload.get("shop", {})).get("rerolls", [])
	_check(rerolls.size() >= 5, "reroll telemetry missing events")
	_check(bool(Dictionary(rerolls[0]).get("free", false)), "free reroll telemetry missing")
	_check(not bool(Dictionary(rerolls[game.SHOP_FREE_REROLLS_PER_VISIT]).get("free", true)), "paid reroll telemetry missing paid flag")
	_check(int(Dictionary(rerolls[game.SHOP_FREE_REROLLS_PER_VISIT]).get("cost", 0)) == 100, "paid reroll telemetry missing cost")

	var visit_before: int = game.shop_visit_index
	_open_test_shop(900, 500)
	_check(game.shop_visit_index == visit_before + 1, "new visit did not advance")
	_check(game.shop_rerolls == 3 and game.shop_paid_rerolls_this_visit == 0, "reroll counters did not reset per visit")

	_open_test_shop(900, 500, true)
	_consume_free_rerolls()
	game._reroll_shop()
	_check(game.is_multiplayer, "multiplayer flag changed during paid reroll")
	_check(not game.shop_mp_ready_to_leave, "paid reroll touched multiplayer ready state")
	_check(game.score == 800, "multiplayer paid reroll did not charge only local score")

	print("SHOP_PAID_REROLLS_SMOKE_OK free=3 paid_costs=100,160 cap=1500 multiplayer=true")
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	game = null
	await process_frame
	await process_frame
	quit(0)
