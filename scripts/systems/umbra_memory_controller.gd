extends RefCounted
class_name RTUmbraMemoryController

# UMBRA 2.0 keeps three intentionally separate memory scopes:
# - work: the policy GRU hidden state, owned by the policy and reset per combat;
# - run: compact aggregates of the local player's recent behaviour;
# - persistent: versioned, aggregate-only local profile between valid runs.
# No coordinates, raw input history, peer IDs, nicknames or policy hidden values
# are persisted. Multiplayer never loads or writes this local profile.
const PERSISTENT_SCHEMA_VERSION := 2
const DEFAULT_STORAGE_PATH := "user://umbra_mind/behavior_profile_v2.json"
const MIN_SAMPLES_TO_PERSIST := 4
const PROFILE_METRICS := ["evade_rate", "distance_preference", "dash_rate", "aggression_rate", "response_rate"]
const KNOWLEDGE_CATEGORIES := ["movement", "shooting", "choices", "preferences", "weaknesses"]
const KNOWLEDGE_LABELS := {
	"movement": "MOVIMENTO",
	"shooting": "DISPARO",
	"choices": "ESCOLHAS",
	"preferences": "PREFERENCIAS",
	"weaknesses": "FRAQUEZAS"
}

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


func knowledge_report(runtime: Object) -> Dictionary:
	if runtime == null or not is_instance_valid(runtime):
		return _empty_knowledge_report()
	var behavior: Dictionary = runtime.call("_run_behavior_report") if runtime.has_method("_run_behavior_report") else {}
	var cards: Array = runtime.call("_cards_report_rows") if runtime.has_method("_cards_report_rows") else []
	var damage_hits: Dictionary = Dictionary(runtime.get("run_damage_hits_by_source"))
	var damage_totals: Dictionary = Dictionary(runtime.get("run_damage_taken_by_source"))
	var damage_meta: Dictionary = Dictionary(runtime.get("run_damage_source_meta"))
	var phase_seconds: Dictionary = Dictionary(behavior.get("phase_seconds", {}))
	var duration := maxf(0.0, float(runtime.get("time_alive")))
	var move_samples := maxi(0, int(runtime.get("run_behavior_move_samples"))) + maxi(0, int(runtime.get("run_behavior_stationary_samples")))
	var phases_observed := 0
	for seconds in phase_seconds.values():
		if float(seconds) >= 8.0:
			phases_observed += 1
	var shots := maxi(0, int(behavior.get("shots_fired", 0)))
	var hits := maxi(0, int(behavior.get("hits", 0)))
	var dashes := maxi(0, int(behavior.get("dash_count", 0)))
	var card_total := 0
	for card_value in cards:
		card_total += maxi(0, int(Dictionary(card_value).get("count", 0)))
	var distinct_cards := cards.size()
	var damage_hit_count := 0
	for hit_count in damage_hits.values():
		damage_hit_count += maxi(0, int(hit_count))
	var damage_total := 0.0
	for damage_value in damage_totals.values():
		damage_total += maxf(0.0, float(damage_value))
	var hp_max := maxf(1.0, float(runtime.get("player_hp_max")))
	var base_choices := 0
	if String(runtime.get("manifestation_key")) != "" or String(runtime.get("mutation_key")) != "":
		base_choices += 1
	var aura_state: Dictionary = Dictionary(runtime.get("aura_state"))
	if String(aura_state.get("name", "")) != "" or String(runtime.get("effect_key")) != "":
		base_choices += 1

	var movement_score := 100.0 * (
		0.42 * _saturation(duration, 150.0)
		+ 0.38 * _saturation(float(move_samples), 160.0)
		+ 0.20 * clampf(float(phases_observed) / 3.0, 0.0, 1.0)
	)
	var shooting_score := 100.0 * (
		0.60 * _saturation(float(shots), 110.0)
		+ 0.25 * _saturation(float(hits), 36.0)
		+ 0.15 * _saturation(duration, 180.0)
	)
	var choices_score := 100.0 * (
		0.30 * clampf(float(base_choices) / 2.0, 0.0, 1.0)
		+ 0.45 * _saturation(float(card_total), 8.0)
		+ 0.25 * _saturation(float(distinct_cards), 5.0)
	)
	var preferences_score := 100.0 * (
		0.36 * _saturation(duration, 210.0)
		+ 0.24 * _saturation(float(shots + dashes * 3), 120.0)
		+ 0.20 * _saturation(float(card_total), 7.0)
		+ 0.20 * clampf(float(phases_observed) / 3.0, 0.0, 1.0)
	)
	var weaknesses_score := 100.0 * (
		0.52 * _saturation(float(damage_hit_count), 14.0)
		+ 0.25 * _saturation(float(damage_hits.size()), 5.0)
		+ 0.23 * _saturation(damage_total / hp_max, 2.2)
	)
	var top_damage_source := _top_damage_source(damage_totals, damage_meta)
	var categories := {
		"movement": _category(movement_score, _movement_insight(behavior)),
		"shooting": _category(shooting_score, _shooting_insight(behavior)),
		"choices": _category(choices_score, _choice_insight(card_total, distinct_cards)),
		"preferences": _category(preferences_score, _preference_insight(behavior, dashes, shots)),
		"weaknesses": _category(weaknesses_score, _weakness_insight(damage_hit_count, top_damage_source))
	}
	var total := 0.0
	for key in KNOWLEDGE_CATEGORIES:
		total += float(Dictionary(categories[key]).get("percent", 0.0))
	total /= float(KNOWLEDGE_CATEGORIES.size())
	var archetype := _classify_archetype(behavior, damage_total, duration)
	return {
		"schema_version": 1,
		"total_percent": int(round(clampf(total, 0.0, 100.0))),
		"categories": categories,
		"archetype": archetype,
		"archetype_label": _archetype_label(archetype),
		"sample_seconds": snappedf(duration, 0.1),
		"phases_observed": phases_observed,
		"evidence": {
			"move_samples": move_samples, "shots": shots, "hits": hits, "dashes": dashes,
			"cards": card_total, "distinct_cards": distinct_cards,
			"damage_hits": damage_hit_count, "damage_sources": damage_hits.size()
		},
		"behavior_vector": {
			"edge_ratio": clampf(float(behavior.get("edge_ratio", 0.0)), 0.0, 1.0),
			"corner_ratio": clampf(float(behavior.get("corner_ratio", 0.0)), 0.0, 1.0),
			"center_ratio": clampf(float(behavior.get("center_ratio", 0.0)), 0.0, 1.0),
			"stationary_ratio": clampf(float(behavior.get("stationary_ratio", 0.0)), 0.0, 1.0),
			"dash_per_minute": maxf(0.0, float(behavior.get("dash_per_minute", 0.0))),
			"shots_per_minute": maxf(0.0, float(behavior.get("shots_per_minute", 0.0))),
			"hit_rate": clampf(float(behavior.get("hit_rate", 0.0)), 0.0, 1.0),
			"damage_taken_per_minute": damage_total / maxf(1.0, duration) * 60.0
		}
	}


func profile_from_knowledge(report: Dictionary) -> Dictionary:
	var archetype := String(report.get("archetype", "SOBREVIVENTE_ADAPTATIVO"))
	return {
		"arquetipo_principal": archetype,
		"arquetipo_secundario": "INDEFINIDO",
		"confianca": clampf(float(report.get("total_percent", 0)) / 100.0, 0.0, 0.92),
		"historico_arquetipos": [archetype],
		"conhecimento": report.duplicate(true),
		"fonte": "run_atual"
	}


func merge_profiles(remote_profile: Dictionary, run_report: Dictionary) -> Dictionary:
	var local := profile_from_knowledge(run_report)
	var local_confidence := float(local.get("confianca", 0.0))
	var remote_confidence := clampf(float(remote_profile.get("confianca", 0.0)), 0.0, 0.92)
	if local_confidence < 0.20 and not remote_profile.is_empty():
		var remote := remote_profile.duplicate(true)
		remote["arquetipo_secundario"] = String(local.get("arquetipo_principal", "INDEFINIDO"))
		remote["conhecimento"] = run_report.duplicate(true)
		remote["confianca"] = maxf(remote_confidence * 0.55, local_confidence)
		remote["fonte"] = "coorte_com_validacao_local"
		return remote
	if not remote_profile.is_empty():
		local["arquetipo_secundario"] = String(remote_profile.get("arquetipo_principal", "INDEFINIDO"))
		local["confianca"] = clampf(local_confidence * 0.82 + remote_confidence * 0.18, 0.0, 0.92)
		local["fonte"] = "run_atual_com_prior_coletivo"
	return local


func finish_run(policy: Object = null, knowledge: Dictionary = {}) -> bool:
	if not run_active:
		return false
	var has_run_knowledge := float(knowledge.get("sample_seconds", 0.0)) >= 30.0
	var should_persist := not multiplayer_isolated and (int(run_profile.get("samples", 0)) >= MIN_SAMPLES_TO_PERSIST or has_run_knowledge)
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
		if not knowledge.is_empty():
			persistent_profile["knowledge"] = knowledge.duplicate(true)
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
	if raw.get("knowledge", {}) is Dictionary:
		profile["knowledge"] = Dictionary(raw.get("knowledge", {})).duplicate(true)
	return profile


static func _empty_persistent_profile() -> Dictionary:
	var metrics: Dictionary = {}
	for key in PROFILE_METRICS:
		metrics[key] = 0.0
	return {"schema_version": PERSISTENT_SCHEMA_VERSION, "runs_observed": 0, "metrics": metrics, "knowledge": _empty_knowledge_report()}


static func _empty_run_profile() -> Dictionary:
	return {
		"samples": 0, "distance_sum": 0.0, "dash_count": 0, "aggression_count": 0,
		"threat_samples": 0, "threat_responses": 0, "last_position": Vector2.ZERO,
		"has_previous_position": false, "last_dash_marker": -1.0, "last_attack_marker": -1.0
	}


static func _saturation(value: float, target: float) -> float:
	return 1.0 - exp(-maxf(0.0, value) / maxf(0.001, target))


static func _category(score: float, insight: String) -> Dictionary:
	return {"percent": int(round(clampf(score, 0.0, 100.0))), "insight": insight}


static func _empty_knowledge_report() -> Dictionary:
	var categories := {}
	for key in KNOWLEDGE_CATEGORIES:
		categories[key] = _category(0.0, "Evidencia insuficiente")
	return {"schema_version": 1, "total_percent": 0, "categories": categories, "archetype": "INDEFINIDO", "archetype_label": "PERFIL INDEFINIDO", "sample_seconds": 0.0, "phases_observed": 0, "evidence": {}, "behavior_vector": {}}


static func _movement_insight(behavior: Dictionary) -> String:
	if float(behavior.get("corner_ratio", 0.0)) >= 0.12:
		return "Busca cantos sob pressao"
	if float(behavior.get("edge_ratio", 0.0)) >= 0.34:
		return "Prefere as bordas da arena"
	if float(behavior.get("stationary_ratio", 0.0)) >= 0.34:
		return "Interrompe o movimento com frequencia"
	return "Mantem deslocamento frequente"


static func _shooting_insight(behavior: Dictionary) -> String:
	var rate := float(behavior.get("shots_per_minute", 0.0))
	var accuracy := float(behavior.get("hit_rate", 0.0))
	if rate >= 48.0 and accuracy < 0.34:
		return "Dispara muito e corrige depois"
	if accuracy >= 0.52:
		return "Prioriza disparos confirmados"
	if rate < 18.0:
		return "Ataca em janelas curtas"
	return "Mantem cadencia moderada"


static func _choice_insight(card_total: int, distinct_cards: int) -> String:
	if card_total <= 1:
		return "Build ainda pouco definida"
	if distinct_cards >= 5:
		return "Distribui recursos entre varias respostas"
	return "Concentra compras em poucos efeitos"


static func _preference_insight(behavior: Dictionary, dashes: int, shots: int) -> String:
	if float(behavior.get("center_ratio", 0.0)) >= 0.32:
		return "Disputa o centro da arena"
	if dashes * 4 > shots:
		return "Prioriza mobilidade sobre pressao"
	if shots >= 80:
		return "Prioriza pressao ofensiva"
	return "Alterna cautela e agressao"


static func _weakness_insight(hit_count: int, source: String) -> String:
	if hit_count <= 0:
		return "Nenhuma fraqueza confirmada"
	if source != "":
		return "Maior exposicao: " + source
	return "Repetiu falhas defensivas"


static func _top_damage_source(totals: Dictionary, meta: Dictionary) -> String:
	var top_key := ""
	var top_damage := -1.0
	for key_value in totals.keys():
		var value := float(totals.get(key_value, 0.0))
		if value > top_damage:
			top_damage = value
			top_key = String(key_value)
	if top_key == "":
		return ""
	var row: Dictionary = Dictionary(meta.get(top_key, {}))
	return String(row.get("name", top_key)).replace("_", " ").capitalize()


static func _classify_archetype(behavior: Dictionary, damage_total: float, duration: float) -> String:
	var edge := float(behavior.get("edge_ratio", 0.0))
	var corner := float(behavior.get("corner_ratio", 0.0))
	var dash := float(behavior.get("dash_per_minute", 0.0))
	var shots := float(behavior.get("shots_per_minute", 0.0))
	var hit_rate := float(behavior.get("hit_rate", 0.0))
	var stationary := float(behavior.get("stationary_ratio", 0.0))
	var damage_per_minute := damage_total / maxf(1.0, duration) * 60.0
	if corner >= 0.12 or edge >= 0.34:
		return "REFUGIADO_DE_CANTO"
	if dash >= 8.0:
		return "DEPENDENTE_DE_DASH"
	if shots >= 48.0 and hit_rate < 0.34:
		return "ATIRADOR_DISTANTE"
	if stationary < 0.14 and edge < 0.22:
		return "CORREDOR_CIRCULAR"
	if damage_per_minute >= 120.0 and edge < 0.25:
		return "AGRESSOR_IMPULSIVO"
	return "SOBREVIVENTE_ADAPTATIVO"


static func _archetype_label(archetype: String) -> String:
	return {
		"REFUGIADO_DE_CANTO": "REFUGIADO DE CANTO",
		"DEPENDENTE_DE_DASH": "DEPENDENTE DE DASH",
		"ATIRADOR_DISTANTE": "ATIRADOR DISTANTE",
		"CORREDOR_CIRCULAR": "CORREDOR CIRCULAR",
		"AGRESSOR_IMPULSIVO": "AGRESSOR IMPULSIVO",
		"SOBREVIVENTE_ADAPTATIVO": "SOBREVIVENTE ADAPTATIVO"
	}.get(archetype, "PERFIL INDEFINIDO")
