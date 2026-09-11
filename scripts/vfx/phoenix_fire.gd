extends RefCounted

# Clockwise ignition, with at most two overlapping hot quadrants.
# This field drives both damage and the growing fire, independently of VFX quality.
const DURATION := 50.0
const ORDER := [0, 1, 3, 2]
const STAGGER := 10.0
const WARNING := 3.0
const SPREAD := 4.0
const RISE := 1.2
const COOL_START := 16.0
const END := 19.0
const DAMAGE_HEAT := 0.72
const NORMAL_FLAME_CAP := 96
const LOW_FLAME_CAP := 36


static func quadrant_rect(index: int, world_size: Vector2) -> Rect2:
	var half := world_size * 0.5
	return Rect2(Vector2(index % 2, floori(index * 0.5)) * half, half)


static func quadrant_at(pos: Vector2, world_size: Vector2) -> int:
	return (1 if pos.x >= world_size.x * 0.5 else 0) + (2 if pos.y >= world_size.y * 0.5 else 0)


static func age(elapsed: float, quadrant: int) -> float:
	return elapsed - float(ORDER.find(quadrant)) * STAGGER


static func phase(elapsed: float, quadrant: int) -> int:
	var t := age(elapsed, quadrant)
	if t < 0.0 or t >= END:
		return 0
	if t < WARNING:
		return 1
	return 2 if t < WARNING + SPREAD + RISE or t >= COOL_START else 3


static func heat_at(pos: Vector2, world_size: Vector2, elapsed: float) -> float:
	if not Rect2(Vector2.ZERO, world_size).has_point(pos):
		return 0.0
	var quadrant := quadrant_at(pos, world_size)
	var t := age(elapsed, quadrant)
	if t < WARNING or t >= END:
		return 0.0
	var rect := quadrant_rect(quadrant, world_size)
	var uv := (pos - rect.position) / rect.size
	if quadrant % 2 == 1:
		uv.x = 1.0 - uv.x
	if quadrant >= 2:
		uv.y = 1.0 - uv.y
	# The front travels from the outer corner towards the arena centre.
	var distance := (uv.x + uv.y) * 0.5
	var growth := clampf((t - WARNING - distance * SPREAD) / RISE, 0.0, 1.0)
	var cooling := clampf((END - t) / (END - COOL_START), 0.0, 1.0)
	return growth * cooling


static func dangerous(pos: Vector2, world_size: Vector2, elapsed: float) -> bool:
	return heat_at(pos, world_size, elapsed) >= DAMAGE_HEAT


static func draw_flame(canvas: CanvasItem, base: Vector2, width: float, height: float, clock: float, flame_seed: float, strength: float = 1.0, rise: Vector2 = Vector2.UP, low: bool = false) -> void:
	if strength <= 0.01 or height <= 1.0:
		return
	var axis := rise.normalized()
	var side := Vector2(-axis.y, axis.x)
	var flicker := 0.82 + 0.14 * sin(clock * 12.0 + flame_seed) + 0.08 * sin(clock * 19.0 + flame_seed * 2.0)
	var palette := [Color(0.65, 0.075, 0.014, 0.46), Color(1.0, 0.30, 0.035, 0.78), Color(1.0, 0.72, 0.18, 0.87), Color(1.0, 0.94, 0.64, 0.86)]
	var layers := 3 if low else 4
	for layer in range(layers):
		var scale_x: float = [1.0, 0.72, 0.42, 0.19][layer]
		var scale_y: float = [1.0, 0.82, 0.58, 0.32][layer]
		var w := width * scale_x
		var h := height * flicker * scale_y
		# Flow travels up the silhouette; each colour has its own curling contour.
		var points := PackedVector2Array()
		var right := PackedVector2Array()
		var samples := 6 if low else 10
		for sample in range(samples):
			var t := float(sample) / float(samples - 1)
			var flow := t * 9.0 - clock * 9.0 + flame_seed * 2.7 + layer * 0.9
			var curl := (sin(flow * 0.7) * 0.23 + sin(flow * 1.7) * 0.09) * t * w
			var breadth := pow(1.0 - t, 0.8) * w * (0.36 + 0.12 * sin(flow) + 0.05 * cos(flow * 2.8))
			var centre := base + axis * t * h + side * curl
			points.append(centre - side * breadth)
			right.append(centre + side * breadth)
		# The two contours share a single tip, avoiding duplicate polygon vertices.
		for index in range(right.size() - 2, -1, -1):
			points.append(right[index])
		var color: Color = palette[layer]
		color.a *= strength
		canvas.draw_colored_polygon(points, color)
	if not low:
		var ember_t := fposmod(clock * 0.8 + flame_seed * 0.37, 1.0)
		var ember := base + axis * height * (0.5 + ember_t * 0.45) + side * sin(flame_seed + ember_t * 4.0) * width * 0.7
		canvas.draw_line(ember, ember + axis * 4.0, Color(1.0, 0.82, 0.32, (1.0 - ember_t) * strength), 1.6)


static func draw_projectile(canvas: CanvasItem, pos: Vector2, direction: Vector2, radius: float, clock: float, flame_seed: float, low: bool) -> void:
	var dir := direction.normalized() if direction.length() > 0.01 else Vector2.DOWN
	var side := dir.orthogonal()
	# Trailing fingers overlap into a turbulent body with a hot leading edge.
	for i in range(3):
		var offset := side * (i - 1) * radius * 0.46
		draw_flame(canvas, pos + dir * radius * 0.6 + offset, radius * (1.0 if i == 1 else 0.65), radius * (3.8 if i == 1 else 2.8), clock, flame_seed + i, 0.9, -dir, low)
	var core := PackedVector2Array([pos + dir * radius * 0.85, pos + side * radius * 0.23, pos - dir * radius * 0.38, pos - side * radius * 0.2])
	canvas.draw_colored_polygon(core, Color(1.0, 0.96, 0.67, 0.9))


static func draw_strip(canvas: CanvasItem, a: Vector2, b: Vector2, width: float, clock: float, strength: float, low: bool) -> void:
	var count := clampi(int(a.distance_to(b) / (48.0 if low else 28.0)) + 1, 2, 32 if not low else 16)
	canvas.draw_line(a, b, Color(0.15, 0.035, 0.015, strength * 0.48), width * 1.4, true)
	canvas.draw_line(a, b, Color(0.95, 0.20, 0.015, strength * 0.3), width * 0.75, true)
	for i in range(count):
		var pos := a.lerp(b, float(i) / float(count - 1))
		draw_flame(canvas, pos, width * 0.62, width * (1.2 + 0.4 * sin(i * 2.3)), clock, float(i), strength, Vector2.UP, low)


static func draw_burst(canvas: CanvasItem, center: Vector2, radius: float, clock: float, strength: float, low: bool) -> void:
	var count := 8 if low else 14
	for i in range(count):
		var angle := float(i) * TAU / count
		var pos := center + Vector2.from_angle(angle) * radius * 0.65
		draw_flame(canvas, pos, radius * 0.36, radius * (0.7 + 0.3 * sin(i * 1.7 + 0.5)), clock, i * 0.7, strength, Vector2.UP, low)
	draw_flame(canvas, center, radius * 0.5, radius * 1.5, clock, 9.0, strength, Vector2.UP, low)


static func draw_quadrants(canvas: Node2D, camera: Vector2, viewport: Vector2, world_size: Vector2, elapsed: float, clock: float, low: bool) -> int:
	var drawn := 0
	var cap := LOW_FLAME_CAP if low else NORMAL_FLAME_CAP
	var step := 146.0 if low else 96.0
	var view := Rect2(camera, viewport)
	for quadrant in range(4):
		var state := phase(elapsed, quadrant)
		if state == 0:
			continue
		var rect := quadrant_rect(quadrant, world_size)
		if not rect.intersects(view):
			continue
		var visible := rect.intersection(view)
		var t := age(elapsed, quadrant)
		var warning := clampf(t / WARNING, 0.0, 1.0)
		var outline := Color(1.0, 0.64, 0.12, 0.3 + warning * 0.4)
		canvas.draw_rect(Rect2(rect.position - camera + Vector2.ONE * 3.0, rect.size - Vector2.ONE * 6.0), Color(0.28, 0.085, 0.025, 0.07), true)
		canvas.draw_rect(Rect2(rect.position - camera + Vector2.ONE * 3.0, rect.size - Vector2.ONE * 6.0), outline, false, 2.0)
		var label_pos := visible.get_center() - camera
		var label := "AQUECENDO  %.1fs" % maxf(0.0, WARNING - t) if state == 1 else ("RESFRIANDO" if t >= COOL_START else "EM COMBUSTAO")
		canvas.draw_string(ThemeDB.fallback_font, label_pos + Vector2(-66, 0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.85, 0.52, 0.88))
		var y := floorf(visible.position.y / step) * step + step * 0.5
		while y < visible.end.y:
			var x := floorf(visible.position.x / step) * step + step * 0.5
			while x < visible.end.x:
				var flame_seed := floorf(x / step) * 7.3 + floorf(y / step) * 13.7
				var pos := Vector2(x + sin(flame_seed * 3.8) * step * 0.23, y + sin(flame_seed * 2.1) * step * 0.19)
				if rect.grow(-12.0).has_point(pos) and drawn < cap:
					var heat := heat_at(pos, world_size, elapsed)
					var screen := pos - camera
					var bed := PackedVector2Array([screen + Vector2(-22, 0), screen + Vector2(-10, -8), screen + Vector2(24, -3), screen + Vector2(14, 6), screen + Vector2(-14, 7)])
					canvas.draw_colored_polygon(bed, Color(0.13, 0.027, 0.012, 0.16 + heat * 0.5))
					var spark_alpha := (0.16 + warning * 0.32) if heat < 0.05 else heat * 0.8
					canvas.draw_line(screen + Vector2(-16, 1), screen + Vector2(12, -3), Color(1.0, 0.36 + heat * 0.3, 0.07, spark_alpha), 1.5)
					if heat > 0.01:
						var h := minf(10.0 + heat * (48.0 + 26.0 * sin(flame_seed)), (pos.y - rect.position.y - 5.0) / 1.1)
						draw_flame(canvas, screen, 19.0 + heat * (18.0 + 8.0 * cos(flame_seed)), h, clock, flame_seed, minf(1.0, heat * 1.7), Vector2.UP, low)
						drawn += 1
				x += step
			y += step
	return drawn
