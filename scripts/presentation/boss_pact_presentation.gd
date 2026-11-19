class_name RTBossPactPresentation
extends RefCounted

## Visual dos pactos: perigos telegrafados no mundo e a escuridao de visao.

const BOLT := Color(0.72, 0.9, 1.0)
const METEOR := Color(1.0, 0.56, 0.24)
const BURST := Color(0.66, 1.0, 0.36)
const BLINK := Color(0.74, 0.5, 1.0)
const GUST := Color(0.82, 0.96, 1.0)


static func draw_world(game: Node2D, camera: Vector2) -> void:
	var pacts: RTBossPactController = game._boss_pacts()
	if pacts.hazards.is_empty():
		return
	var t: float = float(game.time_alive)
	for h in pacts.hazards:
		var kind: String = String(h["kind"])
		var k: float = clampf(float(h["t"]) / maxf(0.01, float(h["warn"])), 0.0, 1.0)
		if float(h["t"]) < 0.0:
			continue
		var p: Vector2 = Vector2(h["pos"]) - camera
		match kind:
			"lightning":
				_ring(game, p, RTBossPactController.LIGHTNING_RADIUS, BOLT, k, t)
				# Nuvem carregando acima do ponto.
				game.draw_circle(p + Vector2(0, -150), 26.0 + 10.0 * k, Color(0.2, 0.26, 0.4, 0.35 + 0.3 * k))
				if fposmod(t * 14.0, 1.0) < 0.3 * k:
					game.draw_line(p + Vector2(-6, -140), p + Vector2(4, -110), Color(BOLT, 0.8), 2.0, true)
			"bolt":
				var a: float = 1.0 - k
				var top: Vector2 = p + Vector2(0, -420)
				var pts := PackedVector2Array([top])
				for i in range(1, 7):
					var u: float = float(i) / 7.0
					pts.append(top.lerp(p, u) + Vector2(sin(float(i) * 7.3 + float(h["pos"].x)) * 18.0, 0.0))
				pts.append(p)
				game.draw_polyline(pts, Color(BOLT, 0.45 * a), 10.0, true)
				game.draw_polyline(pts, Color(1, 1, 1, 0.95 * a), 3.0, true)
				game.draw_circle(p, 40.0 * a + 10.0, Color(BOLT, 0.35 * a))
			"meteor":
				_ring(game, p, RTBossPactController.METEOR_RADIUS, METEOR, k, t)
				var fall: Vector2 = p + Vector2(160, -360) * (1.0 - k)
				game.draw_circle(fall, 9.0 + 6.0 * k, Color(METEOR, 0.9))
				game.draw_line(fall, fall + Vector2(60, -130) * 0.4, Color(METEOR, 0.45), 6.0, true)
			"burst":
				_ring(game, p, RTBossPactController.BURST_RADIUS, BURST, k, t)
				game.draw_circle(p, 10.0 + 14.0 * k, Color(BURST, 0.35 + 0.4 * k))
			"blink":
				var from: Vector2 = Vector2(h.get("from", h["pos"])) - camera
				game.draw_line(from, p, Color(BLINK, 0.25 + 0.4 * k), 3.0, true)
				_ring(game, p, 34.0, BLINK, k, t)
				game.draw_arc(from, 30.0 + 10.0 * sin(t * 16.0), 0.0, TAU, 24, Color(BLINK, 0.6 * k), 2.0, true)
			"gust":
				var dir: Vector2 = Vector2(h["dir"])
				for i in range(3):
					var base: Vector2 = Vector2(game.player_pos) - camera + dir.orthogonal() * (float(i) - 1.0) * 22.0
					var off: float = fposmod(t * 2.2 + float(i) * 0.3, 1.0) * 70.0
					var a0: Vector2 = base + dir * (20.0 + off)
					game.draw_line(a0, a0 + dir * 40.0, Color(GUST, 0.25 + 0.5 * k), 3.0, true)
					game.draw_polyline(PackedVector2Array([a0 + dir * 40.0 + dir.orthogonal() * 8.0, a0 + dir * 52.0, a0 + dir * 40.0 - dir.orthogonal() * 8.0]), Color(GUST, 0.3 + 0.5 * k), 3.0, true)
			"tremor":
				var pp: Vector2 = Vector2(game.player_pos) - camera
				for r in range(3):
					game.draw_arc(pp + Vector2(0, 20), 40.0 + float(r) * 26.0 + k * 20.0, 0.0, TAU, 28, Color(0.86, 0.7, 0.5, (0.5 - float(r) * 0.14) * k), 2.0, true)


static func _ring(game: Node2D, p: Vector2, radius: float, color: Color, k: float, t: float) -> void:
	game.draw_circle(p, radius, Color(color, 0.08 + 0.12 * k))
	game.draw_arc(p, radius, 0.0, TAU, 32, Color(color, 0.55 + 0.4 * k), 2.5, true)
	game.draw_arc(p, radius * k, 0.0, TAU, 28, Color(color, 0.7), 2.0, true)
	if k > 0.7 and fposmod(t * 12.0, 1.0) < 0.5:
		game.draw_arc(p, radius + 6.0, 0.0, TAU, 32, Color(1, 1, 1, 0.6), 1.5, true)


## Escuridao dos pactos de visao (tela). Anel em degrade ao redor da personagem.
static func draw_darkness(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	var pacts: RTBossPactController = game._boss_pacts()
	if not pacts.has_mech("darkness"):
		return
	var radius: float = float(pacts.mech["darkness"])
	var center: Vector2 = Vector2(game.player_pos) - camera + Vector2(0, -20)
	var far: float = viewport.length() + 200.0
	var low: bool = game._memory_saver_active() or bool(game.gfx_low_resource)
	var segs: int = 28 if low else 48
	var clear_c := Color(0.0, 0.0, 0.02, 0.0)
	var mid_c := Color(0.0, 0.0, 0.03, 0.82)
	var dark_c := Color(0.0, 0.0, 0.03, 0.95)
	var r_mid: float = radius + 110.0
	for i in range(segs):
		var a0: float = float(i) * TAU / float(segs)
		var a1: float = float(i + 1) * TAU / float(segs)
		var d0 := Vector2.from_angle(a0)
		var d1 := Vector2.from_angle(a1)
		game.draw_polygon(PackedVector2Array([center + d0 * radius, center + d1 * radius, center + d1 * r_mid, center + d0 * r_mid]), PackedColorArray([clear_c, clear_c, mid_c, mid_c]))
		game.draw_polygon(PackedVector2Array([center + d0 * r_mid, center + d1 * r_mid, center + d1 * far, center + d0 * far]), PackedColorArray([mid_c, mid_c, dark_c, dark_c]))
