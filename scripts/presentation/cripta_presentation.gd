class_name RTCriptaPresentation
extends RefCounted

## Desenho da Cripta de Seda (RTCriptaController / RTBoss9Controller).
## Camadas: chao (pilastras, lamparinas, ecos, fios, sombras do teto),
## breu com cone de visao (grade de vertices) + sombras das pilastras, e por cima
## do breu so o que ela "sente": ondulacoes, olhos acesos, chamas, feixes da
## Matriarca, aviso pelas costas e o susto.
##
## Arte: res://assets/sprites/cripta/<nome>.png (tools/cripta_slice.py). Sem a arte,
## tools/cripta_slice.py --placeholders gera silhuetas provisorias.

const DIR := "res://assets/sprites/cripta/"
const DARK := 0.93
const DIM := 0.16
const CELL := 40.0
const SIZES := {
	"aranha_lobo": 72.0, "viuva_silencio": 100.0, "aranha_alcapao": 88.0, "aranha_saltadora": 78.0,
	"aranha_mimica": 70.0, "noiva_de_seda": 220.0, "filhote_aranha": 42.0, "olho_vigia": 50.0,
	"aranha_boleadeira": 82.0, "aranha_armadeira": 98.0,
}
const PREFIX := {
	"aranha_lobo": "s9_lobo", "viuva_silencio": "s9_viuva", "aranha_alcapao": "s9_alcapao", "aranha_saltadora": "s9_saltadora",
	"aranha_mimica": "s9_mimica", "noiva_de_seda": "s9_noiva", "filhote_aranha": "s9_filhote", "olho_vigia": "s9_olho",
	"aranha_boleadeira": "s9_boleadeira", "aranha_armadeira": "s9_armadeira",
}

static var _tex: Dictionary = {}
static var _grid_key := Vector2i.ZERO
static var _grid_idx := PackedInt32Array()


static func tex(name: String) -> Texture2D:
	if _tex.has(name):
		return _tex[name]
	var path: String = DIR + name + ".png"
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex[name] = t
	return t


static func frames(prefix: String, count: int) -> Array:
	var out: Array = []
	for i in range(count):
		var t := tex("%s_%d" % [prefix, i])
		if t != null:
			out.append(t)
	return out


# ============================================================ inimigos
static func enemy_draw_size(kind: String) -> Vector2:
	var s: float = float(SIZES.get(kind, 70.0))
	return Vector2(s, s)


## Quadro do bicho conforme o estado (cr_anim) do controlador.
static func enemy_texture(game: Node, enemy: Dictionary) -> Texture2D:
	var kind: String = String(enemy.get("type", ""))
	var prefix: String = String(PREFIX.get(kind, ""))
	if prefix == "":
		return null
	var anim: String = String(enemy.get("cr_anim", "walk"))
	var tt: float = float(game.time_alive) + float(enemy.get("uid", 0)) * 0.37
	if kind == "noiva_de_seda":
		var row := 0
		match anim:
			"cast": row = 1
			"veil": row = 2
		if float(enemy.get("hit_flash", 0.0)) > 0.0:
			row = 3
		return tex("%s_%d" % [prefix, row * 4 + int(tt * 6.0) % 4])
	var idx := int(tt * 6.0) % 2
	match anim:
		"attack", "emerge", "reveal":
			idx = 2 + int(tt * 8.0) % 2
		"crouch":
			idx = 2
		"leap", "recover":
			idx = 3
		"freeze":
			var f := tex(prefix + "_freeze")
			if f != null:
				return f
			idx = 0
		"buried":
			return tex("s9_alcapao_lid")
		"disguise":
			return tex("s9_echo_%d" % (int(tt * 4.0) % 4))
	var t := tex("%s_%d" % [prefix, idx])
	return t if t != null else tex("%s_0" % prefix)


static func boss_texture(game: Node) -> Texture2D:
	var info: Array = game.boss9_controller.frame_info()
	var t := tex("%s_%d" % [String(info[0]), int(info[1]) % 4])
	return t if t != null else tex("boss9_walk_0")


static func draw_boss(game: Node, camera: Vector2, boss_tex: Texture2D, pos: Vector2, size: Vector2, modulate: Color) -> void:
	var b: RTBoss9Controller = game.boss9_controller
	if b.height > 300.0:
		return  # no teto: so a sombra aparece
	var p: Vector2 = pos - camera - Vector2(0, b.height)
	var flip: bool = game.player_pos.x < pos.x
	if boss_tex != null:
		game._draw_entity_fit_flipped(boss_tex, p, size, flip, modulate, true)
	else:
		game.draw_circle(p, 80.0, Color(0.1, 0.06, 0.08))
		for k in range(8):
			game.draw_circle(p + Vector2(-42 + 12 * k, -30 - absf(3.5 - k) * 4.0), 5.0, Color(1.0, 0.15, 0.2))


# ============================================================ chao
static func draw_ground(game: Node, camera: Vector2) -> void:
	var c: RTCriptaController = game.cripta_controller
	var vp: Rect2 = Rect2(camera - Vector2(200, 200), game.get_viewport_rect().size + Vector2(400, 400))
	# Luz das lamparinas no chao.
	for l in c.lamps:
		var lp: Vector2 = l["pos"]
		if not vp.has_point(lp):
			continue
		var p: Vector2 = lp - camera
		var f: float = RTCriptaController.lamp_flicker(l)
		if f > 0.0:
			game.draw_circle(p, RTCriptaController.LAMP_RADIUS, Color(1.0, 0.8, 0.45, 0.10 * f))
			game.draw_arc(p, RTCriptaController.LAMP_RADIUS, 0.0, TAU, 48, Color(1.0, 0.82, 0.5, 0.35 * f), 2.0)
		var post := tex("s9_lamp_on" if f > 0.0 else "s9_lamp_off")
		if post != null:
			game._draw_entity_fit(post, p + Vector2(0, -47), Vector2(70, 110), Color.WHITE, true)
		else:
			game.draw_rect(Rect2(p + Vector2(-4, -60), Vector2(8, 60)), Color(0.22, 0.2, 0.2))
			game.draw_circle(p + Vector2(0, -66), 10.0, Color(1.0, 0.85, 0.45, 0.9) if f > 0.0 else Color(0.2, 0.2, 0.2))
	# Fios da Noiva.
	for th in c.threads:
		var a: Vector2 = Vector2(th["a"]) - camera
		var bb: Vector2 = Vector2(th["b"]) - camera
		var grow: float = clampf(float(th["t"]) / 0.6, 0.0, 1.0)
		game.draw_line(a, a.lerp(bb, grow), Color(0.92, 0.92, 1.0, 0.85), 3.0)
		game.draw_line(a, a.lerp(bb, grow), Color(1, 1, 1, 0.35), 7.0)
	# Pilastras.
	for pl in c.pillars:
		var pp: Vector2 = pl["pos"]
		if not vp.has_point(pp):
			continue
		var p2: Vector2 = pp - camera
		var r: float = pl["r"]
		var ptex := tex("s9_pillar_%d" % (int(pp.x + pp.y) % 2))
		game.draw_circle(p2 + Vector2(6, 10), r * 1.05, Color(0, 0, 0, 0.45))
		if ptex != null:
			# Base da pilastra (pe do sprite) sobre o circulo de colisao/sombra.
			game._draw_entity_fit(ptex, p2 + Vector2(0, -r * 1.9), Vector2(r * 2.6, r * 5.0), Color.WHITE, true)
		else:
			game.draw_circle(p2, r, Color(0.28, 0.27, 0.3))
			game.draw_circle(p2 + Vector2(-r * 0.25, -r * 0.25), r * 0.6, Color(0.38, 0.37, 0.4))
			game.draw_arc(p2, r, 0.0, TAU, 32, Color(0.1, 0.1, 0.12), 3.0)
	# Ecos de Luar.
	for e in c.echoes:
		var ep: Vector2 = Vector2(e["pos"]) - camera
		var et := tex("s9_echo_%d" % (int(float(e["t"]) * 4.0) % 4))
		if et != null:
			game._draw_entity_fit(et, ep, Vector2(48, 48), Color.WHITE)
		else:
			game.draw_circle(ep, 12.0, Color(0.7, 0.88, 1.0, 0.9))


# ============================================================ breu
static func draw_darkness(game: Node, viewport: Vector2, camera: Vector2) -> void:
	var c: RTCriptaController = game.cripta_controller
	var b: RTBoss9Controller = game.boss9_controller
	var nx: int = int(ceil(viewport.x / CELL)) + 1
	var ny: int = int(ceil(viewport.y / CELL)) + 1
	var key := Vector2i(nx, ny)
	if key != _grid_key:
		_grid_key = key
		_grid_idx = PackedInt32Array()
		for gy in range(ny - 1):
			for gx in range(nx - 1):
				var i: int = gy * nx + gx
				_grid_idx.append_array([i, i + 1, i + nx, i + 1, i + nx + 1, i + nx])
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	pts.resize(nx * ny)
	cols.resize(nx * ny)
	var eye: Vector2 = c.eye()
	var fa: float = c.facing.angle()
	var rng_mult: float = 0.62 if b.blackout > 0.0 else 1.0
	var cone_range: float = c.cone_range() * rng_mult
	var cone_half: float = c.cone_half()
	var aura: float = c.aura()
	var lamps: Array = []
	for l in c.lamps:
		var f: float = RTCriptaController.lamp_flicker(l)
		if f > 0.0:
			lamps.append([Vector2(l["pos"]), f])
	for gy in range(ny):
		for gx in range(nx):
			var sp := Vector2(minf(float(gx) * CELL, viewport.x), minf(float(gy) * CELL, viewport.y))
			var w: Vector2 = sp + camera
			var d: Vector2 = w - eye
			var dist: float = d.length()
			var vis: float = 1.0 - smoothstep(aura - 30.0, aura + 40.0, dist)
			if dist < cone_range + 10.0:
				var da: float = absf(wrapf(d.angle() - fa, -PI, PI))
				var cone: float = (1.0 - smoothstep(cone_half - 0.06, cone_half + 0.16, da)) * (1.0 - smoothstep(cone_range - 170.0, cone_range, dist))
				vis = maxf(vis, cone)
			for lf in lamps:
				var ld: float = w.distance_to(lf[0])
				if ld < RTCriptaController.LAMP_RADIUS:
					vis = maxf(vis, float(lf[1]) * (1.0 - smoothstep(RTCriptaController.LAMP_RADIUS * 0.55, RTCriptaController.LAMP_RADIUS, ld)))
			var i: int = gy * nx + gx
			pts[i] = sp
			cols[i] = Color(0.0, 0.0, 0.015, DIM + (DARK - DIM) * (1.0 - vis))
	RenderingServer.canvas_item_add_triangle_array(game.get_canvas_item(), _grid_idx, pts, cols)
	# Sombras das pilastras (atras delas ela nao ve).
	for pl in c.pillars:
		var cp: Vector2 = pl["pos"]
		var to: Vector2 = cp - eye
		var dd: float = to.length()
		if dd > cone_range + 120.0 or dd < float(pl["r"]) + 4.0:
			continue
		var rr: float = float(pl["r"]) * 0.85
		var half: float = asin(clampf(rr / dd, 0.0, 1.0))
		var base: float = to.angle()
		var t1: Vector2 = eye + Vector2.from_angle(base - half) * sqrt(maxf(0.0, dd * dd - rr * rr))
		var t2: Vector2 = eye + Vector2.from_angle(base + half) * sqrt(maxf(0.0, dd * dd - rr * rr))
		var far: float = 1600.0
		var poly := PackedVector2Array([t1 - camera, t2 - camera, eye + Vector2.from_angle(base + half) * far - camera, eye + Vector2.from_angle(base - half) * far - camera])
		game.draw_colored_polygon(poly, Color(0.0, 0.0, 0.015, 0.86))


# ============================================================ por cima do breu
static func draw_screen(game: Node, viewport: Vector2, camera: Vector2) -> void:
	var c: RTCriptaController = game.cripta_controller
	draw_darkness(game, viewport, camera)
	# Ondulacoes: algo se mexeu no escuro.
	for rp in c.ripples:
		var u: float = float(rp["t"]) / RTCriptaController.RIPPLE_LIFE
		var p: Vector2 = Vector2(rp["pos"]) - camera
		var a: float = (1.0 - u) * 0.55 * float(rp.get("s", 1.0))
		game.draw_arc(p, 8.0 + 46.0 * u, 0.0, TAU, 24, Color(0.75, 0.82, 0.95, a), 2.0)
		game.draw_arc(p, 4.0 + 26.0 * u, 0.0, TAU, 16, Color(0.75, 0.82, 0.95, a * 0.6), 1.5)
	# Chamas das lamparinas acesas: faroes no escuro.
	for l in c.lamps:
		var f: float = RTCriptaController.lamp_flicker(l)
		if f > 0.0:
			var lp: Vector2 = Vector2(l["pos"]) - camera + Vector2(0, -66)
			game.draw_circle(lp, 16.0 * f, Color(1.0, 0.75, 0.35, 0.25 * f))
			game.draw_circle(lp, 6.0, Color(1.0, 0.92, 0.6, f))
	# Ecos e mimicas: o brilho atravessa o escuro (a mimica pisca torto).
	for e in c.echoes:
		_glow(game, Vector2(e["pos"]) - camera, 0.45 + 0.15 * sin(float(e["t"]) * 3.0))
	for en in game.enemies:
		var kind: String = String(en.get("type", ""))
		var ep: Vector2 = Vector2(en["pos"]) - camera
		if kind == RTCriptaController.MIMICA and String(en.get("cr_state", "")) == "disguise":
			var tt: float = float(game.time_alive) + float(en.get("uid", 0))
			var stutter: float = 1.0 if fmod(tt * 1.7, 2.3) > 0.25 else 0.3
			_glow(game, ep, (0.45 + 0.15 * sin(tt * 3.0)) * stutter)
		elif kind == RTCriptaController.SALTADORA and String(en.get("cr_state", "")) == "crouch":
			# Olhos acesos: o aviso do pulo aparece mesmo no breu.
			for k in range(4):
				game.draw_circle(ep + Vector2(-9 + 6 * k, -18), 2.6, Color(1.0, 0.2, 0.2, 0.95))
			game.draw_circle(ep + Vector2(0, -18), 18.0, Color(1.0, 0.1, 0.1, 0.12))
		elif kind == RTCriptaController.SALTADORA and String(en.get("cr_state", "")) == "air":
			var to: Vector2 = Vector2(en.get("leap_to", en["pos"])) - camera
			game.draw_arc(to, RTCriptaController.SALTA_LAND_R, 0.0, TAU, 32, Color(1.0, 0.25, 0.25, 0.8), 2.0)
		elif kind == RTCriptaController.OLHO:
			var sees: bool = game.boss9_controller.watcher_sees(en)
			game.draw_circle(ep, 10.0, Color(1.0, 0.2, 0.25, 0.9 if sees else 0.5))
			if sees:
				game.draw_line(ep, game.player_pos - camera, Color(1.0, 0.2, 0.25, 0.25), 2.0)
	# Teias voando.
	for w in c.webs:
		if String(w["kind"]) == "bola":
			continue  # desenhada em _draw_grapple (com a linha ate a dona)
		var wp: Vector2 = Vector2(w["p"]) - camera
		var col: Color = Color(0.95, 0.95, 1.0, 0.9) if String(w["kind"]) == "teia" else Color(0.55, 1.0, 0.4, 0.9)
		game.draw_circle(wp, float(w["r"]), Color(col, 0.25))
		game.draw_arc(wp, float(w["r"]) * 0.8, 0.0, TAU, 12, col, 2.0)
	_draw_grapple(game, viewport, camera)
	_draw_boss_overlay(game, viewport, camera)
	# Bonus de visao dos Ecos: losangos (quantos) e barra (quanto tempo falta).
	if c.sight_stacks > 0:
		var pp: Vector2 = game.player_pos - camera + Vector2(0, 54)
		var left: float = clampf(c.sight_timer / RTCriptaController.SIGHT_TIME, 0.0, 1.0)
		var blink: float = 1.0 if left > 0.25 else 0.45 + 0.55 * absf(sin(float(game.time_alive) * 14.0))
		for k in range(c.sight_stacks):
			var dp: Vector2 = pp + Vector2((float(k) - float(c.sight_stacks - 1) * 0.5) * 13.0, 0.0)
			game.draw_colored_polygon(PackedVector2Array([dp + Vector2(0, -6), dp + Vector2(4, 0), dp + Vector2(0, 6), dp + Vector2(-4, 0)]), Color(0.75, 0.92, 1.0, 0.9 * blink))
		game.draw_line(pp + Vector2(-30, 11), pp + Vector2(-30 + 60.0 * left, 11), Color(0.75, 0.92, 1.0, 0.75 * blink), 2.0)
	# Aviso pelas costas: borda vermelha do lado do perigo + coracao.
	if c.threat_level > 0.05:
		var side: Vector2 = c.threat_side
		var center: Vector2 = viewport * 0.5 + side * minf(viewport.x, viewport.y) * 0.46
		var beat: float = 0.6 + 0.4 * absf(sin(float(game.time_alive) * (6.0 + 6.0 * c.threat_level)))
		for k in range(4):
			game.draw_circle(center, 90.0 + 40.0 * k, Color(0.8, 0.0, 0.05, 0.06 * c.threat_level * beat))
	# Susto.
	if not c.scare.is_empty():
		_draw_scare(game, viewport, c.scare)


static func _glow(game: Node, p: Vector2, a: float) -> void:
	game.draw_circle(p, 20.0, Color(0.6, 0.85, 1.0, 0.18 * a))
	game.draw_circle(p, 8.0, Color(0.8, 0.95, 1.0, 0.7 * a))


static func _draw_boss_overlay(game: Node, viewport: Vector2, camera: Vector2) -> void:
	if int(game.current_phase) != RTCriptaController.PHASE or not game.boss_active:
		return
	var b: RTBoss9Controller = game.boss9_controller
	if b.mode == "olhar":
		var e: Vector2 = b.eye_pos() - camera
		for d in b.beam_dirs():
			var dir: Vector2 = d
			var poly := PackedVector2Array([e, e + dir.rotated(-RTBoss9Controller.BEAM_HALF) * RTBoss9Controller.BEAM_RANGE, e + dir.rotated(RTBoss9Controller.BEAM_HALF) * RTBoss9Controller.BEAM_RANGE])
			game.draw_colored_polygon(poly, Color(1.0, 0.1, 0.15, 0.16 + 0.3 * clampf(b.spot / RTBoss9Controller.SPOT_TIME, 0.0, 1.0)))
		for k in range(8):
			game.draw_circle(e + Vector2(-28 + 8 * k, -absf(3.5 - k) * 3.0), 3.0, Color(1.0, 0.2, 0.25))
	if b.mode == "ambush_warn":
		_draw_ambush_warning(game, viewport, camera, b)
	if b.mode == "pounce_warn":
		var tp: Vector2 = b.pounce_to - camera
		var u: float = clampf(b.t / RTBoss9Controller.POUNCE_WARN, 0.0, 1.0)
		game.draw_circle(tp, RTBoss9Controller.POUNCE_RADIUS * u, Color(1.0, 0.1, 0.15, 0.25))
		game.draw_arc(tp, RTBoss9Controller.POUNCE_RADIUS, 0.0, TAU, 40, Color(1.0, 0.25, 0.3, 0.9), 3.0)
	var sh: Dictionary = b.ceiling_shadow()
	if not sh.is_empty():
		var sp: Vector2 = Vector2(sh["pos"]) - camera
		var r: float = RTBoss9Controller.DROP_RADIUS * (0.4 + 0.6 * float(sh["u"]))
		game.draw_circle(sp, r, Color(0.0, 0.0, 0.0, 0.55))
		game.draw_arc(sp, RTBoss9Controller.DROP_RADIUS, 0.0, TAU, 40, Color(1.0, 0.2, 0.25, 0.95 if bool(sh["lock"]) else 0.5), 3.0)
		for k in range(8):
			game.draw_circle(sp + Vector2(-28 + 8 * k, -10 - absf(3.5 - k) * 3.0), 2.5, Color(1.0, 0.2, 0.25, 0.8))
	for egg in b.eggs:
		var ep: Vector2 = Vector2(egg["pos"]) - camera
		var u2: float = clampf(float(egg["t"]) / float(egg["fall"]), 0.0, 1.0)
		game.draw_circle(ep, 10.0 + 18.0 * u2, Color(0, 0, 0, 0.45))
		game.draw_arc(ep, 28.0, 0.0, TAU, 24, Color(0.95, 0.92, 0.85, 0.7), 2.0)
	if b.blackout > 0.0:
		game._draw_centered("APAGÃO — ESCUTE AS ONDAS", Vector2(viewport.x * 0.5, 176), 18, Color(1.0, 0.35, 0.4, 0.9))


# ============================================================ laco, casulo, veneno
static func _peer_pos(game: Node, peer: int) -> Vector2:
	if peer == 0 or peer == int(game._mp_unique_id()) or not game.is_multiplayer:
		return game.player_pos
	var st: Dictionary = game.net_players_by_peer.get(peer, {})
	return Vector2(st.get("render_pos", st.get("pos", game.player_pos)))


static func _silk(game: Node, a: Vector2, b: Vector2, k: float = 1.0) -> void:
	game.draw_line(a, b, Color(1, 1, 1, 0.22 * k), 6.0)
	game.draw_line(a, b, Color(0.95, 0.95, 1.0, 0.9 * k), 2.0)


## O casulo da arte ja traz a Geovana dentro (o sprite normal dela some nessa hora).
static func hides_player(game: Node) -> bool:
	if int(game.current_phase) != RTCriptaController.PHASE or game._merchant_dimension().active:
		return false
	var g: RTCriptaGrapple = game.cripta_controller.grapple
	return g.held() and String(g.grab["kind"]) == "cocoon" and game.active_character_key == game.CHARACTER_GEOVANA and tex("s9_casulo_0") != null


static func _draw_cocoon(game: Node, foot: Vector2, wrap: float, wiggle: float) -> void:
	# 0-2 enrolando; 3 = casulo rachando (aparece quando ela se debate).
	var idx: int = clampi(int(wrap * 3.0), 0, 2) if wrap < 1.0 else (3 if wiggle > 0.15 else 2)
	var t := tex("s9_casulo_%d" % idx)
	var shake := Vector2(sin(float(game.time_alive) * 60.0) * 3.0 * wiggle, 0.0)
	if t != null:
		game._draw_entity_fit(t, foot + shake + Vector2(0, -2), Vector2(58, 87), Color.WHITE, true)
	else:
		var h: float = 30.0 + 60.0 * clampf(wrap, 0.0, 1.0)
		game.draw_rect(Rect2(foot + shake + Vector2(-24, -h), Vector2(48, h)), Color(0.93, 0.93, 0.98, 0.92))
		for k in range(int(h / 9.0)):
			game.draw_line(foot + shake + Vector2(-24, -6 - k * 9), foot + shake + Vector2(24, -2 - k * 9), Color(0.7, 0.7, 0.78), 1.5)


static func _draw_grapple(game: Node, viewport: Vector2, camera: Vector2) -> void:
	var c: RTCriptaController = game.cripta_controller
	var g: RTCriptaGrapple = c.grapple
	var now: float = float(game.time_alive)
	for en in game.enemies:
		var kind: String = String(en.get("type", ""))
		if not g.owns_kind(kind):
			continue
		var st: String = String(en.get("cr_state", ""))
		var ep: Vector2 = Vector2(en["pos"]) - camera
		var gp: int = int(en.get("gp", 0))
		if kind == RTCriptaGrapple.BOLEADEIRA and st == "spin":
			# A bola girando brilha verde no escuro: e o aviso do arremesso.
			if tex("s9_boleadeira_2") != null:
				# A arte ja tem a bola girando; aqui so o brilho que fura o breu.
				var gk: float = 0.6 + 0.4 * absf(sin(now * 9.0))
				game.draw_circle(ep + Vector2(0, -34), 34.0, Color(0.5, 1.0, 0.45, 0.10 * gk))
				game.draw_circle(ep + Vector2(0, -34), 14.0, Color(0.6, 1.0, 0.5, 0.22 * gk))
			else:
				var a: float = now * 14.0
				var bp: Vector2 = ep + Vector2(0, -20) + Vector2.from_angle(a) * 26.0
				_silk(game, ep + Vector2(0, -20), bp, 0.7)
				game.draw_circle(bp, 16.0, Color(0.5, 1.0, 0.45, 0.18))
				game.draw_circle(bp, 8.0, Color(0.7, 1.0, 0.6, 0.95))
		elif st == "drag" and gp != 0:
			_silk(game, ep + Vector2(0, -12), _peer_pos(game, gp) - camera + Vector2(0, -6))
		elif kind == RTCriptaGrapple.ARMADEIRA and st == "rear":
			for k in range(4):
				game.draw_circle(ep + Vector2(-9 + 6 * k, -24), 2.8, Color(1.0, 0.18, 0.15, 0.95))
			game.draw_circle(ep + Vector2(0, -24), 20.0, Color(1.0, 0.1, 0.1, 0.14))
		elif kind == RTCriptaGrapple.ARMADEIRA and st == "weave" and gp != 0:
			# Anel de seda se fechando em volta da presa.
			var tp: Vector2 = _peer_pos(game, gp) - camera + Vector2(0, -20)
			var u: float = clampf(float(en.get("cr_t", 0.0)) / RTCriptaGrapple.WEAVE_TIME, 0.0, 1.0)
			var r: float = lerpf(RTCriptaGrapple.WEAVE_RADIUS, 40.0, u)
			game.draw_arc(tp, r, 0.0, TAU, 36, Color(0.95, 0.95, 1.0, 0.45 + 0.5 * u), 2.0 + 3.0 * u)
			for k in range(6):
				var aa: float = TAU * float(k) / 6.0 + now * 3.0
				_silk(game, tp + Vector2.from_angle(aa) * r, tp + Vector2.from_angle(aa + 1.4) * r, 0.5 + 0.5 * u)
		elif st == "guard" and gp != 0 and gp != int(game._mp_unique_id()):
			var rp: Vector2 = _peer_pos(game, gp)
			if c.visible(rp):
				_draw_cocoon(game, rp - camera + Vector2(0, 40), 1.0, 0.0)
	# Bola de seda voando, ligada a dona por um fio.
	for w in c.webs:
		if String(w["kind"]) != "bola":
			continue
		var wp: Vector2 = Vector2(w["p"]) - camera
		for en2 in game.enemies:
			if int(en2.get("uid", -1)) == int(w.get("owner", -2)):
				_silk(game, Vector2(en2["pos"]) - camera + Vector2(0, -16), wp, 0.6)
		var bt := tex("s9_bola_%d" % (int(now * 10.0) % 2))
		if bt != null:
			game._draw_entity_fit(bt, wp, Vector2(36, 36), Color.WHITE)
		else:
			game.draw_circle(wp, 15.0, Color(0.5, 1.0, 0.45, 0.25))
			game.draw_circle(wp, 9.0, Color(0.75, 1.0, 0.65, 0.95))
	# Este jogador preso: casulo por cima e a "luta" (apertar o disparo).
	if g.held():
		var foot: Vector2 = game.player_pos - camera + Vector2(0, 40)
		if String(g.grab["kind"]) == "cocoon":
			_draw_cocoon(game, foot, clampf(float(g.grab["t"]) / 0.35, 0.0, 1.0), g.press_flash)
		_draw_struggle(game, viewport, camera, g)
	# Seda estourando quando ela se solta.
	if g.burst > 0.0:
		var bk: float = g.burst / 0.45
		var bt2 := tex("s9_seda_rompida")
		var bc: Vector2 = game.player_pos - camera + Vector2(0, -20)
		if bt2 != null:
			game._draw_entity_fit(bt2, bc, Vector2.ONE * (90.0 + 80.0 * (1.0 - bk)), Color(1, 1, 1, bk))
		else:
			for k in range(10):
				var aa2: float = TAU * float(k) / 10.0
				game.draw_line(bc + Vector2.from_angle(aa2) * 14.0, bc + Vector2.from_angle(aa2) * (30.0 + 60.0 * (1.0 - bk)), Color(0.95, 0.95, 1.0, bk), 2.0)
	# Veneno: bordas verdes pulsando (mais forte por carga).
	if g.poison_stacks > 0:
		var pulse: float = 0.7 + 0.3 * absf(sin(now * 3.0))
		var a2: float = 0.07 * float(g.poison_stacks) * pulse
		for k in range(3):
			var m: float = 26.0 * float(k + 1)
			game.draw_rect(Rect2(Vector2.ZERO, Vector2(viewport.x, m)), Color(0.25, 0.9, 0.2, a2 * 0.5))
			game.draw_rect(Rect2(Vector2(0, viewport.y - m), Vector2(viewport.x, m)), Color(0.25, 0.9, 0.2, a2 * 0.5))
			game.draw_rect(Rect2(Vector2.ZERO, Vector2(m, viewport.y)), Color(0.25, 0.9, 0.2, a2 * 0.5))
			game.draw_rect(Rect2(Vector2(viewport.x - m, 0), Vector2(m, viewport.y)), Color(0.25, 0.9, 0.2, a2 * 0.5))
		var pp: Vector2 = game.player_pos - camera + Vector2(-40, -66)
		var vt := tex("s9_veneno")
		for k in range(g.poison_stacks):
			if vt != null:
				game._draw_entity_fit(vt, pp + Vector2(k * 14, 0), Vector2(14, 14), Color.WHITE)
			else:
				game.draw_circle(pp + Vector2(k * 12, 0), 4.5, Color(0.45, 1.0, 0.35, 0.95))


## Barra da luta: anel de progresso + "ATK!" pulsando + brilho no botao de disparo.
static func _draw_struggle(game: Node, viewport: Vector2, camera: Vector2, g: RTCriptaGrapple) -> void:
	var center: Vector2 = game.player_pos - camera + Vector2(0, -66)
	var prog: float = clampf(float(g.grab["progress"]), 0.0, 1.0)
	var pulse: float = 0.6 + 0.4 * absf(sin(float(game.time_alive) * 12.0))
	var big: float = 1.0 + 0.25 * g.press_flash
	game.draw_circle(center, 22.0 * big, Color(0.05, 0.03, 0.08, 0.75))
	game.draw_arc(center, 22.0 * big, -PI * 0.5, -PI * 0.5 + TAU * prog, 40, Color(1.0, 0.85, 0.3, 0.95), 5.0)
	var label: String = "ATK!" if not game._uses_desktop_ui() else String(game._tutorial_guide().key("attack"))
	game._draw_centered(label, center + Vector2(0, 6), 15, Color(1.0, 1.0, 1.0, pulse))
	game._draw_centered("APERTE PARA SE SOLTAR", center + Vector2(0, -32), 13, Color(1.0, 0.9, 0.7, 0.85))
	var btn = game.buttons.get("attack", null)
	if btn is Rect2 and not game._uses_desktop_ui():
		var r: Rect2 = btn
		game.draw_arc(r.get_center(), maxf(r.size.x, r.size.y) * 0.62 * big, 0.0, TAU, 40, Color(1.0, 0.85, 0.3, 0.9 * pulse), 4.0)


## Aviso da espreita: seta vermelha em volta do jogador apontando de onde ela
## vem + brilho na borda da tela daquele lado. Forte para o alvo, fraco para os
## outros (eles tambem podem avisar/ajudar).
static func _draw_ambush_warning(game: Node, viewport: Vector2, camera: Vector2, b: RTBoss9Controller) -> void:
	var me: bool = not game.is_multiplayer or b.ambush_peer == int(game._mp_unique_id())
	var u: float = clampf(b.t / RTBoss9Controller.AMBUSH_WARN, 0.0, 1.0)
	var pulse: float = 0.65 + 0.35 * absf(sin(u * PI * 4.0))
	var k: float = (1.0 if me else 0.45) * pulse
	var pp: Vector2 = game.player_pos - camera + Vector2(0, -20)
	var dir: Vector2 = b.ambush_dir_from(game.player_pos)
	var tip: Vector2 = pp + dir * (62.0 + 10.0 * u)
	var side: Vector2 = dir.orthogonal()
	game.draw_colored_polygon(PackedVector2Array([tip, tip - dir * 26.0 + side * 15.0, tip - dir * 16.0, tip - dir * 26.0 - side * 15.0]), Color(1.0, 0.15, 0.2, 0.95 * k))
	game.draw_arc(pp, 62.0, dir.angle() - 0.5, dir.angle() + 0.5, 16, Color(1.0, 0.2, 0.25, 0.8 * k), 4.0)
	# Borda da tela do lado de onde ela vem.
	var center: Vector2 = viewport * 0.5 + dir * minf(viewport.x, viewport.y) * 0.5
	for i in range(3):
		game.draw_circle(center, 120.0 + 60.0 * i, Color(1.0, 0.05, 0.1, 0.10 * k))
	if me:
		game._draw_centered("!", tip + dir * 18.0 + Vector2(0, 8), 30, Color(1.0, 0.85, 0.85, k))


static func _draw_scare(game: Node, viewport: Vector2, s: Dictionary) -> void:
	var t: float = float(s["t"])
	var a: float = clampf(t / 0.06, 0.0, 1.0) * clampf((0.9 - t) / 0.4, 0.0, 1.0)
	if a <= 0.0:
		return
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.25, 0.0, 0.02, 0.35 * a))
	var face := tex("s9_scare_" + String(s.get("kind", "")).replace("aranha_", "").replace("_silencio", "").replace("noiva_de_seda", "noiva"))
	var scale: float = 1.25 - 0.25 * clampf(t / 0.12, 0.0, 1.0)
	var size: float = minf(viewport.x, viewport.y) * 0.9 * scale
	var center: Vector2 = viewport * 0.5 + Vector2(s.get("side", Vector2.ZERO)) * viewport.x * 0.12 + Vector2(sin(t * 80.0) * 6.0, cos(t * 70.0) * 6.0)
	if face != null:
		var fs: Vector2 = face.get_size()
		var k: float = size / maxf(fs.x, fs.y)
		game.draw_texture_rect(face, Rect2(center - fs * k * 0.5, fs * k), false, Color(1, 1, 1, a))
	else:
		game.draw_circle(center, size * 0.32, Color(0.05, 0.02, 0.03, a))
		for k2 in range(8):
			var ex: Vector2 = center + Vector2(-size * 0.2 + size * 0.055 * k2, -size * 0.06 - absf(3.5 - k2) * size * 0.015)
			game.draw_circle(ex, size * 0.03, Color(1.0, 0.1, 0.15, a))
			game.draw_circle(ex + Vector2(-2, -2), size * 0.01, Color(1, 1, 1, a))
