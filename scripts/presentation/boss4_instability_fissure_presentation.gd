class_name RTBoss4InstabilityFissurePresentation
extends RefCounted

const MAGENTA := Color(1.0, 0.18, 0.72)
const CYAN := Color(0.24, 0.96, 1.0)
const VOID := Color(0.055, 0.01, 0.11)


static func draw(game: Node2D, hazard: Dictionary, camera: Vector2) -> void:
	var age := float(hazard.get("age", 0.0))
	if age < 0.0:
		return
	var warning := maxf(0.01, float(hazard.get("warning", 1.05)))
	var active_duration := maxf(0.01, float(hazard.get("active_duration", 0.65)))
	var dissipate_duration := maxf(0.01, float(hazard.get("dissipate_duration", 0.45)))
	var active_end := warning + active_duration
	var total_end := active_end + dissipate_duration
	var low: bool = bool(game.gfx_low_resource) or bool(game._memory_saver_active()) or bool(game._runtime_visual_budget_active())
	if int(hazard.get("fissure_index", 0)) == 0:
		_draw_safe_corridor(game, hazard, camera, age, warning, low)
	var a := Vector2(hazard.get("a", Vector2.ZERO)) - camera
	var b := Vector2(hazard.get("b", Vector2.ZERO)) - camera
	var visual_seed := int(hazard.get("seed", 0)) + int(hazard.get("fissure_index", 0)) * 1297
	var points := _jagged_points(a, b, visual_seed, 7 if low else 12, 7.0 if age < warning else 12.0)
	if age < warning:
		var progress := clampf(age / warning, 0.0, 1.0)
		_draw_telegraph(game, points, progress)
		return
	if age < active_end:
		var pulse := 0.82 + sin(game.time_alive * 18.0 + float(visual_seed)) * 0.18
		_draw_active(game, points, pulse, low, visual_seed)
		return
	var dissipate := clampf(1.0 - (age - active_end) / maxf(0.01, total_end - active_end), 0.0, 1.0)
	_draw_dissipation(game, points, dissipate, low, visual_seed)


static func _draw_safe_corridor(game: Node2D, hazard: Dictionary, camera: Vector2, age: float, warning: float, low: bool) -> void:
	var a := Vector2(hazard.get("safe_a", Vector2.ZERO)) - camera
	var b := Vector2(hazard.get("safe_b", Vector2.ZERO)) - camera
	var width := float(hazard.get("safe_width", 72.0))
	var alpha := 0.15 + 0.06 * sin(game.time_alive * 4.0)
	game.draw_line(a, b, Color(0.01, 0.04, 0.08, alpha), width * 2.0, true)
	game.draw_line(a, b, Color(CYAN.r, CYAN.g, CYAN.b, 0.52), 2.5, true)
	var side := (b - a).normalized().orthogonal()
	game.draw_line(a + side * width, b + side * width, Color(CYAN.r, CYAN.g, CYAN.b, 0.46), 2.0, true)
	game.draw_line(a - side * width, b - side * width, Color(CYAN.r, CYAN.g, CYAN.b, 0.46), 2.0, true)
	var chevrons := 4 if low else 7
	for index in range(chevrons):
		var ratio := (float(index) + 0.5) / float(chevrons)
		var center := a.lerp(b, ratio)
		var direction := (b - a).normalized()
		var size := 10.0 + 3.0 * clampf(age / warning, 0.0, 1.0)
		game.draw_polyline(PackedVector2Array([
			center - direction * size + side * size * 0.7,
			center,
			center - direction * size - side * size * 0.7
		]), Color(0.72, 1.0, 1.0, 0.58), 2.0, false)


static func _draw_telegraph(game: Node2D, points: PackedVector2Array, progress: float) -> void:
	if points.size() < 2:
		return
	var visible_count := clampi(int(ceil(float(points.size()) * progress)), 2, points.size())
	var visible := PackedVector2Array()
	for index in range(visible_count):
		visible.append(points[index])
	game.draw_polyline(visible, Color(VOID.r, VOID.g, VOID.b, 0.72), 12.0, true)
	game.draw_polyline(visible, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.42 + progress * 0.32), 3.0, true)
	var direction := (points[points.size() - 1] - points[0]).normalized()
	var side := direction.orthogonal()
	for index in range(1, visible_count, 2):
		var point := visible[index]
		var tick := 7.0 + progress * 5.0
		game.draw_line(point - side * tick, point + side * tick, Color(0.92, 0.9, 1.0, 0.74), 2.0, true)


static func _draw_active(game: Node2D, points: PackedVector2Array, pulse: float, low: bool, visual_seed: int) -> void:
	game.draw_polyline(points, Color(VOID.r, VOID.g, VOID.b, 0.88), 22.0, true)
	var direction := (points[points.size() - 1] - points[0]).normalized()
	var side := direction.orthogonal()
	var cyan_points := PackedVector2Array()
	var magenta_points := PackedVector2Array()
	for index in range(points.size()):
		var offset := side * sin(float(index) * 2.1 + game.time_alive * 13.0) * 3.5
		cyan_points.append(points[index] + offset)
		magenta_points.append(points[index] - offset)
	game.draw_polyline(magenta_points, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.92 * pulse), 6.0, true)
	game.draw_polyline(cyan_points, Color(CYAN.r, CYAN.g, CYAN.b, 0.84 * pulse), 2.8, true)
	var fragment_count := 4 if low else 8
	for index in range(fragment_count):
		var ratio := (float(index) + 0.5) / float(fragment_count)
		var center := points[0].lerp(points[points.size() - 1], ratio)
		var spread := side * (18.0 + float(posmod(visual_seed + index * 31, 22)))
		if index % 2 == 0:
			spread = -spread
		var size := 3.0 + float(posmod(visual_seed + index * 13, 5))
		var fragment := PackedVector2Array([center + spread + Vector2(0.0, -size), center + spread + Vector2(size, size), center + spread + Vector2(-size, size)])
		game.draw_colored_polygon(fragment, Color(CYAN.r, CYAN.g, CYAN.b, 0.62))


static func _draw_dissipation(game: Node2D, points: PackedVector2Array, fade: float, low: bool, visual_seed: int) -> void:
	game.draw_polyline(points, Color(VOID.r, VOID.g, VOID.b, 0.7 * fade), 16.0 * fade + 2.0, true)
	game.draw_polyline(points, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, 0.72 * fade), 4.0 * fade + 1.0, true)
	var fragments := 3 if low else 6
	for index in range(fragments):
		var ratio := (float(index) + 0.5) / float(fragments)
		var point := points[0].lerp(points[points.size() - 1], ratio)
		var drift := Vector2.from_angle(float(posmod(visual_seed + index * 47, 6283)) / 1000.0) * (1.0 - fade) * 24.0
		game.draw_circle(point + drift, 2.0 + 3.0 * fade, Color(CYAN.r, CYAN.g, CYAN.b, 0.58 * fade))


static func _jagged_points(a: Vector2, b: Vector2, visual_seed: int, segments: int, amplitude: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var direction := (b - a).normalized()
	var side := direction.orthogonal()
	for index in range(segments + 1):
		var ratio := float(index) / float(segments)
		var edge_scale := sin(ratio * PI)
		var noise := sin(float(visual_seed % 997) * 0.013 + float(index) * 2.37) * amplitude * edge_scale
		result.append(a.lerp(b, ratio) + side * noise)
	return result
