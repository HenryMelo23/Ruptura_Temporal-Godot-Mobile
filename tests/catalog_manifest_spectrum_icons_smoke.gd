extends SceneTree

var game: Node

const EXPECTED_MANIFEST_ICONS := {
	"eclipsada": "res://assets/sprites/manifestacao-eclipsada.png",
	"necronada": "res://assets/sprites/manifestacao-necronada.png"
}

const EXPECTED_SPECTRUM_ICONS := {
	"crepuscular": "res://assets/sprites/aurea-eclipsa.png",
	"peregrino": "res://assets/sprites/aurea-peregrina.png",
	"equilibrista": "res://assets/sprites/aurea-equilibrista.png",
	"avarento": "res://assets/sprites/aurea-avarenta.png",
	"oportunista": "res://assets/sprites/aurea-oportunista.png"
}


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("CATALOG_MANIFEST_SPECTRUM_ICONS_FAIL " + message)
	quit(1)


func _check_icon_packable(icon_path: String, label: String) -> void:
	_check(icon_path.begins_with("res://assets/sprites/"), "icon must live in exported sprite assets: " + label)
	_check(FileAccess.file_exists(icon_path), "missing icon source file: " + label)
	_check(FileAccess.file_exists(icon_path + ".import"), "missing icon import metadata for Android export: " + label)
	_check(ResourceLoader.exists(icon_path), "icon is not visible to ResourceLoader: " + label)


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
		if EXPECTED_MANIFEST_ICONS.has(key):
			_check(String(item.get("icon", "")) == String(EXPECTED_MANIFEST_ICONS[key]), "wrong manifestation icon path: " + key)
			_check_icon_packable(String(EXPECTED_MANIFEST_ICONS[key]), "manifestation " + key)
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
		if EXPECTED_SPECTRUM_ICONS.has(key):
			_check(String(item.get("icon", "")) == String(EXPECTED_SPECTRUM_ICONS[key]), "wrong spectrum icon path: " + key)
			_check_icon_packable(String(EXPECTED_SPECTRUM_ICONS[key]), "spectrum " + key)
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
