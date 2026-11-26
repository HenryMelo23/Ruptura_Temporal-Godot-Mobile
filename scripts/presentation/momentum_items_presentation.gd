extends RefCounted

## Desenho no mundo dos itens de impulso (RTMomentumItemsController): orbes
## do Espectro Eletrico, marcadores de acumulo sob a Geovana (Ganancia em
## dourado, velocidade em ciano), aneis do Eco da Ruina e o estalo do uso
## guardado da HAB1. Barato para celular: so primitivas.

const GOLD := Color(1.0, 0.78, 0.22)
const VOLT := Color(0.45, 0.9, 1.0)
const ECO := Color(1.0, 0.4, 0.32)


static func draw(game: Node2D, camera: Vector2) -> void:
	var c = game.momentum_items_controller
	if c == null:
		return
	var t: float = float(game.time_alive)
	for orb in c.orbs:
		_draw_orb(game, Vector2(orb["pos"]) - camera, t + float(orb.get("phase", 0.0)), clampf(float(orb["life"]) / 2.0, 0.0, 1.0))
	var me: Vector2 = Vector2(game.player_pos) - camera
	_draw_pips(game, me + Vector2(0, 30), c.ganancia_stacks, c.ganancia_max_stacks(), GOLD, clampf(c.ganancia_timer / 1.5, 0.0, 1.0))
	_draw_pips(game, me + Vector2(0, 38), c.speed_stacks, c.speed_max_stacks(), VOLT, clampf(c.speed_timer / 1.5, 0.0, 1.0))
	if c.speed_stacks > 0 and c.speed_timer > 0.0:
		for k in range(mini(3, c.speed_stacks)):
			var a: float = t * 6.0 + float(k) * TAU / 3.0
			game.draw_line(me + Vector2.from_angle(a) * 22.0, me + Vector2.from_angle(a + 0.5) * 30.0 + Vector2(0, -8), Color(VOLT, 0.55), 2.0)
	var pending: int = c.pending_eco_hits()
	for k in range(pending):
		var r: float = 34.0 + float(k) * 9.0 + sin(t * 8.0 + float(k)) * 2.0
		game.draw_arc(me + Vector2(0, -30), r, 0.0, TAU, 28, Color(ECO, 0.45), 2.0)
	for flash in c.flashes:
		var k: float = 1.0 - float(flash["life"]) / maxf(0.01, float(flash["max"]))
		match String(flash["kind"]):
			"espectro":
				game.draw_arc(Vector2(flash["pos"]) - camera, 14.0 + 40.0 * k, 0.0, TAU, 24, Color(VOLT, 1.0 - k), 3.0)
			"eco":
				game.draw_arc(me + Vector2(0, -30), 30.0 + 50.0 * k, 0.0, TAU, 32, Color(ECO, 0.9 * (1.0 - k)), 4.0)
			"eco_hit":
				game.draw_circle(me + Vector2(0, -30), 26.0 * (1.0 - k), Color(ECO, 0.3 * (1.0 - k)))
			"retorno":
				game.draw_arc(me + Vector2(0, -30), 24.0 + 30.0 * k, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - k), 24, Color(0.3, 0.8, 1.0, 1.0 - k), 3.0)


static func _draw_orb(game: Node2D, at: Vector2, t: float, fade: float) -> void:
	var bob: Vector2 = Vector2(0, sin(t * 3.0) * 4.0)
	var glow: Texture2D = RTWorldLighting.light_texture()
	game.draw_texture_rect(glow, Rect2(at + bob - Vector2(34, 34), Vector2(68, 68)), false, Color(VOLT, 0.45 * fade))
	game.draw_circle(at + bob, 9.0, Color(0.85, 0.98, 1.0, fade))
	game.draw_arc(at + bob, 13.0, t * 4.0, t * 4.0 + PI * 1.3, 12, Color(VOLT, fade), 2.0)
	for k in range(3):
		var a: float = t * 5.0 + float(k) * TAU / 3.0
		var p: Vector2 = at + bob + Vector2.from_angle(a) * 12.0
		game.draw_line(p, p + Vector2.from_angle(a + 1.2) * 7.0, Color(VOLT, 0.8 * fade), 1.5)


static func _draw_pips(game: Node2D, center: Vector2, value: int, cap: int, color: Color, fade: float) -> void:
	if value <= 0 or cap <= 0:
		return
	var shown: int = mini(value, 15)
	var w: float = float(shown) * 6.0
	for k in range(shown):
		var p := center + Vector2(-w * 0.5 + 3.0 + float(k) * 6.0, 0)
		game.draw_circle(p, 2.2, Color(color, (1.0 if value >= cap else 0.8) * maxf(0.35, fade)))
