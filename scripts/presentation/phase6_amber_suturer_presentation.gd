class_name RTPhase6AmberSuturerPresentation
extends RefCounted

const COLUMNS := 4
const ROWS := 6
const ROW_IDLE := 0
const ROW_MOVE := 1
const ROW_PREPARE := 2
const ROW_STITCH := 3
const ROW_DAMAGE := 4
const ROW_DEATH := 5

# Color Palette: Organic Amber, Calcified Bone, and Toxic Chaga Bio-luminescence
const COLOR_AMBER_DEEP := Color(0.18, 0.09, 0.025, 0.95)
const COLOR_AMBER_DARK := Color(0.38, 0.18, 0.04, 0.90)
const COLOR_AMBER_WARM := Color(0.96, 0.52, 0.12, 0.94)
const COLOR_AMBER_BRIGHT := Color(1.0, 0.72, 0.22, 0.96)
const COLOR_AMBER_GOLD := Color(1.0, 0.88, 0.42, 0.98)
const COLOR_AMBER_CORE := Color(1.0, 0.96, 0.75, 1.0)
const COLOR_BIO_ACID := Color(0.68, 0.94, 0.22, 0.86)
const COLOR_BIO_PALE := Color(0.82, 0.98, 0.45, 0.90)
const COLOR_BONE_BASE := Color(0.84, 0.80, 0.70, 0.95)
const COLOR_BONE_DARK := Color(0.32, 0.28, 0.22, 0.95)
const COLOR_FISSURE_VOID := Color(0.06, 0.035, 0.015, 0.92)

static var _frames: Array = []
static var _source_id := 0


static func enemy_texture(game: Node2D, enemy: Dictionary) -> Texture2D:
	var source: Texture2D = game.textures.get("enemy_phase_6_suturador_ambar")
	if source == null:
		return null
	_ensure_frames(source)
	if _frames.is_empty():
		return source
	var state := String(enemy.get("suturer_state", game.amber_suturer_state.get("state", "entry")))
	var anim_time := float(enemy.get("suturer_anim_time", game.amber_suturer_state.get("anim_time", game.time_alive)))
	var row := ROW_IDLE
	var fps := 4.5
	if float(game.time_alive) - float(enemy.get("last_damage_time", -100.0)) < 0.20:
		row = ROW_DAMAGE
		fps = 10.0
	else:
		match state:
			"observe", "reposition":
				row = ROW_MOVE
				fps = 7.0
			"telegraph", "needle_telegraph", "hook_telegraph":
				row = ROW_PREPARE
				fps = 6.5
			"active", "needle_recovery", "hook_recovery":
				row = ROW_STITCH
				fps = 9.0
			"dying":
				row = ROW_DEATH
				fps = 5.0
	var column := int(anim_time * fps) % COLUMNS
	return _frames[row * COLUMNS + column]


static func draw_world(game: Node2D, camera: Vector2) -> void:
	_draw_suturer_presence(game, camera)
	_draw_sutures(game, camera)
	_draw_needle_projectiles(game, camera)
	_draw_visual_events(game, camera)


static func _draw_needle_projectiles(game: Node2D, camera: Vector2) -> void:
	for bullet_value in game.enemy_bullets:
		var bullet: Dictionary = bullet_value
		var bullet_type := String(bullet.get("type", ""))
		if bullet_type not in ["suturer_needle", "suturer_hook"]:
			continue
		var world_pos := Vector2(bullet.get("pos", Vector2.ZERO))
		if not game._world_point_in_view(world_pos, camera, 90.0):
			continue
		var pos := world_pos - camera
		var direction := Vector2(bullet.get("dir", Vector2.LEFT)).normalized()
		var side := direction.orthogonal()
		var phase := float(bullet.get("phase", 0.0))
		if bullet_type == "suturer_hook":
			var tail := pos - direction * 62.0
			game.draw_line(tail, pos - direction * 8.0, Color(COLOR_BIO_ACID.r, COLOR_BIO_ACID.g, COLOR_BIO_ACID.b, 0.42), 7.0, true)
			game.draw_line(tail, pos - direction * 8.0, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.88), 2.2, true)
			var barb := PackedVector2Array([
				pos + direction * 20.0,
				pos - direction * 8.0 + side * 12.0,
				pos - direction * 3.0,
				pos - direction * 8.0 - side * 12.0,
			])
			game.draw_colored_polygon(barb, Color(COLOR_BONE_BASE.r, COLOR_BONE_BASE.g, COLOR_BONE_BASE.b, 0.98))
			game.draw_polyline(PackedVector2Array([barb[0], barb[1], barb[2], barb[3], barb[0]]), COLOR_AMBER_DEEP, 2.0, true)
			game.draw_circle(pos - direction * 5.0, 4.0 + sin(phase) * 1.0, COLOR_AMBER_BRIGHT)
			continue
		var body := PackedVector2Array([
			pos + direction * 18.0,
			pos - direction * 13.0 + side * 4.0,
			pos - direction * 9.0,
			pos - direction * 13.0 - side * 4.0,
		])
		game.draw_line(pos - direction * 34.0, pos - direction * 7.0, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.28), 5.0, true)
		game.draw_colored_polygon(body, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.98))
		game.draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[0]]), COLOR_AMBER_DEEP, 1.6, true)
		game.draw_circle(pos - direction * 7.0, 2.5 + sin(phase) * 0.8, Color(COLOR_BIO_ACID.r, COLOR_BIO_ACID.g, COLOR_BIO_ACID.b, 0.88))


# ==============================================================================
# SUTURADOR ENTITY PRESENCE (Aura, Weaving Filaments & Bio-Resonance)
# ==============================================================================
static func _draw_suturer_presence(game: Node2D, camera: Vector2) -> void:
	var suturer: Dictionary = {}
	for candidate in game.enemies:
		if String(candidate.get("type", "")) == game.ENEMY_AMBER_SUTURER:
			suturer = candidate
			break
	if suturer.is_empty():
		return
	var world_pos := Vector2(suturer.get("pos", Vector2.ZERO))
	if not game._world_point_in_view(world_pos, camera, 200.0):
		return
	var pos := world_pos - camera
	var state := String(suturer.get("suturer_state", "observe"))
	var anim_time := float(suturer.get("suturer_anim_time", game.time_alive))
	var reduced_fx: bool = bool(game.gfx_low_resource or game.gfx_memory_saver)
	var breath := 0.5 + 0.5 * sin(anim_time * 3.6)

	# 1. Ground amber aura beneath the Suturador
	var base_radius := 44.0 + breath * 6.0
	game.draw_circle(pos + Vector2(0.0, 14.0), base_radius, Color(0.24, 0.12, 0.03, 0.32 + breath * 0.12))
	game.draw_circle(pos + Vector2(0.0, 14.0), base_radius * 0.62, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.20 + breath * 0.10))
	if not reduced_fx:
		var rune_points := PackedVector2Array()
		for i in range(8):
			var a := float(i) * TAU / 8.0 + anim_time * 0.65
			var r := base_radius * (0.82 if i % 2 == 0 else 0.98)
			rune_points.append(pos + Vector2(0.0, 14.0) + Vector2.from_angle(a) * r)
		rune_points.append(rune_points[0])
		game.draw_polyline(rune_points, Color(COLOR_AMBER_BRIGHT.r, COLOR_AMBER_BRIGHT.g, COLOR_AMBER_BRIGHT.b, 0.28 + breath * 0.20), 1.6, true)

	# Compact, world-space slow meter. Four notches mirror the four crystals
	# without creating combat popups or adding HUD clutter.
	var slow_stacks := clampi(int(suturer.get("suturer_crystal_slow_stacks", game.amber_suturer_state.get("crystal_slow_stacks", 0))), 0, 4)
	var slow_timer := float(suturer.get("suturer_crystal_slow_timer", game.amber_suturer_state.get("crystal_slow_timer", 0.0)))
	if slow_stacks > 0 and slow_timer > 0.0:
		var meter_pos := pos + Vector2(-27.0, -72.0)
		var timer_ratio := clampf(slow_timer / maxf(0.01, game.amber_suturer_controller.CRYSTAL_SLOW_DURATION), 0.0, 1.0)
		game.draw_rect(Rect2(meter_pos - Vector2(3.0, 3.0), Vector2(60.0, 11.0)), Color(0.06, 0.035, 0.015, 0.78), true)
		for index in range(4):
			var notch := Rect2(meter_pos + Vector2(float(index) * 14.0, 0.0), Vector2(11.0, 5.0))
			var filled := index < slow_stacks
			var color := Color(COLOR_BIO_ACID.r, COLOR_BIO_ACID.g, COLOR_BIO_ACID.b, 0.48 + timer_ratio * 0.48) if filled else Color(COLOR_BONE_DARK.r, COLOR_BONE_DARK.g, COLOR_BONE_DARK.b, 0.58)
			game.draw_rect(notch, color, true)
			if filled:
				game.draw_line(notch.position, notch.position + Vector2(notch.size.x * timer_ratio, 0.0), COLOR_AMBER_CORE, 1.0)

	# 2. Weaving Filaments connecting Suturador to active/telegraphed sutures
	if state in ["telegraph", "active"] and not game.amber_sutures.is_empty():
		var facing_sign := -1.0 if Vector2(suturer.get("facing_dir", Vector2.LEFT)).x < 0.0 else 1.0
		var mouth_pos := pos + Vector2(facing_sign * 32.0, 4.0)
		for suture_val in game.amber_sutures:
			var suture: Dictionary = suture_val
			var mid_world: Vector2 = Vector2(suture.get("a", Vector2.ZERO)).lerp(Vector2(suture.get("b", Vector2.ZERO)), 0.5)
			var target_screen := mid_world - camera
			var dist := mouth_pos.distance_to(target_screen)
			if dist <= 8.0:
				continue
			var normal := (target_screen - mouth_pos).normalized().orthogonal()
			var sag := sin(anim_time * 5.0 + dist * 0.01) * 12.0
			var ctrl := mouth_pos.lerp(target_screen, 0.5) + normal * sag

			var is_act := String(suture.get("state", "telegraph")) == "active"
			var thread_col := COLOR_AMBER_BRIGHT if is_act else COLOR_BIO_ACID
			var thread_alpha := 0.70 + breath * 0.25 if is_act else 0.45 + breath * 0.20

			# Double braided thread
			var segments := 6 if reduced_fx else 12
			var strand1 := PackedVector2Array()
			var strand2 := PackedVector2Array()
			for s in range(segments + 1):
				var t := float(s) / float(segments)
				var pt := mouth_pos.lerp(ctrl, t).lerp(ctrl.lerp(target_screen, t), t)
				var braid_off := normal * sin(t * 16.0 + anim_time * 8.0) * (2.2 if is_act else 1.4)
				strand1.append(pt + braid_off)
				strand2.append(pt - braid_off)

			game.draw_polyline(strand1, Color(thread_col.r, thread_col.g, thread_col.b, thread_alpha * 0.6), 2.2, true)
			game.draw_polyline(strand2, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, thread_alpha * 0.7), 1.8, true)
			game.draw_polyline(strand1, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, thread_alpha * 0.9), 1.0, true)

			# Energy beads traversing from suturador to suture
			if not reduced_fx:
				var bead_t := fmod(anim_time * 1.6 + float(dist * 0.005), 1.0)
				var bead_pt := mouth_pos.lerp(ctrl, bead_t).lerp(ctrl.lerp(target_screen, bead_t), bead_t)
				game.draw_circle(bead_pt, 3.5, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.90))
				game.draw_circle(bead_pt, 1.8, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.98))


# ==============================================================================
# SUTURE RENDERING (Telegraph & Active States)
# ==============================================================================
static func _draw_sutures(game: Node2D, camera: Vector2) -> void:
	for value in game.amber_sutures:
		var suture: Dictionary = value
		var a_world := Vector2(suture.get("a", Vector2.ZERO))
		var b_world := Vector2(suture.get("b", Vector2.ZERO))
		if not game._world_point_in_view(a_world.lerp(b_world, 0.5), camera, a_world.distance_to(b_world) * 0.5 + 100.0):
			continue
		var a := a_world - camera
		var b := b_world - camera
		var state := String(suture.get("state", "telegraph"))
		var event_seed := int(String(suture.get("id", "0")).hash())
		if state == "telegraph":
			_draw_telegraph(game, a, b, float(suture.get("timer", 0.0)), event_seed)
		else:
			_draw_active(game, a, b, float(suture.get("timer", 0.0)), event_seed)


static func _draw_telegraph(game: Node2D, a: Vector2, b: Vector2, timer: float, event_seed: int) -> void:
	var progress := 1.0 - clampf(timer / maxf(0.01, game.amber_suturer_controller.TELEGRAPH_TIME), 0.0, 1.0)
	var delta := b - a
	var length := delta.length()
	if length <= 1.0:
		return
	var direction := delta / length
	var normal := direction.orthogonal()
	var reduced_fx: bool = bool(game.gfx_low_resource or game.gfx_memory_saver)

	# 1. Hazard Corridor Warning Strip (Corredor de Alerta da Sutura)
	var half_width := 18.0 + progress * 4.0
	var corridor_poly := PackedVector2Array([
		a - normal * half_width,
		b - normal * half_width,
		b + normal * half_width,
		a + normal * half_width,
	])
	var corridor_alpha := 0.07 + progress * 0.16
	game.draw_colored_polygon(corridor_poly, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, corridor_alpha))

	# Boundary hazard lines
	var bound_alpha := 0.22 + progress * 0.55
	game.draw_line(a - normal * half_width, b - normal * half_width, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, bound_alpha * 0.4), 1.5)
	game.draw_line(a + normal * half_width, b + normal * half_width, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, bound_alpha * 0.4), 1.5)

	# 2. Hazard Hatching / Inward Chevron indicators along corridor
	var hatch_count := 4 if reduced_fx else 7
	for h in range(1, hatch_count):
		var ht := float(h) / float(hatch_count)
		var center := a.lerp(b, ht)
		var chevron_off := direction * 6.0
		var h_alpha := 0.18 + progress * 0.35
		game.draw_line(center - normal * half_width, center + chevron_off, Color(COLOR_AMBER_BRIGHT.r, COLOR_AMBER_BRIGHT.g, COLOR_AMBER_BRIGHT.b, h_alpha), 1.8)
		game.draw_line(center + normal * half_width, center + chevron_off, Color(COLOR_AMBER_BRIGHT.r, COLOR_AMBER_BRIGHT.g, COLOR_AMBER_BRIGHT.b, h_alpha), 1.8)

	# 3. Ground Incision Crack (Fenda que se abre antes do fecho)
	var segments := 8 if reduced_fx else 14
	var crack_points := PackedVector2Array()
	var crack_glow_points := PackedVector2Array()
	for s in range(segments + 1):
		var t := float(s) / float(segments)
		var base_pt := a.lerp(b, t)
		var wobble_freq := float(s * 3 + event_seed % 17)
		var wobble := sin(float(game.time_alive) * 12.0 + wobble_freq) * (3.8 * (1.0 - progress * 0.7))
		crack_points.append(base_pt + normal * wobble)
		crack_glow_points.append(base_pt + normal * (wobble * 0.5))

	game.draw_polyline(crack_points, Color(COLOR_FISSURE_VOID.r, COLOR_FISSURE_VOID.g, COLOR_FISSURE_VOID.b, 0.40 + progress * 0.40), 5.0, true)
	game.draw_polyline(crack_glow_points, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.35 + progress * 0.55), 2.5, true)
	game.draw_polyline(crack_points, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.40 + progress * 0.60), 1.2, true)

	# 4. Floating Amber Tension Motes
	if not reduced_fx:
		var mote_count := 5
		for m in range(mote_count):
			var mt := fmod(float(m) * 0.22 + float(game.time_alive) * 0.35 + float(event_seed % 29) * 0.05, 1.0)
			var m_pos := a.lerp(b, mt) + normal * sin(float(game.time_alive) * 6.0 + float(m)) * 10.0
			var m_pulse := 0.5 + 0.5 * sin(float(game.time_alive) * 10.0 + float(m * 2))
			game.draw_circle(m_pos, 2.0 + m_pulse, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.45 + progress * 0.45))

	# 5. Endpoint Sigils
	_draw_endpoint_hint(game, a, progress, direction)
	_draw_endpoint_hint(game, b, progress, -direction)


static func _draw_active(game: Node2D, a: Vector2, b: Vector2, timer: float, event_seed: int) -> void:
	var delta := b - a
	var length := delta.length()
	if length <= 1.0:
		return
	var direction := delta / length
	var normal := direction.orthogonal()
	var life_ratio := clampf(timer / maxf(0.01, game.amber_suturer_controller.ACTIVE_TIME), 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(float(game.time_alive) * 8.5 + float(event_seed % 19))
	var tension_twitch := sin(float(game.time_alive) * 24.0 + float(event_seed % 11)) * 0.8
	var reduced_fx: bool = bool(game.gfx_low_resource or game.gfx_memory_saver)

	# 1. Dark Fissure Trench (Chão lacerado com fundo visceral)
	game.draw_line(a, b, Color(COLOR_FISSURE_VOID.r, COLOR_FISSURE_VOID.g, COLOR_FISSURE_VOID.b, 0.90 * life_ratio), 18.0)

	# 2. Viscous Amber Bleed & Soft Bloom
	var glow_width := 24.0 + pulse * 4.0
	game.draw_line(a, b, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.28 * life_ratio), glow_width)
	game.draw_line(a, b, Color(COLOR_BIO_ACID.r, COLOR_BIO_ACID.g, COLOR_BIO_ACID.b, 0.16 * life_ratio), glow_width * 0.6)

	# 3. Main Multi-Layered Suture Vein (Feixe de Âmbar Cristalino)
	var point_count := 8 if reduced_fx else 15
	var outer_points := PackedVector2Array()
	var core_points := PackedVector2Array()
	for index in range(point_count + 1):
		var t := float(index) / float(point_count)
		var wobble := sin(float(index) * 2.1 + float(game.time_alive) * 2.8 + event_seed * 0.01) * (2.2 + pulse * 1.8) + tension_twitch
		var pt := a.lerp(b, t) + normal * wobble
		outer_points.append(pt)
		core_points.append(a.lerp(b, t) + normal * (wobble * 0.45))

	# Amber sheath
	game.draw_polyline(outer_points, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.92 * life_ratio), 8.5 + pulse * 1.5, true)
	# Acid bio-rim
	game.draw_polyline(outer_points, Color(COLOR_BIO_ACID.r, COLOR_BIO_ACID.g, COLOR_BIO_ACID.b, 0.78 * life_ratio), 4.2, true)
	# Glowing marrow core
	game.draw_polyline(core_points, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.98 * life_ratio), 2.2, true)

	# 4. Organic Cross-Stitches (As Costuras / Pontos Cirúrgicos de Osso e Âmbar)
	var stitch_interval := 34.0 if reduced_fx else 26.0
	var num_stitches := maxi(2, int(length / stitch_interval))
	for i in range(1, num_stitches):
		var st := float(i) / float(num_stitches)
		var center := a.lerp(b, st)
		var stitch_span := 15.0 + pulse * 2.5
		var diag_offset := direction * 6.5
		var puncture_a1 := center - normal * stitch_span - diag_offset
		var puncture_b1 := center + normal * stitch_span + diag_offset
		var puncture_a2 := center - normal * stitch_span + diag_offset
		var puncture_b2 := center + normal * stitch_span - diag_offset

		# Calcified puncture nodules
		game.draw_circle(puncture_a1, 2.2, Color(COLOR_BONE_DARK.r, COLOR_BONE_DARK.g, COLOR_BONE_DARK.b, 0.88 * life_ratio))
		game.draw_circle(puncture_b1, 2.2, Color(COLOR_BONE_DARK.r, COLOR_BONE_DARK.g, COLOR_BONE_DARK.b, 0.88 * life_ratio))
		game.draw_circle(puncture_a2, 2.2, Color(COLOR_BONE_DARK.r, COLOR_BONE_DARK.g, COLOR_BONE_DARK.b, 0.88 * life_ratio))
		game.draw_circle(puncture_b2, 2.2, Color(COLOR_BONE_DARK.r, COLOR_BONE_DARK.g, COLOR_BONE_DARK.b, 0.88 * life_ratio))

		# Thread crossing 1
		game.draw_line(puncture_a1, puncture_b1, Color(COLOR_AMBER_DARK.r, COLOR_AMBER_DARK.g, COLOR_AMBER_DARK.b, 0.90 * life_ratio), 3.0)
		game.draw_line(puncture_a1, puncture_b1, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.95 * life_ratio), 1.6)

		# Thread crossing 2 (alternate X and single stitch)
		if i % 2 == 0:
			game.draw_line(puncture_a2, puncture_b2, Color(COLOR_AMBER_DARK.r, COLOR_AMBER_DARK.g, COLOR_AMBER_DARK.b, 0.90 * life_ratio), 3.0)
			game.draw_line(puncture_a2, puncture_b2, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.95 * life_ratio), 1.6)

	# 5. Calcified Bone Spines & Amber Stalagmites
	var spine_count := 6 if reduced_fx else 11
	for index in range(1, spine_count + 1):
		var t := float(index) / float(spine_count + 1)
		var root := a.lerp(b, t)
		var side := -1.0 if index % 2 == 0 else 1.0
		var spine_len := 10.0 + sin(float(index) * 1.8 + event_seed) * 4.0 + pulse * 3.0
		var spine_tilt := direction * (side * 4.0)
		var tip := root + normal * side * spine_len + spine_tilt
		var base_left := root - direction * 3.0
		var base_right := root + direction * 3.0
		var spine_poly := PackedVector2Array([base_left, tip, base_right])
		game.draw_colored_polygon(spine_poly, Color(COLOR_BONE_BASE.r, COLOR_BONE_BASE.g, COLOR_BONE_BASE.b, 0.92 * life_ratio))
		game.draw_line(root, tip, Color(COLOR_AMBER_BRIGHT.r, COLOR_AMBER_BRIGHT.g, COLOR_AMBER_BRIGHT.b, 0.85 * life_ratio), 1.6)
		# Specular glint on spine tip
		game.draw_circle(tip, 1.4, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, life_ratio))

	# 6. Flowing Amber Energy Nodes (Pulsos de resina que viajam pela sutura)
	if not reduced_fx:
		var node_t1 := fmod(float(game.time_alive) * 0.45 + float(event_seed % 13) * 0.08, 1.0)
		var node_t2 := fmod(1.0 - (float(game.time_alive) * 0.38 + float(event_seed % 7) * 0.12), 1.0)
		var p1 := a.lerp(b, node_t1)
		var p2 := a.lerp(b, node_t2)
		game.draw_circle(p1, 5.2, Color(COLOR_AMBER_BRIGHT.r, COLOR_AMBER_BRIGHT.g, COLOR_AMBER_BRIGHT.b, 0.70 * life_ratio))
		game.draw_circle(p1, 2.8, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.95 * life_ratio))
		game.draw_circle(p2, 4.4, Color(COLOR_BIO_PALE.r, COLOR_BIO_PALE.g, COLOR_BIO_PALE.b, 0.65 * life_ratio))
		game.draw_circle(p2, 2.2, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.92 * life_ratio))


# ==============================================================================
# ENDPOINT HINT (Countdown Sigil with Rotating Needles)
# ==============================================================================
static func _draw_endpoint_hint(game: Node2D, pos: Vector2, progress: float, outward_dir: Vector2) -> void:
	var pulse := 0.5 + 0.5 * sin(float(game.time_alive) * 10.0 + progress * 8.0)
	var radius := 20.0 + progress * 6.0

	# 1. Outer Ground Amber Puddle
	game.draw_circle(pos, radius * 1.15, Color(COLOR_AMBER_DARK.r, COLOR_AMBER_DARK.g, COLOR_AMBER_DARK.b, 0.25 + progress * 0.35))

	# 2. Contracting Countdown Diamond (Mostra claramente o tempo até o disparo)
	var contract_radius := radius * (1.6 - progress * 0.6)
	var diamond := PackedVector2Array([
		pos + Vector2(0.0, -contract_radius),
		pos + Vector2(contract_radius * 0.85, 0.0),
		pos + Vector2(0.0, contract_radius),
		pos + Vector2(-contract_radius * 0.85, 0.0),
		pos + Vector2(0.0, -contract_radius),
	])
	game.draw_polyline(diamond, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.40 + progress * 0.55), 2.2, true)

	# 3. Inner Bone Needle Claws (Spikes voltados para dentro)
	for i in range(4):
		var angle := float(i) * TAU / 4.0 + (1.0 - progress) * 1.5
		var tip := pos + Vector2.from_angle(angle) * (radius * 0.45)
		var base1 := pos + Vector2.from_angle(angle + 0.35) * (radius * 0.95)
		var base2 := pos + Vector2.from_angle(angle - 0.35) * (radius * 0.95)
		var spike_poly := PackedVector2Array([base1, tip, base2])
		game.draw_colored_polygon(spike_poly, Color(COLOR_BONE_BASE.r, COLOR_BONE_BASE.g, COLOR_BONE_BASE.b, 0.50 + progress * 0.45))

	# 4. Central Amber Core Flare
	var core_rad := 4.0 + progress * 4.5 + pulse * 2.0
	game.draw_circle(pos, core_rad, Color(COLOR_AMBER_BRIGHT.r, COLOR_AMBER_BRIGHT.g, COLOR_AMBER_BRIGHT.b, 0.65 + progress * 0.35))
	game.draw_circle(pos, core_rad * 0.55, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.90 + progress * 0.10))


# ==============================================================================
# SUTURE NODE (NÓ OSSEO / ÂNCORA DA SUTURA)
# ==============================================================================
static func draw_node(game: Node2D, enemy: Dictionary, camera: Vector2) -> void:
	var world_pos := Vector2(enemy.get("pos", Vector2.ZERO))
	if not game._world_point_in_view(world_pos, camera, 90.0):
		return
	var pos := world_pos - camera
	var hp := float(enemy.get("hp", 0.0))
	var max_hp := maxf(1.0, float(enemy.get("max_hp", 1.0)))
	var hp_ratio := clampf(hp / max_hp, 0.0, 1.0)
	var is_hit: bool = (float(game.time_alive) - float(enemy.get("last_damage_time", -100.0))) < 0.18
	var uid := int(enemy.get("uid", 0))
	var pulse_speed := 7.0 + (1.0 - hp_ratio) * 12.0 # Beats faster as it gets damaged!
	var pulse := 0.5 + 0.5 * sin(float(game.time_alive) * pulse_speed + float(uid % 31))
	var reduced_fx: bool = bool(game.gfx_low_resource or game.gfx_memory_saver)

	# 1. Ground Amber Resin Puddle with Roots
	var pool_radius := 24.0 + pulse * 3.0
	game.draw_circle(pos + Vector2(0.0, 6.0), pool_radius, Color(COLOR_AMBER_DEEP.r, COLOR_AMBER_DEEP.g, COLOR_AMBER_DEEP.b, 0.55))
	game.draw_circle(pos + Vector2(0.0, 6.0), pool_radius * 0.65, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.35 + pulse * 0.15))

	if not reduced_fx:
		for r in range(5):
			var r_angle := float(r) * TAU / 5.0 + float(uid % 7) * 0.2
			var r_start := pos + Vector2(0.0, 6.0) + Vector2.from_angle(r_angle) * (pool_radius * 0.4)
			var r_end := pos + Vector2(0.0, 6.0) + Vector2.from_angle(r_angle + 0.2) * (pool_radius * 1.25)
			game.draw_line(r_start, r_end, Color(COLOR_AMBER_DARK.r, COLOR_AMBER_DARK.g, COLOR_AMBER_DARK.b, 0.55), 2.2)

	# 2. Calcified Bone Claws / Mandible Clamps (Garras ósseas que cravam o nó no chão)
	var claw_radius := 18.0 + pulse * 1.5
	for side in [-1.0, 1.0]:
		var tip := pos + Vector2(side * (claw_radius * 0.95), -claw_radius * 0.8)
		var mid := pos + Vector2(side * (claw_radius * 1.25), 4.0)
		var base := pos + Vector2(side * (claw_radius * 0.5), claw_radius * 0.9)
		var inner := pos + Vector2(side * (claw_radius * 0.3), -2.0)
		var claw_poly := PackedVector2Array([tip, mid, base, inner])
		var bone_col := COLOR_AMBER_CORE if is_hit else COLOR_BONE_BASE
		game.draw_colored_polygon(claw_poly, Color(bone_col.r, bone_col.g, bone_col.b, 0.95))
		game.draw_polyline(PackedVector2Array([tip, mid, base, inner, tip]), Color(COLOR_BONE_DARK.r, COLOR_BONE_DARK.g, COLOR_BONE_DARK.b, 0.85), 1.8, true)

	# 3. Faceted Crystalline Amber Nucleus (Geodo de Âmbar Multifacetado)
	var gem_h := 19.0 + pulse * 2.0
	var gem_w := 14.0 + pulse * 1.5
	var top := pos + Vector2(0.0, -gem_h)
	var right := pos + Vector2(gem_w, -2.0)
	var bottom := pos + Vector2(0.0, gem_h * 0.85)
	var left := pos + Vector2(-gem_w, -2.0)
	var center_facet := pos + Vector2(0.0, -1.0)

	# Facets with light angles
	var f1 := PackedVector2Array([top, right, center_facet])
	var f2 := PackedVector2Array([right, bottom, center_facet])
	var f3 := PackedVector2Array([bottom, left, center_facet])
	var f4 := PackedVector2Array([left, top, center_facet])

	if is_hit:
		game.draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), Color(1.0, 0.98, 0.90, 0.98))
	else:
		game.draw_colored_polygon(f1, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.96))
		game.draw_colored_polygon(f2, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.94))
		game.draw_colored_polygon(f3, Color(COLOR_AMBER_DARK.r, COLOR_AMBER_DARK.g, COLOR_AMBER_DARK.b, 0.98))
		game.draw_colored_polygon(f4, Color(COLOR_AMBER_BRIGHT.r, COLOR_AMBER_BRIGHT.g, COLOR_AMBER_BRIGHT.b, 0.96))

	# Crystal facet edges
	var gem_edges := PackedVector2Array([top, right, bottom, left, top])
	game.draw_polyline(gem_edges, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.90), 2.0, true)
	game.draw_line(top, bottom, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.75), 1.5)
	game.draw_line(left, right, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.75), 1.5)

	# 4. Pulsing Inner Bio-Heart (Coração pulsante dentro do cristal)
	var heart_radius := (4.0 + pulse * 2.8) * hp_ratio
	if heart_radius > 0.8:
		game.draw_circle(center_facet, heart_radius * 1.5, Color(COLOR_BIO_ACID.r, COLOR_BIO_ACID.g, COLOR_BIO_ACID.b, 0.55 + pulse * 0.35))
		game.draw_circle(center_facet, heart_radius, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.95))

	# 5. Polished Bone-Framed Health Bar (Shown when damaged or targeted, or subtle compact frame)
	var is_targeted: bool = game._attack_target_is_enemy(uid)
	if hp_ratio < 0.999 or is_hit or is_targeted:
		var bar_width := 36.0
		var bar_height := 4.0
		var bar_pos := pos + Vector2(-bar_width * 0.5, -gem_h - 12.0)
		# Background
		game.draw_rect(Rect2(bar_pos + Vector2(-1.0, -1.0), Vector2(bar_width + 2.0, bar_height + 2.0)), Color(COLOR_BONE_DARK.r, COLOR_BONE_DARK.g, COLOR_BONE_DARK.b, 0.92), true)
		game.draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.08, 0.05, 0.03, 0.90), true)
		# HP fill
		var fill_color := COLOR_AMBER_BRIGHT if hp_ratio > 0.35 else Color(1.0, 0.28, 0.15)
		game.draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), fill_color, true)
		game.draw_line(bar_pos, bar_pos + Vector2(bar_width * hp_ratio, 0.0), Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.75), 1.0)

	# 6. Attack Target Indicator
	if is_targeted:
		game._draw_attack_target_marker(pos + Vector2(0.0, 8.0), 24.0, true)


# ==============================================================================
# VISUAL EVENTS (Entry, Telegraph, Activate, Break, Dissipate, Death)
# ==============================================================================
static func _draw_visual_events(game: Node2D, camera: Vector2) -> void:
	for value in game.amber_suturer_visual_events:
		var event: Dictionary = value
		var world_pos := Vector2(event.get("pos", Vector2.ZERO))
		if not game._world_point_in_view(world_pos, camera, 220.0):
			continue
		var pos := world_pos - camera
		var age := float(event.get("age", 0.0))
		var max_life := maxf(0.01, float(event.get("max_life", 1.0)))
		var progress := clampf(age / max_life, 0.0, 1.0)
		var fade := 1.0 - progress
		var reduced_fx: bool = bool(game.gfx_low_resource or game.gfx_memory_saver)

		match String(event.get("kind", "")):
			"entry":
				_draw_event_entry(game, pos, progress, fade, reduced_fx)
			"telegraph":
				_draw_event_telegraph(game, pos, progress, fade, reduced_fx)
			"activate":
				_draw_event_activate(game, pos, progress, fade, reduced_fx)
			"needle_telegraph":
				_draw_event_needle_telegraph(game, event, pos, progress, fade, reduced_fx)
			"needle_fire":
				_draw_event_needle_fire(game, event, pos, progress, fade, reduced_fx)
			"hook_telegraph":
				_draw_event_hook_telegraph(game, event, pos, progress)
			"hook_fire", "hook_hit":
				_draw_event_hook(game, event, pos, progress, fade, reduced_fx)
			"card_steal":
				_draw_event_card_steal(game, event, pos, progress, fade)
			"evasion":
				_draw_event_evasion(game, pos, progress, fade)
			"crystal_slow":
				_draw_event_crystal_slow(game, event, pos, progress, fade, reduced_fx)
			"break":
				_draw_event_break(game, pos, progress, fade, reduced_fx)
			"dissipate", "cleanup":
				_draw_event_dissipate(game, pos, progress, fade, reduced_fx)
			"death":
				_draw_death_frame(game, pos, progress, fade, reduced_fx)


static func _draw_event_crystal_slow(game: Node2D, event: Dictionary, pos: Vector2, progress: float, fade: float, reduced_fx: bool) -> void:
	var stacks := clampi(int(event.get("stacks", 1)), 1, 4)
	var radius := 12.0 + progress * 34.0
	game.draw_arc(pos, radius, 0.0, TAU, 18, Color(COLOR_BIO_ACID.r, COLOR_BIO_ACID.g, COLOR_BIO_ACID.b, fade * 0.82), 2.2, true)
	var shard_count := stacks + 2 if reduced_fx else stacks * 2 + 4
	for index in range(shard_count):
		var direction := Vector2.from_angle(float(index) * TAU / float(shard_count) + progress * 0.8)
		var shard_pos := pos + direction * (9.0 + progress * 24.0)
		game.draw_line(shard_pos, shard_pos - direction * (5.0 + float(stacks)), Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, fade), 2.0, true)


static func _draw_event_entry(game: Node2D, pos: Vector2, progress: float, fade: float, reduced_fx: bool) -> void:
	# 1. Concentric Amber Shockwaves
	var r1 := 20.0 + progress * 85.0
	var r2 := 10.0 + progress * 55.0
	game.draw_arc(pos, r1, 0.0, TAU, 36, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.75 * fade), 3.5, true)
	game.draw_arc(pos, r2, 0.0, TAU, 28, Color(COLOR_BIO_ACID.r, COLOR_BIO_ACID.g, COLOR_BIO_ACID.b, 0.60 * fade), 2.2, true)

	# 2. Organic Ground Fracture Lines rooted in the center
	var rays := 6 if reduced_fx else 9
	for index in range(rays):
		var angle := float(index) * TAU / float(rays) + 0.22
		var dir := Vector2.from_angle(angle)
		var norm := dir.orthogonal()
		var mid_dist := (18.0 + progress * 32.0)
		var end_dist := (42.0 + progress * 72.0)
		var zig := norm * sin(float(index) * 2.5 + progress * 4.0) * 5.0
		var start_pt := pos
		var mid_pt := pos + dir * mid_dist + zig
		var end_pt := pos + dir * end_dist
		game.draw_line(start_pt, mid_pt, Color(COLOR_AMBER_BRIGHT.r, COLOR_AMBER_BRIGHT.g, COLOR_AMBER_BRIGHT.b, 0.85 * fade), 2.8)
		game.draw_line(mid_pt, end_pt, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.75 * fade), 1.8)

	# 3. Flying Amber Shards
	if not reduced_fx:
		for s in range(8):
			var s_angle := float(s) * TAU / 8.0 + progress * 1.8
			var s_pos := pos + Vector2.from_angle(s_angle) * (30.0 + progress * 95.0)
			var s_size := 3.5 * fade
			game.draw_circle(s_pos, s_size, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.90 * fade))


static func _draw_event_telegraph(game: Node2D, pos: Vector2, progress: float, fade: float, reduced_fx: bool) -> void:
	var ring_r := 30.0 + progress * 60.0
	game.draw_arc(pos, ring_r, 0.0, TAU, 32, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.65 * fade), 2.8, true)
	if not reduced_fx:
		for i in range(6):
			var a := float(i) * TAU / 6.0 - progress * 1.5
			var p1 := pos + Vector2.from_angle(a) * (ring_r * 0.7)
			var p2 := pos + Vector2.from_angle(a) * ring_r
			game.draw_line(p1, p2, Color(COLOR_BIO_ACID.r, COLOR_BIO_ACID.g, COLOR_BIO_ACID.b, 0.75 * fade), 2.2)


static func _draw_event_needle_telegraph(game: Node2D, event: Dictionary, pos: Vector2, progress: float, _fade: float, reduced_fx: bool) -> void:
	var direction := Vector2(event.get("direction", Vector2.LEFT)).normalized()
	var radial := String(event.get("pattern", "fan")) == "radial"
	var pulse := 0.55 + 0.45 * sin(progress * TAU * 4.0)
	var count := 8 if radial and reduced_fx else (12 if radial else (3 if reduced_fx else 5))
	for index in range(count):
		var needle_dir: Vector2
		if radial:
			needle_dir = Vector2.from_angle(float(index) * TAU / float(count))
		else:
			var spread := 0.30 if not reduced_fx else 0.24
			var factor := 0.0 if count <= 1 else (float(index) / float(count - 1) * 2.0 - 1.0)
			needle_dir = direction.rotated(factor * spread)
		var length := 150.0 if radial else 285.0
		var start := pos + needle_dir * 44.0
		var finish := pos + needle_dir * length
		game.draw_line(start, finish, Color(COLOR_AMBER_DEEP.r, COLOR_AMBER_DEEP.g, COLOR_AMBER_DEEP.b, 0.42), 5.0, true)
		game.draw_line(start, finish, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.28 + pulse * 0.26), 1.5, true)
		var tip := finish - needle_dir * 10.0
		game.draw_circle(tip, 3.0 + pulse * 1.5, Color(COLOR_BIO_PALE.r, COLOR_BIO_PALE.g, COLOR_BIO_PALE.b, 0.62))
	game.draw_arc(pos, 50.0 + pulse * 7.0, 0.0, TAU, 32, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.52), 2.2, true)


static func _draw_event_needle_fire(game: Node2D, event: Dictionary, pos: Vector2, progress: float, fade: float, reduced_fx: bool) -> void:
	var radial := String(event.get("pattern", "fan")) == "radial"
	var direction := Vector2(event.get("direction", Vector2.LEFT)).normalized()
	var count := 8 if reduced_fx else (14 if radial else 7)
	for index in range(count):
		var shard_dir := Vector2.from_angle(float(index) * TAU / float(count)) if radial else direction.rotated(lerpf(-0.38, 0.38, float(index) / float(maxi(1, count - 1))))
		var shard_pos := pos + shard_dir * (34.0 + progress * 76.0)
		game.draw_line(shard_pos - shard_dir * 11.0, shard_pos + shard_dir * 5.0, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.86 * fade), 2.8, true)
	game.draw_arc(pos, 30.0 + progress * 54.0, 0.0, TAU, 28, Color(COLOR_BIO_ACID.r, COLOR_BIO_ACID.g, COLOR_BIO_ACID.b, 0.62 * fade), 2.5, true)


static func _draw_event_hook_telegraph(game: Node2D, event: Dictionary, pos: Vector2, progress: float) -> void:
	var target := Vector2(event.get("target_pos", Vector2(event.get("pos", Vector2.ZERO)))) - Vector2(event.get("pos", Vector2.ZERO)) + pos
	var direction := (target - pos).normalized()
	var distance := minf(pos.distance_to(target), game.amber_suturer_controller.HOOK_RANGE)
	var finish := pos + direction * distance
	var pulse := 0.55 + 0.45 * sin(progress * TAU * 5.0)
	game.draw_line(pos + direction * 42.0, finish, Color(COLOR_AMBER_DEEP.r, COLOR_AMBER_DEEP.g, COLOR_AMBER_DEEP.b, 0.58), 9.0, true)
	game.draw_dashed_line(pos + direction * 42.0, finish, Color(COLOR_BIO_ACID.r, COLOR_BIO_ACID.g, COLOR_BIO_ACID.b, 0.48 + pulse * 0.3), 3.0, 14.0, true)
	game.draw_arc(finish, 24.0 + pulse * 7.0, -PI * 0.25, PI * 1.25, 18, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.82), 3.0, true)


static func _draw_event_hook(game: Node2D, event: Dictionary, pos: Vector2, progress: float, fade: float, reduced_fx: bool) -> void:
	var target_world := Vector2(event.get("target_pos", event.get("pos", Vector2.ZERO)))
	var origin_world := Vector2(event.get("pos", Vector2.ZERO))
	var target := target_world - origin_world + pos
	var direction := (target - pos).normalized()
	var reach := pos.lerp(target, minf(1.0, progress * 2.4))
	game.draw_line(pos + direction * 38.0, reach, Color(COLOR_AMBER_DEEP.r, COLOR_AMBER_DEEP.g, COLOR_AMBER_DEEP.b, 0.62 * fade), 8.0, true)
	game.draw_line(pos + direction * 38.0, reach, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.88 * fade), 2.2, true)
	var shard_count := 4 if reduced_fx else 8
	for index in range(shard_count):
		var t := float(index + 1) / float(shard_count + 1)
		var bead := (pos + direction * 38.0).lerp(reach, t)
		game.draw_circle(bead, 2.2, Color(COLOR_BIO_ACID.r, COLOR_BIO_ACID.g, COLOR_BIO_ACID.b, 0.72 * fade))
	game.draw_arc(reach, 12.0 + progress * 24.0, 0.0, TAU, 20, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.76 * fade), 2.6, true)


static func _draw_event_card_steal(game: Node2D, event: Dictionary, pos: Vector2, progress: float, fade: float) -> void:
	var color: Color = event.get("card_color", COLOR_AMBER_WARM)
	var card_name := String(event.get("card_name", "CARTA")).to_upper()
	var viewport := game.get_viewport_rect().size
	var panel_size := Vector2(224.0, 50.0)
	var desired := pos + Vector2(0.0, -37.0 - progress * 10.0) - Vector2(panel_size.x * 0.5, panel_size.y * 0.5)
	var panel_pos := Vector2(
		clampf(desired.x, 14.0, maxf(14.0, viewport.x - panel_size.x - 14.0)),
		clampf(desired.y, 155.0, maxf(155.0, viewport.y - panel_size.y - 72.0))
	)
	var panel := Rect2(panel_pos, panel_size)
	game.draw_rect(panel, Color(COLOR_FISSURE_VOID.r, COLOR_FISSURE_VOID.g, COLOR_FISSURE_VOID.b, 0.88 * fade), true)
	game.draw_rect(panel, Color(color.r, color.g, color.b, 0.92 * fade), false, 2.5)
	game.draw_string(game.font, panel.position + Vector2(10.0, 18.0), "CARTA ROUBADA", HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 20.0, game._readable_text_size(11), Color(1.0, 0.56, 0.28, fade))
	game.draw_string(game.font, panel.position + Vector2(10.0, 39.0), card_name, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x - 20.0, game._readable_text_size(14), Color(1.0, 0.96, 0.82, fade))


static func _draw_event_evasion(game: Node2D, pos: Vector2, progress: float, fade: float) -> void:
	for index in range(3):
		var offset := Vector2(-34.0 - float(index) * 20.0, 0.0) * progress
		game.draw_arc(pos + offset, 28.0 + float(index) * 8.0, -PI * 0.55, PI * 0.55, 16, Color(COLOR_AMBER_BRIGHT.r, COLOR_AMBER_BRIGHT.g, COLOR_AMBER_BRIGHT.b, (0.5 - float(index) * 0.1) * fade), 2.0, true)


static func _draw_event_activate(game: Node2D, pos: Vector2, progress: float, fade: float, reduced_fx: bool) -> void:
	# 1. Violent Suture Snap Shockwave (Impacto súbito)
	var snap_r := 35.0 + progress * 115.0
	game.draw_arc(pos, snap_r, 0.0, TAU, 44, Color(COLOR_AMBER_BRIGHT.r, COLOR_AMBER_BRIGHT.g, COLOR_AMBER_BRIGHT.b, 0.85 * fade), 4.5, true)
	game.draw_arc(pos, snap_r * 0.82, 0.0, TAU, 36, Color(COLOR_BIO_PALE.r, COLOR_BIO_PALE.g, COLOR_BIO_PALE.b, 0.70 * fade), 2.4, true)

	# 2. Radial Amber Needles Burst (Espículas de alta velocidade)
	var needle_count := 8 if reduced_fx else 14
	for i in range(needle_count):
		var angle := float(i) * TAU / float(needle_count) + 0.15
		var dir := Vector2.from_angle(angle)
		var tip := pos + dir * (snap_r * 1.15)
		var base := pos + dir * (snap_r * 0.6)
		game.draw_line(base, tip, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.92 * fade), 2.6)

	# 3. Central Core Flare
	if progress < 0.45:
		var flare_fade := 1.0 - (progress / 0.45)
		game.draw_circle(pos, 22.0 * flare_fade, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.95 * flare_fade))


static func _draw_event_break(game: Node2D, pos: Vector2, progress: float, fade: float, reduced_fx: bool) -> void:
	# Spectacular Glass/Amber Shatter! (Quando o jogador quebra um nó ou rompe uma sutura)
	var shard_count := 10 if reduced_fx else 18
	for i in range(shard_count):
		var seed_val := float(i * 17)
		var angle := float(i) * TAU / float(shard_count) + sin(seed_val) * 0.35
		var speed := 45.0 + fmod(seed_val * 7.1, 75.0)
		var shard_pos := pos + Vector2.from_angle(angle) * (speed * progress)
		var shard_rot := progress * (4.0 if i % 2 == 0 else -5.0) + angle
		var shard_size := (4.5 + fmod(seed_val, 3.5)) * fade
		var p1 := shard_pos + Vector2.from_angle(shard_rot) * shard_size
		var p2 := shard_pos + Vector2.from_angle(shard_rot + 2.1) * (shard_size * 0.7)
		var p3 := shard_pos + Vector2.from_angle(shard_rot + 4.2) * (shard_size * 0.6)
		var col := COLOR_AMBER_GOLD if i % 2 == 0 else COLOR_BIO_ACID
		game.draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(col.r, col.g, col.b, 0.92 * fade))

	# Broken thread recoil curls
	var snap_r := 15.0 + progress * 55.0
	game.draw_arc(pos, snap_r, 0.0, TAU, 28, Color(COLOR_AMBER_BRIGHT.r, COLOR_AMBER_BRIGHT.g, COLOR_AMBER_BRIGHT.b, 0.80 * fade), 2.8, true)
	game.draw_circle(pos, 8.0 * fade, Color(COLOR_AMBER_CORE.r, COLOR_AMBER_CORE.g, COLOR_AMBER_CORE.b, 0.90 * fade))


static func _draw_event_dissipate(game: Node2D, pos: Vector2, progress: float, fade: float, reduced_fx: bool) -> void:
	# Gentle unspooling into floating golden embers
	var count := 6 if reduced_fx else 12
	for index in range(count):
		var angle := float(index) * TAU / float(count) - 0.35 + progress * 0.8
		var dist := 10.0 + progress * 60.0
		var mote_pos := pos + Vector2.from_angle(angle) * dist + Vector2(0.0, -progress * 24.0) # Floating up
		game.draw_circle(mote_pos, 2.8 * fade, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.75 * fade))
	game.draw_arc(pos, 20.0 + progress * 35.0, 0.0, TAU, 24, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.45 * fade), 1.8, true)


static func _draw_death_frame(game: Node2D, pos: Vector2, progress: float, fade: float, reduced_fx: bool) -> void:
	var source: Texture2D = game.textures.get("enemy_phase_6_suturador_ambar")
	if source == null:
		return
	_ensure_frames(source)
	var column := clampi(int(floor(progress * float(COLUMNS))), 0, COLUMNS - 1)
	var frame: Texture2D = _frames[ROW_DEATH * COLUMNS + column]

	# 1. Ground Amber Fossil Puddle (Stain that remains while dying)
	var pool_r := 38.0 * (1.0 - progress * 0.4)
	game.draw_circle(pos + Vector2(0.0, 18.0), pool_r, Color(COLOR_AMBER_DEEP.r, COLOR_AMBER_DEEP.g, COLOR_AMBER_DEEP.b, 0.65 * fade))
	game.draw_circle(pos + Vector2(0.0, 18.0), pool_r * 0.6, Color(COLOR_AMBER_WARM.r, COLOR_AMBER_WARM.g, COLOR_AMBER_WARM.b, 0.45 * fade))

	# 2. Carapace Splatter Shards
	if not reduced_fx:
		for i in range(8):
			var a := float(i) * TAU / 8.0 + 0.4
			var shard_p := pos + Vector2.from_angle(a) * (20.0 + progress * 58.0)
			game.draw_circle(shard_p, 3.0 * fade, Color(COLOR_AMBER_GOLD.r, COLOR_AMBER_GOLD.g, COLOR_AMBER_GOLD.b, 0.85 * fade))

	# 3. Death sprite with amber modulation
	game._draw_entity(frame, pos, Vector2(168.0, 108.0), Color(1.0, 0.95, 0.85, fade), false)


static func _ensure_frames(source: Texture2D) -> void:
	var source_id := source.get_instance_id()
	if source_id == _source_id and _frames.size() == COLUMNS * ROWS:
		return
	_source_id = source_id
	_frames.clear()
	var cell := Vector2i(source.get_width() / COLUMNS, source.get_height() / ROWS)
	for row in range(ROWS):
		for column in range(COLUMNS):
			var frame := AtlasTexture.new()
			frame.atlas = source
			frame.region = Rect2i(Vector2i(column * cell.x, row * cell.y), cell)
			_frames.append(frame)
