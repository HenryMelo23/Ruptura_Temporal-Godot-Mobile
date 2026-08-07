extends RefCounted

const CatalogRepository = preload("res://scripts/catalog/catalog_repository.gd")
const CatalogValidator = preload("res://scripts/catalog/catalog_validator.gd")


static func draw_catalog(host: Node, viewport: Vector2) -> void :
	host._draw_holo_background(viewport, null, Color(0.0, 0.88, 1.0))
	host._draw_glitch_title("CATALOGO TEMPORAL", Vector2(viewport.x * 0.5, 54), 34, Color(0.0, 0.88, 1.0))
	var tab_w: float = viewport.x / host.CATALOG_TABS.size()
	for i in range(host.CATALOG_TABS.size()):
		var rect: = Rect2(i * tab_w + 3, 92, tab_w - 6, 48)
		var selected: bool = i == host.catalog_tab
		host._draw_holo_panel(rect, Color(0.0, 1.0, 0.82) if selected else Color(0.18, 0.38, 0.48), selected, 0.68)
		host._draw_centered(tab_label(i), rect.get_center() + Vector2(0, 6), 12 if host._is_portrait(viewport) else 16, Color.WHITE)
	if host.catalog_detail_open:
		draw_catalog_detail(host, viewport)
		return
	draw_catalog_search_and_filters(host, viewport)
	var visible_items: = items(host)
	ensure_selected_visible(host, viewport)
	var portrait: bool = host._is_portrait(viewport)
	var visible: int = visible_count(host, viewport)
	var end_index: int = mini(visible_items.size(), host.catalog_scroll_index + visible)
	for i in range(host.catalog_scroll_index, end_index):
		var item: Dictionary = visible_items[i]
		var rect: Rect2 = item_rect(host, i, host.catalog_scroll_index, viewport)
		var color: Color = item.get("color", Color(0.62, 0.92, 1.0))
		host._draw_holo_panel(rect, color, host.catalog_selected == i, 0.74)
		var icon_rect: = Rect2(rect.position + Vector2(16, 20), Vector2(72, 72))
		host._draw_texture_contain(item_texture(host, item), icon_rect, Color.WHITE)
		var title: = String(item["name"]).to_upper()
		var title_size: int = host._fit_text_size(title, rect.size.x - 126, 20, 14)
		host.draw_string(host.font, rect.position + Vector2(106, 36), title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color.WHITE)
		host._draw_wrapped(short_text(host, item), Rect2(rect.position + Vector2(106, 56), Vector2(rect.size.x - 126, 54)), 14, Color(0.78, 0.88, 0.92))
		host.draw_line(rect.position + Vector2(106, rect.size.y - 18), rect.position + Vector2(rect.size.x - 22, rect.size.y - 18), Color(color.r, color.g, color.b, 0.38), 1)
	var page_text: = "%d-%d / %d" % [mini(host.catalog_scroll_index + 1, maxi(1, visible_items.size())), end_index, visible_items.size()]
	host._draw_centered(page_text, Vector2(viewport.x * 0.5, viewport.y - 45), 13, Color(0.76, 0.92, 1.0, 0.82))
	var back_rect: Rect2 = Rect2(viewport.x * 0.08, viewport.y - 72, viewport.x * 0.84, 48) if portrait else Rect2(viewport.x * 0.06, viewport.y - 68, 160, 44)
	host._draw_big_button(back_rect, "VOLTAR", Color(0.11, 0.04, 0.06, 0.88), Color(1.0, 0.28, 0.34))
	if not portrait and visible_items.size() > visible:
		var prev_rect: = Rect2(viewport.x - 250, viewport.y - 68, 106, 44)
		var next_rect: = Rect2(viewport.x - 132, viewport.y - 68, 106, 44)
		host._draw_big_button(prev_rect, "<", Color(0.04, 0.08, 0.1, 0.88), Color(0.42, 0.92, 1.0), false)
		host._draw_big_button(next_rect, ">", Color(0.04, 0.08, 0.1, 0.88), Color(0.42, 0.92, 1.0), false)


static func draw_catalog_search_and_filters(host: Node, viewport: Vector2) -> void :
	var search_area: Rect2 = search_rect(host, viewport)
	host._draw_holo_panel(search_area, Color(0.0, 0.78, 1.0), false, 0.5)
	var query_text: String = host.catalog_search_query if host.catalog_search_query.strip_edges() != "" else "BUSCAR REGISTRO..."
	var query_color: = Color.WHITE if host.catalog_search_query.strip_edges() != "" else Color(0.6, 0.74, 0.82, 0.72)
	host.draw_string(host.font, search_area.position + Vector2(16, 22), query_text.left(42), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, query_color)
	if host.catalog_search_query.strip_edges() != "":
		var clear_rect: = Rect2(search_area.end.x - 34, search_area.position.y + 5, 24, 22)
		host.draw_rect(clear_rect, Color(0.2, 0.04, 0.08, 0.7), true)
		host.draw_rect(clear_rect, Color(1.0, 0.18, 0.36, 0.82), false, 1)
		host._draw_centered("X", clear_rect.get_center() + Vector2(0, 5), 12, Color.WHITE)
	for mode_key in filter_modes():
		var rect: Rect2 = filter_rects(host, viewport).get(mode_key, Rect2())
		var selected: bool = String(mode_key) == host.catalog_filter_mode
		var color: = Color(0.0, 1.0, 0.82) if selected else Color(0.16, 0.3, 0.38)
		host._draw_holo_panel(rect, color, selected, 0.52)
		host._draw_centered(filter_label(String(mode_key)), rect.get_center() + Vector2(0, 5), 11 if host._is_portrait(viewport) else 12, Color.WHITE)


static func search_rect(host: Node, viewport: Vector2) -> Rect2:
	if host._is_portrait(viewport):
		return Rect2(viewport.x * 0.08, 150, viewport.x * 0.84, 34)
	return Rect2(viewport.x * 0.06, 150, min(520.0, viewport.x * 0.42), 34)


static func filter_modes() -> Array:
	return CatalogRepository.FILTERS


static func filter_label(mode_key: String) -> String:
	match mode_key:
		"combat":
			return "COMBATE"
		"lore":
			return "LORE"
		"support":
			return "SUPORTE"
		_:
			return "TUDO"


static func filter_rects(host: Node, viewport: Vector2) -> Dictionary:
	var rects: = {}
	var modes: = filter_modes()
	var gap: = 8.0
	if host._is_portrait(viewport):
		var w: float = (viewport.x * 0.84 - gap * float(modes.size() - 1)) / float(modes.size())
		var x: float = viewport.x * 0.08
		for i in range(modes.size()):
			rects[String(modes[i])] = Rect2(x + float(i) * (w + gap), 192, w, 30)
	else:
		var w: = 104.0
		var x: float = viewport.x * 0.06 + min(520.0, viewport.x * 0.42) + 18.0
		for i in range(modes.size()):
			rects[String(modes[i])] = Rect2(x + float(i) * (w + gap), 152, w, 30)
	return rects


static func tab_label(index: int) -> String:
	return CatalogRepository.category_label(index)


static func visible_count(host: Node, viewport: Vector2) -> int:
	return 5 if host._is_portrait(viewport) else 6


static func columns(host: Node, viewport: Vector2) -> int:
	return 1 if host._is_portrait(viewport) else 2


static func item_rect(host: Node, index: int, first_index: int, viewport: Vector2) -> Rect2:
	var portrait: bool = host._is_portrait(viewport)
	var cols: int = columns(host, viewport)
	var card_w: float = viewport.x * 0.86 if portrait else min(390.0, viewport.x * 0.42)
	var card_h: = 126.0 if portrait else 118.0
	var start_x: float = viewport.x * 0.5 - card_w * 0.5 if portrait else viewport.x * 0.5 - card_w - 14
	var start_y: = 234.0 if portrait else 198.0
	var local_index: = index - first_index
	var row: = floori(float(local_index) / float(cols))
	var col: = local_index % cols
	return Rect2(start_x + col * (card_w + 28), start_y + row * (card_h + 16), card_w, card_h)


static func ensure_selected_visible(host: Node, viewport: Vector2) -> void :
	var visible_items: = items(host)
	if visible_items.is_empty():
		host.catalog_selected = 0
		host.catalog_scroll_index = 0
		return
	var visible: int = visible_count(host, viewport)
	host.catalog_selected = clampi(host.catalog_selected, 0, visible_items.size() - 1)
	var max_scroll: int = maxi(0, visible_items.size() - visible)
	if host.catalog_selected < host.catalog_scroll_index:
		host.catalog_scroll_index = host.catalog_selected
	elif host.catalog_selected >= host.catalog_scroll_index + visible:
		host.catalog_scroll_index = host.catalog_selected - visible + 1
	host.catalog_scroll_index = clampi(host.catalog_scroll_index, 0, max_scroll)


static func reset_tab(host: Node, index: int) -> void :
	host.catalog_tab = clampi(index, 0, host.CATALOG_TABS.size() - 1)
	host.catalog_selected = 0
	host.catalog_scroll_index = 0
	host.catalog_detail_open = false


static func change_tab(host: Node, direction: int) -> void :
	reset_tab(host, (host.catalog_tab + direction + host.CATALOG_TABS.size()) % host.CATALOG_TABS.size())


static func select_relative(host: Node, direction: int, viewport: Vector2) -> void :
	if host.catalog_detail_open:
		return
	var visible_items: = items(host)
	if visible_items.is_empty():
		return
	host.catalog_selected = posmod(host.catalog_selected + direction, visible_items.size())
	ensure_selected_visible(host, viewport)


static func page_relative(host: Node, direction: int, viewport: Vector2) -> void :
	if host.catalog_detail_open:
		return
	var visible_items: = items(host)
	if visible_items.is_empty():
		return
	var visible: int = visible_count(host, viewport)
	host.catalog_selected = clampi(host.catalog_selected + direction * visible, 0, visible_items.size() - 1)
	ensure_selected_visible(host, viewport)


static func short_text(host: Node, item: Dictionary) -> String:
	if String(item.get("summary", "")).strip_edges() != "":
		return String(item.get("summary", ""))
	var kind: String = item_kind(host, item)
	if kind == "card":
		return String(item.get("nick", item.get("desc", "")))
	if kind == "manifestation":
		return String(item.get("desc", "Registro de manifestacao."))
	if kind == "spectrum":
		return String(item.get("desc", "Registro espectral."))
	return String(item.get("summary", item.get("desc", "")))


static func detail_title(kind: String) -> String:
	match kind:
		"card":
			return "CARTA"
		"manifestation":
			return "MANIFESTACAO"
		"spectrum":
			return "ESPECTRO"
		"enemy":
			return "INIMIGO"
		"boss":
			return "CHEFE"
		"fraction":
			return "FRACAO"
	return "REGISTRO"


static func enemy_items() -> Array:
	return CatalogRepository.enemy_entries()


static func boss_items() -> Array:
	return CatalogRepository.boss_entries()


static func fraction_items() -> Array:
	return CatalogRepository.faction_entries()


static func draw_catalog_detail(host: Node, viewport: Vector2) -> void :
	host.catalog_related_buttons.clear()
	var visible_items: = items(host)
	if visible_items.is_empty():
		return
	var item: Dictionary = visible_items[clamp(host.catalog_selected, 0, visible_items.size() - 1)]
	var color: Color = item.get("color", Color(0.0, 1.0, 0.82))
	var portrait: bool = host._is_portrait(viewport)
	var kind: String = item_kind(host, item)
	var panel: Rect2 = Rect2(viewport.x * 0.07, 148, viewport.x * 0.86, viewport.y - 238) if portrait else Rect2(viewport.x * 0.06, 148, viewport.x * 0.88, viewport.y - 238)
	host._draw_holo_panel(panel, color, true, 0.78)

	var image_rect: Rect2
	var text_x: float
	var text_w: float
	var text_y: float
	if portrait:
		image_rect = Rect2(panel.position + Vector2(20, 20), Vector2(panel.size.x - 40, min(190.0, panel.size.y * 0.3)))
		text_x = panel.position.x + 20
		text_w = panel.size.x - 40
		text_y = image_rect.end.y + 26
	else:
		var left_w: float = panel.size.x * 0.35
		image_rect = Rect2(panel.position + Vector2(24, 24), Vector2(left_w, panel.size.y - 82))
		var div_x: float = panel.position.x + left_w + 48
		host.draw_line(Vector2(div_x, panel.position.y + 24), Vector2(div_x, panel.end.y - 24), Color(color.r, color.g, color.b, 0.28), 1)
		text_x = div_x + 24
		text_w = panel.end.x - text_x - 24
		text_y = panel.position.y + 26
	host.draw_rect(image_rect, Color(0.0, 0.0, 0.0, 0.32), true)
	host.draw_rect(image_rect, Color(color.r, color.g, color.b, 0.5), false, 2)
	host._draw_texture_contain(item_texture(host, item), image_rect.grow(-16), Color.WHITE)

	if not portrait:
		var image_title: = String(item["name"]).to_upper()
		host._draw_centered(image_title, Vector2(image_rect.get_center().x, image_rect.end.y + 32), host._fit_text_size(image_title, image_rect.size.x - 18.0, 23, 15), Color.WHITE)

	var title: = String(item["name"]).to_upper()
	var title_size: int = host._fit_text_size(title, text_w, 27 if not portrait else 23, 16)
	host.draw_string(host.font, Vector2(text_x, text_y), detail_title(kind), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
	var source_text: = String(item.get("source_type", "JOGO ATUAL"))
	host.draw_string(host.font, Vector2(text_x + text_w - min(190.0, text_w * 0.45), text_y), source_text, HORIZONTAL_ALIGNMENT_RIGHT, min(190.0, text_w * 0.45), 11, Color(0.7, 0.86, 0.92, 0.76))
	text_y += 28
	host.draw_string(host.font, Vector2(text_x, text_y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color.WHITE)
	text_y += title_size + 20
	var subtitle: = String(item.get("subtitle", item.get("classification", ""))).strip_edges()
	if subtitle != "":
		host._draw_wrapped(subtitle, Rect2(text_x, text_y - 10, text_w, 24), 12, Color(color.r, color.g, color.b, 0.86))
		text_y += 18

	var section_gap: = 12.0
	var desc_h: = 64.0 if portrait else 58.0
	host.draw_string(host.font, Vector2(text_x, text_y), "IDENTIDADE", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	text_y += 18
	host._draw_wrapped(detail_description(host, item), Rect2(text_x, text_y, text_w, desc_h), 13 if portrait else 14, Color(0.85, 0.92, 0.96))
	text_y += desc_h + section_gap

	host.draw_line(Vector2(text_x, text_y), Vector2(text_x + text_w, text_y), Color(color.r, color.g, color.b, 0.36), 1)
	text_y += 18
	host.draw_string(host.font, Vector2(text_x, text_y), "HISTORIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	text_y += 18
	host._draw_wrapped(detail_lore(host, item), Rect2(text_x, text_y, text_w, 66.0), 13, Color(0.7, 0.82, 0.88))
	text_y += 76.0

	host.draw_string(host.font, Vector2(text_x, text_y), "COMO FUNCIONA", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	text_y += 18
	var related_area_h: = 54.0 if not item.get("related_entry_ids", []).is_empty() else 0.0
	var note_h: = 36.0 if String(item.get("field_note", "")).strip_edges() != "" else 0.0
	host._draw_wrapped(detail_mechanics(host, item), Rect2(text_x, text_y, text_w, panel.end.y - text_y - 22.0 - related_area_h - note_h), 13, Color(0.82, 0.9, 0.94))
	if note_h > 0.0:
		var note_y: float = panel.end.y - related_area_h - note_h - 10.0
		host.draw_line(Vector2(text_x, note_y - 8.0), Vector2(text_x + text_w, note_y - 8.0), Color(color.r, color.g, color.b, 0.24), 1)
		host._draw_wrapped(String(item.get("field_note", "")), Rect2(text_x, note_y, text_w, note_h), 12, Color(1.0, 0.86, 0.52, 0.88))
	if related_area_h > 0.0:
		draw_related_entries(host, item, Rect2(text_x, panel.end.y - related_area_h - 8.0, text_w, related_area_h), color)

	var back_label: = "VOLTAR AO REGISTRO" if not host.catalog_history.is_empty() else "VOLTAR AO INDICE"
	host._draw_big_button(Rect2(viewport.x * 0.5 - 120, viewport.y - 72, 240, 48), back_label, Color(0.08, 0.04, 0.1, 0.9), Color(1.0, 0.2, 0.78))


static func draw_related_entries(host: Node, item: Dictionary, area: Rect2, color: Color) -> void :
	host.draw_string(host.font, area.position + Vector2(0, 12), "RELACIONADOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(color.r, color.g, color.b, 0.9))
	var related: Array = item.get("related_entry_ids", [])
	var x: = area.position.x
	var y: = area.position.y + 20.0
	var chip_h: = 28.0
	for related_id in related:
		var target: Dictionary = find_entry(host, String(related_id))
		if target.is_empty():
			continue
		var label: = String(target.get("name", related_id))
		var chip_w: float = clamp(host.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 28.0, 86.0, 180.0)
		if x + chip_w > area.end.x:
			break
		var rect: = Rect2(x, y, chip_w, chip_h)
		host.catalog_related_buttons[String(related_id)] = rect
		host.draw_rect(rect, Color(0.02, 0.06, 0.08, 0.84), true)
		host.draw_rect(rect, Color(color.r, color.g, color.b, 0.54), false, 1)
		host._draw_centered(label.to_upper(), rect.get_center() + Vector2(0, 5), host._fit_text_size(label.to_upper(), chip_w - 14.0, 11, 8), Color.WHITE)
		x += chip_w + 8.0


static func item_texture(host: Node, item: Dictionary) -> Texture2D:
	if item.has("key") and host.textures.has("aura_" + String(item["key"])):
		return host.textures["aura_" + String(item["key"])]
	if item.has("key") and host.textures.has("manifestation_" + String(item["key"])):
		return host.textures["manifestation_" + String(item["key"])]
	var texture_key: = String(item.get("texture", ""))
	if texture_key != "" and host.textures.has(texture_key):
		var value = host.textures[texture_key]
		if value is Array:
			for frame in value:
				if frame is Texture2D:
					return frame
			return null
		if value is Texture2D:
			return value
	if item.has("icon"):
		var card_texture = host.textures.get("card_" + String(item["name"]), null)
		if card_texture is Texture2D:
			return card_texture
		if card_texture == null:
			card_texture = host._safe_load_sprite_icon(String(item["icon"]), "res://assets/sprites/")
			if card_texture is Texture2D:
				return card_texture
	return null


static func items(host: Node) -> Array:
	var base_items: = CatalogRepository.entries_for_tab(host.catalog_tab, host.MANIFESTATIONS, host.AURAS, host.CARDS)
	return CatalogRepository.filter_entries(base_items, host.catalog_search_query, host.catalog_filter_mode)


static func all_items_by_tab(host: Node) -> Array:
	var all_tabs: Array = []
	for tab_index in range(host.CATALOG_TABS.size()):
		all_tabs.append(CatalogRepository.entries_for_tab(tab_index, host.MANIFESTATIONS, host.AURAS, host.CARDS))
	return all_tabs


static func find_entry(host: Node, entry_id: String) -> Dictionary:
	for tab_entries in all_items_by_tab(host):
		for raw_item in tab_entries:
			var item: = Dictionary(raw_item)
			var id: = String(item.get("id", item.get("key", item.get("name", ""))))
			if id == entry_id:
				return item
	return {}


static func find_entry_location(host: Node, entry_id: String) -> Dictionary:
	for tab_index in range(host.CATALOG_TABS.size()):
		var tab_items: Array = CatalogRepository.entries_for_tab(tab_index, host.MANIFESTATIONS, host.AURAS, host.CARDS)
		for i in range(tab_items.size()):
			var item: = Dictionary(tab_items[i])
			var id: = String(item.get("id", item.get("key", item.get("name", ""))))
			if id == entry_id:
				return {"tab": tab_index, "index": i}
	return {}


static func push_history(host: Node) -> void :
	host.catalog_history.append({
		"tab": host.catalog_tab, 
		"selected": host.catalog_selected, 
		"scroll": host.catalog_scroll_index, 
		"query": host.catalog_search_query, 
		"filter": host.catalog_filter_mode
	})
	if host.catalog_history.size() > 12:
		host.catalog_history.pop_front()


static func back_from_detail(host: Node) -> void :
	if not host.catalog_history.is_empty():
		var state: Dictionary = Dictionary(host.catalog_history.pop_back())
		host.catalog_tab = int(state.get("tab", host.catalog_tab))
		host.catalog_selected = int(state.get("selected", host.catalog_selected))
		host.catalog_scroll_index = int(state.get("scroll", host.catalog_scroll_index))
		host.catalog_search_query = String(state.get("query", host.catalog_search_query))
		host.catalog_filter_mode = String(state.get("filter", host.catalog_filter_mode))
		host.catalog_detail_open = true
		return
	host.catalog_detail_open = false


static func open_related(host: Node, entry_id: String) -> bool:
	var location: = find_entry_location(host, entry_id)
	if location.is_empty():
		return false
	push_history(host)
	host.catalog_tab = int(location["tab"])
	host.catalog_search_query = ""
	host.catalog_filter_mode = "all"
	host.catalog_selected = int(location["index"])
	host.catalog_scroll_index = 0
	host.catalog_detail_open = true
	var viewport_size: = Vector2(1280, 720)
	if host.is_inside_tree():
		viewport_size = host.get_viewport_rect().size
	ensure_selected_visible(host, viewport_size)
	return true


static func rebuild_validation_report(host: Node) -> void :
	host.catalog_validation_report = CatalogValidator.validate(all_items_by_tab(host))


static func append_text_from_key(host: Node, event: InputEventKey) -> void :
	if event.echo:
		return
	var code: = event.unicode
	if code <= 0:
		return
	var character: = char(code)
	if character.length() != 1:
		return
	var allowed: = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_"
	if allowed.find(character) < 0:
		return
	if host.catalog_search_query.length() >= 36:
		return
	host.catalog_search_query += character
	host.catalog_selected = 0
	host.catalog_scroll_index = 0


static func item_kind(host: Node, item: Dictionary) -> String:
	if item.has("kind"):
		return String(item.get("kind", ""))
	if item.has("nick"):
		return "card"
	var key: = String(item.get("key", ""))
	if key != "":
		for manifest in host.MANIFESTATIONS:
			if String(manifest.get("key", "")) == key:
				return "manifestation"
		for aura in host.AURAS:
			if String(aura.get("key", "")) == key:
				return "spectrum"
	return String(item.get("kind", ""))


static func detail_description(host: Node, item: Dictionary) -> String:
	if String(item.get("identity_text", "")).strip_edges() != "":
		return String(item.get("identity_text", ""))
	var kind: = item_kind(host, item)
	if kind == "card":
		var lines: = [String(item.get("desc", ""))]
		for line in host._card_projection_lines(item):
			lines.append(String(line))
		return "\n".join(lines)
	if kind == "manifestation":
		var details: Dictionary = host._manifestation_details(String(item.get("key", "")))
		return "%s\n%s" % [String(details.get("funcao", item.get("desc", ""))), String(details.get("disparo", ""))]
	if kind == "spectrum":
		var details: Dictionary = host._aura_details(String(item.get("name", "")))
		return "%s\n%s" % [String(details.get("funcao", item.get("desc", ""))), String(details.get("disparo", ""))]
	return String(item.get("desc", ""))


static func detail_lore(host: Node, item: Dictionary) -> String:
	if String(item.get("history_text", "")).strip_edges() != "":
		return String(item.get("history_text", ""))
	var kind: = item_kind(host, item)
	if kind == "card":
		return host._card_lore(String(item.get("name", "")))
	if kind == "manifestation":
		var details: Dictionary = host._manifestation_details(String(item.get("key", "")))
		return "Identidade da Manifestacao: %s\nAssinatura: %s" % [String(item.get("desc", "Registro da Ruptura.")), String(details.get("traco", "Padrao ainda em leitura."))]
	if kind == "spectrum":
		var details: Dictionary = host._aura_details(String(item.get("name", "")))
		return "Espectro de combate: %s\nAssinatura: %s" % [String(item.get("desc", "Registro espectral.")), String(details.get("traco", "Padrao ainda em leitura."))]
	return String(item.get("lore", "Registro estabilizado no banco de dados temporal da Geovana."))


static func detail_mechanics(host: Node, item: Dictionary) -> String:
	if String(item.get("mechanics_text", "")).strip_edges() != "":
		return String(item.get("mechanics_text", ""))
	var kind: = item_kind(host, item)
	if kind == "card":
		return "%s\nCategoria: %s.\nMarcadores: %s." % [
			host._card_effect_snapshot(item, max(1, host._card_count(item))), 
			host._card_category(String(item.get("name", ""))), 
			", ".join(host._card_stat_chips(String(item.get("name", ""))))
		]
	if kind == "manifestation":
		var details: Dictionary = host._manifestation_details(String(item.get("key", "")))
		var lines: = [
			String(details.get("habilidade", "Q")), 
			String(details.get("desc_hab", "")), 
			String(details.get("traco", "")), 
			"Risco: %s" % String(details.get("risco", ""))
		]
		if details.has("info_rows"):
			for row in details["info_rows"]:
				lines.append("%s: %s" % [String(row.get("label", "")), String(row.get("text", ""))])
		return "\n".join(lines)
	if kind == "spectrum":
		var details: Dictionary = host._aura_details(String(item.get("name", "")))
		return "%s\n%s\n%s\nRisco: %s" % [
			String(details.get("habilidade", "Habilidade")), 
			String(details.get("desc_hab", "")), 
			String(details.get("traco", "")), 
			String(details.get("risco", ""))
		]
	return String(item.get("mechanics", "Entrada monitorada durante a jornada."))
