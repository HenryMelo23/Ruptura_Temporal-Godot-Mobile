extends RefCounted
const Lightning = preload("res://scripts/presentation/lightning_presentation.gd")
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


static func pincer_tenaz(canvas: CanvasItem, data: Dictionary, center: Vector2, time: float, low: bool) -> void:
	var state: String = String(data.get("state", "telegraph_first"))
	var strike_index: int = int(data.get("strike_index", 0))
	var prefix: String = "second" if state.ends_with("second") or strike_index >= 2 else "first"
	var direction: Vector2 = Vector2(data.get("%s_dir" % prefix, Vector2.RIGHT)).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	var side: Vector2 = direction.orthogonal()
	var warning: float = maxf(0.01, float(data.get("warning", 0.82)))
	var state_age: float = float(data.get("state_age", 0.0))
	var accent: Color = Color(1.0, 0.52, 0.12, 0.9) if prefix == "first" else Color(1.0, 0.2, 0.16, 0.92)
	var accent_soft: Color = Color(accent, 0.22)
	var line_width: float = 5.0 if not low else 3.0

	if state == "telegraph_first" or state == "telegraph_second":
		var pulse: float = 0.5 + 0.5 * sin(time * 12.0 + (0.0 if prefix == "first" else 1.4))
		var origin_world: Vector2 = Vector2(data.get("%s_origin" % prefix, Vector2.ZERO))
		var end_world: Vector2 = Vector2(data.get("%s_end" % prefix, Vector2.ZERO))
		var path_vector: Vector2 = end_world - origin_world
		if path_vector.length() <= 1.0:
			path_vector = direction * 540.0
		var tip: Vector2 = center + path_vector
		var corridor_half_width: float = maxf(34.0, float(data.get("width", 92.0)) * 0.5)
		var lane_start: Vector2 = center + direction * 34.0
		var lane_points := PackedVector2Array([
			lane_start + side * corridor_half_width,
			tip + side * corridor_half_width,
			tip - side * corridor_half_width,
			lane_start - side * corridor_half_width
		])
		canvas.draw_polygon(lane_points, PackedColorArray([Color(accent, 0.08 + pulse * 0.04)]))
		canvas.draw_line(lane_start + side * corridor_half_width, tip + side * corridor_half_width, Color(INK, 0.68), 5.0, true)
		canvas.draw_line(lane_start - side * corridor_half_width, tip - side * corridor_half_width, Color(INK, 0.68), 5.0, true)
		canvas.draw_line(lane_start + side * corridor_half_width, tip + side * corridor_half_width, Color(accent, 0.42 + pulse * 0.18), 2.0, true)
		canvas.draw_line(lane_start - side * corridor_half_width, tip - side * corridor_half_width, Color(accent, 0.42 + pulse * 0.18), 2.0, true)
		canvas.draw_line(lane_start, tip, Color(INK, 0.74), 12.0, true)
		canvas.draw_line(lane_start, tip, Color(accent, 0.22 + pulse * 0.16), 5.0, true)
		var marker_count: int = 2 if low else 4
		for marker_index in range(marker_count):
			var marker_progress: float = float(marker_index + 1) / float(marker_count + 1)
			var marker_center: Vector2 = lane_start.lerp(tip, marker_progress)
			var marker_back: Vector2 = marker_center - direction * 18.0
			canvas.draw_line(marker_back + side * 13.0, marker_center, Color(1.0, 0.88, 0.52, 0.72), line_width, true)
			canvas.draw_line(marker_back - side * 13.0, marker_center, Color(1.0, 0.88, 0.52, 0.72), line_width, true)
		var arrow_center: Vector2 = tip - direction * 34.0
		var left: Vector2 = arrow_center - direction * 30.0 + side * 34.0
		var right: Vector2 = arrow_center - direction * 30.0 - side * 34.0
		canvas.draw_polygon(PackedVector2Array([tip, left, right]), PackedColorArray([Color(accent, 0.2 + pulse * 0.16)]))
		canvas.draw_polyline(PackedVector2Array([left, tip, right]), Color(1.0, 0.86, 0.52, 0.86), line_width, true)
		arc(canvas, center, 48.0 + pulse * 8.0, direction.angle() - 1.0, direction.angle() - 0.18, accent, 4.0, low)
		arc(canvas, center, 48.0 + pulse * 8.0, direction.angle() + 0.18, direction.angle() + 1.0, accent, 4.0, low)
		canvas.draw_line(center + side * 28.0, center + side * 54.0, Color(1.0, 0.86, 0.52, 0.78), line_width, true)
		canvas.draw_line(center - side * 28.0, center - side * 54.0, Color(1.0, 0.86, 0.52, 0.78), line_width, true)
		return

	if state == "dash_first" or state == "dash_second":
		var back: Vector2 = center - direction * 250.0
		streak(canvas, back, center + direction * 54.0, accent, 16.0 if not low else 11.0)
		canvas.draw_line(center - side * 28.0, center + side * 34.0, Color(1.0, 0.88, 0.5, 0.74), line_width, true)
		canvas.draw_line(center + side * 28.0, center - side * 34.0, Color(1.0, 0.88, 0.5, 0.74), line_width, true)
		for particle in range(4 if low else 8):
			var phase: float = fposmod(time * 0.8 + float(particle) * 0.173 + state_age * 0.6, 1.0)
			var particle_pos: Vector2 = center - direction * (40.0 + phase * 220.0) + side * sin(phase * 11.0 + particle) * 18.0
			canvas.draw_circle(particle_pos, 2.0 + (particle % 2), Color(0.92, 0.62, 0.24, 0.68 * (1.0 - phase)))
		return

	if state == "recovery":
		var fade: float = 1.0 - clampf(state_age / 0.42, 0.0, 1.0)
		canvas.draw_circle(center, 42.0, Color(0.28, 0.08, 0.02, 0.18 * fade))
		arc(canvas, center, 52.0 + (1.0 - fade) * 48.0, 0.0, TAU, Color(1.0, 0.68, 0.22, 0.76 * fade), 5.0, low)


static func whirlpool(canvas: CanvasItem, data: Dictionary, center: Vector2, time: float, low: bool) -> void:
	var state := String(data.get("state", "approach"))
	var state_age := maxf(0.0, float(data.get("state_age", 0.0)))
	var direction := float(data.get("spin_direction", 1.0))
	var opacity := 0.0
	match state:
		"approach":
			opacity = clampf(state_age / 1.1, 0.0, 1.0) * 0.7
		"active":
			opacity = 1.0
		"drying":
			opacity = 1.0 - clampf(state_age / 1.8, 0.0, 1.0)
	if opacity <= 0.001:
		return

	# One translucent arena-sized layer replaces hundreds of water sprites.
	var world_radius := maxf(1080.0, float(data.get("world_radius", 1080.0)))
	canvas.draw_circle(center, world_radius, Color(0.02, 0.24, 0.38, 0.18 * opacity))
	canvas.draw_circle(center, world_radius * 0.70, Color(0.04, 0.48, 0.68, 0.075 * opacity))
	var spiral_count := 3 if low else 6
	for spiral_index in range(spiral_count):
		var base_angle := time * direction * (0.72 + spiral_index * 0.035) + float(spiral_index) * TAU / float(spiral_count)
		var radius := lerpf(128.0, world_radius * 0.68, float(spiral_index) / float(maxi(1, spiral_count - 1)))
		var spiral_color := Color(0.22, 0.88, 1.0, opacity * (0.3 + float(spiral_index % 2) * 0.12))
		arc(canvas, center, radius, base_angle, base_angle + direction * PI * 1.25 if direction > 0.0 else base_angle + PI * 1.25, spiral_color, 5.0 if low else 7.0, low)

	var streak_count := 7 if low else 15
	for streak_index in range(streak_count):
		var phase := fposmod(time * 0.24 + float(streak_index) * 0.618, 1.0)
		var angle := float(streak_index) * 2.39996 + time * direction * 0.64 + phase * direction
		var distance := lerpf(world_radius * 0.88, 92.0, phase)
		var radial := Vector2.from_angle(angle)
		var tangent := radial.orthogonal() * direction
		var streak_end := center + radial * distance
		var streak_start := streak_end + radial * (28.0 + phase * 28.0) - tangent * 18.0
		streak(canvas, streak_start, streak_end, Color(0.52, 0.94, 1.0, sin(phase * PI) * 0.68 * opacity), 4.0 if low else 6.0)

	canvas.draw_circle(center, 72.0, Color(0.01, 0.055, 0.11, 0.58 * opacity))
	arc(canvas, center, 86.0 + sin(time * 5.0) * 4.0, 0.0, TAU, Color(0.55, 0.96, 1.0, 0.84 * opacity), 5.0, low)
	arc(canvas, center, 112.0, time * direction * 1.6, time * direction * 1.6 + PI * 1.35, Color(0.34, 0.72, 1.0, 0.58 * opacity), 4.0, true)

	if state != "active":
		return
	var beam_count: int = clampi(int(data.get("beam_count", 1)), 1, 4)
	var warning: float = maxf(0.0, float(data.get("laser_warning", 0.9)))
	var rotation_duration: float = maxf(0.01, float(data.get("laser_rotation_duration", 10.8)))
	var rotation_progress: float = clampf(maxf(0.0, state_age - warning) / rotation_duration, 0.0, 1.0)
	var start_angle: float = float(data.get("beam_start_angle", 0.0))
	var telegraphing: bool = state_age < warning
	var warning_progress: float = clampf(state_age / maxf(0.01, warning), 0.0, 1.0)
	for beam_index in range(beam_count):
		var angle: float = start_angle + direction * TAU * rotation_progress + TAU * float(beam_index) / float(beam_count)
		var beam_direction := Vector2.from_angle(angle)
		# Collision still begins outside the boss body, but the beam must be drawn
		# from the sprite pivot so the boss naturally occludes its hidden section.
		var beam_start := center
		var beam_end := center + beam_direction * world_radius
		if telegraphing:
			var pulse: float = 0.5 + 0.5 * sin(time * 13.0 + float(beam_index) * 1.7)
			canvas.draw_line(beam_start, beam_end, Color(0.01, 0.055, 0.1, 0.76 * warning_progress), 10.0 if low else 13.0, true)
			canvas.draw_dashed_line(beam_start, beam_end, Color(0.48, 0.94, 1.0, (0.34 + pulse * 0.32) * warning_progress), 3.0 if low else 4.0, 18.0, true)
			continue
		var pulse: float = 0.78 + 0.22 * sin(time * 11.0 + float(beam_index) * 1.9)
		canvas.draw_line(beam_start, beam_end, Color(0.005, 0.025, 0.07, 0.9), 24.0 if low else 30.0, true)
		canvas.draw_line(beam_start, beam_end, Color(0.08, 0.66, 1.0, 0.18 * pulse), 18.0 if low else 23.0, true)
		canvas.draw_line(beam_start, beam_end, Color(0.2, 0.9, 1.0, 0.78 * pulse), 7.0 if low else 9.0, true)
		canvas.draw_line(beam_start, beam_end, Color(0.9, 1.0, 1.0, 0.94), 2.0 if low else 3.0, true)
		var spark_count := 2 if low else 4
		for spark_index in range(spark_count):
			var spark_phase: float = fposmod(time * (0.72 + float(spark_index) * 0.05) + float(spark_index) / float(spark_count), 1.0)
			var spark_pos: Vector2 = beam_start.lerp(beam_end, spark_phase)
			var side := beam_direction.orthogonal() * sin(time * 17.0 + float(spark_index) * 2.3) * (4.0 if low else 7.0)
			canvas.draw_circle(spark_pos + side, 2.0 if low else 3.0, Color(0.72, 0.98, 1.0, 0.76))
	var emitter_pulse: float = 0.5 + 0.5 * sin(time * 9.0)
	canvas.draw_circle(center, 26.0 + emitter_pulse * 4.0, Color(0.02, 0.16, 0.28, 0.72))
	canvas.draw_circle(center, 17.0 + emitter_pulse * 2.0, Color(0.18, 0.82, 1.0, 0.82))
	canvas.draw_circle(center, 7.0, Color(0.9, 1.0, 1.0, 0.96))


static func lightning(canvas: CanvasItem, data: Dictionary, target: Vector2, time: float, age: float, low: bool) -> void:
	var tier := Lightning.PERFORMANCE if low else Lightning.quality(canvas)
	var warning := maxf(0.01, float(data.get("warning", 1.2)))
	var radius := maxf(20.0, float(data.get("radius", 82.0)))
	var seed: int = absi(int(data.get("seed", 1)))
	if age < warning:
		var progress := clampf(age / warning, 0.0, 1.0)
		var pulse := 0.5 + 0.5 * sin(time * 15.0 + float(seed % 17))
		canvas.draw_circle(target, radius, Color(0.12, 0.46, 0.92, 0.1 + progress * 0.11))
		canvas.draw_arc(target, radius, 0.0, TAU, 48, Color(0.01, 0.04, 0.1, 0.82), 6.0, true)
		canvas.draw_arc(target, radius, 0.0, TAU, 48, Color(0.46, 0.86, 1.0, 0.5 + pulse * 0.35), 2.8, true)
		var tick_count := 6 if low else 10
		for tick_index in range(tick_count):
			var angle := float(tick_index) * TAU / float(tick_count) + float(seed % 31) * 0.03
			var outer := target + Vector2.from_angle(angle) * (radius + 6.0 + pulse * 5.0)
			var inner := target + Vector2.from_angle(angle) * (radius - 9.0)
			canvas.draw_line(outer, inner, Color(0.72, 0.94, 1.0, 0.5 + progress * 0.4), 2.0, true)
		var orb_radius := lerpf(5.0, 18.0, progress)
		# Filaments visibly converge into the charge instead of a static dot.
		for i in range(2 if tier == Lightning.PERFORMANCE else 5):
			var angle := float(i) * 2.39996 + time * 0.9 + seed % 13
			var direction := Vector2.from_angle(angle)
			Lightning.bolt(canvas, target + direction * radius * 0.78, target + direction * orb_radius, seed + i, time, CYAN, 0.35 + progress * 0.35, 1.3, tier)
		canvas.draw_circle(target, orb_radius + 7.0, Color(0.18, 0.58, 1.0, 0.16 + progress * 0.2))
		canvas.draw_circle(target, orb_radius, Color(0.72, 0.95, 1.0, 0.72 + progress * 0.25))
		canvas.draw_circle(target, maxf(2.0, orb_radius * 0.35), Color.WHITE)
		return

	var impact_age := age - warning
	var fade := 1.0 - clampf(impact_age / 0.48, 0.0, 1.0)
	if fade <= 0.001:
		return
	Lightning.bolt(canvas, target + Vector2(0, -520), target, seed, age, CYAN, fade, 6.0 if low else 8.0, tier)
	Lightning.contact(canvas, target, seed, age, CYAN, fade, tier)
	canvas.draw_circle(target, radius, Color(0.32, 0.78, 1.0, 0.15 * fade))
	arc(canvas, target, radius + impact_age * 110.0, 0.0, TAU, Color(0.74, 0.96, 1.0, 0.86 * fade), 7.0, low)
	Lightning.bolt(canvas, target - Vector2(radius * 0.72, 0.0), target + Vector2(radius * 0.72, 0.0), seed + 37, age, CYAN, 0.68 * fade, 2.0, tier)


static func attack(canvas: CanvasItem, data: Dictionary, center: Vector2, target: Vector2, time: float, age: float, low: bool) -> bool:
	var kind := String(data.get("kind", ""))
	match kind:
		"boss1_whirlpool":
			whirlpool(canvas, data, center, time, low)
			return true
		"boss1_lightning":
			lightning(canvas, data, target, time, age, low)
			return true
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
		"pincer_tenaz":
			pincer_tenaz(canvas, data, center, time, low)
			return true
	return false
