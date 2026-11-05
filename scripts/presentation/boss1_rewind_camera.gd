class_name RTRewindCamera
extends RefCounted

## Cinematica da ultimate do Cronoguejo (Crono-Ruptura) quando a onda temporal acerta:
## soco de zoom no jogador e tela trincando, depois o mundo gira levemente para tras
## enquanto o relogio rebobina (estetica de fita VHS) e, no fim, um soco de volta com
## clarao de "linha restaurada". Puramente visual e local: usa o canvas_transform do
## viewport (mundo + camada do mapa) e desenha o resto em espaco de tela.

const IMPACT_TIME := 0.14
const IMPACT_ZOOM := 1.3
const REWIND_ZOOM := 1.14
const RESTORE_PUNCH := 1.22
const REWIND_TILT := 0.045
const AFTERGLOW_TIME := 0.42
const CRACKS := 9

## Clarao final: o rewind termina limpando o estado, entao a camera guarda o fim aqui.
static var _was_active := false
static var _afterglow := 0.0
static var _last_ms := 0


static func _ease(t: float) -> float:
	var x: float = clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func total_time(game: Node2D) -> float:
	return float(game.BOSS1_CLOCK_TRAVEL_TIME) + float(game.BOSS1_CLOCK_TURN_TIME)


static func active(game: Node2D) -> bool:
	return game.mode == "game" and game.current_phase == 1 and not game.boss1_rewind_sequence.is_empty()


static func elapsed(game: Node2D) -> float:
	return float(game.boss1_rewind_sequence.get("elapsed", 0.0)) + float(game._boss1_visual_prediction())


static func zoom_at(game: Node2D, e: float) -> float:
	var travel: float = float(game.BOSS1_CLOCK_TRAVEL_TIME)
	var total: float = total_time(game)
	if e < IMPACT_TIME:
		return lerpf(1.0, IMPACT_ZOOM, _ease(e / IMPACT_TIME))
	if e < travel:
		return lerpf(IMPACT_ZOOM, REWIND_ZOOM, _ease((e - IMPACT_TIME) / (travel - IMPACT_TIME)))
	if e < total - 0.22:
		return REWIND_ZOOM + sin((e - travel) * 2.4) * 0.018
	if e < total - 0.1:
		return lerpf(REWIND_ZOOM, RESTORE_PUNCH, _ease((e - (total - 0.22)) / 0.12))
	return lerpf(RESTORE_PUNCH, 1.0, _ease((e - (total - 0.1)) / 0.1))


static func tilt_at(game: Node2D, e: float) -> float:
	var travel: float = float(game.BOSS1_CLOCK_TRAVEL_TIME)
	var total: float = total_time(game)
	if e < travel:
		# Tranco do impacto.
		return sin(clampf(e / 0.3, 0.0, 1.0) * PI) * 0.02
	var p: float = clampf((e - travel) / maxf(0.01, total - travel - 0.1), 0.0, 1.0)
	# Gira para tras (anti-horario) e volta no fim.
	return -sin(p * PI) * REWIND_TILT + sin(e * 7.0) * 0.004 * sin(p * PI)


static func clear(game: Node2D) -> void:
	var vp: Viewport = game.get_viewport()
	if vp != null and vp.canvas_transform != Transform2D.IDENTITY:
		vp.canvas_transform = Transform2D.IDENTITY


## Chamado depois do RTExecutionCamera.apply; so assume a camera quando a execucao
## da Lacerante nao esta ativa.
static func apply(game: Node2D, viewport: Vector2, camera: Vector2) -> void:
	var now: int = Time.get_ticks_msec()
	var dt: float = clampf(float(now - _last_ms) / 1000.0, 0.0, 0.1) if _last_ms > 0 else 0.0
	_last_ms = now
	var is_active: bool = active(game)
	if _was_active and not is_active and game.mode == "game":
		_afterglow = AFTERGLOW_TIME
	_was_active = is_active
	_afterglow = maxf(0.0, _afterglow - dt)
	if RTExecutionCamera.active(game):
		return
	var vp: Viewport = game.get_viewport()
	if vp == null:
		return
	if not is_active:
		clear(game)
		return
	var e: float = elapsed(game)
	var s: float = zoom_at(game, e)
	var r: float = tilt_at(game, e)
	var focus: Vector2 = Vector2(game.player_pos) - camera + Vector2(0.0, -30.0)
	# Comeca colado no jogador e vai centralizando enquanto o relogio chega.
	var center_weight: float = _ease((e - IMPACT_TIME) / 0.8) * 0.55
	var screen_anchor: Vector2 = focus.lerp(viewport * 0.5, center_weight)
	vp.canvas_transform = Transform2D(r, Vector2(s, s), 0.0, screen_anchor) * Transform2D(0.0, -focus)


static func afterglow_active() -> bool:
	return _afterglow > 0.0


## Camada de tela: vinheta, fita rebobinando, trincas do impacto e o relogio.
static func draw_overlay(game: Node2D, viewport: Vector2, camera: Vector2) -> void:
	var vp: Viewport = game.get_viewport()
	if vp == null:
		return
	game.draw_set_transform_matrix(vp.canvas_transform.affine_inverse())
	var low: bool = game._get_boss_wave_quality_profile() == "LOW"
	var e: float = elapsed(game)
	var travel: float = float(game.BOSS1_CLOCK_TRAVEL_TIME)
	var total: float = total_time(game)
	var fade_in: float = _ease(e / 0.25)
	var fade_out: float = 1.0 - _ease((e - (total - 0.2)) / 0.2)
	var k: float = fade_in * fade_out
	_grade(game, viewport, k)
	if e < 0.5:
		var player_screen: Vector2 = vp.canvas_transform * (Vector2(game.player_pos) - camera)
		_impact(game, player_screen, e, low)
	if e >= travel * 0.6:
		_vhs(game, viewport, e, k, low)
	game.WorldEnvironmentPresentation._draw_boss1_rewind_overlay(game, viewport, camera)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Clarao de "linha restaurada" depois que o rewind acaba (sem transform).
static func draw_afterglow(game: Node2D, viewport: Vector2) -> void:
	if _afterglow <= 0.0:
		return
	var t: float = 1.0 - _afterglow / AFTERGLOW_TIME
	var center: Vector2 = viewport * 0.5
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.86, 0.98, 1.0, 0.42 * (1.0 - t) * (1.0 - t)), true)
	var r: float = lerpf(60.0, viewport.length() * 0.6, _ease(t))
	game.draw_arc(center, r, 0.0, TAU, 96, Color(0.42, 0.94, 1.0, 0.8 * (1.0 - t)), 10.0 * (1.0 - t) + 2.0, true)
	game.draw_arc(center, r * 0.82, 0.0, TAU, 96, Color(1.0, 0.42, 0.78, 0.5 * (1.0 - t)), 4.0, true)


static func _grade(game: Node2D, viewport: Vector2, k: float) -> void:
	if k <= 0.0:
		return
	# Tom "memoria": azul frio por cima de tudo + vinheta em degrade nas bordas.
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.02, 0.1, 0.22, 0.2 * k), true)
	var edge := Color(0.0, 0.01, 0.04, 0.78 * k)
	var clear_c := Color(0.0, 0.01, 0.04, 0.0)
	var band: float = minf(viewport.x, viewport.y) * 0.24
	var w: float = viewport.x
	var h: float = viewport.y
	game.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - band, band), Vector2(band, band)]), PackedColorArray([edge, edge, clear_c, clear_c]))
	game.draw_polygon(PackedVector2Array([Vector2(0, h), Vector2(band, h - band), Vector2(w - band, h - band), Vector2(w, h)]), PackedColorArray([edge, clear_c, clear_c, edge]))
	game.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(band, band), Vector2(band, h - band), Vector2(0, h)]), PackedColorArray([edge, clear_c, clear_c, edge]))
	game.draw_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w, h), Vector2(w - band, h - band), Vector2(w - band, band)]), PackedColorArray([edge, edge, clear_c, clear_c]))


static func _impact(game: Node2D, at: Vector2, e: float, low: bool) -> void:
	var t: float = clampf(e / 0.5, 0.0, 1.0)
	var flash: float = 1.0 - _ease(e / 0.18)
	if flash > 0.0:
		game.draw_circle(at, 90.0 + e * 600.0, Color(0.86, 0.98, 1.0, 0.36 * flash))
	# Vidro do tempo trincando a partir do jogador.
	var alpha: float = (1.0 - t) * 0.95
	var reach: float = lerpf(40.0, 420.0, _ease(e / 0.16))
	for i in range(CRACKS if not low else 6):
		var base: float = float(i) * TAU / float(CRACKS) + 0.3
		var pts := PackedVector2Array([at])
		var p: Vector2 = at
		for seg in range(5):
			var a: float = base + sin(float(i * 7 + seg * 3)) * 0.35
			p += Vector2.from_angle(a) * reach / 5.0
			pts.append(p)
		game.draw_polyline(pts, Color(0.01, 0.04, 0.1, alpha * 0.8), 5.0, true)
		game.draw_polyline(pts, Color(0.82, 0.98, 1.0, alpha), 1.8, true)
		if i % 2 == 0:
			var mid: Vector2 = pts[2]
			game.draw_line(mid, mid + Vector2.from_angle(base + 1.2) * reach * 0.18, Color(0.82, 0.98, 1.0, alpha * 0.7), 1.2, true)
	game.draw_arc(at, 30.0 + e * 380.0, 0.0, TAU, 64, Color(1.0, 0.42, 0.78, 0.8 * (1.0 - t)), 4.0, true)


static func _vhs(game: Node2D, viewport: Vector2, e: float, k: float, low: bool) -> void:
	if k <= 0.0:
		return
	# Faixas de "tracking" passando de baixo para cima, como fita rebobinando.
	for band in range(3 if low else 5):
		var y: float = fposmod(-e * 260.0 + float(band) * viewport.y / 5.0 + sin(e * 3.0 + band) * 18.0, viewport.y)
		var thickness: float = 3.0 + float(band % 3) * 4.0
		game.draw_rect(Rect2(0.0, y, viewport.x, thickness), Color(0.78, 0.96, 1.0, 0.06 * k), true)
		var jitter: float = sin(e * 41.0 + band * 1.7) * 26.0
		game.draw_rect(Rect2(jitter + viewport.x * 0.1, y + thickness, viewport.x * 0.5, 1.5), Color(1.0, 0.42, 0.78, 0.18 * k), true)
	# Particulas girando para tras em volta do relogio (o tempo correndo ao contrario).
	var center: Vector2 = viewport * 0.5
	for i in range(14 if low else 32):
		var life: float = fposmod(e * 0.55 + float(i) * 0.618, 1.0)
		var ang: float = float(i) * 2.39996 - e * 1.6 - life * 1.2
		var dist: float = lerpf(viewport.length() * 0.5, 130.0, life)
		var pos: Vector2 = center + Vector2.from_angle(ang) * dist
		var tail: Vector2 = center + Vector2.from_angle(ang + 0.12) * (dist + 26.0)
		game.Boss1VFX.streak(game, tail, pos, Color(0.5, 0.92, 1.0, sin(life * PI) * 0.7 * k), 4.0)
	# Simbolo de rebobinar (dois triangulos) no canto, piscando.
	var blink: float = 1.0 if fposmod(e, 0.8) < 0.55 else 0.35
	var o := Vector2(44.0, 44.0)
	for tri in range(2):
		var x: float = o.x + float(tri) * 22.0
		game.draw_colored_polygon(PackedVector2Array([Vector2(x, o.y), Vector2(x + 22.0, o.y - 14.0), Vector2(x + 22.0, o.y + 14.0)]), Color(0.86, 0.98, 1.0, 0.9 * k * blink))
	game._draw_centered("REBOBINANDO", o + Vector2(118.0, 6.0), 16, Color(0.86, 0.98, 1.0, 0.9 * k * blink))
