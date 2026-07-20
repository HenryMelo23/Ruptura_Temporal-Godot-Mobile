extends SceneTree

const SCREENSHOT_PATH := "res://.agent_logs/phase6_miasma_ultimate.png"

var game: Node


func _fail(message: String) -> void:
	push_error("PHASE6_MIASMA_VISUAL_CAPTURE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.force_phase6_start = true
	game.selected_manifestation = 0
	game.selected_aura = 0
	game._start_game()
	game.force_phase6_start = false
	game.current_phase = 6
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = game._boss_hp_for_phase(6)
	game.boss_hp = game.boss_hp_max * 0.25
	game.boss_pos = game.WORLD_SIZE * 0.5
	game._start_boss6_miasma_ultimate()
	for i in range(18):
		game._process(1.0 / 60.0)
		await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("viewport image is empty")
	var path := ProjectSettings.globalize_path(SCREENSHOT_PATH)
	var err := image.save_png(path)
	if err != OK:
		_fail("could not save screenshot: " + error_string(err))
	var sampled_pixels := 0
	var bright_pixels := 0
	for x in range(120, image.get_width(), 80):
		for y in range(90, image.get_height(), 60):
			var color := image.get_pixel(x, y)
			sampled_pixels += 1
			if color.r + color.g + color.b > 0.12:
				bright_pixels += 1
	if sampled_pixels <= 0 or bright_pixels < sampled_pixels / 4:
		_fail("screenshot does not contain enough rendered pixels")
	print("PHASE6_MIASMA_VISUAL_CAPTURE_OK ", path)
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	for i in range(4):
		await process_frame
	quit(0)
