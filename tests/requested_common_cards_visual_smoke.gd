extends SceneTree

const OUTPUT_DIR := "res://.codex/requested_common_cards"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("REQUESTED_COMMON_CARDS_VISUAL_FAIL " + message)
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


func _set_size(size: Vector2i) -> void:
	root.size = size
	root.content_scale_size = size
	DisplayServer.window_set_size(size)


func _initialize() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_set_size(Vector2i(1280, 720))
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	game._finish_startup_thanks()
	game._start_game()
	game.set_process(false)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	_set_size(Vector2i(1280, 720))
	await process_frame
	game.run_tutorial_enabled = false
	game.score = 9000
	game.card_cost = 650
	game._open_shop(false)
	game.shop_cards = [
		game._find_card_by_id(game.CARD_MANTO_IMPULSO_ID).duplicate(true),
		game._find_card_by_id(game.CARD_RECUSA_DANO_ID).duplicate(true),
		game._find_card_by_id(game.CARD_CARRASCO_COLOSSOS_ID).duplicate(true),
	]
	game.shop_selected = 1
	game.shop_select_pulse_index = 1
	game.shop_select_pulse_timer = 0.18
	await _capture("shop_manto_recusa_carrasco_1280x720.png", Vector2i(1280, 720))

	_set_size(Vector2i(960, 540))
	game.shop_cards = [
		game._find_card_by_id(game.CARD_ESTASE_ID).duplicate(true),
		game._find_card_by_id(game.CARD_SUTURA_GRADUAL_ID).duplicate(true),
		game._find_card_by_id("Defesa").duplicate(true),
	]
	game.shop_selected = 1
	game.shop_select_pulse_index = 1
	await _capture("shop_estase_sutura_960x540.png", Vector2i(960, 540))

	_set_size(Vector2i(1280, 720))
	game.mode = "game"
	game.player_pos = Vector2(640, 390)
	game.player_hp_max = 1000
	game.player_hp = 640
	game.cards_bought[game.CARD_ESTASE_ID] = 4
	game.cards_bought[game.CARD_MANTO_IMPULSO_ID] = 2
	game.cards_bought[game.CARD_RECUSA_DANO_ID] = 1
	game.cards_bought[game.CARD_CARRASCO_COLOSSOS_ID] = 2
	game.cards_bought[game.CARD_SUTURA_GRADUAL_ID] = 2
	game.estase_reparadora_active = true
	game.estase_reparadora_timer = 5.0
	game.manto_impulso_shield = 120.0
	game.manto_impulso_timer = 3.0
	game.sutura_gradual_pending = 48.0
	game.sutura_gradual_timer = 2.4
	game.boss_active = true
	game.boss_dead = false
	game.boss_pos = Vector2(900, 330)
	game.boss_hp_max = 10000.0
	game.boss_hp = 7400.0
	game.common_card_effects = [
		{"kind": "recusa_dano", "pos": game.player_pos + Vector2(-150, -55), "life": 0.7, "max": 0.7, "radius": 74.0, "color": Color(0.66, 0.82, 1.0)},
		{"kind": "manto_impulso", "pos": game.player_pos, "life": 0.62, "max": 0.62, "radius": 68.0, "color": Color(0.3, 0.88, 1.0)},
		{"kind": "sutura_gradual", "pos": game.player_pos + Vector2(150, 72), "life": 0.55, "max": 0.55, "radius": 60.0, "color": Color(0.52, 1.0, 0.62)},
		{"kind": "carrasco_colossos", "pos": game.boss_pos, "life": 0.36, "max": 0.36, "radius": 92.0, "color": Color(1.0, 0.42, 0.22)},
	]
	await _capture("gameplay_five_common_vfx_1280x720.png", Vector2i(1280, 720))

	print("REQUESTED_COMMON_CARDS_VISUAL_OK shop_desktop=true shop_mobile=true two_frames=true gameplay_vfx=true output=%s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for i in range(4):
		await process_frame
	quit(0)
