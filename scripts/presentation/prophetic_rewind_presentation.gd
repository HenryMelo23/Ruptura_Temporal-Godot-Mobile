class_name RTPropheticRewindPresentation
extends RefCounted

## Desenho da Profecia (RTPropheticRewind). So le o estado do controller.
## - HUD: retangulo dourado com um olho sobre a barra de vida. No presagio ele
##   entra fechado e abre; depois mostra a contagem dos 10 s.
## - Mundo: no replay, o "eu do passado" (onde ela estava na primeira vez) e
##   onde cada inimigo gravado vai estar logo adiante.
## - Tela: tom dourado e linhas de rebobinar enquanto o tempo volta.

const GOLD := Color(1.0, 0.84, 0.36)
const GOLD_DARK := Color(0.36, 0.25, 0.05)
const INK := Color(0.05, 0.04, 0.02, 0.92)
const PANEL_SIZE := Vector2(116.0, 38.0)


static func draw_hud(game: Node2D, health_rect: Rect2) -> void:
	var rewind: RTPropheticRewind = game.prophetic_rewind
	# Em recarga nao ha olho: ele so aparece quando a profecia comeca.
	if not rewind.available() or rewind.state == RTPropheticRewind.STATE_COOLDOWN:
		return
	var state: String = rewind.state
	var t: float = float(game.time_alive)
	var size: Vector2 = PANEL_SIZE
	var appear: float = 1.0
	if state == RTPropheticRewind.STATE_OMEN:
		appear = clampf(rewind.clock / RTPropheticRewind.OMEN_OPEN_START, 0.0, 1.0)
		appear = 1.0 - pow(1.0 - appear, 3.0)
	var top: float = maxf(2.0, health_rect.position.y - size.y * 0.55)
	var rect := Rect2(Vector2(health_rect.get_center().x - size.x * 0.5, top), size)
	rect = Rect2(rect.get_center() - rect.size * 0.5 * appear, rect.size * appear)
	var alpha: float = 1.0
	game.draw_rect(rect, Color(INK.r, INK.g, INK.b, INK.a * alpha), true)
	var glow: float = 0.5 + 0.5 * sin(t * 6.0)
	var border := Color(GOLD.r, GOLD.g, GOLD.b, (0.85 + 0.15 * glow) * alpha)
	game.draw_rect(rect, border, false, 2.0)
	game.draw_rect(rect.grow(-3.0), Color(GOLD_DARK.r, GOLD_DARK.g, GOLD_DARK.b, 0.6 * alpha), false, 1.0)
	if appear < 0.6:
		return
	var eye_center := Vector2(rect.position.x + rect.size.y * 0.95, rect.get_center().y)
	draw_eye(game, eye_center, rect.size.y * 0.42, rewind.eye_open(), t, alpha, state == RTPropheticRewind.STATE_REWINDING)
	var text_pos := Vector2(eye_center.x + rect.size.y * 0.62, rect.get_center().y + 6.0)
	var text_w: float = rect.end.x - text_pos.x - 6.0
	match state:
		RTPropheticRewind.STATE_OMEN:
			if rewind.eye_open() >= 1.0:
				var flash: float = clampf((rewind.clock - RTPropheticRewind.OMEN_OPEN_END) / (RTPropheticRewind.OMEN_TIME - RTPropheticRewind.OMEN_OPEN_END), 0.0, 1.0)
				game.draw_arc(eye_center, rect.size.y * (0.5 + flash * 1.4), 0.0, TAU, 32, Color(GOLD.r, GOLD.g, GOLD.b, 1.0 - flash), 2.0)
			game.draw_string(game.font, text_pos, "10.0", HORIZONTAL_ALIGNMENT_CENTER, text_w, 16, Color(GOLD.r, GOLD.g, GOLD.b, rewind.eye_open()))
		RTPropheticRewind.STATE_REWINDING:
			game.draw_string(game.font, text_pos, "<<", HORIZONTAL_ALIGNMENT_CENTER, text_w, 18, GOLD.lerp(Color.WHITE, glow * 0.5))
		_:
			var left: float = rewind.time_left()
			var color: Color = GOLD if state == RTPropheticRewind.STATE_RECORDING else GOLD.lerp(Color(0.6, 1.0, 0.95), 0.5)
			game.draw_string(game.font, text_pos, "%.1f" % left, HORIZONTAL_ALIGNMENT_CENTER, text_w, 16, color)
			var bar := Rect2(Vector2(rect.position.x + 4.0, rect.end.y - 5.0), Vector2((rect.size.x - 8.0) * left / RTPropheticRewind.WINDOW, 2.0))
			game.draw_rect(bar, color, true)


## Olho amendoado: `open` 0 = palpebra fechada (linha com cilios), 1 = aberto.
static func draw_eye(game: Node2D, center: Vector2, radius: float, open: float, t: float, alpha: float, spinning: bool) -> void:
	var gold := Color(GOLD.r, GOLD.g, GOLD.b, alpha)
	var lid: float = radius * 0.58 * open
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	var steps := 14
	for i in range(steps + 1):
		var x: float = lerpf(-radius, radius, float(i) / float(steps))
		var bulge: float = 1.0 - pow(x / radius, 2.0)
		upper.append(center + Vector2(x, -lid * bulge))
		lower.append(center + Vector2(x, lid * bulge))
	if open > 0.05:
		var shape := PackedVector2Array(upper)
		for i in range(lower.size() - 1, -1, -1):
			shape.append(lower[i])
		game.draw_colored_polygon(shape, Color(0.98, 0.94, 0.82, 0.95 * alpha))
		var iris_r: float = radius * 0.42 * minf(1.0, open * 1.25)
		var look := Vector2(sin(t * 1.3) * radius * 0.12, 0.0)
		game.draw_circle(center + look, iris_r, Color(0.86, 0.6, 0.08, alpha))
		game.draw_circle(center + look, iris_r * 0.72, Color(1.0, 0.82, 0.24, alpha))
		var slit_h: float = iris_r * 0.85
		var slit_w: float = iris_r * (0.22 if not spinning else 0.5)
		game.draw_colored_polygon(PackedVector2Array([center + look + Vector2(0, -slit_h), center + look + Vector2(slit_w, 0), center + look + Vector2(0, slit_h), center + look + Vector2(-slit_w, 0)]), Color(0.05, 0.03, 0.0, alpha))
		game.draw_circle(center + look + Vector2(-iris_r * 0.35, -iris_r * 0.35), iris_r * 0.16, Color(1, 1, 1, 0.85 * alpha))
		if spinning:
			var a: float = -t * 9.0
			game.draw_arc(center, radius * 1.05, a, a + PI * 1.4, 18, gold, 2.0)
	game.draw_polyline(upper, gold, 2.0, true)
	game.draw_polyline(lower, gold, 1.5 if open > 0.05 else 2.0, true)
	if open <= 0.05:
		for i in range(5):
			var x: float = lerpf(-radius * 0.6, radius * 0.6, float(i) / 4.0)
			game.draw_line(center + Vector2(x, 0.0), center + Vector2(x * 1.15, radius * 0.32), gold, 1.4)


static func draw_world(game: Node2D, camera: Vector2) -> void:
	var rewind: RTPropheticRewind = game.prophetic_rewind
	if not rewind.replaying():
		return
	var t: float = float(game.time_alive)
	var past: Vector2 = rewind.past_self_position()
	if past.is_finite():
		var p: Vector2 = past - camera
		var now: Vector2 = Vector2(game.player_pos) - camera
		var segs: int = int(clampf(p.distance_to(now) / 14.0, 1.0, 40.0))
		for i in range(0, segs, 2):
			game.draw_line(p.lerp(now, float(i) / float(segs)), p.lerp(now, float(i + 1) / float(segs)), Color(GOLD.r, GOLD.g, GOLD.b, 0.35), 1.5)
		game.draw_circle(p + Vector2(0, -30), 22.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.16))
		game.draw_arc(p + Vector2(0, -30), 24.0, 0.0, TAU, 28, Color(GOLD.r, GOLD.g, GOLD.b, 0.7), 2.0)
		draw_eye(game, p + Vector2(0, -30), 11.0, 1.0, t, 0.85, false)
	for future in rewind.future_positions(0.55):
		var f: Vector2 = future - camera
		game.draw_arc(f, 18.0 + sin(t * 8.0) * 2.0, 0.0, TAU, 20, Color(GOLD.r, GOLD.g, GOLD.b, 0.5), 1.5)


static func draw_screen(game: Node2D, viewport: Vector2) -> void:
	var rewind: RTPropheticRewind = game.prophetic_rewind
	if rewind.state == RTPropheticRewind.STATE_REWINDING:
		var k: float = clampf(rewind.clock / RTPropheticRewind.REWIND_TIME, 0.0, 1.0)
		game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.55, 0.38, 0.08, 0.22 + 0.12 * sin(k * PI)), true)
		var offset: float = fmod(float(game.time_alive) * 900.0, 24.0)
		var y: float = -offset
		while y < viewport.y:
			game.draw_line(Vector2(0, y), Vector2(viewport.x, y), Color(1.0, 0.9, 0.6, 0.07), 2.0)
			y += 24.0
		game._draw_centered_outlined("O TEMPO VOLTA", Vector2(viewport.x * 0.5, viewport.y * 0.3), 30, GOLD, Color(0, 0, 0, 0.9), 4)
		draw_eye(game, Vector2(viewport.x * 0.5, viewport.y * 0.3 - 54.0), 26.0, 1.0, float(game.time_alive), 1.0, true)
	elif rewind.replaying():
		var pulse: float = 0.5 + 0.5 * sin(float(game.time_alive) * 4.0)
		game.draw_rect(Rect2(Vector2.ZERO, viewport).grow(-3.0), Color(GOLD.r, GOLD.g, GOLD.b, 0.25 + 0.2 * pulse), false, 6.0)
