extends SceneTree

const OUTPUT_DIR := "res://.codex/uncommon_cards"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("UNCOMMON_CARDS_VISUAL_FAIL " + message)
	quit(1)


func _capture(filename: String, expected_size: Vector2i) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_check(image != null, "missing_image_%s" % filename)
	_check(image.get_size() == expected_size, "wrong_size_%s_expected_%s_actual_%s" % [filename, expected_size, image.get_size()])
	var path: String = ProjectSettings.globalize_path(OUTPUT_DIR.path_join(filename))
	_check(image.save_png(path) == OK, "save_failed_%s" % filename)


func _initialize() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	game._finish_startup_thanks()
	game._start_game()
	game.set_process(false)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	await process_frame
	game.run_tutorial_enabled = false
	game.score = 8000
	game.card_cost = 650
	game._open_shop(false)
	game.shop_cards = [
		game._find_card_by_id("fragmentacao_reativa").duplicate(true),
		game._find_card_by_id("bastiao_inercial").duplicate(true),
		game._find_card_by_id("horizonte_ruptura").duplicate(true),
	]
	game.shop_selected = 1
	game.shop_select_pulse_index = 1
	game.shop_select_pulse_timer = 0.18
	await _capture("shop_new_uncommon_trio_1280x720.png", Vector2i(1280, 720))

	root.size = Vector2i(960, 540)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game.shop_cards = [
		game._find_card_by_id("ressonancia_de_alternancia").duplicate(true),
		game._find_card_by_id("Speed Boost").duplicate(true),
		game._find_card_by_id("Trembo").duplicate(true),
	]
	game.shop_selected = 0
	game.shop_select_pulse_index = 0
	await _capture("shop_rarity_compare_960x540.png", Vector2i(960, 540))

	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.cards_bought["rastro_de_retorno"] = 1
	game.cards_bought["eco_de_impacto"] = 1
	game.cards_bought["zona_de_descompressao"] = 1
	game.cards_bought["ferrolho_ruptura"] = 1
	game.cards_bought["municao_de_rebate"] = 1
	game.cards_bought["impulso_de_sobras"] = 1
	game.cards_bought["margem_de_erro"] = 1
	game.cards_bought["ressonancia_de_alternancia"] = 1
	game.cards_bought["fragmentacao_reativa"] = 1
	game.cards_bought["bastiao_inercial"] = 1
	game.reactive_survival_card_controller.stationary_time = game.reactive_survival_card_controller.BASTION_SETTLE_TIME
	game.reactive_survival_card_controller.stationary_strength = 1.0
	game.reactive_survival_card_controller.fragments = [
		{"pos": game.player_pos + Vector2(-36, -18), "target_pos": game.player_pos + Vector2(-180, -100), "life": 0.5, "max": 0.72},
		{"pos": game.player_pos + Vector2(34, -20), "target_pos": game.player_pos + Vector2(190, -90), "life": 0.5, "max": 0.72},
		{"pos": game.player_pos + Vector2(-28, 32), "target_pos": game.player_pos + Vector2(-170, 125), "life": 0.5, "max": 0.72},
		{"pos": game.player_pos + Vector2(31, 30), "target_pos": game.player_pos + Vector2(175, 130), "life": 0.5, "max": 0.72},
	]
	game.ferrolho_ruptura_armed = true
	game.zona_charge = 0.72
	game.rastro_vestiges = [
		{"pos": game.player_pos + Vector2(-170, 60), "life": 12.0, "max": 16.0, "arm": 0.0, "phase": 0.2},
		{"pos": game.player_pos + Vector2(170, -55), "life": 9.0, "max": 16.0, "arm": 0.0, "phase": 2.1},
	]
	game.common_card_effects = [
		{"kind": "eco_charge", "pos": game.player_pos + Vector2(-80, -20), "life": 1.0, "max": 1.0, "radius": 42.0, "progress": 0.8},
		{"kind": "eco", "pos": game.player_pos + Vector2(150, 75), "life": 1.0, "max": 1.0, "radius": 82.0},
		{"kind": "zona", "pos": game.player_pos, "life": 1.0, "max": 1.0, "radius": 190.0},
		{"kind": "ferrolho", "pos": game.player_pos + Vector2(0, -125), "life": 1.0, "max": 1.0, "radius": 66.0},
		{"kind": "rastro_return", "pos": game.player_pos + Vector2(-170, 60), "life": 1.0, "max": 1.0, "radius": 86.0},
		{"kind": "rebate", "pos": game.player_pos + Vector2(-250, -110), "life": 1.0, "max": 1.0, "radius": 62.0},
		{"kind": "impulso", "pos": game.player_pos + Vector2(250, -105), "life": 1.0, "max": 1.0, "radius": 68.0},
		{"kind": "margem_clear", "pos": game.player_pos + Vector2(-245, 145), "life": 1.0, "max": 1.0, "radius": 68.0},
		{"kind": "ressonancia_ready", "pos": game.player_pos + Vector2(245, 145), "life": 1.0, "max": 1.0, "radius": 78.0},
		{"kind": "fragmentacao_reativa", "pos": game.player_pos, "life": 0.5, "max": 0.5, "radius": 150.0},
	]
	await _capture("gameplay_uncommon_vfx_1280x720.png", Vector2i(1280, 720))

	print("UNCOMMON_CARDS_VISUAL_OK cards=10 shop_desktop=true shop_mobile=true rarity_compare=true gameplay_vfx=true reactive_cards=true output=%s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for i in range(4):
		await process_frame
	quit(0)
