class_name RTHenryColossusPresentation
extends RefCounted

## Restrained physical feedback for Colosso D37 and Lastro. The authored
## sheets carry the pose; these accents only clarify weight, timing and stacks.

const WEIGHT := Color(0.72, 0.82, 0.58)
const IMPACT := Color(0.94, 0.82, 0.58)
const DUST := Color(0.34, 0.29, 0.24)
const CHALK := Color(1.0, 0.94, 0.78)
const INK := Color(0.12, 0.10, 0.09)
static var _meshes: Array[ArrayMesh] = []


static func warmup() -> void:
	if not _meshes.is_empty():
		return
	# Five immutable silhouettes: punch arc, rock, dust, speed wedge, impact.
	# All geometry is triangulated once, then reused through draw transforms.
	for shape in range(5):
		var vertices := PackedVector3Array()
		var colors := PackedColorArray()
		var indices := PackedInt32Array()
		if shape == 0:
			for step in range(25):
				var t := float(step) / 24.0
				var radial := Vector2.from_angle(lerpf(-1.05, 1.05, t))
				var width := sin(t * PI) * 0.24
				for edge in range(2):
					var point := radial * (0.78 + width * float(edge))
					vertices.append(Vector3(point.x, point.y, 0))
					colors.append(Color(1, 1, 1, sin(t * PI) * (0.25 if edge == 0 else 1.0)))
				if step < 24:
					var i := step * 2
					indices.append_array(PackedInt32Array([i, i + 1, i + 2, i + 1, i + 3, i + 2]))
		else:
			var count := 20 if shape == 2 or shape == 4 else 4
			vertices.append(Vector3.ZERO)
			colors.append(Color.WHITE)
			for index in range(count):
				var angle := TAU * float(index) / float(count)
				var radius := 0.8 + 0.2 * sin(index * 2.7)
				if shape == 4:
					radius = (1.0 if index % 2 == 0 else 0.2) * (0.8 + 0.2 * cos(index * 3.1))
				var point := Vector2.from_angle(angle) * radius
				if shape == 3:
					point = Vector2(1.0, 0.0) if index == 0 else (Vector2(-1.0, 0.0) if index == 2 else Vector2(-0.7, 0.32 if index == 1 else -0.32))
				vertices.append(Vector3(point.x, point.y, 0))
				colors.append(Color(1, 1, 1, 0.0 if shape == 2 else 1.0))
				indices.append_array(PackedInt32Array([0, index + 1, (index + 1) % count + 1]))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_meshes.append(mesh)


static func _shape(game: Node2D, shape: int, center: Vector2, size: Vector2, angle: float, color: Color) -> void:
	if color.a <= 0.001:
		return
	warmup()
	game.draw_mesh(_meshes[shape], null, Transform2D(angle, size, 0.0, center), color)


static func _fractures(game: Node2D, foot: Vector2, radius: float, alpha: float) -> void:
	for index in range(5 if game.gfx_low_resource else 8):
		var radial := Vector2.from_angle(index * 2.399)
		var side := radial.orthogonal()
		var a := foot + radial * radius * 0.24 * Vector2(1, 0.44)
		var b := foot + (radial * radius * 0.58 + side * 6.0) * Vector2(1, 0.44)
		var c := foot + radial * radius * (0.75 + 0.2 * sin(index * 2.1)) * Vector2(1, 0.44)
		game.draw_line(a, b, Color(INK, alpha * 0.9), 4.0, true)
		game.draw_line(b, c, Color(INK, alpha * 0.75), 3.0, true)
		game.draw_line(a + Vector2(0, 2), b + Vector2(0, 2), Color(IMPACT, alpha * 0.5), 1.3, true)
		game.draw_line(b, b + side * 9.0, Color(INK, alpha * 0.7), 2.0, true)


static func _debris(game: Node2D, foot: Vector2, radius: float, progress: float, alpha: float) -> void:
	if not game.gfx_particles:
		return
	var p := clampf(progress, 0.0, 1.0)
	for index in range(5 if game.gfx_low_resource else 10):
		var radial := Vector2.from_angle(index * 2.399)
		var landing := foot + radial * radius * (0.3 + p * 0.7) * Vector2(1, 0.42)
		var lift := sin(p * PI) * (14.0 + index % 4 * 8.0)
		var size := 2.5 + index % 3 * 1.6
		_shape(game, 1, landing, Vector2(size * 1.4, 1.5), 0, Color(INK, alpha * 0.28))
		_shape(game, 1, landing - Vector2(0, lift), Vector2(size, size * 0.65), index + p * 4.0, Color(DUST, alpha))
		game.draw_line(landing - Vector2(1, lift + size * 0.4), landing + Vector2(size * 0.5, -lift), Color(IMPACT, alpha * 0.7), 1.3)


static func _dust_wave(game: Node2D, foot: Vector2, radius: float, progress: float, alpha: float) -> void:
	for index in range(4 if game.gfx_low_resource else 7):
		var angle := index * 2.399
		var pos := foot + Vector2.from_angle(angle) * radius * Vector2(1, 0.35)
		var size := Vector2(23.0 + progress * 25.0, 10.0 + progress * 9.0)
		_shape(game, 2, pos + Vector2(0, 3), size * 1.2, 0.0, Color(INK, alpha * 0.5))
		_shape(game, 2, pos, size, -0.2, Color(IMPACT, alpha * 0.46))


static func _draw_swing(game: Node2D, center: Vector2, direction: Vector2, stage: int, progress: float, giant: bool, alpha: float) -> void:
	var p := clampf(progress, 0.0, 1.0)
	var fade := sin(p * PI) * alpha
	var scale := 1.7 if giant else 1.0
	var dir := direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	var shoulder := center + Vector2(0, -23.0 * scale)
	if stage >= 2:
		var tip := shoulder + dir * 44.0 * scale + Vector2(0, lerpf(-40.0, 32.0, p) * scale)
		_shape(game, 3, tip, Vector2(26, 13) * scale, PI * 0.5, Color(INK, fade * 0.65))
		_shape(game, 3, tip - Vector2(3, 0), Vector2(23, 6) * scale, PI * 0.5, Color(CHALK, fade * 0.85))
		if p > 0.45:
			var foot := center + dir * 52.0 * scale + Vector2(0, 34)
			_fractures(game, foot, 42.0 * scale, fade * 0.7)
			_dust_wave(game, foot, 25.0 * scale, p, fade * 0.8)
	else:
		var sweep := dir.angle() + lerpf(-0.48, 0.48, p) * (1.0 if stage == 0 else -1.0)
		var size := Vector2(48, 30) * scale
		_shape(game, 0, shoulder, size * 1.12, sweep, Color(INK, fade * 0.75))
		_shape(game, 0, shoulder + dir * 3.0, size, sweep, Color(IMPACT, fade * 0.88))
		_shape(game, 0, shoulder + dir * 6.0, size * 0.92, sweep, Color(CHALK, fade * 0.9))
		_shape(game, 3, shoulder + dir * 30.0 * scale, Vector2(28, 5) * scale, dir.angle(), Color(WEIGHT, fade * 0.7))


static func draw_impact(game: Node2D, event: Dictionary, camera: Vector2) -> void:
	var p := clampf(1.0 - float(event.get("life", 0.0)) / maxf(0.01, float(event.get("max", 0.3))), 0.0, 1.0)
	var fade := 1.0 - smoothstep(0.15, 1.0, p)
	var pos := Vector2(event.get("pos", Vector2.ZERO)) - camera + Vector2(0, -12)
	var angle := Vector2(event.get("dir", Vector2.RIGHT)).angle()
	var size := float(event.get("size", 28.0)) * (0.65 + p * 0.6)
	_shape(game, 4, pos, Vector2.ONE * size * 1.2, angle, Color(INK, fade * 0.85))
	_shape(game, 4, pos, Vector2.ONE * size, angle + 0.03, Color(IMPACT, fade * 0.9))
	_shape(game, 4, pos, Vector2.ONE * size * 0.56, angle, Color(CHALK, fade))
	_debris(game, pos + Vector2(0, 16), size * 1.6, p, fade)


static func draw_local(game: Node2D, camera: Vector2, owner: RefCounted) -> void:
	_draw_remote_swings(game, camera)
	if owner == null:
		return
	var center: Vector2 = Vector2(game.player_pos) - camera
	if owner.mutation_active() and not game.is_dead and game.player_freeze_visual_timer <= 0.0 and not game.henry_skill_cast_active and not game.henry_ultimate_cast_active and game._player_attack_pose_active():
		_draw_swing(game, center, game.player_attack_visual_dir, game.henry_attack_visual_stage, (game.time_alive - game.last_attack_time) / (game.PLAYER_FIRE_FRAME_SECONDS * 2.0), owner.giant_active, 1.0)
	if owner.transforming or owner.shrinking:
		var progress: float = clampf(owner.transform_elapsed / owner.TRANSFORM_DURATION, 0.0, 1.0)
		var visual_progress: float = 1.0 - progress if owner.shrinking else progress
		_draw_growth(game, center, visual_progress, 1.0)
	if owner.impact_armor > 0.0:
		_draw_impact_armor(game, center, owner, 1.0)
	if owner.giant_active:
		_draw_giant_status(game, center, owner, 1.0)
	if owner.guard_active:
		_draw_guard(game, center, owner.guard_direction, owner.guard_elapsed / owner.GUARD_WINDOW, 1.0)
	if owner.charge_active:
		_draw_charge(game, owner.charge_origin - camera, game.player_pos - camera, owner.charge_direction, owner.charge_elapsed / owner.CHARGE_DURATION, 1.0)
	_draw_lastro_marks(game, camera, owner)


static func _draw_remote_swings(game: Node2D, camera: Vector2) -> void:
	if not game.is_multiplayer:
		return
	for peer in game.net_players_by_peer:
		var state: Dictionary = game.net_players_by_peer[peer]
		if String(state.get("manifestation_key", "")) != "colosso" or not game._remote_player_state_targetable(state):
			continue
		if int(state.get("anim_state", -1)) != game.NET_ANIM_FIRE:
			continue
		var frame := clampi(int(state.get("frame_idx", 0)), 0, 39)
		var pose := frame % 5
		if pose >= 3:
			continue
		var direction := Vector2.from_angle(floorf(float(frame) / 5.0) * PI / 4.0)
		var pos := Vector2(state.get("render_pos", state.get("pos", Vector2.ZERO)))
		if game._world_point_in_view(pos, camera, 180.0):
			_draw_swing(game, pos - camera, direction, pose, 0.45, (int(state.get("visual_flags", 0)) & 4) != 0, 0.8)


static func draw_remote(game: Node2D, visual: Dictionary, camera: Vector2, action: int, progress: float, fade: float) -> void:
	var source_peer: int = int(visual.get("source", 0))
	var state: Dictionary = game.net_players_by_peer.get(source_peer, {})
	var world_pos: Vector2 = Vector2(state.get("render_pos", state.get("pos", visual.get("origin", game.net_player_render_pos))))
	var center: Vector2 = world_pos - camera
	if action == game.NET_ABILITY_SKILL:
		var target: Vector2 = Vector2(visual.get("target", world_pos + Vector2.RIGHT * 80.0))
		var origin := Vector2(visual.get("origin", world_pos))
		var direction: Vector2 = (target - origin).normalized()
		if direction.length_squared() <= 0.001:
			direction = Vector2.RIGHT
		# Classify from the original path: distance remaining shrinks during a
		# charge and must never turn its last half into a guard animation.
		if origin.distance_to(target) > 120.0:
			_draw_charge(game, Vector2(visual.get("origin", world_pos)) - camera, center, direction, progress, fade)
		else:
			_draw_guard(game, center, direction, progress, fade)
	elif action == game.NET_ABILITY_SECONDARY:
		var maximum: float = maxf(0.01, float(visual.get("max", 32.4)))
		var windup: float = maxf(0.01, float(visual.get("extra", 1.2)))
		var elapsed: float = progress * maximum
		if elapsed < windup:
			_draw_growth(game, center, elapsed / windup, fade)
		elif elapsed > maximum - windup:
			_draw_growth(game, center, 1.0 - (elapsed - (maximum - windup)) / windup, fade)
		else:
			game.draw_arc(center + Vector2(0, 38), 46.0, 0.0, TAU, 42, Color(WEIGHT.r, WEIGHT.g, WEIGHT.b, 0.3 * fade), 2.0, true)


static func _draw_growth(game: Node2D, center: Vector2, progress: float, alpha: float) -> void:
	var p: float = clampf(progress, 0.0, 1.0)
	var foot: Vector2 = center + Vector2(0, 35)
	var pressure := smoothstep(0.08, 0.75, p)
	_fractures(game, foot, 35.0 + p * 80.0, pressure * alpha)
	_dust_wave(game, foot, 25.0 + p * 80.0, p, pressure * alpha)
	_debris(game, foot, 38.0 + p * 68.0, p * 0.85, pressure * alpha)
	for side in [-1.0, 1.0]:
		var flank := center + Vector2(float(side) * (34.0 + p * 45.0), -10.0 - p * 23.0)
		_shape(game, 3, flank, Vector2(20.0 + p * 28.0, 7.0), -PI * 0.5 + float(side) * 0.18, Color(INK, pressure * alpha * 0.7))
		_shape(game, 3, flank + Vector2(float(side) * 3, 0), Vector2(18.0 + p * 25.0, 3.0), -PI * 0.5 + float(side) * 0.18, Color(WEIGHT, pressure * alpha * 0.86))
	if p > 0.65:
		var release := (p - 0.65) / 0.35
		for index in range(3):
			_shape(game, 0, foot, Vector2(75.0 + release * 56.0, 22.0 + release * 18.0), index * TAU / 3.0, Color(IMPACT, sin(release * PI) * alpha * 0.6))


static func _draw_giant_status(game: Node2D, center: Vector2, owner: RefCounted, alpha: float) -> void:
	var ratio := clampf(1.0 - owner.giant_elapsed / owner.GIANT_DURATION, 0.0, 1.0)
	var foot := center + Vector2(0, 42)
	for index in range(10):
		var angle := PI + PI * float(index) / 9.0
		var pos := foot + Vector2.from_angle(angle) * Vector2(48, 14)
		var tint := WEIGHT if float(index) / 10.0 < ratio else DUST
		_shape(game, 1, pos, Vector2(3.8, 2.0), 0.0, Color(tint, alpha * 0.6))
	if owner.giant_temp_hp > 0.0:
		var guard_ratio := clampf(owner.giant_temp_hp / maxf(1.0, game.player_hp_max * owner.GIANT_TEMP_HP_RATIO), 0.0, 1.0)
		game.draw_rect(Rect2(center + Vector2(-30, -78), Vector2(60, 4)), Color(0.03, 0.05, 0.04, 0.78 * alpha), true)
		game.draw_rect(Rect2(center + Vector2(-29, -77), Vector2(58 * guard_ratio, 2)), Color(WEIGHT.r, WEIGHT.g, WEIGHT.b, 0.9 * alpha), true)


static func _draw_impact_armor(game: Node2D, center: Vector2, owner: RefCounted, alpha: float) -> void:
	var armor_ratio := clampf(owner.impact_armor / maxf(1.0, owner._impact_armor_cap()), 0.0, 1.0)
	var plate_count := ceili(armor_ratio * 4.0)
	for index in range(plate_count):
		var angle := PI * 0.25 + float(index) * PI * 0.5
		var radial := Vector2.from_angle(angle)
		var plate_center := center + Vector2(0, 4) + radial * 35.0
		_shape(game, 1, plate_center, Vector2(8.0, 4.5), angle, Color(INK, 0.72 * alpha))
		_shape(game, 1, plate_center - radial * 1.5, Vector2(6.8, 2.8), angle, Color(IMPACT, (0.42 + armor_ratio * 0.42) * alpha))
	var bar_width := 42.0
	game.draw_rect(Rect2(center + Vector2(-bar_width * 0.5, -66), Vector2(bar_width, 3)), Color(0.03, 0.03, 0.03, 0.64 * alpha), true)
	game.draw_rect(Rect2(center + Vector2(-bar_width * 0.5 + 1, -65), Vector2((bar_width - 2.0) * armor_ratio, 1)), Color(IMPACT.r, IMPACT.g, IMPACT.b, 0.86 * alpha), true)


static func _draw_guard(game: Node2D, center: Vector2, direction: Vector2, progress: float, alpha: float) -> void:
	var dir := direction.normalized()
	if dir.length_squared() <= 0.001:
		dir = Vector2.RIGHT
	var front := center + Vector2(0, -20) + dir * 8.0
	var p := clampf(progress, 0.0, 1.0)
	var pulse := 1.0 + sin(p * PI) * 0.12
	var fade := (1.0 - smoothstep(0.8, 1.0, p)) * alpha
	_shape(game, 0, front, Vector2(35, 27) * pulse, dir.angle(), Color(INK, fade * 0.9))
	_shape(game, 0, front + dir * 4, Vector2(34, 25) * pulse, dir.angle(), Color(WEIGHT, fade * 0.85))
	_shape(game, 0, front + dir * 7, Vector2(30, 23) * pulse, dir.angle(), Color(CHALK, fade * 0.78))
	_fractures(game, center + Vector2(0, 35), 33.0, fade * 0.45)


static func _draw_charge(game: Node2D, origin: Vector2, center: Vector2, direction: Vector2, progress: float, alpha: float) -> void:
	var dir := direction.normalized()
	if dir.length_squared() <= 0.001:
		dir = Vector2.RIGHT
	var side := dir.orthogonal()
	var p := clampf(progress, 0.0, 1.0)
	var fade := alpha * (1.0 - smoothstep(0.86, 1.0, p))
	var foot := center + Vector2(0, 35)
	var traveled := minf(origin.distance_to(center), 220.0)
	for index in range(3 if game.gfx_low_resource else 5):
		var t := float(index + 1) / 5.0
		var trail := foot - dir * traveled * t
		var opacity := fade * (1.0 - t) * 0.85
		_shape(game, 2, trail + side * sin(index * 2.1) * 18.0, Vector2(34.0 + t * 32.0, 22.0), dir.angle(), Color(IMPACT, opacity))
		_shape(game, 3, trail + Vector2(0, -25.0 - index % 2 * 25.0), Vector2(35, 4), dir.angle(), Color(CHALK, opacity * 0.75))
	var shoulder := center + Vector2(0, -38) + dir * 30.0
	_shape(game, 0, shoulder, Vector2(68, 47), dir.angle(), Color(INK, fade * 0.65))
	_shape(game, 0, shoulder + dir * 4.0, Vector2(66, 43), dir.angle(), Color(IMPACT, fade * 0.75))
	_shape(game, 0, shoulder + dir * 8.0, Vector2(61, 40), dir.angle(), Color(CHALK, fade * 0.82))
	_fractures(game, foot, 54.0, fade * 0.6)
	_debris(game, foot - dir * 22, 52.0, fposmod(p * 2.0, 1.0), fade)


static func _draw_lastro_marks(game: Node2D, camera: Vector2, owner: RefCounted) -> void:
	for enemy in game.enemies:
		var stacks := int(enemy.get("henry_lastro_stacks", 0))
		var anchored := float(enemy.get("henry_lastro_anchor", 0.0)) > 0.0
		if stacks <= 0 and not anchored:
			continue
		var center := Vector2(enemy.get("pos", Vector2.ZERO)) - camera + Vector2(0, 26)
		_draw_stack_ticks(game, center, stacks, anchored)
	if game.boss_active and (owner.boss_lastro_stacks > 0 or owner.boss_lastro_slow_timer > 0.0):
		_draw_stack_ticks(game, game.boss_pos - camera + Vector2(0, 52), owner.boss_lastro_stacks, owner.boss_lastro_slow_timer > 0.0)


static func _draw_stack_ticks(game: Node2D, center: Vector2, stacks: int, triggered: bool) -> void:
	var color := IMPACT if triggered else WEIGHT
	if triggered:
		_fractures(game, center, 35.0, 0.8)
		for side in [-1.0, 1.0]:
			var jaw := center + Vector2(float(side) * 19, -5)
			_shape(game, 3, jaw, Vector2(13, 8), -PI * 0.5 + float(side) * 0.3, Color(INK, 0.9))
			_shape(game, 3, jaw + Vector2(0, -2), Vector2(10, 4), -PI * 0.5 + float(side) * 0.3, Color(WEIGHT, 0.88))
	for index in range(LASTRO_TICKS):
		var angle := PI + PI * float(index) / float(LASTRO_TICKS - 1)
		var inner := center + Vector2.from_angle(angle) * 18.0
		var outer := center + Vector2.from_angle(angle) * (25.0 if index < stacks else 21.0)
		var alpha := 0.9 if index < stacks or triggered else 0.2
		game.draw_line(inner, outer, Color(color.r, color.g, color.b, alpha), 3.0 if index < stacks else 1.4, true)


const LASTRO_TICKS := 5
