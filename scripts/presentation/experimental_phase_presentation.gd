class_name RTExperimentalPhasePresentation
extends RefCounted

const ALTAR_CYAN := Color(0.22, 0.92, 1.0)
const ALTAR_AMBER := Color(1.0, 0.62, 0.18)


static func draw_world(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	if not game.experimental_phase_active:
		return
	_draw_landmarks(game, camera, viewport)
	if not game.experimental_boss_altar_used and not game.boss_active and game.boss_call_timer < 0.0:
		_draw_altar(game, camera, viewport)


static func _draw_landmarks(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	var visible_rect := Rect2(Vector2(-100.0, -100.0), viewport + Vector2(200.0, 200.0))
	var landmarks: Array[Dictionary] = game.experimental_phase_controller.landmarks
	for landmark_index in range(landmarks.size()):
		if game._runtime_visual_budget_active() and landmark_index % 2 != 0:
			continue
		var landmark: Dictionary = landmarks[landmark_index]
		var center := Vector2(landmark.get("pos", Vector2.ZERO)) - camera
		if not visible_rect.has_point(center):
			continue
		var scale := float(landmark.get("scale", 1.0))
		var kind := int(landmark.get("kind", 0))
		match kind:
			0:
				game.draw_circle(center + Vector2(4.0, 8.0) * scale, 16.0 * scale, Color(0.03, 0.04, 0.05, 0.34))
				game.draw_colored_polygon(PackedVector2Array([center + Vector2(-16, 8) * scale, center + Vector2(-8, -13) * scale, center + Vector2(12, -17) * scale, center + Vector2(20, 8) * scale]), Color(0.28, 0.25, 0.24, 0.86))
			1:
				game.draw_line(center + Vector2(-20, 12) * scale, center + Vector2(18, -10) * scale, Color(0.58, 0.28, 0.16, 0.58), 4.0 * scale, true)
				game.draw_line(center + Vector2(-8, -4) * scale, center + Vector2(10, 14) * scale, Color(0.9, 0.48, 0.18, 0.26), 2.0 * scale, true)
			2:
				game.draw_rect(Rect2(center - Vector2(7, 25) * scale, Vector2(14, 50) * scale), Color(0.22, 0.19, 0.18, 0.82), true)
				game.draw_circle(center - Vector2(0, 24) * scale, 10.0 * scale, Color(0.42, 0.34, 0.23, 0.88))
			3:
				for petal in range(5):
					var direction := Vector2.from_angle(float(petal) * TAU / 5.0 + float(landmark.get("phase", 0.0)))
					game.draw_circle(center + direction * 8.0 * scale, 5.0 * scale, Color(0.32, 0.42, 0.20, 0.72))


static func _draw_altar(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	var world_pos: Vector2 = game.experimental_boss_altar_pos
	var center := world_pos - camera
	var t: float = float(game.time_alive)
	var pulse := 0.5 + 0.5 * sin(t * 2.4)
	if game.experimental_phase_controller.altar_visible_on_screen(camera, viewport):
		_draw_altar_grounding(game, center, t)
		var altar_texture: Texture2D = game._get_texture("experimental_phase_altar")
		if altar_texture != null:
			var altar_size := Vector2(224.0, 224.0)
			game.draw_texture_rect(altar_texture, Rect2(center - altar_size * 0.5, altar_size), false, Color(0.82, 0.85, 0.91, 0.96))
		else:
			game.draw_circle(center, 92.0, Color(0.035, 0.075, 0.09, 0.92))
		game.draw_arc(center, 92.0 + pulse * 4.0, 0.0, TAU, 80, Color(ALTAR_CYAN, 0.34 + pulse * 0.22), 3.0, true)
		if game.experimental_boss_altar_near and not game._arauto_active():
			game.draw_arc(center, 72.0, -t * 0.62, -t * 0.62 + TAU * game.experimental_phase_controller.altar_progress(), 64, Color(ALTAR_AMBER, 0.88), 5.0, true)
		game._draw_centered("ALTAR DO CRONOGUEJO", center + Vector2(0.0, -128.0), 18, Color(0.92, 1.0, 0.98))
		var status := "DERROTE O ARAUTO" if game._arauto_active() else ("INVOCANDO..." if game.experimental_boss_altar_near else "APROXIME-SE PARA INVOCAR")
		game._draw_centered(status, center + Vector2(0.0, 124.0), 14, ALTAR_AMBER if game.experimental_boss_altar_near else ALTAR_CYAN)
		if game.experimental_boss_altar_near and not game._arauto_active():
			var bar := Rect2(center + Vector2(-78.0, 140.0), Vector2(156.0, 9.0))
			game.draw_rect(bar, Color(0.01, 0.025, 0.035, 0.92), true)
			game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * game.experimental_phase_controller.altar_progress(), bar.size.y)), ALTAR_AMBER, true)
	elif game.experimental_boss_altar_discovered:
		_draw_discovered_altar_path(game, camera, viewport, world_pos, t)


static func _draw_altar_grounding(game: Node2D, center: Vector2, time: float) -> void:
	game.draw_circle(center + Vector2(5.0, 9.0), 98.0, Color(0.015, 0.018, 0.032, 0.16))
	for index in range(12):
		var angle := float(index) * TAU / 12.0 + sin(float(index) * 3.17) * 0.16
		var direction := Vector2.from_angle(angle)
		var inner := center + direction * (92.0 + float(index % 3) * 3.0)
		var outer := center + direction * (116.0 + float((index * 7) % 5) * 5.0)
		game.draw_line(inner, outer, Color(0.11, 0.08, 0.16, 0.50), 3.0, true)
		if index % 3 == 0:
			game.draw_circle(outer + direction.orthogonal() * 4.0, 3.0 + float(index % 2), Color(0.34, 0.31, 0.35, 0.72))
	var dust_alpha := 0.035 + (0.5 + 0.5 * sin(time * 1.7)) * 0.02
	game.draw_arc(center, 118.0, 0.15, PI * 1.45, 56, Color(0.72, 0.62, 0.48, dust_alpha), 7.0, true)


static func _draw_discovered_altar_path(game: Node2D, camera: Vector2, viewport: Vector2, world_pos: Vector2, time: float) -> void:
	var start := Vector2(game.player_pos) - camera
	var offscreen := world_pos - camera
	var direction := (offscreen - start).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	var margin := Vector2(46.0, 46.0)
	var edge_distance := minf(
		((viewport.x - margin.x) - start.x) / direction.x if direction.x > 0.001 else ((margin.x - start.x) / direction.x if direction.x < -0.001 else INF),
		((viewport.y - margin.y) - start.y) / direction.y if direction.y > 0.001 else ((margin.y - start.y) / direction.y if direction.y < -0.001 else INF)
	)
	var finish := start + direction * maxf(80.0, edge_distance)
	var normal := direction.orthogonal()
	var points := PackedVector2Array()
	var point_count := 8 if game._runtime_visual_budget_active() else 14
	for index in range(point_count):
		var ratio := float(index) / float(point_count - 1)
		var wave := sin(time * 3.2 + ratio * 10.0) * (3.0 + ratio * 6.0)
		points.append(start.lerp(finish, ratio) + normal * wave)
	game.draw_polyline(points, Color(0.05, 0.08, 0.10, 0.46), 8.0, true)
	game.draw_polyline(points, Color(ALTAR_CYAN, 0.34), 2.5, true)
	for index in range(2, point_count, 3):
		game.draw_circle(points[index], 3.0, Color(ALTAR_AMBER, 0.48))
