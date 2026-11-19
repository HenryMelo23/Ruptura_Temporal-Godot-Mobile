extends SceneTree

const EXPECTED_KEYS: Array[String] = ["eletrica", "lacerante", "prismatica", "parasitica", "gravitante"]
const ManifestationRosterSaveMigration = preload("res://scripts/systems/save/manifestation_roster_save_migration.gd")
const REMOVED_KEYS: Array[String] = [
	"retornante", "ancorada", "cartografica", "mnesica", "ressonante",
	"contratual", "acorrentada", "eclipsada", "bombastica", "necronada"
]
const LEGACY_KEYS: Array[String] = [
	"eletrica", "lacerante", "prismatica", "retornante", "parasitica",
	"gravitante", "ancorada", "cartografica", "mnesica", "ressonante",
	"contratual", "acorrentada", "eclipsada", "bombastica", "necronada"
]

var game: Node

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFESTATION_ROSTER_FAIL " + message)
	_cleanup(1)

func _keys(items: Array) -> Array[String]:
	var keys: Array[String] = []
	for raw_item in items:
		keys.append(String(Dictionary(raw_item).get("key", "")))
	return keys

func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var roster: Array[String] = _keys(game.MANIFESTATIONS)
	_check(roster == EXPECTED_KEYS, "official_roster=" + str(roster))
	_check(_keys(game._manifest_selection_visible_items(false)) == EXPECTED_KEYS, "selection_roster_drift")
	_check(game.MANIFESTATION_UNLOCK_RULES.keys().size() == 4, "unlock_rule_count")
	for key in EXPECTED_KEYS:
		_check(key == "eletrica" or game.MANIFESTATION_UNLOCK_RULES.has(key), "missing_unlock_rule=" + key)
	for key in REMOVED_KEYS:
		_check(not game.MANIFESTATION_UNLOCK_RULES.has(key), "removed_unlock_rule=" + key)

	var catalog_tabs: Array = game._catalog_all_items_by_tab()
	_check(not catalog_tabs.is_empty(), "catalog_tabs_empty")
	_check(_keys(catalog_tabs[0]) == EXPECTED_KEYS, "catalog_roster=" + str(_keys(catalog_tabs[0])))

	for legacy_index in range(LEGACY_KEYS.size()):
		var legacy_key: String = LEGACY_KEYS[legacy_index]
		var fields: Dictionary = {
			"active_character_key": game.CHARACTER_GEOVANA,
			"selected_manifestation": legacy_index,
			"manifestation_key": legacy_key,
			"manifest_evolution_state": {"manifestation": legacy_key, "stage": 2}
		}
		ManifestationRosterSaveMigration.normalize_snapshot_fields(fields, game.CHARACTER_GEOVANA, game.CHARACTER_HENRY, game.HENRY_SELECTION_INDEX)
		var expected_key: String = legacy_key if EXPECTED_KEYS.has(legacy_key) else "eletrica"
		_check(String(fields.get("manifestation_key", "")) == expected_key, "migration_key=%s got=%s" % [legacy_key, fields.get("manifestation_key", "")])
		_check(int(fields.get("selected_manifestation", -1)) == EXPECTED_KEYS.find(expected_key), "migration_index=" + legacy_key)
		if REMOVED_KEYS.has(legacy_key):
			_check(Dictionary(fields.get("manifest_evolution_state", {})).is_empty(), "removed_evolution_state=" + legacy_key)

	var henry_fields: Dictionary = {
		"active_character_key": game.CHARACTER_HENRY,
		"selected_manifestation": game.HENRY_SELECTION_INDEX,
		"manifestation_key": "colosso"
	}
	ManifestationRosterSaveMigration.normalize_snapshot_fields(henry_fields, game.CHARACTER_GEOVANA, game.CHARACTER_HENRY, game.HENRY_SELECTION_INDEX)
	_check(int(henry_fields.get("selected_manifestation", -1)) == game.HENRY_SELECTION_INDEX, "henry_selection_changed")
	_check(String(henry_fields.get("manifestation_key", "")) == "colosso", "henry_mutation_changed")

	print("MANIFESTATION_ROSTER_SMOKE_OK roster=5 catalog=5 migration=15 henry_preserved=true")
	_cleanup(0)

func _cleanup(code: int) -> void:
	if game != null:
		game.mode = "menu"
		game.visible = false
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)
