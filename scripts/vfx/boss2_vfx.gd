extends RefCounted
## Local rendering only. All footprints and impact times come from combat state.

const INK := Color(0.015, 0.045, 0.12, 0.94)
const ICE := Color(0.22, 0.84, 1.0, 0.95)
const LIGHT := Color(0.9, 1.0, 1.0, 0.98)
const WARNING := Color(1.0, 0.65, 0.22, 0.96)


static func rim(c: CanvasItem, p: Vector2, radius: float, color: Color, low: bool, end: float = TAU) -> void:
	var segments := 40 if low else 72
	c.draw_arc(p, radius, -PI * 0.5, -PI * 0.5 + end, segments, Color(INK, color.a), 7.0)
	c.draw_arc(p, radius, -PI * 0.5, -PI * 0.5 + end, segments, color, 3.0)


static func crystal(c: CanvasItem, p: Vector2, dir: Vector2, size: float, alpha: float = 1.0) -> void:
	var tip := dir * size
	var side := dir.orthogonal() * size * 0.43
	var points := PackedVector2Array([p + tip, p + side, p - tip * 0.75, p - side, p + tip])
	c.draw_colored_polygon(points, Color(0.08, 0.38, 0.7, alpha))
	c.draw_polyline(points, Color(INK, alpha), 5.0)
	c.draw_polyline(points, Color(ICE, alpha), 2.0)
	c.draw_colored_polygon(PackedVector2Array([p + tip, p, p - side]), Color(0.72, 0.98, 1.0, alpha))
	c.draw_line(p - tip * 0.5, p + tip * 0.85, Color(LIGHT, alpha), 1.5)


static func trajectory(c: CanvasItem, origin: Vector2, dir: Vector2, length: float, time: float, alpha: float) -> void:
	# Moving dashes preserve the path without covering the ground with a solid web.
	for i in range(10):
		var distance := 30.0 + fposmod(i * length / 10.0 + time * 65.0, length - 30.0)
		var start := origin + dir * distance
		var end := origin + dir * minf(length, distance + 24.0)
		c.draw_line(start, end, Color(INK, alpha * 0.8), 4.0)
		c.draw_line(start, end, Color(WARNING, alpha), 1.5)


static func impact(c: CanvasItem, p: Vector2, radius: float, elapsed: float, low: bool) -> void:
	var t := clampf(elapsed / 0.48, 0.0, 1.0)
	var fade := 1.0 - t
	if fade <= 0.0:
		return
	c.draw_circle(p, radius * (0.72 + t * 0.28), Color(0.26, 0.8, 1.0, 0.18 * fade))
	rim(c, p, radius * (0.35 + 0.65 * t), Color(LIGHT, fade), low)
	for i in range(5 if low else 9):
		var dir := Vector2.from_angle(i * 2.4)
		crystal(c, p + dir * radius * t, dir, (6.0 + i % 3) * fade, fade)


static func target(c: CanvasItem, p: Vector2, radius: float, age: float, hit_time: float, low: bool, falling: bool = true) -> void:
	if age >= hit_time:
		impact(c, p, radius, age - hit_time, low)
		return
	var progress := clampf(age / maxf(0.01, hit_time), 0.0, 1.0)
	# The full collision boundary stays visible from the first warning frame.
	c.draw_circle(p, radius, Color(0.06, 0.035, 0.12, 0.24))
	rim(c, p, radius, WARNING, low)
	rim(c, p, maxf(3.0, radius - 7.0), LIGHT, low, maxf(0.001, TAU * progress))
	for i in range(4):
		var dir := Vector2.from_angle(i * PI * 0.5)
		c.draw_line(p + dir * (radius + 4.0), p + dir * (radius + 13.0), INK, 6.0)
		c.draw_line(p + dir * (radius + 4.0), p + dir * (radius + 13.0), WARNING, 2.0)
	if falling and hit_time - age < 0.42:
		var height := 260.0 * pow(clampf((hit_time - age) / 0.42, 0.0, 1.0), 0.7)
		var head := p - Vector2(0, height)
		c.draw_line(head - Vector2(0, 40), head, Color(ICE, 0.3), 11.0)
		crystal(c, head, Vector2.DOWN, 24.0)


static func lane(c: CanvasItem, a: Vector2, b: Vector2, half_width: float, progress: float, active: bool, t: float, low: bool) -> void:
	var dir := a.direction_to(b)
	var side := dir.orthogonal() * half_width
	var color := ICE if active else WARNING
	c.draw_line(a, b, Color(0.02, 0.07, 0.14, 0.23), half_width * 2.0)
	for sign_dir in [-1.0, 1.0]:
		c.draw_line(a + side * sign_dir, b + side * sign_dir, INK, 6.0)
		c.draw_line(a + side * sign_dir, b + side * sign_dir, color, 2.5)
	if active:
		c.draw_line(a, b, Color(ICE, 0.2), half_width * 1.5)
		for i in range(5 if low else 10):
			var point := a.lerp(b, fposmod(i * 0.137 + t * 0.8, 1.0))
			crystal(c, point, dir, 9.0 + (i % 3) * 2.0, 0.85)
	else:
		c.draw_line(a, a.lerp(b, progress), Color(LIGHT, 0.7), 2.0)


static func attack(g: Node2D, data: Dictionary, camera: Vector2, low: bool) -> void:
	var age := float(data.get("age", 0.0))
	var warn := float(data.get("warn", 1.0))
	var progress := clampf(age / maxf(0.01, warn), 0.0, 1.0)
	var active := age >= warn
	var origin: Vector2 = g.boss_pos - camera
	var t: float = g.time_alive
	match String(data["kind"]):
		"ice_pillar", "flash_freeze":
			target(g, Vector2(data["target"]) - camera, float(data["radius"]), age, warn, low, data["kind"] == "ice_pillar")
		"avalanche":
			for pos in data["targets"]:
				target(g, Vector2(pos) - camera, 58.0, age, warn + 1.0, low)
		"spin_spit_up":
			for entry in data["targets"]:
				target(g, Vector2(entry["pos"]) - camera, float(entry.get("radius", 60.0)), age, warn + float(entry.get("delay", 0.0)), low)
		"glacial_stomp":
			if age > warn + g.BOSS2_STOMP_ACTIVE:
				return
			for crack in data["cracks"]:
				lane(g, Vector2(crack["a"]) - camera, Vector2(crack["b"]) - camera, float(crack["width"]), progress, active, t, low)
				# Segment-distance collision also covers the rounded endpoints.
				for endpoint in ["a", "b"]:
					rim(g, Vector2(crack[endpoint]) - camera, float(crack["width"]), ICE if active else WARNING, low)
		"frost_breath":
			# Combat uses a 280 px, +/-0.48 rad cone, not a full-map laser.
			var angle := Vector2(data["dir"]).angle()
			var points := PackedVector2Array([origin])
			for i in range(25):
				points.append(origin + Vector2.from_angle(angle - 0.48 + 0.96 * i / 24.0) * 280.0)
			points.append(origin)
			g.draw_colored_polygon(points, Color(0.04, 0.13, 0.22, 0.28))
			g.draw_polyline(points, INK, 7.0)
			g.draw_polyline(points, ICE if active else WARNING, 3.0)
			for i in range(6 if low else 12):
				var dir := Vector2.from_angle(angle + sin(i * 2.4) * 0.42)
				var distance := fposmod(i * 27.0 + t * 230.0, 260.0)
				if active:
					crystal(g, origin + dir * distance, dir, 6.0 + distance * 0.025, 0.8)
		"ice_prison":
			var center := Vector2(data["center"]) - camera
			var radius := float(data["radius"])
			target(g, center, radius * 0.58, age, warn, low, false)
			for entry in data["crystals"]:
				crystal(g, Vector2(entry["pos"]) - camera, Vector2.UP, 18.0 + progress * 20.0, 0.55 + progress * 0.4)
		"shield":
			rim(g, origin, 92.0, ICE, low)
			for i in range(6):
				var dir := Vector2.from_angle(float(data.get("angle", 0.0)) + i * TAU / 6.0)
				crystal(g, origin + dir * 92.0, dir, 18.0)
		"blizzard":
			var viewport: Vector2 = g.get_viewport_rect().size
			for wave in data["waves"]:
				var horizontal := String(wave.get("direction", "left")) in ["left", "right"]
				var pos := float(wave.get("x" if horizontal else "y", 0.0)) - (camera.x if horizontal else camera.y)
				var a := Vector2(pos, -40) if horizontal else Vector2(-40, pos)
				var b := Vector2(pos, viewport.y + 40) if horizontal else Vector2(viewport.x + 40, pos)
				lane(g, a, b, float(wave.get("width", g.BOSS2_WAVE_WIDTH)) * 0.5, progress, active, t, low)
