extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.selected_manifestation = 1
	game.selected_aura = 4
	game._open_manifest_select()
	_check(game.mode == "manifest", "manifest selector did not open")
	_check(game.manifest_select_stage == game.MANIFEST_STAGE_MANIFESTATION, "selector did not start on manifestation stage")
	_check(game._manifest_select_item_texture(game.MANIFESTATIONS[1], false) != null, "manifestation icon was not loaded")
	_check(game._manifest_select_item_texture(game.AURAS[4], true) != null, "aura icon was not loaded")
	for key in ["ui_manifest_switch", "ui_spectrum_switch", "shop_countdown_tick", "player_shot", "eletrica_travel", "eletrica_hit", "atk_lacerante_1", "atk_lacerante_2", "atk_lacerante_3", "prismatica_glass_hit", "prismatica_shatter", "retornante_reverse", "retornante_wave", "parasitica_wet_hit", "gravitante_attach", "gravitante_orbit_loop"]:
		_check(game.audio_streams.has(key), "missing current sfx: " + key)
	for old_key in ["atk_eletrica", "atk_eletrica_charged", "atk_prismatica", "atk_retornante", "atk_parasitica", "atk_gravitante", "atk_ancorada", "ult_eletrica", "ult_gravitante", "Disparo_Geo.wav", "Disparo.MP3"]:
		_check(not game.audio_streams.has(old_key), "legacy weapon sfx was loaded: " + old_key)
	game._set_selected_manifestation(2, true)
	_check(game.selected_manifestation == 2, "manifestation sfx selection changed behavior")
	game._set_selected_aura(5, true)
	_check(game.selected_aura == 5, "spectrum sfx selection changed behavior")
	game.queue_redraw()
	await process_frame
	_check(game.buttons.has("manifest_preview"), "manifest preview button was not drawn")
	game._handle_manifest_touch(game.buttons["manifest_preview"].get_center(), Vector2(1280, 720))
	_check(game.manifest_preview_open, "manifest preview popup did not open")
	game.queue_redraw()
	await process_frame
	_check(game.buttons.has("manifest_preview_popup"), "manifest preview popup rect was not stored")
	_check(game.buttons.has("manifest_preview_atk"), "manifest preview ATK tab was not drawn")
	_check(game.buttons.has("manifest_preview_skill"), "manifest preview Q tab was not drawn")
	_check(game.buttons.has("manifest_preview_ultimate"), "manifest preview E tab was not drawn")
	game._handle_manifest_touch(game.buttons["manifest_preview_ultimate"].get_center(), Vector2(1280, 720))
	_check(game.manifest_preview_open, "manifest preview tab touch closed popup")
	_check(game.manifest_preview_kind == "ultimate", "manifest preview tab did not switch to ultimate")
	game.manifest_preview_kind = "atk"
	var popup_center: Vector2 = game.buttons["manifest_preview_popup"].get_center()
	game._handle_manifest_touch(popup_center, Vector2(1280, 720))
	_check(game.manifest_preview_open, "manifest preview inner touch closed popup")
	game._start_manifest_drag(77, popup_center, Vector2(1280, 720))
	game._update_manifest_drag(popup_center + Vector2(-180, 0), Vector2(1280, 720))
	game._finish_manifest_drag(popup_center + Vector2(-180, 0), Vector2(1280, 720))
	_check(game.manifest_preview_open, "manifest preview swipe closed popup")
	_check(game.manifest_preview_kind == "skill", "manifest preview swipe left did not switch to Q")
	game._start_manifest_drag(78, popup_center, Vector2(1280, 720))
	game._update_manifest_drag(popup_center + Vector2(180, 0), Vector2(1280, 720))
	game._finish_manifest_drag(popup_center + Vector2(180, 0), Vector2(1280, 720))
	_check(game.manifest_preview_kind == "atk", "manifest preview swipe right did not return to ATK")
	game._handle_manifest_touch(game.buttons["manifest_preview_popup"].get_center(), Vector2(1280, 720))
	_check(game.manifest_preview_open, "manifest preview center touch closed popup")
	game._handle_manifest_touch(Vector2(24, 24), Vector2(1280, 720))
	_check(not game.manifest_preview_open, "manifest preview outside touch did not close")

	game._start_spectrum_reveal()
	_check(game.manifest_select_stage == game.MANIFEST_STAGE_TRANSITION, "spectrum reveal did not enter transition")
	game.manifest_transition_elapsed = game.MANIFEST_SPECTRUM_TRANSITION_TIME * 0.55
	game.queue_redraw()
	await process_frame
	game.manifest_transition_elapsed = game.MANIFEST_SPECTRUM_TRANSITION_TIME
	game._process(0.016)
	_check(game.manifest_select_stage == game.MANIFEST_STAGE_AURA, "spectrum reveal did not finish on aura stage")
	game.queue_redraw()
	await process_frame

	game._set_selected_aura(9, false)
	_check(game.selected_aura == 9, "aura carousel selection failed")
	game._start_game()
	_check(String(game.aura_state.get("name", "")) == String(game.AURAS[9]["name"]), "start game did not use selected spectrum aura")

	print("MANIFEST_SPECTRUM_SELECT_SMOKE_OK stage=true transition=true aura_assets=true sfx=true preview=true")
	quit(0)
