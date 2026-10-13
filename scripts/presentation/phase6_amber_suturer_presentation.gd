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
	if game.time_alive - float(enemy.get("last_damage_time", -100.0)) < 0.20:
		row = ROW_DAMAGE
		fps = 10.0
	else:
		match state:
			"observe", "reposition":
				row = ROW_MOVE
				fps = 7.0
			"telegraph":
				row = ROW_PREPARE
				fps = 6.5
			"active":
				row = ROW_STITCH
				fps = 9.0
			"dying":
				row = ROW_DEATH
				fps = 5.0
	var column := int(anim_time * fps) % COLUMNS
	return _frames[row * COLUMNS + column]


static func draw_world(game: Node2D, camera: Vector2) -> void:
	_draw_sutures(game, camera)
	_draw_visual_events(game, camera)


static func draw_node(game: Node2D, enemy: Dictionary, camera: Vector2) -> void:
	var world_pos := Vector2(enemy.get("pos", Vector2.ZERO))
	if not game._world_point_in_view(world_pos, camera, 80.0):
		return
	var pos := world_pos - camera
	var hp_ratio := clampf(float(enemy.get("hp", 0.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0))), 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(game.time_alive * 8.0 + float(int(enemy.get("uid", 0)) % 31))
	var radius := 15.0 + pulse * 2.0
	var points := PackedVector2Array([
		pos + Vector2(0.0, -radius * 1.25),
		pos + Vector2(radius * 0.82, -2.0),
		pos + Vector2(radius * 0.44, radius),
		pos + Vector2(-radius * 0.44, radius),
		pos + Vector2(-radius * 0.82, -2.0),
	])
	game.draw_colored_polygon(points, Color(0.26, 0.16, 0.07, 0.98))
	var outline := PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[0]])
	game.draw_polyline(outline, Color(1.0, 0.72, 0.22, 0.92), 2.2, true)
	game.draw_line(pos + Vector2(-3.0, -radius), pos + Vector2(5.0, radius * 0.72), Color(0.94, 0.84, 0.62, 0.88), 3.0)
	for index in range(3):
		var angle: float = float(game.time_alive) * (0.45 if index % 2 == 0 else -0.38) + float(index) * TAU / 3.0
		var root := pos + Vector2.from_angle(angle) * (radius + 1.0)
		var tip := pos + Vector2.from_angle(angle + sin(game.time_alive + index) * 0.2) * (radius + 8.0 + pulse * 3.0)
		game.draw_line(root, tip, Color(0.42, 0.66, 0.18, 0.72), 2.0)
	var bar := Rect2(pos + Vector2(-22.0, -31.0), Vector2(44.0, 4.0))
	game.draw_rect(bar, Color(0.05, 0.04, 0.03, 0.86), true)
	game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * hp_ratio, bar.size.y)), Color(1.0, 0.62, 0.16, 0.94), true)
	if game._attack_target_is_enemy(int(enemy.get("uid", -1))):
		game._draw_attack_target_marker(pos + Vector2(0.0, 15.0), 22.0, true)


static func _draw_sutures(game: Node2D, camera: Vector2) -> void:
	for value in game.amber_sutures:
		var suture: Dictionary = value
		var a_world := Vector2(suture.get("a", Vector2.ZERO))
		var b_world := Vector2(suture.get("b", Vector2.ZERO))
		if not game._world_point_in_view(a_world.lerp(b_world, 0.5), camera, a_world.distance_to(b_world) * 0.5 + 80.0):
			continue
		var a := a_world - camera
		var b := b_world - camera
		var state := String(suture.get("state", "telegraph"))
		if state == "telegraph":
			_draw_telegraph(game, a, b, float(suture.get("timer", 0.0)))
		else:
			_draw_active(game, a, b, float(suture.get("timer", 0.0)), int(String(suture.get("id", "0")).hash()))


static func _draw_telegraph(game: Node2D, a: Vector2, b: Vector2, timer: float) -> void:
	var progress := 1.0 - clampf(timer / maxf(0.01, game.amber_suturer_controller.TELEGRAPH_TIME), 0.0, 1.0)
	var direction := b - a
	var length := direction.length()
	if length <= 1.0:
		return
	var normal := direction.normalized().orthogonal()
	var segments := 8 if game.gfx_low_resource or game.gfx_memory_saver else 13
	for index in range(segments):
		if index % 2 != 0:
			continue
		var start_t := float(index) / float(segments)
		var end_t := minf(1.0, float(index + 1) / float(segments))
		var wobble := sin(game.time_alive * 7.0 + index * 1.7) * 2.5
		game.draw_line(a.lerp(b, start_t) + normal * wobble, a.lerp(b, end_t) + normal * wobble, Color(1.0, 0.72, 0.22, 0.34 + progress * 0.52), 3.0)
	game.draw_line(a, b, Color(0.46, 0.78, 0.18, 0.08 + progress * 0.12), 10.0)
	_draw_endpoint_hint(game, a, progress)
	_draw_endpoint_hint(game, b, progress)


static func _draw_active(game: Node2D, a: Vector2, b: Vector2, timer: float, event_seed: int) -> void:
	var direction := b - a
	var length := direction.length()
	if length <= 1.0:
		return
	var normal := direction.normalized().orthogonal()
	var life_ratio := clampf(timer / maxf(0.01, game.amber_suturer_controller.ACTIVE_TIME), 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(game.time_alive * 10.0 + float(event_seed % 19))
	game.draw_line(a, b, Color(0.12, 0.08, 0.025, 0.72 * life_ratio), 13.0)
	var points := PackedVector2Array()
	var point_count := 7 if game.gfx_low_resource or game.gfx_memory_saver else 12
	for index in range(point_count + 1):
		var t := float(index) / float(point_count)
		var wobble := sin(float(index) * 2.3 + game.time_alive * 2.2 + event_seed * 0.01) * (2.0 + pulse * 2.0)
		points.append(a.lerp(b, t) + normal * wobble)
	game.draw_polyline(points, Color(0.72, 0.92, 0.24, 0.82 * life_ratio), 5.0 + pulse * 1.2, true)
	game.draw_polyline(points, Color(1.0, 0.68, 0.16, 0.88 * life_ratio), 2.0, true)
	var thorn_count := 5 if game.gfx_low_resource or game.gfx_memory_saver else 9
	for index in range(1, thorn_count + 1):
		var t := float(index) / float(thorn_count + 1)
		var root := a.lerp(b, t)
		var side := -1.0 if index % 2 == 0 else 1.0
		var tip := root + normal * side * (8.0 + pulse * 4.0)
		game.draw_line(root, tip, Color(0.92, 0.76, 0.42, 0.78 * life_ratio), 2.0)


static func _draw_endpoint_hint(game: Node2D, pos: Vector2, progress: float) -> void:
	var radius := 17.0 + progress * 5.0
	var diamond := PackedVector2Array([
		pos + Vector2(0.0, -radius),
		pos + Vector2(radius * 0.72, 0.0),
		pos + Vector2(0.0, radius),
		pos + Vector2(-radius * 0.72, 0.0),
		pos + Vector2(0.0, -radius),
	])
	game.draw_polyline(diamond, Color(1.0, 0.82, 0.34, 0.5 + progress * 0.38), 2.4, true)


static func _draw_visual_events(game: Node2D, camera: Vector2) -> void:
	for value in game.amber_suturer_visual_events:
		var event: Dictionary = value
		var world_pos := Vector2(event.get("pos", Vector2.ZERO))
		if not game._world_point_in_view(world_pos, camera, 180.0):
			continue
		var pos := world_pos - camera
		var age := float(event.get("age", 0.0))
		var max_life := maxf(0.01, float(event.get("max_life", 1.0)))
		var progress := clampf(age / max_life, 0.0, 1.0)
		var fade := 1.0 - progress
		var reduced_fx: bool = bool(game.gfx_low_resource or game.gfx_memory_saver)
		match String(event.get("kind", "")):
			"entry":
				for index in range(6 if reduced_fx else 10):
					var direction := Vector2.from_angle(float(index) * TAU / float(6 if reduced_fx else 10) + 0.22)
					game.draw_line(pos + direction * 24.0, pos + direction * (64.0 + progress * 55.0), Color(1.0, 0.62, 0.12, 0.72 * fade), 3.0)
			"activate":
				game.draw_arc(pos, 50.0 + progress * 92.0, 0.0, TAU, 48, Color(0.72, 1.0, 0.2, 0.72 * fade), 4.0)
			"break", "dissipate", "cleanup":
				for index in range(5 if reduced_fx else 8):
					var direction := Vector2.from_angle(float(index) * TAU / float(5 if reduced_fx else 8) - 0.35)
					game.draw_line(pos + direction * 5.0, pos + direction * (25.0 + progress * 46.0), Color(0.66, 0.86, 0.22, 0.66 * fade), 2.2)
			"death":
				_draw_death_frame(game, pos, progress, fade)


static func _draw_death_frame(game: Node2D, pos: Vector2, progress: float, fade: float) -> void:
	var source: Texture2D = game.textures.get("enemy_phase_6_suturador_ambar")
	if source == null:
		return
	_ensure_frames(source)
	var column := clampi(int(floor(progress * float(COLUMNS))), 0, COLUMNS - 1)
	var frame: Texture2D = _frames[ROW_DEATH * COLUMNS + column]
	game._draw_entity(frame, pos, Vector2(136.0, 94.0), Color(1.0, 1.0, 1.0, fade), false)


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
