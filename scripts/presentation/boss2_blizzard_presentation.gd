class_name RTBoss2BlizzardPresentation
extends RefCounted

## Nevasca do Sentinela (ultimate do Boss 2) e a presenca do pinguim na tempestade.
## - Fora do anel seguro: nevoa branca que engrossa, neve em 3 camadas girando com a
##   tempestade, rajadas quando o vento puxa; borda do anel como parede de gelo.
## - O pinguim anda para dentro da nevoa e se desfaz em flocos ao entrar; antes de cuspir
##   sai andando da nevasca e vai se remontando (RTBoss2DissolvePresentation).

const FOG := Color(0.86, 0.93, 0.98)
const ICE := Color(0.5, 0.95, 1.0)
const INK := Color(0.02, 0.06, 0.12)

static var _reveal := 1.0
static var _rising := false
static var _last_time := -1.0


## Passo pelo tempo de jogo (respeita pausa e camera lenta).
static func _dt(game: Node2D) -> float:
	var now: float = float(game.time_alive)
	var dt: float = clampf(now - _last_time, 0.0, 0.1) if _last_time >= 0.0 else 0.0
	_last_time = now
	return dt


## 0..1: 1 = pinguim visivel, 0 = dissolvido na nevasca. Depende de onde ele esta:
## some ao entrar na nevoa (fora do anel) e reaparece conforme sai dela.
static func reveal(game: Node2D) -> float:
	var dt := _dt(game)
	var target: float = 1.0
	if game.current_phase == 2 and game.boss2_ultimate_timer > 0.0:
		target = fog_reveal(game, game.boss_pos)
	_rising = target > _reveal + 0.001
	# Suaviza so um pouco (o bote atravessa a neve rapido demais para piscar).
	_reveal = move_toward(_reveal, target, dt * 2.6)
	return _reveal


static func fog_reveal(game: Node2D, world_pos: Vector2) -> float:
	return game._boss2_motion().fog_reveal_at(world_pos)


## Direcao (tela = mundo) que aponta para dentro da nevasca a partir do pinguim.
static func fog_front(game: Node2D) -> Vector2:
	var rel: Vector2 = game.boss_pos - game.boss2_ultimate_center
	return rel.normalized() if rel.length() > 1.0 else Vector2.RIGHT


static func rising() -> bool:
	return _rising


## Direcao da tempestade em volta do pinguim (tangente da espiral + rajada).
static func wind_at(game: Node2D, world_pos: Vector2) -> Vector2:
	var rel: Vector2 = world_pos - game.boss2_ultimate_center
	var tangent: Vector2 = rel.orthogonal().normalized() if rel.length() > 1.0 else Vector2.RIGHT
	var gust: Vector2 = Vector2(game.boss2_ultimate_wind_dir) * clampf(float(game.boss2_ultimate_wind_active), 0.0, 1.0)
	return (tangent + gust + Vector2(0, -0.35)).normalized()


static func draw_environment(game: Node2D, camera: Vector2) -> void:
	var viewport: Vector2 = game.get_viewport_rect().size
	var center: Vector2 = game.boss2_ultimate_center - camera
	var safe_radius: float = game.BOSS2_ULTIMATE_SAFE_RADIUS
	var low: bool = game._memory_saver_active() or game._runtime_visual_budget_active() or game.gfx_low_resource
	var t: float = float(game.time_alive)
	var gust: float = clampf(float(game.boss2_ultimate_wind_active) / 0.6, 0.0, 1.0)
	# Intensidade cresce nos primeiros segundos e some no fim.
	var life: float = float(game.boss2_ultimate_timer)
	var k: float = clampf((float(game.BOSS2_ULTIMATE_DURATION) - life) / 2.0, 0.0, 1.0) * clampf(life / 1.5, 0.0, 1.0)
	_draw_fog(game, center, safe_radius, viewport, k * (0.85 + gust * 0.15), low)
	_draw_snow(game, center, safe_radius, viewport, t, k, gust, low)
	if gust > 0.0:
		_draw_gust(game, center, viewport, t, gust, low)
	_draw_rim(game, center, safe_radius, t, low)


static func _draw_fog(game: Node2D, center: Vector2, safe_radius: float, viewport: Vector2, k: float, low: bool) -> void:
	# Anel de nevoa em degrade: transparente na borda segura, branco denso fora.
	var segments: int = 36 if low else 64
	var r0: float = safe_radius + 10.0
	var r1: float = safe_radius + 170.0
	var r2: float = maxf(viewport.length() * 1.2, safe_radius + 1400.0)
	var clear_c := Color(FOG, 0.0)
	var mid_c := Color(FOG, 0.5 * k)
	var far_c := Color(0.8, 0.88, 0.95, 0.68 * k)
	for i in range(segments):
		var a0: float = float(i) * TAU / float(segments)
		var a1: float = float(i + 1) * TAU / float(segments)
		var d0 := Vector2.from_angle(a0)
		var d1 := Vector2.from_angle(a1)
		game.draw_polygon(PackedVector2Array([center + d0 * r0, center + d1 * r0, center + d1 * r1, center + d0 * r1]), PackedColorArray([clear_c, clear_c, mid_c, mid_c]))
		game.draw_polygon(PackedVector2Array([center + d0 * r1, center + d1 * r1, center + d1 * r2, center + d0 * r2]), PackedColorArray([mid_c, mid_c, far_c, far_c]))


static func _draw_snow(game: Node2D, center: Vector2, safe_radius: float, viewport: Vector2, t: float, k: float, gust: float, low: bool) -> void:
	# Tres camadas (perto/meio/longe) girando em espiral em volta do centro da tempestade.
	var layers: Array = [[0.6, 1.0, 2.2], [1.0, 1.6, 3.2], [1.5, 2.4, 4.4]]
	var counts: Array = [40, 60, 30] if low else [90, 130, 60]
	for li in range(layers.size()):
		var layer: Array = layers[li]
		var speed: float = float(layer[0]) * (1.0 + gust * 1.4)
		var length: float = 10.0 * float(layer[1]) * (1.0 + gust)
		var width: float = float(layer[2]) * 0.6
		for i in range(int(counts[li])):
			var seed_v: float = float(i) * 12.9898 + float(li) * 78.233
			var base := Vector2(fposmod(sin(seed_v) * 43758.5453, 1.0) * viewport.x, fposmod(cos(seed_v) * 24634.6345, 1.0) * viewport.y)
			# Espiral: tangente a tempestade + um pouco para dentro.
			var rel: Vector2 = base - center
			var tangent: Vector2 = rel.orthogonal().normalized() if rel.length() > 1.0 else Vector2.RIGHT
			var flow: Vector2 = (tangent * 0.85 - rel.normalized() * 0.25).normalized()
			var p: Vector2 = base + flow * fposmod(t * 160.0 * speed + seed_v * 13.0, 260.0)
			p = Vector2(fposmod(p.x, viewport.x + 40.0) - 20.0, fposmod(p.y, viewport.y + 40.0) - 20.0)
			var inside: bool = p.distance_to(center) < safe_radius - 20.0
			var alpha: float = (0.18 if inside else 0.75) * k * (0.6 + float(li) * 0.2)
			if alpha <= 0.01:
				continue
			game.draw_line(p - flow * length, p, Color(1.0, 1.0, 1.0, alpha), width, true)


static func _draw_gust(game: Node2D, center: Vector2, viewport: Vector2, t: float, gust: float, low: bool) -> void:
	# Lencois de neve varrendo para o centro (o vento puxa).
	for i in range(3 if low else 6):
		var phase: float = fposmod(t * 0.9 + float(i) / 6.0, 1.0)
		var ang: float = float(i) * 1.7 + t * 0.2
		var dir: Vector2 = Vector2.from_angle(ang)
		var dist: float = lerpf(viewport.length() * 0.7, 120.0, phase)
		var p: Vector2 = center + dir * dist
		var side: Vector2 = dir.orthogonal()
		game.draw_line(p - side * 160.0, p + side * 160.0, Color(1.0, 1.0, 1.0, 0.18 * gust * sin(phase * PI)), 26.0, true)
		game.Boss1VFX.streak(game, p + dir * 60.0, p - dir * 20.0, Color(1.0, 1.0, 1.0, 0.5 * gust * sin(phase * PI)), 6.0)


static func _draw_rim(game: Node2D, center: Vector2, safe_radius: float, t: float, low: bool) -> void:
	var segments: int = 64 if low else 128
	game.draw_arc(center, safe_radius, 0.0, TAU, segments, Color(INK, 0.55), 12.0, true)
	game.draw_arc(center, safe_radius, 0.0, TAU, segments, Color(ICE, 0.95), 4.0, true)
	game.draw_arc(center, safe_radius + 9.0, 0.0, TAU, segments, Color(1.0, 1.0, 1.0, 0.45), 2.0, true)
	# Cristais de gelo em pe na borda, apontando para fora.
	var count: int = 18 if low else 36
	for i in range(count):
		var ang: float = float(i) * TAU / float(count) + t * 0.05
		var dir := Vector2.from_angle(ang)
		var base: Vector2 = center + dir * (safe_radius + 4.0)
		var h: float = 12.0 + float(i % 3) * 7.0
		var side: Vector2 = dir.orthogonal() * 5.0
		game.draw_colored_polygon(PackedVector2Array([base + side, base + dir * h, base - side]), Color(INK, 0.6))
		game.draw_colored_polygon(PackedVector2Array([base + side * 0.6, base + dir * (h - 2.0), base - side * 0.6]), Color(0.85, 0.98, 1.0, 0.9))


## Presenca do pinguim na Nevasca: rastro do bote, preparo do bote e marcador de borda.
static func draw_presence(game: Node2D, camera: Vector2, boss_tex: Texture2D, draw_pos: Vector2, draw_size: Vector2, hidden: float) -> void:
	var motion = game._boss2_motion()
	var t: float = float(game.time_alive)
	for i in range(motion.trail.size()):
		var mark: Dictionary = motion.trail[i]
		var age: float = t - float(mark["t"])
		var fade: float = 1.0 - clampf(age / RTBoss2MotionController.TRAIL_LIFE, 0.0, 1.0)
		var p: Vector2 = Vector2(mark["pos"]) - camera
		game.draw_circle(p, 9.0 + (1.0 - fade) * 10.0, Color(1.0, 1.0, 1.0, 0.45 * fade))
		game.draw_circle(p, 5.0, Color(ICE, 0.6 * fade))
	var screen: Vector2 = draw_pos - camera
	if game.boss2_ultimate_timer > 0.0:
		_draw_dash_windup(game, camera, motion, t)
		if _reveal > 0.35 or motion.dash_windup() > 0.0:
			_draw_edge_marker(game, screen, t)
	if hidden <= 0.01 or boss_tex == null:
		return
	# Escondido na neve: nada de silhueta; ele sai andando da nevasca quando vai atacar.


## Linha de gelo que mostra para onde o bote vai, antes de ele sair.
static func _draw_dash_windup(game: Node2D, camera: Vector2, motion, t: float) -> void:
	var w: float = motion.dash_windup()
	if w <= 0.0:
		return
	var a: Vector2 = Vector2(motion.dash["from"]) - camera
	var b: Vector2 = Vector2(motion.dash["to"]) - camera
	var dir: Vector2 = (b - a).normalized()
	var reach: Vector2 = a.lerp(b, minf(1.0, w * 1.4))
	game.draw_line(a, reach, Color(ICE, 0.22 + 0.25 * w), 26.0)
	game.draw_line(a, reach, Color(1.0, 1.0, 1.0, 0.5 + 0.4 * w), 3.0, true)
	var flash: float = 0.5 + 0.5 * sin(t * 30.0)
	game.draw_arc(b, 46.0 * (1.2 - w * 0.2), 0.0, TAU, 28, Color(ICE, 0.35 + 0.4 * w * flash), 3.0, true)
	for i in range(3):
		var c: Vector2 = a.lerp(reach, (float(i) + fposmod(t * 3.0, 1.0)) / 3.0)
		var side: Vector2 = dir.orthogonal() * 10.0
		game.draw_polyline(PackedVector2Array([c - dir * 10.0 + side, c, c - dir * 10.0 - side]), Color(1, 1, 1, 0.8 * w), 3.0, true)


## Fora da tela: olhos gelados presos na borda apontando para o pinguim.
static func _draw_edge_marker(game: Node2D, screen: Vector2, t: float) -> void:
	var view: Vector2 = game.get_viewport_rect().size
	var margin := 44.0
	if screen.x > -20.0 and screen.y > -20.0 and screen.x < view.x + 20.0 and screen.y < view.y + 20.0:
		return
	var mid: Vector2 = view * 0.5
	var d: Vector2 = screen - mid
	var sx: float = (mid.x - margin) / maxf(0.001, absf(d.x))
	var sy: float = (mid.y - margin - 40.0) / maxf(0.001, absf(d.y))
	var p: Vector2 = mid + d * minf(sx, sy)
	var dir: Vector2 = d.normalized()
	var pulse: float = 0.6 + 0.4 * sin(t * 6.0)
	var windup: float = game._boss2_motion().dash_windup()
	var col: Color = Color(1.0, 0.45, 0.4) if windup > 0.0 else ICE
	game.draw_circle(p, 24.0, Color(INK, 0.55))
	game.draw_arc(p, 24.0, 0.0, TAU, 24, Color(col, 0.55 + 0.35 * pulse), 2.5, true)
	var tip: Vector2 = p + dir * 34.0
	var side: Vector2 = dir.orthogonal() * 10.0
	game.draw_colored_polygon(PackedVector2Array([p + dir * 24.0 + side, tip, p + dir * 24.0 - side]), Color(col, 0.85))
	for s_sign in [-1.0, 1.0]:
		var eye: Vector2 = p + Vector2(7.0 * float(s_sign), -2.0)
		game.draw_circle(eye, 5.0, Color(col, 0.3 * pulse))
		game.draw_circle(eye, 2.6, Color(1, 1, 1, 0.95))
