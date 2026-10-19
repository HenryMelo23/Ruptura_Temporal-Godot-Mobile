extends RefCounted


static func draw(game: Node2D, camera: Vector2) -> void:
	if game.phase4_instability_pulse_controller == null:
		return
	var snapshot: Dictionary = game.phase4_instability_pulse_controller.active_snapshot()
	if not bool(snapshot.get("active", false)):
		return
	var low: bool = game._memory_saver_active() or game._runtime_visual_budget_active() or game.gfx_low_resource
	var result: String = String(snapshot.get("result", "active"))
	var fade: float = 1.0
	if result != "active":
		fade = clampf(float(snapshot.get("result_remaining", 0.0)) / maxf(0.01, game.phase4_instability_pulse_controller.RESULT_DISPLAY_TIME), 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(game.time_alive * 5.2)
	for value in Array(snapshot.get("fragments", [])):
		var fragment: Dictionary = Dictionary(value)
		if bool(fragment.get("collected", false)):
			continue
		var position: Vector2 = Vector2(fragment.get("pos", Vector2.ZERO)) - camera
		var velocity: Vector2 = Vector2(fragment.get("velocity", Vector2.RIGHT))
		var direction: Vector2 = velocity.normalized() if velocity.length_squared() > 0.01 else Vector2.RIGHT
		var tangent: Vector2 = direction.orthogonal()
		var size: float = 20.0 + pulse * 2.5
		var points := PackedVector2Array([
			position + direction * size,
			position + tangent * size * 0.72,
			position - direction * size,
			position - tangent * size * 0.72
		])
		game.draw_line(position - direction * 34.0, position - direction * 12.0, Color(0.42, 0.82, 1.0, 0.34 * fade), 4.0, true)
		game.draw_colored_polygon(points, Color(0.12, 0.5, 0.72, 0.48 * fade))
		game.draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0.72, 1.0, 0.94, 0.94 * fade), 2.5, true)
		game.draw_line(points[0], points[2], Color(1.0, 0.82, 0.34, 0.72 * fade), 1.5, true)
		game.draw_line(points[1], points[3], Color(0.96, 0.46, 1.0, 0.62 * fade), 1.5, true)
		game.draw_arc(position, 29.0 + pulse * 3.0, -game.time_alive * 1.8, -game.time_alive * 1.8 + PI * 1.55, 22 if low else 34, Color(0.5, 0.96, 1.0, 0.72 * fade), 2.0, true)
		if not low:
			for index in range(3):
				var angle: float = game.time_alive * (0.72 + float(index) * 0.08) + float(index) * TAU / 3.0
				var satellite: Vector2 = position + Vector2.from_angle(angle) * (35.0 + pulse * 2.0)
				game.draw_circle(satellite, 2.5, Color(1.0, 0.72, 0.28, 0.8 * fade))

	if result != "active":
		return
	var viewport: Vector2 = game.get_viewport_rect().size
	var collected: int = int(snapshot.get("collected_count", 0))
	var total: int = int(snapshot.get("fragment_count", 3))
	var instability: float = clampf(float(snapshot.get("pulse_instability", 0.0)), 0.0, 100.0)
	var remaining: int = ceili(float(snapshot.get("remaining", 0.0)))
	var bar_size := Vector2(256.0, 9.0)
	var bar_pos := Vector2(viewport.x * 0.5 - bar_size.x * 0.5, 155.0)
	game.draw_rect(Rect2(bar_pos - Vector2(4.0, 4.0), bar_size + Vector2(8.0, 8.0)), Color(0.01, 0.015, 0.035, 0.8), true)
	game.draw_rect(Rect2(bar_pos, bar_size), Color(0.08, 0.12, 0.22, 0.9), true)
	game.draw_rect(Rect2(bar_pos, Vector2(bar_size.x * instability / 100.0, bar_size.y)), Color(0.82, 0.24, 0.94, 0.9), true)
	game.draw_rect(Rect2(bar_pos, bar_size), Color(0.58, 0.96, 1.0, 0.72), false, 1.5)
	game._draw_centered_outlined("ESTABILIZE A LINHA  %d/%d  %ds" % [collected, total, remaining], Vector2(viewport.x * 0.5, 137.0), 15, Color(0.84, 1.0, 0.96), Color(0.01, 0.015, 0.035, 0.98), 3)
	game._draw_centered("INSTABILIDADE DO PULSO  %.0f%%" % instability, Vector2(viewport.x * 0.5, 180.0), 12, Color(0.94, 0.72, 1.0, 0.92))
	var marker_origin: Vector2 = Vector2(viewport.x * 0.5 - 28.0, 198.0)
	for index in range(total):
		var marker_pos: Vector2 = marker_origin + Vector2(float(index) * 28.0, 0.0)
		var filled: bool = index < collected
		var marker_points := PackedVector2Array([marker_pos + Vector2(0, -7), marker_pos + Vector2(7, 0), marker_pos + Vector2(0, 7), marker_pos + Vector2(-7, 0)])
		game.draw_colored_polygon(marker_points, Color(0.4, 1.0, 0.9, 0.9) if filled else Color(0.12, 0.18, 0.3, 0.9))
		game.draw_polyline(PackedVector2Array([marker_points[0], marker_points[1], marker_points[2], marker_points[3], marker_points[0]]), Color(0.72, 1.0, 0.96, 0.9), 1.5, true)
