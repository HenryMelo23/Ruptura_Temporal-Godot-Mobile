extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("SHOP_HUB_ANIMATION_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()
	game.score = 3000
	game.card_cost = 500
	game._open_shop(false)
	game.shop_cards = [game.CARDS[2].duplicate(true), game.CARDS[3].duplicate(true), game.CARDS[9].duplicate(true)]
	game.shop_selected = 0
	var starting_score: int = game.score
	game._buy_selected_card()
	_check(game._shop_purchase_animating(), "purchase animation did not start")
	_check(is_equal_approx(game.shop_purchase_anim_timer, game.SHOP_PURCHASE_ANIM_TIME), "purchase animation duration drifted")
	game._update_shop(game.SHOP_PURCHASE_ANIM_TIME * 0.35)
	_check(game._shop_purchase_animating(), "purchase animation ended before the transfer completed")
	_check(game.score == starting_score, "score changed before purchase confirmation finished")
	game._update_shop(game.SHOP_PURCHASE_ANIM_TIME)
	_check(not game._shop_purchase_animating(), "purchase animation did not commit")
	_check(game.score < starting_score, "purchase did not deduct points after confirmation")
	game._finish_shop()
	_check(game.mode == "shop_return", "shop did not enter return state")
	_check(is_equal_approx(game.shop_return_timer, game.SHOP_RETURN_TIME), "network return window changed")
	_check(is_equal_approx(game.shop_return_visual_timer, game.SHOP_RETURN_VISUAL_TIME), "visual return animation was not initialized")
	game._update_shop_return(game.SHOP_RETURN_VISUAL_TIME + 0.01)
	_check(is_equal_approx(game.shop_return_visual_timer, 0.0), "visual return animation did not finish quickly")
	_check(game.mode == "shop_return", "visual return animation changed the logical return state")
	game._update_shop_return(game.SHOP_RETURN_TIME)
	_check(game.mode == "game", "logical return state did not finish")
	print("SHOP_HUB_ANIMATION_SMOKE_OK purchase_transfer=true hub_finish=true visual_exit=0.72s network_window=3s")
	quit(0)
