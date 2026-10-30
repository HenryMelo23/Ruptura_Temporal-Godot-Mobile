extends RefCounted

const MOTION_RESULTS_PATH := "res://assets/sprites/bargain_capsule/bargain_capsule_motion_results.png"
const IDLE_DAMAGE_PATH := "res://assets/sprites/bargain_capsule/bargain_capsule_idle_damage.png"
const HIT_REACTION_PATH := "res://assets/sprites/bargain_capsule/bargain_capsule_hit.png"

static var _motion_results: Texture2D
static var _idle_damage: Texture2D
static var _hit_reaction: Texture2D

const MOTION_FRAME_SIZE := Vector2(96.0, 96.0)
const IDLE_FRAME_SIZE := Vector2(96.0, 128.0)
const HIT_FRAME_SIZE := Vector2(96.0, 96.0)
const FRAME_COUNT := 6
const IMPACT_DURATION := 0.30
const HIT_DURATION := 0.22
const RESULT_DURATION := 1.08

static var _local_state_started_msec: Dictionary = {}


static func _state_age(capsule: Dictionary) -> float:
	var event_id: String = String(capsule.get("id", "capsule"))
	var state: String = String(capsule.get("state", ""))
	var key: String = "%s:%s" % [event_id, state]
	var now_msec: int = Time.get_ticks_msec()
	var remote_age: float = maxf(0.0, float(capsule.get("visual_state_age", 0.0)))
	if not _local_state_started_msec.has(key):
		if _local_state_started_msec.size() >= 24:
			_local_state_started_msec.clear()
		_local_state_started_msec[key] = now_msec - int(remote_age * 1000.0)
	var local_age: float = maxf(0.0, float(now_msec - int(_local_state_started_msec[key])) * 0.001)
	return maxf(remote_age, local_age)


static func _frame_for_progress(progress: float, frame_count: int = FRAME_COUNT) -> int:
	return clampi(int(floor(clampf(progress, 0.0, 0.9999) * float(frame_count))), 0, frame_count - 1)


static func _texture(path: String, cached: Texture2D) -> Texture2D:
	if cached != null:
		return cached
	var resource := ResourceLoader.load(path)
	return resource as Texture2D


static func _draw_frame(game: Node2D, texture: Texture2D, frame_size: Vector2, row: int, frame: int, center: Vector2, modulate: Color = Color.WHITE) -> void:
	var source := Rect2(Vector2(float(frame) * frame_size.x, float(row) * frame_size.y), frame_size)
	var destination := Rect2(center - frame_size * 0.5, frame_size)
	game.draw_texture_rect_region(texture, destination, source, modulate, false, true)


static func _draw_landing_mark(game: Node2D, pos: Vector2, progress: float, radius: float, seed: int) -> void:
	var pulse: float = 0.5 + 0.5 * sin(progress * PI * 5.0)
	var outer_radius: float = radius * lerpf(1.62, 1.24, progress)
	game.draw_circle(pos, radius * (1.05 + progress * 0.2), Color(0.18, 0.08, 0.01, 0.12 + progress * 0.08))
	game.draw_arc(pos, outer_radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, Color(1.0, 0.76, 0.18, 0.64 + pulse * 0.22), 3.0, true)
	game.draw_arc(pos, radius * (0.72 + pulse * 0.06), PI * 0.5, PI * 0.5 + TAU * progress, 28, Color(1.0, 0.9, 0.48, 0.46), 2.0, true)
	var fragment_count: int = 4 if bool(game.gfx_low_resource) else 8
	for i in range(fragment_count):
		var angle: float = TAU * float(i) / float(fragment_count) + float(seed % 17) * 0.07
		var distance: float = lerpf(radius * 1.7, radius * 0.72, progress) + sin(float(i) * 2.1 + progress * 8.0) * 3.0
		var fragment_pos: Vector2 = pos + Vector2.from_angle(angle) * distance
		var fragment_size: float = 2.0 + float(i % 2)
		game.draw_rect(Rect2(fragment_pos - Vector2.ONE * fragment_size * 0.5, Vector2.ONE * fragment_size), Color(1.0, 0.78, 0.22, 0.42 + progress * 0.45), true)


static func _draw_shadow(game: Node2D, ground_pos: Vector2, scale: float, alpha: float) -> void:
	game.draw_set_transform(ground_pos + Vector2(0.0, 30.0), 0.0, Vector2(1.0, 0.38))
	game.draw_circle(Vector2.ZERO, 35.0 * scale, Color(0.035, 0.02, 0.025, alpha))
	game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_bars(game: Node2D, pos: Vector2, capsule: Dictionary) -> void:
	var hp_ratio: float = clampf(float(capsule.get("hp", 0.0)) / maxf(1.0, float(capsule.get("max_hp", 1.0))), 0.0, 1.0)
	var time_ratio: float = clampf(float(capsule.get("collapse_time", 0.0)) / maxf(1.0, float(capsule.get("collapse_max", 1.0))), 0.0, 1.0)
	var bar_width: float = 86.0
	var hp_rect := Rect2(pos + Vector2(-bar_width * 0.5, -72.0), Vector2(bar_width, 7.0))
	var time_rect := Rect2(pos + Vector2(-bar_width * 0.5, -61.0), Vector2(bar_width, 6.0))
	game.draw_rect(hp_rect, Color(0.04, 0.01, 0.0, 0.78), true)
	game.draw_rect(Rect2(hp_rect.position, Vector2(hp_rect.size.x * hp_ratio, hp_rect.size.y)), Color(1.0, 0.58, 0.18, 0.96), true)
	game.draw_rect(hp_rect, Color(1.0, 0.86, 0.24, 0.7), false, 1.0)
	game.draw_rect(time_rect, Color(0.02, 0.02, 0.05, 0.78), true)
	game.draw_rect(Rect2(time_rect.position, Vector2(time_rect.size.x * time_ratio, time_rect.size.y)), Color(0.35, 0.86, 1.0, 0.92), true)
	game.draw_rect(time_rect, Color(0.64, 0.95, 1.0, 0.58), false, 1.0)


static func draw(game: Node2D, camera: Vector2) -> void:
	_motion_results = _texture(MOTION_RESULTS_PATH, _motion_results)
	_idle_damage = _texture(IDLE_DAMAGE_PATH, _idle_damage)
	_hit_reaction = _texture(HIT_REACTION_PATH, _hit_reaction)
	if _motion_results == null or _idle_damage == null or _hit_reaction == null:
		return
	var capsules: Array = Array(game.bargain_capsule.get("capsules", [])) if game.bargain_capsule.has("capsules") else [game.bargain_capsule]
	for capsule_value in capsules:
		if capsule_value is Dictionary:
			_draw_capsule(game, camera, Dictionary(capsule_value))


static func _draw_capsule(game: Node2D, camera: Vector2, capsule: Dictionary) -> void:
	if capsule.is_empty():
		return
	var state: String = String(capsule.get("state", ""))
	if state == "destroyed":
		state = game.BARGAIN_CAPSULE_STATE_FAIL
	if state == game.BARGAIN_CAPSULE_STATE_NONE:
		return
	var world_pos: Vector2 = Vector2(capsule.get("pos", game.player_pos))
	if not game._world_point_in_view(world_pos, camera, 180.0):
		return
	var ground_pos: Vector2 = world_pos - camera
	var radius: float = game.BARGAIN_CAPSULE_RADIUS
	var seed: int = int(capsule.get("seed", 0))
	var state_age: float = _state_age(capsule)

	if state == game.BARGAIN_CAPSULE_STATE_PREPARING:
		var prepare_progress: float = 1.0 - clampf(float(capsule.get("timer", 0.0)) / maxf(0.01, game.BARGAIN_CAPSULE_PREPARE_TIME), 0.0, 1.0)
		_draw_landing_mark(game, ground_pos, prepare_progress, radius, seed)
		return

	if state == game.BARGAIN_CAPSULE_STATE_FALLING:
		var fall_progress: float = 1.0 - clampf(float(capsule.get("timer", 0.0)) / maxf(0.01, game.BARGAIN_CAPSULE_FALL_TIME), 0.0, 1.0)
		var gravity_progress: float = fall_progress * fall_progress
		var sprite_pos: Vector2 = ground_pos + Vector2(sin(fall_progress * TAU * 1.25 + float(seed % 11)) * 2.5, -(1.0 - gravity_progress) * 180.0)
		_draw_shadow(game, ground_pos, lerpf(0.48, 1.0, gravity_progress), lerpf(0.10, 0.30, gravity_progress))
		_draw_frame(game, _motion_results, MOTION_FRAME_SIZE, 0, _frame_for_progress(fall_progress), sprite_pos)
		return

	if state == game.BARGAIN_CAPSULE_STATE_SUCCESS or state == game.BARGAIN_CAPSULE_STATE_FAIL:
		var result_progress: float = clampf(state_age / RESULT_DURATION, 0.0, 1.0)
		var result_row: int = 2 if state == game.BARGAIN_CAPSULE_STATE_SUCCESS else 3
		var result_alpha: float = 1.0 - maxf(0.0, (result_progress - 0.78) / 0.22)
		_draw_shadow(game, ground_pos, lerpf(1.0, 0.54, result_progress), 0.24 * result_alpha)
		_draw_frame(game, _motion_results, MOTION_FRAME_SIZE, result_row, _frame_for_progress(result_progress), ground_pos, Color(1.0, 1.0, 1.0, result_alpha))
		return

	if state == game.BARGAIN_CAPSULE_STATE_CLEANUP:
		return

	_draw_shadow(game, ground_pos, 1.0, 0.28)
	if state_age < IMPACT_DURATION:
		_draw_frame(game, _motion_results, MOTION_FRAME_SIZE, 1, _frame_for_progress(state_age / IMPACT_DURATION), ground_pos)
	else:
		var hit_flash: float = clampf(float(capsule.get("hit_flash", 0.0)), 0.0, HIT_DURATION)
		if hit_flash > 0.0:
			var hit_progress: float = 1.0 - hit_flash / HIT_DURATION
			_draw_frame(game, _hit_reaction, HIT_FRAME_SIZE, 0, _frame_for_progress(hit_progress, 4), ground_pos)
		else:
			var hp_ratio: float = clampf(float(capsule.get("hp", 0.0)) / maxf(1.0, float(capsule.get("max_hp", 1.0))), 0.0, 1.0)
			var damage_row: int = 0
			if hp_ratio < 0.35:
				damage_row = 2
			elif hp_ratio <= 0.70:
				damage_row = 1
			var idle_rate: float = 3.2 if bool(game.gfx_low_resource) else 5.0
			var idle_frame: int = posmod(int(floor((game.time_alive + float(seed % 23) * 0.03) * idle_rate)), FRAME_COUNT)
			_draw_frame(game, _idle_damage, IDLE_FRAME_SIZE, damage_row, idle_frame, ground_pos)
	_draw_bars(game, ground_pos, capsule)
