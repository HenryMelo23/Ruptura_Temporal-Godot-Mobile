extends SceneTree

const CatalogRepository = preload("res://scripts/catalog/catalog_repository.gd")
const CatalogValidator = preload("res://scripts/catalog/catalog_validator.gd")

var game: Node


func _fail(message: String) -> void:
	push_error("CATALOG_REPOSITORY_FAIL " + message)
	if game != null:
		game.free()
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _initialize() -> void:
	game = load("res://scripts/main.gd").new()
	call_deferred("_run")


func _run() -> void:
	var all_tabs: Array = game._catalog_all_items_by_tab()
	var report := CatalogValidator.validate(all_tabs)
	_check(bool(report.get("ok", false)), "validator_issues=%s" % str(report.get("issues", [])))
	_check(_catalog_has_no_removed_lore_name(all_tabs), "removed_lore_name_visible")
	_check(CatalogRepository.enemy_entries().size() >= 24, "missing_required_enemies")
	_check(CatalogRepository.boss_entries().size() >= 6, "missing_required_bosses")
	_check(CatalogRepository.faction_entries().size() >= 6, "missing_core_entries")
	game._catalog_reset_tab(2)
	game.catalog_search_query = "Matriarca"
	var boss_results: Array = game._catalog_items()
	_check(boss_results.size() == 1, "boss_search_expected_one")
	_check(String(boss_results[0].get("id", "")) == "matriarca_chaga", "boss_search_wrong_result")
	game._catalog_reset_tab(1)
	game.catalog_search_query = ""
	game.catalog_filter_mode = "support"
	var support_enemies: Array = game._catalog_items()
	_check(support_enemies.any(func(item): return String(item.get("id", "")) == "curater"), "support_filter_missing_curater")
	game.catalog_search_query = ""
	game.catalog_filter_mode = "all"
	var opened: bool = game._catalog_open_related("pinguim_atirador")
	_check(opened, "related_navigation_failed")
	_check(game.catalog_tab == 1, "related_navigation_wrong_tab")
	_check(game.catalog_detail_open, "related_navigation_not_detail")
	print("CATALOG_REPOSITORY_SMOKE_OK total=%d issues=0" % int(report.get("total", 0)))
	game.free()
	game = null
	for _i in range(4):
		await process_frame
	quit(0)


func _catalog_has_no_removed_lore_name(all_tabs: Array) -> bool:
	var forbidden := ("apo" + "lo").to_lower()
	var visible_fields := [
		"id", "name", "short_name", "subtitle", "summary", "desc", "lore",
		"mechanics", "identity_text", "history_text", "mechanics_text",
		"field_note", "classification"
	]
	for tab_entries in all_tabs:
		for raw_item in tab_entries:
			var item := Dictionary(raw_item)
			for field in visible_fields:
				if String(item.get(field, "")).to_lower().find(forbidden) >= 0:
					return false
			for related in item.get("related_entry_ids", []):
				if String(related).to_lower().find(forbidden) >= 0:
					return false
	return true
