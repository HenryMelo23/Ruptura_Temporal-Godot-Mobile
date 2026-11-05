class_name RTGravitanteMassVfx
extends RefCounted

## VFX do rework da Gravitante: Estrelas (massa critica), puxao do Q, Poco de Partida
## e disco de acrecao reutilizado pelo E. Tudo desenhado em codigo, com limites fixos.

const VOID := Color(0.01, 0.012, 0.03)
const ICE := Color(0.87, 0.97, 1.0)
const CYAN := Color(0.2, 0.78, 0.94)
const BLUE := Color(0.19, 0.39, 0.68)
const VIOLET := Color(0.52, 0.36, 0.86)
const STAR_CAP := 12
const ARM_STEPS := 14


static func _ctrl(game: Node2D) -> RTGravitanteController:
	return game._gravitante()


## Camada de chao (antes dos inimigos): pocos, halos das estrelas, rastros do Q.
static func draw_ground(game: Node2D, camera: Vector2) -> void:
	var ctrl := _ctrl(game)
	var t: float = float(game.time_alive)
	for well in ctrl.wells:
		var p: float = 1.0 - float(well["life"]) / maxf(0.01, float(well["max"]))
		_draw_well(game, Vector2(well["pos"]) - camera, p, t)
	var drawn := 0
	for star in ctrl.stars():
		if drawn >= STAR_CAP:
			break
		var c: Vector2 = Vector2(star["pos"]) - camera
		if not game._screen_point_in_view(c, 140.0):
			continue
		drawn += 1
		_draw_star_ground(game, c, t, float(int(star.get("uid", 0))))
	for collision in ctrl.collisions:
		var center: Vector2 = Vector2(collision["center"]) - camera
		var p: float = clampf(float(collision["t"]) / RTGravitanteController.COLLISION_PULL_TIME, 0.0, 1.0)
		for target in collision["targets"]:
			var enemy = game._enemy_by_uid(int(target["uid"]))
			if enemy == null:
				continue
			var a: Vector2 = Vector2(enemy["pos"]) - camera
			game.draw_line(a, center, Color(CYAN, 0.5 * (1.0 - p * 0.5)), 3.0, true)
			game.draw_line(a, center, Color(ICE, 0.7), 1.0, true)
		game.draw_circle(center, 10.0 + p * 18.0, Color(VOID, 0.5))
		game.draw_arc(center, 70.0 * (1.0 - p) + 12.0, 0.0, TAU, 36, Color(ICE, 0.7), 2.0, true)


## Camada da frente: centelhas das estrelas e eventos curtos.
static func draw_front(game: Node2D, camera: Vector2) -> void:
	var ctrl := _ctrl(game)
	var t: float = float(game.time_alive)
	var drawn := 0
	for star in ctrl.stars():
		if drawn >= STAR_CAP:
			break
		var c: Vector2 = Vector2(star["pos"]) - camera
		if not game._screen_point_in_view(c, 140.0):
			continue
		drawn += 1
		_draw_star_front(game, c, t, float(int(star.get("uid", 0))))
	for effect in game.gravitante_vfx_events:
		var kind: String = String(effect.get("kind", ""))
		if not kind in ["gravity_star_birth", "gravity_well_collapse", "gravity_q_pull"]:
			continue
		var p: float = clampf(1.0 - float(effect.get("life", 0.0)) / maxf(0.01, float(effect.get("max", 1.0))), 0.0, 1.0)
		var c: Vector2 = Vector2(effect.get("pos", game.player_pos)) - camera
		match kind:
			"gravity_star_birth":
				game.draw_arc(c + Vector2(0, -22), 10.0 + p * 46.0, 0.0, TAU, 32, Color(ICE, 1.0 - p), 3.0 * (1.0 - p) + 1.0, true)
				game.draw_circle(c + Vector2(0, -22), 9.0 * (1.0 - p), Color(ICE, 0.9 * (1.0 - p)))
			"gravity_well_collapse":
				var r: float = RTGravitanteController.WELL_COLLAPSE_RADIUS
				if p < 0.25:
					game.draw_circle(c, 30.0 * (1.0 - p / 0.25), Color(ICE, 0.85))
				game.draw_arc(c, r * (0.25 + p), 0.0, TAU, 44, Color(CYAN, 1.0 - p), 4.0 * (1.0 - p) + 1.0, true)
				game.draw_arc(c, r * (0.15 + p * 0.7), 0.0, TAU, 32, Color(VIOLET, 0.8 * (1.0 - p)), 2.0, true)
				for i in range(8):
					var a: float = float(i) * TAU / 8.0 + 0.3
					game.draw_line(c + Vector2.from_angle(a) * r * (0.2 + p * 0.6), c + Vector2.from_angle(a) * r * (0.45 + p), Color(ICE, 0.8 * (1.0 - p)), 2.0, true)


static func _draw_star_ground(game: Node2D, c: Vector2, t: float, seed: float) -> void:
	var r: float = RTGravitanteController.STAR_RADIUS
	game.draw_set_transform(c + Vector2(0, 6), 0.0, Vector2(1.0, 0.55))
	game.draw_circle(Vector2.ZERO, r, Color(BLUE, 0.1))
	game.draw_arc(Vector2.ZERO, r, t * 0.6, t * 0.6 + TAU * 0.8, 48, Color(CYAN, 0.5), 2.0, true)
	# Detritos caindo em espiral para a estrela (mostra o puxao).
	for i in range(6):
		var phase: float = fposmod(t * 0.55 + float(i) / 6.0 + seed * 0.13, 1.0)
		var ang: float = float(i) * TAU / 6.0 + phase * 2.6
		var pr: float = lerpf(r, 22.0, phase)
		var pos: Vector2 = Vector2.from_angle(ang) * pr
		var tail: Vector2 = Vector2.from_angle(ang - 0.22) * (pr + 14.0)
		game.draw_line(tail, pos, Color(ICE, sin(phase * PI) * 0.7), 2.0, true)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_star_front(game: Node2D, c: Vector2, t: float, seed: float) -> void:
	var core_pos: Vector2 = c + Vector2(0, -22)
	var pulse: float = 0.5 + 0.5 * sin(t * 6.0 + seed)
	game.draw_circle(core_pos, 30.0 + pulse * 4.0, Color(CYAN, 0.1))
	game.draw_circle(core_pos, 18.0 + pulse * 3.0, Color(CYAN, 0.18))
	game.draw_circle(core_pos, 8.0 + pulse * 1.5, Color(ICE, 0.85))
	for i in range(4):
		var a: float = t * 1.4 + float(i) * PI * 0.5
		game.draw_line(core_pos + Vector2.from_angle(a) * 9.0, core_pos + Vector2.from_angle(a) * (20.0 + pulse * 6.0), Color(ICE, 0.55), 1.4, true)


static func _draw_well(game: Node2D, c: Vector2, p: float, t: float) -> void:
	var r: float = RTGravitanteController.WELL_RADIUS
	var birth: float = clampf(p / 0.15, 0.0, 1.0)
	var fade: float = 1.0 - clampf((p - 0.85) / 0.15, 0.0, 1.0)
	var a: float = birth * fade
	game.draw_set_transform(c, 0.0, Vector2(1.0, 0.6))
	game.draw_circle(Vector2.ZERO, r * birth, Color(BLUE, 0.08 * a))
	game.draw_arc(Vector2.ZERO, r * birth, -t * 0.8, -t * 0.8 + TAU, 56, Color(CYAN, 0.35 * a), 1.6, true)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	accretion(game, c, r * 0.62 * birth, t * 2.4, a, 3)
	var core_r: float = (16.0 + 10.0 * sin(p * PI)) * birth * (1.0 - clampf((p - 0.9) / 0.1, 0.0, 1.0) * 0.6)
	game.draw_circle(c, core_r * 1.8, Color(CYAN, 0.12 * a))
	game.draw_circle(c, core_r, VOID)
	game.draw_arc(c, core_r + 1.5, 0.0, TAU, 28, Color(ICE, 0.9 * a), 2.0, true)


## Disco de acrecao em espiral (3 bracos), brilho e infall. Usado no Poco e no E.
static func accretion(game: Node2D, center: Vector2, radius: float, spin: float, alpha: float, arms: int = 3) -> void:
	if radius < 4.0 or alpha <= 0.01:
		return
	game.draw_set_transform(center, 0.0, Vector2(1.0, 0.55))
	game.draw_circle(Vector2.ZERO, radius * 1.05, Color(VOID, 0.22 * alpha))
	game.draw_circle(Vector2.ZERO, radius * 0.7, Color(VIOLET, 0.14 * alpha))
	game.draw_circle(Vector2.ZERO, radius * 0.38, Color(CYAN, 0.18 * alpha))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for k in range(arms):
		var prev: Vector2 = Vector2.ZERO
		for s in range(ARM_STEPS + 1):
			var f: float = float(s) / float(ARM_STEPS)
			var ang: float = spin + float(k) * TAU / float(arms) + f * 2.6
			var rr: float = lerpf(radius, radius * 0.16, f)
			var pt: Vector2 = center + Vector2(cos(ang) * rr, sin(ang) * rr * 0.55)
			if s > 0:
				var col := Color(VIOLET.lerp(CYAN, f * 0.7).lerp(ICE, f * f), alpha * (0.45 + 0.55 * f))
				game.draw_line(prev, pt, Color(VIOLET, alpha * 0.28), 16.0 * (1.0 - f * 0.55))
				game.draw_line(prev, pt, Color(col, col.a * 0.55), 8.0 * (1.0 - f * 0.45))
				game.draw_line(prev, pt, col, 3.6 * (1.0 - f * 0.3) + 1.0)
			prev = pt
	for i in range(8):
		var phase: float = fposmod(spin * 0.18 + float(i) * 0.137, 1.0)
		var ang2: float = float(i) * 2.399 + phase * 3.0
		var rr2: float = lerpf(radius * 1.2, radius * 0.2, phase)
		var pos: Vector2 = center + Vector2(cos(ang2) * rr2, sin(ang2) * rr2 * 0.55)
		game.draw_circle(pos, 2.4 + float(i % 2), Color(ICE, sin(phase * PI) * 0.95 * alpha))


## Horizonte com degrade (sem disco preto chapado) e anel de fotons pulsante.
static func photon_ring(game: Node2D, center: Vector2, radius: float, spin: float, alpha: float) -> void:
	if radius < 4.0 or alpha <= 0.01:
		return
	game.draw_circle(center, radius * 1.0, Color(0.09, 0.05, 0.2, alpha))
	game.draw_circle(center, radius * 0.8, Color(0.04, 0.02, 0.1, alpha))
	game.draw_circle(center, radius * 0.55, Color(VOID, alpha))
	var pulse: float = 0.5 + 0.5 * sin(spin * 2.0)
	game.draw_arc(center, radius * 1.32, 0.0, TAU, 48, Color(VIOLET, 0.22 * alpha), 12.0, true)
	game.draw_arc(center, radius * 1.16, 0.0, TAU, 48, Color(CYAN, (0.35 + pulse * 0.2) * alpha), 6.0, true)
	game.draw_arc(center, radius * 1.08, 0.0, TAU, 48, Color(ICE, 0.95 * alpha), 2.4, true)
	# Lado "quente" do anel (efeito Doppler) girando.
	game.draw_arc(center, radius * 1.1, spin, spin + PI * 0.7, 24, Color(1.0, 1.0, 1.0, 0.9 * alpha), 4.0, true)
