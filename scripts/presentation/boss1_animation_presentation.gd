class_name RTBoss1AnimationPresentation
extends RefCounted

const HIT_DURATION_MIN := 0.18
const HIT_DURATION_MAX := 0.28
const DEATH_DURATION := 1.65
const LANDING_FRAME_HOLD := 0.24
const TURN_DURATION := 0.22
const NETWORK_MOTION_HOLD := 0.18
const MOVEMENT_DEADZONE := 5.0
# The Cronoguejo intentionally occupies more of the arena than the player.
# Keep this single base size so idle, casts, jumps, death, shadow and HUD
# anchoring all grow together instead of making individual frames drift.
const DRAW_SIZE := Vector2(331.2, 306.0)
const FRAME_SIZE := 256.0
const FRAME_BOTTOM_MARGIN := 12.0
const SHADOW_CENTER_Y_OFFSET := -(FRAME_BOTTOM_MARGIN / FRAME_SIZE) * DRAW_SIZE.y

const STATE_IDLE := "idle"
const STATE_WALK := "walk"
const STATE_TURN := "turn"
const STATE_HIT := "hit"
const STATE_JUMP := "jump"
const STATE_BUBBLE := "bubble"
const STATE_PINCER := "pincer"
const STATE_ABSORB := "absorb"
const STATE_SAND := "sand"
const STATE_TIDE := "tide"
const STATE_RAIN := "rain"
const STATE_REWIND := "rewind"

# Generated poses have deliberately different silhouettes (wide claws, rear
# view, crouches). These restrained per-state factors keep the perceived body
# mass equal to idle while preserving each pose's aspect ratio and pixel art.
const DRAW_SCALE_BY_VISUAL := {
	STATE_WALK: 1.15,
	STATE_TURN: 1.01,
	STATE_HIT: 1.02,
	STATE_JUMP: 1.07,
	STATE_BUBBLE: 1.04,
	"pincer_horizontal": 1.20,
	"pincer_up": 0.97,
	"pincer_down": 1.05,
	STATE_ABSORB: 1.05,
	STATE_SAND: 1.11,
	STATE_TIDE: 1.08,
	STATE_RAIN: 1.02,
	STATE_REWIND: 0.97,
}

const LOOP_FPS := {
	STATE_IDLE: 5.0,
	STATE_WALK: 9.0,
	STATE_BUBBLE: 8.0,
	STATE_ABSORB: 7.0,
	STATE_SAND: 8.0,
	STATE_TIDE: 8.0,
	STATE_RAIN: 8.0,
	STATE_REWIND: 7.0,
}

const TEXTURE_KEYS := {
	STATE_IDLE: "boss1_idle",
	STATE_WALK: "boss1_walk",
	STATE_TURN: "boss1_turn",
	STATE_BUBBLE: "boss1_bubble",
	STATE_PINCER: "boss1_pincer",
	STATE_ABSORB: "boss1_absorb",
	STATE_SAND: "boss1_sand",
	STATE_TIDE: "boss1_tide",
	STATE_RAIN: "boss1_rain",
	STATE_REWIND: "boss1_rewind",
}


static func reset(game: Node2D) -> void:
	game.boss1_hit_animation_timer = 0.0
	game.boss1_hit_animation_duration = HIT_DURATION_MIN
	game.boss1_death_animation_timer = 0.0
	game.boss1_death_animation_duration = DEATH_DURATION
	game.boss1_death_animation_pos = Vector2.ZERO
	game.boss1_animation_state = STATE_IDLE
	game.boss1_animation_elapsed = 0.0
	game.boss1_animation_previous_pos = game.boss_pos
	game.boss1_animation_velocity = Vector2.ZERO
	game.boss1_animation_facing = 1.0
	game.boss1_animation_turn_timer = 0.0
	game.boss1_animation_motion_hold = 0.0
	game.boss1_siege_tide_landing_event_id = ""
	clear_siege_tide_jump(game)


static func update(game: Node2D, delta: float) -> void:
	game.boss1_hit_animation_timer = maxf(0.0, game.boss1_hit_animation_timer - delta)
	game.boss1_death_animation_timer = maxf(0.0, game.boss1_death_animation_timer - delta)
	var previous_tide_timer: float = game.boss1_siege_tide_jump_timer
	game.boss1_siege_tide_jump_timer = maxf(0.0, previous_tide_timer - delta)
	if previous_tide_timer > 0.0 and game.boss1_siege_tide_jump_timer <= 0.0:
		var landing_event_id: String = game.boss1_siege_tide_jump_event_id
		if not landing_event_id.is_empty() and game.boss1_siege_tide_landing_event_id != landing_event_id:
			game.boss1_siege_tide_landing_event_id = landing_event_id
			if game.has_method("_on_boss1_siege_tide_landed"):
				game._on_boss1_siege_tide_landed(landing_event_id)
	game.boss1_animation_turn_timer = maxf(0.0, game.boss1_animation_turn_timer - delta)
	game.boss1_animation_motion_hold = maxf(0.0, game.boss1_animation_motion_hold - delta)
	if game.current_phase != 1:
		game.boss1_animation_previous_pos = game.boss_pos
		game.boss1_animation_velocity = Vector2.ZERO
		return
	_update_motion(game, delta)
	var next_state := _desired_state(game)
	if next_state != game.boss1_animation_state:
		game.boss1_animation_state = next_state
		game.boss1_animation_elapsed = 0.0
	else:
		game.boss1_animation_elapsed += delta


static func _update_motion(game: Node2D, delta: float) -> void:
	if game.boss1_animation_previous_pos == Vector2.ZERO:
		game.boss1_animation_previous_pos = game.boss_pos
	var displacement: Vector2 = game.boss_pos - game.boss1_animation_previous_pos
	game.boss1_animation_previous_pos = game.boss_pos
	game.boss1_animation_velocity = displacement / maxf(delta, 0.001)
	if game.boss1_animation_velocity.length() > MOVEMENT_DEADZONE:
		game.boss1_animation_motion_hold = NETWORK_MOTION_HOLD
	if absf(game.boss1_animation_velocity.x) <= MOVEMENT_DEADZONE:
		return
	var facing: float = signf(game.boss1_animation_velocity.x)
	if facing != game.boss1_animation_facing:
		game.boss1_animation_facing = facing
		game.boss1_animation_turn_timer = TURN_DURATION


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
	# A reação é consumida como overlay de estado: casts e locomoção não são
	# interrompidos, e hits repetidos nunca prolongam a janela indefinidamente.
	game.boss1_hit_animation_timer = game.boss1_hit_animation_duration


static func trigger_death(game: Node2D, death_position: Vector2 = Vector2.INF) -> void:
	if game.current_phase != 1 or game.boss1_death_animation_timer > 0.0:
		return
	game.boss1_hit_animation_timer = 0.0
	game.boss1_death_animation_duration = DEATH_DURATION
	game.boss1_death_animation_timer = DEATH_DURATION
	game.boss1_death_animation_pos = game.boss_pos if not death_position.is_finite() else death_position


static func active_texture(game: Node2D) -> Texture2D:
	if game.current_phase != 1:
		return null
	var jump_texture := _jump_texture(game)
	if jump_texture != null:
		return jump_texture
	var state := _desired_state(game)
	if state == STATE_HIT:
		return _timed_texture(game.textures.get("boss1_hit", []), game.boss1_hit_animation_timer, game.boss1_hit_animation_duration)
	var key: String = String(TEXTURE_KEYS.get(state, "boss1_idle"))
	if state == STATE_PINCER:
		key = _pincer_texture_key(game)
	var frames_value: Variant = game.textures.get(key, [])
	if not frames_value is Array or frames_value.is_empty():
		return null
	var frames: Array = frames_value
	var frame_index := _state_frame_index(game, state, frames.size())
	return frames[clampi(frame_index, 0, frames.size() - 1)] as Texture2D


static func _desired_state(game: Node2D) -> String:
	if game.boss_entry_timer > 0.0 or siege_tide_jump_active(game) or game.boss_stage_timer > 0.0:
		return STATE_JUMP
	if not game.boss1_rewind_sequence.is_empty() or not game.boss1_time_wave.is_empty():
		return STATE_REWIND
	if game.boss1_absorb_timer > 0.0:
		return STATE_ABSORB
	var attack_state := _active_attack_state(game)
	# Dash owns locomotion only during its own windup/strike. Lingering hazards
	# must not freeze a moving crab in a cast pose.
	if attack_state != STATE_PINCER and game.boss1_animation_motion_hold > 0.0:
		return STATE_TURN if game.boss1_animation_turn_timer > 0.0 else STATE_WALK
	if not attack_state.is_empty():
		return attack_state
	if game.boss1_animation_turn_timer > 0.0:
		return STATE_TURN
	if game.boss1_animation_motion_hold > 0.0:
		return STATE_WALK
	if game.boss1_hit_animation_timer > 0.0:
		return STATE_HIT
	return STATE_IDLE


static func _active_attack_state(game: Node2D) -> String:
	for attack_index in range(game.boss_attacks.size() - 1, -1, -1):
		var attack: Dictionary = game.boss_attacks[attack_index]
		var kind := String(attack.get("kind", ""))
		var age := float(attack.get("age", 0.0))
		if age < 0.0 or age >= float(attack.get("duration", INF)):
			continue
		match kind:
			"pincer_tenaz", "rush", "pincer":
				if String(attack.get("state", "")) in ["recovery", "gap", "done"] and game.boss1_animation_motion_hold > 0.0:
					continue
				return STATE_PINCER
			"bubble", "pressure_bubbles":
				if age <= 0.92:
					return STATE_BUBBLE
			"boiling_bubbles":
				if age <= 0.96:
					return STATE_RAIN
			"sand":
				if age <= 0.86:
					return STATE_SAND
			"tide":
				if age <= 0.86:
					return STATE_TIDE
			"absorb_retaliation":
				if age <= 0.92:
					return STATE_ABSORB
	return ""


static func _state_frame_index(game: Node2D, state: String, frame_count: int) -> int:
	if frame_count <= 1:
		return 0
	if state == STATE_TURN:
		var turn_progress: float = 1.0 - float(game.boss1_animation_turn_timer) / TURN_DURATION
		return clampi(int(floor(turn_progress * float(frame_count))), 0, frame_count - 1)
	if state == STATE_PINCER:
		return _pincer_frame(game, frame_count)
	if state in [STATE_BUBBLE, STATE_SAND, STATE_TIDE, STATE_RAIN]:
		var attack_age := _matching_attack_age(game, state)
		var cast_progress := clampf((attack_age + 0.18) / 0.94, 0.0, 0.999)
		return clampi(int(floor(cast_progress * float(frame_count))), 0, frame_count - 1)
	if state == STATE_ABSORB and game.boss1_absorb_timer > 0.0:
		var absorb_progress: float = 1.0 - float(game.boss1_absorb_timer) / maxf(0.001, float(game.BOSS1_ABSORB_DURATION))
		return clampi(int(floor(clampf(absorb_progress, 0.0, 0.999) * float(frame_count))), 0, frame_count - 1)
	var fps: float = float(LOOP_FPS.get(state, 6.0))
	return int(floor(game.boss1_animation_elapsed * fps)) % frame_count


static func _matching_attack_age(game: Node2D, state: String) -> float:
	for index in range(game.boss_attacks.size() - 1, -1, -1):
		var attack: Dictionary = game.boss_attacks[index]
		if float(attack.get("age", 0.0)) < 0.0:
			continue
		var kind := String(attack.get("kind", ""))
		if (state == STATE_BUBBLE and kind in ["bubble", "pressure_bubbles"]) or (state == STATE_RAIN and kind == "boiling_bubbles") or (state == STATE_SAND and kind == "sand") or (state == STATE_TIDE and kind == "tide"):
			return float(attack.get("age", 0.0))
	return 0.0


static func _pincer_frame(game: Node2D, frame_count: int) -> int:
	for index in range(game.boss_attacks.size() - 1, -1, -1):
		var attack: Dictionary = game.boss_attacks[index]
		if float(attack.get("age", 0.0)) < 0.0 or float(attack.get("age", 0.0)) >= float(attack.get("duration", INF)):
			continue
		var kind := String(attack.get("kind", ""))
		if kind == "pincer_tenaz":
			var attack_state := String(attack.get("state", "telegraph_first"))
			if attack_state in ["telegraph_first", "telegraph_second", "gap"]:
				return 0
			if attack_state in ["dash_first", "dash_second"]:
				return 1 + int(floor(float(attack.get("state_age", 0.0)) * 14.0)) % maxi(1, frame_count - 2)
			return frame_count - 1
		if kind == "rush":
			var rush_state := String(attack.get("state", "telegraph"))
			match rush_state:
				"telegraph": return 0
				"dash": return mini(1, frame_count - 1)
				"grab", "throw": return mini(2, frame_count - 1)
				_: return frame_count - 1
	return int(floor(game.boss1_animation_elapsed * 10.0)) % frame_count


static func _pincer_direction(game: Node2D) -> Vector2:
	for index in range(game.boss_attacks.size() - 1, -1, -1):
		var attack: Dictionary = game.boss_attacks[index]
		if float(attack.get("age", 0.0)) < 0.0 or float(attack.get("age", 0.0)) >= float(attack.get("duration", INF)):
			continue
		var kind := String(attack.get("kind", ""))
		if kind == "pincer_tenaz":
			var state := String(attack.get("state", "telegraph_first"))
			var leg := "second" if state in ["telegraph_second", "dash_second", "recovery"] else "first"
			return Vector2(attack.get(leg + "_dir", Vector2.RIGHT))
		if kind in ["rush", "pincer"]:
			return Vector2(attack.get("dir", Vector2.RIGHT))
	return Vector2(game.boss1_animation_facing, 0.0)


static func _pincer_texture_key(game: Node2D) -> String:
	var direction := _pincer_direction(game)
	if absf(direction.y) > absf(direction.x):
		return "boss1_pincer_up" if direction.y < 0.0 else "boss1_pincer_down"
	return "boss1_pincer"


static func should_flip_h(game: Node2D) -> bool:
	if game.current_phase != 1:
		return false
	if _desired_state(game) == STATE_PINCER:
		var direction := _pincer_direction(game)
		return absf(direction.x) >= absf(direction.y) and direction.x < 0.0
	return game.boss1_animation_facing < 0.0


static func draw_scale(game: Node2D) -> float:
	var state := _desired_state(game)
	var profile_key := state
	if state == STATE_PINCER:
		var texture_key := _pincer_texture_key(game)
		profile_key = "pincer_horizontal" if texture_key == "boss1_pincer" else texture_key.trim_prefix("boss1_")
	return float(DRAW_SCALE_BY_VISUAL.get(profile_key, 1.0))


static func draw_size(game: Node2D) -> Vector2:
	return DRAW_SIZE * draw_scale(game)


static func shadow_center(world_ground: Vector2, visual_size: Vector2 = DRAW_SIZE) -> Vector2:
	# Every accepted frame ends at y=244 on a 256px canvas. The generic shadow
	# helper anchors to the canvas bottom, so compensate the transparent margin
	# and place the projected silhouette exactly at the visible feet.
	return world_ground + Vector2(0.0, -(FRAME_BOTTOM_MARGIN / FRAME_SIZE) * visual_size.y)


static func stage_modulate(game: Node2D) -> Color:
	var health_ratio: float = game.boss_hp / maxf(1.0, game.boss_hp_max)
	if health_ratio < 0.4:
		return Color(1.0, 0.86, 0.94, 1.0)
	if health_ratio < 0.6:
		return Color(1.0, 0.94, 0.98, 1.0)
	return Color.WHITE


static func draw_damage_stage(game: Node2D, center: Vector2, size: Vector2) -> void:
	var health_ratio: float = game.boss_hp / maxf(1.0, game.boss_hp_max)
	if health_ratio >= 0.6:
		return
	var severity := clampf((0.6 - health_ratio) / 0.6, 0.0, 1.0)
	var clock_radius := minf(size.x, size.y) * 0.205
	var crack_color := Color(0.16, 0.05, 0.24, 0.45 + severity * 0.34)
	var crack_count := 3 if health_ratio >= 0.4 else 5
	for crack_index in range(crack_count):
		var angle := -1.15 + float(crack_index) * 0.52
		var origin := center + Vector2.from_angle(angle) * clock_radius * 0.18
		var middle := origin + Vector2.from_angle(angle + 0.16) * clock_radius * (0.32 + severity * 0.12)
		var end := middle + Vector2.from_angle(angle - 0.24) * clock_radius * 0.34
		game.draw_polyline(PackedVector2Array([origin, middle, end]), crack_color, 1.4, false)


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
	if progress < 0.72:
		game._draw_dynamic_shadow_fit(texture, shadow_center(center), DRAW_SIZE, should_flip_h(game), true, 0.34 * fade)
	game._draw_entity_fit_flipped(texture, center, DRAW_SIZE, should_flip_h(game), Color(1.0, 1.0, 1.0, fade), true)
	if not game.gfx_low_resource and progress >= 0.16 and progress <= 0.88:
		var ring_radius: float = lerpf(42.0, 82.0, progress)
		game.draw_arc(center + Vector2(0.0, 7.0), ring_radius, -PI * 0.82, PI * 0.82, 28, Color(0.32, 0.82, 1.0, 0.34 * fade), 2.0, true)


static func _jump_texture(game: Node2D) -> Texture2D:
	var frames: Array = game.textures.get("boss1_jump", [])
	if frames.is_empty():
		return null
	if game.boss_entry_timer > 0.0:
		var entry_progress: float = 1.0 - float(game.boss_entry_timer) / maxf(0.001, float(game.BOSS_ENTRY_TIME))
		var entry_index := clampi(int(floor(clampf(entry_progress, 0.0, 0.999) * float(frames.size()))), 0, frames.size() - 1)
		return frames[entry_index] as Texture2D
	if siege_tide_jump_active(game):
		var tide_progress: float = 1.0 - game.boss1_siege_tide_jump_timer / maxf(0.001, game.boss1_siege_tide_jump_duration)
		var tide_index: int = clampi(int(floor(clampf(tide_progress, 0.0, 0.999) * 4.0)), 0, min(3, frames.size() - 1))
		if tide_progress >= 0.82:
			tide_index = min(4, frames.size() - 1)
		return frames[tide_index] as Texture2D
	if game.boss_stage_timer <= 0.0:
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


static func _timed_texture(frames_value: Variant, timer: float, duration: float) -> Texture2D:
	if not frames_value is Array:
		return null
	var frames: Array = frames_value
	if frames.is_empty() or timer <= 0.0:
		return null
	var progress: float = 1.0 - timer / maxf(0.001, duration)
	var frame_index: int = clampi(int(floor(progress * float(frames.size()))), 0, frames.size() - 1)
	return frames[frame_index] as Texture2D
