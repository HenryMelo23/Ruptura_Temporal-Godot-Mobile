extends SceneTree

const RTPlayerProgressSync = preload("res://scripts/systems/player_progress_sync.gd")


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PLAYER_PROGRESS_CACHE_FAIL " + message)
	quit(1)


func _run() -> void:
	var secret := "install_secret_fixture"
	var snapshot := RTPlayerProgressSync.compact_snapshot({
		"unlocked": ["Speed Boost"],
		"unlocked_manifestations": ["eletrica"],
		"unlocked_specters": ["impulsiva"],
		"specter_levels": {"impulsiva": 1},
		"content_unread": ["specter:impulsiva", "catalog_spectrum:impulsiva"],
		"spectral_coins": 3,
		"progress": {"enemy_kills": 180.0}
	})
	var pending := [
		RTPlayerProgressSync.unlock_progress_event("rtp_fixture", 1, "ppd_fixture", "enemy_kills", 70.0, false, 24100)
	]
	var payload := RTPlayerProgressSync.build_cache_payload("rtp_fixture", snapshot, pending, [], 1)
	_check(not payload.has("auth_token") and not payload.has("recovery_code"), "cache persisted identity credentials")
	var signed_payload := RTPlayerProgressSync.signed_cache(payload, secret)
	var trusted := RTPlayerProgressSync.validate_cache(signed_payload, secret)
	_check(not trusted.is_empty(), "signed cache rejected")
	_check(Dictionary(trusted.get("snapshot", {})).get("spectral_coins", 0) == 3, "trusted cache value mismatch")
	_check(Array(Dictionary(trusted.get("snapshot", {})).get("content_unread", [])).has("specter:impulsiva"), "trusted cache lost stable unread content")
	_check(Array(trusted.get("pending_events", [])).size() == 1, "pending queue not preserved")
	var disk_payload: Dictionary = JSON.parse_string(JSON.stringify(signed_payload))
	_check(not RTPlayerProgressSync.validate_cache(disk_payload, secret).is_empty(), "cache signature failed JSON roundtrip")
	var legacy := payload.duplicate(true)
	legacy["schema_version"] = 1
	legacy["cache_version"] = 1
	legacy.erase("quarantined_events")
	legacy["snapshot"]["schema_version"] = 1
	legacy["pending_events"][0]["schema_version"] = 1
	legacy["pending_events"][0]["event_version"] = 1
	legacy["pending_events"][0].erase("client_sequence")
	legacy["pending_events"][0].erase("device_id")
	legacy.erase("cache_signature_version")
	legacy["cache_signature"] = RTPlayerProgressSync.cache_signature(legacy, secret)
	_check(not RTPlayerProgressSync.validate_cache(JSON.parse_string(JSON.stringify(legacy)), secret).is_empty(), "v1 persisted cache rejected")
	var legacy_tampered: Dictionary = JSON.parse_string(JSON.stringify(legacy))
	legacy_tampered["snapshot"]["spectral_coins"] = 999
	_check(RTPlayerProgressSync.validate_cache(legacy_tampered, secret).is_empty(), "v1 tampered cache accepted")
	var unknown_version := signed_payload.duplicate(true)
	unknown_version["cache_signature_version"] = 999
	_check(RTPlayerProgressSync.validate_cache(unknown_version, secret).is_empty(), "unknown signature version accepted")

	var tampered := signed_payload.duplicate(true)
	tampered["snapshot"]["progress"]["enemy_kills"] = 9999.0
	_check(RTPlayerProgressSync.validate_cache(tampered, secret).is_empty(), "tampered progress accepted")

	var corrupted_signature := signed_payload.duplicate(true)
	corrupted_signature["cache_signature"] = "bad_signature"
	_check(RTPlayerProgressSync.validate_cache(corrupted_signature, secret).is_empty(), "corrupted signature accepted")

	var wrong_secret := RTPlayerProgressSync.validate_cache(signed_payload, "other_install_secret")
	_check(wrong_secret.is_empty(), "cache accepted with another install secret")
	var overflow_fixture: Array = []
	for index in range(RTPlayerProgressSync.MAX_PENDING_EVENTS + 1):
		overflow_fixture.append({"event_id": "preserve_%d" % index})
	var overflow_payload := RTPlayerProgressSync.build_cache_payload("rtp_fixture", snapshot, overflow_fixture, [], 1)
	_check(Array(overflow_payload.get("pending_events", [])).size() == RTPlayerProgressSync.MAX_PENDING_EVENTS + 1, "cache serialization silently dropped offline events")

	print("PLAYER_PROGRESS_CACHE_OK signed=true json_roundtrip=true legacy=true tampered=false corrupted=false pending=true no_silent_drop=true")
	quit(0)
