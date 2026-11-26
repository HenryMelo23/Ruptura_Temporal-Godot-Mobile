extends RefCounted
## Vitrine de itens da loja: cada vaga e um pedestal com o item flutuando,
## brilho da raridade, item chamuscado (Cinzas), queima que vira cinza e a
## redoma de reserva. So desenho: nada aqui decide compra, queima ou reserva.
##
## Arte: res://assets/sprites/items/<raridade>/<slug>.png, indexada pelo
## manifest.json (campo "card" = nome da carta no catalogo). Sem arte, a vaga
## usa a textura antiga da carta.

const ITEMS_ROOT := "res://assets/sprites/items/"
const EMBER := Color(1.0, 0.42, 0.1)
const ASH := Color(0.32, 0.3, 0.28)

static var _by_name: Dictionary = {}
static var _item_names: Dictionary = {}
static var _loaded := false
static var _tex_cache: Dictionary = {}


## Chave sem acento, minuscula, so letras e numeros: "Âncora Vital" e
## "Ancora Vital" caem na mesma vaga.
static func normalize(value: String) -> String:
	var out := ""
	var plain := "aaaaaeeeeiiiiooooouuuucn"
	var accented := "áàâãäéèêëíìîïóòôõöúùûüçñ"
	for ch in value.to_lower():
		var at := accented.find(ch)
		if at >= 0:
			out += plain[at]
		elif (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			out += ch
	return out


static func _load_manifest() -> void:
	_loaded = true
	var path := ITEMS_ROOT + "manifest.json"
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return
	for key in Dictionary(parsed).keys():
		var entry: Dictionary = Dictionary(parsed[key])
		_by_name[normalize(String(entry.get("card", "")))] = String(key)
		_item_names[String(key)] = String(entry.get("item", ""))


## Sprite do item da carta (null quando ainda nao ha arte).
static func texture(card: Dictionary) -> Texture2D:
	if not _loaded:
		_load_manifest()
	var key: String = String(_by_name.get(normalize(String(card.get("name", ""))), ""))
	if key == "":
		return null
	if _tex_cache.has(key):
		return _tex_cache[key]
	var full := ITEMS_ROOT + key + ".png"
	var tex: Texture2D = load(full) if ResourceLoader.exists(full) else null
	_tex_cache[key] = tex
	return tex


## Nome do objeto (ex.: "Tênis da Última Corrida"); "" sem arte.
static func item_name(card: Dictionary) -> String:
	if not _loaded:
		_load_manifest()
	return String(_item_names.get(String(_by_name.get(normalize(String(card.get("name", ""))), "")), ""))


## Etiqueta da raridade no canto de cima a esquerda da vaga.
static func draw_rarity_pill(g, rect: Rect2, label: String, rarity: Color, alpha: float) -> void:
	var face: Font = g.menu_ui_font
	var size: int = 11
	var w: float = face.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 14.0
	var pill := Rect2(rect.position + Vector2(8.0, 10.0), Vector2(w, 18.0))
	g.draw_style_box(_style(Color(rarity.r * 0.18, rarity.g * 0.18, rarity.b * 0.18, 0.92 * alpha), Color(rarity, 0.9 * alpha), 9, 1), pill)
	g.draw_string(face, Vector2(pill.position.x + 7.0, pill.get_center().y + 4.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(rarity.lightened(0.25), alpha))


## Selo "CINZAS xN" no canto da vaga do item chamuscado.
static func draw_charred_tag(g, rect: Rect2, stacks: int, now: float) -> void:
	var label := ("CINZAS x%d" if rect.size.x >= 150.0 else "x%d") % stacks
	var face: Font = g.menu_ui_font
	var size: int = 11
	var w: float = face.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 14.0
	var tag := Rect2(Vector2(rect.end.x - w - 8.0, rect.position.y + 10.0), Vector2(w, 18.0))
	var heat: float = 0.75 + 0.25 * sin(now * 6.0)
	g.draw_rect(tag, Color(0.22, 0.06, 0.02, 0.92), true)
	g.draw_rect(tag, Color(EMBER, heat), false, 1.0)
	g.draw_string(face, Vector2(tag.position.x + 7.0, tag.get_center().y + 4.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1.0, 0.8, 0.5))


static func rarity_tier(g, card: Dictionary) -> int:
	match String(g._card_rarity_key(card)):
		"uncommon":
			return 1
		"rare":
			return 2
		"legendary":
			return 3
	return 0


static func _style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	return s


## Area do item (parte de cima da vaga) e o pe do pedestal.
static func display_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position + Vector2(8.0, 8.0), Vector2(rect.size.x - 16.0, rect.size.y * 0.62 - 8.0))


static func pedestal_center(rect: Rect2) -> Vector2:
	var area := display_rect(rect)
	return Vector2(area.get_center().x, area.end.y - area.size.y * 0.1)


## Fundo da vaga: vidro escuro com borda na cor da raridade.
static func draw_slot_back(g, rect: Rect2, rarity: Color, selected: bool, alpha: float, workshop: bool, now: float) -> void:
	var fill := Color(0.03, 0.05, 0.065, 0.9 * alpha) if not workshop else Color(0.07, 0.045, 0.05, 0.92 * alpha)
	var border := Color(rarity.r, rarity.g, rarity.b, (0.95 if selected else 0.42) * alpha)
	g.draw_style_box(_style(fill, border, 12, 3 if selected else 2), rect)
	if selected:
		var pulse: float = 0.5 + 0.5 * sin(now * 4.0)
		g.draw_style_box(_style(Color(0, 0, 0, 0), Color(rarity.r, rarity.g, rarity.b, (0.18 + 0.14 * pulse) * alpha), 16, 2), rect.grow(4.0 + pulse * 2.0))
	# Faixa de cor da raridade no topo.
	g.draw_rect(Rect2(rect.position + Vector2(14.0, 2.0), Vector2(rect.size.x - 28.0, 3.0)), Color(rarity.r, rarity.g, rarity.b, 0.75 * alpha), true)


## Pedestal: disco holografico no bracelete, base de latao na oficina.
static func draw_pedestal(g, rect: Rect2, rarity: Color, tone: Color, alpha: float, workshop: bool, now: float, selected: bool) -> void:
	var base := pedestal_center(rect)
	var w: float = display_rect(rect).size.x * 0.62
	var h: float = w * 0.24
	# Cone de luz da raridade subindo do pedestal.
	var top_y: float = display_rect(rect).position.y + 6.0
	var cone_a: float = (0.16 if selected else 0.09) * alpha
	g.draw_polygon(PackedVector2Array([base + Vector2(-w * 0.46, 0), base + Vector2(w * 0.46, 0), Vector2(base.x + w * 0.2, top_y), Vector2(base.x - w * 0.2, top_y)]),
		PackedColorArray([Color(rarity, cone_a), Color(rarity, cone_a), Color(rarity, 0.0), Color(rarity, 0.0)]))
	if workshop:
		var plinth := Rect2(base + Vector2(-w * 0.42, 0.0), Vector2(w * 0.84, h * 0.9))
		g.draw_rect(plinth, Color(0.2, 0.12, 0.09, alpha), true)
		g.draw_rect(plinth, Color(0.85, 0.7, 0.34, 0.85 * alpha), false, 1.5)
	_draw_ellipse(g, base, Vector2(w * 0.5, h * 0.5), Color(0.02, 0.06, 0.07, 0.95 * alpha) if not workshop else Color(0.26, 0.17, 0.1, alpha))
	_draw_ellipse_outline(g, base, Vector2(w * 0.5, h * 0.5), Color(tone, 0.85 * alpha), 2.0)
	var spin: float = now * (1.6 if selected else 0.8)
	for k in range(3):
		var a: float = spin + TAU * float(k) / 3.0
		var p: Vector2 = base + Vector2(cos(a) * w * 0.44, sin(a) * h * 0.44)
		g.draw_circle(p, 2.0, Color(rarity, 0.9 * alpha))


## Item flutuando com o brilho da raridade. `charred` = cargas de Cinzas.
static func draw_item(g, tex: Texture2D, rect: Rect2, tier: int, rarity: Color, alpha: float, now: float, phase: float, selected: bool, frozen: bool, charred: int) -> Rect2:
	var area := display_rect(rect)
	var side: float = minf(area.size.x, area.size.y) * (0.86 if selected else 0.8)
	var bob: float = 0.0 if frozen else sin(now * 2.2 + phase) * side * 0.035
	var center := Vector2(area.get_center().x, area.position.y + area.size.y * 0.46 + bob)
	var item := Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side))
	# Sombra no pedestal acompanha a flutuacao.
	var base := pedestal_center(rect)
	_draw_ellipse(g, base + Vector2(0, -1), Vector2(side * (0.3 - bob / side), side * 0.06), Color(0, 0, 0, 0.45 * alpha))
	_draw_rarity_aura(g, center, side, tier, rarity, alpha, now, phase, frozen)
	if charred > 0:
		_draw_ember_rim(g, tex, item, charred, alpha, now)
	var tint := Color(1, 1, 1, alpha)
	if charred > 0:
		tint = Color(0.92, 0.8, 0.72, alpha)
	if frozen:
		tint = Color(0.78, 0.92, 1.0, alpha)
	if tier >= 3 and not frozen:
		# Eco lendario: copia atrasada e translucida.
		var echo: float = 0.5 + 0.5 * sin(now * 1.7 + phase)
		g.draw_texture_rect(tex, Rect2(item.position + Vector2(4.0 + echo * 3.0, -3.0), item.size), false, Color(1.0, 0.45, 0.15, 0.22 * alpha))
	g.draw_texture_rect(tex, item, false, tint)
	if tier >= 1 and not frozen:
		_draw_sparkles(g, item, tier, rarity, alpha, now, phase)
	return item


static func _draw_rarity_aura(g, center: Vector2, side: float, tier: int, rarity: Color, alpha: float, now: float, phase: float, frozen: bool) -> void:
	var glow: Texture2D = RTWorldLighting.light_texture()
	var r: float = side * (0.62 + 0.08 * float(tier))
	var pulse: float = 0.85 + 0.15 * sin(now * 3.0 + phase)
	g.draw_texture_rect(glow, Rect2(center - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(rarity, (0.22 + 0.07 * float(tier)) * pulse * alpha))
	if tier >= 2 and not frozen:
		# Raios girando atras do item (raro e lendario).
		var rays: int = 6 if tier == 2 else 8
		var spin: float = now * 0.5 + phase
		for k in range(rays):
			var a: float = spin + TAU * float(k) / float(rays)
			var tip: Vector2 = center + Vector2.from_angle(a) * r * 1.05
			var side_a: Vector2 = Vector2.from_angle(a + PI * 0.5) * side * 0.05
			g.draw_polygon(PackedVector2Array([center + side_a, center - side_a, tip]), PackedColorArray([Color(rarity, 0.18 * alpha), Color(rarity, 0.18 * alpha), Color(rarity, 0.0)]))


static func _draw_sparkles(g, item: Rect2, tier: int, rarity: Color, alpha: float, now: float, phase: float) -> void:
	var count: int = 3 + tier * 2
	for k in range(count):
		var life: float = fposmod(now * (0.35 + 0.04 * float(k)) + float(k) * 0.37 + phase, 1.0)
		var x: float = item.position.x + item.size.x * fposmod(float(k) * 0.29 + 0.12, 0.8) + item.size.x * 0.1
		var y: float = item.end.y - life * item.size.y * 1.05
		var s: float = 1.5 + float(k % 2)
		var c: Color = rarity.lightened(0.35) if tier < 3 or k % 2 == 0 else EMBER
		g.draw_rect(Rect2(Vector2(x, y), Vector2(s, s)), Color(c, sin(life * PI) * alpha), true)
	if tier >= 3:
		# Brasas lendarias orbitando.
		for k in range(4):
			var a: float = now * 1.4 + TAU * float(k) / 4.0 + phase
			var p: Vector2 = item.get_center() + Vector2(cos(a) * item.size.x * 0.48, sin(a) * item.size.y * 0.16)
			g.draw_circle(p, 2.2, Color(EMBER, 0.85 * alpha))


## Borda em brasa do item chamuscado (Cinzas): mais cargas, mais calor.
static func _draw_ember_rim(g, tex: Texture2D, item: Rect2, stacks: int, alpha: float, now: float) -> void:
	var heat: float = clampf(float(stacks) / 6.0, 0.2, 1.0)
	var flick: float = 0.7 + 0.3 * sin(now * 9.0)
	var rim := Color(EMBER, (0.35 + 0.35 * heat) * flick * alpha)
	for off in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		g.draw_texture_rect(tex, Rect2(item.position + off, item.size), false, rim)


## Chamas baixas no pedestal e brasas subindo, para o item chamuscado.
static func draw_charred_base(g, rect: Rect2, stacks: int, alpha: float, now: float) -> void:
	var base := pedestal_center(rect)
	var w: float = display_rect(rect).size.x * 0.62
	var heat: float = clampf(float(stacks) / 6.0, 0.25, 1.0)
	var n: int = 5 + mini(stacks, 6) * 2
	for k in range(n):
		var u: float = (float(k) + 0.5) / float(n)
		var x: float = base.x - w * 0.44 + u * w * 0.88
		var phase: float = float(k) * 2.1
		var hgt: float = (6.0 + 14.0 * heat) * (0.6 + 0.4 * sin(now * 10.0 + phase))
		var foot := Vector2(x, base.y + sin(u * PI) * 3.0)
		var wob: float = sin(now * 6.0 + phase) * 2.5
		g.draw_colored_polygon(PackedVector2Array([foot + Vector2(-5, 0), foot + Vector2(wob, -hgt), foot + Vector2(5, 0)]), Color(1.0, 0.32, 0.06, 0.75 * alpha))
		g.draw_colored_polygon(PackedVector2Array([foot + Vector2(-2.5, 0), foot + Vector2(wob * 0.6, -hgt * 0.6), foot + Vector2(2.5, 0)]), Color(1.0, 0.86, 0.32, 0.9 * alpha))
	for k in range(4 + mini(stacks, 6)):
		var life: float = fposmod(now * (0.45 + 0.05 * float(k)) + float(k) * 0.31, 1.0)
		var x2: float = base.x - w * 0.4 + w * 0.8 * fposmod(float(k) * 0.37, 1.0) + sin(now * 2.0 + float(k)) * 5.0
		g.draw_rect(Rect2(Vector2(x2, base.y - life * display_rect(rect).size.y * 0.9), Vector2(2, 2)), Color(1.0, 0.6, 0.2, (1.0 - life) * alpha), true)


## Queima: o item pega fogo de baixo para cima, vira cinza e cai no pedestal.
static func draw_burning(g, tex: Texture2D, rect: Rect2, progress: float, now: float) -> void:
	var area := display_rect(rect)
	var side: float = minf(area.size.x, area.size.y) * 0.8
	var shake: float = sin(now * 60.0) * 2.0 * (1.0 - smoothstep(0.6, 0.9, progress))
	var center := Vector2(area.get_center().x + shake, area.position.y + area.size.y * 0.46)
	var item := Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side))
	var ignite: float = smoothstep(0.0, 0.22, progress)
	var consume: float = smoothstep(0.3, 1.0, progress)
	var glow: Texture2D = RTWorldLighting.light_texture()
	var r: float = side * (0.7 + 0.3 * ignite)
	g.draw_texture_rect(glow, Rect2(center - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(EMBER, 0.45 * sin(progress * PI)))
	# Parte que ainda nao queimou (de cima ate a frente de fogo).
	var tsize: Vector2 = tex.get_size()
	var keep: float = 1.0 - consume
	if keep > 0.08:
		var fade: float = smoothstep(0.08, 0.2, keep)
		var dst := Rect2(item.position, Vector2(item.size.x, item.size.y * keep))
		var src := Rect2(Vector2.ZERO, Vector2(tsize.x, tsize.y * keep))
		_draw_ember_rim_region(g, tex, dst, src, ignite)
		var char_k: float = clampf(ignite * 0.4 + consume * 0.9, 0.0, 1.0)
		g.draw_texture_rect_region(tex, dst, src, Color(1.0, 1.0, 1.0).lerp(Color(0.28, 0.16, 0.1), char_k))
		# Carvao perto da frente e linha incandescente.
		var front_y: float = dst.end.y
		var char_h: float = minf(dst.size.y, side * 0.12)
		g.draw_rect(Rect2(Vector2(item.position.x + side * 0.12, front_y - char_h), Vector2(side * 0.76, char_h)), Color(0.1, 0.03, 0.0, 0.5 * ignite), true)
		var strips := 12
		for i in range(strips):
			var u: float = (float(i) + 0.5) / float(strips)
			var x: float = item.position.x + side * (0.12 + 0.76 * u)
			var hgt: float = side * (0.05 + 0.06 * (0.5 + 0.5 * sin(now * 13.0 + float(i) * 1.7))) * (0.4 + ignite)
			var wob: float = sin(now * 9.0 + float(i)) * 2.5
			var foot := Vector2(x, front_y)
			var half: float = side * 0.035
			g.draw_colored_polygon(PackedVector2Array([foot + Vector2(-half * 1.6, 0), foot + Vector2(wob, -hgt), foot + Vector2(half * 1.6, 0)]), Color(1.0, 0.34, 0.05, 0.85 * fade))
			g.draw_colored_polygon(PackedVector2Array([foot + Vector2(-half, 0), foot + Vector2(wob * 0.6, -hgt * 0.55), foot + Vector2(half, 0)]), Color(1.0, 0.9, 0.4, 0.95 * fade))
		g.draw_rect(Rect2(Vector2(item.position.x + side * 0.12, front_y - 2.0), Vector2(side * 0.76, 3.0)), Color(1.0, 0.75, 0.25, ignite * fade), true)
	# Cinzas e brasas subindo; no fim, um montinho de cinza no pedestal.
	for k in range(18):
		var life: float = fposmod(progress * 1.7 + float(k) * 0.137, 1.0)
		var x2: float = item.position.x + item.size.x * fposmod(float(k) * 0.271 + 0.08, 0.84) + sin(float(k) * 3.0 + progress * 9.0) * 8.0
		var y2: float = item.position.y + item.size.y * keep - life * side * 0.6
		var c: Color = Color(ASH, (1.0 - life) * 0.9) if k % 3 == 0 else Color(1.0, 0.5 + 0.3 * (1.0 - life), 0.15, 1.0 - life)
		g.draw_rect(Rect2(Vector2(x2, y2), Vector2(3, 3)), Color(c, c.a * consume), true)
	var pile: float = smoothstep(0.55, 1.0, progress)
	if pile > 0.0:
		var base := pedestal_center(rect)
		_draw_ellipse(g, base + Vector2(0, -3.0 * pile), Vector2(side * 0.26 * pile, side * 0.07 * pile), Color(0.16, 0.15, 0.14, 0.95))
		for k in range(5):
			var ex: float = base.x + (float(k) - 2.0) * side * 0.08
			g.draw_rect(Rect2(Vector2(ex, base.y - 4.0 * pile - float(k % 2) * 2.0), Vector2(2, 2)), Color(EMBER, pile * (0.5 + 0.5 * sin(now * 7.0 + float(k)))), true)


static func _draw_ember_rim_region(g, tex: Texture2D, dst: Rect2, src: Rect2, heat: float) -> void:
	if heat <= 0.0:
		return
	for off in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2)]:
		g.draw_texture_rect_region(tex, Rect2(dst.position + off, dst.size), src, Color(EMBER, 0.6 * heat))


## Reserva: uma redoma de vidro desce sobre o pedestal e o cadeado trava.
## `k` 0..1 (com animacao de soltar quando `releasing`).
static func draw_reserve_dome(g, rect: Rect2, t: float, releasing: bool, tone: Color, now: float, label: String) -> void:
	var k: float = smoothstep(0.0, 1.0, t)
	if releasing:
		k = 1.0 - k
	if k <= 0.01:
		return
	var area := display_rect(rect)
	var base := pedestal_center(rect)
	var w: float = area.size.x * 0.74
	var h: float = area.size.y * 0.92
	var land: float = smoothstep(0.0, 0.55, k)
	var bounce: float = sin(clampf((k - 0.5) / 0.25, 0.0, 1.0) * PI) * 6.0
	var lift: float = (1.0 - land) * area.size.y * 0.9 + bounce
	var foot := base + Vector2(0, -lift)
	var dome := _dome_points(foot, w, h)
	g.draw_colored_polygon(dome, Color(tone.r, tone.g, tone.b, 0.1 * land))
	var outline := dome.duplicate()
	outline.append(dome[0])
	g.draw_polyline(outline, Color(tone, 0.85 * land), 2.0, true)
	# Reflexo do vidro.
	g.draw_line(foot + Vector2(-w * 0.32, -h * 0.18), foot + Vector2(-w * 0.32, -h * 0.62), Color(1, 1, 1, 0.3 * land), 3.0)
	g.draw_arc(foot + Vector2(0, -h + w * 0.5), w * 0.38, PI * 1.15, PI * 1.45, 8, Color(1, 1, 1, 0.3 * land), 2.0)
	# Puxador no topo e aro na base.
	g.draw_circle(foot + Vector2(0, -h - 4.0), 4.0, Color(tone, land))
	_draw_ellipse_outline(g, foot, Vector2(w * 0.52, w * 0.12), Color(tone, land), 3.0)
	# Cadeado cai na frente do aro e trava com um anel.
	var drop: float = smoothstep(0.5, 0.85, k)
	if drop > 0.0:
		var lock_at := Vector2(base.x, lerpf(base.y - area.size.y * 0.5, base.y + 6.0, drop))
		g.draw_circle(lock_at, 13.0, Color(0.02, 0.1, 0.12, 0.95 * drop))
		g.draw_arc(lock_at, 13.0, 0.0, TAU, 20, Color(tone, drop), 2.0, true)
		_draw_padlock(g, lock_at + Vector2(0, 1), 0.95, Color(tone.lightened(0.4), drop), k > 0.8)
		if k > 0.8 and not releasing and t < 1.0:
			var ring: float = clampf((k - 0.8) / 0.2, 0.0, 1.0)
			g.draw_arc(lock_at, 13.0 + ring * 26.0, 0.0, TAU, 24, Color(tone, 0.7 * (1.0 - ring)), 2.0, true)
	if k > 0.85 and label != "" and rect.size.x >= 150.0:
		var a: float = clampf((k - 0.85) / 0.15, 0.0, 1.0)
		var tag := Rect2(Vector2(rect.position.x + 10.0, area.position.y + 32.0), Vector2(rect.size.x - 20.0, 20.0))
		g.draw_rect(tag, Color(0.02, 0.1, 0.12, 0.9 * a), true)
		g.draw_rect(tag, Color(tone, 0.8 * a), false, 1.0)
		var face: Font = g.menu_ui_font
		var size: int = 12
		var tw: float = face.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		g.draw_string(face, Vector2(tag.get_center().x - tw * 0.5, tag.get_center().y + 4.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(tone.lightened(0.3), a))


static func _dome_points(foot: Vector2, w: float, h: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var r: float = w * 0.5
	pts.append(foot + Vector2(-r, 0))
	pts.append(foot + Vector2(-r, -h + r))
	for i in range(1, 12):
		var a: float = PI + PI * float(i) / 12.0
		pts.append(foot + Vector2(0, -h + r) + Vector2(cos(a), sin(a)) * r)
	pts.append(foot + Vector2(r, -h + r))
	pts.append(foot + Vector2(r, 0))
	return pts


static func _draw_padlock(g, center: Vector2, scale: float, color: Color, closed: bool) -> void:
	var w: float = 14.0 * scale
	var h: float = 11.0 * scale
	g.draw_rect(Rect2(center + Vector2(-w * 0.5, -h * 0.2), Vector2(w, h)), color, true)
	var open_off: float = 0.0 if closed else -4.0 * scale
	g.draw_arc(Vector2(center.x, center.y - h * 0.2 + open_off), w * 0.34, PI, TAU, 12, color, 2.4 * scale, true)
	g.draw_circle(center + Vector2(0, h * 0.3), 1.6 * scale, Color(0, 0, 0, 0.7))


static func _draw_ellipse(g, center: Vector2, radii: Vector2, color: Color) -> void:
	if radii.x <= 0.5 or radii.y <= 0.5:
		return
	var pts := PackedVector2Array()
	for i in range(20):
		var a: float = TAU * float(i) / 20.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	g.draw_colored_polygon(pts, color)


static func _draw_ellipse_outline(g, center: Vector2, radii: Vector2, color: Color, width: float) -> void:
	var pts := PackedVector2Array()
	for i in range(21):
		var a: float = TAU * float(i) / 20.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	g.draw_polyline(pts, color, width, true)
