class_name RTBoss1AnimationPresentation
extends RefCounted

const HIT_DURATION_MIN := 0.18
const HIT_DURATION_MAX := 0.28
const DEATH_DURATION := 1.65
const LANDING_FRAME_HOLD := 0.24
const DRAW_SIZE := Vector2(184.0, 170.0)


static func reset(game: Node2D) -> void:
	game.boss1_hit_animation_timer = 0.0
	game.boss1_hit_animation_duration = HIT_DURATION_MIN
	game.boss1_death_animation_timer = 0.0
	game.boss1_death_animation_duration = DEATH_DURATION
	game.boss1_death_animation_pos = Vector2.ZERO
	clear_siege_tide_jump(game)


static func update(game: Node2D, delta: float) -> void:
	game.boss1_hit_animation_timer = maxf(0.0, game.boss1_hit_animation_timer - delta)
	game.boss1_death_animation_timer = maxf(0.0, game.boss1_death_animation_timer - delta)
	game.boss1_siege_tide_jump_timer = maxf(0.0, game.boss1_siege_tide_jump_timer - delta)


static func trigger_siege_tide_jump(game: Node2D, event_id: String, duration: float) -> void:
	if event_id.is_empty() or duration <= 0.0:
		return
	if game.boss1_siege_tide_jump_event_id == event_id and game.boss1_siege_tide_jump_timer > 0.0:
		return
	game.boss1_siege_tide_jump_event_id = event_id
	game.boss1_siege_tide_jump_duration = duration
	game.boss1_siege_tide_jump_timer = duration


static func clear_siege_tide_jump(game: Node2D) -> void:
	game.boss1_siege_tide_jump_event_id = ""
	game.boss1_siege_tide_jump_timer = 0.0
	game.boss1_siege_tide_jump_duration = 0.0


static func siege_tide_jump_active(game: Node2D) -> bool:
	return game.current_phase == 1 and game.boss1_siege_tide_jump_timer > 0.0 and game.boss1_siege_tide_jump_duration > 0.0


static func trigger_hit(game: Node2D, damage: float) -> void:
	if game.current_phase != 1 or damage <= 0.0 or game.boss1_death_animation_timer > 0.0:
		return
	var severity: float = clampf(damage / maxf(1.0, game.boss_hp_max * 0.025), 0.0, 1.0)
	game.boss1_hit_animation_duration = lerpf(HIT_DURATION_MIN, HIT_DURATION_MAX, severity)
	# Repeated hits restart the short reaction instead of extending it without limit.
	game.boss1_hit_animation_timer = game.boss1_hit_animation_duration


static func trigger_death(game: Node2D, death_position: Vector2 = Vector2.INF) -> void:
	if game.current_phase != 1 or game.boss1_death_animation_timer > 0.0:
		return
	game.boss1_hit_animation_timer = 0.0
	game.boss1_death_animation_duration = DEATH_DURATION
	game.boss1_death_animation_timer = DEATH_DURATION
	game.boss1_death_animation_pos = game.boss_pos if not death_position.is_finite() else death_position


static func active_texture(game: Node2D) -> Texture2D:
	var jump_texture := _jump_texture(game)
	if jump_texture != null:
		return jump_texture
	if game.boss1_hit_animation_timer <= 0.0:
		return null
	return _timed_texture(
		game.textures.get("boss1_hit", []),
		game.boss1_hit_animation_timer,
		game.boss1_hit_animation_duration
	)


static func death_active(game: Node2D) -> bool:
	return game.current_phase == 1 and game.boss1_death_animation_timer > 0.0


static func draw_death(game: Node2D, camera: Vector2) -> void:
	var frames: Array = game.textures.get("boss1_death", [])
	var texture := _timed_texture(frames, game.boss1_death_animation_timer, game.boss1_death_animation_duration)
	if texture == null:
		return
	var progress: float = 1.0 - game.boss1_death_animation_timer / maxf(0.001, game.boss1_death_animation_duration)
	var center: Vector2 = game.boss1_death_animation_pos - camera
	var fade: float = 1.0 - clampf((progress - 0.86) / 0.14, 0.0, 1.0)
	var pulse: float = sin(progress * PI) * 0.045
	var size := DRAW_SIZE * (1.0 + pulse)
	if progress < 0.72:
		game._draw_dynamic_shadow_fit(texture, center + Vector2(0.0, 8.0), size, false, true, 0.34 * fade)
	game._draw_entity_fit(texture, center, size, Color(1.0, 1.0, 1.0, fade), true)
	if not game.gfx_low_resource and progress >= 0.16 and progress <= 0.88:
		var ring_radius: float = lerpf(42.0, 82.0, progress)
		game.draw_arc(center + Vector2(0.0, 7.0), ring_radius, -PI * 0.82, PI * 0.82, 28, Color(0.32, 0.82, 1.0, 0.34 * fade), 2.0, true)


static func _jump_texture(game: Node2D) -> Texture2D:
	var tide_texture := _siege_tide_jump_texture(game)
	if tide_texture != null:
		return tide_texture
	if game.boss_stage_timer <= 0.0:
		return null
	var frames: Array = game.textures.get("boss1_jump", [])
	if frames.is_empty():
		return null
	var elapsed: float = maxf(0.0, game.boss_stage_duration - game.boss_stage_timer)
	var frame_index := -1
	if elapsed <= game.BOSS_STAGE_SLAM_TIME:
		var progress: float = clampf(elapsed / maxf(0.001, game.BOSS_STAGE_SLAM_TIME), 0.0, 1.0)
		frame_index = clampi(int(floor(progress * 4.0)), 0, min(3, frames.size() - 1))
	elif elapsed <= game.BOSS_STAGE_SLAM_TIME + LANDING_FRAME_HOLD:
		frame_index = min(4, frames.size() - 1)
	if frame_index < 0:
		return null
	return frames[frame_index] as Texture2D


static func _siege_tide_jump_texture(game: Node2D) -> Texture2D:
	if not siege_tide_jump_active(game):
		return null
	var frames: Array = game.textures.get("boss1_jump", [])
	if frames.is_empty():
		return null
	var progress: float = 1.0 - game.boss1_siege_tide_jump_timer / maxf(0.001, game.boss1_siege_tide_jump_duration)
	var frame_index: int = clampi(int(floor(clampf(progress, 0.0, 0.999) * 4.0)), 0, min(3, frames.size() - 1))
	if progress >= 0.82:
		frame_index = min(4, frames.size() - 1)
	return frames[frame_index] as Texture2D


static func _timed_texture(frames_value: Variant, timer: float, duration: float) -> Texture2D:
	if not frames_value is Array:
		return null
	var frames: Array = frames_value
	if frames.is_empty() or timer <= 0.0:
		return null
	var progress: float = 1.0 - timer / maxf(0.001, duration)
	var frame_index: int = clampi(int(floor(progress * float(frames.size()))), 0, frames.size() - 1)
	return frames[frame_index] as Texture2D
