extends SceneTree

const Catalog = preload("res://scripts/systems/manifest_evolutions/manifest_evolution_catalog.gd")


func _initialize() -> void:
	var errors: Array = Catalog.validate_catalog()
	if not errors.is_empty():
		push_error("MANIFEST_EVOLUTION_CATALOG_FAIL " + "; ".join(errors))
		quit(1)
		return
	var entries: Array = Catalog.all_entries()
	var ids: Dictionary = {}
	var counts: Dictionary = {}
	for entry in entries:
		var id := String(entry.get("id", ""))
		var manifestation := String(entry.get("manifestation", ""))
		var stage := String(entry.get("stage", ""))
		var family := String(entry.get("family", ""))
		if id == "" or String(entry.get("name", "")) == "" or String(entry.get("short_description", "")) == "":
			push_error("MANIFEST_EVOLUTION_CATALOG_FAIL empty required field")
			quit(1)
			return
		if ids.has(id):
			push_error("MANIFEST_EVOLUTION_CATALOG_FAIL duplicate id " + id)
			quit(1)
			return
		if Catalog.is_legacy_family(family):
			push_error("MANIFEST_EVOLUTION_CATALOG_FAIL legacy family exposed in normal catalog " + id)
			quit(1)
			return
		ids[id] = true
		var key := "%s|%s" % [manifestation, stage]
		counts[key] = int(counts.get(key, 0)) + 1
	if entries.size() != Catalog.TOTAL_EVOLUTIONS:
		push_error("MANIFEST_EVOLUTION_CATALOG_FAIL expected 180 definitions")
		quit(1)
		return
	for manifestation in Catalog.MANIFEST_THEMES.keys():
		for stage in ["ev1", "ev2"]:
			var key := "%s|%s" % [String(manifestation), stage]
			if int(counts.get(key, 0)) != Catalog.EVOLUTIONS_PER_STAGE:
				push_error("MANIFEST_EVOLUTION_CATALOG_FAIL bad count " + key)
				quit(1)
				return
	print("MANIFEST_EVOLUTION_CATALOG_OK definitions=%d manifests=%d per_stage=%d" % [entries.size(), Catalog.MANIFESTATION_COUNT, Catalog.EVOLUTIONS_PER_STAGE])
	quit(0)
