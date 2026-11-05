extends SceneTree

const EXPECTED_HIDDEN_SPECTERS: Array[String] = [
	"nula",
	"abissal",
	"crepuscular",
	"equilibrista"
]

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("HIDDEN_SELECTION_FAIL " + message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _keys(items: Array) -> Array[String]:
	var keys: Array[String] = []
	for item_value in items:
		keys.append(String(Dictionary(item_value).get("key", "")))
	return keys


func _run() -> void:
	await process_frame
	var canonical_specter_keys: Array[String] = _keys(game.AURAS)
	var visible_specter_keys: Array[String] = _keys(game._manifest_selection_visible_items(true))

	for key in EXPECTED_HIDDEN_SPECTERS:
		_check(canonical_specter_keys.has(key), "specter_removed_from_canonical_data=" + key)
		_check(not visible_specter_keys.has(key), "specter_still_visible=" + key)

	var voracious_index: int = canonical_specter_keys.find("voraz")
	var prophetic_index: int = canonical_specter_keys.find("profetica")
	game.selected_aura = voracious_index
	game._set_selected_aura(voracious_index + 1, false)
	_check(game.selected_aura == prophetic_index, "carousel_did_not_skip_hidden_specters")

	var null_index: int = canonical_specter_keys.find("nula")
	game.unlocked_spectrum_ids["nula"] = true
	game.selected_aura = null_index
	game._open_manifest_select()
	_check(game._spectrum_key(game.selected_aura) == "impulsiva", "legacy_hidden_specter_not_normalized")

	var catalog_tabs: Array = game._catalog_all_items_by_tab()
	var catalog_specter_keys: Array[String] = _keys(catalog_tabs[5])
	for key in EXPECTED_HIDDEN_SPECTERS:
		_check(not catalog_specter_keys.has(key), "hidden_specter_in_catalog=" + key)

	game.unlock_notifications.clear()
	game._queue_unlock_spectrum_by_key("nula", "fixture")
	_check(game.unlock_notifications.is_empty(), "hidden_content_queued_unlock_notification")
	game._open_specter_upgrade("victory", true)
	_check(not EXPECTED_HIDDEN_SPECTERS.has(game._current_specter_key()), "hidden_specter_visible_in_upgrade_screen")

	print("HIDDEN_SPECTERS_SMOKE_OK specters=%d legacy_fallback=true catalog=true notifications=true upgrade=true" % visible_specter_keys.size())
	game.mode = "menu"
	game.visible = false
	game.set_process(false)
	game.set_physics_process(false)
	game._cleanup_runtime_resources()
	for _i in range(4):
		await process_frame
	root.remove_child(game)
	game.free()
	game = null
	quit(0)
