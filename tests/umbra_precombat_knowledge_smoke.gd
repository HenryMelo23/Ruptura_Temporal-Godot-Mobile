extends SceneTree

const UmbraMemoryController = preload("res://scripts/systems/umbra_memory_controller.gd")
const TEST_PATH := "user://umbra_mind/umbra_precombat_knowledge_smoke.json"


class RuntimeFixture:
	extends RefCounted
	var time_alive := 420.0
	var run_behavior_move_samples := 560
	var run_behavior_stationary_samples := 60
	var run_damage_hits_by_source := {"espreitador": 11, "boss_wave": 4}
	var run_damage_taken_by_source := {"espreitador": 620, "boss_wave": 210}
	var run_damage_source_meta := {"espreitador": {"name": "Espreitador"}, "boss_wave": {"name": "Caranguejo Cosmico"}}
	var player_hp_max := 500
	var manifestation_key := "eletrica"
	var mutation_key := ""
	var effect_key := ""
	var aura_state := {"name": "Racional"}

	func _run_behavior_report() -> Dictionary:
		return {
			"phase_seconds": {"1": 150.0, "2": 140.0, "3": 130.0},
			"shots_fired": 310, "hits": 172, "dash_count": 34,
			"edge_ratio": 0.11, "corner_ratio": 0.02, "center_ratio": 0.29,
			"stationary_ratio": 0.096, "dash_per_minute": 4.86,
			"shots_per_minute": 44.28, "hit_rate": 0.5548
		}

	func _cards_report_rows() -> Array:
		return [
			{"id": "Porcao", "count": 2}, {"id": "Defesa", "count": 2},
			{"id": "Horizonte", "count": 1}, {"id": "Sutura", "count": 1}
		]


func _init() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var controller := UmbraMemoryController.new()
	controller.set_storage_path(TEST_PATH)
	controller.begin_run(false, 1)
	var runtime := RuntimeFixture.new()
	var report: Dictionary = controller.knowledge_report(runtime)
	_expect(int(report.get("total_percent", 0)) >= 45, "precombat knowledge did not grow")
	_expect(int(report.get("phases_observed", 0)) == 3, "phase variety not observed")
	var categories: Dictionary = Dictionary(report.get("categories", {}))
	for key in UmbraMemoryController.KNOWLEDGE_CATEGORIES:
		_expect(categories.has(key), "missing category " + key)
		_expect(int(Dictionary(categories[key]).get("percent", 0)) > 0, "empty category " + key)
	_expect(String(report.get("archetype", "")) == "CORREDOR_CIRCULAR", "unexpected archetype")
	var remote := {"arquetipo_principal": "REFUGIADO_DE_CANTO", "confianca": 0.88}
	var merged: Dictionary = controller.merge_profiles(remote, report)
	_expect(String(merged.get("arquetipo_principal", "")) == "CORREDOR_CIRCULAR", "current run did not override cohort prior")
	_expect(String(merged.get("arquetipo_secundario", "")) == "REFUGIADO_DE_CANTO", "cohort prior not preserved as secondary")
	_expect(controller.finish_run(null, report), "knowledge-only precombat run was not persisted")
	var reloaded := UmbraMemoryController.new()
	reloaded.set_storage_path(TEST_PATH)
	reloaded.begin_run(false, 1)
	var stored: Dictionary = Dictionary(reloaded.persistent_profile.get("knowledge", {}))
	_expect(int(stored.get("total_percent", 0)) == int(report.get("total_percent", -1)), "knowledge persistence mismatch")
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("UMBRA_PRECOMBAT_KNOWLEDGE_OK categories=5 phases=3 private_aggregate=true collective_prior=true")
	quit(0)


func _expect(condition: bool, label: String) -> void:
	if condition:
		return
	push_error("UMBRA_PRECOMBAT_KNOWLEDGE_FAIL " + label)
	quit(1)
