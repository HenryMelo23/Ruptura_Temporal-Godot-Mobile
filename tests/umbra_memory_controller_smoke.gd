extends SceneTree

const UmbraMemoryController = preload("res://scripts/systems/umbra_memory_controller.gd")
const TEST_PATH := "user://umbra_mind/umbra_memory_controller_smoke.json"


class ResetSpy:
	extends RefCounted
	var calls := 0
	func reset_recurrence() -> void:
		calls += 1


func _init() -> void:
	_remove_test_file()
	var controller = UmbraMemoryController.new()
	controller.set_storage_path(TEST_PATH)
	var spy := ResetSpy.new()
	controller.begin_run(false, 1)
	_expect(int(controller.persistent_profile.runs_observed) == 0 and is_equal_approx(float(controller.persistent_features().evade_rate), 0.0), "missing profile uses memory-free fallback")
	controller.begin_encounter(spy)
	_expect(spy.calls == 1 and controller.policy_memory_context().encounter_active, "combat reset invokes GRU owner")
	_expect(not controller.record_local_sample(2, {"position": Vector2(50, 0)}), "remote peer is isolated")
	for index in range(6):
		_expect(controller.record_local_sample(1, {"position": Vector2(index * 25, 0), "target_distance": 700.0 + index * 10.0, "dash_marker": float(index) if index in [2, 5] else -1.0, "attack_marker": float(index) if index % 2 == 0 else -1.0, "threat_active": true}), "local sample records")
	var run: Dictionary = controller.run_features()
	_expect(float(run.dash_rate) > 0.0 and float(run.aggression_rate) > 0.0 and float(run.distance_preference) > 0.0, "run profile aggregates behaviour")
	_expect(controller.finish_run(), "valid solo run persists")
	_expect(FileAccess.file_exists(TEST_PATH), "persistent profile written")
	var reloaded = UmbraMemoryController.new()
	reloaded.set_storage_path(TEST_PATH)
	reloaded.begin_run(false, 1)
	_expect(int(reloaded.persistent_profile.runs_observed) == 1, "persistent profile reloads")
	_expect(not reloaded.persistent_profile.has("last_position") and not reloaded.persistent_profile.has("peer_id"), "persistent profile stores no raw or peer identity")
	_write_json({"schema_version": 0, "runs": 3, "dash_rate": 0.4, "aggression_rate": 0.6})
	var migrated = UmbraMemoryController.new()
	migrated.set_storage_path(TEST_PATH)
	migrated.begin_run(false, 1)
	_expect(int(migrated.persistent_profile.runs_observed) == 3 and is_equal_approx(float(migrated.persistent_profile.metrics.dash_rate), 0.4), "legacy profile migrates")
	_write_text("{not json")
	var corrupt = UmbraMemoryController.new()
	corrupt.set_storage_path(TEST_PATH)
	corrupt.begin_run(false, 1)
	_expect(int(corrupt.persistent_profile.runs_observed) == 0, "corrupt profile falls back safely")
	_write_json({"schema_version": 1, "runs_observed": 9, "metrics": {"dash_rate": 0.9}})
	var multiplayer = UmbraMemoryController.new()
	multiplayer.set_storage_path(TEST_PATH)
	multiplayer.begin_run(true, 1)
	_expect(int(multiplayer.persistent_profile.runs_observed) == 0, "multiplayer does not load another local profile")
	_expect(not multiplayer.record_local_sample(2, {"position": Vector2(80, 0)}), "multiplayer excludes non-owner peer")
	for index in range(5):
		multiplayer.record_local_sample(1, {"position": Vector2(index * 20, 0), "target_distance": 400.0})
	_expect(not multiplayer.finish_run(), "multiplayer does not persist profile")
	var file := FileAccess.open(TEST_PATH, FileAccess.READ)
	var stored = JSON.parse_string(file.get_as_text())
	file.close()
	_expect(int(Dictionary(stored).get("runs_observed", 0)) == 9, "multiplayer leaves persisted profile unchanged")
	controller.end_encounter(spy)
	_expect(spy.calls >= 2 and not controller.policy_memory_context().encounter_active, "combat end clears transient recurrence")
	_remove_test_file()
	print("UMBRA_MEMORY_CONTROLLER_OK work=true run=true persistent=true migration=true corruption=true multiplayer_isolated=true")
	quit(0)


func _write_json(payload: Dictionary) -> void:
	_write_text(JSON.stringify(payload))


func _write_text(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_PATH.get_base_dir()))
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	_expect(file != null, "test profile opens")
	file.store_string(text)
	file.close()


func _remove_test_file() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func _expect(condition: bool, label: String) -> void:
	if not condition:
		push_error("UMBRA_MEMORY_CONTROLLER_FAIL: " + label)
		quit(1)
