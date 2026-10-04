@static_unload
extends RefCounted
class_name RTGravitanteVfx

# Presentation only. Positions/damage/radii remain owned by gameplay.
# All shapes share the host CanvasItem; no screen texture, materials or nodes.
const VOID := Color(0.003, 0.006, 0.012)
const ICE := Color(0.87, 0.97, 1.0)
const CYAN := Color(0.20, 0.78, 0.94)
const BLUE := Color(0.19, 0.39, 0.68)
const VIOLET := Color(0.46, 0.33, 0.65)
const DEBRIS_CAP := [3, 5, 8, 14]
const SEGMENTS := [12, 16, 24, 36]
const HOST_ORBITALS := [1, 2, 3, 3]
const Q_PATHS := [2, 3, 5, 8]
static var disk_geometry: Dictionary = {}
static var mass_texture: ImageTexture

static func mass_stamp() -> ImageTexture:
	if mass_texture != null:
		return mass_texture
	# One small reusable analytical sprite; generated once, never per projectile/frame.
	var stamp := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	for y in range(40):
		for x in range(40):
			var offset := Vector2(x - 19.5, y - 19.5)
			var distance := offset.length()
			var color := tint(VOID, 1.0 - smoothstep(12.0, 13.0, distance))
			var ring := (1.0 - smoothstep(0.5, 1.6, absf(distance - 13.2)))
			var hot := 1.0 - smoothstep(-0.8, 0.3, offset.normalized().y)
			if ring > 0.0:
				color = color.lerp(tint(CYAN.lerp(ICE, hot), 1.0), ring * (0.7 + hot * 0.3))
			stamp.set_pixel(x, y, color)
	mass_texture = ImageTexture.create_from_image(stamp)
	return mass_texture

static func disk(game: Node2D, center: Vector2, radius: float, detail: int, front: bool) -> void:
	# Cached unit ribbons: a shaped disk, not stacks of uniform outline rings.
	var layers := 2 if detail < 2 else 3
	for layer in range(layers):
		var key: int = detail * 10 + layer + (100 if front else 0)
		if not disk_geometry.has(key):
			var points := PackedVector2Array()
			var colors := PackedColorArray()
			var steps: int = SEGMENTS[detail]
			var ring: float = 1.66 + layer * 0.21
			for side in [1.0, -1.0]:
				for j in range(steps + 1):
					var i: int = j if side > 0.0 else steps - j
					var angle: float = float(i) / steps * PI + (0.0 if front else PI)
					var thickness: float = (0.07 + 0.07 * absf(sin(angle))) * (1.0 - layer * 0.18)
					points.append(Vector2(cos(angle) * ring, sin(angle) * ring * 0.32 + side * thickness))
					var energy: float = 0.45 + 0.55 * pow(absf(cos(angle - 0.4)), 2.0)
					var col := CYAN.lerp(ICE, energy) if layer == 0 else (BLUE.lerp(CYAN, energy) if layer == 1 else VIOLET.lerp(BLUE, energy))
					colors.append(tint(col, (0.96 - layer * 0.16) * (1.0 if front else 0.5)))
			disk_geometry[key] = [points, colors]
		var geometry: Array = disk_geometry[key]
		game.draw_set_transform(center, -0.22, Vector2.ONE * radius)
		game.draw_polygon(geometry[0], geometry[1])
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func lod(game: Node2D) -> int:
	if game._memory_saver_active():
		return 0
	if game.gfx_low_resource or game._is_mobile_runtime():
		return 1
	return 2 if game._runtime_visual_budget_active() else 3

static func evolved(game: Node2D, suffix: String) -> bool:
	for choice in game.manifest_evolution_state.get("choices", []):
		if String(choice.get("id", "")) == "gravitante_" + suffix:
			return true
	return false

static func tint(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))

static func ellipse(game: Node2D, center: Vector2, radius: float, squash: float, tilt: float,
		start: float, span: float, color: Color, width: float, detail: int) -> void:
	game.draw_set_transform(center, tilt, Vector2(1.0, squash))
	game.draw_arc(Vector2.ZERO, maxf(radius, 0.2), start, start + span, SEGMENTS[detail], color, width)
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func core(game: Node2D, center: Vector2, radius: float, alpha: float, _detail: int) -> void:
	var extent := Vector2.ONE * (radius + 2.0) * 1.48
	game.draw_texture_rect(mass_stamp(), Rect2(center - extent, extent * 2.0), false, tint(Color.WHITE, alpha))

static func curve(game: Node2D, a: Vector2, control: Vector2, b: Vector2, color: Color,
		width: float, detail: int, end: float = 1.0) -> void:
	# Small bounded buffer, independent of enemy count or ability intensity.
	var points := PackedVector2Array()
	var steps: int = 5 + detail * 3
	points.resize(steps + 1)
	for i in range(steps + 1):
		var p: float = float(i) / steps * end
		points[i] = a.lerp(control, p).lerp(control.lerp(b, p), p)
	game.draw_polyline(points, color, width, true)

static func projectile(game: Node2D, pos: Vector2, direction: Vector2, age: float) -> void:
	var detail := lod(game)
	var angle := direction.angle()
	for i in range(1 + mini(2, detail)):
		var offset: Vector2 = pos - direction * (7.0 + i * 9.0)
		ellipse(game, offset, 9.0 + i * 3.0, 0.68, angle, 1.4, 3.1,
			tint(CYAN if i == 0 else BLUE, 0.75 - i * 0.22), 1.5 - i * 0.25, detail)
	core(game, pos, 5.5, 1.0, detail)
	ellipse(game, pos, 10.0, 0.48, angle - 0.5, age * 5.0, 2.6, tint(ICE, 0.62), 1.2, detail)

static func orbit_point(anchor: Vector2, angle: float, radius: float, tilt: float) -> Vector2:
	return anchor + Vector2(cos(angle) * radius, sin(angle) * radius * 0.42).rotated(tilt)

static func orbital_position(orbital: Dictionary, time: float, slot: int = 0) -> Vector2:
	var radius: float = (62.0 if String(orbital.get("target_kind", "enemy")) != "enemy" else 42.0) + slot * 7.0
	return orbit_point(Vector2(orbital.get("origin_pos", Vector2.ZERO)), float(orbital.get("angle", 0.0)),
		radius, -0.32 + slot * 0.48 + sin(time * 0.24) * 0.12)

static func capture(orbital: Dictionary, bullet: Dictionary) -> void:
	orbital["vfx_from"] = Vector2(bullet.get("pos", orbital.get("origin_pos", Vector2.ZERO)))
	orbital["vfx_direction"] = Vector2(bullet.get("dir", Vector2.RIGHT))
	orbital["vfx_start_life"] = float(orbital.get("life", 4.0))

static func transfer(orbital: Dictionary, time: float) -> void:
	orbital["vfx_from"] = orbital_position(orbital, time)
	orbital["vfx_direction"] = Vector2.from_angle(float(orbital.get("angle", 0.0)) + PI * 0.5)
	orbital["vfx_start_life"] = float(orbital.get("life", 0.0))
	orbital["vfx_transfer"] = true

static func orbitals(game: Node2D, camera: Vector2, behind: bool) -> void:
	var detail := lod(game)
	var counts: Dictionary = {}
	var total := 0
	var roche := evolved(game, "ev1_roche")
	var chaotic := evolved(game, "ev2_chaotic_orbit")
	var growth := evolved(game, "ev1_mass_growth")
	var slingshot := evolved(game, "ev1_slingshot")
	var synchronized_tick := 0.0
	if evolved(game, "ev2_rupture_horizon"):
		for secondary in game.manifestation_secondaries:
			if secondary.get("kind", "") == "gravitante":
				var interval := maxf(0.18, 0.36 - float(secondary.get("capture_power", 0.0)) * 0.045)
				synchronized_tick = maxf(synchronized_tick, clampf((float(secondary.get("pulse_tick", 0.0)) - interval + 0.10) / 0.10, 0.0, 1.0))
	for orbital in game.orbitals:
		if float(orbital.get("life", 0.0)) <= 0.0:
			continue
		var anchor: Vector2 = orbital.get("origin_pos", game.player_pos)
		if not game._world_point_in_view(anchor, camera, 90.0):
			continue
		var key: String = String(orbital.get("target_kind", "enemy")) + str(orbital.get("enemy_uid", -1))
		var slot: int = counts.get(key, 0)
		counts[key] = slot + 1
		if slot >= HOST_ORBITALS[detail]:
			continue
		total += 1
		var cheap := total > (24 if detail >= 2 else 10)
		var angle: float = orbital.get("angle", 0.0)
		var tilt: float = -0.32 + slot * 0.48 + sin(game.time_alive * 0.24) * 0.12
		var radius: float = (62.0 if String(orbital.get("target_kind", "enemy")) != "enemy" else 42.0) + slot * 7.0
		var pos := orbital_position(orbital, game.time_alive, slot) - camera
		var entering: bool = orbital.has("vfx_from")
		var entry: float = clampf((float(orbital.get("vfx_start_life", 0.0)) - float(orbital["life"])) / 0.32, 0.0, 1.0)
		if entering and entry < 1.0:
			if behind:
				continue
			var start: Vector2 = Vector2(orbital["vfx_from"]) - camera
			var bend: Vector2 = start + Vector2(orbital["vfx_direction"]) * (60.0 if orbital.get("vfx_transfer", false) else 25.0)
			var eased := entry * entry * (3.0 - 2.0 * entry)
			var end := pos
			pos = start.lerp(bend, eased).lerp(bend.lerp(end, eased), eased)
			if not cheap:
				curve(game, start, bend, end, tint(CYAN, 0.35 * (1.0 - entry)), 1.1, detail, eased)
				if slingshot and orbital.get("vfx_transfer", false):
					ellipse(game, pos, 14.0, 0.4, (end - start).angle(), -1.0, PI, tint(ICE, 0.7), 1.5, detail)
			ellipse(game, anchor - camera, 6.0 + 25.0 * (1.0 - entry), 0.55, tilt, 0.0, TAU, tint(CYAN, (1.0 - entry) * 0.75), 1.2, detail)
		elif (sin(angle) < 0.0) != behind:
			continue
		var alpha := 0.38 if behind else 0.95
		var tick := clampf((float(orbital.get("tick", 0.0)) - 0.50) / 0.12, 0.0, 1.0)
		tick = maxf(tick, synchronized_tick)
		var mass: float = clampf((4.0 - float(orbital["life"])) / 3.0, 0.0, 1.0) if growth else 0.0
		if not cheap:
			ellipse(game, anchor - camera, radius, 0.42, tilt, angle - (0.3 if behind else 0.8), 0.8,
				tint(CYAN, alpha * 0.5), 1.0 + tick, detail)
			if chaotic and slot == 0 and detail >= 1:
				ellipse(game, anchor - camera, radius * 1.12, 0.55, -tilt - 0.5, angle + 1.0, 3.4, tint(VIOLET, alpha * 0.33), 1.0, detail)
			if roche and slot == 0 and not behind:
				for fragment in range(mini(3, detail + 1)):
					var fp := orbit_point(anchor - camera, angle - 0.4 - fragment * 0.26, radius + 10.0, tilt)
					game.draw_line(fp, fp + Vector2(3, -2), tint(ICE, 0.7), 2.0, true)
		core(game, pos, (3.0 if behind else 5.0) + mass * 1.7, alpha, 0 if cheap else detail)
		if tick > 0.0 or mass > 0.4:
			ellipse(game, pos, 8.0 + mass * 2.0 - tick * 2.0, 0.6, tilt, -2.0, 3.8, tint(ICE, alpha * maxf(tick, mass)), 1.2, 0)
	if evolved(game, "ev1_captive_moon") and not game.orbitals.is_empty():
		for moon in range(mini(HOST_ORBITALS[detail], game.orbitals.size())):
			var angle: float = game.time_alive * 2.0 + moon * 2.399
			if (sin(angle) < 0.0) == behind:
				var pos := orbit_point(game.player_pos - camera, angle, 47.0 + moon * 6.0, -0.25)
				core(game, pos, 3.3, 0.4 if behind else 0.95, detail)

static func push_event(game: Node2D, event: Dictionary) -> void:
	# Own bounded cosmetic container: must never gate teleport cooldown completion.
	var count := 0
	var oldest := -1
	for i in range(game.gravitante_vfx_events.size()):
		if String(game.gravitante_vfx_events[i].get("kind", "")).begins_with("gravity_"):
			count += 1
			if oldest < 0 and String(game.gravitante_vfx_events[i]["kind"]) == "gravity_impact":
				oldest = i
	if count >= 24:
		if oldest >= 0:
			game.gravitante_vfx_events.remove_at(oldest)
		elif event.get("kind", "") == "gravity_impact":
			return
		else:
			game.gravitante_vfx_events.pop_front()
	game.gravitante_vfx_events.append(event)

static func update(game: Node2D, delta: float) -> void:
	for i in range(game.gravitante_vfx_events.size() - 1, -1, -1):
		var effect: Dictionary = game.gravitante_vfx_events[i]
		effect["life"] = float(effect["life"]) - delta
		if float(effect["life"]) <= 0.0:
			game.gravitante_vfx_events.remove_at(i)

static func collision(game: Node2D, marked: Array, center: Vector2) -> void:
	var points := PackedVector2Array()
	for i in range(mini(Q_PATHS[lod(game)], marked.size())):
		points.append(Vector2(marked[i]["pos"]))
	push_event(game, {"kind": "gravity_q", "pos": center, "points": points, "life": 0.55, "max": 0.55})

static func event(game: Node2D, effect: Dictionary, camera: Vector2) -> void:
	var detail := lod(game)
	var p: float = clampf(1.0 - float(effect.get("life", 0.0)) / maxf(0.01, float(effect.get("max", 1.0))), 0.0, 1.0)
	var center: Vector2 = Vector2(effect.get("pos", game.player_pos)) - camera
	if not game._screen_point_in_view(center, 230.0):
		return
	var kind: String = effect.get("kind", "")
	if kind == "gravity_q":
		if p < 0.55:
			for point in effect.get("points", PackedVector2Array()):
				var a: Vector2 = point - camera
				curve(game, a, (a + center) * 0.5 + (center - a).orthogonal() * 0.25,
					center, tint(CYAN, (1.0 - p) * 0.8), 1.5, detail)
		var compress: float = 1.0 - clampf(p / 0.58, 0.0, 1.0)
		core(game, center, 2.0 + compress * 15.0, 1.0 - p, detail)
		ellipse(game, center, 3.0 + compress * 70.0, 0.58, -0.25, 0.0, TAU, tint(ICE, 1.0 - p), 1.6, detail)
		if p > 0.48:
			game.draw_arc(center, 3.0 + 202.0 * (p - 0.48) / 0.52, 0.0, TAU, SEGMENTS[detail] * 2, tint(CYAN, (1.0 - p) * 1.6), 2.0, true)
		if evolved(game, "ev2_shared_singularity"):
			singularity(game, center, 30.0 * sin(p * PI), p * 5.0, 0.65, 0, true)
	else:
		# Hit compression or residual collapse. No explosion/particle burst.
		var radius: float = (28.0 if kind == "gravity_impact" else 68.0) * (1.0 - p)
		ellipse(game, center, radius + 2.0, 0.55, -0.3, 0.0, TAU, tint(CYAN, 1.0 - p), 1.4, detail)
		core(game, center, 2.0 + radius * 0.15, 1.0 - p, detail)

static func teleport(game: Node2D, effect: Dictionary, camera: Vector2) -> void:
	var detail := lod(game)
	var p: float = clampf(1.0 - float(effect.get("life", 0.0)) / 0.68, 0.0, 1.0)
	var a: Vector2 = Vector2(effect.get("a", game.player_pos)) - camera
	var b: Vector2 = Vector2(effect.get("b", game.player_pos)) - camera
	for index in range(2):
		var center := a if index == 0 else b
		if not game._screen_point_in_view(center, 100.0):
			continue
		var opening := (1.0 - p) if index == 0 else p
		var fade := 1.0 - p
		core(game, center, 3.0 + 10.0 * sin(p * PI), fade, detail)
		ellipse(game, center, 6.0 + opening * 38.0, 0.28 + opening * 0.55, -0.2, 0.0, TAU, tint(ICE, fade), 1.7, detail)
		game.draw_line(center - Vector2(0, 38.0 * opening), center + Vector2(0, 38.0 * opening), tint(CYAN, fade), 1.2 + opening * 4.0, true)
		# Texture echo communicates compression without slowing actual teleport/input.
		var tex: Texture2D = game._player_texture()
		if tex != null and detail > 0:
			game._draw_entity_fit(tex, center, Vector2(2.0 + opening * 42.0, 65.0), tint(ICE, fade * 0.35))
	if evolved(game, "ev1_tidal_step") or evolved(game, "ev2_tidal_event"):
		var side := (b - a).orthogonal().normalized() * 46.0
		for sign_value in [-1.0, 1.0]:
			curve(game, a, (a + b) * 0.5 + side * sign_value, b, tint(CYAN, (1.0 - p) * 0.55), 1.3, detail)

static func singularity(game: Node2D, center: Vector2, radius: float, spin: float,
		intensity: float, detail: int, miniature: bool = false) -> void:
	if radius < 0.3:
		return
	var tilt := -0.22
	var layers := 1 if miniature else 2 + int(detail >= 2)
	# Back disk -> black horizon -> lensed crown -> front disk.
	if miniature:
		ellipse(game, center, radius * 1.75, 0.32, tilt, PI, PI, tint(CYAN, 0.48), 3.5, 0)
	else:
		disk(game, center, radius, detail, false)
	game.draw_circle(center, radius * 1.06, VOID)
	game.draw_arc(center, radius * 1.07, 0.0, TAU, SEGMENTS[detail] * 2, tint(CYAN, 0.42), 1.4, true)
	game.draw_arc(center, radius * 1.10, -PI + 0.12, -0.15, SEGMENTS[detail], tint(ICE, 0.91), 1.6 + intensity * 0.4, true)
	if detail >= 2 and not miniature:
		game.draw_arc(center + Vector2(0, -radius * 0.06), radius * 1.23, -2.75, -0.3, SEGMENTS[detail], tint(BLUE, 0.34), 3.0, true)
	if not miniature:
		disk(game, center, radius, detail, true)
	for layer in range(layers):
		var r: float = radius * (1.75 + layer * 0.22)
		var color := ICE if layer == 0 else (CYAN if layer == 1 else VIOLET)
		ellipse(game, center, r, 0.32, tilt, 0.0, PI, tint(color, 0.94 - layer * 0.20), 3.4 - layer * 0.7 + intensity * 0.25, detail)
		if detail > 0:
			var start: float = fposmod(spin * (0.7 + layer * 0.17) + layer * 1.8, PI * 0.72)
			ellipse(game, center, r + 2.0, 0.32, tilt, start, 0.58, tint(ICE, 0.88), 1.4, detail)
	var debris: int = mini(3, DEBRIS_CAP[detail]) if miniature else DEBRIS_CAP[detail]
	for i in range(debris):
		var phase: float = fposmod(spin * 0.16 + i * 0.618, 1.0)
		var angle: float = i * 2.399 + phase * TAU * 1.15
		var r: float = lerpf(radius * 3.0, radius * 1.14, phase)
		var pos := center + Vector2.from_angle(angle) * r
		var tail := center + Vector2.from_angle(angle - 0.06) * (r + 4.0)
		game.draw_line(tail, pos, tint(CYAN, sin(phase * PI) * 0.65), 1.0 + float(i % 2), true)

static func ultimate(game: Node2D, secondary: Dictionary, camera: Vector2) -> void:
	var center: Vector2 = Vector2(secondary.get("center", game.player_pos)) - camera
	var life: float = secondary.get("life", 0.0)
	var duration: float = maxf(0.01, secondary.get("max", 8.0))
	var age := duration - life
	var progress := age / duration
	var radius: float = game._gravitante_radius(progress)
	if life <= 0.0 or not game._screen_point_in_view(center, radius * 1.1):
		return
	var detail := lod(game)
	var captured: int = int(secondary.get("captured", 0)) + int(secondary.get("orbital_bonus", 0))
	var tier := 3 if captured >= 10 else (2 if captured >= 6 else (1 if captured >= 3 else 0))
	var intensity: float = 0.4 + tier * 0.22 + minf(1.0, float(secondary.get("capture_power", 0.0))) * 0.15
	var spin: float = game.time_alive * (0.85 + float(secondary.get("spin_speed", 250.0)) * 0.004)
	var birth := smoothstep(0.12, 0.9, age)
	var collapse := smoothstep(0.08, 0.62, life)
	var core_radius: float = (48.0 + tier * 4.0) * birth * collapse
	# Exact gameplay boundary, always present even on minimum quality.
	game.draw_arc(center, radius, 0.0, TAU, SEGMENTS[detail] * 2, tint(CYAN, 0.33), 1.0, true)
	for i in range(4):
		var direction := Vector2.from_angle(i * PI * 0.5)
		game.draw_line(center + direction * (radius - 5.0), center + direction * (radius + 5.0), tint(ICE, 0.6), 1.5, true)
	if age < 0.22:
		ellipse(game, center, 45.0 * (1.0 - age / 0.25), 0.46, -0.22, 0.0, TAU, tint(CYAN, 0.55), 1.0, detail)
	var horizon := evolved(game, "ev2_rupture_horizon")
	var ghosts := 0
	if detail > 0:
		for enemy in game.enemies:
			if float(enemy.get("hp", 0.0)) > 0.0 and Vector2(enemy["pos"]).distance_to(center + camera) < radius:
				game._draw_gravitante_enemy_distortion(enemy, center + camera, camera, radius, progress, intensity)
				ghosts += 1
				if ghosts >= 3 + detail * 3:
					break
	if horizon:
		intensity += tier * 0.15
		spin *= 1.0 + tier * 0.12
	singularity(game, center, core_radius, spin * (1.0 + (1.0 - collapse) * 2.0), intensity, detail)
	if evolved(game, "ev2_tidal_event"):
		var inward: float = fposmod(age * 1.2, 1.0)
		game.draw_arc(center, lerpf(radius, maxf(2.0, core_radius * 1.1), inward), 0.0, TAU, SEGMENTS[detail], tint(CYAN, sin(inward * PI) * 0.55), 1.5, true)
	if life < 0.12:
		game.draw_arc(center, 4.0 + (1.0 - life / 0.12) * radius, 0.0, TAU, SEGMENTS[detail] * 2, tint(ICE, life / 0.12), 1.6, true)
	if game.boss_active and game.boss_hp > 0.0 and game.boss_pos.distance_to(center + camera) <= radius + 100.0:
		var boss: Vector2 = game.boss_pos - camera
		var direction := (boss - center).angle()
		for i in range(1 + int(detail > 1)):
			game.draw_arc(boss, 48.0 + i * 10.0, direction - 0.65, direction + 0.65, SEGMENTS[detail], tint(ICE, 0.35 - i * 0.1), 2.5 - i * 0.5, true)

static func systems(game: Node2D, camera: Vector2) -> void:
	var binary := evolved(game, "ev1_binary")
	var planetary := evolved(game, "ev2_planetary_system")
	if not binary and not planetary:
		return
	var detail := lod(game)
	var anchors: Array[Vector2] = []
	for orbital in game.orbitals:
		if float(orbital.get("life", 0.0)) <= 0.0:
			continue
		var pos: Vector2 = orbital.get("origin_pos", game.player_pos)
		if not anchors.has(pos) and game._world_point_in_view(pos, camera, 90.0):
			anchors.append(pos)
		if anchors.size() >= (3 if planetary else 2):
			break
	# Bounded to 2/3 anchors; never compare every enemy pair.
	if anchors.size() < 2:
		return
	var center := Vector2.ZERO
	for anchor in anchors:
		center += anchor - camera
	center /= anchors.size()
	core(game, center, 4.0 if binary else 7.0, 0.8, detail)
	for anchor in anchors:
		var a := anchor - camera
		curve(game, a, (a + center) * 0.5 + (a - center).orthogonal() * 0.22, center, tint(BLUE, 0.42), 1.1, detail)

static func field(game: Node2D, field_state: Dictionary, camera: Vector2) -> void:
	var center: Vector2 = Vector2(field_state.get("pos", game.player_pos)) - camera
	var radius: float = field_state.get("radius", 160.0)
	if not game._screen_point_in_view(center, radius):
		return
	var alpha: float = clampf(float(field_state.get("life", 0.0)) / maxf(0.01, field_state.get("max", 1.0)), 0.0, 1.0)
	ellipse(game, center, radius, 0.65, -0.22, 0.0, TAU, tint(BLUE, 0.42 * alpha), 1.2, lod(game))
	singularity(game, center, 14.0 * alpha, game.time_alive, 0.4, 0, true)
