extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PHASE6_ART_ASSETS_FAIL " + message)
	quit(1)


func _check_texture_array(key: String, expected_size: int) -> void:
	_check(game.textures.has(key), "missing texture key " + key)
	var frames = game.textures.get(key, [])
	_check(frames is Array, "texture key is not an array " + key)
	_check(frames.size() == expected_size, "wrong frame count for " + key)
	for index in range(frames.size()):
		_check(frames[index] is Texture2D, "null frame %d for %s" % [index, key])


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame

	var exact_paths := [
		"res://assets/sprites/Boss6-1-1.png",
		"res://assets/sprites/Boss6-1-2.png",
		"res://assets/sprites/Boss6-1-3.png",
		"res://assets/sprites/Boss6-1-4.png",
		"res://assets/sprites/Boss6-2-1.png",
		"res://assets/sprites/Boss6-2-2.png",
		"res://assets/sprites/Boss6-2-3.png",
		"res://assets/sprites/Boss6-2-4.png",
		"res://assets/sprites/Boss6-3-1.png",
		"res://assets/sprites/Boss6-3-2.png",
		"res://assets/sprites/Boss6-3-3.png",
		"res://assets/sprites/Boss6-3-4.png",
		"res://assets/sprites/Fase6.png",
		"res://assets/sprites/enquiadomiasma1.png",
		"res://assets/sprites/enquiadomiasma2.png",
		"res://assets/sprites/lodario1.png",
		"res://assets/sprites/lodario2.png",
		"res://assets/sprites/pustulafossil1.png",
		"res://assets/sprites/pustulafossil2.png",
		"res://assets/sprites/sanguesugacronal1.png",
		"res://assets/sprites/sanguesugacronal2.png"
	]
	for path in exact_paths:
		_check(ResourceLoader.exists(path), "resource path does not resolve " + path)

	_check_texture_array("boss6_form_1", 4)
	_check_texture_array("boss6_form_2", 4)
	_check_texture_array("boss6_form_3", 4)
	_check_texture_array("enemy_phase_6_enguia_miasma", 2)
	_check_texture_array("enemy_phase_6_lodario", 2)
	_check_texture_array("enemy_phase_6_pustula_fossil", 2)
	_check_texture_array("enemy_phase_6_sanguessuga_cronal", 2)

	game.current_phase = 6
	game.boss_hp_max = 1000.0
	game.boss_phase = 0.0
	game.boss_hp = 1000.0
	_check(game._boss6_form_key() == "boss6_form_1", "boss6 form 1 threshold failed")
	_check(game._boss_texture() == game.textures["boss6_form_1"][0], "boss6 form 1 texture failed")
	game.boss_hp = 550.0
	_check(game._boss6_form_key() == "boss6_form_2", "boss6 form 2 threshold failed")
	_check(game._boss_texture() == game.textures["boss6_form_2"][0], "boss6 form 2 texture failed")
	game.boss_hp = 400.0
	_check(game._boss6_form_key() == "boss6_form_3", "boss6 form 3 threshold failed")
	_check(game._boss_texture() == game.textures["boss6_form_3"][0], "boss6 form 3 texture failed")

	var enemy_texture_keys := {
		game.ENEMY_MIASMA_EEL: "enemy_phase_6_enguia_miasma",
		game.ENEMY_LODARIO: "enemy_phase_6_lodario",
		game.ENEMY_FOSSIL_PUSTULE: "enemy_phase_6_pustula_fossil",
		game.ENEMY_CHRONAL_LEECH: "enemy_phase_6_sanguessuga_cronal"
	}
	var enemy_report_icons := {
		game.ENEMY_MIASMA_EEL: "enquiadomiasma1.png",
		game.ENEMY_LODARIO: "lodario1.png",
		game.ENEMY_FOSSIL_PUSTULE: "pustulafossil1.png",
		game.ENEMY_CHRONAL_LEECH: "sanguesugacronal1.png"
	}
	for kind in enemy_texture_keys.keys():
		var enemy := {"type": String(kind), "phase": 0.0, "pos": game.player_pos, "hp": 10.0, "max_hp": 10.0}
		var key := String(enemy_texture_keys[kind])
		_check(game._phase6_enemy_texture_key(String(kind)) == key, "phase6 texture key failed for " + String(kind))
		_check(game._enemy_texture(enemy) == game.textures[key][0], "phase6 enemy texture failed for " + String(kind))
		_check(game.NET_ENEMY_TYPES.has(String(kind)), "network type missing for " + String(kind))
		_check(game._enemy_report_icon(String(kind), 6) == String(enemy_report_icons[kind]), "report icon mismatch for " + String(kind))

	var catalog_names := []
	for item in game._catalog_enemy_items():
		catalog_names.append(String(item.get("name", "")))
	_check(catalog_names.has("Enguia do Miasma"), "catalog missing Enguia do Miasma")
	_check(catalog_names.has("Lodario"), "catalog missing Lodario")
	_check(catalog_names.has("Pustula Fossil"), "catalog missing Pustula Fossil")
	_check(catalog_names.has("Sanguessuga Cronal"), "catalog missing Sanguessuga Cronal")

	game.current_phase = 1
	game._apply_remote_boss_snapshot(PackedFloat32Array([10.0, 20.0, 500.0, 0.0, 1.0, 6.0, 1000.0, 0.0]), Time.get_ticks_msec())
	_check(game.current_phase == 6, "remote boss snapshot clamped phase 6")
	_check(game._current_map_texture() == game.textures["map_phase_6"], "phase6 map texture failed")

	print("PHASE6_ART_ASSETS_SMOKE_OK boss_forms=3 enemy_types=4 exact_paths=21 network_phase=6")
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	for i in range(4):
		await process_frame
	quit(0)
