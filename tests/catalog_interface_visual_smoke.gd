extends SceneTree

const UI = preload("res://scripts/catalog/catalog_interface.gd")
const OUTPUT := "res://.agent_logs/catalog_after"
var game: Node
var failed: bool = false
var longest: Dictionary = {"length": 0, "tab": 0, "index": 0, "section": 0}


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("CATALOG_INTERFACE_FAIL " + message)


func _capture(name: String) -> void:
	game.queue_redraw()
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	_check(screenshot.get_size() == root.size, "capture size " + name)
	_check(screenshot.save_png(OUTPUT + "/" + name + ".png") == OK, "capture save " + name)


func _layout(viewport: Vector2) -> void:
	var screen := Rect2(Vector2.ZERO, viewport)
	var gallery: Rect2 = UI.gallery_rect(game, viewport)
	var items: Array = game._catalog_items()
	var end: int = mini(items.size(), game.catalog_scroll_index + game._catalog_visible_count(viewport))
	for category in range(7):
		var rect: Rect2 = UI.category_rect(game, category, viewport)
		_check(screen.encloses(rect) and rect.size.y >= 44.0, "category touch bounds")
		_check(not rect.intersects(gallery), "category overlaps gallery")
	for i in range(game.catalog_scroll_index, end):
		var rect: Rect2 = game._catalog_item_rect(i, game.catalog_scroll_index, viewport)
		_check(gallery.grow(0.1).encloses(rect), "entry outside gallery")
		_check(not rect.intersects(UI.footer_rect(viewport, "back")), "entry overlaps footer")
		for j in range(i + 1, end):
			_check(not rect.intersects(game._catalog_item_rect(j, game.catalog_scroll_index, viewport)), "entries overlap")
	var panel: Rect2 = game._catalog_detail_panel_rect(viewport)
	_check(screen.encloses(panel), "detail outside screen")
	_check(panel.encloses(UI.detail_text_rect(viewport)), "reader outside detail")
	_check(not UI.detail_art_rect(viewport).intersects(UI.detail_text_rect(viewport)), "reader overlaps art")


func _expected(item: Dictionary, section: int) -> String:
	match section:
		0: return game._catalog_detail_description(item)
		1: return game._catalog_detail_lore(item)
		_: return game._catalog_detail_mechanics(item)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i.ZERO
	game.startup_thanks_done = true
	game.orientation_poll_timer = 9999.0
	game.vol_master = 0.0
	game.mode = "catalog"
	game.ui_platform_override_unlocked = true
	for viewport in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = viewport
		game.ui_platform_override = "desktop" if viewport.x == 1280 else "android"
		await create_timer(0.1).timeout
		for tab in range(7):
			game._catalog_reset_tab(tab)
			game._catalog_ensure_selected_visible(Vector2(viewport))
			_layout(Vector2(viewport))
			await _capture("%dx%d_category_%d" % [viewport.x, viewport.y, tab])
			var items: Array = game._catalog_items()
			_check(not items.is_empty(), "empty category")
			game.catalog_detail_open = true
			for section in range(3):
				game.catalog_detail_section = section
				await process_frame
				await process_frame
				_check(game.catalog_detail_text.text == _expected(items[0], section), "reader changed or truncated source text")
				_check(game.catalog_detail_text.visible, "reader hidden")
				if tab == 1:
					await _capture("%dx%d_reader_%d" % [viewport.x, viewport.y, section])
			for i in range(items.size()):
				for section in range(3):
					var length: int = _expected(items[i], section).length()
					if length > longest["length"]:
						longest = {"length": length, "tab": tab, "index": i, "section": section}
		game.catalog_detail_open = false
		await process_frame
		_check(not game.catalog_detail_text.visible, "reader leaked into index")
	# Exercise long, unlocked mechanics without changing the player's saved progress.
	for item in game.MANIFESTATIONS:
		game.unlocked_manifestation_ids[String(item["key"])] = true
	for item in game.AURAS:
		game.unlocked_spectrum_ids[String(item["key"])] = true
	for tab in range(7):
		game._catalog_reset_tab(tab)
		var entries: Array = game._catalog_items()
		for i in range(entries.size()):
			for section in range(3):
				var length: int = _expected(entries[i], section).length()
				if length > longest["length"]:
					longest = {"length": length, "tab": tab, "index": i, "section": section}
	root.size = Vector2i(960, 540)
	game._catalog_reset_tab(longest["tab"])
	game.catalog_selected = longest["index"]
	game.catalog_detail_section = longest["section"]
	game.catalog_detail_open = true
	await _capture("mobile_long_text")
	var scrollbar: VScrollBar = game.catalog_detail_text.get_v_scroll_bar()
	_check(scrollbar.max_value > scrollbar.page, "longest source must be scrollable")
	var drag := InputEventScreenDrag.new()
	drag.position = UI.detail_text_rect(Vector2(root.size)).get_center()
	drag.relative = Vector2(0, -140)
	UI.handle_event(game, drag, Vector2(root.size))
	_check(scrollbar.value > 0, "touch scroll failed")
	await _capture("mobile_long_text_scrolled")
	game._handle_catalog_touch(game._catalog_detail_back_rect(Vector2(root.size)).get_center(), Vector2(root.size))
	_check(not game.catalog_detail_open, "reader back failed")
	game._catalog_reset_tab(1)
	game.ui_input_block_until_msec = 0
	var visible: int = game._catalog_visible_count(Vector2(root.size))
	game._catalog_page_relative(1, Vector2(root.size))
	_check(game.catalog_scroll_index == visible, "next page must advance a full page")
	game._catalog_page_relative(-1, Vector2(root.size))
	_check(game.catalog_scroll_index == 0, "previous page must return to start")
	var point: Vector2 = game._catalog_item_rect(0, 0, Vector2(root.size)).get_center()
	var touch := InputEventScreenTouch.new()
	touch.index = 4
	touch.position = point
	touch.pressed = true
	UI.handle_event(game, touch, Vector2(root.size))
	_check(not game.catalog_detail_open, "touch must not open before release")
	touch.position -= Vector2(80, 0)
	touch.pressed = false
	UI.handle_event(game, touch, Vector2(root.size))
	_check(game.catalog_scroll_index == visible and not game.catalog_detail_open, "swipe should page without opening")
	game._catalog_reset_tab(1)
	game._simulate_key_press(KEY_RIGHT)
	_check(game.catalog_selected == 1, "right arrow must reach adjacent entry")
	game._simulate_key_press(KEY_ENTER)
	_check(game.catalog_detail_open, "enter must open reader")
	game._simulate_key_press(KEY_RIGHT)
	_check(game.catalog_detail_section == 1, "reader section keyboard navigation")
	game._simulate_key_press(KEY_ESCAPE)
	_check(not game.catalog_detail_open, "escape must close reader")
	var shoulder := InputEventJoypadButton.new()
	shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER
	shoulder.pressed = true
	game.ui_input_block_until_msec = 0
	UI.handle_event(game, shoulder, Vector2(root.size))
	_check(game.catalog_tab == 2, "controller category navigation")
	game._catalog_reset_tab(6)
	var cards: Array = game._catalog_items()
	var locked: int = -1
	for i in range(cards.size()):
		if game._catalog_card_locked(cards[i]):
			locked = i
			break
	_check(locked >= 0, "locked card sample missing")
	if locked >= 0:
		game.catalog_selected = locked
		game.catalog_detail_open = true
		game.catalog_detail_section = 1
		await _capture("mobile_locked_card")
		_check(game._catalog_display_title(cards[locked]) == "???", "locked identity leaked")
		_check(game.catalog_detail_text.text == game._catalog_detail_lore(cards[locked]), "locked source changed")
	game._catalog_reset_tab(3)
	root.size = Vector2i(1560, 720)
	game.ui_platform_override = "desktop"
	_layout(Vector2(root.size))
	await _capture("ultrawide_phases")
	game._go_to_menu()
	await process_frame
	_check(not game.catalog_detail_text.visible, "reader leaked into menu")
	print("CATALOG_INTERFACE_VISUAL_OK categories=7 desktop=true mobile=true ultrawide=true full_text=true touch_scroll=true swipe=true keyboard=true controller=true locks=true")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	quit(1 if failed else 0)
