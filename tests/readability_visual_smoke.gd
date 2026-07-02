extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _save_view(name: String) -> void:
	var image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	assert(image.save_png("res://.codex/" + name) == OK)


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	assert(is_equal_approx(game.interface_text_scale, 1.25))
	assert(game._readable_text_size(12) == 15)
	assert(game._gameplay_preferences_rects(Vector2(1280, 720)).has("interface_text"))

	game.mode = "settings_gameplay"
	await process_frame
	await process_frame
	_save_view("readability_settings_1280x720.png")

	game.mode = "manifest"
	game.selected_manifestation = 4
	game.manifest_scroll_pos = 4.0
	await process_frame
	await process_frame
	_save_view("readability_manifest_1280x720.png")

	game._start_game()
	game.score = 2400
	game._open_shop(false)
	game.shop_cards = [game.CARDS[2], game.CARDS[3], game.CARDS[9]]
	game.shop_selected = 1
	await process_frame
	await process_frame
	_save_view("readability_shop_1280x720.png")

	print("READABILITY_VISUAL_SMOKE_OK scale=125 settings=true manifest=true shop=true")
	quit(0)
