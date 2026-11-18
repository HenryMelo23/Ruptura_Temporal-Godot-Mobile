extends RefCounted
## Catalogo Temporal: lista com rolagem continua (arrastar/roda), filtros por
## dimensao e uma pagina de leitura unica por registro (sem abas), com
## navegacao anterior/proximo e "ecos" clicaveis. So apresentacao; o
## conteudo vem de Main/CatalogRepository/RTCatalogLore.

const ACCENT := Color(0.36, 0.88, 0.87)
const GOLD := Color(1.0, 0.82, 0.42)
const TEXT := Color(0.94, 0.94, 0.89)
const MUTED := Color(0.59, 0.72, 0.74)
const CATEGORIES := ["Manifestações", "Inimigos", "Chefes", "Fases", "Arquivo", "Espectros", "Cartas"]
const SECTIONS := ["Registro"]
const DIM_LABELS := {1: "Castelo", 2: "Mundo branco", 3: "Catedral", 4: "Nexo", 5: "Cápsula", 6: "Chaga", 7: "Cinzas", 8: "Sertão", 9: "Cripta"}
const GAP := 12.0
const TAP_SLOP := 14.0
const COMBAT_PORTRAITS := {
	"nevasca": "res://assets/sprites/boss2_remaster/idle/idle_01.png",
	"pai_rato": "res://assets/sprites/boss3/remake/idle/idle_01.png",
	"umbra": "res://assets/sprites/umbra_v3/idle_01.png",
	"matriarca_chaga": "res://assets/sprites/boss6_rework/boss6_idle_00.png",
}

static var _tex_cache: Dictionary = {}


# ================================================================ layout
static func compact(host: Node, viewport: Vector2) -> bool:
	return viewport.x < 1100.0 or viewport.y < 620.0 or not host._uses_desktop_ui()


static func margin(viewport: Vector2) -> float:
	return 16.0 if viewport.x < 900.0 else 24.0


static func category_rect(host: Node, index: int, viewport: Vector2) -> Rect2:
	var m := margin(viewport)
	var w: float = (viewport.x - m * 2.0 - 6.0 * float(CATEGORIES.size() - 1)) / float(CATEGORIES.size())
	return Rect2(m + float(index) * (w + 6.0), 78.0, w, 44.0)


static func subfilters(host: Node) -> Array:
	match int(host.catalog_tab):
		1:
			var dims: Dictionary = {}
			for item in host._catalog_public_entries_for_tab(1):
				var d := int(Dictionary(item).get("dimension", 0))
				if d > 0:
					dims[d] = true
			var keys: Array = dims.keys()
			keys.sort()
			var out: Array = [["", "Todos"]]
			for d in keys:
				out.append([str(d), String(DIM_LABELS.get(d, "Dimensão %d" % d))])
			return out
		6:
			return [["", "Todas"], ["open", "Descobertas"], ["locked", "Lacradas"]]
	return []


static func subfilter_rects(host: Node, viewport: Vector2) -> Array:
	var out: Array = []
	var x := margin(viewport)
	for f in subfilters(host):
		var w: float = host.menu_ui_font.get_string_size(String(f[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 30.0
		out.append([String(f[0]), Rect2(x, 132.0, w, 32.0), String(f[1])])
		x += w + 8.0
	return out


static func gallery_rect(host: Node, viewport: Vector2) -> Rect2:
	var m := margin(viewport)
	var top: float = 174.0 if not subfilters(host).is_empty() else 134.0
	return Rect2(m, top, viewport.x - m * 2.0, viewport.y - top - 68.0)


static func columns(host: Node, viewport: Vector2) -> int:
	return clampi(int(gallery_rect(host, viewport).size.x / 210.0), 2, 6)


static func tile_size(host: Node, viewport: Vector2) -> Vector2:
	var area := gallery_rect(host, viewport)
	var cols := columns(host, viewport)
	var w: float = (area.size.x - float(cols - 1) * GAP) / float(cols)
	return Vector2(w, minf(w * 0.92, 230.0))


static func rows(host: Node, viewport: Vector2) -> int:
	return maxi(1, int(gallery_rect(host, viewport).size.y / (tile_size(host, viewport).y + GAP)))


static func visible_count(host: Node, viewport: Vector2) -> int:
	return columns(host, viewport) * rows(host, viewport)


## Retangulo do item i em coordenadas de tela, ja descontada a rolagem.
## (first_index fica por compatibilidade com chamadas antigas.)
static func item_rect(host: Node, index: int, _first_index: int, viewport: Vector2) -> Rect2:
	var area := gallery_rect(host, viewport)
	var cols := columns(host, viewport)
	var size := tile_size(host, viewport)
	var row: int = index / cols
	var col: int = index % cols
	return Rect2(area.position + Vector2(float(col) * (size.x + GAP), float(row) * (size.y + GAP) - float(host.catalog_scroll_px)), size)


static func content_height(host: Node, viewport: Vector2, count: int) -> float:
	var cols := columns(host, viewport)
	var r: int = int(ceil(float(count) / float(cols)))
	return maxf(0.0, float(r) * (tile_size(host, viewport).y + GAP) - GAP)


static func max_scroll(host: Node, viewport: Vector2, count: int) -> float:
	return maxf(0.0, content_height(host, viewport, count) - gallery_rect(host, viewport).size.y)


static func footer_rect(viewport: Vector2, key: String) -> Rect2:
	var m := margin(viewport)
	match key:
		"back": return Rect2(m, viewport.y - 56.0, 170.0, 44.0)
	return Rect2()


static func preview_rect(viewport: Vector2) -> Rect2:
	return Rect2()


# ---------------------------------------------------------------- detalhe
static func detail_panel_rect(viewport: Vector2) -> Rect2:
	var m := margin(viewport)
	return Rect2(m, 74.0, viewport.x - m * 2.0, viewport.y - 140.0)


static func detail_art_rect(viewport: Vector2) -> Rect2:
	var panel := detail_panel_rect(viewport)
	var w: float = clampf(panel.size.x * 0.3, 200.0, 360.0)
	return Rect2(panel.position + Vector2(16, 16), Vector2(w, minf(w, panel.size.y - 150.0)))


static func detail_text_rect(viewport: Vector2) -> Rect2:
	var panel := detail_panel_rect(viewport)
	var art := detail_art_rect(viewport)
	var x: float = art.end.x + 24.0
	return Rect2(x, panel.position.y + 16.0, panel.end.x - x - 16.0, panel.size.y - 32.0)


static func section_rect(_index: int, _viewport: Vector2) -> Rect2:
	return Rect2()


static func back_detail_rect(viewport: Vector2) -> Rect2:
	return Rect2(margin(viewport), viewport.y - 56.0, 210.0, 44.0)


static func nav_rect(viewport: Vector2, key: String) -> Rect2:
	var m := margin(viewport)
	if key == "prev":
		return Rect2(viewport.x - m - 108.0, viewport.y - 56.0, 50.0, 44.0)
	return Rect2(viewport.x - m - 50.0, viewport.y - 56.0, 50.0, 44.0)


static func echo_area(viewport: Vector2) -> Rect2:
	var panel := detail_panel_rect(viewport)
	var art := detail_art_rect(viewport)
	return Rect2(panel.position.x + 16.0, art.end.y + 96.0, art.size.x, panel.end.y - art.end.y - 108.0)


# ================================================================ dados
static func apply_subfilter(host: Node, items: Array) -> Array:
	var f: String = String(host.catalog_subfilter)
	if f == "":
		return items
	var out: Array = []
	for item in items:
		var it: Dictionary = item
		match int(host.catalog_tab):
			1:
				if str(int(it.get("dimension", 0))) == f:
					out.append(it)
			6:
				var locked: bool = host._catalog_item_locked(it)
				if (f == "locked") == locked:
					out.append(it)
			_:
				out.append(it)
	return out


static func texture_for(host: Node, item: Dictionary) -> Texture2D:
	var id: String = String(item.get("id", ""))
	if COMBAT_PORTRAITS.has(id):
		var portrait_path: String = COMBAT_PORTRAITS[id]
		if not _tex_cache.has(portrait_path):
			_tex_cache[portrait_path] = load(portrait_path) if ResourceLoader.exists(portrait_path) else null
		if _tex_cache[portrait_path] is Texture2D:
			return _tex_cache[portrait_path]
	if id in ["sineiro_boreal", "suturador_ambar"]:
		var sheet: Texture2D = host._catalog_item_texture(item)
		if sheet != null:
			var columns := 6 if id == "sineiro_boreal" else 4
			var rows := 4 if id == "sineiro_boreal" else 6
			var frame_key := "catalog_frame:" + id
			var frame: AtlasTexture = _tex_cache.get(frame_key)
			if frame == null or frame.atlas != sheet:
				frame = AtlasTexture.new()
				frame.atlas = sheet
				frame.region = Rect2(Vector2.ZERO, sheet.get_size() / Vector2(columns, rows))
				_tex_cache[frame_key] = frame
			return frame
	var path: String = String(item.get("texture_path", ""))
	if path != "":
		if not _tex_cache.has(path):
			_tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
		if _tex_cache[path] != null:
			return _tex_cache[path]
	return host._catalog_item_texture(item)


static func discovered_count(host: Node) -> Vector2i:
	var total := 0
	var open := 0
	for tab in range(CATEGORIES.size()):
		for item in host._catalog_public_entries_for_tab(tab):
			total += 1
			if not host._catalog_item_locked(item):
				open += 1
	return Vector2i(open, total)


# ================================================================ desenho
static func surface(host: Node, rect: Rect2, selected: bool = false, accent: Color = ACCENT) -> void:
	host.draw_rect(rect, Color(0.03, 0.065, 0.073, 0.96) if selected else Color(0.016, 0.032, 0.041, 0.94))
	host.draw_rect(rect, Color(accent, 0.75) if selected else Color(0.25, 0.4, 0.43, 0.35), false, 1.0)
	if selected:
		host.draw_rect(Rect2(rect.position, Vector2(3.0, rect.size.y)), accent)


static func button(host: Node, rect: Rect2, label: String, active: bool = false, enabled: bool = true, size: int = 13) -> void:
	var hovered: bool = enabled and rect.has_point(host.get_global_mouse_position())
	surface(host, rect, active or hovered)
	var fitted: int = size
	while fitted > 9 and host.menu_ui_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > rect.size.x - 12.0:
		fitted -= 1
	host._draw_centered_with_font(host.menu_ui_font, label, rect.get_center() + Vector2(0, 4), fitted, TEXT if enabled else Color(0.35, 0.46, 0.48))


static func draw_locked(host: Node, rect: Rect2) -> void:
	var center := rect.get_center()
	var size: float = minf(32.0, rect.size.y * 0.3)
	host.draw_arc(center - Vector2(0, size * 0.25), size * 0.33, PI, TAU, 16, MUTED, 2.0, true)
	host.draw_rect(Rect2(center + Vector2(-size * 0.48, -size * 0.25), Vector2(size * 0.96, size * 0.7)), Color(0.12, 0.2, 0.23))
	host.draw_rect(Rect2(center + Vector2(-size * 0.48, -size * 0.25), Vector2(size * 0.96, size * 0.7)), MUTED, false, 1.0)


static func draw_art(host: Node, item: Dictionary, rect: Rect2) -> void:
	if host._catalog_item_locked(item):
		draw_locked(host, rect)
		return
	var tex: Texture2D = texture_for(host, item)
	if tex == null:
		host._draw_centered_with_font(host.menu_ui_font, String(item.get("name", "?")).left(1), rect.get_center() + Vector2(0, 14), 40, Color(MUTED, 0.6))
		return
	host._draw_texture_contain(tex, rect, Color.WHITE)
	_draw_enemy_identity(host, item, rect)


## Arte de um tile cortado pela borda da galeria: desenha so a parte visivel.
static func _draw_art_clipped(host: Node, item: Dictionary, rect: Rect2, clip: Rect2) -> void:
	if host._catalog_item_locked(item):
		if rect.get_center().y > clip.position.y and rect.get_center().y < clip.end.y:
			draw_locked(host, rect)
		return
	var tex: Texture2D = texture_for(host, item)
	if tex == null:
		return
	var ts := tex.get_size()
	if ts.x <= 0.0 or ts.y <= 0.0:
		return
	var k: float = minf(rect.size.x / ts.x, rect.size.y / ts.y)
	var dest := Rect2(rect.get_center() - ts * k * 0.5, ts * k)
	var vis := dest.intersection(clip)
	if vis.size.x <= 1.0 or vis.size.y <= 1.0:
		return
	var src := Rect2((vis.position - dest.position) / k, vis.size / k)
	host.draw_texture_rect_region(tex, vis, src)
	if clip.encloses(rect):
		_draw_enemy_identity(host, item, rect)


static func _draw_enemy_identity(host: Node, item: Dictionary, rect: Rect2) -> void:
	var id: String = String(item.get("id", ""))
	if id == "rebobinador":
		var center: Vector2 = rect.get_center() + Vector2(0.0, rect.size.y * 0.11)
		var radius: float = minf(rect.size.x, rect.size.y) * 0.34
		host.draw_arc(center, radius, -PI * 0.72, PI * 0.68, 32, Color(1.0, 0.52, 0.12, 0.85), 3.0, true)
		host.draw_circle(center + Vector2(radius * 0.88, -radius * 0.25), 4.0, Color(1.0, 0.82, 0.32, 0.95))
	elif id == "briguer_escudeiro":
		var center: Vector2 = rect.get_center() + Vector2(rect.size.x * 0.22, rect.size.y * 0.10)
		var radius: float = minf(rect.size.x, rect.size.y) * 0.28
		host.draw_arc(center, radius, -PI * 0.48, PI * 0.48, 24, Color(0.68, 0.96, 1.0, 0.88), 4.0, true)
		host.draw_line(center + Vector2(radius * 0.35, -radius * 0.8), center + Vector2(radius * 0.35, radius * 0.8), Color(0.84, 1.0, 1.0, 0.72), 2.0, true)


static func _draw_unread_dot(host: Node, rect: Rect2) -> void:
	host.draw_circle(rect.position + Vector2(rect.size.x - 9.0, 9.0), 5.0, Color(1.0, 0.3, 0.34))


static func _item_unread(host: Node, item: Dictionary) -> bool:
	var kind: String = String(host._catalog_item_kind(item))
	if kind not in ["manifestation", "spectrum"]:
		return false
	return host._content_is_unread("catalog_" + kind, String(item.get("key", item.get("id", ""))))


static func draw(host: Node, viewport: Vector2) -> void:
	host._draw_texture_cover(host.textures["menu_panels"][0], Rect2(Vector2.ZERO, viewport))
	host._draw_menu_scrim(viewport, true)
	var m := margin(viewport)
	host._draw_ui_text("RUPTURA TEMPORAL  /  CADERNO DA GEOVANA", Vector2(m, 24), 10, ACCENT)
	host._draw_ui_text("Catálogo temporal", Vector2(m, 58), 28, TEXT)
	var progress := discovered_count(host)
	var prog_text := "%d de %d registros" % [progress.x, progress.y]
	host._draw_ui_text(prog_text, Vector2(viewport.x - m - host.menu_ui_font.get_string_size(prog_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, 56), 12, MUTED)
	if host.catalog_detail_open:
		draw_detail(host, viewport)
		return
	for i in range(CATEGORIES.size()):
		var rect := category_rect(host, i, viewport)
		var count: int = host._catalog_public_entries_for_tab(i).size()
		button(host, rect, "%s  %d" % [CATEGORIES[i], count], i == int(host.catalog_tab), true, 14)
		if (i == 0 and host._content_section_has_unread("catalog_manifestation")) or (i == 5 and host._content_section_has_unread("catalog_spectrum")):
			_draw_unread_dot(host, rect)
	for f in subfilter_rects(host, viewport):
		button(host, f[1], f[2], String(host.catalog_subfilter) == String(f[0]), true, 13)
	var items: Array = host._catalog_items()
	var area := gallery_rect(host, viewport)
	host.catalog_scroll_px = clampf(float(host.catalog_scroll_px), 0.0, max_scroll(host, viewport, items.size()))
	_follow_selection(host, viewport, items.size())
	for i in range(items.size()):
		var rect := item_rect(host, i, 0, viewport)
		if rect.end.y < area.position.y - 4.0 or rect.position.y > area.end.y + 4.0:
			continue
		_draw_tile(host, items[i], rect, i == int(host.catalog_selected), area)
	if items.is_empty():
		host._draw_ui_text("Nenhum registro nesta seleção.", area.position + Vector2(8, 40), 18, MUTED)
	# Faixas de fade e barra de rolagem.
	var total_h := content_height(host, viewport, items.size())
	if total_h > area.size.y:
		var k: float = area.size.y / total_h
		var bar_h: float = maxf(36.0, area.size.y * k)
		var y: float = area.position.y + (area.size.y - bar_h) * (float(host.catalog_scroll_px) / maxf(1.0, total_h - area.size.y))
		host.draw_rect(Rect2(area.end.x + 4.0, area.position.y, 3.0, area.size.y), Color(MUTED, 0.15))
		host.draw_rect(Rect2(area.end.x + 4.0, y, 3.0, bar_h), Color(ACCENT, 0.7))
	button(host, footer_rect(viewport, "back"), "←  Voltar ao menu")
	var hint := "Arraste para ver mais  ·  toque para abrir" if compact(host, viewport) else "Roda do mouse rola  ·  A/D categorias  ·  Enter abre"
	host._draw_ui_text(hint, Vector2(footer_rect(viewport, "back").end.x + 18.0, viewport.y - 28.0), 11, MUTED)


static func _follow_selection(host: Node, viewport: Vector2, count: int) -> void:
	if int(host.catalog_selected) == int(host.catalog_last_selected) or count <= 0:
		return
	host.catalog_last_selected = host.catalog_selected
	if not bool(host.catalog_keyboard_nav):
		return
	host.catalog_keyboard_nav = false
	var area := gallery_rect(host, viewport)
	var rect := item_rect(host, clampi(int(host.catalog_selected), 0, count - 1), 0, viewport)
	if rect.position.y < area.position.y:
		host.catalog_scroll_px = float(host.catalog_scroll_px) - (area.position.y - rect.position.y)
	elif rect.end.y > area.end.y:
		host.catalog_scroll_px = float(host.catalog_scroll_px) + (rect.end.y - area.end.y)
	host.catalog_scroll_px = clampf(float(host.catalog_scroll_px), 0.0, max_scroll(host, viewport, count))


static func _draw_tile(host: Node, item: Dictionary, rect: Rect2, selected: bool, clip: Rect2) -> void:
	var locked: bool = host._catalog_item_locked(item)
	var color: Color = MUTED if locked else Color(item.get("color", ACCENT))
	var vis_rect := rect.intersection(clip)
	if vis_rect.size.y < 2.0:
		return
	surface(host, vis_rect, selected, color)
	var art := Rect2(rect.position + Vector2(10, 10), Vector2(rect.size.x - 20.0, rect.size.y - 70.0))
	var art_vis := art.intersection(clip)
	if art_vis.size.y > 0.0:
		host.draw_rect(art_vis, Color(color, 0.06))
	if art.position.y >= clip.position.y - 2.0 and art.end.y <= clip.end.y + 2.0:
		draw_art(host, item, art.grow(-6.0))
	elif art.intersects(clip):
		_draw_art_clipped(host, item, art.grow(-6.0), clip)
	var title: String = host._catalog_display_title(item)
	if rect.end.y - 54.0 >= clip.position.y and rect.end.y - 34.0 <= clip.end.y:
		host._draw_ui_text(title, Vector2(rect.position.x + 12.0, rect.end.y - 38.0), 16, TEXT, rect.size.x - 24.0)
	var hook: String = host._catalog_locked_objective_text(item, false) if locked else String(item.get("summary", host._catalog_display_short_text(item)))
	if rect.end.y - 28.0 >= clip.position.y and rect.end.y - 12.0 <= clip.end.y:
		host._draw_ui_text(hook, Vector2(rect.position.x + 12.0, rect.end.y - 16.0), 11, Color(MUTED, 0.95), rect.size.x - 24.0)
	if rect.position.y + 12.0 < clip.position.y:
		return
	if int(item.get("dimension", 0)) > 0 and not locked:
		var tag := String(DIM_LABELS.get(int(item["dimension"]), ""))
		var tw: float = host.menu_ui_font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 12.0
		var tr := Rect2(rect.position + Vector2(14, 14), Vector2(tw, 18))
		host.draw_rect(tr, Color(0.0, 0.0, 0.0, 0.55))
		host._draw_ui_text(tag, tr.position + Vector2(6, 13), 10, Color(color, 0.95))
	if not locked and _item_unread(host, item):
		_draw_unread_dot(host, rect)


# ---------------------------------------------------------------- detalhe
static func _current(host: Node) -> Dictionary:
	var items: Array = host._catalog_items()
	if items.is_empty():
		return {}
	return items[clampi(int(host.catalog_selected), 0, items.size() - 1)]


static func draw_detail(host: Node, viewport: Vector2) -> void:
	var items: Array = host._catalog_items()
	var item := _current(host)
	if item.is_empty():
		return
	var locked: bool = host._catalog_item_locked(item)
	var color: Color = MUTED if locked else Color(item.get("color", ACCENT))
	var panel := detail_panel_rect(viewport)
	var art := detail_art_rect(viewport)
	surface(host, panel)
	host.draw_rect(art, Color(0.007, 0.015, 0.022, 0.75))
	host.draw_rect(art, Color(color, 0.4), false, 1.0)
	draw_art(host, item, art.grow(-12.0))
	var y: float = art.end.y + 26.0
	host._draw_ui_text("REGISTRO LACRADO" if locked else host._catalog_detail_title(host._catalog_item_kind(item)), Vector2(art.position.x, y), 10, color)
	host._draw_ui_text(host._catalog_display_title(item), Vector2(art.position.x, y + 28.0), 24, TEXT, art.size.x)
	if not locked:
		host._draw_ui_text(String(item.get("subtitle", "")), Vector2(art.position.x, y + 50.0), 12, Color(color, 0.9), art.size.x)
	draw_echoes(host, item, viewport, color)
	button(host, back_detail_rect(viewport), "←  Voltar aos registros")
	var pos_text := "%d / %d" % [clampi(int(host.catalog_selected), 0, items.size() - 1) + 1, items.size()]
	host._draw_ui_text(pos_text, Vector2(nav_rect(viewport, "prev").position.x - 12.0 - host.menu_ui_font.get_string_size(pos_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, viewport.y - 28.0), 12, MUTED)
	button(host, nav_rect(viewport, "prev"), "‹", false, int(host.catalog_selected) > 0, 20)
	button(host, nav_rect(viewport, "next"), "›", false, int(host.catalog_selected) < items.size() - 1, 20)


static func draw_echoes(host: Node, item: Dictionary, viewport: Vector2, color: Color) -> void:
	host.catalog_related_buttons.clear()
	if host._catalog_item_locked(item):
		return
	var area := echo_area(viewport)
	var related: Array = item.get("related_entry_ids", [])
	if related.is_empty() or area.size.y < 40.0:
		return
	host._draw_ui_text("ECOS NO CADERNO", area.position + Vector2(0, 12), 10, Color(color, 0.9))
	var x := area.position.x
	var y := area.position.y + 22.0
	for related_id in related:
		var target: Dictionary = host._catalog_find_entry(String(related_id))
		if target.is_empty():
			continue
		var label: String = host._catalog_display_title(target)
		var w: float = clampf(host.menu_ui_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 24.0, 70.0, area.size.x)
		if x + w > area.end.x:
			x = area.position.x
			y += 36.0
		if y + 30.0 > area.end.y:
			break
		var rect := Rect2(x, y, w, 30.0)
		host.catalog_related_buttons[String(related_id)] = rect
		button(host, rect, label, false, true, 12)
		x += w + 6.0


## Texto completo do registro em uma pagina so (RichTextLabel com bbcode).
static func reader_text(host: Node, item: Dictionary) -> String:
	if host._catalog_item_locked(item):
		var teaser := ""
		var ref := String(item.get("book_ref", "")).strip_edges()
		if ref != "":
			teaser = "\n\n[font_size=13][color=#7a8f9a]FRAGMENTO RECUPERADO[/color][/font_size]\n[i][color=#9fb3bd]%s[/color][/i]" % ref
		return "[color=#8fb8bb]%s[/color]\n\n%s%s" % [host._catalog_detail_lore(item), host._catalog_locked_objective_text(item, true), teaser]
	var accent: Color = Color(item.get("color", ACCENT))
	var head := func(title: String) -> String:
		return "[font_size=13][color=#%s]%s[/color][/font_size]\n" % [accent.to_html(false), title]
	var parts: PackedStringArray = []
	var history: String = String(item.get("history_text", "")).strip_edges()
	if history == "":
		history = host._catalog_detail_lore(item)
	parts.append(head.call("HISTÓRIA") + history)
	var note: String = String(item.get("field_note", "")).strip_edges()
	if note != "" and not note.begins_with("Nota de campo: registro estabilizado"):
		parts.append(head.call("NOTA DA GEOVANA") + "[color=#ffd27a]“%s”[/color]" % note.trim_prefix("Nota de Geovana: "))
	var book: String = String(item.get("book_ref", "")).strip_edges()
	if book != "":
		parts.append(head.call("DO LIVRO") + "[color=#b9c9cc]%s[/color]" % book)
	var identity: String = host._catalog_detail_description(item).strip_edges()
	var mechanics: String = host._catalog_detail_mechanics(item).strip_edges()
	var combat: String = identity if mechanics == "" else (identity + "\n\n" + mechanics if identity != "" and identity != history else mechanics)
	if combat != "":
		parts.append(head.call("EM COMBATE") + combat)
	return "\n\n".join(parts)


static func sync(host: Node, delta: float) -> void:
	if host.mode != "catalog" or not host.catalog_detail_open:
		if is_instance_valid(host.catalog_detail_text):
			host.catalog_detail_text.hide()
		host.catalog_detail_signature = ""
		if host.mode != "catalog":
			host.catalog_touch_index = -1
		else:
			_inertia(host, delta)
		return
	var item := _current(host)
	if item.is_empty():
		if is_instance_valid(host.catalog_detail_text):
			host.catalog_detail_text.hide()
		return
	var viewport: Vector2 = host.get_viewport_rect().size
	if not is_instance_valid(host.catalog_detail_text):
		var new_reader := RichTextLabel.new()
		new_reader.name = "CatalogReader"
		new_reader.selection_enabled = false
		new_reader.scroll_active = true
		new_reader.mouse_filter = Control.MOUSE_FILTER_IGNORE
		new_reader.add_theme_font_override("normal_font", host.menu_ui_font)
		new_reader.add_theme_color_override("default_color", TEXT)
		new_reader.add_theme_constant_override("line_separation", 6)
		host.add_child(new_reader)
		host.catalog_detail_text = new_reader
	var reader: RichTextLabel = host.catalog_detail_text
	reader.bbcode_enabled = true
	var rect := detail_text_rect(viewport)
	reader.position = rect.position
	reader.size = rect.size
	reader.add_theme_font_size_override("normal_font_size", 16 if viewport.y >= 650.0 else 15)
	reader.show()
	var signature := "%d/%d/%s/%s" % [host.catalog_tab, host.catalog_selected, host.catalog_subfilter, host._catalog_item_locked(item)]
	if signature != host.catalog_detail_signature:
		host.catalog_detail_signature = signature
		reader.text = reader_text(host, item)
		reader.get_v_scroll_bar().value = 0.0
		reader.modulate.a = 0.0
	reader.modulate.a = move_toward(reader.modulate.a, 1.0, delta * 7.0)


## Rolagem com inercia depois de soltar o dedo.
static func _inertia(host: Node, delta: float) -> void:
	if bool(host.catalog_drag_active) or absf(float(host.catalog_scroll_vel)) < 5.0:
		host.catalog_scroll_vel = 0.0 if not bool(host.catalog_drag_active) else host.catalog_scroll_vel
		return
	var viewport: Vector2 = host.get_viewport_rect().size
	host.catalog_scroll_px = clampf(float(host.catalog_scroll_px) + float(host.catalog_scroll_vel) * delta, 0.0, max_scroll(host, viewport, host._catalog_items().size()))
	host.catalog_scroll_vel = float(host.catalog_scroll_vel) * pow(0.04, delta)


# ================================================================ entrada
static func step_detail(host: Node, direction: int) -> void:
	var items: Array = host._catalog_items()
	if items.is_empty():
		return
	host.catalog_selected = clampi(int(host.catalog_selected) + direction, 0, items.size() - 1)
	host._catalog_mark_current_item_seen()


static func ensure_visible(host: Node, viewport: Vector2) -> void:
	var count: int = host._catalog_items().size()
	if count <= 0:
		return
	host.catalog_keyboard_nav = true
	host.catalog_last_selected = -1
	_follow_selection(host, viewport, count)


## Pagina inteira (teclado/controle): move a selecao e a rolagem juntas.
static func page(host: Node, direction: int, viewport: Vector2) -> void:
	var items: Array = host._catalog_items()
	if items.is_empty():
		return
	var step: int = maxi(columns(host, viewport), visible_count(host, viewport))
	host.catalog_selected = clampi(int(host.catalog_selected) + direction * step, 0, items.size() - 1)
	host.catalog_scroll_px = clampf(float(host.catalog_scroll_px) + float(direction) * gallery_rect(host, viewport).size.y * 0.85, 0.0, max_scroll(host, viewport, items.size()))
	ensure_visible(host, viewport)


static func _open_index(host: Node, i: int) -> void:
	host.catalog_selected = i
	host.catalog_last_selected = i
	host.catalog_detail_section = 0
	host.catalog_detail_open = true
	host._catalog_mark_current_item_seen()


static func handle_touch(host: Node, pos: Vector2, viewport: Vector2) -> void:
	if host.catalog_detail_open:
		for related_id in host.catalog_related_buttons.keys():
			if Rect2(host.catalog_related_buttons[related_id]).has_point(pos):
				host._catalog_open_related(String(related_id))
				host.catalog_subfilter = ""
				return
		if nav_rect(viewport, "prev").has_point(pos):
			step_detail(host, -1)
			return
		if nav_rect(viewport, "next").has_point(pos):
			step_detail(host, 1)
			return
		if back_detail_rect(viewport).has_point(pos):
			host.catalog_detail_open = false
			return
		# Toque fora do painel (margens laterais) fecha a ficha.
		if not host._catalog_detail_panel_rect(viewport).has_point(pos) and pos.y > 70.0 and pos.y < viewport.y - 64.0:
			host.catalog_detail_open = false
		return
	for i in range(CATEGORIES.size()):
		if category_rect(host, i, viewport).has_point(pos):
			host._catalog_reset_tab(i)
			return
	for f in subfilter_rects(host, viewport):
		if Rect2(f[1]).has_point(pos):
			host.catalog_subfilter = String(f[0])
			host.catalog_selected = 0
			host.catalog_scroll_px = 0.0
			return
	if footer_rect(viewport, "back").has_point(pos):
		host._go_to_menu()
		return
	var area := gallery_rect(host, viewport)
	if not area.has_point(pos):
		return
	var items: Array = host._catalog_items()
	for i in range(items.size()):
		if item_rect(host, i, 0, viewport).has_point(pos):
			_open_index(host, i)
			return


static func _press(host: Node, pos: Vector2, index: int) -> void:
	host.catalog_touch_index = index
	host.catalog_touch_start = pos
	host.catalog_drag_last = pos
	host.catalog_drag_active = true
	host.catalog_drag_moved = false
	host.catalog_scroll_vel = 0.0


static func _drag(host: Node, pos: Vector2, viewport: Vector2, delta_y: float) -> void:
	if not bool(host.catalog_drag_active):
		return
	if pos.distance_to(host.catalog_touch_start) > TAP_SLOP:
		host.catalog_drag_moved = true
	if host.catalog_detail_open:
		if is_instance_valid(host.catalog_detail_text) and detail_text_rect(viewport).has_point(host.catalog_touch_start):
			host.catalog_detail_text.get_v_scroll_bar().value -= delta_y
		return
	if gallery_rect(host, viewport).has_point(host.catalog_touch_start):
		host.catalog_scroll_px = clampf(float(host.catalog_scroll_px) - delta_y, 0.0, max_scroll(host, viewport, host._catalog_items().size()))
		host.catalog_scroll_vel = -delta_y * 60.0


static func _release(host: Node, pos: Vector2, viewport: Vector2) -> void:
	if not bool(host.catalog_drag_active):
		return
	host.catalog_drag_active = false
	host.catalog_touch_index = -1
	var drag: Vector2 = pos - Vector2(host.catalog_touch_start)
	if host.catalog_detail_open and absf(drag.x) > 70.0 and absf(drag.x) > absf(drag.y) * 1.6:
		host.catalog_scroll_vel = 0.0
		step_detail(host, 1 if drag.x < 0.0 else -1)
		return
	if not bool(host.catalog_drag_moved):
		host.catalog_scroll_vel = 0.0
		handle_touch(host, pos, viewport)


static func handle_event(host: Node, event: InputEvent, viewport: Vector2) -> bool:
	if event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
		if event.pressed and not host._ui_input_blocked():
			host._catalog_change_tab(-1 if event.button_index == JOY_BUTTON_LEFT_SHOULDER else 1)
		return true
	if event is InputEventScreenTouch:
		if host._ui_input_blocked():
			return true
		if event.pressed and not event.canceled:
			_press(host, event.position, event.index)
		elif event.index == host.catalog_touch_index:
			if event.canceled:
				host.catalog_drag_active = false
				host.catalog_touch_index = -1
			else:
				_release(host, event.position, viewport)
		return true
	if event is InputEventScreenDrag:
		if event.index == host.catalog_touch_index:
			_drag(host, event.position, viewport, event.relative.y)
			host.catalog_drag_last = event.position
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if host._ui_input_blocked():
			return true
		if event.pressed:
			_press(host, event.position, -2)
		else:
			_release(host, event.position, viewport)
		return true
	if event is InputEventMouseMotion:
		if bool(host.catalog_drag_active) and int(host.catalog_touch_index) == -2:
			_drag(host, event.position, viewport, event.relative.y)
			return true
		if not host.catalog_detail_open:
			var items: Array = host._catalog_items()
			for i in range(items.size()):
				if item_rect(host, i, 0, viewport).has_point(event.position) and gallery_rect(host, viewport).has_point(event.position):
					host.catalog_selected = i
					host.catalog_last_selected = i
		return false
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var direction: int = 1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1
		if host.catalog_detail_open and is_instance_valid(host.catalog_detail_text):
			host.catalog_detail_text.get_v_scroll_bar().value += direction * 72.0
		else:
			host.catalog_scroll_px = clampf(float(host.catalog_scroll_px) + float(direction) * 90.0, 0.0, max_scroll(host, viewport, host._catalog_items().size()))
		return true
	return false
