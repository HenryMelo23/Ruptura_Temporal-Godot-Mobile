extends SceneTree

var game: Node

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")

func _run() -> void:
	await process_frame
	game.selected_manifestation = 0
	game.selected_aura = 0
	game._start_game()
	game.set_process(false)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 540) if "--mobile" in OS.get_cmdline_user_args() else Vector2i(1280, 720)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.mobile_adaptive_visual_budget = "--mobile" in OS.get_cmdline_user_args()
	game.mode = "game"
	game.startup_thanks_done = true
	game.current_phase = 1
	game.enemies.clear()
	game.boss1_rain_active = true
	game.weather_kind = "rain"
	game.weather_rain_intro_timer = game.WEATHER_RAIN_FADE_TIME
	game.puddles.clear()
	game.rng.seed = 4821
	for offset in [Vector2(-240, 60), Vector2(170, 100), Vector2(290, -90), Vector2(-110, -140)]:
		game._add_rain_puddle(game.player_pos + offset, 65.0, 30.0)
	for i in range(180):
		game._update_rain(1.0 / 60.0)
	var tracked_puddle: Dictionary = game.puddles[0]
	var origin: Vector2 = tracked_puddle["pos"]
	game._spawn_rain_splash(origin)
	for step in range(3):
		for i in range(8):
			game._update_rain(1.0 / 60.0)
		if step == 2:
			game.player_pos += Vector2(100, 40)
		assert(Vector2(tracked_puddle["pos"]) == origin, "Puddle moved with camera")
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		assert(not image.is_empty())
		var label := "before" if "--before" in OS.get_cmdline_user_args() else "after"
		if "--mobile" in OS.get_cmdline_user_args():
			label += "_mobile"
		assert(image.save_png("res://.agent_logs/rain_%s_%d.png" % [label, step]) == OK)
	assert(game.raindrops.size() <= game.WEATHER_MAX_RAIN_DROPS)
	assert(game.rain_splashes.size() <= 90)
	game._clear_environment_weather(true)
	assert(game.puddles.is_empty() and game.rain_splashes.is_empty())
	game._cleanup_runtime_resources()
	game.free()
	print("RAIN_CARTOON_VISUAL_SMOKE_OK captures=3 camera_anchor=true cleanup=true")
	quit()
