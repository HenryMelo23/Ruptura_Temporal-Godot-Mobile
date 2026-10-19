class_name RTVisualSyncContract
extends RefCounted

const PLAYER_VISUAL_SCHEMA := 1.0
const PLAYER_VISUAL_STRIDE := 11
const ABILITY_VISUAL_SCHEMA := 3
const ABILITY_VISUAL_MAX_BYTES := 24576
const ABILITY_VISUAL_PATCH_MAX_BYTES := 12288
const ABILITY_VISUAL_PATCH_INTERVAL_MS := 250
const ABILITY_VISUAL_PATCH_ACTIVE_LIMIT := 4
const ABILITY_VISUAL_MAX_ARRAY := 16
const ABILITY_VISUAL_MAX_DICTIONARY := 64
const ABILITY_VISUAL_MAX_DEPTH := 5
const ABILITY_VISUAL_KEYS := [
	"schema", "event_id", "manifestation_key", "seed", "aim_dir", "move_dir",
	"rotations", "target", "phase", "center", "max_cuts", "target_positions",
	"radius", "overcharged", "last_pos", "color", "final_frame", "route_points",
	"marked_points", "anchor_points", "remnant_positions", "remnant_types",
	"requiem_phase", "visual_kind", "canonical_state", "evolution_ids"
]


static func pack_player_visual(move: Vector2, aim: Vector2, action: int, action_elapsed: float, speed_ratio: float, action_sequence: int, flags: int = 0) -> PackedFloat32Array:
	var safe_move := move.limit_length(1.0)
	var safe_aim := aim.normalized() if aim.length_squared() > 0.0001 else Vector2.RIGHT
	return PackedFloat32Array([
		PLAYER_VISUAL_SCHEMA,
		safe_move.x, safe_move.y,
		safe_aim.x, safe_aim.y,
		float(action), clampf(action_elapsed, 0.0, 8.0),
		clampf(speed_ratio, 0.0, 4.0),
		float(action_sequence), float(flags),
		1.0 if safe_move.length_squared() > 0.01 else 0.0
	])


static func unpack_player_visual(snapshot_data) -> Dictionary:
	var result := {"valid": false}
	if not snapshot_data is PackedFloat32Array:
		return result
	var packed: PackedFloat32Array = snapshot_data
	if packed.size() != PLAYER_VISUAL_STRIDE or not is_equal_approx(packed[0], PLAYER_VISUAL_SCHEMA):
		return result
	var aim := Vector2(packed[3], packed[4])
	if aim.length_squared() <= 0.0001:
		aim = Vector2.RIGHT
	return {
		"valid": true,
		"input_move": Vector2(packed[1], packed[2]).limit_length(1.0),
		"aim_dir": aim.normalized(),
		"visual_action": int(packed[5]),
		"visual_action_elapsed": maxf(0.0, packed[6]),
		"speed_ratio": maxf(0.0, packed[7]),
		"visual_action_sequence": maxi(0, int(packed[8])),
		"visual_flags": int(packed[9]),
		"input_moving": packed[10] > 0.5
	}


static func ability_event_bytes(arguments: Array) -> int:
	return var_to_bytes(arguments).size()


static func sanitize_ability_payload(raw_payload) -> Dictionary:
	if not raw_payload is Dictionary:
		return {}
	var payload: Dictionary = raw_payload
	var clean := {}
	for key_value in ABILITY_VISUAL_KEYS:
		var key := String(key_value)
		if not payload.has(key):
			continue
		var sanitized = _sanitize_visual_value(payload[key], 0)
		if sanitized != null:
			clean[key] = sanitized
	clean["schema"] = ABILITY_VISUAL_SCHEMA
	return clean


static func _sanitize_visual_value(value, depth: int):
	if depth > ABILITY_VISUAL_MAX_DEPTH:
		return null
	if value is String:
		return String(value).left(96)
	if value is Vector2 or value is Color or value is float or value is int or value is bool:
		return value
	if value is PackedVector2Array or value is PackedStringArray or value is Array:
		var limited: Array = []
		for item in value:
			if limited.size() >= ABILITY_VISUAL_MAX_ARRAY:
				break
			var sanitized_item = _sanitize_visual_value(item, depth + 1)
			if sanitized_item != null:
				limited.append(sanitized_item)
		return limited
	if value is Dictionary:
		var source: Dictionary = value
		var limited_dictionary := {}
		var accepted := 0
		for raw_key in source.keys():
			if accepted >= ABILITY_VISUAL_MAX_DICTIONARY:
				break
			var key := String(raw_key).left(64)
			var sanitized_value = _sanitize_visual_value(source[raw_key], depth + 1)
			if sanitized_value == null:
				continue
			limited_dictionary[key] = sanitized_value
			accepted += 1
		return limited_dictionary
	return null
