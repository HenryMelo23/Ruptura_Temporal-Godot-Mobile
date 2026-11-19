extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _card(card_id: String) -> Dictionary:
	for card in game.CARDS:
		if game._card_id(card) == card_id:
			return card
	return {}


func _save_view(path: String, expected_size: Vector2i) -> void:
	var image := root.get_texture().get_image()
	assert(image != null)
	assert(image.get_width() == expected_size.x and image.get_height() == expected_size.y)
	assert(image.save_png(path) == OK)


func _run() -> void:
	game._finish_startup_thanks()
	game._start_game()
	game.run_tutorial_enabled = false
	game.score = 999999
	game.card_cost = 500
	game.cards_bought[game.CARD_PAIN_TRIBUTE_ID] = 8
	game.cards_bought[game.CARD_PRISM_SHARD_ID] = 6
	game.cards_bought[game.CARD_ABSOLUTE_CRIT_ID] = 3
	game.cards_bought[game.CARD_IMPOSSIBLE_ARCHIVE_ID] = 2
	game._open_shop(false)
	game.shop_cards = [
		_card(game.CARD_PAIN_TRIBUTE_ID),
		_card(game.CARD_PRISM_SHARD_ID),
		_card(game.CARD_ABSOLUTE_CRIT_ID),
	]
	game.shop_selected = 1
	game.shop_select_pulse_index = 1
	game.shop_select_pulse_timer = 0.18
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	await process_frame
	await process_frame
	_save_view("res://.codex/roguelike_point_cards_shop_1280x720.png", Vector2i(1280, 720))

	root.size = Vector2i(960, 540)
	game.shop_cards = [
		_card(game.CARD_IMPOSSIBLE_ARCHIVE_ID),
		_card(game.CARD_PAIN_TRIBUTE_ID),
		_card(game.CARD_PRISM_SHARD_ID),
	]
	game.shop_selected = 0
	game.shop_select_pulse_index = 0
	game.shop_select_pulse_timer = 0.18
	await process_frame
	await process_frame
	await process_frame
	_save_view("res://.codex/roguelike_point_cards_legendary_960x540.png", Vector2i(960, 540))

	print("ROGUELIKE_POINT_CARDS_VISUAL_OK " + ProjectSettings.globalize_path("res://.codex/roguelike_point_cards_shop_1280x720.png") + " " + ProjectSettings.globalize_path("res://.codex/roguelike_point_cards_legendary_960x540.png"))
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	for _i in range(4):
		await process_frame
	quit(0)
