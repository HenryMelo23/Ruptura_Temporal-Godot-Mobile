extends SceneTree

const OUTPUT := "res://.codex/catalog_card_lock_1280x720.png"

var game: Node
var failed: bool = false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("CATALOG_CARD_LOCK_VISUAL_FAIL " + message)
	failed = true


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	await process_frame
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	game.startup_thanks_done = true
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	game.mode = "catalog"
	game.catalog_tab = 6
	game.catalog_scroll_index = 0
	game.catalog_detail_open = true
	game.unlocked_card_ids.clear()
	game.card_unlock_progress.clear()
	game._ensure_card_unlock_defaults()

	var items: Array = game._catalog_items()
	var locked_index: int = -1
	var locked_item: Dictionary = {}
	for i in range(items.size()):
		var item: Dictionary = items[i]
		if game._catalog_card_locked(item):
			locked_index = i
			locked_item = item
			break
	_check(locked_index >= 0, "no locked card found in catalog")
	var leaked_name: = String(locked_item.get("name", ""))
	_check(game._catalog_card_locked(locked_item), "sample card should be locked after clean defaults")
	_check(game._catalog_display_title(locked_item) == "???", "locked card title leaked")
	_check(leaked_name == "" or game._catalog_detail_description(locked_item).find(leaked_name) < 0, "locked description leaked card name")
	_check(leaked_name == "" or game._catalog_detail_lore(locked_item).find(leaked_name) < 0, "locked lore leaked card name")
	_check(game._catalog_detail_mechanics(locked_item).find("OBJETIVO") >= 0, "locked mechanics did not show objective")

	game.catalog_selected = locked_index
	game._catalog_ensure_selected_visible(Vector2(root.size))
	for frame in range(10):
		game.queue_redraw()
		await process_frame

	if DisplayServer.get_name() != "headless":
		var viewport_texture: ViewportTexture = root.get_texture()
		var image: Image = viewport_texture.get_image()
		_check(image != null and image.get_width() == 1280 and image.get_height() == 720, "invalid capture")
		_check(image.save_png(OUTPUT) == OK, "could not save screenshot")
		image = null
		viewport_texture = null

	print("CATALOG_CARD_LOCK_VISUAL_SMOKE_OK " + ProjectSettings.globalize_path(OUTPUT))
	root.remove_child(game)
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(1 if failed else 0)
