class_name VFXDirector
extends RefCounted


const ELEMENT_COLORS: = {
	"eletrica": Color(0.28, 0.95, 1.0, 1.0), 
	"temporal": Color(0.3, 1.0, 0.48, 1.0), 
	"incandescente": Color(1.0, 0.48, 0.12, 1.0), 
	"necromante": Color(0.78, 0.28, 0.98, 1.0), 
	"prismatica": Color(0.92, 0.42, 1.0, 1.0), 
	"void": Color(0.2, 0.9, 0.45, 1.0), 
	"umbra": Color(0.18, 0.88, 0.42, 1.0), 
	"physical": Color(1.0, 0.84, 0.25, 1.0)
}


var hit_flashes: Dictionary = {}
var squash_stretch: Dictionary = {}
var impact_sparks: Array = []
var impact_rings: Array = []
var floor_cracks: Array = []
var card_burns: Array = []
var cooldown_pulses: Dictionary = {}
var ambient_motes: Array = []
var sky_lightning_bolts: Array = []
var ground_scorches: Array = []


var particles_enabled: bool = true

func _init(enable_particles: = true) -> void :
	particles_enabled = enable_particles
	_init_ambient_motes()

func set_particles_enabled(enabled: bool) -> void :
	particles_enabled = enabled

func _init_ambient_motes() -> void :
	ambient_motes.clear()
	if not particles_enabled:
		return
	for i in range(28):
		ambient_motes.append({
			"pos": Vector2(randf_range(-600, 1800), randf_range(-400, 1200)), 
			"vel": Vector2(randf_range(-8.0, 8.0), randf_range(-14.0, -4.0)), 
			"size": randf_range(1.5, 3.0), 
			"alpha": randf_range(0.15, 0.45), 
			"phase": randf_range(0.0, TAU)
		})





func request_hit_feedback(data: Dictionary) -> void :
	var pos: Vector2 = data.get("world_position", Vector2.ZERO)
	var dir: Vector2 = data.get("direction", Vector2.RIGHT).normalized()
	var strength: float = float(data.get("strength", 1.0))
	var element: String = String(data.get("element", "physical"))
	var is_crit: bool = bool(data.get("is_critical", false))
	var target_id: String = String(data.get("target_id", ""))

	var base_col: Color = ELEMENT_COLORS.get(element, ELEMENT_COLORS["physical"])
	var flash_col: = Color.WHITE if is_crit else base_col


	if target_id != "":
		hit_flashes[target_id] = {
			"timer": 0.04 if not is_crit else 0.07, 
			"max": 0.04 if not is_crit else 0.07, 
			"color": flash_col
		}


	if target_id != "":
		var squish_vec: = Vector2(1.22, 0.78) if is_crit else Vector2(1.12, 0.88)
		request_squash_stretch(target_id, squish_vec, 14.0)

	if not particles_enabled:
		return


	var spark_count: = 8 if not is_crit else 16
	var spread_angle: = PI * 0.45
	for i in range(spark_count):
		var ang: = dir.angle() + randf_range( - spread_angle, spread_angle)
		var spd: = randf_range(120.0, 340.0) * (1.4 if is_crit else 1.0)
		impact_sparks.append({
			"pos": pos, 
			"vel": Vector2.RIGHT.rotated(ang) * spd, 
			"life": randf_range(0.12, 0.28), 
			"max": 0.28, 
			"color": base_col if randf() > 0.3 else Color.WHITE, 
			"size": randf_range(2.0, 4.0) if not is_crit else randf_range(3.0, 5.0)
		})


	impact_rings.append({
		"pos": pos, 
		"radius": 4.0, 
		"max_radius": 24.0 + strength * 12.0, 
		"life": 0.16, 
		"max": 0.16, 
		"color": base_col, 
		"width": 3.0 if is_crit else 2.0
	})


	if strength > 1.2 or is_crit:
		for mote in ambient_motes:
			var d_vec: Vector2 = Vector2(mote["pos"]) - pos
			if d_vec.length_squared() < 220.0 * 220.0 and d_vec.length_squared() > 1.0:
				mote["vel"] = Vector2(mote["vel"]) + d_vec.normalized() * (120.0 * strength)

func request_squash_stretch(target_id: String, scale_vec: Vector2, recovery_spd: = 12.0) -> void :
	squash_stretch[target_id] = {
		"scale": scale_vec, 
		"recovery": recovery_spd
	}

func request_sky_lightning_strike(pos: Vector2, element: = "eletrica") -> void :
	if not particles_enabled:
		return
	var base_col: Color = ELEMENT_COLORS.get(element, ELEMENT_COLORS["eletrica"])
	var sky_start: = pos + Vector2(randf_range(-40.0, 40.0), -680.0)
	var segments: = 12
	var points: PackedVector2Array = []
	points.append(sky_start)
	var current: = sky_start
	for i in range(1, segments):
		var t: = float(i) / float(segments)
		var target: = sky_start.lerp(pos, t)
		var jitter: = Vector2(randf_range(-26.0, 26.0), randf_range(-8.0, 8.0))
		current = target + jitter
		points.append(current)
	points.append(pos)

	var branches: Array = []
	for b in range(3):
		var idx: = randi_range(3, segments - 3)
		var branch_start: Vector2 = points[idx]
		var branch_dir: = Vector2(randf_range(-1.0, 1.0), randf_range(0.4, 1.0)).normalized()
		branches.append({
			"start": branch_start, 
			"end": branch_start + branch_dir * randf_range(40.0, 85.0)
		})

	sky_lightning_bolts.append({
		"points": points, 
		"branches": branches, 
		"impact": pos, 
		"life": 0.26, 
		"max": 0.26, 
		"color": base_col
	})

	impact_rings.append({
		"pos": pos, 
		"radius": 8.0, 
		"max_radius": 56.0, 
		"life": 0.22, 
		"max": 0.22, 
		"color": base_col, 
		"width": 3.5
	})

	request_ground_scorch(pos, 4.0, element)

func request_ground_scorch(pos: Vector2, duration: = 4.0, element: = "eletrica") -> void :
	if not particles_enabled:
		return
	var base_col: Color = ELEMENT_COLORS.get(element, ELEMENT_COLORS["eletrica"])
	var lines: Array = []
	var line_count: = 8
	for i in range(line_count):
		var ang: = (float(i) / float(line_count)) * TAU + randf_range(-0.2, 0.2)
		var len: = randf_range(16.0, 36.0)
		lines.append({
			"start": pos, 
			"end": pos + Vector2.RIGHT.rotated(ang) * len, 
			"width": randf_range(1.5, 3.0)
		})

	ground_scorches.append({
		"pos": pos, 
		"lines": lines, 
		"life": duration, 
		"max": duration, 
		"color": base_col, 
		"radius": randf_range(28.0, 42.0)
	})

func request_floor_crack(pos: Vector2, radius: = 32.0, element: = "physical", duration: = 3.5) -> void :
	if not particles_enabled:
		return
	var base_col: Color = ELEMENT_COLORS.get(element, ELEMENT_COLORS["physical"])
	var points: Array = []
	var branches: = 5
	for b in range(branches):
		var curr: = pos
		var angle: = (float(b) / float(branches)) * TAU + randf_range(-0.3, 0.3)
		var steps: = randi_range(3, 5)
		var branch_pts: Array = [curr]
		for s in range(steps):
			angle += randf_range(-0.4, 0.4)
			var dist: = (radius / float(steps)) * randf_range(0.8, 1.2)
			curr += Vector2.RIGHT.rotated(angle) * dist
			branch_pts.append(curr)
		points.append(branch_pts)

	floor_cracks.append({
		"pos": pos, 
		"branches": points, 
		"life": duration, 
		"max": duration, 
		"color": base_col, 
		"radius": radius
	})

func request_card_burn(rect: Rect2, element: = "temporal") -> void :
	if not particles_enabled:
		return
	var base_col: Color = ELEMENT_COLORS.get(element, ELEMENT_COLORS["temporal"])
	for i in range(24):
		card_burns.append({
			"pos": Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.position.y, rect.end.y)), 
			"vel": Vector2(randf_range(-15.0, 15.0), randf_range(-60.0, -20.0)), 
			"life": randf_range(0.25, 0.5), 
			"max": 0.5, 
			"color": base_col if randf() > 0.35 else Color(1.0, 0.9, 0.4), 
			"size": randf_range(2.0, 4.0)
		})

func request_cooldown_ready(slot_name: String, color: = Color(0.35, 1.0, 0.5)) -> void :
	cooldown_pulses[slot_name] = {
		"timer": 0.3, 
		"max": 0.3, 
		"color": color
	}





func get_flash_color(target_id: String) -> Color:
	if hit_flashes.has(target_id):
		var f: Dictionary = hit_flashes[target_id]
		if float(f.get("timer", 0.0)) > 0.0:
			return f.get("color", Color.WHITE)
	return Color.TRANSPARENT

func get_squash_scale(target_id: String) -> Vector2:
	if squash_stretch.has(target_id):
		var s: Dictionary = squash_stretch[target_id]
		return Vector2(s.get("scale", Vector2.ONE))
	return Vector2.ONE





func update(delta: float) -> void :

	for k in hit_flashes.keys():
		var f: Dictionary = hit_flashes[k]
		f["timer"] = float(f["timer"]) - delta
		if float(f["timer"]) <= 0.0:
			hit_flashes.erase(k)


	for k in squash_stretch.keys():
		var s: Dictionary = squash_stretch[k]
		var curr_scale: Vector2 = s.get("scale", Vector2.ONE)
		var recovery: float = float(s.get("recovery", 12.0))
		curr_scale = curr_scale.move_toward(Vector2.ONE, recovery * delta)
		s["scale"] = curr_scale
		if curr_scale.distance_squared_to(Vector2.ONE) < 0.0001:
			squash_stretch.erase(k)

	if not particles_enabled:
		impact_sparks.clear()
		impact_rings.clear()
		floor_cracks.clear()
		card_burns.clear()
		sky_lightning_bolts.clear()
		ground_scorches.clear()
		return


	for spark in impact_sparks:
		spark["life"] = float(spark["life"]) - delta
		spark["pos"] = Vector2(spark["pos"]) + Vector2(spark["vel"]) * delta
		spark["vel"] = Vector2(spark["vel"]) * maxf(0.0, 1.0 - 5.0 * delta)
	impact_sparks = impact_sparks.filter( func(s): return float(s["life"]) > 0.0)


	for ring in impact_rings:
		ring["life"] = float(ring["life"]) - delta
		var progress: = 1.0 - clampf(float(ring["life"]) / float(ring["max"]), 0.0, 1.0)
		ring["radius"] = lerpf(4.0, float(ring["max_radius"]), progress)
	impact_rings = impact_rings.filter( func(r): return float(r["life"]) > 0.0)


	for crack in floor_cracks:
		crack["life"] = float(crack["life"]) - delta
	floor_cracks = floor_cracks.filter( func(c): return float(c["life"]) > 0.0)


	for bolt in sky_lightning_bolts:
		bolt["life"] = float(bolt["life"]) - delta
	sky_lightning_bolts = sky_lightning_bolts.filter( func(b): return float(b["life"]) > 0.0)


	for scorch in ground_scorches:
		scorch["life"] = float(scorch["life"]) - delta
	ground_scorches = ground_scorches.filter( func(s): return float(s["life"]) > 0.0)


	for burn in card_burns:
		burn["life"] = float(burn["life"]) - delta
		burn["pos"] = Vector2(burn["pos"]) + Vector2(burn["vel"]) * delta
	card_burns = card_burns.filter( func(b): return float(b["life"]) > 0.0)


	for slot in cooldown_pulses.keys():
		var p: Dictionary = cooldown_pulses[slot]
		p["timer"] = float(p["timer"]) - delta
		if float(p["timer"]) <= 0.0:
			cooldown_pulses.erase(slot)


	for mote in ambient_motes:
		mote["pos"] = Vector2(mote["pos"]) + Vector2(mote["vel"]) * delta
		mote["phase"] = float(mote["phase"]) + delta * 2.0

		var target_vel: = Vector2(sin(float(mote["phase"])) * 6.0, -8.0)
		mote["vel"] = Vector2(mote["vel"]).move_toward(target_vel, 40.0 * delta)

		var p: Vector2 = mote["pos"]
		if p.x < -600.0: p.x = 1800.0
		if p.x > 1800.0: p.x = -600.0
		if p.y < -400.0: p.y = 1200.0
		if p.y > 1200.0: p.y = -400.0
		mote["pos"] = p

func draw_floor_effects(ci: CanvasItem, camera: Vector2) -> void :
	if not particles_enabled:
		return


	for scorch in ground_scorches:
		var life: = float(scorch["life"])
		var max_l: = float(scorch["max"])
		var ratio: = clampf(life / max_l, 0.0, 1.0)
		var base_col: Color = scorch["color"]
		var pos: Vector2 = Vector2(scorch["pos"]) - camera
		var radius: float = float(scorch["radius"])


		var scorch_col: = base_col.lerp(Color(0.08, 0.09, 0.12), 1.0 - ratio)
		scorch_col.a = ratio * 0.82


		ci.draw_circle(pos, radius * (0.35 + ratio * 0.15), Color(0.04, 0.05, 0.07, ratio * 0.75))
		if ratio > 0.6:

			var ember_alpha: = (ratio - 0.6) / 0.4
			ci.draw_circle(pos, radius * 0.22, Color(base_col.r, base_col.g, base_col.b, ember_alpha * 0.65))

		var lines: Array = scorch["lines"]
		for l in lines:
			var p1: Vector2 = Vector2(l["start"]) - camera
			var p2: Vector2 = Vector2(l["end"]) - camera
			ci.draw_line(p1, p2, scorch_col, float(l["width"]) * ratio, true)


	for crack in floor_cracks:
		var life: = float(crack["life"])
		var max_l: = float(crack["max"])
		var ratio: = clampf(life / max_l, 0.0, 1.0)
		var base_col: Color = crack["color"]


		var draw_col: = base_col.lerp(Color(0.12, 0.14, 0.18, 0.8), 1.0 - ratio)
		draw_col.a = ratio * 0.85
		var width: = maxf(1.0, 3.0 * ratio)

		var branches: Array = crack["branches"]
		for branch_pts in branches:
			for i in range(branch_pts.size() - 1):
				var p1: Vector2 = Vector2(branch_pts[i]) - camera
				var p2: Vector2 = Vector2(branch_pts[i + 1]) - camera
				ci.draw_line(p1, p2, draw_col, width, true)

func draw_world_vfx(ci: CanvasItem, camera: Vector2) -> void :
	if not particles_enabled:
		return


	for bolt in sky_lightning_bolts:
		var life: = float(bolt["life"])
		var max_l: = float(bolt["max"])
		var alpha: = clampf(life / max_l, 0.0, 1.0)
		var col: Color = bolt["color"]
		var pts: Array = bolt["points"]
		var screen_pts: = PackedVector2Array()
		for p in pts:
			screen_pts.append(Vector2(p) - camera)


		ci.draw_polyline(screen_pts, Color(col.r, col.g, col.b, alpha * 0.5), 12.0, true)

		ci.draw_polyline(screen_pts, Color(0.55, 0.96, 1.0, alpha * 0.85), 6.0, true)

		ci.draw_polyline(screen_pts, Color(1.0, 1.0, 1.0, alpha * 0.95), 2.5, true)

		var branches: Array = bolt["branches"]
		for br in branches:
			var b_start: Vector2 = Vector2(br["start"]) - camera
			var b_end: Vector2 = Vector2(br["end"]) - camera
			ci.draw_line(b_start, b_end, Color(col.r, col.g, col.b, alpha * 0.7), 2.5, true)
			ci.draw_line(b_start, b_end, Color(1.0, 1.0, 1.0, alpha * 0.85), 1.0, true)


	for mote in ambient_motes:
		var pos: Vector2 = Vector2(mote["pos"]) - camera
		var sz: float = float(mote["size"])
		var alpha: float = float(mote["alpha"])
		ci.draw_rect(Rect2(pos, Vector2(sz, sz)), Color(0.4, 1.0, 0.65, alpha), true)


	for ring in impact_rings:
		var pos: Vector2 = Vector2(ring["pos"]) - camera
		var rad: float = float(ring["radius"])
		var life: = float(ring["life"])
		var max_l: = float(ring["max"])
		var alpha: = clampf(life / max_l, 0.0, 1.0)
		var col: Color = ring["color"]
		col.a = alpha * 0.9
		ci.draw_arc(pos, rad, 0.0, TAU, 32, col, float(ring["width"]), true)


	for spark in impact_sparks:
		var pos: Vector2 = Vector2(spark["pos"]) - camera
		var sz: float = float(spark["size"])
		var life: = float(spark["life"])
		var max_l: = float(spark["max"])
		var alpha: = clampf(life / max_l, 0.0, 1.0)
		var col: Color = spark["color"]
		col.a = alpha
		ci.draw_rect(Rect2(pos - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), col, true)

func draw_ui_vfx(ci: CanvasItem) -> void :
	if not particles_enabled:
		return


	for burn in card_burns:
		var pos: Vector2 = Vector2(burn["pos"])
		var sz: float = float(burn["size"])
		var life: = float(burn["life"])
		var max_l: = float(burn["max"])
		var alpha: = clampf(life / max_l, 0.0, 1.0)
		var col: Color = burn["color"]
		col.a = alpha
		ci.draw_rect(Rect2(pos, Vector2(sz, sz)), col, true)
