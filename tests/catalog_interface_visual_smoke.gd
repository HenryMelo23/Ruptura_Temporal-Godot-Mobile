extends SceneTree

## Smoke visual do catalogo (layout em grade com rolagem continua e leitor unico).
const UI = preload("res://scripts/catalog/catalog_interface.gd")
const OUTPUT := "res://.agent_logs/catalog_after"
var game: Node
var failed: bool = false


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
	_check(screenshot.save_png(OUTPUT + "/" + name + ".png") == OK, "capture save " + name)


func _layout(viewport: Vector2) -> void:
	var screen := Rect2(Vector2.ZERO, viewport)
	var gallery: Rect2 = UI.gallery_rect(game, viewport)
	for category in range(7):
		var rect: Rect2 = UI.category_rect(game, category, viewport)
		_check(screen.encloses(rect) and rect.size.y >= 40.0, "category touch bounds")
		_check(not rect.intersects(gallery), "category overlaps gallery")
	for f in UI.subfilter_rects(game, viewport):
		_check(not Rect2(f[1]).intersects(gallery), "subfilter overlaps gallery")
	var items: Array = game._catalog_items()
	var n: int = mini(items.size(), 12)
	for i in range(n):
		var a: Rect2 = game._catalog_item_rect(i, 0, viewport)
		_check(a.size.x >= 120.0 and a.size.y >= 110.0, "tile too small")
		for j in range(i + 1, n):
			_check(not a.intersects(game._catalog_item_rect(j, 0, viewport)), "entries overlap")
	var panel: Rect2 = game._catalog_detail_panel_rect(viewport)
	_check(screen.encloses(panel), "detail outside screen")
	_check(panel.encloses(UI.detail_text_rect(viewport)), "reader outside detail")
	_check(not UI.detail_art_rect(viewport).intersects(UI.detail_text_rect(viewport)), "reader overlaps art")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i.ZERO
	game.startup_thanks_done = true
	game.orientation_poll_timer = 9999.0
	game.vol_master = 0.0
	game.mode = "catalog"
	game.ui_platform_override_unlocked = true
	game.content_unread_ids = {"catalog_manifestation:eletrica": true, "catalog_spectrum:impulsiva": true}
	for viewport in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = viewport
		game.ui_platform_override = "desktop" if viewport.x == 1280 else "android"
		await create_timer(0.1).timeout
		for tab in range(7):
			game._catalog_reset_tab(tab)
			_layout(Vector2(viewport))
			await _capture("%dx%d_category_%d" % [viewport.x, viewport.y, tab])
			var items: Array = game._catalog_items()
			_check(not items.is_empty(), "empty category")
			game.catalog_detail_open = true
			await process_frame
			await process_frame
			_check(game.catalog_detail_text.visible, "reader hidden")
			_check(String(game.catalog_detail_text.text).length() > 40, "reader empty")
			if tab == 1:
				await _capture("%dx%d_reader" % [viewport.x, viewport.y])
			game.catalog_detail_open = false
		await process_frame
		_check(not game.catalog_detail_text.visible, "reader leaked into index")
	# Leitor: texto longo rola com toque.
	root.size = Vector2i(960, 540)
	var vp := Vector2(root.size)
	game._catalog_reset_tab(2)
	game.catalog_selected = 0
	game.catalog_detail_open = true
	await _capture("mobile_long_text")
	var scrollbar: VScrollBar = game.catalog_detail_text.get_v_scroll_bar()
	_check(scrollbar.max_value > scrollbar.page, "boss reader must be scrollable on mobile")
	game.ui_input_block_until_msec = 0
	var t := InputEventScreenTouch.new()
	t.index = 3
	t.position = UI.detail_text_rect(vp).get_center()
	t.pressed = true
	UI.handle_event(game, t, vp)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = t.position - Vector2(0, 140)
	drag.relative = Vector2(0, -140)
	UI.handle_event(game, drag, vp)
	t.pressed = false
	t.position = drag.position
	UI.handle_event(game, t, vp)
	_check(scrollbar.value > 0, "touch scroll failed")
	_check(game.catalog_detail_open, "reader drag must not close")
	# Swipe horizontal troca de registro.
	var before: int = game.catalog_selected
	t.pressed = true
	t.position = UI.detail_text_rect(vp).get_center()
	UI.handle_event(game, t, vp)
	t.pressed = false
	t.position -= Vector2(140, 0)
	UI.handle_event(game, t, vp)
	_check(game.catalog_selected == before + 1 and game.catalog_detail_open, "swipe must go to next record")
	game._handle_catalog_touch(game._catalog_detail_back_rect(vp).get_center(), vp)
	_check(not game.catalog_detail_open, "reader back failed")
	# Lista: arrastar rola sem abrir; toque abre.
	game._catalog_reset_tab(6)
	game.ui_input_block_until_msec = 0
	var start: Vector2 = game._catalog_item_rect(0, 0, vp).get_center()
	t.pressed = true
	t.position = start
	UI.handle_event(game, t, vp)
	_check(not game.catalog_detail_open, "touch must not open before release")
	drag.position = start - Vector2(0, 120)
	drag.relative = Vector2(0, -120)
	UI.handle_event(game, drag, vp)
	t.pressed = false
	t.position = drag.position
	UI.handle_event(game, t, vp)
	_check(float(game.catalog_scroll_px) > 0.0 and not game.catalog_detail_open, "drag should scroll without opening")
	game._catalog_reset_tab(6)
	t.pressed = true
	t.position = game._catalog_item_rect(1, 0, vp).get_center()
	UI.handle_event(game, t, vp)
	t.pressed = false
	UI.handle_event(game, t, vp)
	_check(game.catalog_detail_open and game.catalog_selected == 1, "tap must open record")
	game.catalog_detail_open = false
	# Teclado / controle.
	game._catalog_reset_tab(1)
	game._simulate_key_press(KEY_RIGHT)
	_check(game.catalog_selected == 1, "right arrow must reach adjacent entry")
	game._simulate_key_press(KEY_ENTER)
	_check(game.catalog_detail_open, "enter must open reader")
	game._simulate_key_press(KEY_RIGHT)
	_check(game.catalog_selected == 2 and game.catalog_detail_open, "right arrow in reader goes to next record")
	game._simulate_key_press(KEY_ESCAPE)
	_check(not game.catalog_detail_open, "escape must close reader")
	var shoulder := InputEventJoypadButton.new()
	shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER
	shoulder.pressed = true
	game.ui_input_block_until_msec = 0
	UI.handle_event(game, shoulder, vp)
	_check(game.catalog_tab == 2, "controller category navigation")
	# Carta lacrada nao vaza identidade, mas mostra fragmento do livro.
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
		await _capture("mobile_locked_card")
		_check(game._catalog_display_title(cards[locked]) == "???", "locked identity leaked")
		_check(not String(game.catalog_detail_text.text).contains(String(cards[locked].get("name", "@@"))), "locked name leaked in reader")
		game.catalog_detail_open = false
	# Ultrawide.
	root.size = Vector2i(1560, 720)
	game.ui_platform_override = "desktop"
	game._catalog_reset_tab(3)
	_layout(Vector2(root.size))
	await _capture("ultrawide_phases")
	# Badge de novidade: ler uma entrada so limpa ela.
	game._catalog_reset_tab(0)
	var manifestation_items: Array = game._catalog_items()
	for index in range(manifestation_items.size()):
		if String(manifestation_items[index].get("key", "")) == "eletrica":
			game.catalog_selected = index
			break
	game.catalog_detail_open = true
	game._catalog_mark_current_item_seen()
	_check(not game._content_is_unread("catalog_manifestation", "eletrica") and game._content_is_unread("catalog_spectrum", "impulsiva"), "reading one catalog entry cleared more than its stable ID")
	game.catalog_detail_open = false
	await process_frame
	game._go_to_menu()
	await process_frame
	_check(not game.catalog_detail_text.visible, "reader leaked into menu")
	if not failed:
		print("CATALOG_INTERFACE_VISUAL_OK categories=7 desktop=true mobile=true ultrawide=true reader=true drag_scroll=true swipe=true keyboard=true controller=true locks=true")
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
