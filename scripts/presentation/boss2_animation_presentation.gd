class_name RTBoss2AnimationPresentation
extends RefCounted

# Presentation-only animation resolver for the Phase 2 penguin boss. Gameplay
# state, timings, hitboxes and multiplayer authority remain in the runtime.

const HIT_DURATION_MIN := 0.16
const HIT_DURATION_MAX := 0.24
const DEATH_DURATION := 1.55
const LEGACY_DRAW_SIZE := Vector2(184.0, 170.0)
# The remaster uses a taller transparent canvas so ice particles never need to
# be cropped.  Raising the draw box restores the original visible body height;
# the ground offset below keeps the gameplay anchor unchanged.
const DRAW_SIZE := Vector2(184.0, 220.0)
const FRAME_HEIGHT := 320.0
const FRAME_BOTTOM_MARGIN := 20.0
const GROUND_OFFSET := (FRAME_BOTTOM_MARGIN / FRAME_HEIGHT) * DRAW_SIZE.y
const LEGACY_FOOT_OFFSET := LEGACY_DRAW_SIZE.y * 0.5
const VISIBLE_FOOT_OFFSET := DRAW_SIZE.y * 0.5 - GROUND_OFFSET
const DRAW_CENTER_Y_OFFSET := LEGACY_FOOT_OFFSET - VISIBLE_FOOT_OFFSET

const TEXTURE_KEY_BY_STATE := {
	"boss2_idle": "boss2_anim_idle",
	"boss2_reposition": "boss2_anim_walk",
	"boss2_freezing_breath": "boss2_anim_breath",
	"boss2_spin_spit_up": "boss2_anim_spin",
	"boss2_glacial_stomp": "boss2_anim_stomp",
	"boss2_ice_prison": "boss2_anim_prison",
	"boss2_crystal_shield": "boss2_anim_shield",
	"boss2_double_blizzard": "boss2_anim_blizzard",
	"boss2_flash_freeze": "boss2_anim_flash",
	"boss2_hunt_mark": "boss2_anim_hunt",
}


static func reset(game: Node2D) -> void:
	game.boss2_hit_animation_timer = 0.0
	game.boss2_hit_animation_duration = HIT_DURATION_MIN
	game.boss2_death_animation_timer = 0.0
	game.boss2_death_animation_duration = DEATH_DURATION
	game.boss2_death_animation_pos = Vector2.ZERO


static func update(game: Node2D, delta: float) -> void:
	game.boss2_hit_animation_timer = maxf(0.0, game.boss2_hit_animation_timer - delta)
	game.boss2_death_animation_timer = maxf(0.0, game.boss2_death_animation_timer - delta)


static func trigger_hit(game: Node2D, damage: float) -> void:
	if game.current_phase != 2 or damage <= 0.0 or game.boss2_death_animation_timer > 0.0:
		return
	# Never hide an authored cast telegraph with a damage pose.
	if game.boss2_state not in [game.BOSS2_STATE_IDLE, game.BOSS2_STATE_REPOSITION]:
		return
	var severity := clampf(damage / maxf(1.0, game.boss_hp_max * 0.025), 0.0, 1.0)
	game.boss2_hit_animation_duration = lerpf(HIT_DURATION_MIN, HIT_DURATION_MAX, severity)
	game.boss2_hit_animation_timer = game.boss2_hit_animation_duration


static func trigger_death(game: Node2D, death_position: Vector2 = Vector2.INF) -> void:
	if game.current_phase != 2 or game.boss2_death_animation_timer > 0.0:
		return
	game.boss2_hit_animation_timer = 0.0
	game.boss2_death_animation_duration = DEATH_DURATION
	game.boss2_death_animation_timer = DEATH_DURATION
	game.boss2_death_animation_pos = game.boss_pos if not death_position.is_finite() else death_position


static func visual_state(game: Node2D) -> String:
	if game.boss2_hit_animation_timer > 0.0 and game.boss2_state in [game.BOSS2_STATE_IDLE, game.BOSS2_STATE_REPOSITION]:
		return "hit"
	return String(game.boss2_state)


static func active_texture(game: Node2D) -> Texture2D:
	if game.current_phase != 2:
		return null
	var state := visual_state(game)
	var texture_key := "boss2_anim_hit" if state == "hit" else String(TEXTURE_KEY_BY_STATE.get(state, "boss2_anim_idle"))
	if not game.textures.has(texture_key):
		game._ensure_runtime_texture(texture_key)
	var frames_value: Variant = game.textures.get(texture_key, [])
	if not frames_value is Array or frames_value.is_empty():
		return null
	var frames: Array = frames_value
	return frames[_frame_index(game, state, frames.size())] as Texture2D


static func draw_position(game: Node2D) -> Vector2:
	var bob := 0.0
	if game.boss2_state == game.BOSS2_STATE_REPOSITION:
		bob = absf(sin((float(game.boss2_anim_frame) + game.boss2_anim_timer * 3.0) * PI)) * 9.0
	elif game.boss2_state != game.BOSS2_STATE_IDLE:
		bob = sin(game.time_alive * 6.0) * 3.0
	else:
		bob = sin(game.time_alive * 2.2) * 2.0
	# Every frame shares a 20 px transparent bottom margin.  The explicit center
	# correction keeps the visible feet on the legacy ground line even though the
	# remaster draw box is taller. Hitboxes and boss_pos are untouched.
	return game.boss_pos + Vector2(0.0, DRAW_CENTER_Y_OFFSET - bob)


static func draw_size() -> Vector2:
	return DRAW_SIZE


static func shadow_center(game: Node2D) -> Vector2:
	# Preserve the previous shadow anchor independently from the taller art box.
	return game.boss_pos + Vector2(0.0, GROUND_OFFSET + 10.0)


static func should_flip_h(game: Node2D) -> bool:
	return game.boss2_facing_dir < 0.0


static func death_active(game: Node2D) -> bool:
	return game.current_phase == 2 and game.boss2_death_animation_timer > 0.0


static func draw_death(game: Node2D, camera: Vector2) -> void:
	if not game.textures.has("boss2_anim_death"):
		game._ensure_runtime_texture("boss2_anim_death")
	var frames: Array = game.textures.get("boss2_anim_death", [])
	var texture: Texture2D = _timed_texture(frames, game.boss2_death_animation_timer, game.boss2_death_animation_duration)
	if texture == null:
		return
	var progress: float = 1.0 - float(game.boss2_death_animation_timer) / maxf(0.001, float(game.boss2_death_animation_duration))
	var center: Vector2 = Vector2(game.boss2_death_animation_pos) - camera + Vector2(0.0, DRAW_CENTER_Y_OFFSET)
	var fade: float = 1.0 - clampf((progress - 0.84) / 0.16, 0.0, 1.0)
	var shake: Vector2 = Vector2(sin(progress * 72.0), cos(progress * 59.0)) * (2.6 * (1.0 - progress))
	if progress < 0.72:
		game._draw_dynamic_shadow_fit(texture, center + Vector2(0.0, 10.0), Vector2(122.0, 82.0), should_flip_h(game), true, 0.34 * fade)
	game._draw_entity_fit_flipped(texture, center + shake, DRAW_SIZE, should_flip_h(game), Color(1.0, 1.0, 1.0, fade), true)


static func _frame_index(game: Node2D, state: String, frame_count: int) -> int:
	if frame_count <= 1:
		return 0
	if state == "hit":
		return _timer_index(game.boss2_hit_animation_timer, game.boss2_hit_animation_duration, frame_count)
	return posmod(int(game.boss2_anim_frame), frame_count)


static func _timer_index(timer: float, duration: float, frame_count: int) -> int:
	var progress := 1.0 - clampf(timer / maxf(0.001, duration), 0.0, 1.0)
	return clampi(int(floor(progress * float(frame_count))), 0, frame_count - 1)


static func _timed_texture(frames: Array, timer: float, duration: float) -> Texture2D:
	if frames.is_empty():
		return null
	return frames[_timer_index(timer, duration, frames.size())] as Texture2D
