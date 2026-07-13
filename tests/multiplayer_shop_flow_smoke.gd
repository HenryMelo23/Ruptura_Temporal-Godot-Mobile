extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.is_multiplayer = true
	game.shop_auto_enabled = false
	game.mode = "game"
	game.score = 1200
	game.card_cost = 120

	game._try_open_manual_shop()
	assert(game.mode == "game")
	assert(game.shop_mp_request_outgoing)
	assert(not game.shop_mp_request_incoming)
	assert(abs(game.shop_mp_request_timer - game.SHOP_MP_REQUEST_TIME) < 0.01)

	game._update_shop_mp_request(game.SHOP_MP_REQUEST_TIME + 0.5)
	assert(game.mode == "game")
	assert(not game.shop_mp_request_outgoing)
	assert(not game.shop_mp_request_incoming)

	game._start_shop_mp_request_overlay(true)
	assert(game._shop_mp_request_visible())
	game._accept_shop_mp_request()
	assert(game.mode == "shop_opening")
	assert(not game.shop_mp_request_incoming)

	game.mode = "game"
	game.previous_mode = "game"
	game.score = 1200
	game.card_cost = 120
	game._open_shop(false)
	assert(game.mode == "shop")
	assert(game.shop_cards.size() > 0)
	var selected_price: int = game._effective_card_price(game.shop_cards[game.shop_selected])
	game.score = selected_price
	game._buy_selected_card()
	assert(game._shop_purchase_animating())
	game._update_shop(game.SHOP_PURCHASE_ANIM_TIME + 0.05)
	assert(game.mode == "shop_mp_waiting")
	assert(game.shop_mp_ready_to_leave)
	assert(not game.shop_mp_partner_ready)

	game.shop_mp_partner_ready = true
	game._check_shop_mp_exit()
	assert(game.mode == "shop_return")
	assert(not game.shop_mp_ready_to_leave)
	assert(game.shop_return_timer > 0.0)
	game._update_shop_return(game.SHOP_RETURN_TIME + 0.05)
	assert(game.mode == "game")

	game._start_game()
	game.is_dead = true
	game._draw_player(Vector2.ZERO)

	print("MULTIPLAYER_SHOP_FLOW_SMOKE_OK request_overlay=true synced_exit=true dead_draw_guard=true")
	quit(0)
