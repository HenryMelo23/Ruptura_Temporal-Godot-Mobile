extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _save_view(path: String) -> void:
	var image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	assert(image.save_png(path) == OK)


func _run() -> void:
	game._start_game()
	game.score = 2400
	game.card_cost = 500
	game.cards_bought["Disparo crescente"] = 2
	game.cards_bought["Tempestade"] = 1
	game.cards_bought["Defesa"] = 1
	game.cards_bought["Petro"] = 1
	game._open_shop(false)
	game.shop_cards = [game.CARDS[2], game.CARDS[3], game.CARDS[9]]
	game.shop_selected = 1
	game.shop_select_pulse_index = 1
	game.shop_select_pulse_timer = 0.18
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	await process_frame
	await process_frame
	_save_view("res://.codex/shop_ui_qa_1280x720.png")

	game._open_deck("shop")
	game.ui_input_block_until_msec = 0
	game.deck_selected = 1
	game.deck_scroll_pos = 1.0
	await process_frame
	await process_frame
	_save_view("res://.codex/deck_ui_qa_1280x720.png")

	print("SHOP_DECK_VISUAL_OK " + ProjectSettings.globalize_path("res://.codex/shop_ui_qa_1280x720.png") + " " + ProjectSettings.globalize_path("res://.codex/deck_ui_qa_1280x720.png"))
	quit(0)
