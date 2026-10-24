extends SceneTree

const OUTPUT_DIR := "res://.codex/legendary_card"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("LEGENDARY_CARD_VISUAL_FAIL " + message)
	quit(1)


func _capture(filename: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_check(image != null, "missing_image_%s" % filename)
	_check(image.get_size() == Vector2i(1280, 720), "wrong_size_%s" % filename)
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
	game.run_tutorial_enabled = false
	game.score = 12000
	game.card_cost = 650
	game._open_shop(false)
	game.shop_cards = [
		game._find_card_by_id(game.CARD_PARADOX_ID).duplicate(true),
		game._find_card_by_id("rastro_de_retorno").duplicate(true),
		game._find_card_by_id("Trembo").duplicate(true),
	]
	game.shop_selected = 0
	game.shop_select_pulse_index = 0
	game.shop_select_pulse_timer = 0.2
	await _capture("shop_legendary_compare_1280x720.png")

	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.cards_bought[game.CARD_PARADOX_ID] = 1
	game.paradox_charge_hits = game.PARADOX_HITS_REQUIRED
	game.paradox_ready = false
	game.paradox_active_timer = 3.7
	game.paradox_flash = 0.85
	game.rare_card_effects = [
		{"kind": "paradox_open", "pos": game.player_pos, "life": 0.82, "max": 1.0, "radius": 112.0},
		{"kind": "paradox_echo", "pos": game.player_pos + Vector2(220, -70), "life": 0.34, "max": 0.42, "radius": 54.0},
		{"kind": "paradox_echo", "pos": game.player_pos + Vector2(-210, 95), "life": 0.25, "max": 0.42, "radius": 54.0},
	]
	await _capture("gameplay_legendary_active_1280x720.png")

	print("LEGENDARY_CARD_VISUAL_OK shop=true two_frames=true gameplay_vfx=true hud=true output=%s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for i in range(4):
		await process_frame
	quit(0)
