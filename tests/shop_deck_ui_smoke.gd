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
	assert(game.mode == "shop_return")
	assert(is_equal_approx(game.shop_return_timer, game.SHOP_RETURN_TIME))
	game._update_shop_return(game.SHOP_RETURN_TIME + 0.01)
	assert(game.mode == "game")

	print("SHOP_DECK_UI_SMOKE_OK deck_from_shop=true drag=true return_modes=true no_black_return=true")
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(4):
		await process_frame
	quit(0)
