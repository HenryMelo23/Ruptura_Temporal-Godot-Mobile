extends SceneTree

var game: Node
var dummy_texture: Texture2D


func _fail(message: String) -> void:
	push_error("CATALOG_TEMPORAL_FAIL " + message)
	if game != null:
		game.textures.clear()
		game.audio_streams.clear()
		game.free()
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _initialize() -> void:
	game = load("res://scripts/main.gd").new()
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 1.0, 0.82, 1.0))
	dummy_texture = ImageTexture.create_from_image(image)
	_seed_catalog_textures()
	call_deferred("_run")


func _seed_catalog_textures() -> void:
	for tab_index in range(game.CATALOG_TABS.size()):
		game._catalog_reset_tab(tab_index)
		for item in game._catalog_items():
			if item.has("key"):
				game.textures["manifestation_" + String(item["key"])] = dummy_texture
				game.textures["aura_" + String(item["key"])] = dummy_texture
			if item.has("texture"):
				game.textures[String(item["texture"])] = dummy_texture
			if item.has("icon"):
				game.textures["card_" + String(item["name"])] = dummy_texture
	game._catalog_reset_tab(0)


func _run() -> void:
	var viewport := Vector2(1280, 720)
	_check(game.CATALOG_TABS.size() == 6, "unexpected_tab_count")
	for tab_index in range(game.CATALOG_TABS.size()):
		game._catalog_reset_tab(tab_index)
		var items: Array = game._catalog_items()
		_check(not items.is_empty(), "empty_tab_%d" % tab_index)
		_check(game.catalog_selected == 0, "selected_not_reset_%d" % tab_index)
		_check(game.catalog_scroll_index == 0, "scroll_not_reset_%d" % tab_index)
		for item in items:
			_check(String(item.get("name", "")) != "", "item_without_name_%d" % tab_index)
			_check(String(game._catalog_short_text(item)) != "", "item_without_summary_%s" % String(item.get("name", "")))
			_check(String(game._catalog_detail_description(item)) != "", "item_without_description_%s" % String(item.get("name", "")))
			_check(String(game._catalog_detail_lore(item)) != "", "item_without_lore_%s" % String(item.get("name", "")))
			_check(String(game._catalog_detail_mechanics(item)) != "", "item_without_mechanics_%s" % String(item.get("name", "")))
			_check(game._catalog_item_texture(item) != null, "item_without_texture_%s" % String(item.get("name", "")))
		if items.size() > game._catalog_visible_count(viewport):
			game.catalog_selected = items.size() - 1
			game._catalog_ensure_selected_visible(viewport)
			_check(game.catalog_scroll_index > 0, "scroll_did_not_advance_%d" % tab_index)
			game._catalog_page_relative(-1, viewport)
			_check(game.catalog_selected < items.size() - 1, "page_back_did_not_move_%d" % tab_index)
	game._catalog_reset_tab(1)
	game.catalog_selected = 3
	game.catalog_detail_open = true
	game.catalog_detail_open = false
	print("CATALOG_TEMPORAL_SMOKE_OK tabs=%d enemies=%d cards=%d" % [game.CATALOG_TABS.size(), game._catalog_enemy_items().size(), game.CARDS.size()])
	game.textures.clear()
	game.audio_streams.clear()
	game.free()
	game = null
	for _i in range(4):
		await process_frame
	quit(0)
