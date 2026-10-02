extends RefCounted

const CACHE_SCHEMA_VERSION := 1
const EVENT_SCHEMA_VERSION := 1
const EVENT_VERSION := 1
const MAX_PENDING_EVENTS := 240


static func cache_signature(payload: Dictionary, install_secret: String) -> String:
	if install_secret == "":
		return ""
	var copy := payload.duplicate(true)
	copy.erase("cache_signature")
	return _sha256_text(install_secret + "\n" + _stable_stringify(copy))


static func signed_cache(payload: Dictionary, install_secret: String) -> Dictionary:
	var signed_payload := payload.duplicate(true)
	signed_payload["cache_signature"] = cache_signature(signed_payload, install_secret)
	return signed_payload


static func validate_cache(payload: Variant, install_secret: String) -> Dictionary:
	if not payload is Dictionary or install_secret == "":
		return {}
	var data: Dictionary = payload
	if int(data.get("schema_version", 0)) != CACHE_SCHEMA_VERSION:
		return {}
	var expected := cache_signature(data, install_secret)
	if expected == "" or not _constant_time_equals(String(data.get("cache_signature", "")), expected):
		return {}
	return data.duplicate(true)


static func build_cache_payload(player_id: String, auth_token: String, recovery_code: String, snapshot: Dictionary, pending_events: Array, event_sequence: int) -> Dictionary:
	return {
		"schema_version": CACHE_SCHEMA_VERSION,
		"cache_version": 1,
		"player_id": player_id,
		"auth_token": auth_token,
		"recovery_code": recovery_code,
		"snapshot": snapshot.duplicate(true),
		"pending_events": _trim_pending_events(pending_events),
		"event_sequence": maxi(0, event_sequence),
		"saved_unix": int(Time.get_unix_time_from_system())
	}


static func unlock_progress_event(player_id: String, event_sequence: int, metric: String, amount: float, max_mode: bool, version_code: int) -> Dictionary:
	return {
		"schema_version": EVENT_SCHEMA_VERSION,
		"event_version": EVENT_VERSION,
		"event_id": _event_id(player_id, event_sequence, metric),
		"type": "unlock_progress",
		"metric": metric,
		"amount": amount,
		"max_mode": max_mode,
		"version_code": version_code,
		"created_unix": int(Time.get_unix_time_from_system())
	}


static func spectral_core_event(player_id: String, event_sequence: int, amount: int, source_type: String, phase: int, version_code: int) -> Dictionary:
	return {
		"schema_version": EVENT_SCHEMA_VERSION,
		"event_version": EVENT_VERSION,
		"event_id": _event_id(player_id, event_sequence, "spectral_core"),
		"type": "spectral_core",
		"amount": maxi(0, amount),
		"source_type": source_type,
		"phase": maxi(1, phase),
		"version_code": version_code,
		"created_unix": int(Time.get_unix_time_from_system())
	}


static func specter_upgrade_event(player_id: String, event_sequence: int, specter_key: String, target_level: int, cost: int, version_code: int) -> Dictionary:
	return {
		"schema_version": EVENT_SCHEMA_VERSION,
		"event_version": EVENT_VERSION,
		"event_id": _event_id(player_id, event_sequence, "specter_upgrade_" + specter_key),
		"type": "specter_upgrade",
		"specter_key": specter_key,
		"target_level": target_level,
		"cost": maxi(0, cost),
		"version_code": version_code,
		"created_unix": int(Time.get_unix_time_from_system())
	}


static func compact_snapshot(snapshot: Dictionary) -> Dictionary:
	var result := snapshot.duplicate(true)
	for key in ["unlocked", "unlocked_manifestations", "unlocked_specters"]:
		var values: Array = result.get(key, [])
		values = values.map(func(value): return String(value))
		values.sort()
		result[key] = values
	var progress: Dictionary = result.get("progress", {})
	var compact_progress := {}
	for key in progress.keys():
		compact_progress[String(key)] = float(progress[key])
	result["progress"] = compact_progress
	var levels: Dictionary = result.get("specter_levels", {})
	var compact_levels := {}
	for key in levels.keys():
		compact_levels[String(key)] = maxi(1, int(levels[key]))
	result["specter_levels"] = compact_levels
	result["spectral_coins"] = maxi(0, int(result.get("spectral_coins", 0)))
	result["schema_version"] = CACHE_SCHEMA_VERSION
	return result


static func _trim_pending_events(events: Array) -> Array:
	var clean: Array = []
	for item in events:
		if item is Dictionary:
			clean.append(item.duplicate(true))
	var overflow: int = maxi(0, clean.size() - MAX_PENDING_EVENTS)
	return clean.slice(overflow)


static func _event_id(player_id: String, event_sequence: int, kind: String) -> String:
	var id_source := "%s:%d:%s:%d" % [player_id, event_sequence, kind, Time.get_ticks_msec()]
	return "ppe_%s_%d" % [_sha256_text(id_source).substr(0, 20), event_sequence]


static func _sha256_text(text: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(text.to_utf8_buffer())
	return ctx.finish().hex_encode()


static func _constant_time_equals(a: String, b: String) -> bool:
	if a.length() != b.length():
		return false
	var diff := 0
	for i in range(a.length()):
		diff |= a.unicode_at(i) ^ b.unicode_at(i)
	return diff == 0


static func _stable_stringify(value: Variant) -> String:
	if value is Dictionary:
		var keys := []
		for key in value.keys():
			keys.append(String(key))
		keys.sort()
		var parts := []
		for key in keys:
			parts.append(JSON.stringify(key) + ":" + _stable_stringify(value[key]))
		return "{" + ",".join(parts) + "}"
	if value is Array:
		var parts := []
		for item in value:
			parts.append(_stable_stringify(item))
		return "[" + ",".join(parts) + "]"
	return JSON.stringify(value)
