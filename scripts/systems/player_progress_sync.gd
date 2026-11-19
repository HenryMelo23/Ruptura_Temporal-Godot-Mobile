extends RefCounted

const CACHE_SCHEMA_VERSION := 2
const CACHE_SIGNATURE_VERSION := 2
const EVENT_SCHEMA_VERSION := 2
const EVENT_VERSION := 2
const MAX_PENDING_EVENTS := 240
const UNLOCK_PROGRESS_BATCH_LIMITS := {
	# Match the relay's per-event validation limits. Keeping each metric in a
	# bounded durable batch prevents an offline run from producing thousands of
	# tiny signed JSON entries while retaining the exact accumulated amount.
	"enemy_kills": 20000.0,
	"boss_kills": 32.0,
	"umbra_victories": 1.0,
	"shop_purchases": 200.0,
	"shop_rerolls": 400.0,
	"stationary_seconds": 20.0,
	"shots_fired": 5000.0,
	"teleports_used": 800.0,
	"abilities_used": 1000.0,
	"healing_events": 300.0,
	"damage_taken_events": 500.0,
}


static func merge_pending_unlock_progress(
	pending_events: Array,
	locked_event_ids: Dictionary,
	metric: String,
	amount: float,
	max_mode: bool
) -> float:
	if metric == "" or amount <= 0.0:
		return 0.0
	var batch_limit: float = float(UNLOCK_PROGRESS_BATCH_LIMITS.get(metric, 0.0))
	if not max_mode and batch_limit <= 0.0:
		return amount
	var remaining := amount
	for index in range(pending_events.size() - 1, -1, -1):
		var item: Variant = pending_events[index]
		if not item is Dictionary:
			continue
		# Pending event dictionaries are treated as immutable snapshots so the
		# background cache writer can safely hold a shallow copy of the array.
		var event: Dictionary = item.duplicate(true)
		if String(event.get("type", "")) != "unlock_progress" \
			or String(event.get("metric", "")) != metric \
			or bool(event.get("max_mode", false)) != max_mode:
			continue
		if locked_event_ids.has(String(event.get("event_id", ""))):
			continue
		if max_mode:
			event["amount"] = maxf(float(event.get("amount", 0.0)), amount)
			pending_events[index] = event
			return 0.0
		var available := maxf(0.0, batch_limit - float(event.get("amount", 0.0)))
		if available <= 0.0:
			continue
		var merged := minf(remaining, available)
		event["amount"] = float(event.get("amount", 0.0)) + merged
		pending_events[index] = event
		remaining -= merged
		if remaining <= 0.0:
			return 0.0
	return remaining


static func unlock_progress_batch_limit(metric: String, max_mode: bool, fallback: float) -> float:
	if max_mode:
		return maxf(0.0, fallback)
	return maxf(0.0, float(UNLOCK_PROGRESS_BATCH_LIMITS.get(metric, fallback)))


static func cache_signature(payload: Dictionary, install_secret: String) -> String:
	if install_secret == "":
		return ""
	var copy := payload.duplicate(true)
	copy.erase("cache_signature")
	if int(copy.get("cache_signature_version", 1)) == CACHE_SIGNATURE_VERSION:
		# JSON restores every number as float. Sign the persisted representation,
		# not the transient mix of int/float held in runtime memory.
		copy = JSON.parse_string(JSON.stringify(copy))
	return _sha256_text(install_secret + "\n" + _stable_stringify(copy))


static func signed_cache(payload: Dictionary, install_secret: String) -> Dictionary:
	var signed_payload := payload.duplicate(true)
	signed_payload["cache_signature_version"] = CACHE_SIGNATURE_VERSION
	signed_payload["cache_signature"] = cache_signature(signed_payload, install_secret)
	return signed_payload


static func validate_cache(payload: Variant, install_secret: String) -> Dictionary:
	if not payload is Dictionary or install_secret == "":
		return {}
	var data: Dictionary = payload
	if int(data.get("schema_version", 0)) not in [1, CACHE_SCHEMA_VERSION]:
		return {}
	var signature_version := int(data.get("cache_signature_version", 1))
	if signature_version not in [1, CACHE_SIGNATURE_VERSION]:
		return {}
	var expected := cache_signature(data, install_secret)
	if expected == "" or not _constant_time_equals(String(data.get("cache_signature", "")), expected):
		if signature_version != 1:
			return {}
		# Preserve existing v1 signatures by restoring only their known numeric
		# types; values and the required signature are never bypassed.
		var legacy := data.duplicate(true)
		_restore_legacy_integer_fields(legacy, ["schema_version", "cache_version", "event_sequence", "saved_unix"])
		if legacy.get("snapshot") is Dictionary:
			var snapshot: Dictionary = legacy["snapshot"]
			_restore_legacy_integer_fields(snapshot, ["schema_version", "version", "spectral_coins", "veteran_unlock_sync_version_code"])
			if snapshot.get("specter_levels") is Dictionary:
				_restore_legacy_integer_fields(snapshot["specter_levels"], snapshot["specter_levels"].keys())
		for event in legacy.get("pending_events", []):
			if event is Dictionary:
				_restore_legacy_integer_fields(event, ["schema_version", "event_version", "version_code", "created_unix", "phase", "target_level", "cost"])
				if String(event.get("type", "")) == "spectral_core":
					_restore_legacy_integer_fields(event, ["amount"])
		if not _constant_time_equals(String(data.get("cache_signature", "")), cache_signature(legacy, install_secret)):
			return {}
	return data.duplicate(true)


static func _restore_legacy_integer_fields(data: Dictionary, fields: Array) -> void:
	for key in fields:
		var value: Variant = data.get(key)
		if value is float and is_finite(value) and value == floor(value):
			data[key] = int(value)


static func build_cache_payload(player_id: String, snapshot: Dictionary, pending_events: Array, quarantined_events: Array, event_sequence: int) -> Dictionary:
	return {
		"schema_version": CACHE_SCHEMA_VERSION,
		"cache_version": 2,
		"player_id": player_id,
		"snapshot": snapshot.duplicate(true),
		"pending_events": _trim_pending_events(pending_events),
		"quarantined_events": compact_quarantined_events(quarantined_events),
		"event_sequence": maxi(0, event_sequence),
		"saved_unix": int(Time.get_unix_time_from_system())
	}


static func compact_quarantined_events(events: Array) -> Array:
	var compacted: Array = []
	var aggregate_index_by_key: Dictionary = {}
	for raw_entry in events:
		if not raw_entry is Dictionary:
			continue
		var entry: Dictionary = raw_entry
		var event_value: Variant = entry.get("event", {})
		var reason := String(entry.get("reason", ""))
		if not event_value is Dictionary:
			compacted.append(entry.duplicate(true))
			continue
		var event: Dictionary = event_value
		if String(event.get("type", "")) != "unlock_progress":
			compacted.append(entry.duplicate(true))
			continue
		var metric := String(event.get("metric", ""))
		if metric == "":
			compacted.append(entry.duplicate(true))
			continue
		var max_mode := bool(event.get("max_mode", false))
		var aggregate_key := "%s|%s|%s|%s" % [reason, metric, str(max_mode), String(event.get("device_id", ""))]
		var incoming_count := maxi(1, int(entry.get("aggregate_count", event.get("aggregate_count", 1))))
		if not aggregate_index_by_key.has(aggregate_key):
			var aggregate_event := event.duplicate(true)
			aggregate_event["aggregate_count"] = incoming_count
			aggregate_event["first_event_id"] = String(event.get("first_event_id", event.get("event_id", "")))
			aggregate_event["last_event_id"] = String(event.get("last_event_id", event.get("event_id", "")))
			aggregate_event["first_client_sequence"] = int(event.get("first_client_sequence", event.get("client_sequence", 0)))
			aggregate_event["last_client_sequence"] = int(event.get("last_client_sequence", event.get("client_sequence", 0)))
			var aggregate_entry := {
				"event": aggregate_event,
				"reason": "queue_capacity_compacted" if reason in ["queue_capacity", "queue_capacity_compacted"] else reason,
				"at": int(entry.get("at", 0)),
				"aggregate_count": incoming_count,
			}
			aggregate_index_by_key[aggregate_key] = compacted.size()
			compacted.append(aggregate_entry)
			continue
		var aggregate_index := int(aggregate_index_by_key[aggregate_key])
		var aggregate_entry: Dictionary = compacted[aggregate_index]
		var aggregate_event: Dictionary = aggregate_entry.get("event", {})
		var current_amount := float(aggregate_event.get("amount", 0.0))
		var incoming_amount := float(event.get("amount", 0.0))
		aggregate_event["amount"] = maxf(current_amount, incoming_amount) if max_mode else current_amount + incoming_amount
		aggregate_event["aggregate_count"] = int(aggregate_event.get("aggregate_count", 1)) + incoming_count
		aggregate_event["last_event_id"] = String(event.get("last_event_id", event.get("event_id", aggregate_event.get("last_event_id", ""))))
		aggregate_event["last_client_sequence"] = maxi(
			int(aggregate_event.get("last_client_sequence", 0)),
			int(event.get("last_client_sequence", event.get("client_sequence", 0)))
		)
		aggregate_entry["event"] = aggregate_event
		aggregate_entry["at"] = maxi(int(aggregate_entry.get("at", 0)), int(entry.get("at", 0)))
		aggregate_entry["aggregate_count"] = int(aggregate_event["aggregate_count"])
		compacted[aggregate_index] = aggregate_entry
	return compacted


static func append_quarantined_event(events: Array, entry: Dictionary) -> Array:
	var updated := events.duplicate(true)
	updated.append(entry.duplicate(true))
	return compact_quarantined_events(updated)


static func unlock_progress_event(player_id: String, event_sequence: int, device_id: String, metric: String, amount: float, max_mode: bool, version_code: int) -> Dictionary:
	return {
		"schema_version": EVENT_SCHEMA_VERSION,
		"event_version": EVENT_VERSION,
		"event_id": _event_id(player_id, event_sequence, metric),
		"client_sequence": maxi(1, event_sequence),
		"device_id": device_id,
		"type": "unlock_progress",
		"metric": metric,
		"amount": amount,
		"max_mode": max_mode,
		"version_code": version_code,
		"created_unix": int(Time.get_unix_time_from_system())
	}


static func spectral_core_event(player_id: String, event_sequence: int, device_id: String, amount: int, source_type: String, phase: int, version_code: int) -> Dictionary:
	return {
		"schema_version": EVENT_SCHEMA_VERSION,
		"event_version": EVENT_VERSION,
		"event_id": _event_id(player_id, event_sequence, "spectral_core"),
		"client_sequence": maxi(1, event_sequence),
		"device_id": device_id,
		"type": "spectral_core",
		"amount": maxi(0, amount),
		"source_type": source_type,
		"phase": maxi(1, phase),
		"version_code": version_code,
		"created_unix": int(Time.get_unix_time_from_system())
	}


static func specter_upgrade_event(player_id: String, event_sequence: int, device_id: String, specter_key: String, target_level: int, cost: int, version_code: int) -> Dictionary:
	return {
		"schema_version": EVENT_SCHEMA_VERSION,
		"event_version": EVENT_VERSION,
		"event_id": _event_id(player_id, event_sequence, "specter_upgrade_" + specter_key),
		"client_sequence": maxi(1, event_sequence),
		"device_id": device_id,
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
	# The runtime rejects a new event once the bounded queue is full and moves
	# that event to review. Never silently discard the oldest durable event when
	# serializing a cache: losing it would make an offline reward unverifiable.
	return clean


static func _event_id(player_id: String, event_sequence: int, kind: String) -> String:
	var id_source := "%s:%d:%s:%d" % [player_id, event_sequence, kind, Time.get_ticks_msec()]
	return "ppe_%s_%d" % [_sha256_text(id_source).substr(0, 20), event_sequence]


static func device_id_from_install_secret(install_secret: String) -> String:
	if install_secret == "":
		return ""
	return "ppd_" + _sha256_text("device\n" + install_secret).substr(0, 32)


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
