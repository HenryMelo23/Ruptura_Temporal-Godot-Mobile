extends RefCounted
## Pixel-sized precipitation layers; no gameplay or random state is changed here.


static func rain(c: CanvasItem, p: Vector2, drop: Dictionary, intensity: float) -> void:
	var depth := clampf((float(drop["size"]) - 1.2), 0.0, 1.0)
	var streak := Vector2(float(drop["wind"]) * 0.055, float(drop["len"]))
	var alpha := (0.3 + depth * 0.4) * lerpf(0.35, 1.0, intensity)
	var tip := p + streak * 0.5
	c.draw_line(p - streak * 0.5, tip, Color(0.035, 0.13, 0.22, alpha * 0.5), 2.0 + depth * 2.0)
	c.draw_line(p - streak * 0.5, tip, Color(0.55, 0.8, 0.95, alpha * 0.65), 1.0 + depth)
	c.draw_line(p, tip, Color(0.86, 0.96, 1.0, alpha), 1.0)
	var width := 1.5 + depth * 1.8
	var body := PackedVector2Array([tip - Vector2(0, 10 + depth * 5), tip + Vector2(width, -3), tip + Vector2(width * 0.6, 1), tip + Vector2(-width * 0.7, 1), tip + Vector2(-width, -3)])
	c.draw_colored_polygon(body, Color(0.58, 0.85, 0.97, alpha))
	c.draw_line(tip - Vector2(0, 7), tip - Vector2(0, 2), Color(0.94, 1, 1, alpha), 1.0)


static func puddle(c: CanvasItem, center: Vector2, data: Dictionary, alpha: float) -> void:
	var radius := float(data["r"])
	var phase := float(data["phase"])
	var outline := PackedVector2Array()
	for i in range(32):
		var angle := TAU * i / 32.0
		var wave := 1.0 + sin(angle * 3.0 + phase * 0.7) * 0.09 + cos(angle * 5.0 - phase) * 0.045
		outline.append(Vector2.from_angle(angle) * radius * wave)
	c.draw_set_transform(center, float(data["tilt"]), Vector2(1, 0.42))
	c.draw_colored_polygon(outline, Color(0.08, 0.28, 0.36, 0.58 * alpha))
	outline.append(outline[0])
	c.draw_polyline(outline, Color(0.04, 0.12, 0.17, 0.75 * alpha), 3.0)
	c.draw_arc(Vector2(0, 2), radius * 0.87, 0.12, 2.7, 22, Color(0.36, 0.73, 0.83, 0.6 * alpha), 2.0)
	for i in range(2):
		var progress := fposmod(phase * 0.65 + i * 0.5, 1.0)
		var origin := Vector2(sin(float(i) * 4.1) * radius * 0.22, cos(float(i) * 3.7) * radius * 0.2)
		c.draw_arc(origin, radius * (0.08 + progress * 0.65), 0.2, 5.7, 24, Color(0.64, 0.89, 0.96, (1.0 - progress) * 0.48 * alpha), 1.8)
	for i in range(3):
		var y := -radius * 0.45 + i * radius * 0.23
		var x := sin(phase * 1.5 + i) * radius * 0.12
		c.draw_line(Vector2(x - radius * 0.36, y), Vector2(x + radius * (0.12 + i * 0.07), y - 2), Color(0.8, 0.96, 1, alpha * 0.38), 2.0)
	c.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


static func splash(c: CanvasItem, center: Vector2, data: Dictionary, camera: Vector2) -> void:
	var alpha := clampf(float(data["life"]) / float(data["max_life"]), 0, 1)
	var age := 1.0 - alpha
	var radius := float(data["radius"]) * (0.3 + sqrt(age) * 1.9)
	c.draw_set_transform(center, 0, Vector2(1, 0.38))
	c.draw_arc(Vector2.ZERO, radius, 0, TAU, 20, Color(0.06, 0.22, 0.3, alpha * 0.7), 3.5)
	c.draw_arc(Vector2.ZERO, radius, 0.2, 5.8, 20, Color(0.7, 0.94, 1, alpha * 0.8), 1.8)
	c.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if age < 0.45:
		var crown := PackedVector2Array()
		for i in range(7):
			crown.append(center + Vector2((i - 3) * 2.0, -sin(age / 0.45 * PI) * (8.0 if i % 2 else 2.0)))
		c.draw_polyline(crown, Color(0.79, 0.97, 1, alpha * 0.85), 2.0)
	for bit in data.get("droplets", []):
		var pos := Vector2(bit["pos"]) - camera
		var size := float(bit["size"]) * sqrt(alpha)
		c.draw_circle(pos, size + 0.7, Color(0.06, 0.24, 0.33, alpha * 0.7))
		c.draw_circle(pos, size, Color(0.69, 0.91, 1, alpha))
		c.draw_line(pos - Vector2(0, size), pos, Color(1, 1, 1, alpha), 1.0)


static func snow(c: CanvasItem, p: Vector2, flake: Dictionary, storm: bool, low: bool) -> void:
	var size := float(flake["size"])
	var age := float(flake.get("age", 1.0))
	var phase := float(flake["phase"])
	var alpha := minf(clampf(age / 0.6, 0.0, 1.0), clampf(float(flake["life"]) / 1.3, 0.0, 1.0))
	alpha *= (0.26 + size * 0.1) * (0.42 if storm else 1.0)
	var center := p.floor()
	if size < 2.6 or low:
		c.draw_rect(Rect2(center, Vector2.ONE * maxf(1.0, floorf(size))), Color(0.76, 0.91, 1.0, alpha))
		return
	var axis := Vector2.from_angle(phase * 0.35)
	var stretch := 0.55 + absf(sin(phase * 0.65)) * 0.45
	for i in range(3):
		var dir := axis.rotated(i * PI / 3.0) * size * Vector2(stretch, 1.0)
		c.draw_line(center - dir, center + dir, Color(0.09, 0.24, 0.37, alpha * 0.4), 3.0)
		c.draw_line(center - dir, center + dir, Color(0.87, 0.97, 1.0, alpha), 1.0)
	c.draw_rect(Rect2(center - Vector2.ONE, Vector2(2, 2)), Color(1.0, 1.0, 1.0, alpha))
