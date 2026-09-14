extends RefCounted
## Render-only layers. No RNG, hit tests, timers or gameplay state are mutated.

const CYAN := Color(0.18, 0.85, 1.0)
const INK := Color(0.015, 0.035, 0.09)


static func arc(canvas: CanvasItem, center: Vector2, radius: float, start: float, end: float, color: Color, width: float, low: bool = false) -> void:
	if radius <= 0.0 or end <= start:
		return
	var segments := clampi(int(radius * (end - start) / 9.0), 24, 160)
	if not low:
		canvas.draw_arc(center, radius, start, end, segments, Color(color, color.a * 0.04), width + 42.0, true)
		canvas.draw_arc(center, radius, start, end, segments, Color(color, color.a * 0.1), width + 26.0, true)
		canvas.draw_arc(center, radius, start, end, segments, Color(color, color.a * 0.22), width + 12.0, true)
	canvas.draw_arc(center, radius, start, end, segments, Color(INK, color.a * 0.8), width + 4.0, true)
	canvas.draw_arc(center, radius, start, end, segments, Color(color, color.a * 0.85), width, true)
	canvas.draw_arc(center, radius + width * 0.18, start, end, segments, Color(0.88, 0.99, 1.0, color.a), maxf(1.2, width * 0.18), true)


static func streak(canvas: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var side := (to - from).normalized().orthogonal() * width * 0.5
	canvas.draw_colored_polygon(PackedVector2Array([from, to + side * 1.8, to - side * 1.8]), Color(color, color.a * 0.09))
	canvas.draw_colored_polygon(PackedVector2Array([from, to + side, to - side]), Color(color, color.a * 0.65))
	canvas.draw_line(from.lerp(to, 0.45), to, Color(0.92, 1.0, 1.0, color.a), 1.5, true)


static func bubble(canvas: CanvasItem, center: Vector2, radius: float, time: float, color: Color = CYAN, low: bool = false) -> void:
	canvas.draw_circle(center, radius, Color(INK, 0.46))
	canvas.draw_circle(center, radius * 0.84, Color(color, 0.12))
	arc(canvas, center, radius, 0.0, TAU, Color(color, 0.92), 4.0, low)
	canvas.draw_arc(center + Vector2(-radius * 0.06, -radius * 0.06), radius * 0.77, PI * 1.08, PI * 1.65, 32, Color(0.95, 1.0, 1.0, 0.94), 3.0, true)
	canvas.draw_arc(center, radius * 0.7, time * 0.8, time * 0.8 + 1.7, 28, Color(0.5, 0.38, 1.0, 0.48), 2.0, true)
	canvas.draw_circle(center + Vector2(-0.28, -0.35) * radius, maxf(2.0, radius * 0.09), Color.WHITE)


static func chrono_wave(canvas: CanvasItem, center: Vector2, radius: float, age: float, color: Color, width: float, returning: bool, low: bool) -> void:
	arc(canvas, center, radius, 0.0, TAU, color, width * 0.72, low)
	if not low:
		var crest := PackedVector2Array()
		for i in range(129):
			var a := float(i) * TAU / 128.0
			var ripple := sin(a * 19.0 - age * 7.0) * 2.2 + sin(a * 31.0 + age * 4.0) * 1.2
			crest.append(center + Vector2.from_angle(a) * (radius + width * 0.32 + ripple))
		canvas.draw_polyline(crest, Color(color, 0.68), 4.0, true)
		canvas.draw_polyline(crest, Color(0.9, 1.0, 1.0, 0.86), 1.4, true)
	var count := 16 if low else 32
	var direction := -1.0 if returning else 1.0
	for i in range(count):
		var phase := float(i) * 2.39996
		var life := fposmod(age * 0.75 + float(i) * 0.618, 1.0)
		var angle := phase + age * direction * 0.3
		var pos := center + Vector2.from_angle(angle) * (radius - direction * life * width * 1.6)
		var alpha := sin(life * PI) * 0.78
		streak(canvas, pos - Vector2.from_angle(angle + direction * 0.4) * (9.0 + life * 14.0), pos, Color(color, alpha), 4.0)


static func absorb(canvas: CanvasItem, center: Vector2, elapsed: float, low: bool) -> void:
	canvas.draw_circle(center, 100.0, Color(INK, 0.3))
	arc(canvas, center, 104.0, 0.0, TAU, Color(CYAN, 0.9), 5.0, low)
	var count := 10 if low else 22
	for i in range(count):
		var p := fposmod(elapsed * 0.48 + float(i) * 0.618, 1.0)
		var angle := float(i) * 2.39996 + elapsed * 0.38 + p * 0.8
		var distance := lerpf(205.0, 60.0, p * p)
		var pos := center + Vector2.from_angle(angle) * distance
		var tail := center + Vector2.from_angle(angle - 0.2) * (distance + 38.0)
		var color := CYAN.lerp(Color(0.68, 0.38, 1.0), float(i % 3) * 0.25)
		streak(canvas, tail, pos, Color(color, sin(p * PI) * 0.95), 7.0)
	for i in range(3):
		var angle := -elapsed * 0.75 + i * TAU / 3.0
		arc(canvas, center, 86.0, angle, angle + 0.7, Color(0.52, 0.38, 1.0, 0.74), 3.0, true)


static func clock_shell(canvas: CanvasItem, center: Vector2, radius: float, elapsed: float, color: Color, low: bool) -> void:
	canvas.draw_circle(center, radius, Color(INK, 0.85))
	arc(canvas, center, radius, 0.0, TAU, Color(color, 0.96), 5.0, low)
	for i in range(12):
		var angle := -elapsed * 0.3 + i * TAU / 12.0
		arc(canvas, center, radius + 9.0, angle, angle + 0.18, Color(color, 0.64), 3.0, true)
	for i in range(4):
		var angle := elapsed * 0.4 + i * PI * 0.5
		var radial := Vector2.from_angle(angle)
		streak(canvas, center + radial * (radius + 28.0), center + radial * (radius + 13.0), Color(color, 0.74), 4.0)


static func tide(canvas: CanvasItem, start: Vector2, end: Vector2, time: float, low: bool) -> void:
	var tangent := (end - start).normalized()
	var normal := tangent.orthogonal()
	canvas.draw_line(start, end, Color(INK, 0.56), 64.0)
	canvas.draw_line(start, end, Color(0.06, 0.48, 0.78, 0.58), 56.0)
	canvas.draw_line(start, end, Color(CYAN, 0.2), 76.0)
	var points := PackedVector2Array()
	var count := 50 if low else 100
	for i in range(count + 1):
		var p := float(i) / count
		var ripple := sin(p * 70.0 - time * 6.0) * 4.0 + sin(p * 137.0 + time * 3.0) * 2.0
		points.append(start.lerp(end, p) + normal * ripple)
	canvas.draw_polyline(points, Color(0.25, 0.88, 1.0, 0.66), 12.0, true)
	canvas.draw_polyline(points, Color(0.9, 1.0, 1.0, 0.95), 3.0, true)
	for i in range(12 if low else 28):
		var phase := fposmod(i * 0.618 + time * 0.15, 1.0)
		var pos := start.lerp(end, phase) + normal * sin(phase * 80.0 + time) * 20.0
		streak(canvas, pos - tangent * 12.0, pos, Color(0.72, 0.97, 1.0, 0.75), 3.0)


static func attack(canvas: CanvasItem, data: Dictionary, center: Vector2, target: Vector2, time: float, age: float, low: bool) -> bool:
	var kind := String(data.get("kind", ""))
	match kind:
		"bubble":
			var p := clampf(age / maxf(0.01, float(data.get("duration", 3.2))), 0.0, 1.0)
			var radius := lerpf(15.0, 65.0, smoothstep(0.0, 0.5, p))
			var color := CYAN.lerp(Color(1.0, 0.18, 0.55), smoothstep(0.45, 0.7, p))
			if p >= 0.75:
				var burst := (p - 0.75) / 0.25
				arc(canvas, target, 90.0 + burst * 45.0, 0.0, TAU, Color(color, 1.0 - burst), 8.0, low)
				for i in range(12):
					var dir := Vector2.from_angle(float(i) * TAU / 12.0 + 0.4)
					streak(canvas, target + dir * 70.0, target + dir * (90.0 + burst * 60.0), Color(color, 1.0 - burst), 6.0)
			else:
				bubble(canvas, target, radius + sin(time * 8.0) * 2.0, time, color, low)
			return true
		"sand":
			var fade := clampf((float(data.get("duration", 4.2)) - age) / 0.4, 0.0, 1.0)
			canvas.draw_circle(target, 48.0, Color(0.1, 0.055, 0.02, 0.62 * fade))
			for i in range(4):
				var a := time * (0.8 + i * 0.16) + i * 1.8
				arc(canvas, target, 18.0 + i * 9.0, a, a + PI * 1.25, Color(0.93, 0.65, 0.28, (0.3 + i * 0.16) * fade), 3.0, low)
			for i in range(10 if low else 24):
				var p := fposmod(time * 0.45 + i * 0.618, 1.0)
				var pos := target + Vector2.from_angle(i * 2.4 + time * 2.0 + p) * lerpf(10.0, 46.0, p)
				canvas.draw_rect(Rect2(pos, Vector2(2, 3)), Color(1.0, 0.9, 0.62, sin(p * PI) * fade))
			return true
		"pressure_bubbles":
			var dir := Vector2(data.get("dir", Vector2.LEFT)).normalized()
			for i in range(3):
				var p := fposmod(age * 2.5 + i / 3.0, 1.0)
				arc(canvas, center + dir * (45.0 + p * 70.0), 12.0 + p * 16.0, dir.angle() - PI * 0.5, dir.angle() + PI * 0.5, Color(CYAN, (1.0 - p) * 0.75), 3.0, low)
			return true
	return false
