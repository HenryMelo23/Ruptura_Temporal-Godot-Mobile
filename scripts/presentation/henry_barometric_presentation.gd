class_name RTHenryBarometricPresentation
extends RefCounted

## Procedural world-space accents for Henry's Barometric Mutation and Nimbo.
## Henry's existing authored attack/cast/ultimate sheets remain the base pose.

const PRESSURE := Color(0.28, 0.84, 0.94)
const AIR_CORE := Color(0.9, 1.0, 0.97)
const DEEP_AIR := Color(0.08, 0.34, 0.48)
const DUST := Color(0.66, 0.61, 0.49)

# Fixed geometry, shared by local/remote draws and every projectile. No nodes,
# particle simulation, screen copies or per-frame vertex-array construction.
static var _meshes: Array[ArrayMesh] = []


static func warmup() -> void:
	if not _meshes.is_empty():
		return
	for shape in range(3):
		var vertices := PackedVector3Array()
		var colors := PackedColorArray()
		var indices := PackedInt32Array()
		for step in range(33):
			var t := float(step) / 32.0
			var taper := pow(sin(PI * t), 0.8)
			var angle := lerpf(-1.25, 1.25, t)
			var radial := Vector2.from_angle(angle)
			var distance := lerpf(0.38, 1.0, t) if shape == 0 else 0.85
			var point := radial * distance
			var normal := radial
			if shape == 2:
				point = Vector2(t, sin(t * PI * 1.5) * 0.14)
				normal = Vector2.UP
			var width := taper * (0.06 if shape == 0 else 0.13)
			if shape == 0:
				width *= 0.88 + 0.12 * sin(t * 43.0) * sin(t * 19.0)
			for edge in [-1.0, 1.0]:
				var p: Vector2 = point + normal * width * float(edge)
				vertices.append(Vector3(p.x, p.y, 0.0))
				colors.append(Color(1.0, 1.0, 1.0, taper * (0.35 if edge < 0 else 1.0)))
			if step < 32:
				var i := step * 2
				indices.append_array(PackedInt32Array([i, i + 1, i + 2, i + 1, i + 3, i + 2]))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_meshes.append(mesh)


static func _ribbon(game: Node2D, shape: int, center: Vector2, size: Vector2, angle: float, color: Color) -> void:
	if color.a <= 0.001:
		return
	warmup()
	var transform := Transform2D(angle, size, 0.0, center)
	game.draw_mesh(_meshes[shape], null, transform, color)


static func draw_projectile(game: Node2D, bullet: Dictionary, pos: Vector2) -> void:
	var direction := Vector2(bullet.get("dir", Vector2.RIGHT)).normalized()
	var angle := direction.angle()
	var age := float(bullet.get("age", 0.0))
	var scale := clampf(float(bullet.get("visual_scale", 1.0)), 0.6, 2.0)
	var fade := clampf(float(bullet.get("life", 1.0)) * 8.0, 0.0, 1.0)
	var echo := String(bullet.get("kind", "")) == "henry_nimbo_pressure"
	var tint := Color(0.62, 0.86, 0.92) if echo else PRESSURE
	var size := Vector2(15.0, 26.0) * scale
	_ribbon(game, 1, pos - direction * 8.0, size * 1.35, angle, Color(DEEP_AIR, fade * 0.55))
	_ribbon(game, 1, pos, size, angle, Color(tint, fade * 0.85))
	_ribbon(game, 1, pos + direction * 2.0, size * 0.83, angle, Color(AIR_CORE, fade))
	var count := 2 if game.gfx_low_resource else 3
	for index in range(count):
		var side := direction.orthogonal() * (float(index) - 1.0) * 9.0 * scale
		var start := pos - direction * (48.0 + 7.0 * sin(age * 12.0 + index)) * scale + side
		_ribbon(game, 2, start, Vector2(40.0, 12.0) * scale, angle, Color(tint, fade * 0.38))


static func draw_local(game: Node2D, camera: Vector2, owner: RefCounted) -> void:
	if owner == null:
		return
	if owner.nimbo_active():
		_draw_nimbo(game, owner.nimbo_position() - camera, owner.nimbo_phase, owner.nimbo_flash, 1.0)
	if owner.corridor_active:
		_draw_corridor(game, game.player_pos - camera, owner.corridor_direction, owner.CORRIDOR_LENGTH, owner.CORRIDOR_HALF_WIDTH, owner.corridor_elapsed / owner.CORRIDOR_DURATION, 1.0)
	if owner.storm_windup_active:
		_draw_storm_charge(game, game.player_pos - camera, owner.storm_elapsed / owner.STORM_WINDUP, 1.0)
	elif owner.storm_active:
		_draw_storm(game, game.player_pos - camera, owner.STORM_RADIUS, owner.storm_elapsed / owner.STORM_DURATION, 1.0)


static func draw_remote(game: Node2D, visual: Dictionary, camera: Vector2, action: int, progress: float, fade: float) -> void:
	var source_peer := int(visual.get("source", 0))
	var source_state: Dictionary = game.net_players_by_peer.get(source_peer, {})
	var source_world := Vector2(source_state.get("render_pos", source_state.get("pos", visual.get("origin", game.net_player_render_pos))))
	var source := source_world - camera
	var target := Vector2(visual.get("target", source_world + Vector2.RIGHT * 390.0)) - camera
	var direction := (target - source).normalized()
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT
	if action == game.NET_ABILITY_SKILL:
		_draw_corridor(game, source, direction, 390.0, 92.0, progress, fade)
		_draw_nimbo(game, source + direction * 170.0 + direction.orthogonal() * sin(game.time_alive * 2.2) * 22.0, game.time_alive * 1.8, 0.0, fade)
	elif action == game.NET_ABILITY_SECONDARY:
		var maximum := maxf(0.01, float(visual.get("max", 7.05)))
		var windup := clampf(float(visual.get("extra", 0.55)), 0.01, maximum)
		var elapsed := progress * maximum
		if elapsed < windup:
			_draw_storm_charge(game, source, elapsed / windup, fade)
		else:
			_draw_storm(game, source, 285.0, (elapsed - windup) / maxf(0.01, maximum - windup), fade)
			_draw_nimbo(game, source + Vector2.from_angle(game.time_alive * 1.9 - 0.7) * 267.0, game.time_alive * 1.9, 0.0, fade)


static func _draw_corridor(game: Node2D, origin: Vector2, direction: Vector2, length: float, half_width: float, progress: float, alpha: float) -> void:
	var dir := direction.normalized()
	if dir.length() <= 0.01:
		dir = Vector2.RIGHT
	var side := dir.orthogonal()
	var reveal := smoothstep(0.0, 0.14, progress)
	var tail_fade := 1.0 - smoothstep(0.88, 1.0, progress)
	var opacity := clampf(reveal * tail_fade * alpha, 0.0, 1.0)
	var visible_length := length * minf(1.0, progress * 4.0)
	var segments := 5 if game.gfx_low_resource else 8
	for index in range(segments):
		var lane := lerpf(-half_width * 0.88, half_width * 0.88, float(index) / float(segments - 1))
		var travel := fposmod(progress * 5.4 + float(index) * 0.173, 1.0)
		var start := origin + dir * (18.0 + travel * visible_length * 0.7) + side * lane
		var span := minf(120.0, visible_length * (1.0 - travel * 0.7))
		var color := AIR_CORE if index % 3 == 0 else PRESSURE
		_ribbon(game, 2, start, Vector2(span, 38.0 + float(index % 3) * 16.0), dir.angle(), Color(DEEP_AIR, opacity * 0.48))
		_ribbon(game, 2, start - side * 2.0, Vector2(span, 27.0), dir.angle(), Color(color, opacity * 0.78))
	# Pressure fronts advance down the actual corridor, with a broad curved lip.
	for index in range(2 if game.gfx_low_resource else 3):
		var travel := fposmod(progress * 3.8 + float(index) * 0.34, 1.0)
		var lip := origin + dir * visible_length * travel
		var lip_alpha := sin(travel * PI) * opacity
		_ribbon(game, 1, lip, Vector2(36.0, half_width), dir.angle(), Color(PRESSURE, lip_alpha * 0.6))
		_ribbon(game, 1, lip + dir * 3.0, Vector2(24.0, half_width * 0.96), dir.angle(), Color(AIR_CORE, lip_alpha * 0.82))
	if game.gfx_particles:
		for index in range(5 if game.gfx_low_resource else 10):
			var travel := fposmod(progress * 4.8 + index * 0.193, 1.0)
			var grain := origin + dir * visible_length * travel + side * sin(index * 2.4) * half_width * 0.8
			game.draw_line(grain - dir * 6.0, grain, Color(DUST, opacity * sin(travel * PI) * 0.7), 2.0)


static func _draw_storm_charge(game: Node2D, center: Vector2, progress: float, alpha: float) -> void:
	var p := clampf(progress, 0.0, 1.0)
	var count := 3 if game.gfx_low_resource else 5
	for index in range(count):
		var radius := lerpf(132.0, 42.0, p) + index * 8.0
		var spin := float(index) * TAU / float(count) + p * 3.8
		_ribbon(game, 0, center, Vector2.ONE * radius, spin, Color(DEEP_AIR, alpha * 0.35))
		_ribbon(game, 0, center, Vector2.ONE * radius * 0.94, spin + 0.04, Color(PRESSURE, alpha * (0.25 + p * 0.5)))
		var grain := center + Vector2.from_angle(spin) * radius
		game.draw_line(grain, grain.lerp(center, 0.16), Color(AIR_CORE, alpha * p * 0.8), 2.0)
	# Empty center leaves the authored hands/face visible during compression.
	_ribbon(game, 1, center, Vector2(42.0, 32.0), -p * 4.0, Color(AIR_CORE, alpha * p * 0.7))


static func _draw_storm(game: Node2D, center: Vector2, radius: float, progress: float, alpha: float) -> void:
	var enter := smoothstep(0.0, 0.08, progress)
	var exit := 1.0 - smoothstep(0.9, 1.0, progress)
	var fade := clampf(enter * exit * alpha, 0.0, 1.0)
	var spin := progress * 6.5 * 1.45
	var arms := 3 if game.gfx_low_resource else 5
	for index in range(arms):
		var angle := spin + TAU * float(index) / float(arms) + 0.16 * sin(spin * 0.7 + index * 2.1)
		var reach := radius * (0.88 + 0.09 * sin(spin * 1.4 + index))
		# Layered tapered spirals, with a dark underside for bright floors.
		_ribbon(game, 0, center + Vector2(0, 5), Vector2.ONE * reach, angle, Color(DEEP_AIR, fade * 0.42))
		_ribbon(game, 0, center, Vector2.ONE * reach, angle + 0.02, Color(PRESSURE, fade * 0.44))
		_ribbon(game, 0, center, Vector2.ONE * reach * 0.98, angle + 0.055, Color(AIR_CORE, fade * 0.48))
		if index < 2:
			_ribbon(game, 1, center, Vector2.ONE * radius * 0.98, angle + 0.35, Color(PRESSURE, fade * 0.2))
	# Inner air folds rotate as one vortex; the eye remains transparent.
	for index in range(2):
		_ribbon(game, 0, center, Vector2.ONE * radius * 0.43, spin * 1.2 + index * PI, Color(AIR_CORE, fade * 0.48))
	if game.gfx_particles:
		for index in range(10 if game.gfx_low_resource else 24):
			var angle := spin * (1.1 + float(index % 3) * 0.16) + index * 2.399
			var distance := radius * (0.48 + 0.46 * fposmod(index * 0.618, 1.0))
			var radial := Vector2.from_angle(angle)
			var grain := center + radial * distance
			var tangent := radial.orthogonal()
			var tint := DUST if index % 3 == 0 else AIR_CORE
			game.draw_line(grain - tangent * (4.0 + index % 4 * 3.0), grain, Color(tint, fade * 0.7), 2.0 if index % 3 == 0 else 1.4, true)


static func _draw_nimbo(game: Node2D, center: Vector2, phase: float, flash: float, alpha: float) -> void:
	var scale := 1.0 + clampf(flash / 0.28, 0.0, 1.0) * 0.24
	var c := center + Vector2(0.0, sin(phase * 2.1) * 3.0)
	var cloud_alpha := alpha * (0.78 + 0.12 * sin(phase * 1.7))
	game.draw_circle(c + Vector2(-8.0, 1.0) * scale, 9.0 * scale, Color(0.42, 0.62, 0.68, cloud_alpha * 0.74))
	game.draw_circle(c + Vector2(0.0, -4.0) * scale, 12.0 * scale, Color(0.62, 0.82, 0.86, cloud_alpha * 0.8))
	game.draw_circle(c + Vector2(10.0, 2.0) * scale, 8.0 * scale, Color(0.48, 0.72, 0.78, cloud_alpha * 0.76))
	game.draw_line(c + Vector2(-12.0, 8.0), c + Vector2(12.0, 8.0), Color(AIR_CORE.r, AIR_CORE.g, AIR_CORE.b, cloud_alpha * 0.68), 2.0, true)
	if flash > 0.0:
		game.draw_arc(c, 20.0 * scale, -phase, PI * 1.4 - phase, 26, Color(AIR_CORE.r, AIR_CORE.g, AIR_CORE.b, alpha * clampf(flash * 3.4, 0.0, 0.9)), 3.0, true)
