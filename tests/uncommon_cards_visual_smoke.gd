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
		game._find_card_by_id("rastro_de_retorno").duplicate(true),
		game._find_card_by_id("eco_de_impacto").duplicate(true),
		game._find_card_by_id("zona_de_descompressao").duplicate(true),
	]
	game.shop_selected = 1
	game.shop_select_pulse_index = 1
	game.shop_select_pulse_timer = 0.18
	await _capture("shop_uncommon_trio_1280x720.png", Vector2i(1280, 720))

	root.size = Vector2i(960, 540)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game.shop_cards = [
		game._find_card_by_id("ferrolho_ruptura").duplicate(true),
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
	]
	await _capture("gameplay_uncommon_vfx_1280x720.png", Vector2i(1280, 720))

	print("UNCOMMON_CARDS_VISUAL_OK shop_desktop=true shop_mobile=true rarity_compare=true gameplay_vfx=true output=%s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for i in range(4):
		await process_frame
	quit(0)
