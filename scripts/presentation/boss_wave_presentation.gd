extends RefCounted

# Boss 1 wave drawing only. State and gameplay stay on the host runtime.


static func _draw_boss_wave_safe_sector(game: Node2D, center: Vector2, angle: float, size: float, radius: float, alpha: float, enraged: bool = false) -> void :
	var profile: String = game._get_boss_wave_quality_profile()
	var points = PackedVector2Array([center])
	var segments = 14
	for segment in range(segments + 1):
		var sector_angle = angle - size * 0.5 + size * float(segment) / float(segments)
		points.append(center + Vector2.from_angle(sector_angle) * radius)

	var fill_color: Color = Color(0.04, 0.78, 0.72, alpha) if not enraged else Color(0.02, 0.85, 0.82, alpha * 1.1)
	game.draw_polygon(points, PackedColorArray([fill_color]))

	var left = center + Vector2.from_angle(angle - size * 0.5) * radius
	var right = center + Vector2.from_angle(angle + size * 0.5) * radius
	var border_color: Color = Color(0.32, 1.0, 0.84, min(0.82, alpha * 2.6))
	game.draw_line(center, left, border_color, 2.2)
	game.draw_line(center, right, border_color, 2.2)

	if profile != "LOW" and alpha > 0.06:
		var line_step: float = 140.0
		var max_r: float = min(radius, 600.0)
		var step_r: float = 120.0
		while step_r < max_r:
			var arc_left: Vector2 = center + Vector2.from_angle(angle - size * 0.35) * step_r
			var arc_right: Vector2 = center + Vector2.from_angle(angle + size * 0.35) * step_r
			game.draw_line(arc_left, arc_right, Color(0.4, 0.98, 0.9, alpha * 0.45), 1.2)
			step_r += line_step


static func _draw_boss_wave_water_body(game: Node2D, center: Vector2, radius: float, arc_ranges: Array, width: float, enraged: bool, profile: String) -> void :
	var c_base: Color = Color(0.02, 0.22, 0.58, 0.52) if enraged else Color(0.04, 0.28, 0.68, 0.48)
	var c_core: Color = Color(0.0, 0.65, 0.92, 0.82) if enraged else Color(0.08, 0.58, 0.88, 0.78)
	var c_upper: Color = Color(0.45, 0.92, 1.0, 0.88) if enraged else Color(0.32, 0.84, 0.96, 0.82)

	for arc in arc_ranges:
		var a1: float = float(arc.x)
		var a2: float = float(arc.y)

		if game.current_phase == 1:
			game.Boss1VFX.arc(game, center, radius, a1, a2, c_core, width, profile == "LOW")
			continue
		game.draw_arc(center, radius, a1, a2, 58, c_base, width + 7.0)
		game.draw_arc(center, radius, a1, a2, 58, c_core, width + 1.0)

		if profile != "LOW":
			game.draw_arc(center, radius + width * 0.15, a1, a2, 58, c_upper, max(2.0, width * 0.4))


static func _draw_boss_wave_crest_and_foam(game: Node2D, center: Vector2, wave: Dictionary, radius: float, arc_ranges: Array, width: float, enraged: bool, profile: String) -> void :
	var age: float = float(wave.get("age", 0.0))
	var wave_idx: int = int(wave.get("idx", 0))

	var crest_color: Color = Color(0.94, 0.99, 1.0, 0.95)
	var undertone_color: Color = Color(0.45, 0.92, 1.0, 0.86) if enraged else Color(0.38, 0.88, 0.98, 0.80)

	var crest_r: float = radius + width * 0.45

	for arc in arc_ranges:
		var a1: float = float(arc.x)
		var a2: float = float(arc.y)

		if profile == "LOW":
			game.draw_arc(center, crest_r, a1, a2, 58, undertone_color, 4.0)
			game.draw_arc(center, crest_r + 1.0, a1, a2, 58, crest_color, 2.0)
		else:
			var segments: int = 42
			var arc_len: float = a2 - a1
			var pts_undertone: PackedVector2Array = PackedVector2Array()
			var pts_crest: PackedVector2Array = PackedVector2Array()

			for s in range(segments + 1):
				var frac: float = float(s) / float(segments)
				var angle: float = a1 + frac * arc_len
				var jitter: float = sin(angle * 16.0 + age * 14.0 + float(wave_idx) * 2.5) * (2.2 if enraged else 1.5)
				var cur_r: float = crest_r + jitter
				pts_crest.append(center + Vector2.from_angle(angle) * cur_r)
				pts_undertone.append(center + Vector2.from_angle(angle) * (cur_r - 1.5))

			if pts_undertone.size() > 1:
				game.draw_polyline(pts_undertone, undertone_color, 4.0, true)
			if pts_crest.size() > 1:
				game.draw_polyline(pts_crest, crest_color, 2.0, true)

		var foam_step: float = 0.08 if enraged else 0.12
		if profile == "LOW":
			foam_step = 0.24

		var angle_curr: float = a1
		var step_i: int = 0
		while angle_curr < a2:
			step_i += 1
			var foam_time: float = age * 2.4 if game.current_phase == 1 else floor(age * 8.0) * 0.3
			var h1: float = sin(float(wave_idx) * 17.3 + float(step_i) * 9.1 + foam_time)
			var h2: float = cos(float(step_i) * 13.7 + float(wave_idx) * 5.2)

			if h1 > (0.1 if profile == "HIGH" else 0.35):
				var f_angle: float = angle_curr + h2 * 0.03
				var f_dist: float = crest_r + h1 * (3.5 if enraged else 2.5)
				var foam_pos: Vector2 = center + Vector2.from_angle(f_angle) * f_dist
				var foam_size: float = 2.0 + abs(h2) * (2.4 if enraged else 1.8)
				var foam_col: Color = Color(0.96, 1.0, 1.0, 0.85 + h1 * 0.15) if h2 > 0.0 else Color(0.6, 0.95, 1.0, 0.78)

				game.draw_circle(foam_pos, foam_size, foam_col)

				if profile == "HIGH" and h1 > 0.65:
					var spray_pos: Vector2 = center + Vector2.from_angle(f_angle + 0.015) * (f_dist + 4.5)
					game.draw_circle(spray_pos, 1.2, Color(0.9, 0.98, 1.0, 0.7))

			angle_curr += foam_step


static func _draw_boss_wave_trail(game: Node2D, center: Vector2, radius: float, arc_ranges: Array, width: float, enraged: bool, profile: String) -> void :
	if profile == "LOW":
		return

	var trail_r: float = radius - width * 0.55
	var trail_width: float = width * 0.7
	var trail_color: Color = Color(0.02, 0.35, 0.75, 0.32) if not enraged else Color(0.01, 0.45, 0.85, 0.42)

	for arc in arc_ranges:
		var a1: float = float(arc.x)
		var a2: float = float(arc.y)
		game.draw_arc(center, trail_r, a1, a2, 48, trail_color, trail_width)


static func _draw_boss_siege_tide(game: Node2D, center: Vector2, wave: Dictionary, radius: float, arc_ranges: Array, width: float, enraged: bool, profile: String) -> void:
	var age: float = float(wave.get("age", 0.0))
	var warning: float = maxf(0.01, float(wave.get("warning", game.BOSS1_SIEGE_TIDE_WARNING)))
	var idx: int = int(wave.get("idx", 0))
	var seed_value: float = float(int(wave.get("seed", idx)) % 997) * 0.017
	var warn_progress: float = clampf(age / warning, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(game.time_alive * 9.0 + seed_value)
	var amber: Color = Color(1.0, 0.48, 0.08, 0.8)
	var sand: Color = Color(0.86, 0.26, 0.05, 0.58)
	var fissure: Color = Color(1.0, 0.8, 0.28, 0.72)
	var low: bool = profile == "LOW"

	for arc in arc_ranges:
		var a1: float = float(arc.x)
		var a2: float = float(arc.y)
		if age < warning:
			game.draw_arc(center, maxf(18.0, radius), a1, a2, 42, Color(0.78, 0.22, 0.03, 0.18 + warn_progress * 0.18), maxf(3.0, width * 0.45))
			continue
		game.draw_arc(center, radius, a1, a2, 48, Color(0.48, 0.12, 0.02, 0.46), width + 7.0)
		game.draw_arc(center, radius, a1, a2, 48, sand, width + 1.0)
		game.draw_arc(center, radius + width * 0.18, a1, a2, 48, amber, maxf(2.0, width * 0.4))
		if not low:
			var crack_count: int = 5 if profile == "HIGH" else 3
			for crack in range(crack_count):
				var crack_t: float = (float(crack) + 0.5) / float(crack_count)
				var crack_angle: float = lerpf(a1, a2, crack_t) + sin(seed_value + float(crack) * 3.1) * 0.025
				var inner: Vector2 = center + Vector2.from_angle(crack_angle) * maxf(8.0, radius - width * 0.2)
				var outer: Vector2 = center + Vector2.from_angle(crack_angle + sin(seed_value + crack) * 0.018) * (radius + width * 0.9)
				game.draw_line(inner, outer, fissure, 1.2 if profile == "MEDIUM" else 1.8, true)

	var impact_progress: float = clampf((age - warning) / 0.24, 0.0, 1.0)
	if age >= warning and impact_progress < 1.0:
		var impact_alpha: float = (1.0 - impact_progress) * (0.36 + pulse * 0.16)
		game.draw_arc(center, radius + width * 1.8 + impact_progress * 18.0, 0.0, TAU, 56, Color(1.0, 0.68, 0.16, impact_alpha), 2.0)
		if not low:
			for particle in range(6 if profile == "HIGH" else 3):
				var particle_angle: float = seed_value + float(particle) * TAU / 6.0
				var particle_pos: Vector2 = center + Vector2.from_angle(particle_angle) * (radius + width + impact_progress * 20.0)
				game.draw_circle(particle_pos, 1.5 + impact_progress * 1.8, Color(1.0, 0.72, 0.24, impact_alpha))

	if age >= warning and age < warning + 0.52:
		var fade: float = 1.0 - clampf((age - warning) / 0.52, 0.0, 1.0)
		game.draw_arc(center, radius + width * 1.5, 0.0, TAU, 56, Color(1.0, 0.56, 0.12, fade * 0.24), 2.0)
