extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	var previous_retornante: bool = game.retornante_unlocked
	var previous_qa: bool = game.qa_data_unlocked
	var previous_fps: bool = game.show_fps_counter
	game.retornante_unlocked = false
	var retornante_index := -1
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i].get("key", "")) == "retornante":
			retornante_index = i
			break
	assert(retornante_index >= 0)
	assert(not game._manifestation_unlocked(retornante_index))
	game.retornante_unlocked = true
	game._load_config()
	assert(not game._manifestation_unlocked(retornante_index))
	game.gameplay_cheat_text = "QA231021"
	assert(game._try_unlock_retornante_cheat())
	assert(not game._manifestation_unlocked(retornante_index))
	game.gameplay_cheat_text = "Geovaninha"
	assert(game._try_unlock_retornante_cheat())
	assert(game._manifestation_unlocked(retornante_index))

	game.show_fps_counter = false
	game._handle_gameplay_settings_touch(game._gameplay_preferences_rects(Vector2(1280, 720))["fps"].get_center(), Vector2(1280, 720))
	assert(game.show_fps_counter)

	var aura_scale: float = game.hud_aura_panel_scale
	var cards_scale: float = game.hud_cards_panel_scale
	var coagulum_scale: float = game.hud_coagulum_scale
	game._adjust_layout_box_scale("aura_panel", 0.1)
	game._adjust_layout_box_scale("cards_panel", 0.1)
	game._adjust_layout_box_scale("coagulum", 0.1)
	assert(game.hud_aura_panel_scale > aura_scale)
	assert(game.hud_cards_panel_scale > cards_scale)
	assert(game.hud_coagulum_scale > coagulum_scale)
	game.retornante_unlocked = previous_retornante
	game.qa_data_unlocked = previous_qa
	game.show_fps_counter = previous_fps
	game.hud_aura_panel_scale = aura_scale
	game.hud_cards_panel_scale = cards_scale
	game.hud_coagulum_scale = coagulum_scale
	game._save_config()

	print("HUD_FPS_RETORNANTE_SMOKE_OK fps=true cheat=true scalable_hud=true")
	quit(0)
