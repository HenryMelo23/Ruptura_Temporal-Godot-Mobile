class_name RTBailePresentation
extends RefCounted

## Desenho da Fase 10 (Bailao da Dona Boleta). So apresentacao: le o estado de
## RTBaileController / RTBaileLagartona / RTBoss10Controller e nunca decide dano.
## Arte PROVISORIA em assets/sprites/baile/ (tools/baile_placeholder_sprites.py);
## trocar PNGs mantendo nomes/canvas nao exige mexer aqui. Asset ausente cai em
## desenho procedural seguro.

const DIR := "res://assets/sprites/baile/"
const PINK := Color(1.0, 0.36, 0.72)
const AMBER := Color(1.0, 0.68, 0.24)
const SIZES := {
	"borboleta_monarca": 84.0, "borboleta_garrafeira": 86.0, "borboleta_sombrinha": 96.0,
	"borboleta_paredinha": 100.0, "borboleta_hype": 84.0, "lagartona_paredao": 150.0,
}
const PREFIX := {
	"borboleta_monarca": "b10_monarca", "borboleta_garrafeira": "b10_garrafeira", "borboleta_sombrinha": "b10_sombrinha",
	"borboleta_paredinha": "b10_paredinha", "borboleta_hype": "b10_hype",
}
const SEGMENT_SIZE := Vector2(100, 100)
const BOTTLE_SIZE := Vector2(34, 34)
const DANCER_SIZE := Vector2(72, 72)
const FLOOR_LIGHTS := 4

static var _tex: Dictionary = {}


static func tex(name: String) -> Texture2D:
	if _tex.has(name):
		return _tex[name]
	var path: String = DIR + name + ".png"
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex[name] = t
	return t


static func _low(game: Node) -> bool:
	return bool(game.gfx_low_resource) or game._memory_saver_active() or game._runtime_visual_budget_active()


# ============================================================ inimigos e boss
static func enemy_draw_size(kind: String) -> Vector2:
	var s: float = float(SIZES.get(kind, 84.0))
	return Vector2(s, s)


static func enemy_texture(game: Node, enemy: Dictionary) -> Texture2D:
	var kind: String = String(enemy.get("type", ""))
	var anim: String = String(enemy.get("b10_anim", "idle"))
	var bp: float = float(game.baile_controller.beat.beat_pos)
	if kind == RTBaileController.LAGARTONA:
		match anim:
			"attack":
				return tex("b10_lagartona_attack")
			"daze":
				return tex("b10_lagartona_daze")
			"casulo":
				return tex("b10_segmento_casulo")
		return tex("b10_lagartona_%d" % (int(bp) % 4))
	var prefix: String = String(PREFIX.get(kind, ""))
	if prefix == "":
		return null
	var idx: int = int(bp * 2.0 + float(enemy.get("b10_offset", 0.0)) * 2.0) % 2
	match anim:
		"attack":
			idx = 2
		"drop":
			idx = 3
	var t := tex("%s_%d" % [prefix, idx])
	return t if t != null else tex(prefix + "_0")


static func boss_texture(game: Node) -> Texture2D:
	var info: Array = game.boss10_controller.frame_info()
	var t := tex("%s_%d" % [String(info[0]), int(info[1])])
	return t if t != null else tex("boss10_idle_0")


static func draw_boss(game: Node, camera: Vector2, boss_tex: Texture2D, pos: Vector2, size: Vector2, modulate: Color) -> void:
	var b: RTBoss10Controller = game.boss10_controller
	var p: Vector2 = pos - camera - Vector2(0, b.height)
	var flip: bool = game.player_pos.x < pos.x
	if boss_tex != null:
		game._draw_entity_fit_flipped(boss_tex, p, size, flip, modulate, true)
	else:
		game.draw_circle(p + Vector2(0, -110), 90.0, Color(0.45, 0.16, 0.66))
		game.draw_circle(p + Vector2(0, -180), 30.0, Color(0.16, 0.1, 0.16))


# ============================================================ chao (antes das entidades)
static func draw_ground(game: Node, camera: Vector2) -> void:
	var c: RTBaileController = game.baile_controller
	var beat: RTBaileBeatClock = c.beat
	var pulse: float = beat.light_pulse()
	var low: bool = _low(game)
	var vp: Vector2 = game.get_viewport_rect().size
	# Luzes de pista que pulsam na batida (perto da camera; custo fixo).
	if not low and game.boss10_controller.roda.is_empty():
		for i in range(FLOOR_LIGHTS):
			var fx: float = fposmod(float(i) * 0.37 + beat.beat_pos * 0.05 * (1.0 if i % 2 == 0 else -1.0), 1.0)
			var fy: float = fposmod(float(i) * 0.61 + sin(beat.beat_pos * 0.25 + i) * 0.1, 1.0)
			var lp: Vector2 = Vector2(fx * vp.x, fy * vp.y)
			var col: Color = PINK if i % 3 == 0 else (AMBER if i % 3 == 1 else Color(0.5, 0.3, 1.0))
			col.a = 0.025 + 0.045 * pulse
			game.draw_circle(lp, 80.0 + 18.0 * pulse, col)
	_draw_stage(game, camera, pulse)
	# Pocas de gin.
	for pd in c.puddles:
		var pp: Vector2 = Vector2(pd["pos"]) - camera
		var fade: float = clampf((float(pd["life"]) - float(pd["t"])) / 1.0, 0.0, 1.0)
		game.draw_circle(pp, float(pd["r"]), Color(0.55, 0.85, 0.8, 0.22 * fade))
		game.draw_arc(pp, float(pd["r"]), 0.0, TAU, 28, Color(0.75, 1.0, 0.95, 0.45 * fade), 2.0)
	# Marcadores de queda das garrafas: mesmo centro/raio do dano.
	for b in c.bottles:
		var to: Vector2 = Vector2(b["to"]) - camera
		var u: float = clampf(float(b["t"]) / maxf(0.01, float(b["dur"])), 0.0, 1.0)
		game.draw_circle(to, RTBaileController.BOTTLE_RADIUS, Color(1.0, 0.4, 0.3, 0.10 + 0.12 * u))
		game.draw_arc(to, RTBaileController.BOTTLE_RADIUS, 0.0, TAU, 28, Color(1.0, 0.5, 0.35, 0.75), 2.0)
		game.draw_arc(to, RTBaileController.BOTTLE_RADIUS * u, 0.0, TAU, 24, Color(1.0, 0.85, 0.5, 0.8), 2.0)
	# Aneis de grave.
	for r in c.rings:
		var rp: Vector2 = Vector2(r["pos"]) - camera
		var rad: float = RTBaileController.ring_radius(r)
		var a: float = 1.0 - clampf(float(r["t"]) / maxf(0.01, float(r["life"])), 0.0, 1.0)
		game.draw_arc(rp, rad, 0.0, TAU, 40, Color(PINK.r, PINK.g, PINK.b, 0.8 * a), RTBaileController.RING_BAND * 0.7)
	# Indicadores dos bichos: sombrinha (cone de bloqueio) e aura da Hype.
	for e in game.enemies:
		var kind: String = String(e.get("type", ""))
		var ep: Vector2 = Vector2(e["pos"]) - camera
		if ep.x < -200 or ep.y < -200 or ep.x > vp.x + 200 or ep.y > vp.y + 200:
			continue
		if kind == RTBaileController.SOMBRINHA:
			var g: float = Vector2(e.get("b10_guard", Vector2.RIGHT)).angle()
			game.draw_arc(ep + Vector2(0, 10), 58.0, g - RTBaileController.SOMBRINHA_BLOCK_HALF, g + RTBaileController.SOMBRINHA_BLOCK_HALF, 12, Color(1.0, 0.45, 0.75, 0.75), 5.0)
		elif kind == RTBaileController.HYPE:
			game.draw_arc(ep, RTBaileController.HYPE_RADIUS, 0.0, TAU, 40, Color(0.35, 0.6, 1.0, 0.18 + 0.2 * pulse), 2.0)
		elif bool(e.get("b10_embalo", false)):
			game.draw_arc(ep + Vector2(0, 30), 26.0, 0.0, TAU, 16, Color(0.35, 0.6, 1.0, 0.5), 2.0)
	_draw_lagartona(game, camera)
	_draw_boss_world(game, camera, pulse)
	# Multidao da Roda: camada propria (shader), acima do chao e abaixo do jogo.
	var boss: RTBoss10Controller = game.boss10_controller
	var roda_on: bool = not boss.roda.is_empty()
	RTBaileCrowdPresentation.update(game, camera, vp, roda_on, Vector2(boss.roda.get("center", Vector2.ZERO)), float(boss.roda.get("r", 0.0)), float(boss.roda.get("angle", 0.0)), roda_appear(game, boss), beat.beat_pos, low)
	if roda_on:
		_draw_roda(game, camera, boss, pulse)


static func _draw_stage(game: Node, camera: Vector2, pulse: float) -> void:
	var c: RTBaileController = game.baile_controller
	var rect: Rect2 = c.stage_rect()
	var origin: Vector2 = rect.position - camera
	var vp: Vector2 = game.get_viewport_rect().size
	if origin.x > vp.x + 60 or origin.y > vp.y + 60 or origin.x + rect.size.x < -60 or origin.y + rect.size.y < -200:
		return
	var st: Texture2D = tex("b10_palco")
	var draw_rect := Rect2(origin + Vector2(-20, -100), rect.size + Vector2(40, 100))
	if st != null:
		game.draw_texture_rect(st, draw_rect, false)
	else:
		game.draw_rect(Rect2(origin, rect.size), Color(0.27, 0.18, 0.14))
	# Faixa de luz do palco pulsando na batida.
	game.draw_rect(Rect2(origin + Vector2(0, rect.size.y - 8), Vector2(rect.size.x, 6)), Color(PINK.r, PINK.g, PINK.b, 0.3 + 0.5 * pulse))
	var b: RTBoss10Controller = game.boss10_controller
	if b.on_stage():
		var info_tex: Texture2D = tex("boss10_sing_%d" % (int(c.beat.beat_pos) % 4))
		var sp: Vector2 = c.singer_pos() - camera
		if info_tex != null:
			game._draw_entity_fit(info_tex, sp, RTBoss10Controller.DRAW_SIZE * 0.85, Color.WHITE, true)
		# Notas saindo do microfone.
		for k in range(3):
			var u: float = fposmod(c.beat.beat_pos * 0.5 + k * 0.33, 1.0)
			var np: Vector2 = sp + Vector2(70 + 50 * u, -200 - 90 * u + sin(u * TAU) * 10)
			game.draw_circle(np, 6.0, Color(PINK.r, PINK.g, PINK.b, 1.0 - u))
			game.draw_line(np + Vector2(5, 0), np + Vector2(5, -18), Color(PINK.r, PINK.g, PINK.b, 1.0 - u), 2.0)


static func _draw_lagartona(game: Node, camera: Vector2) -> void:
	var c: RTBaileController = game.baile_controller
	var lg: RTBaileLagartona = c.lagartona
	if not c.miniboss_alive() and lg.segments.is_empty():
		return
	# Caminho do Trenzinho: luzes de chao (aviso).
	if lg.state in ["trem_warn", "trem"] and lg.path.size() > 1:
		for i in range(lg.path.size()):
			if i < lg.path_i:
				continue
			var on: bool = (int(c.beat.beat_pos * 4.0) + i) % 2 == 0
			game.draw_circle(lg.path[i] - camera, 9.0 if on else 6.0, Color(AMBER.r, AMBER.g, AMBER.b, 0.85 if on else 0.4))
	if lg.state == "vira_warn" or lg.state == "vira":
		game.draw_arc(lg.vira_center - camera, RTBaileLagartona.VIRA_RADIUS, 0.0, TAU, 48, Color(0.6, 1.0, 0.4, 0.4), 3.0)
	# Segmentos (do rabo para a cabeca).
	for i in range(lg.segments.size() - 1, -1, -1):
		var sp: Vector2 = Vector2(lg.segments[i]) - camera
		var lit: bool = lg.state == "grave" and lg.lit_seg - 1 == i
		var cocoon: bool = lg.state == "casulo"
		var st: Texture2D = tex("b10_segmento_casulo" if cocoon else ("b10_segmento_1" if lit else "b10_segmento_0"))
		if st != null:
			game._draw_entity_fit(st, sp, SEGMENT_SIZE, Color.WHITE, false)
		else:
			game.draw_circle(sp, RTBaileLagartona.SEGMENT_RADIUS, Color(0.45, 0.7, 0.2))
		if lit:
			game.draw_circle(sp, 46.0, Color(PINK.r, PINK.g, PINK.b, 0.35))
	for cn in lg.cones:
		var o: Vector2 = Vector2(cn["pos"]) - camera
		var d: Vector2 = cn["dir"]
		var a: float = 1.0 - float(cn["t"]) / 0.35
		_cone(game, o, d, RTBaileLagartona.GRAVE_RANGE, RTBaileLagartona.GRAVE_HALF, Color(PINK.r, PINK.g, PINK.b, 0.4 * a))


static func _cone(game: Node, origin: Vector2, dir: Vector2, length: float, half: float, col: Color) -> void:
	var pts := PackedVector2Array([origin])
	var a0: float = dir.angle() - half
	for k in range(9):
		pts.append(origin + Vector2.from_angle(a0 + 2.0 * half * float(k) / 8.0) * length)
	game.draw_colored_polygon(pts, col)


static func _draw_boss_world(game: Node, camera: Vector2, pulse: float) -> void:
	var b: RTBoss10Controller = game.boss10_controller
	var c: RTBaileController = game.baile_controller
	if not game.boss_active and b.roda.is_empty() and b.spots.is_empty():
		return
	# Holofotes: feixe do palco ate o circulo; trava pisca no tempo; rojao cai.
	var light_src: Vector2 = c.singer_pos() + Vector2(0, -230) - camera
	for s in b.spots:
		var st: String = String(s["state"])
		if st == "wait":
			continue
		var p: Vector2 = Vector2(s["pos"]) - camera
		var beam := PackedVector2Array([light_src + Vector2(-10, 0), light_src + Vector2(10, 0), p + Vector2(RTBoss10Controller.SPOT_RADIUS, 0), p - Vector2(RTBoss10Controller.SPOT_RADIUS, 0)])
		game.draw_colored_polygon(beam, Color(1.0, 0.85, 0.5, 0.07 if st == "sweep" else 0.13))
		var ring_col: Color = AMBER if st == "sweep" else Color(1.0, 0.3, 0.2)
		game.draw_circle(p, RTBoss10Controller.SPOT_RADIUS, Color(ring_col.r, ring_col.g, ring_col.b, 0.14 + (0.18 * pulse if st == "lock" else 0.0)))
		game.draw_arc(p, RTBoss10Controller.SPOT_RADIUS, 0.0, TAU, 32, Color(ring_col.r, ring_col.g, ring_col.b, 0.9), 3.0)
		if st == "fall":
			var u: float = clampf(float(s["t"]) / RTBoss10Controller.SPOT_FALL, 0.0, 1.0)
			var rk: Vector2 = p + Vector2(0, -420.0 * (1.0 - u))
			game.draw_line(rk, rk + Vector2(0, -38), Color(1.0, 0.9, 0.6), 6.0)
			game.draw_circle(rk, 7.0, Color(1.0, 0.5, 0.2))
	# Grave do microfone (cone) e aviso da inspiracao.
	if b.mode == "inhale":
		var bp: Vector2 = Vector2(game.boss_pos) - camera
		_cone(game, bp, b.grave_dir, RTBoss10Controller.GRAVE_RANGE, RTBoss10Controller.GRAVE_HALF, Color(1.0, 0.4, 0.7, 0.12))
		game.draw_arc(bp, 120.0 * (1.0 - clampf(b.t / maxf(0.01, c.beat.beat_len()), 0.0, 1.0)) + 20.0, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 2.0)
	if b.grave_flash > 0.0:
		_cone(game, Vector2(game.boss_pos) - camera, b.grave_dir, RTBoss10Controller.GRAVE_RANGE, RTBoss10Controller.GRAVE_HALF, Color(1.0, 0.4, 0.75, 0.45 * b.grave_flash / 0.35))
	# Sarrada: trilha marcada antes do dash.
	if b.mode == "dash_warn":
		game.draw_line(b.dash_from - camera, b.dash_to - camera, Color(PINK.r, PINK.g, PINK.b, 0.7), RTBoss10Controller.HIT_RADIUS * 1.2)


## 0..1: o publico fecha durante o aviso e se dispersa no fim.
static func roda_appear(game: Node, b: RTBoss10Controller) -> float:
	var beat_len: float = game.baile_controller.beat.beat_len()
	match String(b.roda.get("phase", "")):
		"warn":
			return clampf(float(b.roda["t"]) / maxf(0.01, beat_len * RTBoss10Controller.RODA_WARN_BEATS), 0.0, 1.0)
		"off":
			return 1.0 - clampf(float(b.roda["t"]) / maxf(0.01, beat_len * RTBoss10Controller.RODA_OFF_BEATS), 0.0, 1.0)
	return 1.0 if not b.roda.is_empty() else 0.0


static func _draw_roda(game: Node, camera: Vector2, b: RTBoss10Controller, pulse: float) -> void:
	var c: Vector2 = Vector2(b.roda["center"]) - camera
	var r: float = float(b.roda["r"])
	var ph: String = String(b.roda["phase"])
	if ph == "warn":
		for k in range(36):
			var a: float = TAU * float(k) / 36.0
			game.draw_circle(c + Vector2.from_angle(a) * r, 5.0, Color(PINK.r, PINK.g, PINK.b, 0.4 + 0.5 * pulse))
		return
	var alpha: float = 1.0
	if ph == "off":
		alpha = 1.0 - clampf(float(b.roda["t"]) / maxf(0.01, game.baile_controller.beat.beat_len() * RTBoss10Controller.RODA_OFF_BEATS), 0.0, 1.0)
	game.draw_arc(c, r - RTBoss10Controller.RODA_EDGE, 0.0, TAU, 64, Color(PINK.r, PINK.g, PINK.b, 0.35 * alpha), 3.0)
	var dancers: Array = b.dancer_positions()
	var marked: Dictionary = {}
	for m in Array(b.roda["marks"]):
		marked[int(m["i"])] = true
	var bp: float = float(game.baile_controller.beat.beat_pos)
	for i in range(dancers.size()):
		var dp: Vector2 = Vector2(dancers[i]) - camera
		var t: Texture2D = tex("b10_dancarina_%d" % ((int(bp * 2.0) + i) % 2))
		if marked.has(i):
			game.draw_circle(dp, 40.0, Color(1.0, 0.5, 0.2, 0.45 * alpha))
		if t != null:
			game._draw_entity_fit(t, dp + Vector2(0, -sin(bp * PI + i) * 6.0), DANCER_SIZE, Color(1, 1, 1, alpha), false)
		else:
			game.draw_circle(dp, 22.0, Color(PINK.r, PINK.g, PINK.b, alpha))


# ============================================================ tela (sobre as entidades)
static func draw_screen(game: Node, viewport: Vector2, camera: Vector2) -> void:
	var c: RTBaileController = game.baile_controller
	# Garrafas em voo (arco), acima de todo mundo.
	for b in c.bottles:
		var u: float = clampf(float(b["t"]) / maxf(0.01, float(b["dur"])), 0.0, 1.0)
		var p: Vector2 = Vector2(b["from"]).lerp(Vector2(b["to"]), u) - Vector2(0, sin(u * PI) * RTBaileController.BOTTLE_ARC) - camera
		var bt: Texture2D = tex("b10_garrafa_" + String(b["kind"]))
		if bt != null:
			game.draw_set_transform(p, u * TAU * 2.0, Vector2.ONE)
			game.draw_texture_rect(bt, Rect2(-BOTTLE_SIZE * 0.5, BOTTLE_SIZE), false)
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			game.draw_circle(p, 9.0, Color(0.8, 0.55, 0.2))
	for s in c.shots:
		var sp: Vector2 = Vector2(s["p"]) - camera
		game.draw_circle(sp, 12.0, Color(PINK.r, PINK.g, PINK.b, 0.9))
		game.draw_circle(sp, 6.0, Color(1, 1, 1, 0.9))
	_draw_teor(game, viewport, camera)
	_draw_beat_hud(game, viewport)


static func _draw_teor(game: Node, viewport: Vector2, camera: Vector2) -> void:
	var c: RTBaileController = game.baile_controller
	var teor: float = c.teor
	var low: bool = _low(game)
	var tt: float = float(game.time_alive)
	if teor >= 45.0:
		# Visao dupla: fantasmas deslocados dos inimigos visiveis (nunca dos avisos).
		var k: float = clampf((teor - 45.0) / 55.0, 0.0, 1.0) * (0.5 if low else 1.0)
		var off: Vector2 = Vector2(sin(tt * 1.7), cos(tt * 1.3)) * (10.0 + 18.0 * k)
		var drawn := 0
		for e in game.enemies:
			if drawn >= 14:
				break
			var ep: Vector2 = Vector2(e["pos"]) - camera
			if ep.x < -80 or ep.y < -80 or ep.x > viewport.x + 80 or ep.y > viewport.y + 80:
				continue
			var et: Texture2D = game._enemy_texture(e)
			if et == null:
				continue
			game._draw_entity_fit(et, ep + off, game._enemy_draw_size(e), Color(1.0, 0.6, 0.9, 0.28 * k), false)
			drawn += 1
	if teor >= 70.0 and not low:
		# Ilusoes: borboletas falsas translucidas (sem colisao nem dano).
		var n: int = 2 + int((teor - 70.0) / 15.0)
		for i in range(mini(4, n)):
			var a: float = tt * (0.6 + 0.15 * i) + i * 1.9
			var ip: Vector2 = game.player_pos - camera + Vector2(cos(a), sin(a * 1.3)) * (170.0 + 40.0 * i)
			var it: Texture2D = tex("b10_dancarina_%d" % (int(tt * 4.0 + i) % 2))
			if it != null:
				game._draw_entity_fit(it, ip, DANCER_SIZE, Color(1, 1, 1, 0.3), false)
	if teor >= 20.0:
		var v: float = clampf((teor - 20.0) / 80.0, 0.0, 1.0) * (0.6 if low else 1.0)
		var sway: float = sin(tt * 1.1) * 0.5 + 0.5
		_vignette(game, viewport, Color(0.9, 0.35, 0.2, 0.18 + 0.32 * v * (0.7 + 0.3 * sway)), 0.22 + 0.06 * sway)
	if c.blackout > 0.0:
		game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0, 0, 0, 0.7 * clampf(c.blackout / RTBaileController.BLACKOUT_TIME, 0.0, 1.0)))
	if teor > 1.0:
		var bar := Rect2(Vector2(viewport.x * 0.5 - 70.0, viewport.y * 0.85 + 12.0), Vector2(140.0, 7.0))
		game.draw_rect(bar, Color(0, 0, 0, 0.45))
		game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * teor / RTBaileController.TEOR_MAX, bar.size.y)), Color(1.0, 0.6, 0.25, 0.9))


static func _vignette(game: Node, viewport: Vector2, col: Color, depth: float) -> void:
	var clear := Color(col.r, col.g, col.b, 0.0)
	var dx: float = viewport.x * depth
	var dy: float = viewport.y * depth
	var o := Vector2.ZERO
	var w := viewport
	game.draw_polygon(PackedVector2Array([o, Vector2(w.x, 0), Vector2(w.x - dx, dy), Vector2(dx, dy)]), PackedColorArray([col, col, clear, clear]))
	game.draw_polygon(PackedVector2Array([Vector2(0, w.y), Vector2(dx, w.y - dy), Vector2(w.x - dx, w.y - dy), w]), PackedColorArray([col, clear, clear, col]))
	game.draw_polygon(PackedVector2Array([o, Vector2(dx, dy), Vector2(dx, w.y - dy), Vector2(0, w.y)]), PackedColorArray([col, clear, clear, col]))
	game.draw_polygon(PackedVector2Array([Vector2(w.x, 0), Vector2(w.x, w.y), Vector2(w.x - dx, w.y - dy), Vector2(w.x - dx, dy)]), PackedColorArray([col, col, clear, clear]))


## Contador de compasso (4 pontos) e aviso do drop, acima dos botoes.
static func _draw_beat_hud(game: Node, viewport: Vector2) -> void:
	var beat: RTBaileBeatClock = game.baile_controller.beat
	var cx: float = viewport.x * 0.5
	var y: float = viewport.y * 0.85
	for i in range(4):
		var on: bool = beat.bar_beat() == i
		var p := Vector2(cx - 30.0 + 20.0 * i, y)
		game.draw_circle(p, 6.0 if on else 4.0, Color(PINK.r, PINK.g, PINK.b, 0.95 if on else 0.35))
	if beat.is_freeze():
		game.draw_string(ThemeDB.fallback_font, Vector2(cx - 22.0, y - 12.0), "DROP", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.9, 0.5))
