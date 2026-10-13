extends SceneTree

const OUT_DESKTOP := "res://.agent_logs/prismatica_evolutions_1280x720.png"
const OUT_MOBILE := "res://.agent_logs/prismatica_evolutions_960x540.png"

var game: Node2D
var title: Label


func _initialize() -> void:
	call_deferred("_run")


func _capture(path: String, expected_size: Vector2i) -> void:
	for frame in range(8):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != expected_size or image.save_png(path) != OK:
		push_error("PRISMATICA_EVOLUTION_VISUAL_FAIL capture " + path)
		quit(1)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("PRISMATICA_EVOLUTION_VISUAL requires a renderer")
		quit(1)
		return
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
	game.player_pos = Vector2(640, 400)
	game.last_facing = Vector2.RIGHT
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.gfx_screen_shake = false
	game.gfx_particles = true
	game.gfx_low_resource = false
	game.gfx_memory_saver = false
	game.mobile_adaptive_visual_budget = false
	game.time_alive = 16.0
	game._reset_manifest_evolution_state()
	var ev1: Dictionary = game._manifest_evolution_entries("prismatica", "ev1")[1]
	var ev2: Dictionary = game._manifest_evolution_entries("prismatica", "ev2")[4]
	game.manifest_evolution_options = [ev1]
	game._choose_manifest_evolution(0)
	game.manifest_evolution_options = [ev2]
	game._choose_manifest_evolution(0)
	game._manifest_evolution_on_skill(Vector2(760, 390))
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(760, 278))
	game._update_manifest_evolution_effects(0.70)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	title = Label.new()
	title.text = "PRISMATICA / PRISMA ESPELHADO + REDE ESPECTRAL"
	title.position = Vector2(28, 674)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.78, 0.96, 1.0))
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(title)
	await _capture(OUT_DESKTOP, Vector2i(1280, 720))
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	title.position = Vector2(18, 500)
	await _capture(OUT_MOBILE, Vector2i(960, 540))
	print("PRISMATICA_EVOLUTION_VISUAL_OK desktop=1280x720 mobile=960x540")
	game._cleanup_runtime_resources()
	game.queue_free()
	layer.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
