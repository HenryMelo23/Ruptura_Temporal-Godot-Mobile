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
	if depth > 0.7:
		c.draw_rect(Rect2(tip.floor(), Vector2(2, 3)), Color(0.95, 1.0, 1.0, alpha))


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
