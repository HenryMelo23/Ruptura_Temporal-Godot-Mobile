extends SceneTree

const OUT_MOVE := "res://.agent_logs/prismatica_skin_move_1280x720.png"
const OUT_FIRE := "res://.agent_logs/prismatica_skin_fire_1280x720.png"
const OUT_ENTRY := "res://.agent_logs/prismatica_skin_entry_960x540.png"
const OUT_DANCE := "res://.agent_logs/prismatica_skin_dance_1280x720.png"

var game: Node2D
var caption: Label


func _initialize() -> void:
	call_deferred("_run")


func _capture(path: String, expected_size: Vector2i) -> void:
	for frame in range(6):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != expected_size or image.save_png(path) != OK:
		push_error("PRISMATICA_SPRITE_SKIN_VISUAL_FAIL capture " + path)
		quit(1)


func _prepare_game() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.run_tutorial_enabled = false
	game._start_game()
	game.shop_tutorial_seen = true
	game.boss_call_tutorial_seen = true
	game._reset_tutorial_state()
	game._finish_startup_thanks()
	game.startup_thanks_teaser_available = false
	game.mode = "game"
	game.manifestation_key = "prismatica"
	game.selected_manifestation = game._manifestation_index_for_key("prismatica", -1)
	game.player_pos = Vector2(640, 390)
	game.last_facing = Vector2.RIGHT
	game.gfx_screen_shake = false
	game.gfx_particles = true
	game.gfx_low_resource = false
	game.gfx_memory_saver = false
	game.mobile_adaptive_visual_budget = false
	game.time_alive = 25.0
	game.last_attack_time = -999.0
	game.last_damage_time = -999.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	# Keep each authored state frozen long enough for a deterministic screenshot.
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var layer := CanvasLayer.new()
	root.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(24, 24)
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_color_override("font_color", Color(0.80, 0.97, 1.0))
	caption.add_theme_color_override("font_shadow_color", Color(0.03, 0.01, 0.08, 1.0))
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(caption)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("PRISMATICA_SPRITE_SKIN_VISUAL requires a renderer")
		quit(1)
		return
	_prepare_game()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)

	caption.text = "PRISMATICA / MOVIMENTO DIMENSIONAL"
	game.move_touch_index = 0
	game.touch_move = Vector2.RIGHT
	await _capture(OUT_MOVE, Vector2i(1280, 720))
	game.move_touch_index = -1
	game.touch_move = Vector2.ZERO

	caption.text = "PRISMATICA / DISPARO FACETADO"
	game.player_attack_visual_dir = Vector2(1.0, -1.0).normalized()
	game.last_attack_time = game.time_alive
	await _capture(OUT_FIRE, Vector2i(1280, 720))
	game.last_attack_time = -999.0

	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	game.player_pos = Vector2(480, 300)
	caption.text = "PRISMATICA / ENTRADA PELA FENDA"
	game.player_start_down_fall_timer = game.PLAYER_START_DOWN_FALL_TIME * 0.18
	await _capture(OUT_ENTRY, Vector2i(960, 540))
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0

	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	game.player_pos = Vector2(640, 390)
	caption.text = "PRISMATICA / DANCA DE OUTRA DIMENSAO"
	game._use_secondary_skill()
	await _capture(OUT_DANCE, Vector2i(1280, 720))

	print("PRISMATICA_SPRITE_SKIN_VISUAL_OK move=1280x720 fire=1280x720 entry=960x540 dance=1280x720")
	game._cleanup_runtime_resources()
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
