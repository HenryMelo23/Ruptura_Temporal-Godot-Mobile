extends SceneTree

func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)

func _initialize() -> void:
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run", game)

func _run(game: Node) -> void:
	await process_frame
	var expected := {
		"crepuscular": "res://Game Base/Ruptura_Temporal-APOLO2.0/Sprites/aurea-eclipsa.png",
		"peregrino": "res://Game Base/Ruptura_Temporal-APOLO2.0/Sprites/aurea-peregrina.png",
		"equilibrista": "res://Game Base/Ruptura_Temporal-APOLO2.0/Sprites/aurea-equilibrista.png",
		"avarento": "res://Game Base/Ruptura_Temporal-APOLO2.0/Sprites/aurea-avarenta.png",
		"oportunista": "res://Game Base/Ruptura_Temporal-APOLO2.0/Sprites/aurea-oportunista.png",
	}
	_check(game.AURAS.size() == 15, "selector count is not 15")
	for aura in game.AURAS:
		var key := String(aura.get("key", ""))
		if expected.has(key):
			var icon_path := String(aura.get("icon", ""))
			_check(icon_path == expected[key], "wrong icon path for " + key)
			_check(FileAccess.file_exists(ProjectSettings.globalize_path(icon_path)), "icon path does not resolve on disk: " + icon_path)
			_check(game.textures.get("aura_" + key) != null, "aura texture did not load: " + key)
			game.selected_aura = game.AURAS.find(aura)
			game._start_game()
			_check(String(game.aura_state.get("name", "")) == String(aura.get("name", "")), "selected aura state mismatch for " + key)
			_check(game._aura_color() != Color.WHITE, "missing aura color for " + key)
			var details: Dictionary = game._aura_details(String(aura.get("name", "")))
			_check(String(details.get("funcao", "")).length() > 20, "missing details for " + key)
	_check(expected.keys().all(func(k): return game.AURAS.any(func(a): return String(a.get("key", "")) == String(k))), "one or more new auras missing from selector")
	print("NEW_AURAS_REGISTRATION_SMOKE_OK count=15 icons=true details=true")
	root.remove_child(game)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0)
