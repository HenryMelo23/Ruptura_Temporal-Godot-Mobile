class_name RTBossDnaPresentation
extends RefCounted

## Desenho da Rede do Petro: maquina na oficina, tubos/cartas da tela de
## fusao, animacao da fusao, VFX das habilidades e chips de recarga no HUD.
## So desenho: nada aqui decide gameplay. A arte fica em
## res://assets/sprites/boss_dna/ (corpo da maquina, frascos e icones); o que
## faltar cai no desenho procedural.

const GLASS := Color(0.72, 0.92, 1.0)
const METAL := Color(0.32, 0.34, 0.42)
const BRASS := Color(0.85, 0.70, 0.34)
const PANEL := Color(0.06, 0.07, 0.13, 0.96)

const ART_ROOT := "res://assets/sprites/boss_dna/"
## machine/body.png (512x512): pe da maquina, altura do desenho e o vidro
## interno do tubo, medidos na arte. O liquido e a helice sao desenhados por
## codigo dentro desse retangulo, na cor do DNA.
const MACHINE_FOOT := Vector2(256.0, 492.0)
const MACHINE_ART_H := 464.0
const MACHINE_TUBE := Rect2(200.0, 146.0, 118.0, 174.0)

static var _art_cache: Dictionary = {}


static func _art(path: String) -> Texture2D:
	if _art_cache.has(path):
		return _art_cache[path]
	var full: String = ART_ROOT + path + ".png"
	var tex: Texture2D = load(full) if ResourceLoader.exists(full) else null
	_art_cache[path] = tex
	return tex


static func machine_art() -> Texture2D:
	return _art("machine/body")


## Frasco de DNA do chefe (null sem arte).
static func vial(phase: int) -> Texture2D:
	return _art("vials/dna_%d" % phase)


## Icone redondo da habilidade (null sem arte).
static func icon(id: String) -> Texture2D:
	return _art("icons/" + id)


## Textura encaixada no retangulo, mantendo a proporcao e centralizada.
static func draw_fit(g: Node2D, tex: Texture2D, rect: Rect2, modulate: Color = Color.WHITE) -> void:
	var s: Vector2 = tex.get_size()
	var k: float = minf(rect.size.x / maxf(1.0, s.x), rect.size.y / maxf(1.0, s.y))
	var size: Vector2 = s * k
	g.draw_texture_rect(tex, Rect2(rect.get_center() - size * 0.5, size), false, modulate)


# ================================================================ texto
static func text(g: Node2D, value: String, rect: Rect2, size: int, color: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, min_size: int = 9) -> void:
	var face: Font = g.menu_ui_font
	var fitted := size
	while fitted > min_size and face.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > rect.size.x:
		fitted -= 1
	var baseline := rect.position.y + (rect.size.y + face.get_ascent(fitted) - face.get_descent(fitted)) * 0.5
	g.draw_string(face, Vector2(rect.position.x, baseline), value, align, rect.size.x, fitted, color)


static func paragraph(g: Node2D, value: String, rect: Rect2, size: int, color: Color) -> void:
	var buffer := TextParagraph.new()
	buffer.width = rect.size.x
	buffer.add_string(value, g.menu_ui_font, size)
	var actual := size
	while buffer.get_size().y > rect.size.y and actual > 9:
		actual -= 1
		buffer.clear()
		buffer.add_string(value, g.menu_ui_font, actual)
	buffer.draw(g.get_canvas_item(), rect.position, color)


static func _box(g: Node2D, rect: Rect2, bg: Color, border: Color, width: float, radius: int = 10) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(int(width))
	style.set_corner_radius_all(radius)
	g.draw_style_box(style, rect)


static func draw_button(g: Node2D, rect: Rect2, label: String, accent: Color, enabled: bool) -> void:
	var a: float = 1.0 if enabled else 0.4
	_box(g, rect, Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.22, 0.95 * a), Color(accent.r, accent.g, accent.b, a), 3.0, 12)
	text(g, label, rect.grow(-10.0), 20, Color(1.0, 1.0, 1.0, a), HORIZONTAL_ALIGNMENT_CENTER)


# ================================================================ maquina
## Desenho procedural da maquina: base de metal, tubo de vidro com liquido
## da cor do DNA, helice girando e cabos. `foot` e o pe (base) na tela.
static func draw_machine_shape(g: Node2D, foot: Vector2, height: float, color: Color, t: float, fill: float, occupant_alpha: float = 0.0) -> void:
	var body: Texture2D = machine_art()
	if body != null:
		_draw_machine_art(g, body, foot, height, color, t, fill, occupant_alpha)
		return
	var w: float = height * 0.56
	var base := Rect2(foot + Vector2(-w * 0.6, -height * 0.16), Vector2(w * 1.2, height * 0.16))
	g.draw_circle(foot + Vector2(0.0, -4.0), w * 0.7, Color(0.0, 0.0, 0.0, 0.28))
	_box(g, base, METAL.darkened(0.2), BRASS, 2.0, 6)
	var tube := _procedural_tube(foot, height)
	_box(g, tube, Color(0.04, 0.06, 0.1, 0.9), Color(GLASS.r, GLASS.g, GLASS.b, 0.8), 2.0, int(w * 0.3))
	_draw_tube_contents(g, tube, color, t, fill, occupant_alpha)
	# Tampa, reflexo e cabos.
	_box(g, Rect2(tube.position + Vector2(-6.0, -12.0), Vector2(tube.size.x + 12.0, 16.0)), METAL, BRASS, 2.0, 5)
	g.draw_line(tube.position + Vector2(8.0, 14.0), Vector2(tube.position.x + 8.0, tube.end.y - 14.0), Color(1.0, 1.0, 1.0, 0.22), 3.0)
	var cable_from: Vector2 = Vector2(tube.end.x, tube.position.y + 20.0)
	g.draw_polyline(PackedVector2Array([cable_from, cable_from + Vector2(18.0, 10.0), Vector2(base.end.x, base.position.y + 8.0)]), Color(0.18, 0.2, 0.26), 4.0)
	g.draw_circle(Vector2(base.get_center().x, base.position.y + base.size.y * 0.5), 5.0, Color(color.r, color.g, color.b, 0.6 + 0.4 * sin(t * 5.0)))


static func _procedural_tube(foot: Vector2, height: float) -> Rect2:
	var w: float = height * 0.56
	return Rect2(foot + Vector2(-w * 0.38, -height * 0.9), Vector2(w * 0.76, height * 0.76))


## Vidro do tubo na tela (com arte, o retangulo medido no corpo da maquina).
static func machine_tube_rect(foot: Vector2, height: float) -> Rect2:
	if machine_art() == null:
		return _procedural_tube(foot, height)
	var k: float = height / MACHINE_ART_H
	return Rect2(foot + (MACHINE_TUBE.position - MACHINE_FOOT) * k, MACHINE_TUBE.size * k)


static func _draw_machine_art(g: Node2D, body: Texture2D, foot: Vector2, height: float, color: Color, t: float, fill: float, occupant_alpha: float) -> void:
	var k: float = height / MACHINE_ART_H
	var size: Vector2 = body.get_size() * k
	g.draw_texture_rect(body, Rect2(foot - MACHINE_FOOT * k, size), false)
	var tube := machine_tube_rect(foot, height)
	_draw_tube_contents(g, tube.grow(-1.0), color, t, fill, occupant_alpha)
	draw_glass(g, tube, t)


## Reflexo do vidro por cima do liquido (e da Geovana dentro do tubo).
static func draw_glass(g: Node2D, tube: Rect2, t: float) -> void:
	var x: float = tube.position.x + tube.size.x * 0.16
	var shine: float = 0.16 + 0.05 * sin(t * 1.7)
	g.draw_line(Vector2(x, tube.position.y + tube.size.y * 0.08), Vector2(x, tube.end.y - tube.size.y * 0.1), Color(1.0, 1.0, 1.0, shine), maxf(1.5, tube.size.x * 0.05))
	g.draw_line(Vector2(tube.end.x - tube.size.x * 0.12, tube.position.y + tube.size.y * 0.12), Vector2(tube.end.x - tube.size.x * 0.12, tube.position.y + tube.size.y * 0.34), Color(1.0, 1.0, 1.0, shine * 0.7), maxf(1.0, tube.size.x * 0.025))


## Liquido, bolhas e helice de DNA dentro do tubo.
static func _draw_tube_contents(g: Node2D, tube: Rect2, color: Color, t: float, fill: float, occupant_alpha: float) -> void:
	var dot: float = clampf(tube.size.x / 44.0, 1.2, 4.5)
	var level: float = clampf(fill, 0.0, 1.0)
	if level > 0.0:
		var liquid := Rect2(tube.position.x + 3.0, tube.end.y - tube.size.y * level, tube.size.x - 6.0, tube.size.y * level - 3.0)
		var wobble: float = 0.75 + 0.25 * sin(t * 2.4)
		_box(g, liquid, Color(color.r, color.g, color.b, 0.32 * wobble + 0.12), Color(color.r, color.g, color.b, 0.0), 0.0, int(tube.size.x * 0.2))
		g.draw_line(Vector2(liquid.position.x + 2.0, liquid.position.y + 1.0), Vector2(liquid.end.x - 2.0, liquid.position.y + 1.0), Color(color.r, color.g, color.b, 0.75), maxf(1.0, dot * 0.6))
		for b in range(5):
			var bk: float = fposmod(t * 0.45 + float(b) * 0.21, 1.0)
			var bx: float = liquid.position.x + liquid.size.x * (0.2 + 0.6 * fposmod(float(b) * 0.37, 1.0))
			g.draw_circle(Vector2(bx, liquid.end.y - liquid.size.y * bk), dot * (0.8 + 0.3 * float(b % 2)), Color(1.0, 1.0, 1.0, 0.35 * (1.0 - bk)))
	var center_x: float = tube.get_center().x
	var steps := 14
	for i in range(steps):
		var y: float = tube.position.y + tube.size.y * 0.06 + tube.size.y * 0.88 * float(i) / float(steps - 1)
		var phase: float = t * 3.0 + float(i) * 0.55
		var dx: float = sin(phase) * tube.size.x * 0.28
		var a: float = 0.85 if cos(phase) > 0.0 else 0.35
		g.draw_line(Vector2(center_x - dx, y), Vector2(center_x + dx, y), Color(color.r, color.g, color.b, 0.35 * a), maxf(1.0, dot * 0.5))
		g.draw_circle(Vector2(center_x + dx, y), dot, Color(color.r, color.g, color.b, a))
		g.draw_circle(Vector2(center_x - dx, y), dot, Color(1.0, 1.0, 1.0, a * 0.7))
	if occupant_alpha > 0.0:
		g.draw_rect(tube.grow(-3.0), Color(1.0, 1.0, 1.0, 0.25 * occupant_alpha), true)


## Cor do liquido na oficina: DNA guardado (o primeiro chefe com DNA) ou
## azul apagado quando vazia.
static func machine_color(dna: RTBossDnaController) -> Color:
	for phase in RTBossDnaCatalog.PHASES:
		if dna.dna_count(phase) > 0:
			return RTBossDnaCatalog.boss_color(phase)
	return Color(0.4, 0.62, 0.8)


static func draw_machine_world(game: Node2D, camera: Vector2) -> void:
	var dim: RTMerchantDimension = game._merchant_dimension()
	var t: float = float(game.time_alive)
	var foot: Vector2 = RTBossDnaMachine.POS - camera
	var stored: int = dim.dna.total_dna()
	var color := machine_color(dim.dna)
	if bool(game.gfx_particles):
		var r: float = 120.0 * (0.94 + 0.06 * sin(t * 2.0))
		game.draw_texture_rect(RTWorldLighting.light_texture(), Rect2(foot - Vector2(r, r * 0.72), Vector2(r * 2.0, r * 1.44)), false, Color(color.r, color.g, color.b, 0.2 if stored > 0 else 0.08))
	draw_machine_shape(game, foot, 176.0, color, t, 0.82 if stored > 0 else 0.14)
	var near: bool = Vector2(game.player_pos).distance_to(RTBossDnaMachine.POS) < 260.0
	if near and not game._dialogue().busy():
		game._draw_centered_outlined("MÁQUINA DE FUSÃO", foot + Vector2(0.0, -204.0), 16, Color(0.86, 0.96, 1.0), Color(0.02, 0.02, 0.06, 0.9), 4)
		var line: String = "DNA GUARDADO x%d" % stored if stored > 0 else "SEM DNA · DERROTE UM CHEFE"
		game._draw_centered_outlined(line, foot + Vector2(0.0, -184.0), 14, color.lightened(0.2), Color(0.02, 0.02, 0.06, 0.9), 4)


# ================================================================ tela
static func draw_dna_tube(g: Node2D, rect: Rect2, phase: int, count: int, owned: int, selected: bool, region: String, t: float, small: bool) -> void:
	var color := RTBossDnaCatalog.boss_color(phase)
	var lit: bool = count > 0
	var border := Color(color.r, color.g, color.b, 1.0 if selected else (0.7 if lit else 0.3))
	_box(g, rect, Color(color.r * 0.1, color.g * 0.1, color.b * 0.12, 0.96), border, 4.0 if selected else 2.0, 12)
	if selected:
		g.draw_rect(rect.grow(4.0), Color(color.r, color.g, color.b, 0.18 + 0.1 * sin(t * 4.0)), false, 2.0)
	var name_h: float = 16.0 if small else 20.0
	var tube_h: float = rect.size.y - name_h * 2.0 - 16.0
	var foot := Vector2(rect.get_center().x, rect.position.y + 8.0 + tube_h)
	var flask: Texture2D = vial(phase)
	if flask != null:
		var bob: float = sin(t * 2.2 + float(phase)) * 3.0 if selected and lit else 0.0
		var area := Rect2(rect.position.x + 6.0, rect.position.y + 22.0 + bob, rect.size.x - 12.0, foot.y - rect.position.y - 24.0)
		if lit:
			g.draw_circle(area.get_center(), minf(area.size.x, area.size.y) * 0.36, Color(color.r, color.g, color.b, 0.12 + (0.08 * sin(t * 3.0) if selected else 0.0)))
		draw_fit(g, flask, area, Color.WHITE if lit else Color(0.32, 0.34, 0.42, 0.85))
	else:
		draw_machine_shape(g, foot, minf(tube_h, rect.size.x * 1.5), color if lit else color.darkened(0.6), t + float(phase), 0.85 if lit else 0.1)
	var boss_name: String = String(RTBossDnaCatalog.boss(phase).get("name", ""))
	text(g, boss_name, Rect2(rect.position.x + 4.0, foot.y + 4.0, rect.size.x - 8.0, name_h), 15 if not small else 11, Color(1.0, 1.0, 1.0, 1.0 if lit else 0.55), HORIZONTAL_ALIGNMENT_CENTER, 6)
	text(g, region, Rect2(rect.position.x + 4.0, foot.y + 4.0 + name_h, rect.size.x - 8.0, name_h), 12 if not small else 9, Color(color.r, color.g, color.b, 0.95 if lit else 0.5), HORIZONTAL_ALIGNMENT_CENTER, 6)
	var badge: String = "DNA x%d" % count if lit else "SEM DNA"
	text(g, badge, Rect2(rect.position.x + 6.0, rect.position.y + 4.0, rect.size.x - 12.0, 16.0), 12 if not small else 10, Color(1.0, 0.92, 0.5) if lit else Color(0.6, 0.66, 0.78, 0.7), HORIZONTAL_ALIGNMENT_CENTER)
	# Habilidades ja fundidas deste chefe: bolinhas na lateral do tubo.
	for k in range(3):
		var pip := Vector2(rect.position.x + 10.0, rect.position.y + 30.0 + float(k) * 11.0)
		g.draw_circle(pip, 3.6, Color(color.r, color.g, color.b, 0.95) if k < owned else Color(0.3, 0.32, 0.4, 0.8))


static func draw_ability_card(g: Node2D, rect: Rect2, id: String, rank: int, selected: bool, has_dna: bool, t: float, small: bool) -> void:
	var data := RTBossDnaCatalog.ability(id)
	var phase: int = int(data.get("phase", 1))
	var color := RTBossDnaCatalog.boss_color(phase)
	var active: bool = rank > 0
	_box(g, rect, PANEL, Color(color.r, color.g, color.b, 1.0 if selected else 0.45), 4.0 if selected else 2.0, 14)
	if selected:
		g.draw_rect(rect.grow(5.0), Color(color.r, color.g, color.b, 0.16 + 0.12 * sin(t * 4.5)), false, 3.0)
	var pad: float = 10.0 if small else 16.0
	var band := Rect2(rect.position + Vector2(2.0, 2.0), Vector2(rect.size.x - 4.0, 34.0 if small else 46.0))
	_box(g, band, Color(color.r * 0.45, color.g * 0.45, color.b * 0.45, 0.95), Color(0, 0, 0, 0), 0.0, 12)
	var name_x: float = pad
	var badge: Texture2D = icon(id)
	if badge != null:
		var side: float = band.size.y + (10.0 if small else 14.0)
		var spot := Rect2(band.position + Vector2(pad * 0.5, (band.size.y - side) * 0.5), Vector2(side, side))
		draw_fit(g, badge, spot, Color.WHITE if active or has_dna else Color(0.5, 0.52, 0.6, 0.9))
		name_x = pad * 0.5 + side + 8.0
	text(g, String(data.get("name", "")).to_upper(), Rect2(band.position + Vector2(name_x, 0.0), Vector2(band.size.x - name_x - pad, band.size.y)), 22 if not small else 16, Color.WHITE)
	var y: float = band.end.y + (6.0 if small else 10.0)
	var shown_rank: int = maxi(1, rank)
	text(g, RTBossDnaCatalog.trigger_label(id, shown_rank), Rect2(rect.position.x + pad, y, rect.size.x - pad * 2.0, 18.0), 14 if not small else 11, color.lightened(0.25))
	y += 22.0 if not small else 18.0
	var footer_h: float = 22.0 if small else 30.0
	paragraph(g, String(data.get("desc", "")), Rect2(rect.position.x + pad, y, rect.size.x - pad * 2.0, rect.end.y - y - footer_h - 6.0), 16 if not small else 12, Color(0.88, 0.92, 1.0))
	var state: String = "FUNDIDA · NÍVEL %d/%d" % [rank, RTBossDnaCatalog.MAX_RANK] if active else ("DISPONÍVEL PARA FUSÃO" if has_dna else "TRANCADA · ENFRENTE O CHEFE")
	if rank >= RTBossDnaCatalog.MAX_RANK:
		state = "NÍVEL MÁXIMO"
	var footer := Rect2(rect.position.x + pad, rect.end.y - footer_h - 4.0, rect.size.x - pad * 2.0 - 46.0, footer_h)
	text(g, state, footer, 14 if not small else 11, Color(1.0, 0.92, 0.5) if active else Color(0.7, 0.76, 0.9))
	for k in range(RTBossDnaCatalog.MAX_RANK):
		var pip := Vector2(rect.end.x - pad - float(k) * 14.0, footer.get_center().y)
		g.draw_circle(pip, 5.0, Color(color.r, color.g, color.b) if k < rank else Color(0.28, 0.3, 0.38))


## Animacao: ela anda ate o tubo, entra, a helice gira e o flash funde.
static func draw_fusion_animation(g: Node2D, viewport: Vector2, phase: int, id: String, k: float, t: float) -> void:
	var color := RTBossDnaCatalog.boss_color(phase)
	var height: float = minf(viewport.y * 0.62, 420.0)
	var foot := Vector2(viewport.x * 0.5, viewport.y * 0.5 + height * 0.5)
	g.draw_circle(foot + Vector2(0.0, -height * 0.45), height * 0.7, Color(color.r, color.g, color.b, 0.08 + 0.1 * k))
	var walk: float = clampf(k / (RTBossDnaFusionScreen.ANIM_WALK / RTBossDnaFusionScreen.ANIM_TIME), 0.0, 1.0)
	var flash_k: float = RTBossDnaFusionScreen.ANIM_FLASH / RTBossDnaFusionScreen.ANIM_TIME
	var inside: bool = walk >= 1.0
	var tex: Texture2D = g._player_texture()
	var body_h: float = height * 0.42
	var body_pos := Vector2(lerpf(viewport.x * 0.16, foot.x, ease(walk, -1.6)), foot.y - height * 0.16)
	if not inside:
		_draw_body(g, tex, body_pos, body_h, Color.WHITE)
	var spin: float = t * (2.0 + 9.0 * clampf((k - 0.27) / 0.4, 0.0, 1.0))
	draw_machine_shape(g, foot, height, color, spin, 0.4 + 0.5 * k, 0.0)
	if inside and k < flash_k + 0.08:
		var pulse: float = 0.5 + 0.5 * sin(t * 18.0)
		var tube := machine_tube_rect(foot, height)
		_draw_body(g, tex, Vector2(foot.x, tube.end.y - tube.size.y * 0.03), minf(body_h * 0.92, tube.size.y * 0.9), Color(color.r, color.g, color.b, 0.55 + 0.3 * pulse))
		if machine_art() != null:
			draw_glass(g, tube, t)
	if k >= flash_k:
		var f: float = clampf((k - flash_k) / 0.08, 0.0, 1.0)
		var fade: float = 1.0 - clampf((k - flash_k - 0.1) / 0.2, 0.0, 1.0)
		g.draw_rect(Rect2(Vector2.ZERO, viewport), Color(1.0, 1.0, 1.0, 0.85 * f * fade), true)
		for ring in range(3):
			var rr: float = height * (0.3 + float(ring) * 0.25) * (0.4 + k)
			g.draw_arc(foot + Vector2(0.0, -height * 0.45), rr, 0.0, TAU, 48, Color(color.r, color.g, color.b, 0.6 * (1.0 - f * 0.5)), 4.0)
	var badge: Texture2D = icon(id)
	if badge != null and k >= flash_k:
		var pop: float = clampf((k - flash_k) / 0.12, 0.0, 1.0)
		var side: float = height * 0.34 * ease(pop, 0.4)
		var at: Vector2 = foot + Vector2(0.0, -height * 0.5)
		g.draw_circle(at, side * 0.62, Color(color.r, color.g, color.b, 0.22 * pop))
		draw_fit(g, badge, Rect2(at - Vector2(side, side) * 0.5, Vector2(side, side)), Color(1.0, 1.0, 1.0, pop))
	var title: String = "FUNDINDO DNA..." if k < flash_k else "FUSÃO COMPLETA"
	text(g, title, Rect2(0.0, viewport.y * 0.05, viewport.x, 40.0), 30, color.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER)
	text(g, String(RTBossDnaCatalog.ability(id).get("name", "")).to_upper(), Rect2(0.0, viewport.y * 0.05 + 40.0, viewport.x, 30.0), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)


static func _draw_body(g: Node2D, tex: Texture2D, foot: Vector2, height: float, tint: Color) -> void:
	if tex == null:
		g.draw_circle(foot + Vector2(0.0, -height * 0.5), height * 0.22, tint)
		return
	var s: Vector2 = tex.get_size()
	var scale: float = height / maxf(1.0, s.y)
	g.draw_set_transform(foot, 0.0, Vector2(scale, scale))
	g.draw_texture(tex, Vector2(-s.x * 0.5, -s.y), tint)
	g.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ================================================================ VFX no mundo
static func draw_world_vfx(game: Node2D, camera: Vector2) -> void:
	var dna: RTBossDnaController = game._merchant_dimension().dna
	var t: float = float(game.time_alive)
	if dna.slow_all_timer > 0.0:
		var c := _ability_color("mare_cosmica")
		var a: float = clampf(dna.slow_all_timer, 0.0, 1.0) * 0.12
		var view: Vector2 = game.get_viewport_rect().size
		for band in range(6):
			var y: float = fposmod(t * 40.0 + float(band) * view.y / 6.0, view.y)
			game.draw_rect(Rect2(0.0, y, view.x, 10.0), Color(c.r, c.g, c.b, a), true)
	for zone in dna.zones:
		var c: Color = zone["color"]
		var at: Vector2 = Vector2(zone["pos"]) - camera
		var life: float = clampf(float(zone["life"]) / 0.5, 0.0, 1.0)
		game.draw_circle(at, float(zone["radius"]), Color(c.r, c.g, c.b, 0.12 * life))
		game.draw_arc(at, float(zone["radius"]), t, t + TAU, 40, Color(c.r, c.g, c.b, 0.5 * life), 2.0)
	for wave in dna.waves:
		var c: Color = wave["color"]
		var fade: float = 1.0 - float(wave["r"]) / maxf(1.0, float(wave["max"]))
		game.draw_arc(Vector2(wave["pos"]) - camera, float(wave["r"]), 0.0, TAU, 72, Color(c.r, c.g, c.b, 0.75 * fade), 10.0)
		game.draw_arc(Vector2(wave["pos"]) - camera, maxf(1.0, float(wave["r"]) - 18.0), 0.0, TAU, 72, Color(1.0, 1.0, 1.0, 0.3 * fade), 3.0)
	for orbit in dna.orbits:
		var c: Color = orbit["color"]
		for point in dna.orbit_points(orbit):
			game.draw_circle(point - camera, 13.0, Color(c.r, c.g, c.b, 0.85))
			game.draw_circle(point - camera, 6.0, Color(1.0, 1.0, 1.0, 0.8))
	for burst in dna.bursts:
		var c: Color = burst["color"]
		var k: float = 1.0 - float(burst["life"]) / maxf(0.01, float(burst["max"]))
		var at: Vector2 = Vector2(burst["pos"]) - camera
		var r: float = float(burst["radius"]) * (0.35 + 0.65 * k)
		game.draw_arc(at, r, 0.0, TAU, 56, Color(c.r, c.g, c.b, 0.8 * (1.0 - k)), 5.0)
		if String(burst["kind"]) in ["freeze", "nova", "drain", "pull"]:
			game.draw_circle(at, r, Color(c.r, c.g, c.b, 0.14 * (1.0 - k)))
		elif String(burst["kind"]) == "dna":
			var flask: Texture2D = vial(int(burst.get("phase", 0)))
			if flask != null:
				var side: float = 84.0 * (0.6 + 0.4 * ease(minf(1.0, k * 3.0), 0.4))
				var rise: Vector2 = at + Vector2(0.0, -70.0 - 90.0 * k)
				draw_fit(game, flask, Rect2(rise - Vector2(side, side) * 0.5, Vector2(side, side)), Color(1.0, 1.0, 1.0, 1.0 - k * k))
	if dna.shield > 0.0:
		var me: Vector2 = Vector2(game.player_pos) - camera + Vector2(0.0, -40.0)
		game.draw_arc(me, 52.0, 0.0, TAU, 40, Color(0.7, 0.95, 1.0, 0.7), 3.0)
	if dna.guard_timer > 0.0:
		var me2: Vector2 = Vector2(game.player_pos) - camera + Vector2(0.0, -40.0)
		game.draw_arc(me2, 46.0, -PI * 0.9, -PI * 0.1, 18, Color(1.0, 0.88, 0.36, 0.85), 6.0)
	if not dna.rewind_fx.is_empty():
		var c2: Color = dna.rewind_fx["color"]
		var k2: float = float(dna.rewind_fx["life"]) / maxf(0.01, float(dna.rewind_fx["max"]))
		var from: Vector2 = Vector2(dna.rewind_fx["from"]) - camera
		var to: Vector2 = Vector2(dna.rewind_fx["to"]) - camera
		game.draw_line(from, to, Color(c2.r, c2.g, c2.b, 0.6 * k2), 4.0)
		for ring in range(3):
			game.draw_arc(to, 40.0 + float(ring) * 26.0 + (1.0 - k2) * 60.0, -t * 3.0, -t * 3.0 + PI * 1.4, 24, Color(c2.r, c2.g, c2.b, 0.8 * k2), 3.0)
		# Ponteiros do relogio girando para tras.
		game.draw_line(to, to + Vector2.from_angle(-t * 9.0) * 36.0, Color(1.0, 1.0, 1.0, k2), 3.0)
		game.draw_line(to, to + Vector2.from_angle(-t * 2.0) * 24.0, Color(1.0, 1.0, 1.0, k2), 4.0)


static func _ability_color(id: String) -> Color:
	return RTBossDnaCatalog.boss_color(int(RTBossDnaCatalog.ability(id).get("phase", 1)))


## Chips de recarga das habilidades fundidas (canto inferior esquerdo,
## acima dos controles de toque).
static func draw_hud(game: Node2D, viewport: Vector2) -> void:
	var dna: RTBossDnaController = game._merchant_dimension().dna
	if not dna.active_in_world():
		return
	var size: float = 30.0 if viewport.y < 560.0 else 36.0
	var x: float = 16.0
	var y: float = viewport.y * 0.5 - size * 0.5
	var row := 0
	for id in dna.owned.keys():
		var sid := String(id)
		var c := _ability_color(sid)
		var cd: float = float(dna.cooldowns.get(sid, 0.0))
		var full: float = RTBossDnaCatalog.cooldown_for(sid, dna.rank(sid))
		var center := Vector2(x + size * 0.5, y + float(row) * (size + 6.0))
		game.draw_circle(center, size * 0.5, Color(0.04, 0.05, 0.1, 0.78))
		var ready: float = 1.0 - clampf(cd / maxf(0.01, full), 0.0, 1.0)
		game.draw_arc(center, size * 0.5 - 2.0, -PI * 0.5, -PI * 0.5 + TAU * ready, 28, Color(c.r, c.g, c.b, 0.95 if cd <= 0.0 else 0.55), 3.0)
		if dna.last_fired == sid and dna.last_fired_timer > 0.0:
			game.draw_circle(center, size * 0.5 + 4.0 * dna.last_fired_timer, Color(c.r, c.g, c.b, 0.25 * dna.last_fired_timer))
		var badge: Texture2D = icon(sid)
		if badge != null:
			var side: float = size - 5.0
			draw_fit(game, badge, Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side)), Color.WHITE if cd <= 0.0 else Color(0.55, 0.57, 0.65, 0.85))
			game.draw_arc(center, size * 0.5 - 2.0, -PI * 0.5, -PI * 0.5 + TAU * ready, 28, Color(c.r, c.g, c.b, 0.95 if cd <= 0.0 else 0.75), 3.0)
		else:
			var initials: String = String(RTBossDnaCatalog.ability(sid).get("name", "?")).substr(0, 2).to_upper()
			game._draw_centered(initials, center, 12, Color(1.0, 1.0, 1.0, 1.0 if cd <= 0.0 else 0.6))
		row += 1
