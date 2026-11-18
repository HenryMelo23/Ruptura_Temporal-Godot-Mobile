class_name RTUmbraNecrosePresentation
extends RefCounted

## Desenho da MISSA DO NINHO (RTUmbraNecroseMass): chao (luz das velas,
## incenso, arco dos turibulos, ondas do sino), frente (correntes, turibulos,
## velas, coroinhas) e tela (medidor de desajuste, contagem do sino).

const RAT_PATHS := ["res://assets/sprites/phase3_enemies/flagelante_01.png", "res://assets/sprites/phase3_enemies/flagelante_02.png"]
const INCENSE := Color(0.42, 0.78, 0.22)
const INCENSE_DARK := Color(0.12, 0.26, 0.08)
const LIGHT := Color(1.0, 0.82, 0.42)

static var _rat_frames: Array = []


static func _rats() -> Array:
	if _rat_frames.is_empty():
		for p in RAT_PATHS:
			if ResourceLoader.exists(p):
				_rat_frames.append(load(p))
	return _rat_frames


# ============================================================ chao
static func draw_floor(game: Node, h: Dictionary, camera: Vector2) -> void:
	var t: float = RTUmbraNecroseMass.elapsed(h)
	var fade_in: float = clampf(t / 0.5, 0.0, 1.0)
	var fade_out: float = clampf((RTUmbraNecroseMass.DURATION - t) / 0.6, 0.0, 1.0)
	var a: float = fade_in * fade_out
	# Luz das velas (a zona segura) por baixo de tudo.
	for c in Array(h.get("candles", [])):
		var p: Vector2 = Vector2(c["pos"]) - camera
		if bool(c["lit"]):
			var flick: float = 1.0 + 0.04 * sin(game.time_alive * 9.0 + float(c["flicker"]))
			var r: float = RTUmbraNecroseMass.CANDLE_RADIUS * flick
			game.draw_circle(p, r + 14.0, Color(LIGHT, 0.08 * a))
			game.draw_circle(p, r, Color(LIGHT, 0.16 * a))
			game.draw_circle(p, r * 0.6, Color(1.0, 0.92, 0.65, 0.12 * a))
			game.draw_arc(p, r, 0.0, TAU, 48, Color(1.0, 0.85, 0.45, 0.7 * a), 2.0)
		else:
			game.draw_arc(p, RTUmbraNecroseMass.RELIGHT_RADIUS, 0.0, TAU, 36, Color(1.0, 0.85, 0.45, 0.25 * a), 1.5)
			var relight: float = float(c.get("relight", 0.0))
			if relight > 0.0:
				game.draw_arc(p, RTUmbraNecroseMass.RELIGHT_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * relight, 36, Color(1.0, 0.9, 0.5, 0.95), 4.0)
	# Arco dos turibulos: avisa o caminho antes do incenso comecar.
	if t < RTUmbraNecroseMass.WARMUP + 0.6:
		var warn: float = clampf(1.0 - (t - RTUmbraNecroseMass.WARMUP) / 0.6, 0.0, 1.0) * fade_in
		for cen in Array(h.get("censers", [])):
			var prev := Vector2.INF
			for k in range(29):
				var ang: float = float(cen["base"]) + float(cen["amp"]) * 1.25 * lerpf(-1.0, 1.0, float(k) / 28.0)
				var q: Vector2 = Vector2(cen["pivot"]) + Vector2.from_angle(ang) * float(cen["len"]) - camera
				if prev != Vector2.INF and k % 2 == 0:
					game.draw_line(prev, q, Color(INCENSE, 0.75 * warn), 3.0)
				prev = q
	# Incenso.
	var low: bool = game._runtime_visual_budget_active()
	var list: Array = RTUmbraNecroseMass.live_puffs(h, t)
	for i in range(list.size()):
		if low and i % 2 == 1:
			continue
		var pf: Dictionary = list[i]
		var p: Vector2 = Vector2(pf["pos"]) - camera
		var r: float = float(pf["r"])
		var u: float = float(pf["age"])
		var pa: float = a * clampf(u / 0.12, 0.0, 1.0) * clampf((1.0 - u) / 0.3, 0.0, 1.0)
		var wob: Vector2 = Vector2(sin(game.time_alive * 2.0 + float(i)), cos(game.time_alive * 1.7 + float(i) * 1.3)) * 3.0
		game.draw_circle(p + wob, r, Color(INCENSE_DARK, 0.28 * pa))
		game.draw_circle(p - wob * 0.5, r * 0.78, Color(INCENSE, 0.24 * pa))
		game.draw_circle(p + Vector2(-r * 0.25, -r * 0.25), r * 0.38, Color(0.75, 1.0, 0.5, 0.16 * pa))
	# Ondas do sino.
	for i in range(RTUmbraNecroseMass.TOLLS.size()):
		var dt: float = t - float(RTUmbraNecroseMass.TOLLS[i])
		if dt >= 0.0 and dt < 0.9:
			var rr: float = 60.0 + dt * 900.0
			var final_toll: bool = i == RTUmbraNecroseMass.TOLLS.size() - 1
			var col: Color = Color(0.75, 1.0, 0.35) if final_toll else Color(0.9, 0.95, 0.7)
			game.draw_arc(Vector2(game.boss_pos) - camera, rr, 0.0, TAU, 96, Color(col, 0.65 * (1.0 - dt / 0.9)), 8.0 if final_toll else 4.0)


# ============================================================ frente
static func draw_front(game: Node, camera: Vector2) -> void:
	var h: Dictionary = RTUmbraNecroseMass.active(game)
	if h.is_empty():
		return
	var t: float = RTUmbraNecroseMass.elapsed(h)
	var a: float = clampf(t / 0.5, 0.0, 1.0) * clampf((RTUmbraNecroseMass.DURATION - t) / 0.6, 0.0, 1.0)
	# Velas (o poste e a chama).
	for c in Array(h.get("candles", [])):
		var p: Vector2 = Vector2(c["pos"]) - camera
		game.draw_rect(Rect2(p + Vector2(-5, -34), Vector2(10, 34)), Color(0.92, 0.88, 0.76, a))
		game.draw_rect(Rect2(p + Vector2(-5, -34), Vector2(10, 34)), Color(0.25, 0.2, 0.15, a), false, 2.0)
		game.draw_rect(Rect2(p + Vector2(-9, -4), Vector2(18, 6)), Color(0.35, 0.3, 0.22, a))
		if bool(c["lit"]):
			var f: float = sin(game.time_alive * 14.0 + float(c["flicker"]))
			game.draw_circle(p + Vector2(0, -42), 9.0 + f, Color(1.0, 0.6, 0.15, 0.85 * a))
			game.draw_circle(p + Vector2(0, -44), 5.0, Color(1.0, 0.95, 0.6, a))
		else:
			for k in range(3):
				var s: float = fmod(game.time_alive * 0.8 + float(k) * 0.33, 1.0)
				game.draw_circle(p + Vector2(sin(s * 6.0 + float(k)) * 5.0, -40.0 - s * 30.0), 4.0 + s * 4.0, Color(0.55, 0.55, 0.55, 0.45 * (1.0 - s) * a))
	# Turibulos.
	for cen in Array(h.get("censers", [])):
		var pivot: Vector2 = Vector2(cen["pivot"]) - camera
		var head: Vector2 = RTUmbraNecroseMass.censer_head(cen, maxf(t, 0.0)) - camera
		var chain: Vector2 = head - pivot
		var links: int = int(chain.length() / 14.0)
		for k in range(links):
			var q: Vector2 = pivot + chain * (float(k) / float(maxi(1, links)))
			game.draw_circle(q, 3.6, Color(0.2, 0.15, 0.06, 0.9 * a))
			game.draw_circle(q, 2.4, Color(0.85, 0.7, 0.36, 0.95 * a))
		# Argola de onde o turibulo pende.
		game.draw_circle(pivot, 11.0, Color(0.18, 0.13, 0.05, a))
		game.draw_arc(pivot, 11.0, 0.0, TAU, 24, Color(0.9, 0.75, 0.38, a), 3.0)
		# Turibulo: bojo dourado com tampa e furos brilhando de incenso.
		var emitting: float = 1.0 if t >= RTUmbraNecroseMass.WARMUP and t < RTUmbraNecroseMass.EMIT_END else 0.3
		game.draw_circle(head, 30.0, Color(0.55, 1.0, 0.35, 0.16 * a * emitting))
		game.draw_circle(head, 21.0, Color(0.18, 0.12, 0.04, a))
		game.draw_circle(head, 18.0, Color(0.88, 0.68, 0.26, a))
		game.draw_circle(head + Vector2(-5, -6), 6.0, Color(1.0, 0.9, 0.55, 0.8 * a))
		game.draw_colored_polygon(PackedVector2Array([head + Vector2(-12, -14), head + Vector2(12, -14), head + Vector2(0, -27)]), Color(0.7, 0.52, 0.18, a))
		for k in range(4):
			var hole: Vector2 = head + Vector2.from_angle(float(k) * TAU / 4.0 + game.time_alive) * 10.0
			game.draw_circle(hole, 2.6, Color(0.6, 1.0, 0.4, (0.5 + 0.5 * emitting) * a))
	# Coroinhas.
	var frames: Array = _rats()
	for r in Array(h.get("rats", [])):
		var p: Vector2 = Vector2(r["pos"]) - camera
		var dead: float = float(r.get("dead", 0.0))
		var ra: float = a * (1.0 - clampf(dead / 0.45, 0.0, 1.0))
		var flip: bool = Vector2(r.get("dir", Vector2.RIGHT)).x < 0.0
		if not frames.is_empty():
			var tex: Texture2D = frames[int(float(r["phase"]) / 3.0) % frames.size()]
			game._draw_entity_fit_flipped(tex, p, Vector2(46, 46), flip, Color(1, 1, 1, ra), true)
		else:
			game.draw_circle(p, 13.0, Color(0.45, 0.42, 0.4, ra))
		if float(r.get("flee", 0.0)) > 0.0 and dead <= 0.0:
			game.draw_string(game.menu_ui_font, p + Vector2(-4, -30), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, ra))


# ============================================================ tela
static func draw_screen(game: Node, viewport: Vector2) -> void:
	var h: Dictionary = RTUmbraNecroseMass.active(game)
	if h.is_empty():
		return
	var t: float = RTUmbraNecroseMass.elapsed(h)
	var d: float = float(h.get("desajuste", 0.0))
	var camera: Vector2 = game._camera(viewport)
	# Vinheta verde conforme o desajuste.
	if d > 0.05:
		var e: float = 90.0
		for i in range(4):
			var aa: float = 0.22 * d * (1.0 - float(i) / 4.0)
			var w: float = e * float(i + 1) / 4.0
			var col := Color(0.18, 0.42, 0.08, aa)
			game.draw_rect(Rect2(0, 0, viewport.x, w), col)
			game.draw_rect(Rect2(0, viewport.y - w, viewport.x, w), col)
			game.draw_rect(Rect2(0, 0, w, viewport.y), col)
			game.draw_rect(Rect2(viewport.x - w, 0, w, viewport.y), col)
	# Medidor de desajuste em volta da Geovana.
	var p: Vector2 = game.player_pos - camera + Vector2(0, 52)
	game.draw_arc(p, 30.0, PI * 0.15, PI * 0.85, 24, Color(0, 0, 0, 0.55), 7.0)
	if d > 0.0:
		var hot: bool = d >= RTUmbraNecroseMass.INVERT_AT
		game.draw_arc(p, 30.0, PI * 0.85, PI * 0.85 - PI * 0.7 * d, 24, Color(0.95, 0.35, 0.9) if hot else Color(0.55, 1.0, 0.3), 5.0)
	var mark: Vector2 = p + Vector2.from_angle(PI * 0.5) * 30.0
	game.draw_line(mark + Vector2(0, -5), mark + Vector2(0, 5), Color(1, 1, 1, 0.8), 2.0)
	if bool(h.get("inverted", false)):
		game._draw_centered("CONTROLES INVERTIDOS", game.player_pos - camera + Vector2(0, 96), 14, Color(0.95, 0.5, 1.0, 0.95))
	# Contagem do sino.
	var final_t: float = float(RTUmbraNecroseMass.TOLLS[RTUmbraNecroseMass.TOLLS.size() - 1])
	if t > final_t - 3.2 and t < final_t + 0.3:
		var tolls: int = int(h.get("tolls", 0))
		var cx: float = viewport.x * 0.5
		game._draw_centered("TOQUE DE RECOLHER — FIQUE NA LUZ", Vector2(cx, 176), 20, Color(1.0, 0.88, 0.5, 0.95))
		for i in range(3):
			var bp := Vector2(cx - 40.0 + 40.0 * float(i), 204)
			var rung: bool = i < tolls
			game.draw_circle(bp, 11.0, Color(0.95, 0.75, 0.3, 0.95) if rung else Color(0.15, 0.12, 0.08, 0.8))
			game.draw_arc(bp, 11.0, 0.0, TAU, 20, Color(1, 0.9, 0.6, 0.9), 2.0)
