@static_unload
extends RefCounted
class_name RTLaceranteVfxPresentation

# Presentation and VFX controller for Geovana's Lacerante manifestation.
# Responsibilities:
# 1. Visceral Teleport Tear ("Rasgo Lacerado"): A dimensional reality-shearing wound
#    left in the earth along the teleport path, featuring jagged ragged wound lips,
#    abyssal crimson-black core, straining flesh/sinew cross-fibers, entry/exit claw ruptures,
#    perimeter blood spatter, and dynamic progressive coagulation and fading.
# 2. Dynamic Lacerate Passive Bleed: Continuous dynamic blood gushing/spurting out of
#    affected enemies in all directions with arcs, drag, and gravity, leaving subtle
#    fading blood splatters and movement trails on the ground that fade out progressively.

# Visceral arterial color palette
const COLOR_VOID_ABYSS := Color(0.035, 0.002, 0.008, 0.98)
const COLOR_FLESH_DEEP := Color(0.24, 0.012, 0.032, 0.95)
const COLOR_BLOOD_ARTERIAL := Color(0.56, 0.02, 0.06, 0.95)
const COLOR_BLOOD_CRIMSON := Color(0.88, 0.05, 0.12, 0.96)
const COLOR_BLOOD_BRIGHT := Color(1.0, 0.20, 0.26, 0.98)
const COLOR_BLOOD_GLINT := Color(1.0, 0.86, 0.88, 0.98)
const COLOR_BLOOD_DRIED := Color(0.18, 0.012, 0.022, 0.75)

# Performance & memory caps
const MAX_GROUND_MARKS_DESKTOP := 140
const MAX_GROUND_MARKS_MOBILE := 50
const MAX_FLYING_SPURTS_DESKTOP := 110
const MAX_FLYING_SPURTS_MOBILE := 40
const GROUND_MARK_DEFAULT_LIFE := 4.2

# Active presentation state
static var flying_spurts: Array = []
static var ground_marks: Array = []


static func reset() -> void:
	flying_spurts.clear()
	ground_marks.clear()


static func _ground_mark_cap(game: Node2D) -> int:
	if game._memory_saver_active():
		return 30
	if game._runtime_visual_budget_active() or game.mobile_adaptive_visual_budget:
		return MAX_GROUND_MARKS_MOBILE
	return MAX_GROUND_MARKS_DESKTOP


static func _flying_spurt_cap(game: Node2D) -> int:
	if game._memory_saver_active():
		return 25
	if game._runtime_visual_budget_active() or game.mobile_adaptive_visual_budget:
		return MAX_FLYING_SPURTS_MOBILE
	return MAX_FLYING_SPURTS_DESKTOP


static func on_lacerate_applied(game: Node2D, target: Variant) -> void:
	var target_pos := Vector2.ZERO
	if target is Dictionary:
		target_pos = Vector2(target.get("pos", Vector2.ZERO))
	elif target is Vector2:
		target_pos = target
	else:
		return

	if not game._particle_budget_available() or not game.gfx_particles:
		_add_ground_mark(game, target_pos, game.rng.randf_range(7.0, 12.0), game.rng.randf_range(3.5, 4.5))
		return

	var burst_count: int = 10 if not (game._runtime_visual_budget_active() or game.mobile_adaptive_visual_budget) else 5
	for i in range(burst_count):
		var angle: float = float(i) * TAU / float(maxi(1, burst_count)) + game.rng.randf_range(-0.25, 0.25)
		var speed: float = game.rng.randf_range(110.0, 260.0)
		var size: float = game.rng.randf_range(2.4, 4.4)
		var life: float = game.rng.randf_range(0.24, 0.46)
		_add_spurt(
			game,
			target_pos + Vector2(game.rng.randf_range(-8.0, 8.0), game.rng.randf_range(-12.0, 6.0)),
			Vector2.from_angle(angle) * speed,
			size,
			life
		)

	# Fresh visceral impact ground stain
	_add_ground_mark(game, target_pos, game.rng.randf_range(8.0, 14.0), game.rng.randf_range(3.8, 4.8))


static func _add_spurt(game: Node2D, pos: Vector2, vel: Vector2, size: float, life: float) -> void:
	if flying_spurts.size() >= _flying_spurt_cap(game):
		flying_spurts.pop_front()
	flying_spurts.append({
		"pos": pos,
		"vel": vel,
		"size": size,
		"life": life,
		"max": life,
		"color": COLOR_BLOOD_CRIMSON if game.rng.randf() > 0.3 else COLOR_BLOOD_ARTERIAL
	})


static func _add_ground_mark(game: Node2D, pos: Vector2, radius: float, life: float) -> void:
	var cap: int = _ground_mark_cap(game)
	if ground_marks.size() >= cap:
		ground_marks.pop_front()

	var satellites: Array = []
	var sat_count: int = game.rng.randi_range(2, 4)
	for s in range(sat_count):
		var sat_angle: float = game.rng.randf_range(0.0, TAU)
		var sat_dist: float = radius * game.rng.randf_range(1.2, 2.3)
		satellites.append({
			"offset": Vector2.from_angle(sat_angle) * sat_dist,
			"radius": game.rng.randf_range(1.2, maxf(1.6, radius * 0.32))
		})

	ground_marks.append({
		"pos": pos,
		"radius": radius,
		"life": life,
		"max": life,
		"color": COLOR_BLOOD_ARTERIAL if game.rng.randf() > 0.4 else COLOR_FLESH_DEEP,
		"satellites": satellites
	})


static func update(game: Node2D, delta: float) -> void:
	# 1. Update flying blood spurts (physics: velocity, gravity, drag)
	# Iterate backwards so expired entries can be removed in place. This avoids
	# rebuilding both VFX arrays every rendered frame during dense encounters.
	for spurt_index in range(flying_spurts.size() - 1, -1, -1):
		var spurt: Dictionary = flying_spurts[spurt_index]
		spurt["life"] = float(spurt["life"]) - delta
		if float(spurt["life"]) <= 0.0:
			if game.rng.randf() < 0.65:
				_add_ground_mark(game, Vector2(spurt["pos"]), float(spurt.get("size", 3.0)) * 1.4, game.rng.randf_range(2.8, 3.8))
			flying_spurts.remove_at(spurt_index)
			continue
		var vel: Vector2 = Vector2(spurt.get("vel", Vector2.ZERO))
		vel += Vector2(0.0, 145.0) * delta
		vel *= pow(0.86, delta * 60.0)
		spurt["vel"] = vel
		spurt["pos"] = Vector2(spurt["pos"]) + vel * delta

	# 2. Update ground blood marks (fade out)
	for mark_index in range(ground_marks.size() - 1, -1, -1):
		var mark: Dictionary = ground_marks[mark_index]
		mark["life"] = float(mark["life"]) - delta
		if float(mark["life"]) <= 0.0:
			ground_marks.remove_at(mark_index)

	# 3. Dynamic gushing from bleeding enemies while passive is active
	var budget_ok: bool = game._particle_budget_available() and game.gfx_particles
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var laceracao: int = int(enemy.get("laceracao", 0))
		var bleed_timer: float = float(enemy.get("bleed_timer", 0.0))
		if laceracao <= 0 or bleed_timer <= 0.0:
			continue

		var cd: float = float(enemy.get("_lacerante_spurt_cd", 0.0)) - delta
		if cd <= 0.0:
			cd = game.rng.randf_range(0.08, 0.15)
			var enemy_pos: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))

			if budget_ok:
				var spurt_count: int = mini(4, 2 + int(floor(float(laceracao) * 0.5)))
				for j in range(spurt_count):
					var angle: float = game.rng.randf_range(0.0, TAU)
					var speed: float = game.rng.randf_range(70.0, 200.0)
					var size: float = game.rng.randf_range(2.0, 3.8)
					var life: float = game.rng.randf_range(0.20, 0.38)
					_add_spurt(
						game,
						enemy_pos + Vector2(game.rng.randf_range(-8.0, 8.0), game.rng.randf_range(-14.0, 6.0)),
						Vector2.from_angle(angle) * speed,
						size,
						life
					)

			# Trail deposit under the moving/bleeding enemy
			var trail_pos: Vector2 = enemy_pos + Vector2(game.rng.randf_range(-6.0, 6.0), game.rng.randf_range(-4.0, 6.0))
			_add_ground_mark(game, trail_pos, game.rng.randf_range(3.8, 7.2), game.rng.randf_range(3.0, 4.4))

		enemy["_lacerante_spurt_cd"] = cd


static func draw_ground_marks(game: CanvasItem, camera: Vector2) -> void:
	if ground_marks.is_empty():
		return

	var has_view_check: bool = game.has_method("_world_point_in_view")
	for mark in ground_marks:
		var world_pos: Vector2 = Vector2(mark.get("pos", Vector2.ZERO))
		if has_view_check and not game.call("_world_point_in_view", world_pos, camera, 80.0):
			continue

		var pos: Vector2 = world_pos - camera
		var life: float = float(mark.get("life", 0.0))
		var max_life: float = maxf(0.01, float(mark.get("max", GROUND_MARK_DEFAULT_LIFE)))
		var alpha: float = clampf(life / max_life, 0.0, 1.0)
		var radius: float = float(mark.get("radius", 6.0))
		var color: Color = mark.get("color", COLOR_BLOOD_ARTERIAL)

		# Outer dried blood soak rim (subtle mark on the ground)
		game.draw_circle(pos, radius * 1.55, Color(color.r * 0.75, 0.01, 0.02, 0.20 * alpha))
		# Main blood pool / splatter blob
		game.draw_circle(pos, radius, Color(color.r, color.g, color.b, 0.58 * alpha))
		# Darker core of coagulated blood
		game.draw_circle(pos, radius * 0.52, Color(COLOR_BLOOD_DRIED.r, COLOR_BLOOD_DRIED.g, COLOR_BLOOD_DRIED.b, 0.72 * alpha))

		# Splatter satellites
		for sat in mark.get("satellites", []):
			var sat_pos: Vector2 = pos + Vector2(sat.get("offset", Vector2.ZERO))
			game.draw_circle(sat_pos, float(sat.get("radius", 1.5)), Color(color.r, color.g, color.b, 0.48 * alpha))


static func draw_blood_spurts(game: CanvasItem, camera: Vector2) -> void:
	if flying_spurts.is_empty():
		return

	var has_view_check: bool = game.has_method("_world_point_in_view")
	for spurt in flying_spurts:
		var world_pos: Vector2 = Vector2(spurt.get("pos", Vector2.ZERO))
		if has_view_check and not game.call("_world_point_in_view", world_pos, camera, 60.0):
			continue

		var pos: Vector2 = world_pos - camera
		var vel: Vector2 = Vector2(spurt.get("vel", Vector2.ZERO))
		var life: float = float(spurt.get("life", 0.0))
		var max_life: float = maxf(0.01, float(spurt.get("max", 0.35)))
		var alpha: float = clampf(life / max_life, 0.0, 1.0)
		var size: float = float(spurt.get("size", 3.0))
		var color: Color = spurt.get("color", COLOR_BLOOD_CRIMSON)

		var speed: float = vel.length()
		var streak: Vector2 = vel.normalized() * minf(speed * 0.035, size * 2.8) if speed > 10.0 else Vector2.ZERO

		if streak.length() > 1.0:
			game.draw_line(pos - streak, pos + streak * 0.4, Color(color.r, color.g, color.b, 0.88 * alpha), size, true)
		game.draw_circle(pos, size * 0.85, Color(COLOR_BLOOD_BRIGHT.r, COLOR_BLOOD_BRIGHT.g, COLOR_BLOOD_BRIGHT.b, 0.95 * alpha))


static func draw_teleport_tear(game: CanvasItem, slash: Dictionary, camera: Vector2) -> void:
	var fallback_pos: Vector2 = Vector2(game.get("player_pos")) if game.get("player_pos") != null else Vector2.ZERO
	var a: Vector2 = Vector2(slash.get("a", fallback_pos)) - camera
	var b: Vector2 = Vector2(slash.get("b", fallback_pos)) - camera
	var diff: Vector2 = b - a
	var dist: float = diff.length()
	if dist <= 1.0:
		return

	var dir: Vector2 = diff / dist
	var normal: Vector2 = dir.orthogonal()

	var life: float = float(slash.get("life", 0.0))
	var max_life: float = maxf(0.01, float(slash.get("max", 3.0)))
	var fade: float = clampf(life / max_life, 0.0, 1.0)

	var segs: int = clampi(int(dist / 24.0), 16, 36)
	var max_width: float = 44.0 * (0.65 + 0.35 * fade)

	var left_points: PackedVector2Array = PackedVector2Array()
	var right_points: PackedVector2Array = PackedVector2Array()

	# Organic rhythmic pulse
	var time_val: float = float(game.get("time_alive")) if game.get("time_alive") != null else 0.0
	var pulse: float = sin(time_val * 9.0) * 0.08

	for i in range(segs + 1):
		var t: float = float(i) / float(segs)
		var base: Vector2 = a.lerp(b, t)
		var env: float = sin(t * PI)

		# Stable deterministic pseudo-random jagged tooth offsets
		var j_left: float = (sin(float(i) * 3.71 + 0.5) * 0.44 + cos(float(i) * 7.13) * 0.26)
		var j_right: float = (cos(float(i) * 4.19 + 1.2) * 0.44 + sin(float(i) * 6.83) * 0.26)
		var tooth: float = 0.32 if (i % 3 == 0) else 0.0

		var w_left: float = env * max_width * (0.85 + j_left * 0.4 + tooth + pulse)
		var w_right: float = env * max_width * (0.85 + j_right * 0.4 + tooth + pulse)

		left_points.append(base + normal * w_left)
		right_points.append(base - normal * w_right)

	# 1. Soft bleeding under-glow / ground depression along the tear
	game.draw_polyline(PackedVector2Array([a, a.lerp(b, 0.5), b]), Color(COLOR_BLOOD_ARTERIAL.r, 0.01, 0.03, 0.35 * fade), max_width * 2.0, true)
	game.draw_polyline(PackedVector2Array([a, a.lerp(b, 0.5), b]), Color(COLOR_FLESH_DEEP.r, 0.015, 0.035, 0.60 * fade), max_width * 1.35, true)

	# 2. Visceral abyss void core polygon
	var poly: PackedVector2Array = PackedVector2Array()
	for pt in left_points:
		poly.append(pt)
	for k in range(right_points.size() - 1, -1, -1):
		poly.append(right_points[k])
	game.draw_polygon(poly, PackedColorArray([Color(COLOR_VOID_ABYSS.r, COLOR_VOID_ABYSS.g, COLOR_VOID_ABYSS.b, 0.97 * fade)]))

	# 3. Jagged flesh lips (crimson torn flesh rim + sharp razor glint)
	game.draw_polyline(left_points, Color(COLOR_BLOOD_CRIMSON.r, COLOR_BLOOD_CRIMSON.g, COLOR_BLOOD_CRIMSON.b, 0.92 * fade), 4.2, true)
	game.draw_polyline(right_points, Color(COLOR_BLOOD_CRIMSON.r, COLOR_BLOOD_CRIMSON.g, COLOR_BLOOD_CRIMSON.b, 0.92 * fade), 4.2, true)
	game.draw_polyline(left_points, Color(COLOR_BLOOD_GLINT.r, COLOR_BLOOD_GLINT.g, COLOR_BLOOD_GLINT.b, 0.86 * fade), 1.6, true)
	game.draw_polyline(right_points, Color(COLOR_BLOOD_GLINT.r, COLOR_BLOOD_GLINT.g, COLOR_BLOOD_GLINT.b, 0.86 * fade), 1.6, true)

	# 4. Stretched sinew / coagulated flesh fibers spanning across the tear
	for i in range(1, segs):
		if i % 3 != 0:
			continue
		var lp: Vector2 = left_points[i]
		var rp: Vector2 = right_points[i]
		var mid: Vector2 = lp.lerp(rp, 0.5) + dir * (sin(float(i) * 2.5) * 8.0)
		var fiber_pts := PackedVector2Array([lp, mid, rp])
		game.draw_polyline(fiber_pts, Color(COLOR_BLOOD_ARTERIAL.r, COLOR_BLOOD_ARTERIAL.g, COLOR_BLOOD_ARTERIAL.b, 0.80 * fade), 2.4, true)
		game.draw_polyline(fiber_pts, Color(COLOR_BLOOD_BRIGHT.r, COLOR_BLOOD_BRIGHT.g, COLOR_BLOOD_BRIGHT.b, 0.70 * fade), 1.1, true)

	# 5. Spattered droplets radiating outward perpendicular to the tear
	for i in range(segs):
		if i % 2 == 0:
			var t: float = float(i) / float(segs)
			var base: Vector2 = a.lerp(b, t)
			var side_sign: float = 1.0 if (i % 4 == 0) else -1.0
			var drop_offset: Vector2 = normal * side_sign * (sin(t * PI) * max_width * 0.92 + (9.0 + fmod(float(i) * 7.9, 20.0)))
			var drop_pos: Vector2 = base + drop_offset
			var d_size: float = 2.2 + fmod(float(i) * 2.3, 3.2)
			game.draw_circle(drop_pos, d_size, Color(COLOR_BLOOD_CRIMSON.r, COLOR_BLOOD_CRIMSON.g, COLOR_BLOOD_CRIMSON.b, 0.72 * fade))

	# 6. Origin Rupture: 3-claw visceral tear where reality opened
	for k in range(-1, 2):
		var claw_dir: Vector2 = (-dir).rotated(float(k) * 0.44)
		var claw_tip: Vector2 = a + claw_dir * (42.0 + absf(float(k)) * 8.0)
		game.draw_line(a, claw_tip, Color(COLOR_BLOOD_CRIMSON.r, COLOR_BLOOD_CRIMSON.g, COLOR_BLOOD_CRIMSON.b, 0.88 * fade), 4.5, true)
		game.draw_line(a, claw_tip * 0.65 + a * 0.35, Color(COLOR_BLOOD_GLINT.r, COLOR_BLOOD_GLINT.g, COLOR_BLOOD_GLINT.b, 0.92 * fade), 1.8, true)
	game.draw_circle(a, 18.0 * fade, Color(COLOR_VOID_ABYSS.r, COLOR_VOID_ABYSS.g, COLOR_VOID_ABYSS.b, 0.92 * fade))
	game.draw_arc(a, 22.0 * fade, 0, TAU, 28, Color(COLOR_BLOOD_BRIGHT.r, COLOR_BLOOD_BRIGHT.g, COLOR_BLOOD_BRIGHT.b, 0.82 * fade), 2.8)

	# 7. Destination Rupture: piercing exit laceration fork and gore splash
	var exit_tip: Vector2 = b + dir * 46.0
	var exit_l: Vector2 = b + (-dir * 16.0 + normal * 26.0)
	var exit_r: Vector2 = b + (-dir * 16.0 - normal * 26.0)
	game.draw_polyline(PackedVector2Array([exit_l, exit_tip, exit_r]), Color(COLOR_BLOOD_CRIMSON.r, COLOR_BLOOD_CRIMSON.g, COLOR_BLOOD_CRIMSON.b, 0.95 * fade), 4.5, true)
	game.draw_polyline(PackedVector2Array([exit_l, exit_tip, exit_r]), Color(COLOR_BLOOD_GLINT.r, COLOR_BLOOD_GLINT.g, COLOR_BLOOD_GLINT.b, 0.95 * fade), 1.8, true)
	game.draw_circle(b, 20.0 * fade, Color(COLOR_VOID_ABYSS.r, COLOR_VOID_ABYSS.g, COLOR_VOID_ABYSS.b, 0.95 * fade))
	game.draw_circle(b, 11.0 * fade, Color(COLOR_BLOOD_BRIGHT.r, COLOR_BLOOD_BRIGHT.g, COLOR_BLOOD_BRIGHT.b, 0.92 * fade))


static func draw_network_teleport_tear(game: Node2D, visual: Dictionary, camera: Vector2, _progress: float, fade: float) -> void:
	var origin: Vector2 = Vector2(visual.get("origin", game.net_player_render_pos))
	var target: Vector2 = Vector2(visual.get("target", game.net_player_render_pos))
	var slash_data := {
		"a": origin,
		"b": target,
		"life": fade,
		"max": 1.0,
		"kind": "lacerante_tp"
	}
	draw_teleport_tear(game, slash_data, camera)
