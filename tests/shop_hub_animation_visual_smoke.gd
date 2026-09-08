extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _save_view(path: String) -> void:
	var texture: Texture2D = root.get_texture()
	if texture == null:
		printerr("SHOP_HUB_ANIMATION_VISUAL_FAIL render target unavailable")
		quit(1)
		return
	var image: Image = texture.get_image()
	if image == null or image.get_width() != root.size.x or image.get_height() != root.size.y:
		printerr("SHOP_HUB_ANIMATION_VISUAL_FAIL invalid screenshot size")
		quit(1)
		return
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	if image.save_png(path) != OK:
		printerr("SHOP_HUB_ANIMATION_VISUAL_FAIL could not save screenshot")
		quit(1)


func _run() -> void:
	game._start_game()
	game.score = 3000
	game.card_cost = 500
	game._open_shop(false)
	game.shop_cards = [game.CARDS[2].duplicate(true), game.CARDS[3].duplicate(true), game.CARDS[9].duplicate(true)]
	game.shop_selected = 0
	game._buy_selected_card()
	game._update_shop(0.30)
	await process_frame
	await process_frame
	_save_view(ProjectSettings.globalize_path("res://.codex/shop_purchase_transfer_1280x720.png"))

	game._update_shop(game.SHOP_PURCHASE_ANIM_TIME)
	game._finish_shop()
	game._update_shop_return(0.34)
	await process_frame
	await process_frame
	_save_view(ProjectSettings.globalize_path("res://.codex/shop_exit_1280x720.png"))

	game._update_shop_return(game.SHOP_RETURN_TIME)
	root.size = Vector2i(800, 450)
	game._open_shop(false)
	game.shop_cards = [game.CARDS[2].duplicate(true), game.CARDS[3].duplicate(true), game.CARDS[9].duplicate(true)]
	game.shop_selected = 0
	game._buy_selected_card()
	game._update_shop(0.30)
	await process_frame
	await process_frame
	_save_view(ProjectSettings.globalize_path("res://.codex/shop_purchase_transfer_mobile_800x450.png"))
	print("SHOP_HUB_ANIMATION_VISUAL_OK " + ProjectSettings.globalize_path("res://.codex/shop_purchase_transfer_1280x720.png") + " " + ProjectSettings.globalize_path("res://.codex/shop_exit_1280x720.png") + " " + ProjectSettings.globalize_path("res://.codex/shop_purchase_transfer_mobile_800x450.png"))
	quit(0)
