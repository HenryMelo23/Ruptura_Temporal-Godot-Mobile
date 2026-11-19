class_name RTFossilPustuleTetherPresentation
extends RefCounted

## Desenho do cordao umbilical da Pustula Fossil: carne torcida que sai da
## pustula, com ponta de osso afiada. So le estado; placeholder procedural ate a
## arte dedicada (pedido em .agents/codex_requests/fossil_pustule_cord.md).

const FLESH := Color(0.62, 0.22, 0.26)
const FLESH_LIGHT := Color(0.92, 0.5, 0.52)
const VEIN := Color(0.42, 0.9, 0.2)
const BONE := Color(0.95, 0.9, 0.78)


## Cordao em voo (o antigo cuspe): da pustula ate a ponta do projetil.
static func draw_projectile(game: Node2D, bullet: Dictionary, camera: Vector2) -> void:
	var tip := Vector2(bullet["pos"]) - camera
	var dir := Vector2(bullet.get("dir", Vector2.LEFT)).normalized()
	var root := Vector2(bullet.get("source_enemy_pos", Vector2(bullet["pos"]) - dir * 120.0)) - camera
	var pustule: Dictionary = game._fossil_pustule_by_uid(int(bullet.get("source_enemy_uid", -1)))
	if not pustule.is_empty():
		root = Vector2(pustule.get("pos", root + camera)) - camera
	_draw_cord(game, root, tip, float(bullet.get("phase", 0.0)) + float(game.time_alive) * 9.0, 1.0)
	_draw_tip(game, tip, dir)


## Cordao preso ao jogador durante o puxao.
static func draw_pull(game: Node2D, camera: Vector2) -> void:
	var tether: RTFossilPustuleTether = game.fossil_pustule_tether
	if tether.snap_timer > 0.0:
		var p := tether.snap_pos - camera
		var k: float = tether.snap_timer / 0.3
		for i in range(5):
			var a: float = float(i) * 1.26
			game.draw_line(p, p + Vector2.from_angle(a) * (10.0 + 18.0 * (1.0 - k)), Color(FLESH_LIGHT, k), 2.0, true)
	if not tether.is_pulling():
		return
	var anchor := tether.anchor - camera
	var hooked := Vector2(game.player_pos) - camera + Vector2(0.0, 6.0)
	_draw_cord(game, anchor, hooked, float(game.time_alive) * 14.0, 1.0 + 0.4 * (1.0 - tether.progress()))
	var dir := (anchor - hooked).normalized()
	_draw_tip(game, hooked - dir * 6.0, -dir if dir.length() > 0.05 else Vector2.DOWN)


static func _draw_cord(game: Node2D, a: Vector2, b: Vector2, phase: float, tension: float) -> void:
	var length: float = a.distance_to(b)
	if length < 2.0:
		return
	var dir := (b - a) / length
	var side := dir.orthogonal()
	var segments: int = clampi(int(length / 14.0), 6, 28)
	var spine := PackedVector2Array()
	var twist := PackedVector2Array()
	for i in range(segments + 1):
		var u: float = float(i) / float(segments)
		var sag: float = sin(u * PI) * 10.0 / tension
		var wobble: float = sin(u * 9.0 + phase) * 3.0 / tension
		var p := a + dir * length * u + side * (sag + wobble)
		spine.append(p)
		twist.append(p + side * sin(u * 18.0 + phase) * 3.2)
	game.draw_polyline(spine, Color(0.18, 0.04, 0.06, 0.6), 9.0, true)
	game.draw_polyline(spine, FLESH, 6.0, true)
	game.draw_polyline(twist, FLESH_LIGHT, 1.8, true)
	game.draw_polyline(spine, Color(VEIN, 0.55), 1.0, true)


static func _draw_tip(game: Node2D, tip: Vector2, dir: Vector2) -> void:
	var side := dir.orthogonal()
	var spike := PackedVector2Array([tip + dir * 16.0, tip + side * 6.0, tip - dir * 6.0, tip - side * 6.0])
	game.draw_colored_polygon(spike, BONE)
	game.draw_polyline(PackedVector2Array([spike[0], spike[1], spike[2], spike[3], spike[0]]), Color(0.36, 0.3, 0.22, 0.9), 1.4, true)
	game.draw_circle(tip - dir * 6.0, 5.0, FLESH)
