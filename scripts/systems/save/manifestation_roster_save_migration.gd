extends RefCounted
class_name RTManifestationRosterSaveMigration

const STABLE_MANIFESTATION_KEYS: Array[String] = [
	"eletrica", "lacerante", "prismatica", "parasitica", "gravitante"
]
const LEGACY_MANIFESTATION_KEYS: Array[String] = [
	"eletrica", "lacerante", "prismatica", "retornante", "parasitica",
	"gravitante", "ancorada", "cartografica", "mnesica", "ressonante",
	"contratual", "acorrentada", "eclipsada", "bombastica", "necronada"
]

static func normalize_legacy_manifestation_key(raw_key: String, raw_index: int = 0) -> String:
	var candidate: String = raw_key.strip_edges().to_lower()
	if candidate == "" and raw_index >= 0 and raw_index < LEGACY_MANIFESTATION_KEYS.size():
		candidate = LEGACY_MANIFESTATION_KEYS[raw_index]
	return candidate if STABLE_MANIFESTATION_KEYS.has(candidate) else "eletrica"

static func stable_manifestation_index(raw_key: String, raw_index: int = 0) -> int:
	return maxi(0, STABLE_MANIFESTATION_KEYS.find(normalize_legacy_manifestation_key(raw_key, raw_index)))

static func normalize_snapshot_fields(fields: Dictionary, geovana_key: String, henry_key: String, henry_selection_index: int) -> void:
	if String(fields.get("active_character_key", geovana_key)) == henry_key:
		fields["selected_manifestation"] = henry_selection_index
		return
	var legacy_index: int = int(fields.get("selected_manifestation", 0))
	var stable_key: String = normalize_legacy_manifestation_key(String(fields.get("manifestation_key", "")), legacy_index)
	fields["selected_manifestation"] = stable_manifestation_index(stable_key, legacy_index)
	fields["manifestation_key"] = stable_key
	var evolution_state: Variant = fields.get("manifest_evolution_state", {})
	if evolution_state is Dictionary and String(evolution_state.get("manifestation", stable_key)) != stable_key:
		fields["manifest_evolution_state"] = {}
