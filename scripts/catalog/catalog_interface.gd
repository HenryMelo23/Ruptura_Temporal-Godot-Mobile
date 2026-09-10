extends RefCounted
## Presentation only. Content and unlock rules remain owned by Main/CatalogRepository.

const ACCENT := Color(0.36, 0.88, 0.87)
const TEXT := Color(0.94, 0.94, 0.89)
const MUTED := Color(0.59, 0.72, 0.74)
const CATEGORIES := ["Manifestações", "Inimigos", "Chefes", "Fases", "Frações", "Espectros", "Cartas"]
const SECTIONS := ["Identidade", "História", "Como funciona"]


static func compact(host: Node, viewport: Vector2) -> bool:
	return viewport.x < 1100.0 or viewport.y < 620.0 or not host._uses_desktop_ui()


static func gallery_rect(host: Node, viewport: Vector2) -> Rect2:
	if compact(host, viewport):
		return Rect2(28.0, 152.0, viewport.x - 56.0, viewport.y - 224.0)
	return Rect2(226.0, 126.0, viewport.x - 566.0, viewport.y - 204.0)


static func columns(host: Node, viewport: Vector2) -> int:
	var width: float = gallery_rect(host, viewport).size.x
	return maxi(1, mini(4, int(width / 220.0)))


static func rows(host: Node, viewport: Vector2) -> int:
	var maximum: int = 2 if host._catalog_tab_key() == "Cartas" else 3
	return maxi(1, mini(maximum, int(gallery_rect(host, viewport).size.y / 156.0)))


static func visible_count(host: Node, viewport: Vector2) -> int:
	return columns(host, viewport) * rows(host, viewport)


static func item_rect(host: Node, index: int, first_index: int, viewport: Vector2) -> Rect2:
	var area := gallery_rect(host, viewport)
	var cols := columns(host, viewport)
	var row_count := rows(host, viewport)
	var size := Vector2((area.size.x - float(cols - 1) * 12.0) / float(cols), (area.size.y - float(row_count - 1) * 12.0) / float(row_count))
	var local_index := index - first_index
	return Rect2(area.position + Vector2(float(local_index % cols) * (size.x + 12.0), floorf(float(local_index) / float(cols)) * (size.y + 12.0)), size)


static func category_rect(host: Node, index: int, viewport: Vector2) -> Rect2:
	if compact(host, viewport):
		var width: float = (viewport.x - 56.0 - 6.0 * 6.0) / 7.0
		return Rect2(28.0 + index * (width + 6.0), 90.0, width, 44.0)
	return Rect2(28.0, 126.0 + index * 58.0, 178.0, 50.0)


static func footer_rect(viewport: Vector2, key: String) -> Rect2:
	match key:
		"back": return Rect2(28.0, viewport.y - 60.0, 150.0, 44.0)
		"prev": return Rect2(viewport.x - 132.0, viewport.y - 60.0, 44.0, 44.0)
		"next": return Rect2(viewport.x - 76.0, viewport.y - 60.0, 44.0, 44.0)
	return Rect2()


static func preview_rect(viewport: Vector2) -> Rect2:
	return Rect2(viewport.x - 320.0, 126.0, 292.0, viewport.y - 204.0)


static func detail_panel_rect(viewport: Vector2) -> Rect2:
	return Rect2(28.0, 106.0, viewport.x - 56.0, viewport.y - 182.0)


static func detail_art_rect(viewport: Vector2) -> Rect2:
	var panel := detail_panel_rect(viewport)
	return Rect2(panel.position + Vector2(18, 18), Vector2(panel.size.x * 0.3, panel.size.y - 36.0))


static func detail_text_rect(viewport: Vector2) -> Rect2:
	var panel := detail_panel_rect(viewport)
	var art := detail_art_rect(viewport)
	return Rect2(art.end.x + 28.0, panel.position.y + 138.0, panel.end.x - art.end.x - 48.0, panel.size.y - 158.0)


static func section_rect(index: int, viewport: Vector2) -> Rect2:
	var text_area := detail_text_rect(viewport)
	var width: float = (text_area.size.x - 16.0) / 3.0
	return Rect2(text_area.position.x + index * (width + 8.0), detail_panel_rect(viewport).position.y + 78.0, width, 44.0)


static func back_detail_rect(viewport: Vector2) -> Rect2:
	return Rect2(28.0, viewport.y - 60.0, 194.0, 44.0)


static func surface(host: Node, rect: Rect2, selected: bool = false) -> void:
	host.draw_rect(rect, Color(0.03, 0.065, 0.073, 0.96) if selected else Color(0.016, 0.032, 0.041, 0.96))
	host.draw_rect(rect, Color(ACCENT, 0.68) if selected else Color(0.25, 0.4, 0.43, 0.35), false, 1.0)
	if selected:
		host.draw_rect(Rect2(rect.position, Vector2(3.0, rect.size.y)), ACCENT)


static func button(host: Node, rect: Rect2, label: String, active: bool = false, enabled: bool = true) -> void:
	var hovered: bool = enabled and rect.has_point(host.get_global_mouse_position())
	surface(host, rect, active or hovered)
	host._draw_centered_with_font(host.menu_ui_font, label, rect.get_center(), 13, TEXT if enabled else Color(0.35, 0.46, 0.48))


static func draw_locked(host: Node, rect: Rect2) -> void:
	var center := rect.get_center()
	var size: float = minf(32.0, rect.size.y * 0.3)
	host.draw_arc(center - Vector2(0, size * 0.25), size * 0.33, PI, TAU, 16, MUTED, 2.0, true)
	host.draw_rect(Rect2(center + Vector2(-size * 0.48, -size * 0.25), Vector2(size * 0.96, size * 0.7)), Color(0.12, 0.2, 0.23))
	host.draw_rect(Rect2(center + Vector2(-size * 0.48, -size * 0.25), Vector2(size * 0.96, size * 0.7)), MUTED, false, 1.0)
	host.draw_circle(center + Vector2(0, size * 0.07), 2.0, TEXT)


static func draw_art(host: Node, item: Dictionary, rect: Rect2) -> void:
	if host._catalog_item_locked(item):
		draw_locked(host, rect)
	else:
		host._draw_texture_contain(host._catalog_item_texture(item), rect, Color.WHITE)


static func draw(host: Node, viewport: Vector2) -> void:
	host._draw_texture_cover(host.textures["menu_panels"][0], Rect2(Vector2.ZERO, viewport))
	host._draw_menu_scrim(viewport, true)
	host._draw_ui_text("RUPTURA TEMPORAL  /  ARQUIVO", Vector2(28, 25), 10, ACCENT)
	host._draw_ui_text("Catálogo temporal", Vector2(28, 64), 32, TEXT)
	if host.catalog_detail_open:
		draw_detail(host, viewport)
		return
	if compact(host, viewport):
		host._draw_ui_text("Deslize para mudar de página", Vector2(viewport.x - 240.0, 60), 11, MUTED)
	for i in range(CATEGORIES.size()):
		var category := category_rect(host, i, viewport)
		button(host, category, CATEGORIES[i], i == host.catalog_tab)
	var items: Array = host._catalog_items()
	host._catalog_ensure_selected_visible(viewport)
	var end: int = mini(items.size(), host.catalog_scroll_index + visible_count(host, viewport))
	if not compact(host, viewport):
		host._draw_ui_text(CATEGORIES[host.catalog_tab], Vector2(226, 106), 14, MUTED)
		host._draw_ui_text("%d registros" % items.size(), Vector2(viewport.x - 320.0, 106), 12, MUTED)
	if host._catalog_tab_key() == "Fases":
		host._draw_catalog_phase_route(items, host.catalog_scroll_index, end, viewport)
	for i in range(host.catalog_scroll_index, end):
		var item: Dictionary = items[i]
		var rect := item_rect(host, i, host.catalog_scroll_index, viewport)
		var selected: bool = i == host.catalog_selected
		surface(host, rect, selected)
		var locked: bool = host._catalog_item_locked(item)
		var art := Rect2(rect.position + Vector2(12, 12), Vector2(rect.size.x - 24.0, rect.size.y - 72.0))
		var color: Color = MUTED if locked else item.get("color", ACCENT)
		host.draw_rect(art, Color(color, 0.055))
		draw_art(host, item, art.grow(-7.0))
		host._draw_ui_text(host._catalog_display_title(item), Vector2(rect.position.x + 14.0, rect.end.y - 34.0), 16, TEXT, rect.size.x - 28.0)
		host._draw_ui_text("Registro lacrado" if locked else "Abrir registro  →", Vector2(rect.position.x + 14.0, rect.end.y - 15.0), 11, MUTED, rect.size.x - 28.0)
	if items.is_empty():
		host._draw_ui_text("Nenhum registro nesta seleção.", gallery_rect(host, viewport).position + Vector2(20, 40), 18, MUTED)
	elif not compact(host, viewport):
		draw_preview(host, items[host.catalog_selected], viewport)
	button(host, footer_rect(viewport, "back"), "←  Voltar ao menu")
	button(host, footer_rect(viewport, "prev"), "←", false, host.catalog_scroll_index > 0)
	button(host, footer_rect(viewport, "next"), "→", false, end < items.size())
	var page_label := "%d–%d de %d" % [0 if items.is_empty() else host.catalog_scroll_index + 1, end, items.size()]
	host._draw_centered_with_font(host.menu_ui_font, page_label, Vector2(viewport.x * 0.5, viewport.y - 38), 12, MUTED)
	if not compact(host, viewport):
		host._draw_ui_text("A / D ou LB / RB  categorias     Setas  navegar     Enter  abrir", Vector2(226, 80), 10, MUTED)


static func draw_preview(host: Node, item: Dictionary, viewport: Vector2) -> void:
	var rect := preview_rect(viewport)
	surface(host, rect)
	host._draw_ui_text("REGISTRO SELECIONADO", rect.position + Vector2(20, 28), 10, ACCENT)
	var art := Rect2(rect.position + Vector2(20, 46), Vector2(rect.size.x - 40, rect.size.y * 0.42))
	draw_art(host, item, art)
	var y: float = art.end.y + 30.0
	host._draw_ui_text(host._catalog_display_title(item), Vector2(rect.position.x + 20.0, y), 23, TEXT, rect.size.x - 40.0)
	host._draw_ui_wrap(host._catalog_display_short_text(item), Rect2(rect.position.x + 20, y + 16.0, rect.size.x - 40.0, rect.end.y - y - 88.0), 13, MUTED, 5)
	button(host, Rect2(rect.position.x + 18, rect.end.y - 60, rect.size.x - 36, 44), "Abrir registro  →", true)


static func draw_detail(host: Node, viewport: Vector2) -> void:
	var items: Array = host._catalog_items()
	if items.is_empty():
		return
	var item: Dictionary = items[clampi(host.catalog_selected, 0, items.size() - 1)]
	var panel := detail_panel_rect(viewport)
	var art := detail_art_rect(viewport)
	var text_area := detail_text_rect(viewport)
	surface(host, panel)
	host.draw_rect(art, Color(0.007, 0.015, 0.022, 0.7))
	draw_art(host, item, art.grow(-16.0))
	var locked: bool = host._catalog_item_locked(item)
	host._draw_ui_text("REGISTRO LACRADO" if locked else host._catalog_detail_title(host._catalog_item_kind(item)), Vector2(text_area.position.x, panel.position.y + 26), 10, ACCENT)
	host._draw_ui_text(host._catalog_display_title(item), Vector2(text_area.position.x, panel.position.y + 60), 28, TEXT, text_area.size.x)
	for i in range(SECTIONS.size()):
		button(host, section_rect(i, viewport), SECTIONS[i], host.catalog_detail_section == i)
	button(host, back_detail_rect(viewport), "←  Voltar aos registros")
	host._draw_ui_text("Deslize ou role para ler", Vector2(text_area.position.x, viewport.y - 32), 11, MUTED)


static func sync(host: Node, delta: float) -> void:
	if host.mode != "catalog" or not host.catalog_detail_open:
		if is_instance_valid(host.catalog_detail_text):
			host.catalog_detail_text.hide()
		host.catalog_detail_signature = ""
		if host.mode != "catalog":
			host.catalog_touch_index = -1
		return
	var items: Array = host._catalog_items()
	if items.is_empty():
		if is_instance_valid(host.catalog_detail_text):
			host.catalog_detail_text.hide()
		return
	var item: Dictionary = items[clampi(host.catalog_selected, 0, items.size() - 1)]
	var viewport: Vector2 = host.get_viewport_rect().size
	if not is_instance_valid(host.catalog_detail_text):
		var new_reader := RichTextLabel.new()
		new_reader.name = "CatalogReader"
		new_reader.bbcode_enabled = false
		new_reader.selection_enabled = false
		new_reader.scroll_active = true
		new_reader.mouse_filter = Control.MOUSE_FILTER_IGNORE
		new_reader.add_theme_font_override("normal_font", host.menu_ui_font)
		new_reader.add_theme_color_override("default_color", TEXT)
		new_reader.add_theme_constant_override("line_separation", 7)
		host.add_child(new_reader)
		host.catalog_detail_text = new_reader
	var reader: RichTextLabel = host.catalog_detail_text
	var rect := detail_text_rect(viewport)
	reader.position = rect.position
	reader.size = rect.size
	reader.add_theme_font_size_override("normal_font_size", 16 if viewport.y >= 650.0 else 15)
	reader.show()
	var signature := "%d/%d/%d/%s" % [host.catalog_tab, host.catalog_selected, host.catalog_detail_section, host._catalog_item_locked(item)]
	if signature != host.catalog_detail_signature:
		host.catalog_detail_signature = signature
		match host.catalog_detail_section:
			0: reader.text = host._catalog_detail_description(item)
			1: reader.text = host._catalog_detail_lore(item)
			2: reader.text = host._catalog_detail_mechanics(item)
		reader.get_v_scroll_bar().value = 0.0
		reader.modulate.a = 0.0
	reader.modulate.a = move_toward(reader.modulate.a, 1.0, delta * 7.0)


static func handle_touch(host: Node, pos: Vector2, viewport: Vector2) -> void:
	if host.catalog_detail_open:
		for i in range(SECTIONS.size()):
			if section_rect(i, viewport).has_point(pos):
				host.catalog_detail_section = i
				return
		if back_detail_rect(viewport).has_point(pos) or not detail_panel_rect(viewport).has_point(pos):
			host.catalog_detail_open = false
		return
	for i in range(CATEGORIES.size()):
		if category_rect(host, i, viewport).has_point(pos):
			host._catalog_reset_tab(i)
			return
	if footer_rect(viewport, "back").has_point(pos):
		host._go_to_menu()
		return
	var items: Array = host._catalog_items()
	if footer_rect(viewport, "prev").has_point(pos):
		if host.catalog_scroll_index > 0:
			host._catalog_page_relative(-1, viewport)
		return
	if footer_rect(viewport, "next").has_point(pos):
		if host.catalog_scroll_index + visible_count(host, viewport) < items.size():
			host._catalog_page_relative(1, viewport)
		return
	for i in range(host.catalog_scroll_index, mini(items.size(), host.catalog_scroll_index + visible_count(host, viewport))):
		if item_rect(host, i, host.catalog_scroll_index, viewport).has_point(pos):
			host.catalog_selected = i
			host.catalog_detail_section = 0
			host.catalog_detail_open = true
			return
	if not items.is_empty() and not compact(host, viewport) and preview_rect(viewport).has_point(pos):
		host.catalog_detail_section = 0
		host.catalog_detail_open = true


static func handle_event(host: Node, event: InputEvent, viewport: Vector2) -> bool:
	if event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
		if event.pressed and not host._ui_input_blocked():
			host._catalog_change_tab(-1 if event.button_index == JOY_BUTTON_LEFT_SHOULDER else 1)
		return true
	if event is InputEventScreenTouch and not host.catalog_detail_open:
		if event.pressed and not event.canceled and gallery_rect(host, viewport).has_point(event.position):
			if host._ui_input_blocked():
				return true
			host.catalog_touch_index = event.index
			host.catalog_touch_start = event.position
			return true
		if event.index == host.catalog_touch_index:
			host.catalog_touch_index = -1
			if event.canceled:
				return true
			var drag: Vector2 = event.position - host.catalog_touch_start
			if absf(drag.x) >= 44.0 and absf(drag.x) > absf(drag.y):
				host._catalog_page_relative(1 if drag.x < 0.0 else -1, viewport)
			elif drag.length() < 20.0:
				handle_touch(host, event.position, viewport)
			return true
	if event is InputEventScreenDrag and event.index == host.catalog_touch_index:
		return true
	if event is InputEventMouseMotion and not host.catalog_detail_open:
		var items: Array = host._catalog_items()
		for i in range(host.catalog_scroll_index, mini(items.size(), host.catalog_scroll_index + visible_count(host, viewport))):
			if item_rect(host, i, host.catalog_scroll_index, viewport).has_point(event.position):
				host.catalog_selected = i
		return false
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var direction: int = 1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1
		if host.catalog_detail_open and is_instance_valid(host.catalog_detail_text):
			host.catalog_detail_text.get_v_scroll_bar().value += direction * 72.0
		else:
			host._catalog_page_relative(direction, viewport)
		return true
	if event is InputEventScreenDrag and host.catalog_detail_open and is_instance_valid(host.catalog_detail_text) and detail_text_rect(viewport).has_point(event.position):
		host.catalog_detail_text.get_v_scroll_bar().value -= event.relative.y
		return true
	return false
