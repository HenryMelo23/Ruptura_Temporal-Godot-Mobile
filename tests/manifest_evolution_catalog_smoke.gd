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
	var prismatica_effects: Dictionary = {}
	var shared_effects: Dictionary = {}
	var definitions: Dictionary = {}
	for stage_profiles in Catalog.STAGE_EFFECTS.values():
		for profile in Array(stage_profiles):
			shared_effects[String(Dictionary(profile).get("effect", ""))] = true
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
		var definition := Catalog.definition_by_id(id)
		if String(definition.get("definition_id", "")) != id or int(definition.get("definition_schema_version", 0)) != Catalog.DEFINITION_SCHEMA_VERSION:
			push_error("MANIFEST_EVOLUTION_CATALOG_FAIL invalid explicit registry entry " + id)
			quit(1)
			return
		if String(definition.get("trigger", "")) == "" or Array(definition.get("conditions", [])).is_empty() or String(definition.get("state_key", "")) == "" or String(definition.get("visual_tag", "")) == "" or String(definition.get("test_target", "")) == "":
			push_error("MANIFEST_EVOLUTION_CATALOG_FAIL incomplete behavior contract " + id)
			quit(1)
			return
		definitions[id] = definition
		if manifestation == "prismatica":
			var effect := String(Dictionary(entry).get("effect", ""))
			if not effect.begins_with("prismatica_"):
				push_error("MANIFEST_EVOLUTION_CATALOG_FAIL Prismatica retained shared effect " + id)
				quit(1)
				return
			if prismatica_effects.has(effect) or shared_effects.has(effect):
				push_error("MANIFEST_EVOLUTION_CATALOG_FAIL Prismatica effect is not exclusive " + effect)
				quit(1)
				return
			prismatica_effects[effect] = true
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
	if prismatica_effects.size() != 12:
		push_error("MANIFEST_EVOLUTION_CATALOG_FAIL Prismatica needs 12 exclusive effects")
		quit(1)
		return
	var arc := Dictionary(definitions.get("eletrica_ev1_arco_condutor", {}))
	var bobina := Dictionary(definitions.get("eletrica_ev1_bobina_ambulante", {}))
	if String(arc.get("effect", "")) == String(bobina.get("effect", "")) or String(arc.get("trigger", "")) == String(bobina.get("trigger", "")):
		push_error("MANIFEST_EVOLUTION_CATALOG_FAIL semantic registry examples collapsed")
		quit(1)
		return
	var legacy_choice := Catalog.normalize_saved_choice({"evolution": "eletrica_ev1_arco_condutor", "family": "projectile_echo", "profile": {"effect": "projectile_echo", "every": 4}})
	if String(legacy_choice.get("definition_id", "")) != "eletrica_ev1_arco_condutor" or int(legacy_choice.get("profile", {}).get("every", 0)) != 4:
		push_error("MANIFEST_EVOLUTION_CATALOG_FAIL legacy choice compatibility")
		quit(1)
		return
	var unknown_choice := Catalog.normalize_saved_choice({"evolution": "legacy_removed_id", "family": "eco"})
	if String(unknown_choice.get("definition_status", "")) != "unknown_legacy":
		push_error("MANIFEST_EVOLUTION_CATALOG_FAIL unknown legacy fallback")
		quit(1)
		return
	print("MANIFEST_EVOLUTION_CATALOG_OK definitions=%d manifests=%d per_stage=%d schema=%d explicit=true" % [entries.size(), Catalog.MANIFESTATION_COUNT, Catalog.EVOLUTIONS_PER_STAGE, Catalog.DEFINITION_SCHEMA_VERSION])
	quit(0)
