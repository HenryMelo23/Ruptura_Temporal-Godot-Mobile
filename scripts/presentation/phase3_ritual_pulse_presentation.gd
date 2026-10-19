extends RefCounted


static func draw(game: Node2D, camera: Vector2) -> void:
	if game.phase3_ritual_pulse_controller == null:
		return
	var snapshot: Dictionary = game.phase3_ritual_pulse_controller.active_snapshot()
	if not bool(snapshot.get("active", false)):
		return
	var low: bool = game._memory_saver_active() or game._runtime_visual_budget_active() or game.gfx_low_resource
	var result: String = String(snapshot.get("result", "active"))
	var result_fade: float = 1.0
	if result != "active":
		result_fade = clampf(float(snapshot.get("result_remaining", 0.0)) / maxf(0.01, game.phase3_ritual_pulse_controller.RESULT_DISPLAY_TIME), 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(game.time_alive * 5.5)
	var circles: Array = Array(snapshot.get("circles", []))
	for value in circles:
		var circle: Dictionary = value
		var pos: Vector2 = Vector2(circle.get("pos", Vector2.ZERO)) - camera
		var radius: float = float(circle.get("radius", game.phase3_ritual_pulse_controller.CIRCLE_RADIUS))
		var progress: float = clampf(float(circle.get("progress", 0.0)), 0.0, 1.0)
		var disrupted: bool = bool(circle.get("disrupted", false))
		var occupied: bool = bool(circle.get("occupied", false))
		var accent: Color = Color(0.52, 0.94, 0.24) if not occupied else Color(0.86, 0.3, 0.62)
		if disrupted or result == "success":
			accent = Color(0.58, 1.0, 0.42)
		elif result == "failure":
			accent = Color(0.94, 0.2, 0.56)
		game.draw_circle(pos, radius, Color(0.07, 0.02, 0.11, 0.18 * result_fade))
		game.draw_circle(pos, radius * (0.58 + pulse * 0.04), Color(accent, (0.08 + progress * 0.09) * result_fade))
		game.draw_arc(pos, radius, 0.0, TAU, 48 if not low else 28, Color(0.03, 0.02, 0.06, 0.88 * result_fade), 6.0, true)
		game.draw_arc(pos, radius, 0.0, TAU, 48 if not low else 28, Color(accent, 0.68 * result_fade), 2.5, true)
		if progress > 0.0:
			game.draw_arc(pos, radius + 6.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 42 if not low else 24, Color(1.0, 0.78, 0.9, 0.92 * result_fade), 4.0, true)
		var rune_count: int = 6 if low else 10
		for rune_index in range(rune_count):
			var angle: float = float(circle.get("phase", 0.0)) + float(rune_index) * TAU / float(rune_count) + game.time_alive * (0.08 if rune_index % 2 == 0 else -0.06)
			var outer: Vector2 = pos + Vector2.from_angle(angle) * radius * 0.78
			var inner: Vector2 = pos + Vector2.from_angle(angle + 0.26) * radius * 0.42
			game.draw_line(outer, inner, Color(accent, 0.42 * result_fade), 2.0, true)
		var diamond_size: float = 8.0 + pulse * 2.0
		var diamond := PackedVector2Array([
			pos + Vector2(0.0, -diamond_size),
			pos + Vector2(diamond_size, 0.0),
			pos + Vector2(0.0, diamond_size),
			pos + Vector2(-diamond_size, 0.0),
			pos + Vector2(0.0, -diamond_size)
		])
		game.draw_polyline(diamond, Color(accent, 0.92 * result_fade), 2.0, true)

	for value in Array(snapshot.get("devotees", [])):
		var devotee: Dictionary = value
		var devotee_pos: Vector2 = Vector2(devotee.get("pos", Vector2.ZERO)) - camera
		var circle_id: int = int(devotee.get("circle_id", -1))
		var target_pos: Vector2 = devotee_pos
		for circle_value in circles:
			var circle: Dictionary = circle_value
			if int(circle.get("id", -2)) == circle_id:
				target_pos = Vector2(circle.get("pos", Vector2.ZERO)) - camera
				break
		game.draw_dashed_line(devotee_pos, target_pos, Color(0.74, 0.92, 0.34, 0.34), 2.0, 14.0, true)
		game.draw_arc(devotee_pos, 27.0 + pulse * 3.0, 0.0, TAU, 24, Color(0.86, 0.34, 0.64, 0.78), 2.5, true)
		game.draw_line(devotee_pos + Vector2(-7.0, -34.0), devotee_pos + Vector2(0.0, -43.0), Color(1.0, 0.9, 0.5, 0.92), 3.0, true)
		game.draw_line(devotee_pos + Vector2(7.0, -34.0), devotee_pos + Vector2(0.0, -43.0), Color(1.0, 0.9, 0.5, 0.92), 3.0, true)

	if result == "active":
		var viewport: Vector2 = game.get_viewport_rect().size
		var overall: float = clampf(float(snapshot.get("overall_progress", 0.0)), 0.0, 1.0)
		var remaining: int = ceili(float(snapshot.get("remaining", 0.0)))
		var bar_size := Vector2(250.0, 9.0)
		var bar_pos := Vector2(viewport.x * 0.5 - bar_size.x * 0.5, 142.0)
		game.draw_rect(Rect2(bar_pos - Vector2(3.0, 3.0), bar_size + Vector2(6.0, 6.0)), Color(0.01, 0.015, 0.025, 0.76), true)
		game.draw_rect(Rect2(bar_pos, bar_size), Color(0.18, 0.08, 0.2, 0.82), true)
		game.draw_rect(Rect2(bar_pos, Vector2(bar_size.x * overall, bar_size.y)), Color(0.78, 0.3, 0.62, 0.9), true)
		game._draw_centered_outlined("INTERROMPA O RITUAL  %ds" % remaining, Vector2(viewport.x * 0.5, 128.0), 15, Color(0.9, 1.0, 0.72), Color(0.01, 0.015, 0.025, 0.96), 3)
