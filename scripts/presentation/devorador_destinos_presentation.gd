class_name RTDevoradorDestinosPresentation
extends RefCounted

## Card art: a violet fanged maw, a crimson destiny tether, a cyan target
## and a cyan protective shell. All animation consumes existing proc state.
## No simulation, damage, random calls, screen copies or extra viewports.
const VOID := Color(0.025, 0.007, 0.055)
const VIOLET := Color(0.38, 0.08, 0.68)
const MAGENTA := Color(0.94, 0.08, 0.57)
const RED := Color(1.0, 0.10, 0.30)
const IVORY := Color(1.0, 0.80, 0.93)
const CYAN := Color(0.20, 0.94, 1.0)
const MAX_BURSTS := 4
static var _meshes: Array[ArrayMesh] = []


static func warmup() -> void:
	if not _meshes.is_empty():
		return
	# Disc, rough annulus, hooked tooth, ribbon, shard, halo, fine shield rim.
	for shape in range(7):
		var vertices := PackedVector3Array()
		var colors := PackedColorArray()
		var indices := PackedInt32Array()
		if shape == 1 or shape == 3 or shape == 6:
			for step in range(49):
				var t := float(step) / 48.0
				var angle := lerpf(-0.9, 1.3, t) if shape == 3 else t * TAU
				var radial := Vector2.from_angle(angle)
				var rough := 0.035 * sin(t * TAU * 13.0) if shape == 1 else 0.0
				var width := 0.12 if shape == 1 else (0.035 if shape == 6 else sin(t * PI) * 0.12)
				for edge in range(2):
					var point := radial * (0.85 + rough + width * float(edge))
					vertices.append(Vector3(point.x, point.y, 0))
					colors.append(Color(1, 1, 1, (0.4 if edge == 0 else 1.0)))
				if step < 48:
					var i := step * 2
					indices.append_array(PackedInt32Array([i, i + 1, i + 2, i + 1, i + 3, i + 2]))
		elif shape == 2:
			# Root at x=1; a bent inner edge gives each fang a hooked tip.
			for step in range(9):
				var t := float(step) / 8.0
				var spine := Vector2(1.0 - t * 0.42, -0.10 * t * t)
				var width := 0.12 * pow(1.0 - t, 0.7)
				for edge in range(2):
					var point := spine + Vector2(0, width * (-1.0 if edge == 0 else 1.0))
					vertices.append(Vector3(point.x, point.y, 0))
					colors.append(Color(1, 1, 1, 1))
				if step < 8:
					var i := step * 2
					indices.append_array(PackedInt32Array([i, i + 1, i + 2, i + 1, i + 3, i + 2]))
		else:
			var count := 4 if shape == 4 else 48
			vertices.append(Vector3.ZERO)
			colors.append(Color.WHITE)
			for index in range(count):
				var point := Vector2.from_angle(float(index) * TAU / float(count))
				if shape == 4:
					point *= Vector2(1.0, 0.38)
				vertices.append(Vector3(point.x, point.y, 0))
				colors.append(Color(1, 1, 1, 0.0 if shape == 5 else 1.0))
				indices.append_array(PackedInt32Array([0, index + 1, (index + 1) % count + 1]))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_meshes.append(mesh)


static func _shape(game: Node2D, index: int, pos: Vector2, size: Vector2, angle: float, color: Color) -> void:
	if color.a <= 0.001:
		return
	warmup()
	game.draw_mesh(_meshes[index], null, Transform2D(angle, size, 0.0, pos), color)


static func _maw(game: Node2D, pos: Vector2, radius: float, openness: float, phase: float, alpha: float) -> void:
	var aspect := Vector2(1.0, lerpf(0.22, 0.88, openness))
	_shape(game, 5, pos, aspect * radius * 1.6, -0.18, Color(VIOLET, alpha * 0.75))
	_shape(game, 0, pos, aspect * radius, -0.18, Color(VOID, alpha * 0.98))
	_shape(game, 1, pos, aspect * radius * 1.10, -0.18, Color(VIOLET, alpha))
	_shape(game, 1, pos, aspect * radius, -0.18, Color(MAGENTA, alpha * 0.8))
	for index in range(3):
		_shape(game, 3, pos, aspect * radius * (1.18 + index * 0.10), phase * 0.3 + index * TAU / 3.0, Color(VIOLET if index % 2 == 0 else MAGENTA, alpha * 0.55))
	# Fangs rotate as a jaw, while the dark center stays visibly hollow.
	var teeth := 10 if game.gfx_low_resource else 12
	var jaw := Transform2D(-0.18, aspect, 0.0, pos)
	for index in range(teeth):
		var angle := float(index) * TAU / float(teeth) + sin(phase * 0.5) * 0.08
		var fang_radius := radius * (0.93 + 0.06 * sin(index * 2.1))
		var tooth := Transform2D(angle, Vector2(fang_radius, fang_radius * 0.90), 0.0, Vector2.ZERO)
		game.draw_mesh(_meshes[2], null, jaw * tooth, Color(0.65, 0.12, 0.50, alpha))
		var face := Transform2D(angle + 0.035, Vector2(fang_radius * 0.97, fang_radius * 0.60), 0.0, Vector2.ZERO)
		game.draw_mesh(_meshes[2], null, jaw * face, Color(IVORY, alpha * 0.88))
	for index in range(2):
		_shape(game, 3, pos, aspect * radius * (0.32 + index * 0.10), phase + index * PI, Color(VIOLET, alpha * 0.7))
	_shape(game, 5, pos, aspect * radius * 0.42, 0.0, Color(MAGENTA, alpha * 0.9))
	_shape(game, 0, pos, aspect * radius * 0.12, 0.0, Color(VOID, alpha))
	_shape(game, 1, pos, aspect * radius * 0.16, phase, Color(RED, alpha))


static func _target(game: Node2D, pos: Vector2, radius: float, phase: float, alpha: float) -> void:
	_shape(game, 5, pos, Vector2.ONE * radius * 1.8, 0.0, Color(CYAN, alpha * 0.32))
	game.draw_arc(pos, radius, 0, TAU, 24, Color(VOID, alpha), 5.0, true)
	game.draw_arc(pos, radius, 0, TAU, 24, Color(CYAN, alpha), 1.8, true)
	for index in range(4):
		var dir := Vector2.from_angle(index * PI * 0.5)
		game.draw_line(pos + dir * radius * 0.5, pos + dir * radius * 1.5, Color(CYAN, alpha), 1.6, true)
	_shape(game, 4, pos, Vector2(5, 7), phase * 0.25, Color(IVORY, alpha))


static func _tether(game: Node2D, start: Vector2, end: Vector2, phase: float, alpha: float) -> void:
	alpha *= 0.86 + 0.14 * sin(phase * 2.0)
	var previous := start
	var side := (end - start).orthogonal().normalized()
	for index in range(1, 17):
		var t := float(index) / 16.0
		var point := start.lerp(end, t) + side * sin(t * PI) * (12.0 + 4.0 * sin(phase + t * 4.0))
		game.draw_line(previous, point, Color(VOID, alpha * 0.85), 6.0, true)
		game.draw_line(previous, point, Color(RED, alpha * 0.85), 3.0, true)
		game.draw_line(previous, point, Color(IVORY, alpha * 0.65), 1.0, true)
		previous = point
	var travel := fposmod(phase * 0.35, 1.0)
	var pulse := start.lerp(end, travel) + side * sin(travel * PI) * (12.0 + 4.0 * sin(phase + travel * 4.0))
	_shape(game, 4, pulse, Vector2(4, 3), (end - start).angle(), Color(IVORY, alpha))


static func _mark_position(game: Node2D) -> Vector2:
	if game.devorador_mark_kind == "boss":
		return game.boss_pos if game.boss_active and game.boss_hp > 0.0 else Vector2.INF
	if game.devorador_mark_kind == "enemy":
		var enemy = game._enemy_by_uid(game.devorador_mark_uid)
		if enemy != null and float(enemy.get("hp", 0.0)) > 0.0:
			return Vector2(enemy.get("pos", game.devorador_mark_pos))
	return Vector2.INF


static func draw_world(game: Node2D, camera: Vector2) -> void:
	var phase := float(game.time_alive) * 2.8
	var world_pos := _mark_position(game)
	if world_pos.is_finite() and game._world_point_in_view(world_pos, camera, 190.0):
		var pos := world_pos - camera + Vector2(0, 20)
		var radius := 58.0 if game.devorador_mark_kind == "boss" else 30.0
		_shape(game, 5, pos, Vector2(radius * 1.3, radius * 0.5), 0, Color(VIOLET, 0.42))
		for index in range(3):
			_shape(game, 3, pos, Vector2(radius, radius * 0.35), phase * 0.2 + index * TAU / 3.0, Color(MAGENTA, 0.32))
	var count := 0
	for event in game.devorador_effects:
		if float(event.get("life", 0.0)) <= 0.0:
			continue
		var pos := Vector2(event.get("pos", game.player_pos))
		if not game._world_point_in_view(pos, camera, 260.0):
			continue
		var p := clampf(1.0 - float(event["life"]) / maxf(0.01, float(event.get("max", 0.56))), 0.0, 1.0)
		var radius := minf(240.0, float(event.get("radius", 114.0)))
		var fade := 1.0 - smoothstep(0.55, 1.0, p)
		for index in range(4 if game.gfx_low_resource else 7):
			var angle := index * 2.399 + float(event.get("phase", 0.0))
			_shape(game, 3, pos - camera, Vector2(radius, radius * 0.66) * (0.55 + p * 0.5), angle, Color(VIOLET if index % 2 == 0 else MAGENTA, fade * 0.24))
		count += 1
		if count >= MAX_BURSTS:
			break


static func draw_foreground(game: Node2D, camera: Vector2) -> void:
	var phase := float(game.time_alive) * 2.8
	var world_pos := _mark_position(game)
	if world_pos.is_finite() and game._world_point_in_view(world_pos, camera, 190.0):
		var boss: bool = game.devorador_mark_kind == "boss"
		var target := world_pos - camera + Vector2(0, -32 if boss else -12)
		var mouth := target + (Vector2(106, -74) if boss else Vector2(54, -54))
		var progress := 0.0
		if boss:
			progress = clampf((game.devorador_boss_mark_start_hp - game.boss_hp) / maxf(1.0, game.devorador_boss_mark_max_hp * game.DEVORADOR_BOSS_HP_LOSS_RATIO), 0.0, 1.0)
		_tether(game, target, mouth, phase, 0.78)
		_maw(game, mouth, (29.0 if boss else 22.0) + progress * 9.0, 0.5 + progress * 0.5, phase, 0.9)
		_target(game, target, 18.0 if boss else 13.0, phase, 0.85)
	var count := 0
	for event in game.devorador_effects:
		if float(event.get("life", 0.0)) <= 0.0:
			continue
		var world := Vector2(event.get("pos", game.player_pos))
		if not game._world_point_in_view(world, camera, 260.0):
			continue
		_draw_burst(game, event, world - camera)
		count += 1
		if count >= MAX_BURSTS:
			break
	if game.devorador_destiny_shield > 0.0 and game.devorador_shield_timer > 0.0 and not game.is_dead:
		_draw_shield(game, Vector2(game.player_pos) - camera, phase)


static func _draw_burst(game: Node2D, event: Dictionary, pos: Vector2) -> void:
	var p := clampf(1.0 - float(event["life"]) / maxf(0.01, float(event.get("max", 0.56))), 0.0, 1.0)
	var phase := float(event.get("phase", 0.0)) + p * 3.0
	var fade := 1.0 - smoothstep(0.65, 1.0, p)
	var boss: bool = String(event.get("kind", "")) == "boss"
	var radius := (70.0 if boss else 52.0) * (0.7 + 0.3 * sin(p * PI))
	var mouth := pos + Vector2(26 if boss else 0, -78 if boss else -36)
	var openness := (0.3 + 0.7 * smoothstep(0.0, 0.18, p)) * (1.0 - 0.85 * smoothstep(0.38, 0.8, p))
	_maw(game, mouth, radius, openness, phase, fade)
	# Torn fragments converge on the maw, then escape outward as it closes.
	if game.gfx_particles:
		for index in range(7 if game.gfx_low_resource else 13):
			var angle := index * 2.399 + float(event.get("phase", 0.0))
			var radial := Vector2.from_angle(angle)
			var travel := lerpf(1.8, 0.3, minf(1.0, p / 0.55)) if p < 0.55 else lerpf(0.3, 2.0, (p - 0.55) / 0.45)
			var point := mouth + radial * radius * travel * Vector2(1, 0.68)
			_shape(game, 4, point, Vector2(5.5, 7.0), angle + p * 4, Color(VOID, fade))
			_shape(game, 4, point + Vector2(1, -1), Vector2(3.0, 5.0), angle + p * 4, Color(MAGENTA, fade * 0.9))
			game.draw_line(point, point + radial * 12.0, Color(RED, fade * 0.65), 1.3, true)
	if p > 0.5:
		var release := (p - 0.5) * 2.0
		for index in range(3):
			_shape(game, 3, mouth, Vector2(1, 0.55) * radius * (1.0 + release), index * TAU / 3.0 + phase, Color(MAGENTA, sin(release * PI) * 0.65))


static func _draw_shield(game: Node2D, center: Vector2, phase: float) -> void:
	var timer := float(game.devorador_shield_timer)
	var fade := minf(1.0, timer / 0.8)
	var arrival := 1.0 - clampf((game.DEVORADOR_SHIELD_DURATION - timer) / 0.5, 0.0, 1.0)
	var shell := Vector2(43, 57) * (1.0 + arrival * 0.08)
	var pos := center + Vector2(0, -7)
	_shape(game, 5, pos, shell * 1.13, 0.0, Color(CYAN, 0.12 * fade))
	_shape(game, 6, pos, shell, 0.0, Color(CYAN, fade * (0.65 + arrival * 0.3)))
	for index in range(3):
		_shape(game, 3, pos, shell * (1.02 + index * 0.025), phase * 0.15 + index * TAU / 3.0, Color(CYAN, fade * 0.22))
	for index in range(6 if game.gfx_low_resource else 10):
		var angle := index * 2.399 + phase * 0.12
		var point := pos + Vector2.from_angle(angle) * shell * 0.96
		_shape(game, 4, point, Vector2(2, 5), angle, Color(IVORY, fade * (0.5 + 0.2 * sin(phase + index))))
