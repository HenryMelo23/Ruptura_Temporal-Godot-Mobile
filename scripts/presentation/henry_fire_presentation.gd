@static_unload
extends RefCounted

## Bounded, pre-triangulated flame silhouettes. No particle nodes, RNG, screen
## texture reads or gameplay state. Local and remote casts use the same clock.
static var flame_meshes: Array[ArrayMesh] = []
const VARIANTS := 8


static func _mesh(index: int) -> ArrayMesh:
	if flame_meshes.is_empty():
		for variant in range(VARIANTS):
			var vertices := PackedVector2Array()
			var colors := PackedColorArray()
			var indices := PackedInt32Array()
			var bend := sin(float(variant) * TAU / VARIANTS) * 0.26
			var outline := PackedVector2Array([
				Vector2(0, 0.08), Vector2(-0.34, 0), Vector2(-0.48, -0.22),
				Vector2(-0.39, -0.43), Vector2(-0.48, -0.66), Vector2(-0.17, -0.54),
				Vector2(-0.2 + bend, -0.79), Vector2(0.12 + bend, -1.18),
				Vector2(0.08 + bend, -0.8), Vector2(0.32, -0.59),
				Vector2(0.36, -0.83), Vector2(0.49, -0.45), Vector2(0.45, -0.18), Vector2(0.24, 0.04)])
			for layer in range(3):
				var points := PackedVector2Array()
				var scale := Vector2(1.0 - layer * 0.27, 1.0 - layer * 0.24)
				for point in outline:
					points.append(point * scale)
				var offset := vertices.size()
				for triangle in Geometry2D.triangulate_polygon(points):
					indices.append(triangle + offset)
				for point in points:
					vertices.append(point)
					var tip := clampf(-point.y, 0.0, 1.0)
					var color: Color
					match layer:
						0: color = Color(0.96, 0.17, 0.012, 0.82).lerp(Color(0.7, 0.055, 0.006, 0.05), tip)
						1: color = Color(1.0, 0.70, 0.055, 0.94).lerp(Color(1.0, 0.26, 0.012, 0.72), tip)
						_: color = Color(1.0, 0.97, 0.64, 0.94).lerp(Color(1.0, 0.68, 0.10, 0.72), tip)
					colors.append(color)
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_COLOR] = colors
			arrays[Mesh.ARRAY_INDEX] = indices
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			flame_meshes.append(mesh)
	return flame_meshes[posmod(index, VARIANTS)]


static func _flame(game: Node2D, base: Vector2, direction: Vector2, width: float, height: float, clock: float, seed_value: int, alpha: float) -> void:
	if height < 1.0 or alpha <= 0.005:
		return
	var flicker := 1.0 + sin(clock * 24.0 + float(seed_value) * 2.4) * 0.12
	var rotation := direction.angle() + PI * 0.5
	game.draw_mesh(_mesh(int(clock * 18.0) + seed_value), null,
		Transform2D(rotation, Vector2(width, height * flicker), 0.0, base), Color(1, 1, 1, alpha))


static func cone(game: Node2D, origin: Vector2, direction: Vector2, progress: float, alpha: float) -> void:
	var dir := direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	var p := clampf(progress, 0.0, 1.0)
	var reach: float = game.HENRY_SKILL_RANGE * smoothstep(0.04, game.HENRY_SKILL_IMPACT_TIME, p)
	var fade := alpha * smoothstep(0.0, 0.08, p) * (1.0 - smoothstep(0.76, 1.0, p))
	var low: bool = game._runtime_visual_budget_active() or not game.gfx_particles
	var count := 14 if low else 28
	# Moving staggered lobes build a widening plume; no triangle or range outline.
	for index in range(count):
		var lane := float(index % 7) / 6.0
		var bands := float(count / 7)
		var travel := (floorf(float(index) / 7.0) + fposmod(p * 3.0 + sin(index * 7.13) * 0.48, 1.0)) / bands
		var angle: float = lerpf(-game.HENRY_SKILL_HALF_ANGLE * 0.86, game.HENRY_SKILL_HALF_ANGLE * 0.86, lane)
		var outward := dir.rotated(angle)
		var distance := 28.0 + travel * maxf(0.0, reach - 55.0)
		var base := origin + outward * distance
		var width := lerpf(22.0, 64.0, travel) * (0.8 + 0.2 * sin(index * 3.1 + p * 13.0))
		var length := minf(reach / bands * (1.6 + 0.3 * sin(index * 2.1)), maxf(0.0, reach - distance) / 1.18)
		_flame(game, base, outward.rotated(sin(p * 15.0 + index) * 0.1), width, length, p, index, fade * (0.55 + (1.0 - travel) * 0.32))
	_flame(game, origin + dir * 26.0, dir, 26.0, minf(85.0, reach * 0.5), p, 3, fade)
	if not low:
		for index in range(10):
			var travel := fposmod(p * 2.0 + index * 0.137, 1.0)
			var outward := dir.rotated(sin(float(index) * 3.7) * game.HENRY_SKILL_HALF_ANGLE)
			var pos := origin + outward * reach * travel + Vector2(0, -travel * 14.0)
			game.draw_rect(Rect2(pos, Vector2(2, 3)), Color(1.0, 0.65, 0.18, fade * sin(travel * PI)))


static func wave(game: Node2D, center: Vector2, radius: float, max_radius: float, alpha: float) -> void:
	var p := clampf(radius / maxf(1.0, max_radius), 0.0, 1.0)
	var fade := alpha * smoothstep(0.0, 0.08, p) * (1.0 - smoothstep(0.65, 1.0, p))
	var low: bool = game._runtime_visual_budget_active() or not game.gfx_particles
	var count := 18 if low else 36
	for index in range(count):
		var angle := float(index) / count * TAU
		var outward := Vector2.from_angle(angle)
		var jitter := sin(index * 2.17 + p * 19.0) * 12.0
		var base := center + outward * maxf(0.0, radius - 25.0 + jitter)
		var direction := (outward * 0.3 + Vector2.UP).normalized()
		var width := maxf(28.0, TAU * radius / count * 1.65)
		_flame(game, base, direction, width, (32.0 + sin(index * 1.8) * 10.0) * (1.4 - p * 0.4), p, index, fade)
	# The open center leaves the character, enemies and pickups legible.


static func charge(game: Node2D, center: Vector2, progress: float, alpha: float) -> void:
	var p := clampf(progress, 0.0, 1.0)
	var fade := alpha * smoothstep(0.12, 0.4, p)
	var low: bool = game._runtime_visual_budget_active() or not game.gfx_particles
	var count := 5 if low else 9
	for index in range(count):
		var side := lerpf(-1.0, 1.0, float(index) / maxf(1, count - 1))
		var base := center + Vector2(side * 26.0, 28.0 - absf(side) * 7.0)
		# Side flames climb around the suit; do not cover face or glasses.
		_flame(game, base, Vector2(side * 0.15, -1.0), 16.0 + p * 12.0,
			(15.0 + 47.0 * p) * (0.5 + absf(side) * 0.5), p, index, fade * 0.85)
	for index in range(4 if low else 8):
		var angle := index * 2.399
		var travel := fposmod(p * 2.4 + index * 0.27, 1.0)
		var pos := center + Vector2.from_angle(angle) * lerpf(74.0, 22.0, travel) + Vector2(0, 20)
		game.draw_rect(Rect2(pos, Vector2(2, 3)), Color(1.0, 0.66, 0.14, sin(travel * PI) * fade))


static func draw_entrance(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	var owner = game.henry_incendiary_ability_controller
	if not owner.entrance_active:
		return
	var tint: float = (1.0 - owner.entrance_world_speed()) * 0.29
	# One translucent pass; no full-screen blur, screen copy or extra viewport.
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.035, 0.19, 0.43, tint))
	if owner.entrance_elapsed < owner.ENTRY_WANDER_TIME + owner.ENTRY_BRAKE_TIME:
		return
	for peer in owner.entrance_peers:
		var pos: Vector2 = game.player_pos
		if int(peer) != game._mp_unique_id():
			var state: Dictionary = game.net_players_by_peer.get(int(peer), {})
			pos = Vector2(state.get("render_pos", state.get("pos", game.PLAYER_START)))
		game.EntitiesPresentation._draw_henry_entry_pose(game, camera, pos, owner.entrance_pose_time())
