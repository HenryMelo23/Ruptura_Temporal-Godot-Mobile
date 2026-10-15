class_name RTBoss3AnimationPresentation
extends RefCounted

# Presentation-only animation resolver for Pai-Rato. Gameplay state, timings,
# hitboxes and authority remain owned by the existing phase 3 runtime.

const HIT_DURATION_MIN := 0.16
const HIT_DURATION_MAX := 0.24
const HIT_FEEDBACK_DURATION := 0.10
const DEATH_DURATION := 1.72
const DRAW_SIZE := Vector2(184.0, 170.0)
const MOVE_SPEED_DEADZONE := 6.0
const FACING_SPEED_DEADZONE := 10.0
const TELEPORT_SAMPLE_DISTANCE := 160.0
const ORIGINAL_ART_FACING := -1.0


static func reset(game: Node2D) -> void:
	game.boss3_hit_animation_timer = 0.0
	game.boss3_hit_animation_duration = HIT_DURATION_MIN
	game.boss3_hit_feedback_timer = 0.0
	game.boss3_death_animation_timer = 0.0
	game.boss3_death_animation_duration = DEATH_DURATION
	game.boss3_death_animation_pos = Vector2.ZERO
	game.boss3_visual_state = "idle"
	game.boss3_visual_state_elapsed = 0.0
	game.boss3_visual_previous_pos = game.boss_pos
	game.boss3_visual_velocity = Vector2.ZERO
	game.boss3_visual_motion_sample_valid = true
	game.boss3_facing_dir = ORIGINAL_ART_FACING


static func update(game: Node2D, delta: float) -> void:
	game.boss3_hit_animation_timer = maxf(0.0, game.boss3_hit_animation_timer - delta)
	game.boss3_hit_feedback_timer = maxf(0.0, game.boss3_hit_feedback_timer - delta)
	game.boss3_death_animation_timer = maxf(0.0, game.boss3_death_animation_timer - delta)
	_sample_motion(game, delta)
	var next_state: String = _resolve_visual_state(game)
	if next_state != game.boss3_visual_state:
		game.boss3_visual_state = next_state
		game.boss3_visual_state_elapsed = 0.0
	else:
		game.boss3_visual_state_elapsed += maxf(0.0, delta)


static func trigger_hit(game: Node2D, damage: float, source: String = "") -> void:
	if game.current_phase != 3 or damage <= 0.0 or game.boss3_death_animation_timer > 0.0:
		return
	game.boss3_hit_feedback_timer = maxf(game.boss3_hit_feedback_timer, HIT_FEEDBACK_DURATION)
	# Persistent damage ticks keep their gameplay feedback without pinning the
	# character in hit-stun animation every frame.
	if source in ["veneno", "parasite_feast", "gravitante_orbital"] or source.begins_with("aura_"):
		return
	if game.boss3_hit_animation_timer > 0.0:
		return
	# Hit is a brief idle reaction, never a movement/cast interrupt. Damage and
	# the overlay feedback above are independent from this optional pose.
	# The authority movement flag also closes the snapshot-order gap before a
	# replica has sampled the newly received position.
	if game.boss3_is_moving:
		return
	if _resolve_visual_state(game, false) != "idle":
		return
	var severity: float = clampf(damage / maxf(1.0, game.boss_hp_max * 0.025), 0.0, 1.0)
	game.boss3_hit_animation_duration = lerpf(HIT_DURATION_MIN, HIT_DURATION_MAX, severity)
	game.boss3_hit_animation_timer = game.boss3_hit_animation_duration


static func trigger_death(game: Node2D, death_position: Vector2 = Vector2.INF) -> void:
	if game.current_phase != 3 or game.boss3_death_animation_timer > 0.0:
		return
	game.boss3_hit_animation_timer = 0.0
	game.boss3_hit_feedback_timer = 0.0
	game.boss3_death_animation_duration = DEATH_DURATION
	game.boss3_death_animation_timer = DEATH_DURATION
	game.boss3_death_animation_pos = game.boss_pos if not death_position.is_finite() else death_position
	game.boss3_visual_state = "death"
	game.boss3_visual_state_elapsed = 0.0


static func visual_state(game: Node2D) -> String:
	return _resolve_visual_state(game)


static func should_flip_h(game: Node2D) -> bool:
	# Source art faces left. Only the visual is mirrored for rightward facing;
	# gameplay positions, hitboxes, attacks and child effects stay untouched.
	return game.boss3_facing_dir > 0.0


static func movement_active(game: Node2D) -> bool:
	if game.boss3_visual_motion_sample_valid:
		return game.boss3_visual_velocity.length() >= MOVE_SPEED_DEADZONE
	return bool(game.boss3_is_moving)


static func active_texture(game: Node2D) -> Texture2D:
	var state := visual_state(game)
	if state.is_empty() or state == "death":
		return null
	var texture_key := "boss3_anim_" + state
	if not game.textures.has(texture_key):
		game._ensure_runtime_texture(texture_key)
	var frames: Array = game.textures.get(texture_key, [])
	if frames.is_empty():
		return null
	var index: int = _frame_index(game, state, frames.size())
	var texture = frames[clampi(index, 0, frames.size() - 1)]
	return texture as Texture2D


static func stage_modulate(game: Node2D) -> Color:
	var color := Color.WHITE
	match clampi(int(game.boss3_stage), 1, 3):
		2:
			color = Color(0.98, 1.0, 0.88, 1.0)
		3:
			color = Color(1.0, 0.91, 0.72, 1.0)
	if game.boss3_hit_feedback_timer > 0.0:
		var pulse: float = clampf(game.boss3_hit_feedback_timer / HIT_FEEDBACK_DURATION, 0.0, 1.0)
		color = color.lerp(Color(1.0, 0.62, 0.42, 1.0), 0.34 * pulse)
	return color


static func death_active(game: Node2D) -> bool:
	return game.current_phase == 3 and game.boss3_death_animation_timer > 0.0


static func draw_death(game: Node2D, camera: Vector2) -> void:
	if not game.textures.has("boss3_anim_death"):
		game._ensure_runtime_texture("boss3_anim_death")
	var frames: Array = game.textures.get("boss3_anim_death", [])
	var texture := _timed_texture(frames, game.boss3_death_animation_timer, game.boss3_death_animation_duration)
	if texture == null:
		return
	var progress: float = 1.0 - game.boss3_death_animation_timer / maxf(0.001, game.boss3_death_animation_duration)
	var center: Vector2 = game.boss3_death_animation_pos - camera
	var fade: float = 1.0 - clampf((progress - 0.9) / 0.1, 0.0, 1.0)
	var shake: Vector2 = Vector2(sin(progress * 86.0), cos(progress * 71.0)) * (3.5 * (1.0 - progress))
	if progress < 0.76:
		game._draw_dynamic_shadow_fit(texture, center + Vector2(0.0, 8.0), DRAW_SIZE, should_flip_h(game), true, 0.36 * fade)
	game._draw_entity_fit_flipped(texture, center + shake, DRAW_SIZE, should_flip_h(game), Color(1.0, 1.0, 1.0, fade), true)
	if not game.gfx_low_resource and not game._memory_saver_active() and progress >= 0.42:
		var shard_count: int = 8
		for shard in range(shard_count):
			var angle: float = float(shard) * TAU / float(shard_count) + progress * 0.45
			var shard_pos: Vector2 = center + Vector2.from_angle(angle) * lerpf(18.0, 72.0, progress)
			game.draw_rect(Rect2(shard_pos, Vector2(3.0, 3.0)), Color(0.72, 0.9, 0.28, (1.0 - progress) * 0.72), true)


static func _frame_index(game: Node2D, state: String, frame_count: int) -> int:
	if frame_count <= 1:
		return 0
	match state:
		"entry":
			var entry_progress: float = 1.0 - game.boss_entry_timer / maxf(0.001, game.BOSS3_ENTRY_TIME)
			return _progress_index(entry_progress, frame_count)
		"hit":
			return _timer_index(game.boss3_hit_animation_timer, game.boss3_hit_animation_duration, frame_count)
		"stun":
			return int(game.time_alive * 5.0) % frame_count
		"consume":
			return _progress_index(clampf(game.boss3_consume_timer / 1.0, 0.0, 1.0), frame_count)
		"rat_tail", "rat_spit", "rat_rain", "sector_ritual":
			var attack := _attack_for_state(game, state)
			return _progress_index(float(attack.get("age", 0.0)) / maxf(0.001, float(attack.get("duration", 1.0))), frame_count)
		"cheese_ritual":
			return int(game.time_alive * 7.0) % frame_count
		"miasma":
			return int(game.time_alive * 6.0) % frame_count
		"faith":
			return int(game.boss3_visual_state_elapsed * 6.5) % frame_count
		"walk":
			return int(game.boss3_visual_state_elapsed * 7.5) % frame_count
		_:
			return int(game.boss3_visual_state_elapsed * 4.5) % frame_count


static func _sample_motion(game: Node2D, delta: float) -> void:
	if game.current_phase != 3:
		game.boss3_visual_motion_sample_valid = false
		game.boss3_visual_velocity = Vector2.ZERO
		return
	if not game.boss3_visual_motion_sample_valid:
		game.boss3_visual_previous_pos = game.boss_pos
		game.boss3_visual_velocity = Vector2.ZERO
		game.boss3_visual_motion_sample_valid = true
		return
	var displacement: Vector2 = game.boss_pos - game.boss3_visual_previous_pos
	game.boss3_visual_previous_pos = game.boss_pos
	if delta <= 0.0 or displacement.length() >= TELEPORT_SAMPLE_DISTANCE:
		game.boss3_visual_velocity = Vector2.ZERO
		return
	game.boss3_visual_velocity = displacement / delta
	if absf(game.boss3_visual_velocity.x) >= FACING_SPEED_DEADZONE:
		game.boss3_facing_dir = 1.0 if game.boss3_visual_velocity.x > 0.0 else -1.0


static func _resolve_visual_state(game: Node2D, allow_hit: bool = true) -> String:
	# One resolver owns presentation priority. Gameplay state remains in the
	# phase controller and is never cancelled by a visual transition.
	if death_active(game):
		return "death"
	if game.current_phase != 3:
		return ""
	if game.boss_entry_timer > 0.0:
		return "entry"
	if game.boss3_stun_timer > 0.0:
		return "stun"
	var blocking_cast: String = _blocking_cast_state(game)
	if not blocking_cast.is_empty():
		return blocking_cast
	if movement_active(game):
		return "walk"
	if game.boss3_consume_uid >= 0 and game.boss3_consume_timer > 0.0:
		return "consume"
	if game.boss3_faith_test_active or game.boss3_faith_link_timer > 0.0:
		return "faith"
	if allow_hit and game.boss3_hit_animation_timer > 0.0:
		return "hit"
	return "idle"


static func _blocking_cast_state(game: Node2D) -> String:
	if game.boss3_ritual_timer > 0.0:
		return "cheese_ritual"
	if _has_attack(game, "boss3_sector_ritual"):
		return "sector_ritual"
	if game._boss3_miasma_active():
		return "miasma"
	if _has_attack(game, "rat_tail"):
		return "rat_tail"
	if _has_attack(game, "miasma_cheese_spit") or _has_attack(game, "rat_spit"):
		return "rat_spit"
	if _has_attack(game, "rat_rain"):
		return "rat_rain"
	return ""


static func _attack_for_state(game: Node2D, state: String) -> Dictionary:
	var kinds: Array[String] = []
	match state:
		"rat_spit":
			kinds = ["miasma_cheese_spit", "rat_spit"]
		"sector_ritual":
			kinds = ["boss3_sector_ritual"]
		_:
			kinds = [state]
	for attack_value in game.boss_attacks:
		if attack_value is Dictionary and kinds.has(String(attack_value.get("kind", ""))):
			return attack_value
	return {}


static func _has_attack(game: Node2D, kind: String) -> bool:
	for attack_value in game.boss_attacks:
		if attack_value is Dictionary and String(attack_value.get("kind", "")) == kind:
			return true
	return false


static func _timer_index(timer: float, duration: float, frame_count: int) -> int:
	return _progress_index(1.0 - timer / maxf(0.001, duration), frame_count)


static func _progress_index(progress: float, frame_count: int) -> int:
	return clampi(int(floor(clampf(progress, 0.0, 0.999) * float(frame_count))), 0, frame_count - 1)


static func _timed_texture(frames_value: Variant, timer: float, duration: float) -> Texture2D:
	if not frames_value is Array:
		return null
	var frames: Array = frames_value
	if frames.is_empty() or timer <= 0.0:
		return null
	return frames[_timer_index(timer, duration, frames.size())] as Texture2D
