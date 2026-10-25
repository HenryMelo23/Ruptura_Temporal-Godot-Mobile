extends SceneTree

const OUT_DESKTOP := "res://.agent_logs/acorrentada_evolutions_1280x720.png"
const OUT_MOBILE := "res://.agent_logs/acorrentada_evolutions_960x540.png"

var game: Node2D
var title: Label


func _initialize() -> void:
	call_deferred("_run")


func _capture(path: String, expected_size: Vector2i) -> void:
	for _frame in range(8):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		push_error("ACORRENTADA_EVOLUTION_VISUAL_FAIL null capture " + path)
		quit(1)
		return
	if image.get_size() != expected_size:
		push_error("ACORRENTADA_EVOLUTION_VISUAL_FAIL size %s expected %s" % [str(image.get_size()), str(expected_size)])
		quit(1)
		return
	if image.save_png(path) != OK:
		push_error("ACORRENTADA_EVOLUTION_VISUAL_FAIL save " + path)
		quit(1)


func _entry(stage: String, index: int) -> Dictionary:
	return Dictionary(game._manifest_evolution_entries("acorrentada", stage)[index])


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("ACORRENTADA_EVOLUTION_VISUAL requires a renderer")
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
	game.selected_manifestation = 11
	game.manifestation_key = "acorrentada"
	game.boss_ready = true
	game.tutorial_state = game.TUTORIAL_STATE_NONE
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
	# EV1 Grilhao Movel + EV2 Teia De Grilhoes exposes the two persistent
	# silhouettes: a cyan pursuing shackle and the red physical damage network.
	game.manifest_evolution_options = [_entry("ev1", 2)]
	game._choose_manifest_evolution(0)
	game.manifest_evolution_options = [_entry("ev2", 0)]
	game._choose_manifest_evolution(0)
	for position in [Vector2(610, 280), Vector2(915, 300), Vector2(905, 505), Vector2(620, 520)]:
		game._spawn_enemy(game.ENEMY_COMMON, position)
		game.enemies.back()["hp"] = 100000.0
		game.enemies.back()["max_hp"] = 100000.0
	var first: Dictionary = game.enemies[0]
	game._manifest_evolution_on_combat_hit("visual:mobile", "acorrentada", first, Vector2(first["pos"]))
	game._manifest_evolution_on_skill(Vector2(770, 400))
	game.set_process(false)
	game.acorrentada_worn_chains.clear()
	game.effects.clear()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	title = Label.new()
	title.text = "ACORRENTADA / GRILHAO MOVEL + TEIA DE GRILHOES"
	title.position = Vector2(28, 674)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.78, 0.94, 1.0))
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(title)
	await _capture(OUT_DESKTOP, Vector2i(1280, 720))
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	title.position = Vector2(18, 500)
	await _capture(OUT_MOBILE, Vector2i(960, 540))
	print("ACORRENTADA_EVOLUTION_VISUAL_OK desktop=1280x720 mobile=960x540 synced_segments=true")
	game._cleanup_runtime_resources()
	game.queue_free()
	layer.queue_free()
	for _frame in range(4):
		await process_frame
	quit(0)
