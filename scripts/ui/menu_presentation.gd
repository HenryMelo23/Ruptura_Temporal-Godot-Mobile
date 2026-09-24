class_name MenuPresentation
extends RefCounted

static func draw_menu_scrim(g: CanvasItem, viewport: Vector2, settings: bool) -> void:
	var left := Color(0.009, 0.02, 0.026, 0.98 if settings else 0.94)
	var right := Color(0.009, 0.02, 0.026, 0.94 if settings else 0.18)
	var points := PackedVector2Array([Vector2.ZERO, Vector2(viewport.x, 0), viewport, Vector2(0, viewport.y)])
	g.draw_polygon(points, PackedColorArray([left, right, right, left]))
	g.draw_rect(Rect2(0, viewport.y - 56.0, viewport.x, 56.0), Color(0.009, 0.02, 0.026, 0.66))

static func draw_settings_shell(g: CanvasItem, viewport: Vector2, title: String, detail: String, texture: Texture2D, page_age: float) -> void:
	g._draw_texture_cover(texture, Rect2(Vector2.ZERO, viewport))
	draw_menu_scrim(g, viewport, true)
	var x: float = viewport.x * 0.06
	var compact: bool = viewport.y < 600.0
	g._draw_ui_text("RUPTURA TEMPORAL  /  CONFIGURAÇÕES", Vector2(x, 23.0), 10, Color(0.4, 0.73, 0.74))
	var offset: float = (1.0 - clampf(page_age / 0.2, 0.0, 1.0)) * 6.0
	g._draw_ui_text(title, Vector2(x + offset, 52.0 if compact else 62.0), 27 if compact else 34, Color(0.95, 0.94, 0.89))
	g._draw_ui_text(detail, Vector2(x, 72.0 if compact else 84.0), 11 if compact else 12, Color(0.59, 0.7, 0.73), viewport.x * 0.85)
	g._draw_ui_text("Alterações salvas automaticamente", Vector2(x, viewport.y - 18.0), 11, Color(0.51, 0.65, 0.67))

static func draw_settings_surface(g: CanvasItem, rect: Rect2, selected: bool, accent: Color, selection_age: float) -> void:
	var fill := Color(0.028, 0.047, 0.055, 0.96)
	if selected:
		fill = fill.lerp(Color(0.09, 0.22, 0.23, 0.98), 0.65 * clampf(selection_age / 0.14, 0.0, 1.0))
	if selected and rect.has_point(g.get_global_mouse_position()) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		fill = fill.lightened(0.08)
	g.draw_rect(rect, fill)
	g.draw_rect(rect, Color(0.31, 0.49, 0.51, 0.6) if selected else Color(0.25, 0.35, 0.37, 0.35), false, 1.0)
	if selected:
		g.draw_rect(Rect2(rect.position, Vector2(3.0, rect.size.y)), accent)

static func draw_settings_card(g: CanvasItem, rect: Rect2, title: String, subtitle: String, selected: bool, selection_age: float) -> void:
	draw_settings_surface(g, rect, selected, Color(0.36, 0.88, 0.87), selection_age)
	var center := Vector2(rect.position.x + 23.0, rect.get_center().y)
	if title == "VOLTAR":
		g.draw_polyline(PackedVector2Array([center + Vector2(4, -5), center + Vector2(-2, 0), center + Vector2(4, 5)]), Color(0.53, 0.77, 0.77), 1.6, true)
	else:
		g.draw_rect(Rect2(center - Vector2(3, 3), Vector2(6, 6)), Color(0.36, 0.88, 0.87) if selected else Color(0.33, 0.47, 0.49), selected)
	var x: float = rect.position.x + 46.0
	g._draw_ui_text(g._menu_sentence_case(title), Vector2(x, rect.get_center().y - 2.0), 16, Color(0.93, 0.94, 0.9), rect.size.x - 75.0)
	g._draw_ui_text(subtitle, Vector2(x, rect.get_center().y + 15.0), 11, Color(0.59, 0.7, 0.73), rect.size.x - 75.0)

static func draw_menu_grid(g: CanvasItem, viewport: Vector2, color: Color, spacing: float) -> void:
	var x := 0.0
	while x <= viewport.x:
		g.draw_line(Vector2(x, 0), Vector2(x, viewport.y), color, 1)
		x += spacing
	var y := 0.0
	while y <= viewport.y:
		g.draw_line(Vector2(0, y), Vector2(viewport.x, y), color, 1)
		y += spacing

static func draw_pause_deck(g: CanvasItem, viewport: Vector2) -> void:
	g.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.66), true)
	var portrait = g._is_portrait(viewport)
	var panel = Rect2(viewport.x * 0.08 if not portrait else viewport.x * 0.05, viewport.y * 0.08, viewport.x * 0.84 if not portrait else viewport.x * 0.9, viewport.y * 0.8)
	g._draw_holo_panel(panel, Color(0.44, 0.84, 1.0), true, 0.84)
	var view_counts: Dictionary = g._deck_view_counts()
	var view_name: String = g._deck_view_name()
	g._draw_glitch_title("DECK DE %s" % view_name.to_upper(), Vector2(viewport.x * 0.5, panel.position.y + 44), 30 if not portrait else 26, Color(0.44, 0.84, 1.0))
	g._draw_centered("TOTAL DE CARTAS: %d" % g._deck_total_cards_from_counts(view_counts), Vector2(viewport.x * 0.5, panel.position.y + 84), 18, Color.WHITE)
	var owned: Array = g._owned_deck_cards_from_counts(view_counts)
	if owned.is_empty():
		g._draw_centered("Nenhuma carta comprada nesta run.", panel.get_center(), 18, Color(0.72, 0.88, 0.94))
	else:
		g._clamp_deck_selection(owned.size())
		var center = Vector2(viewport.x * 0.5, panel.position.y + (245.0 if not portrait else 260.0))
		var spacing = g._deck_carousel_spacing(viewport)
		var card_w = 154.0 if not portrait else min(160.0, viewport.x * 0.34)
		var card_h = 214.0 if not portrait else 224.0
		for i in range(owned.size()):
			var diff = g._carousel_diff(float(i), g.deck_scroll_pos, owned.size())
			if abs(diff) > 2.15:
				continue
			var selected = abs(diff) < 0.45
			var scale = clamp(1.0 - abs(diff) * 0.16, 0.66, 1.0)
			var rect = Rect2(center.x + diff * spacing - card_w * scale * 0.5, center.y - card_h * scale * 0.5 + abs(diff) * 18.0, card_w * scale, card_h * scale)
			var alpha = clamp(1.0 - abs(diff) * 0.26, 0.36, 1.0)
			g._draw_card_surface(owned[i]["card"], rect, selected, alpha, int(owned[i]["count"]))
		var selected_entry: Dictionary = owned[g.deck_selected]
		var detail = Rect2(panel.position.x + 26.0, panel.end.y - 190.0, panel.size.x - 52.0, 126.0)
		g._draw_card_detail_panel(selected_entry["card"], detail, int(selected_entry["count"]), true)
	var back_rect = Rect2(panel.get_center().x - 112.0, panel.end.y - 50.0, 224.0, 36.0)
	g.buttons["pause_deck_back"] = back_rect
	g._draw_small_rect_button(back_rect, "VOLTAR", Color(0.03, 0.1, 0.14, 0.9), Color(0.44, 0.84, 1.0))
	g.buttons.erase("pause_deck_prev_player")
	g.buttons.erase("pause_deck_next_player")
	if g.is_multiplayer and not g.net_decks_by_peer.is_empty():
		g.buttons["pause_deck_prev_player"] = Rect2(panel.position.x + 24.0, panel.position.y + 28.0, 42.0, 34.0)
		g.buttons["pause_deck_next_player"] = Rect2(panel.end.x - 66.0, panel.position.y + 28.0, 42.0, 34.0)
		g._draw_small_rect_button(g.buttons["pause_deck_prev_player"], "<", Color(0.03, 0.1, 0.14, 0.9), Color(0.44, 0.84, 1.0))
		g._draw_small_rect_button(g.buttons["pause_deck_next_player"], ">", Color(0.03, 0.1, 0.14, 0.9), Color(0.44, 0.84, 1.0))

static func graphics_settings_rects(g: CanvasItem, viewport: Vector2) -> Dictionary:
	var portrait: bool = g._is_portrait(viewport)
	var keys: Array = g._graphics_setting_keys()
	if not portrait:
		var outer_w: float = min(1120.0, viewport.x * 0.88)
		var x: float = viewport.x * 0.5 - outer_w * 0.5
		var y: float = maxf(100.0, viewport.y * 0.18)
		var gap: float = 12.0
		var col_gap: float = 18.0
		var col_w: float = (outer_w - col_gap) * 0.5
		var option_count: int = maxi(1, keys.size() - 1)
		var rows: int = int(ceil(float(option_count) / 2.0))
		var back_h: float = 54.0
		var row_h: float = clamp((viewport.y - y - back_h - 64.0 - gap * float(maxi(0, rows - 1))) / float(maxi(1, rows)), 64.0, 108.0)
		var wide_rects: Dictionary = {}
		var option_index: int = 0
		for key in keys:
			if key == "back":
				continue
			var col: int = option_index % 2
			var row: int = int(option_index / 2)
			wide_rects[String(key)] = Rect2(x + float(col) * (col_w + col_gap), y + float(row) * (row_h + gap), col_w, row_h)
			option_index += 1
		wide_rects["back"] = Rect2(x, y + float(rows) * (row_h + gap) + 8.0, outer_w, back_h)
		return wide_rects
	var w: float = min(760.0, viewport.x * (0.86 if portrait else 0.66))
	var x: float = viewport.x * 0.5 - w * 0.5
	var y: float = viewport.y * (0.14 if portrait else 0.15)
	var gap: float = 9.0
	var row_h: float = clamp((viewport.y - y - 42.0 - gap * float(keys.size() - 1)) / float(keys.size()), 42.0, 58.0)
	var rects: Dictionary = {}
	for i in range(keys.size()):
		rects[String(keys[i])] = Rect2(x, y + (row_h + gap) * float(i), w, row_h)
	return rects
