extends RefCounted

## Desenho no mundo dos itens incomuns de 26/11 (RTSkirmishItemsController):
## estalo da Fe Emaculada, raios da Bobina e dos Espinhos, cargas
## da Bobina, anel do Veu e as novas de cura do Pulso. So primitivas.

const AMMO := Color(1.0, 0.86, 0.45)
const VOLT := Color(0.55, 0.85, 1.0)
const THORN := Color(0.85, 0.15, 0.25)
const VEIL := Color(0.7, 0.6, 1.0)
const HEAL := Color(0.5, 1.0, 0.7)


static func draw(game: Node2D, camera: Vector2) -> void:
	var c = game.skirmish_items_controller
	if c == null:
		return
	var t: float = float(game.time_alive)
	for bolt in c.bolts:
		var k: float = float(bolt["life"]) / maxf(0.01, float(bolt["max"]))
		var color: Color = THORN if String(bolt.get("kind", "")) == "espinhos" else VOLT
		_draw_bolt(game, Vector2(bolt["from"]) - camera, Vector2(bolt["to"]) - camera, int(bolt.get("seed", 1)), Color(color, k))
	var me: Vector2 = Vector2(game.player_pos) - camera
	if c.copies(c.BOBINA_ID) > 0 and c.bobina_charges > 0:
		for k in range(c.bobina_charges):
			var a: float = t * 2.0 + TAU * float(k) / float(maxi(1, c.bobina_charges))
			var ready: bool = c.bobina_charges >= c.BOBINA_COST
			game.draw_circle(me + Vector2(0, -34) + Vector2.from_angle(a) * 30.0, 3.0, Color(VOLT, 1.0 if ready else 0.55))
	if c.veiled():
		game.draw_arc(me + Vector2(0, -32), 38.0 + sin(t * 6.0) * 3.0, 0.0, TAU, 32, Color(VEIL, 0.6), 2.0)
		var decoy: Vector2 = c.veu_decoy - camera
		game.draw_arc(decoy, 22.0, 0.0, TAU, 20, Color(VEIL, 0.35), 2.0)
	for flash in c.flashes:
		var k: float = 1.0 - float(flash["life"]) / maxf(0.01, float(flash["max"]))
		var at: Vector2 = Vector2(flash.get("pos", game.player_pos)) - camera
		match String(flash["kind"]):
			"fe":
				game.draw_arc(at, 16.0 + 50.0 * k, 0.0, TAU, 28, Color(AMMO, 1.0 - k), 3.0)
			"veu":
				game.draw_circle(at + Vector2(0, -30), 50.0 * k, Color(VEIL, 0.25 * (1.0 - k)))
			"pulso":
				game.draw_arc(at, 30.0 + float(c.PULSO_RADIUS) * k, 0.0, TAU, 48, Color(HEAL, 0.8 * (1.0 - k)), 5.0)
				game.draw_circle(at, 30.0 + float(c.PULSO_RADIUS) * k, Color(HEAL, 0.08 * (1.0 - k)))


static func _draw_bolt(game: Node2D, from: Vector2, to: Vector2, seed: int, color: Color) -> void:
	var pts := PackedVector2Array([from])
	var side := (to - from).orthogonal().normalized()
	for k in range(1, 6):
		var u: float = float(k) / 6.0
		var jitter: float = sin(float(seed % 97) * 1.7 + float(k) * 2.3) * 10.0
		pts.append(from.lerp(to, u) + side * jitter)
	pts.append(to)
	game.draw_polyline(pts, Color(color.r, color.g, color.b, color.a * 0.5), 5.0)
	game.draw_polyline(pts, Color(1, 1, 1, color.a), 2.0)
