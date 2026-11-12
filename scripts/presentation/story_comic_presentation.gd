class_name RTStoryComicPresentation
extends RefCounted

## Desenha a HQ animada: painéis entram em sequência (deslizar, zoom, impacto),
## cada imagem tem câmera lenta (Ken Burns), balões digitam, onomatopeias
## saltam, linhas de velocidade e clarão nos quadros de ação, virada de página.

const INK := Color(0.02, 0.02, 0.04)
const PAPER := Color(0.97, 0.95, 0.9)
const CAPTION := Color(1.0, 0.86, 0.36)
const HUD := Color(0.3, 0.95, 1.0)

static var _tex_cache: Dictionary = {}


static func image(id: String) -> Texture2D:
	if _tex_cache.has(id):
		return _tex_cache[id]
	var tex: Texture2D = null
	for ext in ["jpg", "png", "webp"]:
		var path := "%s%s.%s" % [RTStoryCatalog.IMAGE_DIR, id, ext]
		if ResourceLoader.exists(path):
			tex = load(path) as Texture2D
			break
	_tex_cache[id] = tex
	return tex


## Libera as imagens ao fechar a cena (cada uma ocupa ~3,5 MB de VRAM).
static func clear_cache() -> void:
	_tex_cache.clear()


static func _ease_back(x: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


static func draw(game: Node2D, viewport: Vector2) -> void:
	var story: RTStoryController = game._story()
	if not story.manual_clock:
		story.tick(game.get_process_delta_time())
	game.buttons.clear()
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.03, 0.03, 0.05), true)
	if story.active_id == "":
		return
	var margin: float = clampf(viewport.x * 0.03, 12.0, 36.0)
	var area := Rect2(Vector2(margin, margin), viewport - Vector2(margin, margin) * 2.0 - Vector2(0, 30))
	# Virada de página: tudo desliza para a esquerda e some.
	var turn_k: float = 1.0 - clampf(story.turning / RTStoryController.PAGE_TURN, 0.0, 1.0) if story.turning > 0.0 else 0.0
	var page_shift := Vector2(-viewport.x * 1.1 * turn_k * turn_k, 0)
	var ps: Array = story.panels()
	var t: float = float(Time.get_ticks_msec()) * 0.001
	for i in range(mini(story.shown, ps.size())):
		var panel: Dictionary = ps[i]
		var local_t: float = story.t_panel if i == story.shown - 1 else 99.0
		_draw_panel(game, story, panel, area, local_t, page_shift, t, i == story.shown - 1)
	# Indicador de página + pular.
	var n_pages: int = story.pages().size()
	for p in range(n_pages):
		var c := Vector2(viewport.x * 0.5 + (float(p) - float(n_pages - 1) * 0.5) * 16.0, viewport.y - 18.0)
		game.draw_circle(c, 4.0 if p == story.page else 3.0, Color(PAPER, 0.9 if p == story.page else 0.35))
	var skip := Rect2(Vector2(viewport.x - margin - 110.0, viewport.y - 34.0), Vector2(110.0, 28.0))
	game.draw_rect(skip, Color(0, 0, 0, 0.6), true)
	game.draw_rect(skip, Color(PAPER, 0.6), false, 1.5)
	game._draw_centered("PULAR  ▶▶", skip.get_center() + Vector2(0, 5), 13, Color(PAPER, 0.85))
	game.buttons["story_skip"] = skip
	if story.panel_done() and story.turning <= 0.0:
		var blink: float = 0.5 + 0.5 * sin(t * 6.0)
		game._draw_centered("toque para continuar", Vector2(margin + 90.0, viewport.y - 14.0), 12, Color(PAPER, 0.35 + 0.4 * blink))


static func _draw_panel(game: Node2D, story: RTStoryController, panel: Dictionary, area: Rect2, local_t: float, page_shift: Vector2, t: float, current: bool) -> void:
	var r: Array = panel.get("rect", [0.0, 0.0, 1.0, 1.0])
	var gap := 8.0
	var rect := Rect2(area.position + Vector2(float(r[0]) * area.size.x + gap * 0.5, float(r[1]) * area.size.y + gap * 0.5), Vector2(float(r[2]) * area.size.x - gap, float(r[3]) * area.size.y - gap))
	var enter_k: float = clampf(local_t / RTStoryController.PANEL_ENTER, 0.0, 1.0)
	var e: float = _ease_back(enter_k) if enter_k < 1.0 else 1.0
	var offset := page_shift
	var scale := 1.0
	var alpha := 1.0
	var shake := Vector2.ZERO
	match String(panel.get("enter", "fade")):
		"slide_left":
			offset.x += -(1.0 - e) * (rect.size.x + 60.0)
		"slide_right":
			offset.x += (1.0 - e) * (rect.size.x + 60.0)
		"slide_up":
			offset.y += (1.0 - e) * (rect.size.y + 60.0)
		"zoom":
			scale = lerpf(0.6, 1.0, e)
			alpha = enter_k
		"impact":
			scale = lerpf(1.25, 1.0, enter_k * enter_k)
			alpha = minf(1.0, enter_k * 3.0)
			if local_t < 0.6:
				shake = Vector2(sin(local_t * 90.0), cos(local_t * 77.0)) * 9.0 * (1.0 - local_t / 0.6)
		_:
			alpha = enter_k
	var center: Vector2 = rect.get_center() + offset + shake
	var size: Vector2 = rect.size * scale
	var dr := Rect2(center - size * 0.5, size)
	# Moldura (sombra + borda de HQ).
	game.draw_rect(Rect2(dr.position + Vector2(6, 6), dr.size), Color(0, 0, 0, 0.6 * alpha), true)
	game.draw_rect(dr.grow(4.0), Color(PAPER, alpha), true)
	game.draw_rect(dr.grow(1.0), Color(INK, alpha), true)
	# Imagem com câmera lenta (cover + Ken Burns) ou placeholder.
	var cam: Array = panel.get("cam", [1.0, 1.0, Vector2.ZERO, Vector2.ZERO])
	var life: float = clampf(local_t / maxf(1.0, story.panel_duration(panel)), 0.0, 1.0) if current else 1.0
	var zoom: float = lerpf(float(cam[0]), float(cam[1]), smoothstep(0.0, 1.0, life))
	var pan: Vector2 = Vector2(cam[2]).lerp(Vector2(cam[3]), smoothstep(0.0, 1.0, life))
	var tex: Texture2D = image(String(panel.get("img", ""))) if String(panel.get("type", "")) != "card" else null
	if String(panel.get("type", "")) == "card":
		_draw_card(game, dr, String(panel.get("title", "")), alpha, local_t, t)
	elif tex != null:
		var ts: Vector2 = tex.get_size()
		var aspect: float = dr.size.x / maxf(1.0, dr.size.y)
		var src_size := Vector2(ts.x, ts.x / aspect)
		if src_size.y > ts.y:
			src_size = Vector2(ts.y * aspect, ts.y)
		src_size /= zoom
		var focus: Vector2 = Vector2(panel.get("focus", Vector2(0.5, 0.5)))
		var src_center: Vector2 = focus * ts + pan * ts
		var src := Rect2(src_center - src_size * 0.5, src_size)
		src.position = src.position.clamp(Vector2.ZERO, ts - src.size)
		game.draw_texture_rect_region(tex, dr, src, Color(1, 1, 1, alpha))
	else:
		_draw_placeholder(game, dr, panel, alpha, zoom, pan, t)
	match String(panel.get("fx", "")):
		"speed":
			_speed_lines(game, dr, t, alpha * (0.5 if not current else 1.0))
		"flash":
			if current and local_t < 0.35:
				game.draw_rect(dr, Color(1, 1, 1, (1.0 - local_t / 0.35) * 0.85), true)
	# Falas: digitam na ordem.
	var chars_left: float = maxf(0.0, (local_t - RTStoryController.PANEL_ENTER) * RTStoryController.TYPE_CPS) if current else 99999.0
	for line in Array(panel.get("lines", [])):
		var full: String = story.fill(String(line[1]))
		if full == "":
			continue
		var visible: int = int(minf(float(full.length()), chars_left))
		chars_left -= float(full.length())
		if visible <= 0:
			break
		var anchor: Vector2 = dr.position + Vector2(float(line[2]) * dr.size.x, float(line[3]) * dr.size.y)
		_draw_line(game, String(line[0]), full.substr(0, visible), full, anchor, dr, alpha, visible >= full.length())


## Cartao de dimensao: leitura do visor do bracelete com o nome do lugar.
static func _draw_card(game: Node2D, dr: Rect2, title: String, alpha: float, local_t: float, t: float) -> void:
	game.draw_rect(dr, Color(0.01, 0.06, 0.08, alpha), true)
	var y: float = dr.position.y + 4.0
	while y < dr.end.y:
		game.draw_line(Vector2(dr.position.x, y), Vector2(dr.end.x, y), Color(HUD, 0.05 * alpha), 1.0)
		y += 4.0
	var scan_y: float = dr.position.y + fposmod(t * 0.6, 1.0) * dr.size.y
	game.draw_rect(Rect2(Vector2(dr.position.x, scan_y), Vector2(dr.size.x, 2.0)), Color(HUD, 0.25 * alpha), true)
	var face: Font = game.font
	var big: int = 26 if dr.size.x > 360.0 else 20
	game.draw_string(face, dr.position + Vector2(18, 34), "BRACELETE  ·  LEITURA", HORIZONTAL_ALIGNMENT_LEFT, dr.size.x - 36.0, 12, Color(HUD, 0.8 * alpha))
	var shown: int = int(clampf((local_t - 0.3) * 30.0, 0.0, float(title.length())))
	game.draw_multiline_string(face, dr.position + Vector2(18, 34 + big + 14), title.substr(0, shown), HORIZONTAL_ALIGNMENT_LEFT, dr.size.x - 36.0, big, 2, Color(PAPER, alpha))
	var bar := Rect2(dr.position + Vector2(18, dr.size.y - 46.0), Vector2(dr.size.x - 36.0, 6.0))
	var k: float = clampf(local_t / 1.6, 0.0, 1.0)
	game.draw_rect(bar, Color(HUD, 0.18 * alpha), true)
	game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), Color(HUD, 0.9 * alpha), true)
	game.draw_string(face, bar.position + Vector2(0, 26), "FRAGMENTO DETECTADO" if k >= 1.0 else "ESCANEANDO...", HORIZONTAL_ALIGNMENT_LEFT, bar.size.x, 12, Color(CAPTION if k >= 1.0 else HUD, alpha))


static func _draw_placeholder(game: Node2D, dr: Rect2, panel: Dictionary, alpha: float, zoom: float, pan: Vector2, t: float) -> void:
	var seed_f: float = float(String(panel.get("img", "")).hash() % 1000) / 1000.0
	var top := Color.from_hsv(fposmod(0.72 + seed_f * 0.3, 1.0), 0.55, 0.35, alpha)
	var bottom := Color.from_hsv(fposmod(0.05 + seed_f * 0.2, 1.0), 0.6, 0.18, alpha)
	game.draw_polygon(PackedVector2Array([dr.position, Vector2(dr.end.x, dr.position.y), dr.end, Vector2(dr.position.x, dr.end.y)]), PackedColorArray([top, top, bottom, bottom]))
	# Formas que se movem com a câmera, para sentir o Ken Burns sem arte.
	for k in range(5):
		var c: Vector2 = dr.get_center() + (Vector2(fposmod(seed_f * 7.0 + float(k) * 0.23, 1.0) - 0.5, fposmod(seed_f * 3.0 + float(k) * 0.37, 1.0) - 0.5) * dr.size * 0.8 - pan * dr.size) * zoom
		if dr.has_point(c):
			game.draw_circle(c, dr.size.y * 0.08 * zoom * (1.0 + float(k) * 0.2), Color(1, 1, 1, 0.06 * alpha))
	var face: Font = game.font
	var txt := "[%s]\n%s" % [String(panel.get("img", "")), String(panel.get("art", ""))]
	game.draw_multiline_string(face, dr.position + Vector2(14, dr.size.y - 64.0), txt, HORIZONTAL_ALIGNMENT_LEFT, dr.size.x - 28.0, 12, 4, Color(1, 1, 1, 0.45 * alpha))


static func _speed_lines(game: Node2D, dr: Rect2, t: float, alpha: float) -> void:
	var c: Vector2 = dr.get_center()
	for k in range(22):
		var a: float = float(k) / 22.0 * TAU + sin(float(k) * 3.7) * 0.1
		var flick: float = fposmod(t * 3.0 + float(k) * 0.37, 1.0)
		var r0: float = minf(dr.size.x, dr.size.y) * (0.35 + 0.15 * flick)
		var p0: Vector2 = c + Vector2.from_angle(a) * r0
		var p1: Vector2 = c + Vector2.from_angle(a) * maxf(dr.size.x, dr.size.y)
		p1 = p1.clamp(dr.position, dr.end)
		game.draw_line(p0, p1, Color(1, 1, 1, 0.18 * alpha), 2.0)


static func _draw_line(game: Node2D, kind: String, text: String, full: String, anchor: Vector2, panel: Rect2, alpha: float, finished: bool) -> void:
	var face: Font = game.font
	var size: int = 17 if panel.size.x > 500.0 else 14
	if kind == "sfx":
		var pop: float = 1.0 if not finished else 1.0
		var pos: Vector2 = anchor
		game._draw_centered_outlined(text, pos, int(float(size) * 2.4 * pop), Color(1.0, 0.86, 0.2, alpha), Color(0.3, 0.05, 0.0, alpha), 6)
		return
	var max_w: float = minf(panel.size.x * 0.62, 460.0)
	var full_size: Vector2 = face.get_multiline_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, max_w, size)
	var pad := Vector2(12, 9)
	var box := Rect2(anchor, full_size + pad * 2.0)
	box.position.x = clampf(box.position.x, panel.position.x + 6.0, panel.end.x - box.size.x - 6.0)
	box.position.y = clampf(box.position.y, panel.position.y + 6.0, panel.end.y - box.size.y - 6.0)
	var fill := PAPER
	var ink := INK
	match kind:
		"caption":
			fill = CAPTION
		"hud":
			fill = Color(0.02, 0.12, 0.16, 0.92)
			ink = HUD
		"thought":
			fill = Color(0.92, 0.94, 1.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(fill, fill.a * alpha)
	sb.border_color = Color(INK if kind != "hud" else HUD, alpha)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14 if kind in ["speech", "thought"] else 3)
	if kind == "speech":
		# Rabo do balão apontando para baixo/esquerda.
		var tail_base: Vector2 = Vector2(box.position.x + box.size.x * 0.25, box.end.y - 1.0)
		game.draw_colored_polygon(PackedVector2Array([tail_base + Vector2(-10, 0), tail_base + Vector2(10, 0), tail_base + Vector2(-4, 18)]), Color(INK, alpha))
		game.draw_colored_polygon(PackedVector2Array([tail_base + Vector2(-7, -2), tail_base + Vector2(7, -2), tail_base + Vector2(-3, 13)]), Color(fill, alpha))
	elif kind == "thought":
		for k in range(3):
			game.draw_circle(Vector2(box.position.x + 18.0 - float(k) * 6.0, box.end.y + 6.0 + float(k) * 8.0), 5.0 - float(k), Color(fill, alpha))
	game.draw_style_box(sb, box)
	game.draw_multiline_string(face, box.position + pad + Vector2(0, float(size) * 0.85), text, HORIZONTAL_ALIGNMENT_LEFT, max_w, size, -1, Color(ink, alpha))
