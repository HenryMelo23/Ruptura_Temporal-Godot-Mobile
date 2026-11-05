class_name RTSuturerThreatPresentation
extends RefCounted

## Visual das mecanicas novas do Suturador (RTSuturerThreatController).

const AMBER := Color(1.0, 0.68, 0.18)
const AMBER_LIGHT := Color(1.0, 0.9, 0.56)
const INK := Color(0.1, 0.05, 0.0)


static func _ctrl(game: Node2D) -> RTSuturerThreatController:
	if game.amber_suturer_controller == null:
		return null
	return game.amber_suturer_controller._threat


static func _suturer_pos(game: Node2D) -> Vector2:
	var enemy: Dictionary = game.amber_suturer_controller.active_enemy()
	return Vector2(enemy.get("pos", Vector2.ZERO)) if not enemy.is_empty() else Vector2(-99999, -99999)


## Camada do chao (antes dos inimigos).
static func draw_world(game: Node2D, camera: Vector2) -> void:
	var ctrl := _ctrl(game)
	if ctrl == null:
		return
	var t: float = float(game.time_alive)
	var spos: Vector2 = _suturer_pos(game)
	if spos.x < -90000.0:
		return
	var s: Vector2 = spos - camera
	# Pele de Ambar: fios dos nos ate ele, com pulsos de cura correndo para dentro.
	for node_value in ctrl.tethers:
		var n: Vector2 = Vector2(node_value) - camera
		game.draw_line(n, s, Color(INK, 0.5), 7.0, true)
		game.draw_line(n, s, Color(AMBER, 0.6), 3.0, true)
		for k in range(3):
			var f: float = fposmod(t * 0.9 + float(k) / 3.0, 1.0)
			game.draw_circle(n.lerp(s, f), 4.0, Color(AMBER_LIGHT, 0.9 * sin(f * PI)))
	if not ctrl.tethers.is_empty():
		var pulse: float = 0.5 + 0.5 * sin(t * 6.0)
		game.draw_arc(s + Vector2(0, 10), 70.0 + pulse * 6.0, 0.0, TAU, 40, Color(AMBER, 0.55), 3.0, true)
		game._draw_centered("+", s + Vector2(46, -70 - pulse * 10.0), 22, Color(AMBER_LIGHT, 0.9))
	# Cadaveres que ele pode costurar.
	for corpse_value in ctrl.corpses:
		var c: Vector2 = Vector2(Dictionary(corpse_value)["pos"]) - camera
		game.draw_line(c + Vector2(-8, -8), c + Vector2(8, 8), Color(AMBER, 0.45), 2.0, true)
		game.draw_line(c + Vector2(8, -8), c + Vector2(-8, 8), Color(AMBER, 0.45), 2.0, true)
	# Remendo Vivo: linha de costura em zigue-zague ate cada corpo, poca de ambar crescendo.
	if not ctrl.stitch.is_empty():
		var p: float = clampf(float(ctrl.stitch["age"]) / RTSuturerThreatController.STITCH_TELEGRAPH, 0.0, 1.0)
		for target_value in ctrl.stitch["targets"]:
			var target: Vector2 = Vector2(Dictionary(target_value)["pos"]) - camera
			var pts := PackedVector2Array()
			var steps := 14
			var side: Vector2 = (target - s).normalized().orthogonal()
			for i in range(steps + 1):
				var u: float = float(i) / float(steps) * p
				pts.append(s.lerp(target, u) + side * (8.0 if i % 2 == 0 else -8.0))
			game.draw_polyline(pts, Color(INK, 0.7), 5.0, true)
			game.draw_polyline(pts, Color(AMBER, 0.95), 2.0, true)
			game.draw_circle(target, 14.0 + p * 22.0, Color(AMBER, 0.18 + p * 0.25))
			game.draw_arc(target, 14.0 + p * 22.0, 0.0, TAU, 28, Color(AMBER_LIGHT, 0.8), 2.0, true)


## Camada por cima dos inimigos: casulo, remendados e elites.
static func draw_over(game: Node2D, camera: Vector2) -> void:
	var ctrl := _ctrl(game)
	var t: float = float(game.time_alive)
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		var elite: bool = bool(enemy.get("amber_elite", false))
		var patched: bool = bool(enemy.get("amber_patched", false))
		if not elite and not patched:
			continue
		var world: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
		if not game._world_point_in_view(world, camera, 80.0):
			continue
		var p: Vector2 = world - camera
		if elite:
			var flare: float = 0.5 + 0.5 * sin(t * 7.0 + float(int(enemy.get("uid", 0)) % 9))
			game.draw_arc(p, 40.0 + flare * 4.0, 0.0, TAU, 32, Color(INK, 0.6), 7.0, true)
			game.draw_arc(p, 40.0 + flare * 4.0, 0.0, TAU, 32, Color(1.0, 0.5, 0.1, 0.9), 3.5, true)
			var crown: Vector2 = p + Vector2(0, -58)
			game.draw_colored_polygon(PackedVector2Array([crown + Vector2(-12, 6), crown + Vector2(-12, -4), crown + Vector2(-6, 2), crown + Vector2(0, -8), crown + Vector2(6, 2), crown + Vector2(12, -4), crown + Vector2(12, 6)]), Color(1.0, 0.7, 0.16))
		else:
			# Costuras de ambar no corpo remendado.
			for k in range(3):
				var a: float = float(k) * 2.1 + 0.4
				var c: Vector2 = p + Vector2.from_angle(a) * 20.0
				game.draw_line(c + Vector2(-5, -3), c + Vector2(5, 3), Color(AMBER, 0.9), 2.0, true)
			game.draw_arc(p, 30.0, 0.0, TAU, 24, Color(AMBER, 0.45), 2.0, true)
	if ctrl == null or ctrl.cocoon.is_empty():
		return
	var cp: Vector2 = Vector2(ctrl.cocoon["pos"]) - camera
	var q: float = clampf(float(ctrl.cocoon["age"]) / RTSuturerThreatController.COCOON_TIME, 0.0, 1.0)
	var hex := PackedVector2Array()
	for i in range(7):
		var a2: float = float(i) * TAU / 6.0 + PI / 6.0
		hex.append(cp + Vector2.from_angle(a2) * Vector2(48.0, 58.0))
	game.draw_colored_polygon(hex, Color(AMBER, 0.32 + q * 0.2))
	game.draw_polyline(hex, Color(INK, 0.8), 6.0, true)
	game.draw_polyline(hex, Color(AMBER_LIGHT, 0.95), 2.5, true)
	game.draw_arc(cp, 72.0, -PI * 0.5, -PI * 0.5 + TAU * q, 48, Color(1.0, 0.4, 0.1, 0.95), 5.0, true)
	game._draw_centered("%.1f" % maxf(0.0, RTSuturerThreatController.COCOON_TIME - float(ctrl.cocoon["age"])), cp + Vector2(0, -80), 18, Color(1.0, 0.86, 0.5))
