extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("CATALOG_MANIFEST_SPECTRUM_ICONS_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_check(game._catalog_tab_label(4) == "ESPECTROS", "catalog tab 4 should be Espectros")

	game.catalog_tab = 0
	var manifest_items: Array = game._catalog_items()
	_check(manifest_items.size() == game.MANIFESTATIONS.size(), "catalog manifestation list is not synchronized")
	for item in game.MANIFESTATIONS:
		var key := String(item.get("key", ""))
		_check(game._manifest_select_item_texture(item, false) != null, "selector missing manifestation icon: " + key)
		_check(game._catalog_item_texture(item) != null, "catalog missing manifestation icon: " + key)
		var description := String(game._catalog_detail_description(item))
		var mechanics := String(game._catalog_detail_mechanics(item))
		_check(description.length() > 35, "catalog manifestation description too shallow: " + key)
		_check(mechanics.length() > 35 and mechanics.contains("Risco:"), "catalog manifestation mechanics missing: " + key)

	game.catalog_tab = 4
	var spectrum_items: Array = game._catalog_items()
	_check(spectrum_items.size() == game.AURAS.size(), "catalog spectrum list is not synchronized")
	for item in game.AURAS:
		var key := String(item.get("key", ""))
		_check(game._manifest_select_item_texture(item, true) != null, "selector missing spectrum icon: " + key)
		_check(game._catalog_item_texture(item) != null, "catalog missing spectrum icon: " + key)
		var description := String(game._catalog_detail_description(item))
		var mechanics := String(game._catalog_detail_mechanics(item))
		_check(description.length() > 35, "catalog spectrum description too shallow: " + key)
		_check(mechanics.length() > 35 and mechanics.contains("Risco:"), "catalog spectrum mechanics missing: " + key)

	print("CATALOG_MANIFEST_SPECTRUM_ICONS_SMOKE_OK manifests=%d spectrums=%d" % [game.MANIFESTATIONS.size(), game.AURAS.size()])
	game.visible = false
	game.set_process(false)
	game.set_physics_process(false)
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.manifest_preview_atlases.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	await process_frame
	await process_frame
	quit(0)
