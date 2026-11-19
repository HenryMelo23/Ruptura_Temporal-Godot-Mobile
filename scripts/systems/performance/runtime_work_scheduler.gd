class_name RTRuntimeWorkScheduler
extends RefCounted

# Deterministic frame-lane scheduler for presentation and background work.
# Gameplay/authority code must never depend on this scheduler.

var frame_index: int = 0


func reset() -> void:
	frame_index = 0


func advance() -> void:
	frame_index = (frame_index + 1) & 0x7fffffff


func runs_lane(lane: int, interval: int) -> bool:
	var safe_interval := maxi(1, interval)
	return posmod(frame_index + maxi(0, lane), safe_interval) == 0


func runs_key(key: StringName, interval: int) -> bool:
	var safe_interval := maxi(1, interval)
	return posmod(frame_index + _stable_hash(String(key)), safe_interval) == 0


static func interval_for_stage(stage: int, full_interval: int = 1, reduced_interval: int = 2, emergency_interval: int = 3) -> int:
	match stage:
		2:
			return maxi(1, emergency_interval)
		1:
			return maxi(1, reduced_interval)
	return maxi(1, full_interval)


static func _stable_hash(value: String) -> int:
	# FNV-1a keeps lanes stable across runs, unlike randomized Dictionary hashes.
	var result: int = 2166136261
	for byte in value.to_utf8_buffer():
		result = int((result ^ int(byte)) * 16777619) & 0x7fffffff
	return result
