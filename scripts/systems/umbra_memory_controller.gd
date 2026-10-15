extends RefCounted
class_name RTUmbraMemoryController

# UMBRA 2.0 keeps three intentionally separate memory scopes:
# - work: the policy GRU hidden state, owned by the policy and reset per combat;
# - run: compact aggregates of the local player's recent behaviour;
# - persistent: versioned, aggregate-only local profile between valid runs.
# No coordinates, raw input history, peer IDs, nicknames or policy hidden values
# are persisted. Multiplayer never loads or writes this local profile.
const PERSISTENT_SCHEMA_VERSION := 1
const DEFAULT_STORAGE_PATH := "user://umbra_mind/behavior_profile_v2.json"
const MIN_SAMPLES_TO_PERSIST := 4
const PROFILE_METRICS := ["evade_rate", "distance_preference", "dash_rate", "aggression_rate", "response_rate"]

var storage_path := DEFAULT_STORAGE_PATH
var owner_peer_id := 1
var multiplayer_isolated := false
var run_active := false
var encounter_active := false
var work_reset_generation := 0
var persistent_profile: Dictionary = _empty_persistent_profile()
var run_profile: Dictionary = _empty_run_profile()


func set_storage_path(path: String) -> void:
	storage_path = path


func begin_run(is_multiplayer_run: bool, local_peer_id: int, policy: Object = null) -> void:
	owner_peer_id = maxi(1, local_peer_id)
	multiplayer_isolated = is_multiplayer_run
	run_active = true
	encounter_active = false
	run_profile = _empty_run_profile()
	# A client and a host can have different local users. Do not load either
	# player's long-term profile into shared, authoritative multiplayer logic.
	persistent_profile = _empty_persistent_profile() if multiplayer_isolated else _load_persistent_profile()
	reset_work_memory(policy)


func begin_encounter(policy: Object = null) -> void:
	encounter_active = true
	reset_work_memory(policy)


func end_encounter(policy: Object = null) -> void:
	encounter_active = false
	reset_work_memory(policy)


func reset_work_memory(policy: Object = null) -> void:
	work_reset_generation += 1
	if policy != null and policy.has_method("reset_recurrence"):
		policy.call("reset_recurrence")


func record_local_sample(peer_id: int, sample: Dictionary) -> bool:
	if not run_active or peer_id != owner_peer_id:
		return false
	var position: Vector2 = Vector2(sample.get("position", Vector2.ZERO))
	var previous: Vector2 = Vector2(run_profile.get("last_position", position))
	var had_previous := bool(run_profile.get("has_previous_position", false))
	var moved := previous.distance_to(position) if had_previous else 0.0
	var samples := int(run_profile.get("samples", 0)) + 1
	run_profile["samples"] = samples
	run_profile["last_position"] = position
	run_profile["has_previous_position"] = true
	run_profile["distance_sum"] = float(run_profile.get("distance_sum", 0.0)) + maxf(0.0, float(sample.get("target_distance", 0.0)))
	var dash_marker := float(sample.get("dash_marker", -1.0))
	var dash_happened := false
	if dash_marker >= 0.0 and not is_equal_approx(dash_marker, float(run_profile.get("last_dash_marker", -1.0))):
		run_profile["dash_count"] = int(run_profile.get("dash_count", 0)) + 1
		run_profile["last_dash_marker"] = dash_marker
		dash_happened = true
	var attack_marker := float(sample.get("attack_marker", -1.0))
	if attack_marker >= 0.0 and not is_equal_approx(attack_marker, float(run_profile.get("last_attack_marker", -1.0))):
		run_profile["aggression_count"] = int(run_profile.get("aggression_count", 0)) + 1
		run_profile["last_attack_marker"] = attack_marker
	if bool(sample.get("threat_active", false)):
		run_profile["threat_samples"] = int(run_profile.get("threat_samples", 0)) + 1
		if moved >= 12.0 or dash_happened:
			run_profile["threat_responses"] = int(run_profile.get("threat_responses", 0)) + 1
	return true


func run_features() -> Dictionary:
	var samples := maxi(1, int(run_profile.get("samples", 0)))
	var threats := maxi(1, int(run_profile.get("threat_samples", 0)))
	return {
		"evade_rate": clampf(float(run_profile.get("threat_responses", 0)) / float(threats), 0.0, 1.0),
		"distance_preference": clampf(float(run_profile.get("distance_sum", 0.0)) / float(samples) / 1600.0, 0.0, 1.0),
		"dash_rate": clampf(float(run_profile.get("dash_count", 0)) / float(samples) * 5.0, 0.0, 1.0),
		"aggression_rate": clampf(float(run_profile.get("aggression_count", 0)) / float(samples) * 5.0, 0.0, 1.0),
		"response_rate": clampf(float(run_profile.get("threat_responses", 0)) / float(threats), 0.0, 1.0)
	}


func persistent_features() -> Dictionary:
	return Dictionary(persistent_profile.get("metrics", {})).duplicate(true)


func policy_memory_context() -> Dictionary:
	return {
		"work_reset_generation": work_reset_generation,
		"run": run_features(),
		"persistent": persistent_features(),
		"persistent_enabled": not multiplayer_isolated,
		"encounter_active": encounter_active
	}


func finish_run(policy: Object = null) -> bool:
	if not run_active:
		return false
	var should_persist := not multiplayer_isolated and int(run_profile.get("samples", 0)) >= MIN_SAMPLES_TO_PERSIST
	if should_persist:
		var metrics: Dictionary = Dictionary(persistent_profile.get("metrics", {}))
		var current := run_features()
		var observed_runs := maxi(0, int(persistent_profile.get("runs_observed", 0)))
		var blend := 1.0 / float(mini(observed_runs + 1, 6))
		for key in PROFILE_METRICS:
			metrics[key] = clampf(lerpf(float(metrics.get(key, 0.0)), float(current.get(key, 0.0)), blend), 0.0, 1.0)
		persistent_profile["schema_version"] = PERSISTENT_SCHEMA_VERSION
		persistent_profile["runs_observed"] = observed_runs + 1
		persistent_profile["metrics"] = metrics
		_save_persistent_profile()
	run_active = false
	encounter_active = false
	reset_work_memory(policy)
	return should_persist


func _load_persistent_profile() -> Dictionary:
	if not FileAccess.file_exists(storage_path):
		return _empty_persistent_profile()
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		return _empty_persistent_profile()
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not json.data is Dictionary:
		return _empty_persistent_profile()
	return _normalize_persistent_profile(Dictionary(json.data))


func _save_persistent_profile() -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(storage_path.get_base_dir()))
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(persistent_profile, "\t"))
	file.close()
	return true


func _normalize_persistent_profile(raw: Dictionary) -> Dictionary:
	var version := int(raw.get("schema_version", 0))
	if version > PERSISTENT_SCHEMA_VERSION:
		return _empty_persistent_profile()
	var profile := _empty_persistent_profile()
	profile["runs_observed"] = clampi(int(raw.get("runs_observed", raw.get("runs", 0))), 0, 100000)
	var source_metrics: Dictionary = Dictionary(raw.get("metrics", raw))
	var metrics: Dictionary = {}
	for key in PROFILE_METRICS:
		metrics[key] = clampf(float(source_metrics.get(key, 0.0)), 0.0, 1.0)
	profile["metrics"] = metrics
	return profile


static func _empty_persistent_profile() -> Dictionary:
	var metrics: Dictionary = {}
	for key in PROFILE_METRICS:
		metrics[key] = 0.0
	return {"schema_version": PERSISTENT_SCHEMA_VERSION, "runs_observed": 0, "metrics": metrics}


static func _empty_run_profile() -> Dictionary:
	return {
		"samples": 0, "distance_sum": 0.0, "dash_count": 0, "aggression_count": 0,
		"threat_samples": 0, "threat_responses": 0, "last_position": Vector2.ZERO,
		"has_previous_position": false, "last_dash_marker": -1.0, "last_attack_marker": -1.0
	}
