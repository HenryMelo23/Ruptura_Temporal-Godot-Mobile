class_name RTHenryQuimeraPresentation
extends RefCounted

# Presentation-only compositor for QUIMERA 02. Gameplay/authority owns the
# snapshot; this owner only maps it onto the existing Henry body rectangle.

const LOCAL_VISUAL_META := &"henry_quimera_visual_state"
const REMOTE_VISUAL_KEY := &"henry_quimera_visual"

const FAMILY_STRUCTURAL := &"estrutural"
const FAMILY_PREDATORY := &"predatoria"
const FAMILY_ANOMALOUS := &"anomala"

const STATE_IDLE := &"idle"
const STATE_WALK := &"walk"
const STATE_ATTACK := &"attack"
const STATE_CAST := &"cast"
const STATE_ULTIMATE := &"ultimate"
const STATE_DAMAGE := &"damage"
const STATE_FROZEN := &"frozen"
const STATE_DEATH := &"death"

const BUCKET_FRONT := 0
const BUCKET_SIDE := 1
const BUCKET_BACK := 2

const PREDATORY_WALK_PHASES := [0, 1, 0, 1, 0]
const SOURCE_CELL_SIZE := 256.0

const STRUCTURAL_TEXTURE_KEY := &"henry_quimera_estrutural_overlay"
const PREDATORY_TEXTURE_KEY := &"henry_quimera_predatoria_overlay"
const ANOMALOUS_TEXTURE_KEY := &"henry_quimera_anomala_overlay"

# Source-space sockets are stable attachment points for the stage-3 accent.
# Full-canvas organ overlays still inherit the body Rect2 and ground anchor.
const STRUCTURAL_SOCKETS := [Vector2(128.0, 170.0), Vector2(121.0, 166.0), Vector2(128.0, 160.0)]
const PREDATORY_SOCKETS := [Vector2(128.0, 157.0), Vector2(115.0, 154.0), Vector2(128.0, 146.0)]
const ANOMALOUS_SOCKETS := [Vector2(128.0, 88.0), Vector2(123.0, 86.0), Vector2(128.0, 82.0)]

const STRUCTURAL_ACCENT := Color(0.82, 0.68, 0.38, 0.92)
const PREDATORY_ACCENT := Color(0.82, 0.18, 0.12, 0.92)
const ANOMALOUS_ACCENT := Color(0.22, 0.92, 0.78, 0.92)


static func bucket_for(direction: Vector2, state: StringName, fallback_bucket: int = BUCKET_FRONT) -> int:
	if state == STATE_ULTIMATE:
		return BUCKET_FRONT
	if direction.length_squared() <= 0.001:
		return clampi(fallback_bucket, BUCKET_FRONT, BUCKET_BACK)
	var sector := posmod(roundi(direction.normalized().angle() / (PI / 4.0)), 8)
	match sector:
		0, 4:
			return BUCKET_SIDE
		1, 2, 3:
			return BUCKET_FRONT
		5, 6, 7:
			return BUCKET_BACK
	return BUCKET_FRONT


static func bucket_name(bucket: int) -> StringName:
	match bucket:
		BUCKET_SIDE:
			return &"lado"
		BUCKET_BACK:
			return &"costas"
	return &"frente"


static func should_flip(direction: Vector2, state: StringName, body_flip_h: bool) -> bool:
	if state == STATE_ULTIMATE:
		return false
	if state == STATE_ATTACK or state == STATE_CAST:
		if direction.length_squared() <= 0.001:
			return body_flip_h
		var sector := posmod(roundi(direction.normalized().angle() / (PI / 4.0)), 8)
		return sector >= 3 and sector <= 5
	return body_flip_h


static func is_visible_state(state: StringName) -> bool:
	return state != STATE_FROZEN and state != STATE_DEATH


static func predatory_phase(locomotion_frame: int) -> int:
	return int(PREDATORY_WALK_PHASES[posmod(locomotion_frame, PREDATORY_WALK_PHASES.size())])


static func frame_index(family: StringName, stage: int, bucket: int, locomotion_frame: int) -> int:
	if stage <= 0 or not is_known_family(family):
		return -1
	var source_stage := 0 if stage == 1 else 1
	var safe_bucket := clampi(bucket, BUCKET_FRONT, BUCKET_BACK)
	if family == FAMILY_PREDATORY:
		return source_stage * 6 + safe_bucket * 2 + predatory_phase(locomotion_frame)
	return source_stage * 3 + safe_bucket


static func family_layer(family: StringName) -> int:
	match family:
		FAMILY_STRUCTURAL:
			return 0
		FAMILY_PREDATORY:
			return 1
		FAMILY_ANOMALOUS:
			return 2
	return -1


static func family_for_layer(layer: int) -> StringName:
	match layer:
		0:
			return FAMILY_STRUCTURAL
		1:
			return FAMILY_PREDATORY
		2:
			return FAMILY_ANOMALOUS
	return &""


static func is_known_family(family: StringName) -> bool:
	return family == FAMILY_STRUCTURAL or family == FAMILY_PREDATORY or family == FAMILY_ANOMALOUS


static func texture_key_for_family(family: StringName) -> StringName:
	match family:
		FAMILY_STRUCTURAL:
			return STRUCTURAL_TEXTURE_KEY
		FAMILY_PREDATORY:
			return PREDATORY_TEXTURE_KEY
		FAMILY_ANOMALOUS:
			return ANOMALOUS_TEXTURE_KEY
	return &""


static func socket_for(family: StringName, bucket: int) -> Vector2:
	var safe_bucket := clampi(bucket, BUCKET_FRONT, BUCKET_BACK)
	match family:
		FAMILY_STRUCTURAL:
			return STRUCTURAL_SOCKETS[safe_bucket]
		FAMILY_PREDATORY:
			return PREDATORY_SOCKETS[safe_bucket]
		FAMILY_ANOMALOUS:
			return ANOMALOUS_SOCKETS[safe_bucket]
	return Vector2(128.0, 128.0)


static func offset_for_state(state: StringName) -> Vector2:
	# QUIMERA 01 freezes every initial state offset at zero. Keeping the mapping
	# centralized lets final art tune a state without editing draw call sites.
	match state:
		STATE_IDLE, STATE_WALK, STATE_ATTACK, STATE_CAST, STATE_ULTIMATE, STATE_DAMAGE:
			return Vector2.ZERO
	return Vector2.ZERO


# Diagnostic/test API. The hot draw path below resolves indices directly and
# does not allocate command dictionaries per rendered frame.
static func resolve_overlay(family: StringName, stage: int, direction: Vector2, locomotion_frame: int, state: StringName, body_flip_h: bool = false, fallback_bucket: int = BUCKET_FRONT) -> Dictionary:
	var bucket := bucket_for(direction, state, fallback_bucket)
	return {
		"visible": stage > 0 and is_known_family(family) and is_visible_state(state),
		"family": family,
		"stage": stage,
		"source_stage": mini(maxi(stage, 1), 2),
		"bucket": bucket_name(bucket),
		"bucket_index": bucket,
		"frame_index": frame_index(family, stage, bucket, locomotion_frame),
		"flip_h": should_flip(direction, state, body_flip_h),
		"socket": socket_for(family, bucket),
		"offset": offset_for_state(state),
		"layer": family_layer(family),
		"procedural_accent": stage >= 3 and is_visible_state(state),
	}


static func texture_for(textures: Dictionary, family: StringName, stage: int, bucket: int, locomotion_frame: int) -> Texture2D:
	var texture_key := texture_key_for_family(family)
	if texture_key == &"":
		return null
	var frames_value: Variant = textures.get(texture_key, null)
	if not frames_value is Array:
		return null
	var frames: Array = frames_value
	var index := frame_index(family, stage, bucket, locomotion_frame)
	if index < 0 or index >= frames.size():
		return null
	return frames[index] as Texture2D


static func local_body_rect(body_texture: Texture2D, center: Vector2, profile: Dictionary, player_box_size: Vector2) -> Rect2:
	var origin := center + Vector2(profile.get("offset", Vector2.ZERO))
	if body_texture == null:
		return Rect2(origin, Vector2.ZERO)
	var texture_size := body_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2(origin, Vector2.ZERO)
	if bool(profile.get("preserve_height", false)):
		var draw_size := texture_size * (float(profile.get("height", player_box_size.y)) / texture_size.y)
		return Rect2(origin + Vector2(-draw_size.x * 0.5, player_box_size.y * 0.5 - draw_size.y), draw_size)
	var max_size := Vector2(profile.get("size", player_box_size))
	if bool(profile.get("fit_aspect", false)):
		var fit_scale := minf(max_size.x / texture_size.x, max_size.y / texture_size.y)
		var draw_size := texture_size * fit_scale
		return Rect2(origin + Vector2(-draw_size.x * 0.5, player_box_size.y * 0.5 - draw_size.y), draw_size)
	return Rect2(origin + Vector2(-max_size.x * 0.5, player_box_size.y * 0.5 - max_size.y), max_size)


static func centered_fit_rect(body_texture: Texture2D, center: Vector2, max_size: Vector2) -> Rect2:
	if body_texture == null:
		return Rect2(center, Vector2.ZERO)
	var texture_size := body_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2(center, Vector2.ZERO)
	var fit_scale := minf(max_size.x / texture_size.x, max_size.y / texture_size.y)
	var draw_size := texture_size * fit_scale
	return Rect2(center - draw_size * 0.5, draw_size)


static func draw_local(game: Node2D, body_texture: Texture2D, center: Vector2, profile: Dictionary, rotation: float, body_modulate: Color, body_flip_h: bool) -> void:
	if game.active_character_key != game.CHARACTER_HENRY or not game.has_meta(LOCAL_VISUAL_META):
		return
	var snapshot_value: Variant = game.get_meta(LOCAL_VISUAL_META)
	if not snapshot_value is Dictionary:
		return
	var snapshot: Dictionary = snapshot_value
	var state := _local_state(game)
	var direction := _local_direction(game, snapshot, state)
	var body_rect := local_body_rect(body_texture, center, profile, game.PLAYER_DRAW_BOX_SIZE)
	var transform_origin := center + Vector2(profile.get("offset", Vector2.ZERO))
	_draw_snapshot(game, game.textures, snapshot, body_rect, transform_origin, rotation, body_modulate, body_flip_h, state, direction)


static func draw_remote(game: Node2D, state_data: Dictionary, body_texture: Texture2D, body_center: Vector2, body_max_size: Vector2, body_modulate: Color, body_flip_h: bool) -> void:
	var snapshot_value: Variant = state_data.get(REMOTE_VISUAL_KEY, null)
	if not snapshot_value is Dictionary:
		return
	var snapshot: Dictionary = snapshot_value
	var state := _remote_state(game, state_data)
	var direction := _remote_direction(state_data, snapshot, state)
	var body_rect := centered_fit_rect(body_texture, body_center, body_max_size)
	_draw_snapshot(game, game.textures, snapshot, body_rect, body_center, 0.0, body_modulate, body_flip_h, state, direction)


static func _draw_snapshot(canvas: CanvasItem, textures: Dictionary, snapshot: Dictionary, body_rect: Rect2, transform_origin: Vector2, rotation: float, body_modulate: Color, body_flip_h: bool, state: StringName, direction: Vector2) -> void:
	if body_rect.size.x <= 0.0 or body_rect.size.y <= 0.0 or not is_visible_state(state):
		return
	var families_value: Variant = snapshot.get("families", null)
	if not families_value is Dictionary:
		return
	var families: Dictionary = families_value
	var locomotion_frame := int(snapshot.get("locomotion_frame", snapshot.get("frame", 0)))
	var fallback_bucket := int(snapshot.get("bucket", BUCKET_FRONT))
	var bucket := bucket_for(direction, state, fallback_bucket)
	var flip_h := should_flip(direction, state, body_flip_h)
	var state_offset := offset_for_state(state)
	for layer in range(3):
		var family := family_for_layer(layer)
		var stage := int(families.get(family, 0))
		if stage <= 0:
			continue
		var texture := texture_for(textures, family, stage, bucket, locomotion_frame)
		if texture != null:
			_draw_texture(canvas, texture, body_rect, transform_origin, rotation, flip_h, body_modulate, state_offset)
	# Stage-3 accents are deliberately a second pass, above every organ layer.
	for layer in range(3):
		var family := family_for_layer(layer)
		if int(families.get(family, 0)) >= 3:
			_draw_stage_three_accent(canvas, family, bucket, body_rect, transform_origin, rotation, flip_h, float(snapshot.get("accent_phase", 0.0)), body_modulate.a)


static func _draw_texture(canvas: CanvasItem, texture: Texture2D, body_rect: Rect2, transform_origin: Vector2, rotation: float, flip_h: bool, modulate: Color, source_offset: Vector2) -> void:
	var scale_to_body := Vector2(body_rect.size.x / SOURCE_CELL_SIZE, body_rect.size.y / SOURCE_CELL_SIZE)
	var offset := source_offset * scale_to_body
	var local_rect := Rect2(body_rect.position - transform_origin + offset, body_rect.size)
	canvas.draw_set_transform(transform_origin, rotation, Vector2(-1.0, 1.0) if flip_h else Vector2.ONE)
	canvas.draw_texture_rect(texture, local_rect, false, modulate)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_stage_three_accent(canvas: CanvasItem, family: StringName, bucket: int, body_rect: Rect2, transform_origin: Vector2, rotation: float, flip_h: bool, phase: float, alpha: float) -> void:
	var socket := socket_for(family, bucket)
	var socket_local := body_rect.position - transform_origin + body_rect.size * (socket / SOURCE_CELL_SIZE)
	var pulse := 1.0 + sin(phase * TAU) * 0.16
	var radius := maxf(2.4, minf(body_rect.size.x, body_rect.size.y) * 0.055) * pulse
	var color := _accent_color(family)
	color.a *= alpha
	canvas.draw_set_transform(transform_origin, rotation, Vector2(-1.0, 1.0) if flip_h else Vector2.ONE)
	canvas.draw_line(socket_local + Vector2(-radius, 0.0), socket_local + Vector2(0.0, -radius), color, 1.35, false)
	canvas.draw_line(socket_local + Vector2(0.0, -radius), socket_local + Vector2(radius, 0.0), color, 1.35, false)
	canvas.draw_line(socket_local + Vector2(radius, 0.0), socket_local + Vector2(0.0, radius), color, 1.35, false)
	canvas.draw_line(socket_local + Vector2(0.0, radius), socket_local + Vector2(-radius, 0.0), color, 1.35, false)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _accent_color(family: StringName) -> Color:
	match family:
		FAMILY_STRUCTURAL:
			return STRUCTURAL_ACCENT
		FAMILY_PREDATORY:
			return PREDATORY_ACCENT
		FAMILY_ANOMALOUS:
			return ANOMALOUS_ACCENT
	return Color.WHITE


static func _local_state(game: Node2D) -> StringName:
	if game.is_dead:
		return STATE_DEATH
	if game.player_freeze_visual_timer > 0.0:
		return STATE_FROZEN
	if game.henry_ultimate_cast_active:
		return STATE_ULTIMATE
	if game.henry_skill_cast_active:
		return STATE_CAST
	if game._player_attack_pose_active():
		return STATE_ATTACK
	if game.time_alive - game.last_damage_time < 0.35:
		return STATE_DAMAGE
	if game._read_move().length() > 0.12:
		return STATE_WALK
	return STATE_IDLE


static func _local_direction(game: Node2D, snapshot: Dictionary, state: StringName) -> Vector2:
	if state == STATE_CAST:
		return game.henry_skill_cast_direction
	if state == STATE_ATTACK:
		return game.player_attack_visual_dir
	var snapshot_direction: Variant = snapshot.get("direction", Vector2.ZERO)
	if snapshot_direction is Vector2 and Vector2(snapshot_direction).length_squared() > 0.001:
		return snapshot_direction
	var move: Vector2 = game._read_move()
	return move if move.length_squared() > 0.001 else game.last_facing


static func _remote_state(game: Node2D, state_data: Dictionary) -> StringName:
	if bool(state_data.get("dead", false)):
		return STATE_DEATH
	var anim_state := int(state_data.get("anim_state", game.NET_ANIM_IDLE))
	if anim_state == game.NET_ANIM_FROZEN:
		return STATE_FROZEN
	if anim_state == game.NET_ANIM_DAMAGE:
		return STATE_DAMAGE
	if anim_state == game.NET_ANIM_FIRE:
		return STATE_ATTACK
	if anim_state == game.NET_ANIM_LACERANTE:
		return STATE_ULTIMATE if int(state_data.get("frame_idx", 0)) >= 40 else STATE_CAST
	if anim_state == game.NET_ANIM_UP or anim_state == game.NET_ANIM_DOWN or anim_state == game.NET_ANIM_RIGHT:
		return STATE_WALK
	return STATE_IDLE


static func _remote_direction(state_data: Dictionary, snapshot: Dictionary, state: StringName) -> Vector2:
	if state == STATE_ATTACK or state == STATE_CAST:
		var aim_value: Variant = state_data.get("input_aim", snapshot.get("direction", Vector2.ZERO))
		if aim_value is Vector2:
			return aim_value
	var direction_value: Variant = snapshot.get("direction", state_data.get("input_move", state_data.get("move", Vector2.ZERO)))
	return Vector2(direction_value) if direction_value is Vector2 else Vector2.ZERO
