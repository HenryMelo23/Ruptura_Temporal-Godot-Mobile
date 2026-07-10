extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	var viewport = Vector2(1280, 720)
	game._start_game()
	game.score = 1800
	game.cards_bought["Disparo crescente"] = 2
	game.cards_bought["Tempestade"] = 1
	game.cards_bought["Defesa"] = 1
	game._open_shop(false)
	assert(game.mode == "shop")

	game._handle_shop_touch(game._shop_deck_center(viewport), viewport)
	assert(game.mode == "pause_deck")
	assert(game.deck_previous_mode == "shop")
	assert(game._owned_deck_cards().size() == 3)

	game._return_from_deck()
	assert(game.mode == "shop")
	game.shop_selected = 0
	game.shop_select_pulse_timer = 0.0
	game._touch_shop_card(1)
	assert(game.shop_selected == 1)
	var first_pulse = game.shop_select_pulse_timer
	game._touch_shop_card(1)
	assert(game.shop_selected == 1)
	assert(game.shop_select_pulse_timer > first_pulse)

	game._open_deck("paused")
	game.ui_input_block_until_msec = 0
	game._start_deck_drag(2, Vector2(760, 300), viewport)
	game._update_deck_drag(Vector2(520, 300), viewport)
	game._finish_deck_drag(Vector2(520, 300), viewport)
	assert(game.deck_selected >= 1)
	game._return_from_deck()
	assert(game.mode == "paused")

	game.previous_mode = "game"
	game._open_shop(false)
	assert(game.mode == "shop")
	game._finish_shop()
	assert(game.mode == "game")
	assert(game.shop_return_timer == 0.0)

	print("SHOP_DECK_UI_SMOKE_OK deck_from_shop=true drag=true return_modes=true no_black_return=true")
	quit(0)
