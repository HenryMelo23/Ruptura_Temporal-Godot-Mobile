class_name RTUmbraTransmuteVfx
extends RefCounted

## Transmutacao da UMBRA (troca de dimensao na Mente da UMBRA).
##
##   0.00 - SNAP   carga: a realidade e sugada para a mao dela (riscos que
##                 convergem, mostrador de relogio girando no chao, rasgo escuro)
##   SNAP          estalo: clarao, tremor, vibracao, impacto
##   SNAP - 1.25   a dimensao nova se espalha a partir dela; fora do circulo
##                 continua o chao antigo, desbotando e rachando (shader do chao
##                 em PhaseMapPresentation.set_reveal); estilhacos voam da frente
##   ate DURATION  nome da dimensao na tela e vinheta na cor nova
##
## Usa o estado que ja existia (phase5_transmute_*). So muda o visual: a troca
## de dimensao e a mecanica continuam acontecendo no instante do cast.

const DURATION := 2.1
const SNAP := 0.34
## A frente cruza a tela (~750 px) em ~0,5 s e termina fora dela.
const SPREAD := 1.25
const MAX_RADIUS := 1150.0
const NAMES := {
	"vortice": "VÓRTICE", "gravidade": "GRAVIDADE", "necrose": "NECROSE",
	"ressonancia": "RESSONÂNCIA", "hemorragia": "HEMORRAGIA", "atrito": "ATRITO",
	"rastro": "RASTRO", "base": "MENTE DA UMBRA",
}
const SHARDS := 34
const STREAKS := 26


static func active(game: Node) -> bool:
	return bool(game.phase5_transmute_active) and int(game.current_phase) == 5


static func elapsed(game: Node) -> float:
	return float(game.phase5_transmute_timer)


static func _ease_out(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - x, 3.0)


## Raio da frente da dimensao nova (-1 antes do estalo / depois do fim).
static func radius(game: Node) -> float:
	if not active(game):
		return -1.0
	var t: float = elapsed(game) - SNAP
	if t < 0.0:
		return 0.0
	if t > SPREAD:
		return -1.0
	var u: float = clampf(t / SPREAD, 0.0, 1.0)
	return (1.0 - (1.0 - u) * (1.0 - u)) * MAX_RADIUS


static func color(game: Node) -> Color:
	return Color(game.phase5_transmute_color)


static func center(game: Node) -> Vector2:
	return Vector2(game.phase5_transmute_center)


## Chamado depois do present_chunks do chao definitivo.
static func apply_ground(game: Node) -> void:
	if not is_instance_valid(game.phase_map_layer) or not game.phase_map_layer.has_method("set_reveal"):
		return
	var r: float = radius(game) if game.experimental_phase_controller.uses_definitive_world() else -1.0
	game.phase_map_layer.set_reveal(game.phase5_transmute_old_tex, center(game), r, color(game))


## Estalo: tremor, vibracao e som (chamado uma vez pelo update do nucleo).
static func update(game: Node, previous_t: float) -> void:
	if not active(game):
		return
	var t: float = elapsed(game)
	if previous_t < SNAP and t >= SNAP:
		game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.42)
		game.screen_shake_strength = maxf(float(game.screen_shake_strength), 11.0)
		game._vibrate(180, 0.8)
		game._play_sfx("boss_impact", 0.02, 0.85, 0.72)


# ============================================================ chao
static func draw_floor(game: Node, camera: Vector2) -> void:
	if not active(game):
		return
	var t: float = elapsed(game)
	var c: Vector2 = center(game) - camera
	var col: Color = color(game)
	if t < SNAP:
		# Mostrador de relogio no chao, girando cada vez mais rapido.
		var k: float = t / SNAP
		var r: float = lerpf(170.0, 96.0, k)
		var spin: float = t * (4.0 + 18.0 * k)
		game.draw_circle(c, r, Color(0.0, 0.0, 0.0, 0.28 * k))
		game.draw_arc(c, r, 0.0, TAU, 64, Color(col, 0.75 * k), 3.0)
		game.draw_arc(c, r * 0.72, spin, spin + PI * 1.4, 48, Color(1, 1, 1, 0.55 * k), 2.0)
		for i in range(12):
			var a: float = float(i) * TAU / 12.0 - spin * 0.5
			var d := Vector2.from_angle(a)
			game.draw_line(c + d * r * 0.86, c + d * r, Color(col.lightened(0.4), 0.9 * k), 3.0 if i % 3 == 0 else 1.5)
		game.draw_line(c, c + Vector2.from_angle(spin * 1.7) * r * 0.8, Color(1, 1, 1, 0.8 * k), 3.0)
		# Rasgo escuro se abrindo atras dela (desenhado antes do corpo).
		var body: Vector2 = Vector2(game.boss_pos) + Vector2(0, -20) - camera
		var tear: float = 14.0 + 40.0 * k
		game.draw_circle(body, tear + 12.0, Color(col, 0.3))
		game.draw_circle(body, tear, Color(0.02, 0.0, 0.05, 0.85))
		game.draw_arc(body, tear, 0.0, TAU, 40, Color(1, 1, 1, 0.85), 2.5)
		return
	# Fendas: raios irregulares que partem do ponto do estalo e somem.
	var u: float = clampf((t - SNAP) / 0.7, 0.0, 1.0)
	if u < 1.0:
		var reach: float = radius(game) if radius(game) > 0.0 else MAX_RADIUS
		for i in range(9):
			var a: float = float(i) * TAU / 9.0 + 0.37
			var p := c
			var length: float = minf(reach, 260.0 + float(i % 3) * 120.0)
			var steps := 7
			for s in range(steps):
				var q: Vector2 = c + Vector2.from_angle(a + sin(float(i * 7 + s) * 1.9) * 0.22) * length * float(s + 1) / float(steps)
				game.draw_line(p, q, Color(0.02, 0.0, 0.04, 0.85 * (1.0 - u)), 6.0 - float(s) * 0.6)
				game.draw_line(p, q, Color(col.lightened(0.35), 0.9 * (1.0 - u)), 2.2 - float(s) * 0.2)
				p = q


# ============================================================ frente
static func draw_front(game: Node, camera: Vector2) -> void:
	if not active(game):
		return
	var t: float = elapsed(game)
	var col: Color = color(game)
	var body: Vector2 = Vector2(game.boss_pos) + Vector2(0, -20) - camera
	var c: Vector2 = center(game) - camera
	if t < SNAP:
		var k: float = t / SNAP
		# A realidade sendo sugada: riscos convergindo para ela.
		for i in range(STREAKS):
			var a: float = float(i) * TAU / float(STREAKS) + float(i % 5) * 0.41
			var phase: float = fmod(k * 1.6 + float(i) * 0.137, 1.0)
			var far: float = lerpf(360.0, 30.0, phase)
			var near: float = maxf(18.0, far - 60.0 - 70.0 * k)
			var d := Vector2.from_angle(a)
			game.draw_line(body + d * far, body + d * near, Color(col.lightened(0.3), 0.25 + 0.6 * phase), 2.0 + 2.0 * phase)
		return
	var tb: float = t - SNAP
	# Onda de choque no ar + segunda onda mais fina.
	var r: float = _ease_out(tb / 0.55) * 520.0
	var fade: float = clampf(1.0 - tb / 0.55, 0.0, 1.0)
	if fade > 0.0:
		game.draw_arc(body, r, 0.0, TAU, 96, Color(1, 1, 1, 0.9 * fade), 10.0 * fade + 2.0)
		game.draw_arc(body, r * 0.82, 0.0, TAU, 96, Color(col.lightened(0.2), 0.8 * fade), 5.0)
		game.draw_circle(body, 60.0 * fade, Color(1, 1, 1, 0.7 * fade))
	# Estilhacos da realidade antiga voando a partir da frente do chao.
	var front: float = radius(game)
	if front > 0.0:
		for i in range(SHARDS):
			var a: float = float(i) * TAU / float(SHARDS) + sin(float(i) * 12.9898) * 0.3
			var life: float = fmod(tb * 1.8 + float(i % 7) * 0.13, 1.0)
			var d := Vector2.from_angle(a)
			var p: Vector2 = c + d * (front + 30.0 * life) + Vector2(0, -90.0 * life * (0.5 + 0.5 * sin(float(i))))
			var s: float = 7.0 + float(i % 4) * 3.0
			var rot: float = tb * (6.0 + float(i % 5)) + float(i)
			var poly := PackedVector2Array([p + Vector2.from_angle(rot) * s, p + Vector2.from_angle(rot + 2.3) * s * 0.7, p + Vector2.from_angle(rot + 4.1) * s * 0.9])
			game.draw_colored_polygon(poly, Color(col.lightened(0.25), 0.85 * (1.0 - life)))
			game.draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[0]]), Color(1, 1, 1, 0.7 * (1.0 - life)), 1.2)


# ============================================================ tela
static func draw_screen(game: Node, viewport: Vector2) -> void:
	if not active(game):
		return
	var t: float = elapsed(game)
	var col: Color = color(game)
	var full := Rect2(Vector2.ZERO, viewport)
	if t < SNAP:
		# Tudo escurece enquanto ela puxa a dimensao.
		game.draw_rect(full, Color(0.0, 0.0, 0.02, 0.32 * t / SNAP))
		return
	var tb: float = t - SNAP
	# Clarao do estalo: branco que vira a cor da dimensao.
	if tb < 0.24:
		var f: float = 1.0 - tb / 0.24
		game.draw_rect(full, Color(Color(1, 1, 1).lerp(col, clampf(tb / 0.1, 0.0, 1.0)), 0.7 * f * f))
	# Vinheta na cor nova.
	var v: float = clampf(1.0 - tb / (DURATION - SNAP), 0.0, 1.0)
	if v > 0.0:
		var edge: float = 70.0
		for i in range(4):
			var a: float = 0.16 * v * (1.0 - float(i) / 4.0)
			var e: float = edge * float(i + 1) / 4.0
			game.draw_rect(Rect2(0, 0, viewport.x, e), Color(col.darkened(0.3), a))
			game.draw_rect(Rect2(0, viewport.y - e, viewport.x, e), Color(col.darkened(0.3), a))
			game.draw_rect(Rect2(0, 0, e, viewport.y), Color(col.darkened(0.3), a))
			game.draw_rect(Rect2(viewport.x - e, 0, e, viewport.y), Color(col.darkened(0.3), a))
	# Nome da dimensao: entra com o estalo, segura e some.
	var dim: String = String(game.boss5_dimension)
	var title: String = String(NAMES.get(dim, dim.to_upper()))
	var a_in: float = clampf((tb - 0.08) / 0.2, 0.0, 1.0)
	var a_out: float = clampf((DURATION - SNAP - tb) / 0.45, 0.0, 1.0)
	var alpha: float = a_in * a_out
	if alpha > 0.0:
		# Embaixo, no centro (o alto da tela costuma ter a UMBRA e a barra dela).
		var y: float = viewport.y - 178.0
		var grow: float = 1.0 + 0.25 * (1.0 - _ease_out(tb / 0.35))
		var w: float = 420.0 * grow
		game.draw_rect(Rect2(viewport.x * 0.5 - w * 0.5, y - 34.0, w, 2.0), Color(col, 0.8 * alpha))
		game.draw_rect(Rect2(viewport.x * 0.5 - w * 0.5, y + 30.0, w, 2.0), Color(col, 0.8 * alpha))
		game.draw_rect(Rect2(viewport.x * 0.5 - w * 0.5, y - 32.0, w, 62.0), Color(0.02, 0.0, 0.05, 0.45 * alpha))
		game._draw_centered(title, Vector2(viewport.x * 0.5 + 2.0, y - 4.0), int(38 * grow), Color(0, 0, 0, 0.6 * alpha))
		game._draw_centered(title, Vector2(viewport.x * 0.5, y - 6.0), int(38 * grow), Color(col.lightened(0.35), alpha))
		game._draw_centered("A UMBRA TROCOU DE DIMENSÃO" if dim != "base" else "DE VOLTA À MENTE DELA", Vector2(viewport.x * 0.5, y + 20.0), 13, Color(0.9, 0.95, 0.95, 0.85 * alpha))
