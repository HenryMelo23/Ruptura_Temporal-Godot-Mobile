class_name RTParasiticaPresentation
extends RefCounted

## Visuais da Parasitica nova: simbionte preso a Geovana, Verme-Rei, hospedeiros
## (larvas visiveis / Hospedeiro Maduro) e indicadores de HUD.
## Paleta D37: quitina terrosa, carne verde infecciosa e ambar.

const CHITIN := Color(0.16, 0.11, 0.06)
const CHITIN_LIGHT := Color(0.36, 0.26, 0.12)
const FLESH := Color(0.4, 0.6, 0.16)
const FLESH_LIGHT := Color(0.7, 0.9, 0.3)
const AMBER := Color(1.0, 0.7, 0.2)
const BILE := Color(0.62, 1.0, 0.28)


static func _ctl(game: Node2D) -> RTParasiticaController:
	return game._parasitica()


# ================================================================ mundo
static func draw_world(game: Node2D, camera: Vector2) -> void:
	if game.manifestation_key != "parasitica":
		return
	draw_hosts(game, camera)
	var ctl := _ctl(game)
	for event in ctl.events:
		_draw_event(game, event, camera)
	if ctl.king_active():
		draw_king(game, ctl.king, camera, ctl.visual_level(), game.time_alive)


## Larvas por alvo (pips) e coroa de espinhos ambar no Hospedeiro Maduro.
static func draw_hosts(game: Node2D, camera: Vector2) -> void:
	var low: bool = bool(game.gfx_low_resource)
	for enemy in game.enemies:
		var seeds: int = int(enemy.get("seeds", 0))
		if seeds <= 0 or float(enemy.get("parasite_mark_time", 0.0)) <= 0.0 or float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var r: float = game._enemy_radius(enemy)
		_draw_host_overlay(game, Vector2(enemy["pos"]) - camera, r, seeds, int(enemy.get("uid", 0)), float(enemy.get("parasite_mark_time", 0.0)), low)
	if game.boss_active and game.boss_hp > 0.0 and game.boss_parasite_mark_time > 0.0 and game.boss_parasite_seeds > 0:
		_draw_host_overlay(game, game.boss_pos - camera, game._boss_hit_radius(), int(game.boss_parasite_seeds), -9173, game.boss_parasite_mark_time, low)
	if game._arauto_active() and float(game.arauto.get("parasite_mark_time", 0.0)) > 0.0 and int(game.arauto.get("seeds", 0)) > 0:
		_draw_host_overlay(game, Vector2(game.arauto["pos"]) - camera, 58.0, int(game.arauto.get("seeds", 0)), -8121, float(game.arauto.get("parasite_mark_time", 0.0)), low)


static func _draw_host_overlay(game: Node2D, center: Vector2, radius: float, seeds: int, uid: int, mark: float, low: bool) -> void:
	var t: float = game.time_alive
	var fade: float = clampf(mark / 1.2, 0.35, 1.0)
	# Pips de larva: um arco curto acima da cabeca, sempre legivel.
	var pip_y: float = -radius - 18.0
	var spacing: float = 11.0
	var start_x: float = -spacing * 2.0
	for i in range(5):
		var p: Vector2 = center + Vector2(start_x + spacing * float(i), pip_y + absf(float(i) - 2.0) * 2.0)
		var filled: bool = i < seeds
		if filled:
			var wiggle: float = sin(t * 9.0 + float(i) * 1.3 + uid * 0.01) * 1.2
			game.draw_circle(p, 4.6, Color(0.05, 0.06, 0.02, 0.85 * fade))
			game.draw_circle(p + Vector2(0, wiggle), 3.4, Color(FLESH_LIGHT.r, FLESH_LIGHT.g, FLESH_LIGHT.b, 0.95 * fade))
			game.draw_circle(p + Vector2(-0.9, wiggle - 1.0), 1.1, Color(1.0, 1.0, 0.8, 0.8 * fade))
		else:
			game.draw_arc(p, 3.4, 0.0, TAU, 10, Color(0.4, 0.5, 0.2, 0.42 * fade), 1.2)
	if seeds < 5:
		return
	# Hospedeiro Maduro: espinhos ambar pulsando na base, sem cobrir o corpo.
	var pulse: float = 0.5 + 0.5 * sin(t * 6.0 + uid * 0.03)
	var spikes: int = 7 if low else 11
	for i in range(spikes):
		var a: float = TAU * float(i) / float(spikes) + t * 0.35
		var base: Vector2 = center + Vector2(cos(a), sin(a) * 0.45) * (radius * 0.95)
		var tip: Vector2 = base + Vector2(cos(a), sin(a) * 0.45) * (8.0 + pulse * 7.0) + Vector2(0, -4.0)
		game.draw_line(base, tip, Color(AMBER.r, AMBER.g, AMBER.b, 0.75), 2.4, true)
		game.draw_circle(tip, 1.6, Color(1.0, 0.95, 0.6, 0.9))
	game.draw_set_transform(center + Vector2(0, radius * 0.35), 0.0, Vector2(1.0, 0.42))
	game.draw_arc(Vector2.ZERO, radius * 1.05 + pulse * 4.0, 0.0, TAU, 30, Color(1.0, 0.62, 0.16, 0.55), 2.6, true)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	game._draw_centered_outlined("MADURO", center + Vector2(0, pip_y - 12.0), 11, Color(1.0, 0.78, 0.3), Color(0, 0, 0, 0.85), 3)


# ================================================================ verme-rei
static func draw_king(game: Node2D, king: Dictionary, camera: Vector2, level: float, t: float) -> void:
	var low: bool = bool(game.gfx_low_resource)
	var hole: Vector2 = Vector2(king.get("pos", game.player_pos)) - camera
	var state: String = String(king.get("state", "attack"))
	var st: float = float(king.get("state_t", 0.0))
	var perfect: bool = bool(king.get("perfect", false))
	var facing: float = float(king.get("facing", 1.0))
	var seed: float = float(int(king.get("seed", 0)) % 997)
	# Rastro de terra revolvida.
	var trail: Array = king.get("trail", [])
	if trail.size() >= 2:
		for i in range(1, trail.size()):
			var a: Vector2 = Vector2(trail[i - 1]) - camera
			var b: Vector2 = Vector2(trail[i]) - camera
			var k: float = float(i) / float(trail.size())
			game.draw_line(a, b, Color(0.12, 0.08, 0.04, 0.42 * k), 13.0 * level * k + 3.0, true)
			game.draw_line(a, b, Color(0.42, 0.3, 0.14, 0.38 * k), 3.0, true)
	# Quanto do corpo esta fora do chao.
	var exposure := 1.0
	match state:
		"emerge":
			exposure = clampf(st / RTParasiticaController.KING_EMERGE_TIME, 0.0, 1.0)
		"resurface":
			exposure = clampf(st / RTParasiticaController.KING_RESURFACE_TIME, 0.0, 1.0)
		"burrow":
			exposure = 1.0 - clampf(st / RTParasiticaController.KING_BURROW_TIME, 0.0, 1.0)
		"leave":
			exposure = 1.0 - clampf(st / RTParasiticaController.KING_LEAVE_TIME, 0.0, 1.0)
		"tunnel":
			exposure = 0.0
		"follow":
			exposure = 0.18
	exposure = 1.0 - pow(1.0 - exposure, 2.0)
	_draw_burrow_mound(game, hole, level, t, seed, state == "tunnel" or state == "follow", perfect)
	if exposure <= 0.02:
		return
	var bite: float = clampf(float(king.get("bite", 0.0)) / 0.22, 0.0, 1.0)
	var devour: float = clampf(float(king.get("devour", 0.0)) / 0.5, 0.0, 1.0)
	var height: float = (104.0 + 30.0 * (level - 1.0)) * exposure
	var sway: float = sin(t * 2.4 + seed) * 8.0
	var lunge: float = (bite * 26.0 + devour * 40.0)
	# O corpo sobe do buraco em S e a cabeca inclina para o alvo.
	var head: Vector2 = hole + Vector2(facing * (34.0 + lunge) + sway, -height + devour * 14.0)
	var c1: Vector2 = hole + Vector2(-facing * 26.0 + sway * 0.3, -height * 0.34)
	var c2: Vector2 = hole + Vector2(-facing * 6.0 + sway * 0.7, -height * 0.86)
	var segments: int = 8 if low else 13
	var thick: float = 15.0 * level
	var pts: Array = []
	for i in range(segments + 1):
		pts.append(_bezier(hole, c1, c2, head, float(i) / float(segments)))
	game.draw_set_transform(hole + Vector2(facing * 10.0, 6), 0.0, Vector2(1.0, 0.34))
	game.draw_circle(Vector2.ZERO, thick * 2.2, Color(0, 0, 0, 0.38 * exposure))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var line := PackedVector2Array()
	for p in pts:
		line.append(p)
	# Contorno + barriga de carne do lado do alvo.
	game.draw_polyline(line, Color(0.03, 0.02, 0.01, 0.95), thick * 2.35, true)
	var belly := PackedVector2Array()
	for i in range(pts.size()):
		belly.append(Vector2(pts[i]) + Vector2(facing * thick * 0.42, thick * 0.1))
	game.draw_polyline(belly, Color(0.5, 0.36, 0.22, 1.0), thick * 1.2, true)
	game.draw_polyline(belly, Color(0.62, 0.74, 0.3, 0.55), thick * 0.5, true)
	# Placas de quitina: do buraco para a cabeca, cada uma com crista clara,
	# costura de carne verde e espinho dorsal.
	for i in range(segments + 1):
		var u: float = float(i) / float(segments)
		var p: Vector2 = pts[i]
		var nxt: Vector2 = pts[mini(i + 1, segments)] if i < segments else p + (p - Vector2(pts[i - 1]))
		var along: Vector2 = (nxt - p).normalized()
		if along.length() < 0.1:
			along = Vector2.UP
		var normal: Vector2 = along.orthogonal() * -facing
		var w: float = thick * lerpf(1.1, 0.86, u)
		var plate_col: Color = CHITIN if i % 2 == 0 else Color(0.22, 0.15, 0.07)
		var pulse: float = 0.5 + 0.5 * sin(t * 7.0 - u * 6.0 + seed)
		game.draw_circle(p - normal * w * 0.12, w * 0.98, plate_col)
		game.draw_arc(p - normal * w * 0.12, w * 0.98, normal.angle() + PI - 1.1, normal.angle() + PI + 1.1, 10, Color(0.5, 0.38, 0.2, 0.95), 2.6)
		if not low:
			game.draw_arc(p, w * 0.98, normal.angle() - 0.9, normal.angle() + 0.9, 8, Color(BILE.r, BILE.g, BILE.b, 0.22 + 0.25 * pulse), 1.6)
		if i % 2 == 1 and u < 0.92:
			var spine_base: Vector2 = p - normal * w * 0.9
			var spine_tip: Vector2 = spine_base - normal * (8.0 + 4.0 * level) - along * 6.0
			var spine := PackedVector2Array([spine_base + along * 4.0, spine_tip, spine_base - along * 4.0])
			game.draw_colored_polygon(spine, AMBER if perfect else Color(0.58, 0.46, 0.26))
		if i % 3 == 0 and not low and u > 0.1:
			game.draw_circle(p + normal * w * 0.55, 2.4 + pulse * 1.2, Color(0.72, 1.0, 0.32, 0.55 + 0.35 * pulse))
	# Raizes que agarram a borda do buraco.
	for i in range(4 if low else 7):
		var a: float = PI + float(i) * PI / 6.0 + 0.15
		var root_a: Vector2 = hole + Vector2(cos(a) * thick * 1.15, 2.0)
		var root_b: Vector2 = root_a + Vector2(cos(a) * 20.0, sin(t * 3.0 + float(i)) * 3.0 + 7.0)
		game.draw_line(root_a, root_b, Color(0.3, 0.2, 0.08, 0.9 * exposure), 3.2, true)
		game.draw_line(root_b, root_b + Vector2(cos(a) * 8.0, 5.0), Color(0.3, 0.2, 0.08, 0.7 * exposure), 1.8, true)
	var head_dir: Vector2 = Vector2(facing, -0.55 + devour * 0.4 + bite * 0.25).normalized()
	_draw_king_head(game, head, head_dir, thick * 1.3, bite, devour, perfect, t, seed, low)
	# Leitura: vida restante e Alimentado.
	var life_ratio: float = clampf(float(king.get("life", 0.0)) / maxf(1.0, float(king.get("max_life", 1.0))), 0.0, 1.0)
	var bar_c: Vector2 = hole + Vector2(0, 22.0)
	var bw: float = 54.0 + 10.0 * level
	game.draw_rect(Rect2(bar_c - Vector2(bw * 0.5, 0), Vector2(bw, 5)), Color(0.04, 0.04, 0.02, 0.85), true)
	game.draw_rect(Rect2(bar_c - Vector2(bw * 0.5, 0), Vector2(bw * life_ratio, 5)), AMBER if perfect else BILE, true)
	var fed: int = int(king.get("fed", 0))
	var label: String = ("REI PERFEITO" if perfect else "VERME-REI") + (("  ALIMENTADO %d" % fed) if fed > 0 else "")
	game._draw_centered_outlined(label, bar_c + Vector2(0, 22), 12, AMBER if perfect else Color(0.8, 1.0, 0.5), Color(0, 0, 0, 0.9), 3)


static func _draw_king_head(game: Node2D, head: Vector2, dir: Vector2, size: float, bite: float, devour: float, perfect: bool, t: float, seed: float, low: bool) -> void:
	if dir.length() < 0.1:
		dir = Vector2.RIGHT
	var side: Vector2 = dir.orthogonal()
	var open: float = maxf(bite * 0.6, devour)
	var jaw_len: float = size * (1.25 + devour * 0.85)
	var back: Vector2 = head - dir * size * 0.35
	# Capuz de quitina em leque (placas sobrepostas).
	for k in range(3):
		var r: float = size * (1.25 - float(k) * 0.18)
		var c: Vector2 = back - dir * float(k) * size * 0.22
		game.draw_circle(c, r, Color(0.03, 0.02, 0.01) if k == 0 else (CHITIN if k == 1 else Color(0.24, 0.17, 0.08)))
		game.draw_arc(c, r, side.angle() + PI * 0.15, side.angle() + PI * 0.85, 12, Color(0.55, 0.42, 0.22, 0.9), 2.4)
	# Boca circular de carne com aneis de dentes.
	var maw_c: Vector2 = head + dir * size * 0.35
	var maw_r: float = size * (0.42 + open * 0.55)
	game.draw_circle(maw_c, maw_r + 3.0, Color(0.05, 0.02, 0.01))
	game.draw_circle(maw_c, maw_r, Color(0.42, 0.08, 0.05))
	game.draw_circle(maw_c, maw_r * 0.55, Color(0.12, 0.02, 0.01))
	var teeth: int = 6 if low else 11
	for i in range(teeth):
		var a: float = TAU * float(i) / float(teeth) + seed
		var tb: Vector2 = maw_c + Vector2.from_angle(a) * maw_r
		game.draw_line(tb, tb.lerp(maw_c, 0.42), Color(0.95, 0.9, 0.72, 0.95), 2.2, true)
	# Mandibulas: dois pares de ganchos que abrem no Devorar.
	for s in [-1.0, 1.0]:
		for layer in range(2):
			var spread: float = (0.5 + open * 0.9 + float(layer) * 0.25) * s
			var base: Vector2 = maw_c + side * s * maw_r * 0.9 - dir * size * 0.1 * float(layer)
			var mid: Vector2 = base + dir.rotated(spread) * jaw_len * 0.55
			var tip: Vector2 = mid + dir.rotated(spread - s * (1.25 - open * 0.5)) * jaw_len * 0.5
			var w: float = 7.0 - float(layer) * 2.0
			game.draw_polyline(PackedVector2Array([base, mid, tip]), Color(0.04, 0.03, 0.01), w + 2.5, true)
			game.draw_polyline(PackedVector2Array([base, mid, tip]), AMBER if perfect else Color(0.78, 0.64, 0.34), w, true)
			game.draw_circle(tip, w * 0.35, Color(1.0, 0.95, 0.8))
	# Olhos: cacho ambar no capuz.
	for i in range(3 if low else 6):
		var a: float = -1.2 + float(i) * 0.48
		var eye: Vector2 = back + side.rotated(a * 0.6) * size * (0.55 + 0.12 * float(i % 2)) * (1.0 if i % 2 == 0 else -1.0) - dir * size * 0.1
		var glow: float = 0.6 + 0.4 * sin(t * 5.0 + float(i) + seed)
		game.draw_circle(eye, 3.4, Color(0.1, 0.04, 0.0))
		game.draw_circle(eye, 2.4, Color(1.0, 0.7, 0.18, glow))
	if perfect:
		for i in range(5):
			var a2: float = side.angle() + PI * (0.2 + 0.15 * float(i))
			var crown: Vector2 = back + Vector2.from_angle(a2) * size * 1.2
			game.draw_line(crown, crown + Vector2.from_angle(a2) * (10.0 + 4.0 * sin(t * 4.0 + float(i))), AMBER, 3.0, true)
	if devour > 0.0:
		game.draw_arc(maw_c, size * (1.3 + (1.0 - devour) * 1.6), 0.0, TAU, 28, Color(1.0, 0.62, 0.16, 0.55 * devour), 3.0, true)


static func _draw_burrow_mound(game: Node2D, hole: Vector2, level: float, t: float, seed: float, travelling: bool, perfect: bool) -> void:
	var r: float = 24.0 * level
	game.draw_set_transform(hole, 0.0, Vector2(1.0, 0.42))
	game.draw_circle(Vector2.ZERO, r * 1.5, Color(0.1, 0.07, 0.03, 0.55))
	game.draw_circle(Vector2.ZERO, r, Color(0.03, 0.02, 0.01, 0.9))
	game.draw_arc(Vector2.ZERO, r * 1.5, 0.0, TAU, 24, Color(0.42, 0.3, 0.14, 0.7), 2.4)
	if perfect:
		game.draw_arc(Vector2.ZERO, r * 1.75 + sin(t * 4.0) * 3.0, 0.0, TAU, 28, Color(1.0, 0.66, 0.18, 0.45), 2.0)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Torroes e rachaduras.
	for i in range(6):
		var a: float = float(i) * TAU / 6.0 + seed
		var crack_a: Vector2 = hole + Vector2(cos(a), sin(a) * 0.42) * r * 1.2
		var crack_b: Vector2 = hole + Vector2(cos(a + 0.18), sin(a + 0.18) * 0.42) * r * (2.0 + 0.4 * sin(seed + float(i)))
		game.draw_line(crack_a, crack_b, Color(0.08, 0.05, 0.02, 0.7), 2.0, true)
		var bounce: float = absf(sin(t * (14.0 if travelling else 3.0) + float(i) * 1.7))
		game.draw_circle(hole + Vector2(cos(a), sin(a) * 0.42) * r * 1.35 + Vector2(0, -bounce * (6.0 if travelling else 2.0)), 3.2, Color(0.34, 0.24, 0.12, 0.95))


static func _draw_event(game: Node2D, event: Dictionary, camera: Vector2) -> void:
	var p: Vector2 = Vector2(event.get("pos", Vector2.ZERO)) - camera
	var k: float = clampf(float(event.get("life", 0.0)) / maxf(0.01, float(event.get("max", 0.6))), 0.0, 1.0)
	var grow: float = 1.0 - k
	match String(event.get("kind", "")):
		"emerge", "surface", "recast":
			for i in range(8):
				var a: float = float(i) * TAU / 8.0
				var d: float = 18.0 + grow * 56.0
				var chunk: Vector2 = p + Vector2(cos(a), sin(a) * 0.45) * d + Vector2(0, -sin(grow * PI) * 22.0)
				game.draw_circle(chunk, 4.0 * k + 1.5, Color(0.36, 0.25, 0.12, k))
			game.draw_set_transform(p, 0.0, Vector2(1.0, 0.42))
			game.draw_arc(Vector2.ZERO, 22.0 + grow * 70.0, 0.0, TAU, 28, Color(0.62, 0.9, 0.24, 0.55 * k), 3.0)
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"devour":
			game.draw_circle(p, 30.0 + grow * 40.0, Color(0.5, 0.1, 0.04, 0.22 * k))
			for i in range(10):
				var a: float = float(i) * TAU / 10.0
				game.draw_line(p + Vector2.from_angle(a) * (20.0 + grow * 20.0), p + Vector2.from_angle(a) * (34.0 + grow * 52.0), Color(1.0, 0.64, 0.18, 0.8 * k), 3.0, true)
		"leave":
			game.draw_set_transform(p, 0.0, Vector2(1.0, 0.42))
			game.draw_arc(Vector2.ZERO, 26.0 + grow * 30.0, 0.0, TAU, 24, Color(0.34, 0.24, 0.1, 0.7 * k), 3.0)
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _bezier(a: Vector2, b: Vector2, c: Vector2, d: Vector2, u: float) -> Vector2:
	var iu: float = 1.0 - u
	return a * iu * iu * iu + b * 3.0 * iu * iu * u + c * 3.0 * iu * u * u + d * u * u * u


# ================================================================ simbionte
## Verme enrolado em Geovana: cresce com a Fome; morde com um bote visivel.
static func draw_symbiote(game: Node2D, camera: Vector2) -> void:
	if game.manifestation_key != "parasitica":
		return
	var ctl := _ctl(game)
	_draw_symbiote_at(game, Vector2(game.player_pos) - camera, ctl.sym_active, ctl.hunger, ctl.hunger_falling, ctl.sym_pulse, game.time_alive, bool(game.gfx_low_resource))
	for v in ctl.bite_visuals:
		_draw_bite(game, Vector2(v["from"]) - camera, Vector2(v["to"]) - camera, 1.0 - float(v["life"]) / maxf(0.01, float(v["max"])))


static func _draw_symbiote_at(game: Node2D, center: Vector2, active: bool, hunger: int, falling: bool, pulse: float, t: float, low: bool) -> void:
	if not active:
		return
	var ratio: float = clampf(float(hunger) / float(RTParasiticaController.HUNGER_MAX), 0.0, 1.0)
	var alpha: float = 0.7 + 0.3 * ratio
	if falling:
		alpha *= 0.6 + 0.2 * sin(t * 10.0)
	var width: float = 3.6 + ratio * 3.0 + pulse * 0.9
	var segs: int = 10 if low else 18
	# Espiral na cintura que sobe ate o ombro; a parte de tras fica mais apagada.
	var prev: Vector2 = Vector2.ZERO
	var head: Vector2 = Vector2.ZERO
	var head_dir: Vector2 = Vector2.RIGHT
	for i in range(segs):
		var u: float = float(i) / float(segs - 1)
		var a: float = u * TAU * 1.05 + t * 1.1
		var rx: float = 15.0 - u * 3.0
		var p: Vector2 = center + Vector2(cos(a) * rx, 10.0 - u * 28.0 + sin(a) * 4.0)
		if i > 0:
			var front: bool = sin(a) > -0.2
			var k: float = (1.0 if front else 0.35) * alpha
			game.draw_line(prev, p, Color(0.04, 0.05, 0.02, 0.85 * k), width + 2.2, true)
			game.draw_line(prev, p, Color(FLESH.r, FLESH.g, FLESH.b, k), width, true)
			if front and i % 3 == 0:
				game.draw_circle(p, width * 0.45, Color(CHITIN_LIGHT.r, CHITIN_LIGHT.g, CHITIN_LIGHT.b, k))
			head_dir = (p - prev).normalized()
		prev = p
		head = p
	# Cabeca levantada no ombro, olhando para frente.
	var look: Vector2 = Vector2(1.0 if game.last_facing.x >= 0.0 else -1.0, -0.4).normalized() if game.has_method("_parasitica") else head_dir
	var tip: Vector2 = head + look * (7.0 + ratio * 5.0 + pulse * 3.0)
	game.draw_line(head, tip, Color(0.04, 0.05, 0.02, alpha), width + 2.0, true)
	game.draw_line(head, tip, Color(FLESH.r, FLESH.g, FLESH.b, alpha), width, true)
	game.draw_circle(tip, width * 0.9 + 1.2, Color(0.1, 0.07, 0.02, alpha))
	game.draw_circle(tip + look * 1.2, width * 0.7, Color(FLESH_LIGHT.r, FLESH_LIGHT.g, FLESH_LIGHT.b, alpha))
	for s in [-1.0, 1.0]:
		game.draw_line(tip + look * 2.0, tip + look.rotated(0.55 * s) * (6.0 + ratio * 3.0), Color(0.95, 0.85, 0.5, alpha), 1.6, true)
	if hunger >= RTParasiticaController.HUNGER_MAX:
		game.draw_circle(tip, 7.0 + sin(t * 9.0) * 1.5, Color(1.0, 0.68, 0.18, 0.22))
		game.draw_circle(tip + look * 1.5, 1.6, Color(1.0, 0.75, 0.2, 0.95))


static func _draw_bite(game: Node2D, from: Vector2, to: Vector2, progress: float) -> void:
	# Bote: a cabeca do simbionte se estica ate o alvo e volta.
	var reach: float = sin(clampf(progress, 0.0, 1.0) * PI)
	var head: Vector2 = from.lerp(to, reach)
	var mid: Vector2 = from.lerp(head, 0.5) + (head - from).orthogonal().normalized() * 14.0 * reach
	var line := PackedVector2Array([from + Vector2(0, -18), mid, head])
	game.draw_polyline(line, Color(0.05, 0.05, 0.02, 0.85), 8.0, true)
	game.draw_polyline(line, Color(FLESH.r, FLESH.g, FLESH.b, 0.95), 5.0, true)
	var dir: Vector2 = (head - mid).normalized()
	for s in [-1.0, 1.0]:
		game.draw_line(head, head + dir.rotated(0.7 * s) * 12.0, AMBER, 2.4, true)
	if reach > 0.8:
		game.draw_circle(to, 10.0, Color(0.6, 0.12, 0.06, 0.4))


# ================================================================ HUD
## Indicadores compactos sobre os botoes de HAB1 e E (sem painel novo).
static func draw_hud(game: Node2D, viewport: Vector2) -> void:
	if game.manifestation_key != "parasitica" or game.mode != "game":
		return
	var ctl := _ctl(game)
	var small: int = game._readable_text_size(12) if game.has_method("_readable_text_size") else 12
	if ctl.sym_active and game.buttons.has("skill"):
		var r: Rect2 = game.buttons["skill"]
		var max_fome: bool = ctl.hunger >= RTParasiticaController.HUNGER_MAX
		var text: String = "FOME %d/%d · %.1fs" % [ctl.hunger, RTParasiticaController.HUNGER_MAX, maxf(0.0, ctl.sym_left)]
		_badge(game, Vector2(r.get_center().x, r.position.y - 16.0), text, AMBER if max_fome else (Color(0.85, 0.75, 0.5) if ctl.hunger_falling else BILE), small)
	if ctl.king_active() and game.buttons.has("secondary"):
		var r2: Rect2 = game.buttons["secondary"]
		var k: Dictionary = ctl.king
		var label: String = ("REI PERFEITO" if bool(k.get("perfect", false)) else "VERME-REI") + " · ALIM. %d · %.0fs" % [int(k.get("fed", 0)), maxf(0.0, float(k.get("life", 0.0)))]
		# Empilha acima do selo da Fome quando os botoes estao lado a lado.
		var y2: float = r2.position.y - 16.0
		if ctl.sym_active and game.buttons.has("skill") and absf(Rect2(game.buttons["skill"]).get_center().x - r2.get_center().x) < 260.0:
			y2 -= 26.0
		_badge(game, Vector2(r2.get_center().x, y2), label, AMBER if bool(k.get("perfect", false)) else BILE, small)


static func _badge(game: Node2D, center: Vector2, text: String, color: Color, size: int) -> void:
	var w: float = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 16.0
	var rect := Rect2(center - Vector2(w * 0.5, 11.0), Vector2(w, 22.0))
	game.draw_rect(rect, Color(0.03, 0.04, 0.02, 0.88), true)
	game.draw_rect(rect, Color(color.r, color.g, color.b, 0.9), false, 1.5)
	game.draw_string(game.font, rect.position + Vector2(8.0, 16.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


# ================================================================ replica
## Desenha o estado compacto vindo da rede (simbionte + rei) sem refs de alvo.
static func draw_remote(game: Node2D, snap: Dictionary, camera: Vector2, owner_pos: Vector2) -> void:
	if snap.is_empty():
		return
	_draw_symbiote_at(game, owner_pos - camera, bool(snap.get("sym", false)), int(snap.get("hunger", 0)), bool(snap.get("falling", false)), 0.0, game.time_alive, true)
	var k = snap.get("king", {})
	if k is Dictionary and not Dictionary(k).is_empty():
		var kd: Dictionary = k
		var level: float = minf(2.3, 1.0 + 0.07 * float(kd.get("consumed", 1)) + (0.16 if bool(kd.get("perfect", false)) else 0.0) + 0.035 * float(kd.get("fed", 0)))
		draw_king(game, kd, camera, level, game.time_alive)
