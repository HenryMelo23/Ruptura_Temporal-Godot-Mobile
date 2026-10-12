class_name RTPhase2SineiroPresentation
extends RefCounted

const MOTION_COLUMNS := 6
const MOTION_ROWS := 4
const DEATH_COLUMNS := 6

static var _motion_frames: Array = []
static var _death_frames: Array = []
static var _motion_source_id := 0
static var _death_source_id := 0


static func enemy_texture(game: Node2D, enemy: Dictionary) -> Texture2D:
	var source: Texture2D = game.textures.get("sineiro_boreal_motion")
	if source == null:
		return null
	_ensure_motion_frames(source)
	if _motion_frames.is_empty():
		return source
	var frame := _motion_frame_index(game, enemy)
	return _motion_frames[clampi(frame, 0, _motion_frames.size() - 1)]


static func draw_world(game: Node2D, camera: Vector2) -> void:
	_draw_echo_marks(game, camera)
	_draw_visual_events(game, camera)
	_draw_shard_projectiles(game, camera)


static func _motion_frame_index(game: Node2D, enemy: Dictionary) -> int:
	var anim_time := float(enemy.get("sineiro_anim_time", game.time_alive))
	if game.time_alive - float(enemy.get("last_damage_time", -100.0)) < 0.20:
		return 4 + int(anim_time * 11.0) % 2
	var state := String(enemy.get("sineiro_state", "approach"))
	if state == "exhausted":
		return 21 + int(anim_time * 5.0) % 3
	if state == "telegraph":
		var kind := String(enemy.get("sineiro_attack_kind", ""))
		if float(enemy.get("sineiro_state_timer", 0.0)) <= 0.16:
			return 17
		return 12 + int(anim_time * (7.0 if kind == "badalada_passado" else 8.5)) % 5
	if float(enemy.get("sineiro_attack_anim_timer", 0.0)) > 0.0:
		return 18 + int(anim_time * 12.0) % 3
	if Vector2(enemy.get("last_move_dir", Vector2.ZERO)).length_squared() > 0.01:
		return 6 + int(anim_time * 8.0) % 6
	return int(anim_time * 4.5) % 4


static func _ensure_motion_frames(source: Texture2D) -> void:
	var source_id := source.get_instance_id()
	if source_id == _motion_source_id and _motion_frames.size() == MOTION_COLUMNS * MOTION_ROWS:
		return
	_motion_source_id = source_id
	_motion_frames.clear()
	var cell := Vector2i(source.get_width() / MOTION_COLUMNS, source.get_height() / MOTION_ROWS)
	for row in range(MOTION_ROWS):
		for column in range(MOTION_COLUMNS):
			var frame := AtlasTexture.new()
			frame.atlas = source
			frame.region = Rect2i(Vector2i(column * cell.x, row * cell.y), cell)
			_motion_frames.append(frame)


static func _ensure_death_frames(source: Texture2D) -> void:
	var source_id := source.get_instance_id()
	if source_id == _death_source_id and _death_frames.size() == DEATH_COLUMNS:
		return
	_death_source_id = source_id
	_death_frames.clear()
	var cell := Vector2i(source.get_width() / DEATH_COLUMNS, source.get_height())
	for column in range(DEATH_COLUMNS):
		var frame := AtlasTexture.new()
		frame.atlas = source
		frame.region = Rect2i(Vector2i(column * cell.x, 0), cell)
		_death_frames.append(frame)


static func _draw_echo_marks(game: Node2D, camera: Vector2) -> void:
	for mark_value in game.sineiro_echo_marks:
		var mark: Dictionary = mark_value
		var pos := Vector2(mark.get("pos", Vector2.ZERO)) - camera
		if not game._world_point_in_view(Vector2(mark.get("pos", Vector2.ZERO)), camera, 100.0):
			continue
		var radius := float(mark.get("radius", 48.0))
		var age := float(mark.get("age", 0.0))
		var max_life := maxf(0.01, float(mark.get("max_life", 1.1)))
		var progress := clampf(age / max_life, 0.0, 1.0)
		var impact := String(mark.get("phase", "telegraph")) == "impact"
		var pulse := 0.72 + sin(game.time_alive * 13.0 + pos.x * 0.01) * 0.12
		var alpha := (1.0 - progress) if impact else (0.55 + progress * 0.34)
		game.draw_circle(pos, radius * (0.88 + progress * 0.12), Color(0.10, 0.32, 0.46, 0.16 * alpha))
		var points := PackedVector2Array()
		for index in range(8):
			var angle := float(index) * TAU / 8.0 - PI * 0.5
			var jag := radius * (0.80 if index % 2 == 0 else 1.0)
			points.append(pos + Vector2.from_angle(angle) * jag)
		points.append(points[0])
		game.draw_polyline(points, Color(0.44, 0.94, 1.0, alpha * pulse), 3.0, true)
		for index in range(4 if game.gfx_low_resource else 7):
			var angle := float(index) * TAU / float(4 if game.gfx_low_resource else 7) + age * 0.65
			var tip := pos + Vector2.from_angle(angle) * radius * (0.35 + progress * 0.48)
			var side := Vector2.from_angle(angle + PI * 0.5) * 4.0
			game.draw_colored_polygon(PackedVector2Array([pos + side, tip, pos - side]), Color(0.58, 0.88, 1.0, alpha * 0.74))
		if impact:
			for index in range(6 if game.gfx_low_resource else 10):
				var direction := Vector2.from_angle(float(index) * TAU / float(6 if game.gfx_low_resource else 10) + 0.25)
				game.draw_line(pos + direction * radius * 0.42, pos + direction * radius * (0.85 + progress * 0.7), Color(0.76, 0.96, 1.0, alpha), 3.0)


static func _draw_visual_events(game: Node2D, camera: Vector2) -> void:
	for event_value in game.sineiro_visual_events:
		var event: Dictionary = event_value
		var world_pos := Vector2(event.get("pos", Vector2.ZERO))
		if not game._world_point_in_view(world_pos, camera, 220.0):
			continue
		var pos := world_pos - camera
		var age := float(event.get("age", 0.0))
		var max_life := maxf(0.01, float(event.get("max_life", 1.0)))
		var progress := clampf(age / max_life, 0.0, 1.0)
		var fade := 1.0 - progress
		match String(event.get("kind", "")):
			"entry":
				_draw_entry_ice(game, pos, progress, fade)
			"shard_prepare":
				_draw_shard_lane(game, pos, Vector2(event.get("dir", Vector2.LEFT)), progress, fade)
			"shard_attack":
				_draw_sound_wave(game, pos, Vector2(event.get("dir", Vector2.LEFT)), progress, fade)
			"death":
				_draw_death(game, pos, progress, fade)
			"dissipate":
				_draw_dissipate(game, pos, progress, fade)


static func _draw_entry_ice(game: Node2D, pos: Vector2, progress: float, fade: float) -> void:
	var growth := maxf(0.08, minf(1.0, progress * 3.0))
	for index in range(5 if game.gfx_low_resource else 8):
		var angle := float(index) * TAU / float(5 if game.gfx_low_resource else 8)
		var root := pos + Vector2.from_angle(angle) * (34.0 + progress * 42.0)
		var side := Vector2(7.0, 0.0)
		var tip := root + Vector2(0.0, -28.0 - float(index % 3) * 9.0) * growth
		game.draw_colored_polygon(PackedVector2Array([root - side, root + side, tip]), Color(0.42, 0.88, 1.0, fade * 0.78))
	game.draw_arc(pos + Vector2(0, 18), 46.0 + progress * 52.0, 0.0, TAU, 32, Color(0.58, 0.92, 1.0, fade * 0.65), 3.0)


static func _draw_shard_lane(game: Node2D, pos: Vector2, direction: Vector2, progress: float, fade: float) -> void:
	var dir := direction.normalized()
	var side := dir.orthogonal()
	for lane in [-1, 0, 1]:
		var lane_dir := dir.rotated(float(lane) * 0.18)
		var end := pos + lane_dir * (180.0 + progress * 140.0)
		game.draw_dashed_line(pos + side * float(lane) * 4.0, end, Color(0.56, 0.92, 1.0, 0.28 + progress * 0.52), 3.0, 10.0)
		var arrow_side := lane_dir.orthogonal() * 8.0
		game.draw_colored_polygon(PackedVector2Array([end, end - lane_dir * 20.0 + arrow_side, end - lane_dir * 20.0 - arrow_side]), Color(0.74, 0.96, 1.0, fade * 0.88))


static func _draw_sound_wave(game: Node2D, pos: Vector2, direction: Vector2, progress: float, fade: float) -> void:
	var dir := direction.normalized()
	for index in range(3):
		var center := pos + dir * (28.0 + progress * (85.0 + index * 28.0))
		game.draw_arc(center, 18.0 + progress * (22.0 + index * 7.0), -1.15, 1.15, 14, Color(0.72, 0.92, 1.0, fade * (0.78 - index * 0.16)), 3.0)


static func _draw_shard_projectiles(game: Node2D, camera: Vector2) -> void:
	for bullet_value in game.enemy_bullets:
		var bullet: Dictionary = bullet_value
		if String(bullet.get("type", "")) != "sineiro_shard":
			continue
		var world_pos := Vector2(bullet.get("pos", Vector2.ZERO))
		if not game._world_point_in_view(world_pos, camera, 90.0):
			continue
		var pos := world_pos - camera
		var dir := Vector2(bullet.get("dir", Vector2.RIGHT)).normalized()
		var side := dir.orthogonal()
		game.draw_line(pos - dir * 28.0, pos - dir * 6.0, Color(0.36, 0.78, 1.0, 0.34), 6.0)
		game.draw_colored_polygon(PackedVector2Array([pos + dir * 17.0, pos - dir * 12.0 + side * 8.0, pos - dir * 6.0, pos - dir * 12.0 - side * 8.0]), Color(0.64, 0.94, 1.0, 0.96))
		game.draw_polyline(PackedVector2Array([pos + dir * 17.0, pos - dir * 12.0 + side * 8.0, pos - dir * 12.0 - side * 8.0, pos + dir * 17.0]), Color(0.18, 0.42, 0.64, 0.95), 2.0)


static func _draw_death(game: Node2D, pos: Vector2, progress: float, fade: float) -> void:
	var source: Texture2D = game.textures.get("sineiro_boreal_death")
	if source != null:
		_ensure_death_frames(source)
		if not _death_frames.is_empty():
			var frame_index := mini(DEATH_COLUMNS - 1, int(progress * float(DEATH_COLUMNS)))
			game._draw_entity(_death_frames[frame_index], pos, Vector2(124, 148), Color(1.0, 1.0, 1.0, maxf(0.28, fade)), false)
	for index in range(5 if game.gfx_low_resource else 9):
		var direction := Vector2.from_angle(float(index) * TAU / float(5 if game.gfx_low_resource else 9) + 0.4)
		var shard_pos := pos + direction * progress * (42.0 + index * 5.0)
		game.draw_line(shard_pos, shard_pos + direction * (12.0 + progress * 10.0), Color(0.58, 0.92, 1.0, fade), 3.0)


static func _draw_dissipate(game: Node2D, pos: Vector2, progress: float, fade: float) -> void:
	game.draw_arc(pos, 38.0 + progress * 56.0, 0.0, TAU, 30, Color(0.46, 0.82, 1.0, fade * 0.72), 3.0)
	for index in range(4 if game.gfx_low_resource else 7):
		var direction := Vector2.from_angle(float(index) * TAU / float(4 if game.gfx_low_resource else 7))
		game.draw_circle(pos + direction * progress * 72.0, 3.0 + float(index % 2), Color(0.72, 0.94, 1.0, fade))
