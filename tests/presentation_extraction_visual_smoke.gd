extends SceneTree

var game: Node2D
var captures: int = 0
var failed: bool = false

func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	if picture == null or picture.is_empty() or picture.get_used_rect().size.x < root.size.x * 0.7:
		push_error("PRESENTATION_EXTRACTION_FAIL blank " + label)
		failed = true
		return
	var output: String = "res://.agent_logs/presentation_sweep/" + label + ".png"
	if picture.save_png(output) != OK:
		push_error("PRESENTATION_EXTRACTION_FAIL capture " + label)
		failed = true
	captures += 1

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Presentation smoke requires a rendering display")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs/presentation_sweep"))
	game.set_process(false)
	game.startup_thanks_done = true
	game.run_tutorial_enabled = false
	game.gfx_low_resource = false
	game.gfx_memory_saver = false
	game.gfx_particles = true
	game.gfx_shadows = true
	game.ui_platform_override_unlocked = true
	game.ui_platform_override = "desktop"
	root.mode = Window.MODE_WINDOWED
	await process_frame
	root.size = Vector2i(1280, 720)
	for phase in range(1, 8):
		game._start_game(false)
		game.set_process(false)
		game.current_phase = phase
		game.mode = "game"
		game.player_start_down_fall_timer = 0.0
		game.player_start_down_landing_timer = 0.0
		game.boss_ready = true
		game._start_boss_call_local()
		game.boss_call_timer = 0.01
		game._update_boss_call(0.02)
		game.boss_entry_timer = 0.0
		game.player_pos = Vector2(800, 600)
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(100, 60))
		game._update_boss_attacks(0.1)
		await _capture("phase_%d" % phase)
	game.boss_active = false
	game.current_phase = 1
	for entry in game.MANIFESTATIONS:
		game.manifestation_key = String(entry["key"])
		game.last_skill_time = -1000.0
		game.last_secondary_time = -1000.0
		game._use_skill(game.player_pos + Vector2(100, 0))
		game._use_secondary_skill(game.player_pos + Vector2(100, 0))
		game._update_effects(0.05)
		await _capture("manifest_" + game.manifestation_key)
	for platform in ["desktop", "android"]:
		game.ui_platform_override = platform
		root.size = Vector2i(1280, 720) if platform == "desktop" else Vector2i(960, 540)
		for screen in ["menu", "settings", "settings_audio", "settings_gameplay", "settings_graphics", "paused", "pause_deck", "game_over", "victory"]:
			game.mode = screen
			await _capture(platform + "_" + screen)
	game._cleanup_runtime_resources()
	game.free()
	await process_frame
	print("PRESENTATION_EXTRACTION_VISUAL_OK captures=%d phases=7 desktop=true mobile=true" % captures)
	quit(1 if failed else 0)
