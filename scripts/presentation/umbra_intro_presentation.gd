class_name RTUmbraIntroPresentation
extends RefCounted

## Desenho da cena de chegada da UMBRA (RTUmbraIntro): atores e efeitos no mundo,
## baloes de fala, faixas de cinema, tempo arrastado e o desvio dos meteoros.
##
## Arte do Codex (opcional; sem ela ha versoes provisorias):
##   res://assets/sprites/umbra_intro/geo231_<anim>_NN.png   (olhando para a DIREITA)
##       run 6, fall 4, kneel 2, shout 2, hit 3, erase 6
##   res://assets/sprites/umbra_intro/geovana_<pose>_NN.png  (olhando para a DIREITA)
##       susto 2, firme 3, esquiva 4
##   res://assets/sprites/umbra_intro/meteoro_NN.png 4, impacto_NN.png 6
##   res://assets/sprites/umbra_v3/risada_NN.png 4, invocar_NN.png 4

const DIR := "res://assets/sprites/umbra_intro/"
const GEO_FPS := {"run": 12.0, "fall": 8.0, "kneel": 3.0, "shout": 6.0, "hit": 10.0, "erase": 5.0}
const GEO_LOOP := {"run": true, "kneel": true, "shout": true}
const POSE_FPS := {"susto": 6.0, "firme": 4.0, "esquiva": 18.0}
const UMBRA_FALLBACK := {"risada": "idle", "invocar": "conjurar"}
const UMBRA_LOOP := {"idle": true, "sifao": true, "risada": true}
const UMBRA_FPS := {"idle": 6.0, "transmutar": 6.0, "conjurar": 8.0, "ataque": 12.0, "sifao": 6.0, "risada": 8.0, "invocar": 6.0}
## Versao provisoria (texturas da Geovana jogavel): mesma caixa do jogador.
const GEO_SIZE := Vector2(54, 80)
## Arte da cena (tools/umbra_intro_slice.py): canvas 220x210, uma escala por
## personagem, pose de pe com 174 px e pes a 3 px da borda. Desenhada nesta
## escala, a pose de pe tem os mesmos 80 px da Geovana jogavel e os pes em +40.
const CHAR_SCALE := 80.0 / 174.0
const CHAR_FEET_PAD := 3.0
const PLAYER_FEET := 40.0

static var _cache: Dictionary = {}


static func _frames(prefix: String) -> Array:
	if _cache.has(prefix):
		return _cache[prefix]
	var out: Array = []
	for i in range(1, 13):
		var path := "%s_%02d.png" % [prefix, i]
		if not ResourceLoader.exists(path):
			break
		out.append(load(path))
	_cache[prefix] = out
	return out


static func _pick(frames: Array, t: float, fps: float, loop: bool) -> Texture2D:
	if frames.is_empty():
		return null
	var i := int(floor(t * fps))
	i = posmod(i, frames.size()) if loop else clampi(i, 0, frames.size() - 1)
	return frames[i]


static func hides_player(game: Node) -> bool:
	if game.mode != RTUmbraIntro.MODE:
		return false
	var intro: RTUmbraIntro = game._umbra_intro()
	return intro.hero_pose != "" and not _frames(DIR + "geovana_" + intro.hero_pose).is_empty()


# ================================================================ mundo
static func draw_world(game: Node, camera: Vector2) -> void:
	var intro: RTUmbraIntro = game._umbra_intro()
	if not intro.active:
		return
	var now: float = intro.clock
	# Portal (rasgo da Ruptura).
	if intro.portal_open > 0.01:
		_draw_portal(game, intro.portal_pos - camera, intro.portal_open, now)
	# Aneis de choque.
	for r in intro.rings:
		var k: float = float(r["t"]) / float(r["life"])
		var col: Color = r["color"]
		game.draw_arc(Vector2(r["pos"]) - camera, float(r["max"]) * (0.2 + 0.8 * k), 0.0, TAU, 64, Color(col, 0.8 * (1.0 - k)), 6.0 * (1.0 - k) + 1.0)
	# Meteoros: sombra no chao primeiro.
	for i in range(intro.meteors.size()):
		var m: Dictionary = intro.meteors[i]
		if i > intro.qte_index and not (i == 0 and intro.beat < intro.beats.size() and String(intro.beats[intro.beat].get("k", "")) == "summon"):
			continue
		_draw_meteor_shadow(game, m, camera)
	_draw_geo231(game, intro, camera)
	_draw_hero_pose(game, intro, camera)
	_draw_umbra(game, intro, camera)
	# Rajada.
	if not intro.beam.is_empty():
		var a: Vector2 = Vector2(intro.beam["from"]) - camera
		var b: Vector2 = Vector2(intro.beam["to"]) - camera
		var w: float = 1.0 - clampf(float(intro.beam["t"]) / 0.55, 0.0, 1.0)
		game.draw_line(a, b, Color(0.45, 1.0, 0.6, 0.35 * w), 46.0 * w + 6.0)
		game.draw_line(a, b, Color(0.8, 0.6, 1.0, 0.8 * w), 18.0 * w + 3.0)
		game.draw_line(a, b, Color(1, 1, 1, 0.95 * w), 6.0 * w + 1.0)
		game.draw_circle(b, 40.0 * w + 10.0, Color(0.9, 1.0, 0.95, 0.6 * w))
	# Energia de GEO231 voando ate a UMBRA.
	if not intro.wisp.is_empty():
		var k2: float = float(intro.wisp["t"])
		var from: Vector2 = intro.wisp["from"]
		var to: Vector2 = intro.wisp["to"]
		var ctrl: Vector2 = from.lerp(to, 0.5) + Vector2(0, -170)
		for j in range(8):
			var kk: float = clampf(k2 - float(j) * 0.025, 0.0, 1.0)
			var p: Vector2 = from.lerp(ctrl, kk).lerp(ctrl.lerp(to, kk), kk) - camera
			game.draw_circle(p, 13.0 - float(j) * 1.3, Color(0.55, 1.0, 0.95, 0.75 - float(j) * 0.08))
		var head: Vector2 = from.lerp(ctrl, k2).lerp(ctrl.lerp(to, k2), k2) - camera
		game.draw_circle(head, 7.0, Color(1, 1, 1, 0.95))
	# Faiscas.
	for s in intro.sparks:
		var a2: float = 1.0 - float(s["t"]) / float(s["life"])
		game.draw_circle(Vector2(s["pos"]) - camera, 3.0 * a2 + 1.0, Color(s["color"], a2))
	# Meteoros no ar e explosoes por cima de tudo.
	for i in range(intro.meteors.size()):
		var m2: Dictionary = intro.meteors[i]
		if i > intro.qte_index and not (i == 0 and intro.beat < intro.beats.size() and String(intro.beats[intro.beat].get("k", "")) == "summon"):
			continue
		_draw_meteor(game, m2, camera, now)


static func _draw_portal(game: Node, c: Vector2, open: float, now: float) -> void:
	var tears := _frames_rift()
	if not tears.is_empty():
		var idx: int = clampi(int(open * float(tears.size() - 1)), 0, tears.size() - 1)
		game._draw_entity_fit(tears[idx], c, Vector2(150, 230) * (0.6 + 0.4 * open), Color(1, 1, 1, open))
		return
	var h: float = 110.0 * open
	var pts := PackedVector2Array()
	for i in range(13):
		var a := float(i) / 12.0 * TAU
		pts.append(c + Vector2(cos(a) * 34.0 * open + sin(now * 9.0 + float(i)) * 4.0, sin(a) * h))
	game.draw_colored_polygon(pts, Color(0.12, 0.0, 0.2, 0.9))
	game.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.8, 0.5, 1.0, 0.9), 3.0)


static func _frames_rift() -> Array:
	if _cache.has("__rift"):
		return _cache["__rift"]
	var out: Array = []
	for i in range(11):
		var path := "res://assets/sprites/rift_fx/tear_%d.png" % i
		if ResourceLoader.exists(path):
			out.append(load(path))
	_cache["__rift"] = out
	return out


static func _draw_geo231(game: Node, intro: RTUmbraIntro, camera: Vector2) -> void:
	var anim: String = String(intro.geo["anim"])
	if anim == "hidden":
		return
	var pos: Vector2 = Vector2(intro.geo["pos"]) - camera
	var t: float = float(intro.geo["t"])
	var frames: Array = _frames(DIR + "geo231_" + anim)
	var tex: Texture2D = _pick(frames, t, float(GEO_FPS.get(anim, 8.0)), bool(GEO_LOOP.get(anim, false)))
	var flip := true  # arte olha para a direita; GEO231 olha para a nossa Geovana (esquerda)
	var tint := Color(1, 1, 1, 1)
	var offset := Vector2.ZERO
	if tex == null:
		# Provisorio: a propria Geovana, mais palida e machucada.
		flip = false
		tint = Color(0.78, 0.84, 1.0)
		if anim == "run":
			tex = game._texture_frame("player_left", int(t * 10.0))
		else:
			tex = game._texture_frame("player_idle", 0)
			flip = true
		if anim in ["fall", "kneel", "shout"]:
			offset = Vector2(0, 14)
		if anim == "hit":
			tint = Color(1.6, 1.6, 1.8)
			offset = Vector2(sin(t * 60.0) * 4.0, 10)
	if anim == "erase":
		var e: float = float(intro.geo["erase"])
		tint.a = 1.0 - e
		offset += Vector2(sin(t * 47.0) * 6.0 * e, 0)
		# Faixas de "apagamento" atravessando o corpo.
		for k in range(5):
			var y: float = -float(k) * 16.0 - fmod(t * 90.0, 16.0)
			game.draw_line(pos + Vector2(-26, y), pos + Vector2(26, y), Color(0.5, 1.0, 1.0, 0.55 * (1.0 - e)), 2.0)
	if tex != null:
		if frames.is_empty():
			game._draw_entity_fit_flipped(tex, pos + offset, GEO_SIZE, flip, tint, true)
		else:
			_draw_char(game, tex, pos + offset, flip, tint)
	# Ferimentos provisorios: brilho violeta nas rachaduras.
	if frames.is_empty() and anim != "erase":
		game.draw_circle(pos + Vector2(6, -10), 3.0, Color(0.8, 0.2, 1.0, 0.8))
		game.draw_line(pos + Vector2(-8, -30), pos + Vector2(2, -18), Color(0.8, 0.3, 1.0, 0.7), 2.0)


static func _draw_hero_pose(game: Node, intro: RTUmbraIntro, camera: Vector2) -> void:
	if not hides_player(game):
		return
	var frames: Array = _frames(DIR + "geovana_" + intro.hero_pose)
	var loop: bool = intro.hero_pose != "esquiva"
	var tex: Texture2D = _pick(frames, intro.hero_pose_t, float(POSE_FPS.get(intro.hero_pose, 6.0)), loop)
	var flip: bool = Vector2(game.last_facing).x < -0.05
	_draw_char(game, tex, game.player_pos - camera, flip, Color.WHITE)


## Quadro da cena na escala da Geovana jogavel (pes em center + 40).
static func _draw_char(game: Node, tex: Texture2D, center: Vector2, flip: bool, tint: Color) -> void:
	if tex == null:
		return
	var size: Vector2 = tex.get_size() * CHAR_SCALE
	var top_left := Vector2(-size.x * 0.5, PLAYER_FEET + CHAR_FEET_PAD * CHAR_SCALE - size.y)
	game.draw_set_transform(center, 0.0, Vector2(-1.0, 1.0) if flip else Vector2.ONE)
	game.draw_texture_rect(tex, Rect2(top_left, size), false, tint)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_umbra(game: Node, intro: RTUmbraIntro, camera: Vector2) -> void:
	var anim: String = String(intro.umbra["anim"])
	if anim == "hidden":
		return
	var alpha: float = float(intro.umbra["alpha"]) if anim == "transmutar" else 1.0
	var frames: Array = RTUmbraBossAnimation.frames(anim)
	if frames.is_empty() and UMBRA_FALLBACK.has(anim):
		frames = RTUmbraBossAnimation.frames(String(UMBRA_FALLBACK[anim]))
	var tex: Texture2D = _pick(frames, float(intro.umbra["t"]), float(UMBRA_FPS.get(anim, 8.0)), bool(UMBRA_LOOP.get(anim, false)))
	var size: Vector2 = RTUmbraBossAnimation.DRAW_SIZE
	if tex == null:
		var legacy: Array = game.textures.get("boss5", [])
		tex = legacy[int(intro.clock * 6.0) % legacy.size()] if not legacy.is_empty() else null
		size = Vector2(90, 130)
	var bob := Vector2(sin(intro.clock * 1.4) * 3.0, sin(intro.clock * 2.2) * 6.0 + RTUmbraBossAnimation.HOVER)
	var pos: Vector2 = Vector2(intro.umbra["pos"]) - camera + bob
	if anim == "sifao" or anim == "invocar":
		game.draw_circle(pos + Vector2(0, -60), 70.0 + sin(intro.clock * 8.0) * 6.0, Color(0.36, 1.0, 0.56, 0.12))
	if tex != null:
		game._draw_entity_fit_flipped(tex, pos, size, float(intro.umbra["facing"]) < 0.0, Color(1, 1, 1, alpha), true)
	if anim == "invocar" and RTUmbraBossAnimation.frames("invocar").is_empty():
		var up: Vector2 = pos + Vector2(46.0 * float(intro.umbra["facing"]), -150)
		game.draw_circle(up, 20.0 + sin(intro.clock * 12.0) * 4.0, Color(1.0, 0.6, 0.2, 0.7))


static func _meteor_pos(m: Dictionary, camera: Vector2) -> Vector2:
	var h: float = float(m["h"])
	return Vector2(m["target"]) - camera + Vector2(-120.0, -270.0) * h


static func _draw_meteor_shadow(game: Node, m: Dictionary, camera: Vector2) -> void:
	if bool(m.get("impact", false)):
		return
	var c: Vector2 = Vector2(m["target"]) - camera
	var h: float = float(m["h"])
	var r: float = (90.0 if bool(m["big"]) else 70.0) * (1.0 - h * 0.6)
	game.draw_set_transform(c, 0.0, Vector2(1.0, 0.45))
	game.draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.35 + 0.3 * (1.0 - h)))
	game.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(1.0, 0.35, 0.15, 0.8), 3.0)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_meteor(game: Node, m: Dictionary, camera: Vector2, now: float) -> void:
	if bool(m.get("impact", false)):
		var b: float = float(m.get("boom", 0.0))
		if b > 0.8:
			return
		var c: Vector2 = Vector2(m["target"]) - camera
		var boom_frames: Array = _frames(DIR + "impacto")
		if not boom_frames.is_empty():
			game._draw_entity_fit(_pick(boom_frames, b, 8.0, false), c, Vector2(260, 260), Color.WHITE)
		else:
			var k: float = b / 0.8
			game.draw_arc(c, 30.0 + 130.0 * k, 0.0, TAU, 48, Color(1.0, 0.5, 0.12, 0.85 * (1.0 - k)), 10.0 * (1.0 - k) + 2.0)
			game.draw_circle(c, 46.0 * (1.0 - k), Color(1.0, 0.85, 0.45, 0.9 * (1.0 - k)))
			for j in range(8):
				var a: float = float(j) * TAU / 8.0 + 0.4
				game.draw_line(c + Vector2.from_angle(a) * 30.0 * k, c + Vector2.from_angle(a) * (40.0 + 110.0 * k), Color(1.0, 0.6, 0.2, 0.8 * (1.0 - k)), 4.0)
		return
	var p := _meteor_pos(m, camera)
	var size: float = 110.0 if bool(m["big"]) else 78.0
	var dir := Vector2(120.0, 270.0).normalized()
	for i in range(6):
		var k2 := float(i) / 6.0
		game.draw_circle(p - dir * size * (0.4 + k2 * 1.6), size * 0.42 * (1.0 - k2 * 0.8), Color(1.0, 0.45 + 0.3 * k2, 0.1, 0.55 * (1.0 - k2)))
	var frames: Array = _frames(DIR + "meteoro")
	if not frames.is_empty():
		game._draw_entity_fit(_pick(frames, now, 10.0, true), p, Vector2(size, size) * 1.2, Color.WHITE)
	else:
		# Provisorio: rocha escura com veios em brasa, girando.
		var rot: float = now * 2.2
		var rock := PackedVector2Array()
		for i in range(10):
			var a: float = rot + float(i) * TAU / 10.0
			rock.append(p + Vector2.from_angle(a) * size * (0.46 + 0.07 * sin(float(i) * 2.7)))
		game.draw_circle(p, size * 0.62, Color(1.0, 0.4, 0.1, 0.35))
		game.draw_colored_polygon(rock, Color(0.16, 0.09, 0.08, 1.0))
		game.draw_polyline(rock + PackedVector2Array([rock[0]]), Color(1.0, 0.55, 0.15, 1.0), 3.0)
		for i in range(3):
			var a2: float = rot * 1.3 + float(i) * 2.1
			game.draw_line(p + Vector2.from_angle(a2) * size * 0.1, p + Vector2.from_angle(a2 + 0.6) * size * 0.36, Color(1.0, 0.7, 0.2, 0.9), 2.5)


# ================================================================ tela
static func skip_rect(viewport: Vector2) -> Rect2:
	return Rect2(Vector2(viewport.x - 230.0, 18.0), Vector2(212.0, 44.0))


static func draw_overlay(game: Node, viewport: Vector2) -> void:
	var intro: RTUmbraIntro = game._umbra_intro()
	if not intro.active:
		return
	var camera: Vector2 = game._camera(viewport)
	var full := Rect2(Vector2.ZERO, viewport)
	# Tempo arrastado: tela azulada e silenciosa.
	if intro.slow > 0.01:
		game.draw_rect(full, Color(0.1, 0.18, 0.32, 0.32 * intro.slow))
		var c := viewport * 0.5
		game.draw_arc(c, viewport.y * 0.46, -PI * 0.5, -PI * 0.5 + TAU * fmod(intro.clock * 0.25, 1.0), 64, Color(0.7, 0.9, 1.0, 0.18 * intro.slow), 3.0)
	if intro.flash > 0.0:
		game.draw_rect(full, Color(intro.flash_color, 0.85 * intro.flash))
	# Faixas de cinema.
	var bar: float = 74.0 * intro.letterbox
	if bar > 0.5:
		game.draw_rect(Rect2(0, 0, viewport.x, bar), Color(0, 0, 0, 0.96))
		game.draw_rect(Rect2(0, viewport.y - bar, viewport.x, bar), Color(0, 0, 0, 0.96))
	_draw_balloon(game, intro, camera, viewport)
	if intro.qte_index >= 0 and intro.qte_index < intro.meteors.size():
		_draw_qte(game, intro, camera, viewport)
	if intro.title > 0.0:
		var a: float = clampf(intro.title / 0.5, 0.0, 1.0) * clampf((1.7 - intro.title) / 0.3 + 0.2, 0.0, 1.0)
		game._draw_centered("UMBRA", Vector2(viewport.x * 0.5, viewport.y * 0.4), 64, Color(0.42, 1.0, 0.55, a))
		game._draw_centered("a Geovana que desistiu", Vector2(viewport.x * 0.5, viewport.y * 0.4 + 52), 22, Color(0.85, 0.92, 0.9, a))
	if intro.can_skip:
		var r := skip_rect(viewport)
		game.draw_rect(r, Color(0, 0, 0, 0.5))
		if intro.skip_hold > 0.0:
			game.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(intro.skip_hold / RTUmbraIntro.SKIP_HOLD, 0.0, 1.0), r.size.y)), Color(0.42, 1.0, 0.55, 0.45))
		game._draw_centered("SEGURE PARA PULAR", r.get_center(), 15, Color(0.9, 0.95, 0.95, 0.9))


static func _speaker_pos(game: Node, intro: RTUmbraIntro, who: String) -> Vector2:
	match who:
		"geo231":
			return Vector2(intro.geo["pos"]) + Vector2(0, -78)
		"umbra":
			return Vector2(intro.umbra["pos"]) + Vector2(0, -175)
	return game.player_pos + Vector2(0, -82)


static func _draw_balloon(game: Node, intro: RTUmbraIntro, camera: Vector2, viewport: Vector2) -> void:
	if intro.balloon.is_empty():
		return
	var who: String = String(intro.balloon.get("who", ""))
	var text: String = intro.balloon_visible_text()
	var full_text: String = String(intro.balloon.get("text", ""))
	var font: Font = game.menu_ui_font
	var big: bool = bool(intro.balloon.get("big", false))
	var loud: bool = bool(intro.balloon.get("loud", false))
	var size: int = 24 if big else (26 if loud else 19)
	var width: float = 420.0 if big else 360.0
	var measure: Vector2 = font.get_multiline_string_size(full_text, HORIZONTAL_ALIGNMENT_CENTER, width, size)
	var box_size := Vector2(minf(width, measure.x) + 36.0, measure.y + 34.0)
	var anchor: Vector2 = _speaker_pos(game, intro, who) - camera
	var box_pos := Vector2(anchor.x - box_size.x * 0.5, anchor.y - box_size.y - 26.0)
	var side := false
	if box_pos.y < 84.0:
		# Sem espaco acima da cabeca: o balao vai para o lado de quem fala.
		side = true
		var to_left: bool = anchor.x > viewport.x * 0.5
		box_pos = Vector2(anchor.x - box_size.x - 46.0 if to_left else anchor.x + 46.0, anchor.y + 30.0)
	box_pos = box_pos.clamp(Vector2(12, 84), viewport - box_size - Vector2(12, 90))
	if loud:
		box_pos += Vector2(sin(intro.clock * 50.0) * 2.0, cos(intro.clock * 43.0) * 2.0)
	var umbra_style: bool = who == "umbra"
	var bg := Color(0.07, 0.02, 0.1, 0.94) if umbra_style else Color(0.98, 0.97, 0.94, 0.97)
	var ink := Color(0.62, 1.0, 0.7) if umbra_style else Color(0.08, 0.06, 0.1)
	var edge := Color(0.42, 1.0, 0.55) if umbra_style else (Color(0.85, 0.12, 0.2) if loud else Color(0.1, 0.08, 0.12))
	var rect := Rect2(box_pos, box_size)
	# Rabicho apontando para quem fala.
	var tail: PackedVector2Array
	if side:
		var edge_x: float = rect.end.x - 2.0 if anchor.x > rect.end.x else rect.position.x + 2.0
		var ty: float = clampf(anchor.y, rect.position.y + 14.0, rect.end.y - 14.0)
		tail = PackedVector2Array([Vector2(edge_x, ty - 12.0), Vector2(edge_x, ty + 12.0), anchor])
	else:
		var tail_base: float = clampf(anchor.x, rect.position.x + 24.0, rect.end.x - 24.0)
		tail = PackedVector2Array([Vector2(tail_base - 12.0, rect.end.y - 2.0), Vector2(tail_base + 12.0, rect.end.y - 2.0), anchor + Vector2(0, -6)])
	game.draw_colored_polygon(tail, edge)
	game.draw_rect(rect.grow(3.0), edge)
	game.draw_rect(rect, bg)

	var name: String = {"geo231": "GEO231", "umbra": "UMBRA", "geovana": "GEOVANA"}.get(who, who.to_upper())
	var tag_col := Color(0.42, 1.0, 0.55) if umbra_style else (Color(0.85, 0.3, 0.9) if who == "geo231" else Color(0.2, 0.6, 1.0))
	var tag_w: float = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 14.0
	game.draw_rect(Rect2(rect.position + Vector2(10, -12), Vector2(tag_w, 20)), tag_col)
	game.draw_string(font, rect.position + Vector2(17, 3), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.04, 0.03, 0.06))
	game.draw_multiline_string(font, rect.position + Vector2(18, 18 + font.get_ascent(size)), text, HORIZONTAL_ALIGNMENT_CENTER, box_size.x - 36.0, size, -1, ink)


static func _draw_qte(game: Node, intro: RTUmbraIntro, camera: Vector2, viewport: Vector2) -> void:
	var waiting: bool = intro.qte_waiting()
	var dir_name: String = intro.qte_dir()
	if waiting:
		var dir: Vector2 = RTUmbraIntro.DIRS.get(dir_name, Vector2.ZERO)
		# Seta grande sobre a Geovana + anel do tempo que resta.
		# Unico comando na tela: a seta sobre a Geovana (deslize/toque, setas, WASD ou direcional).
		var head: Vector2 = game.player_pos - camera + Vector2(0, -122)
		var left: float = 1.0 - intro.qte_progress()
		var pulse: float = 0.5 + 0.5 * sin(intro.clock * 14.0)
		game.draw_circle(head, 50.0 + pulse * 3.0, Color(1.0, 0.8, 0.25, 0.18 + 0.12 * pulse))
		game.draw_circle(head, 44.0, Color(0.03, 0.02, 0.06, 0.78))
		game.draw_arc(head, 47.0, -PI * 0.5, -PI * 0.5 + TAU * left, 48, Color(1.0, 0.85, 0.3, 0.95), 5.0)
		_draw_arrow(game, head + dir * 3.0 * pulse, dir, 31.0, Color(1, 1, 1))
		game._draw_centered("O TEMPO SE ARRASTA... DESVIE!", Vector2(viewport.x * 0.5, 110), 22, Color(0.75, 0.92, 1.0, 0.95))
		game._draw_centered("%d / %d" % [intro.qte_index + 1, RTUmbraIntro.QTE_COUNT], Vector2(viewport.x * 0.5, 140), 16, Color(0.9, 0.9, 0.9, 0.8))


static func _draw_arrow(game: Node, c: Vector2, dir: Vector2, s: float, color: Color) -> void:
	var side := dir.orthogonal()
	game.draw_colored_polygon(PackedVector2Array([c + dir * s, c + side * s * 0.8, c + side * s * 0.32, c - dir * s * 0.9 + side * s * 0.32, c - dir * s * 0.9 - side * s * 0.32, c - side * s * 0.32, c - side * s * 0.8]), color)
