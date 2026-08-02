extends SceneTree

const SCREENSHOT_PATH := "res://.agent_logs/phase6_miasma_ecdysis.png"

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
	game.startup_thanks_done = true
	game.mode = "game"
	game.force_phase6_start = false
	game.current_phase = 6
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = game._boss_hp_for_phase(6)
	game.boss_hp = game.boss_hp_max * 0.25
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(-360.0, 220.0)
	game._start_boss6_miasma_ecdysis()
	game.boss6_miasma_ult_angle = -PI * 0.16
	game.boss_attacks.clear()
	var impact_time: float = game._boss6_relocation_rain_impact_time()
	var warning_target: Vector2 = game.player_pos + Vector2(130, -20)
	game.boss_attacks.append({"kind": game.BOSS6_ATTACK_RELOCATION_RAIN, "age": 0.02, "duration": impact_time + game.BOSS6_NEW_SWARM_RAIN_SPLASH_TIME, "target": warning_target, "hit_local": false, "phase": 0.3, "fall_side": -45.0})
	game._add_text("!", warning_target + Vector2(0.0, -78.0), Color(1.0, 0.92, 0.18), game.BOSS6_NEW_SWARM_RAIN_WARNING, 32)
	game.boss_attacks.append({"kind": game.BOSS6_ATTACK_RELOCATION_RAIN, "age": game.BOSS6_NEW_SWARM_RAIN_WARNING + 0.28, "duration": impact_time + game.BOSS6_NEW_SWARM_RAIN_SPLASH_TIME, "target": game.player_pos + Vector2(270, -95), "hit_local": false, "phase": 1.8, "fall_side": 55.0})
	game.boss_attacks.append({"kind": game.BOSS6_ATTACK_RELOCATION_RAIN, "age": impact_time + 0.18, "duration": impact_time + game.BOSS6_NEW_SWARM_RAIN_SPLASH_TIME, "target": game.player_pos + Vector2(410, -8), "hit_local": true, "phase": 3.1, "fall_side": 20.0})
	for i in range(18):
		game._process(1.0 / 60.0)
		await process_frame
	if not game._boss6_miasma_ultimate_active():
		_fail("miasma ecdysis did not activate")
		return
	if game.boss6_organs.size() != 4:
		_fail("miasma ecdysis did not create four organs")
		return
	game.queue_redraw()
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
	var red_warning_pixels := 0
	for x in range(120, image.get_width(), 80):
		for y in range(90, image.get_height(), 60):
			var color := image.get_pixel(x, y)
			sampled_pixels += 1
			if color.r + color.g + color.b > 0.12:
				bright_pixels += 1
			if color.r > 0.55 and color.g < 0.28 and color.b < 0.28:
				red_warning_pixels += 1
	if sampled_pixels <= 0 or bright_pixels < sampled_pixels / 4:
		_fail("screenshot does not contain enough rendered pixels")
	if red_warning_pixels <= 0:
		_fail("screenshot did not include visible red rain warning")
	print("PHASE6_MIASMA_VISUAL_CAPTURE_OK ", path)
	_cleanup()
	quit(0)


func _cleanup() -> void:
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
