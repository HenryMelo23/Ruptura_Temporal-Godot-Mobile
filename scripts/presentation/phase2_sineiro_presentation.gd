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


## Paleta aurora (verde-agua + violeta) com contorno escuro: le bem sobre o gelo claro.
const AURORA := Color(0.36, 1.0, 0.78)
const VIOLET := Color(0.72, 0.42, 1.0)
const FROST := Color(0.86, 0.98, 1.0)
const INK := Color(0.02, 0.05, 0.12)


static func draw_world(game: Node2D, camera: Vector2) -> void:
	_draw_aura(game, camera)
	_draw_echo_marks(game, camera)
	_draw_visual_events(game, camera)
	_draw_shard_projectiles(game, camera)


static func _ring_ink(game: Node2D, pos: Vector2, radius: float, color: Color, width: float, segments: int = 48) -> void:
	game.draw_arc(pos, radius, 0.0, TAU, segments, Color(INK, color.a * 0.7), width + 4.0, true)
	game.draw_arc(pos, radius, 0.0, TAU, segments, color, width, true)


## Presenca: aurora girando aos pes e pulso de badalada para ele nao sumir no mapa.
static func _draw_aura(game: Node2D, camera: Vector2) -> void:
	var t: float = float(game.time_alive)
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if String(enemy.get("type", "")) != "sineiro_boreal":
			continue
		var world: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
		if not game._world_point_in_view(world, camera, 160.0):
			continue
		var foot: Vector2 = world - camera + Vector2(0, 46)
		game.draw_set_transform(foot, 0.0, Vector2(1.0, 0.4))
		game.draw_circle(Vector2.ZERO, 70.0, Color(INK, 0.28))
		for band in range(3):
			var a: float = t * (0.9 + band * 0.25) + band * 2.1
			var col: Color = AURORA.lerp(VIOLET, float(band) / 2.0)
			game.draw_arc(Vector2.ZERO, 58.0 + band * 7.0, a, a + PI * 1.1, 32, Color(col, 0.75), 3.0, true)
		game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var toll: float = fposmod(t * 0.6, 1.0)
		game.draw_arc(world - camera + Vector2(0, -20), 40.0 + toll * 90.0, 0.0, TAU, 40, Color(AURORA, 0.4 * (1.0 - toll)), 2.0, true)


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
	var low: bool = game.gfx_low_resource
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
		if not impact:
			# Eco do passado: circulo escuro, contagem enchendo e um sino no centro.
			var pulse := 0.5 + 0.5 * sin(game.time_alive * (10.0 + progress * 16.0))
			game.draw_circle(pos, radius, Color(INK, 0.32 + progress * 0.22))
			game.draw_circle(pos, radius * progress, Color(VIOLET, 0.16 + progress * 0.14))
			_ring_ink(game, pos, radius, Color(AURORA, 0.85), 3.0)
			game.draw_arc(pos, radius - 8.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, Color(FROST, 0.95), 4.0, true)
			var bell := pos + Vector2(0, -4)
			var bw: float = 11.0 + pulse * 2.0
			game.draw_colored_polygon(PackedVector2Array([bell + Vector2(-bw * 0.55, -12), bell + Vector2(bw * 0.55, -12), bell + Vector2(bw, 8), bell + Vector2(-bw, 8)]), Color(FROST, 0.75 + progress * 0.25))
			game.draw_circle(bell + Vector2(0, 11), 3.5, Color(VIOLET, 0.95))
			for index in range(4 if low else 7):
				var angle := float(index) * TAU / float(4 if low else 7) + age * 1.4
				var shard := pos + Vector2.from_angle(angle) * radius * 0.82
				game.draw_colored_polygon(PackedVector2Array([shard + Vector2(-4, 4), shard + Vector2(4, 4), shard + Vector2(0, -10 - progress * 8.0)]), Color(AURORA, 0.7))
		else:
			# Impacto: estacas de gelo subindo e anel estourando.
			var fade := 1.0 - progress
			game.draw_circle(pos, radius * (1.0 + progress * 0.4), Color(FROST, 0.3 * fade))
			_ring_ink(game, pos, radius * (1.0 + progress * 0.7), Color(AURORA, 0.9 * fade), 4.0)
			for index in range(7 if low else 12):
				var angle := float(index) * TAU / float(7 if low else 12) + 0.25
				var base := pos + Vector2.from_angle(angle) * radius * 0.45
				var tip := base + Vector2.from_angle(angle) * radius * 0.4 + Vector2(0, -30.0 - float(index % 3) * 12.0) * (0.4 + fade * 0.6)
				var side := Vector2.from_angle(angle).orthogonal() * 6.0
				game.draw_colored_polygon(PackedVector2Array([base + side, tip, base - side]), Color(INK, 0.7 * fade))
				game.draw_colored_polygon(PackedVector2Array([base + side * 0.6, tip, base - side * 0.6]), Color(FROST, 0.95 * fade))


static func _draw_visual_events(game: Node2D, camera: Vector2) -> void:
	for event_value in game.sineiro_visual_events:
		var event: Dictionary = event_value
		var world_pos := Vector2(event.get("pos", Vector2.ZERO))
		if String(event.get("kind", "")) != "ring_release" and not game._world_point_in_view(world_pos, camera, 220.0):
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
			"ring_prepare":
				_draw_ring_prepare(game, pos, progress)
			"ring_release":
				_draw_ring_release(game, pos, age, fade)
			"call_origin":
				_draw_call_origin(game, pos, progress)
			"call_dest":
				_draw_call_dest(game, pos, progress)
			"call_arrive":
				_draw_call_arrive(game, pos, progress, fade)
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
	for spread in RTPhase2SineiroBorealController.SHARD_SPREADS:
		var lane_dir := dir.rotated(float(spread))
		var start := pos + lane_dir * 40.0
		var end := pos + lane_dir * (220.0 + progress * 160.0)
		game.draw_line(start, end, Color(INK, 0.55), 7.0, true)
		game.draw_line(start, start.lerp(end, progress), Color(AURORA, 0.9), 3.0, true)
		game.draw_dashed_line(start, end, Color(FROST, 0.35 + progress * 0.4), 2.0, 12.0)
		var arrow_side := lane_dir.orthogonal() * 9.0
		game.draw_colored_polygon(PackedVector2Array([end + lane_dir * 6.0, end - lane_dir * 18.0 + arrow_side, end - lane_dir * 18.0 - arrow_side]), Color(INK, 0.7))
		game.draw_colored_polygon(PackedVector2Array([end, end - lane_dir * 16.0 + arrow_side * 0.8, end - lane_dir * 16.0 - arrow_side * 0.8]), Color(AURORA, 0.95))


static func _draw_ring_prepare(game: Node2D, pos: Vector2, progress: float) -> void:
	# O sino enche de luz e um anel fantasma mostra onde a onda vai passar.
	var center := pos + Vector2(0, -20)
	var pulse := 0.5 + 0.5 * sin(game.time_alive * (12.0 + progress * 20.0))
	game.draw_circle(center, 30.0 + progress * 26.0, Color(AURORA, 0.12 + progress * 0.2))
	_ring_ink(game, center, 34.0 + progress * 30.0 + pulse * 4.0, Color(FROST, 0.6 + progress * 0.35), 3.0)
	for i in range(3):
		var r: float = lerpf(140.0, 520.0, float(i) / 2.0)
		game.draw_arc(pos, r, 0.0, TAU, 72, Color(AURORA, 0.12 + progress * 0.16), 2.0, true)


static func _draw_ring_release(game: Node2D, pos: Vector2, age: float, fade: float) -> void:
	var r: float = 40.0 + age * RTPhase2SineiroBorealController.RING_SPEED
	var w: float = RTPhase2SineiroBorealController.RING_WIDTH
	var a: float = clampf(fade * 1.6, 0.0, 1.0)
	game.draw_arc(pos, r, 0.0, TAU, 96, Color(INK, 0.55 * a), w + 10.0, true)
	game.draw_arc(pos, r, 0.0, TAU, 96, Color(0.2, 0.55, 0.85, 0.6 * a), w, true)
	game.draw_arc(pos, r + w * 0.35, 0.0, TAU, 96, Color(AURORA, 0.9 * a), 4.0, true)
	game.draw_arc(pos, r - w * 0.4, 0.0, TAU, 96, Color(VIOLET, 0.7 * a), 2.5, true)
	var spikes: int = 18 if game.gfx_low_resource else 36
	for i in range(spikes):
		var ang := float(i) * TAU / float(spikes) + age * 0.4
		var base := pos + Vector2.from_angle(ang) * (r + w * 0.4)
		var tip := base + Vector2.from_angle(ang) * (10.0 + float(i % 3) * 6.0)
		var side := Vector2.from_angle(ang).orthogonal() * 4.0
		game.draw_colored_polygon(PackedVector2Array([base + side, tip, base - side]), Color(FROST, 0.9 * a))


static func _draw_call_origin(game: Node2D, pos: Vector2, progress: float) -> void:
	# Ele se desfaz numa coluna de luz de aurora.
	var top := pos + Vector2(0, -240)
	game.draw_line(pos, top, Color(AURORA, 0.25 + progress * 0.45), 26.0 * (1.0 - progress * 0.5), true)
	game.draw_line(pos, top, Color(FROST, 0.5 + progress * 0.4), 6.0, true)
	for i in range(8):
		var life := fposmod(progress * 1.6 + float(i) * 0.13, 1.0)
		game.draw_circle(pos + Vector2(sin(float(i) * 2.1) * 26.0, -life * 200.0), 3.0, Color(FROST, 0.8 * (1.0 - life)))


static func _draw_call_dest(game: Node2D, pos: Vector2, progress: float) -> void:
	# Circulo de chamada (floco/sino) crescendo onde ele vai aparecer: da para fugir dele.
	var r: float = lerpf(20.0, 70.0, progress)
	game.draw_circle(pos, r, Color(INK, 0.35))
	_ring_ink(game, pos, r, Color(AURORA, 0.9), 3.0)
	game.draw_arc(pos, r + 10.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, Color(VIOLET, 0.95), 4.0, true)
	for i in range(6):
		var ang := float(i) * TAU / 6.0 + progress * 2.0
		game.draw_line(pos + Vector2.from_angle(ang) * r * 0.25, pos + Vector2.from_angle(ang) * r * 0.85, Color(FROST, 0.85), 2.5, true)


static func _draw_call_arrive(game: Node2D, pos: Vector2, progress: float, fade: float) -> void:
	game.draw_circle(pos, 60.0 + progress * 80.0, Color(FROST, 0.35 * fade))
	_ring_ink(game, pos, 50.0 + progress * 140.0, Color(AURORA, 0.9 * fade), 5.0)


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
