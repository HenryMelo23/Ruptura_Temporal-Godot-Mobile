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


static func spin(game: Node2D, center: Vector2, turns: float, progress: float, alpha: float) -> void:
	var p := clampf(progress, 0.0, 1.0)
	var phase := turns * TAU
	var arm_axis := Vector2.from_angle(phase)
	var fade := alpha * smoothstep(0.0, 0.06, p) * (1.0 - smoothstep(0.94, 1.0, p))
	var low: bool = game._runtime_visual_budget_active() or not game.gfx_particles
	for side in [-1.0, 1.0]:
		var outward: Vector2 = arm_axis * float(side)
		var hand: Vector2 = center + outward * 42.0 + Vector2(0.0, -4.0)
		_flame(game, hand, outward, 19.0 if low else 24.0, 54.0 if low else 76.0, p * 3.0, int(side * 3.0), fade)
		if not low:
			for ember in range(3):
				var trail := fposmod(p * 8.0 + float(ember) * 0.27 + (0.5 if side < 0.0 else 0.0), 1.0)
				var angle: float = phase - float(side) * trail * 0.9
				var pos := center + Vector2.from_angle(angle) * (44.0 + trail * 34.0) + Vector2(0.0, -6.0 - trail * 8.0)
				game.draw_circle(pos, 2.2 - trail * 0.8, Color(1.0, 0.55, 0.08, fade * (1.0 - trail)))
	var ring_alpha := fade * (0.16 + smoothstep(0.72, 1.0, p) * 0.48)
	game.draw_arc(center, 48.0 + smoothstep(0.72, 1.0, p) * 24.0, phase, phase + PI * 1.52, 42, Color(1.0, 0.34, 0.04, ring_alpha), 4.0, true)


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



static func _tex(game: Node2D, path: String) -> Texture2D:
	if game.textures.has(path):
		return game.textures[path] as Texture2D
	var full := "res://assets/sprites/player/player_2_suit/" + path + ".png"
	if not ResourceLoader.exists(full):
		game.textures[path] = null
		return null
	var texture := load(full) as Texture2D
	game.textures[path] = texture
	return texture


## Cargas de Queimadura: chamas pequenas acima do alvo (cresce e pisca ao ganhar carga).
static func burn_pips(game: Node2D, center: Vector2, count: int, flash: float) -> void:
	if count <= 0:
		return
	var pip: Texture2D = _tex(game, "henry_burn_pip")
	var spacing := 11.0
	var start_x := -float(count - 1) * spacing * 0.5
	var pulse := 1.0 + clampf(flash * 2.2, 0.0, 0.45)
	var hot := count >= 5
	for index in range(count):
		var p := center + Vector2(start_x + float(index) * spacing, sin(game.time_alive * 7.0 + float(index)) * 1.5)
		if pip != null:
			var size := Vector2(14.0, 14.0) * pulse
			game.draw_texture_rect(pip, Rect2(p - size * 0.5, size), false)
		else:
			var height := 10.0 * pulse * (1.25 if hot else 1.0)
			var flick := sin(game.time_alive * 22.0 + float(index) * 1.7) * 1.2
			game.draw_colored_polygon(PackedVector2Array([p + Vector2(-4.0, 3.0), p + Vector2(4.0, 3.0), p + Vector2(flick, -height)]), Color(1.0, 0.3, 0.03, 0.95))
			game.draw_colored_polygon(PackedVector2Array([p + Vector2(-2.0, 2.5), p + Vector2(2.0, 2.5), p + Vector2(flick * 0.6, -height * 0.55)]), Color(1.0, 0.88, 0.3, 0.98))
	if hot:
		game.draw_arc(center + Vector2(0.0, 1.0), float(count) * spacing * 0.6, 0.0, TAU, 20, Color(1.0, 0.5, 0.1, 0.35 + 0.25 * sin(game.time_alive * 12.0)), 1.5, true)


## Rastro de Brasa: chao rachado em brasa com chamas baixas ao longo da trilha.
static func draw_ember_trail(game: Node2D, camera: Vector2, trail: Array) -> void:
	if trail.is_empty():
		return
	var patch: Texture2D = _tex(game, "henry_fire_patch")
	var low: bool = game._runtime_visual_budget_active() or not game.gfx_particles
	for index in range(trail.size()):
		var point: Dictionary = trail[index]
		var life := clampf(float(point.get("life", 0.0)) / maxf(0.01, float(point.get("max", 3.0))), 0.0, 1.0)
		var fade := smoothstep(0.0, 0.25, life)
		var pos: Vector2 = Vector2(point.get("pos", Vector2.ZERO)) - camera
		if patch != null:
			game.draw_texture_rect(patch, Rect2(pos - Vector2(40.0, 30.0), Vector2(80.0, 60.0)), false, Color(1.0, 1.0, 1.0, fade))
		else:
			game.draw_circle(pos, 30.0, Color(0.16, 0.04, 0.0, 0.42 * fade))
			game.draw_circle(pos, 20.0, Color(0.9, 0.26, 0.02, 0.32 * fade))
			for crack in range(3):
				var a := float(index * 3 + crack) * 2.1
				game.draw_line(pos, pos + Vector2.from_angle(a) * 22.0, Color(1.0, 0.6, 0.12, 0.7 * fade), 2.0, true)
		# Chamas baixas e irregulares (pula pontos e varia o tamanho para nao virar uma serra).
		if index % (3 if low else 2) == 0:
			var size_jitter := 0.6 + 0.4 * absf(sin(float(index) * 2.7))
			var side := Vector2(sin(float(index) * 4.1) * 10.0, 6.0)
			_flame(game, pos + side, Vector2.UP, 16.0 * size_jitter + 6.0, (14.0 + 16.0 * absf(sin(game.time_alive * 7.0 + float(index) * 1.3))) * size_jitter * (0.4 + 0.6 * fade), game.time_alive, index, fade * 0.85)


## Investida: rastro de fogo atras de Henry e sapatos em chamas.
static func dash(game: Node2D, center: Vector2, direction: Vector2, progress: float, alpha: float) -> void:
	var dir := direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	var fade := alpha * (1.0 - smoothstep(0.8, 1.0, progress))
	for index in range(5):
		var back := float(index + 1) * 16.0
		_flame(game, center - dir * back + Vector2(0.0, 20.0), (-dir + Vector2.UP * 0.6).normalized(), 26.0 - float(index) * 3.0, 40.0 - float(index) * 5.0, game.time_alive, index, fade * (1.0 - float(index) * 0.15))
	for side in [-1.0, 1.0]:
		_flame(game, center + Vector2(side * 10.0, 34.0), Vector2.UP, 12.0, 20.0, game.time_alive, int(side * 7.0), fade)


## Explosoes de Combustao (e da bola de fogo): anel de fogo + estilhacos de brasa.
static func draw_combustion(game: Node2D, camera: Vector2, bursts: Array) -> void:
	if bursts.is_empty():
		return
	var tex: Texture2D = _tex(game, "henry_combustion_burst")
	var low: bool = game._runtime_visual_budget_active() or not game.gfx_particles
	for burst_value in bursts:
		var burst: Dictionary = burst_value
		var u := 1.0 - clampf(float(burst.get("life", 0.0)) / maxf(0.01, float(burst.get("max", 0.5))), 0.0, 1.0)
		var center: Vector2 = Vector2(burst.get("pos", Vector2.ZERO)) - camera
		var radius: float = float(burst.get("radius", 80.0))
		var stacks: int = int(burst.get("stacks", 1))
		var r := radius * (0.35 + 0.65 * (1.0 - pow(1.0 - u, 2.0)))
		var fade := 1.0 - smoothstep(0.55, 1.0, u)
		if tex != null:
			game.draw_texture_rect(tex, Rect2(center - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1.0, 1.0, 1.0, fade))
			continue
		game.draw_circle(center, r * 0.55, Color(1.0, 0.82, 0.36, 0.55 * fade * (1.0 - u)))
		game.draw_arc(center, r, 0.0, TAU, 36, Color(1.0, 0.42, 0.06, 0.85 * fade), 5.0 + float(stacks), true)
		game.draw_arc(center, r * 0.82, 0.0, TAU, 32, Color(1.0, 0.82, 0.3, 0.55 * fade), 2.0, true)
		var shards: int = (6 if low else 10) + stacks
		for index in range(shards):
			var a := float(index) * TAU / float(shards) + float(stacks) * 0.4
			var p := center + Vector2.from_angle(a) * r * (0.9 + 0.25 * u)
			game.draw_line(p, p + Vector2.from_angle(a) * (8.0 + 10.0 * (1.0 - u)), Color(1.0, 0.66, 0.16, fade), 3.0, true)
		if not low:
			for index in range(4 + stacks):
				var a2 := float(index) * 2.399
				_flame(game, center + Vector2.from_angle(a2) * r * 0.6, (Vector2.from_angle(a2) * 0.4 + Vector2.UP).normalized(), 22.0, 30.0 * fade, game.time_alive, index, fade)



## Bola de fogo do 3o golpe: miolo claro, chamas para tras e brasas soltas.
static func fireball(game: Node2D, pos: Vector2, direction: Vector2) -> void:
	var dir := direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	var tex: Texture2D = _tex(game, "henry_fireball")
	if tex != null:
		game.draw_set_transform(pos, dir.angle(), Vector2.ONE)
		game.draw_texture_rect(tex, Rect2(Vector2(-34.0, -22.0), Vector2(44.0, 44.0)), false)
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	for index in range(3):
		_flame(game, pos - dir * (6.0 + float(index) * 9.0), -dir, 22.0 - float(index) * 5.0, 30.0 - float(index) * 6.0, game.time_alive, index, 0.9 - float(index) * 0.2)
	game.draw_circle(pos, 12.0, Color(1.0, 0.42, 0.06, 0.9))
	game.draw_circle(pos, 7.0, Color(1.0, 0.92, 0.6, 1.0))



const ULT_CRACK_COUNT := 9
const ULT_PULSE_TIMES := [0.7, 1.45, 2.2]
const ULT_PULSE_RADII := [150.0, 225.0, 300.0]


## Ignicao Total (durante o cast): carga no corpo antes do 1o impacto e rachaduras de magma que
## crescem a cada impacto (ficam acesas ate o fim).
static func ignition(game: Node2D, center: Vector2, elapsed: float, pulses: int) -> void:
	var low: bool = game._runtime_visual_budget_active() or not game.gfx_particles
	var feet := center + Vector2(0.0, 30.0)
	# Carga: brasas sugadas para os punhos e chamas subindo pelas pernas.
	var next_index: int = clampi(pulses, 0, 2)
	var next_time: float = float(ULT_PULSE_TIMES[next_index])
	var prev_time: float = 0.0 if next_index == 0 else float(ULT_PULSE_TIMES[next_index - 1]) + 0.1
	var charge: float = clampf((elapsed - prev_time) / maxf(0.05, next_time - prev_time), 0.0, 1.0) if pulses < 3 else 0.0
	if charge > 0.0:
		for index in range(5 if low else 10):
			var a := float(index) * 2.399 + elapsed * 3.0
			var travel := fposmod(elapsed * 1.8 + float(index) * 0.13, 1.0)
			var p := center + Vector2.from_angle(a) * lerpf(110.0, 16.0, travel)
			game.draw_circle(p, 2.5, Color(1.0, 0.62, 0.12, charge * sin(travel * PI)))
		game.draw_circle(feet, 26.0 + 10.0 * charge, Color(1.0, 0.36, 0.04, 0.14 + 0.18 * charge))
	# Rachaduras: crescem ate o raio do ultimo impacto liberado.
	if pulses <= 0:
		return
	var reach: float = float(ULT_PULSE_RADII[clampi(pulses - 1, 0, 2)])
	var since: float = elapsed - float(ULT_PULSE_TIMES[clampi(pulses - 1, 0, 2)])
	var grow: float = clampf(since / 0.18, 0.0, 1.0)
	var prev_reach: float = 0.0 if pulses <= 1 else float(ULT_PULSE_RADII[pulses - 2])
	var r: float = lerpf(prev_reach, reach, grow)
	var cracks: Texture2D = _tex(game, "henry_ground_cracks")
	var glow: float = 0.65 + 0.35 * sin(elapsed * 14.0)
	if cracks != null:
		game.draw_texture_rect(cracks, Rect2(feet - Vector2(r, r * 0.62), Vector2(r * 2.0, r * 1.24)), false, Color(1.0, 1.0, 1.0, 0.9))
		return
	for index in range(ULT_CRACK_COUNT):
		var a2 := float(index) * TAU / float(ULT_CRACK_COUNT) + 0.31
		var points := PackedVector2Array([feet])
		var segments := 5
		for step in range(1, segments + 1):
			var u := float(step) / float(segments)
			var wobble := sin(float(index) * 3.7 + float(step) * 1.9) * 0.22
			points.append(feet + Vector2.from_angle(a2 + wobble) * r * u * Vector2(1.0, 0.62))
		game.draw_polyline(points, Color(0.18, 0.04, 0.0, 0.85), 7.0, true)
		game.draw_polyline(points, Color(1.0, 0.42 + 0.2 * glow, 0.06, 0.9), 3.0, true)
	game.draw_circle(feet, 18.0 + 6.0 * glow, Color(1.0, 0.7, 0.2, 0.5))


## Impacto da Ignicao Total: anel de colunas de fogo irrompendo na borda, onda de choque e brasas.
static func eruption(game: Node2D, center: Vector2, radius: float, max_radius: float, pulse: int) -> void:
	var low: bool = game._runtime_visual_budget_active() or not game.gfx_particles
	var p := clampf(radius / maxf(1.0, max_radius), 0.0, 1.0)
	var feet := center + Vector2(0.0, 30.0)
	var fade := 1.0 - smoothstep(0.7, 1.0, p)
	var squash := Vector2(1.0, 0.62)
	# Onda de choque no chao (elipse = perspectiva top-down 3/4).
	var front: float = max_radius * (1.0 - pow(1.0 - p, 2.4))
	_draw_ellipse_ring(game, feet, front, squash, Color(1.0, 0.78, 0.34, 0.75 * fade), 4.0 + float(pulse) * 2.0)
	_draw_ellipse_ring(game, feet, front * 0.86, squash, Color(1.0, 0.34, 0.04, 0.5 * fade), 9.0)
	# Colunas de fogo: sobem rapido e caem, escalonadas pelo angulo; mais colunas a cada impacto.
	var count: int = (8 + pulse * 3) if low else (12 + pulse * 5)
	var pillar: Texture2D = _tex(game, "henry_fire_pillar")
	for index in range(count):
		var a := float(index) * TAU / float(count) + float(pulse) * 0.37
		var delay := fposmod(float(index) * 0.37, 1.0) * 0.25
		var local := clampf((p - delay) / 0.55, 0.0, 1.0)
		if local <= 0.0:
			continue
		var rise := sin(local * PI)
		var base := feet + Vector2.from_angle(a) * max_radius * squash
		var height := (70.0 + 30.0 * float(pulse)) * rise
		if pillar != null:
			var w := 30.0 + 6.0 * float(pulse)
			game.draw_texture_rect(pillar, Rect2(base - Vector2(w * 0.5, height), Vector2(w, height)), false, Color(1.0, 1.0, 1.0, fade))
		else:
			_flame(game, base, Vector2.UP, 26.0 + 5.0 * float(pulse), height, game.time_alive, index + pulse * 17, fade)
			game.draw_circle(base, 10.0 * rise, Color(1.0, 0.86, 0.4, 0.7 * fade))
	# Brasas voando para fora.
	if not low:
		for index in range(10 + pulse * 4):
			var a3 := float(index) * 2.399 + float(pulse)
			var travel := clampf(p * 1.2 - fposmod(float(index) * 0.11, 0.3), 0.0, 1.0)
			var pos := feet + Vector2.from_angle(a3) * max_radius * travel * squash + Vector2(0.0, -sin(travel * PI) * 40.0)
			game.draw_rect(Rect2(pos, Vector2(3, 3)), Color(1.0, 0.7, 0.2, fade * (1.0 - travel)))


static func _draw_ellipse_ring(game: Node2D, center: Vector2, radius: float, squash: Vector2, color: Color, width: float) -> void:
	if radius < 2.0 or color.a <= 0.01:
		return
	var points := PackedVector2Array()
	for index in range(41):
		points.append(center + Vector2.from_angle(float(index) * TAU / 40.0) * radius * squash)
	game.draw_polyline(points, color, width, true)
