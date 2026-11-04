extends SceneTree

## Capturas da Fenda do Mercador e da nevoa-guia (fenda e altar).
## Uso: godot --headless --path . --script res://tests/merchant_rift_visual_smoke.gd [-- --low]

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.active_character_key = game.CHARACTER_GEOVANA
	game._start_game()
	game.set_process(false)
	game.set_physics_process(false)
	game.startup_thanks_done = true
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	game.show_fps_counter = false
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.enemies.clear()
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.gfx_low_resource = "--low" in OS.get_cmdline_user_args()
	game.mode = "game"
	game.is_multiplayer = false
	game.shop_auto_enabled = true
	game.shop_rift_controller.allow_rift = true
	game.time_alive = 12.35
	var rift_controller = game.shop_rift_controller
	var suffix := "_low" if game.gfx_low_resource else ""
	var output_dir := "res://.agent_logs/merchant_rift"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))

	var base: Vector2 = (game.WORLD_SIZE * 0.5).floor()
	game.player_pos = base
	rift_controller.spawn("visual", base + Vector2(250.0, -30.0))
	game.shop_rift["state_age"] = rift_controller.OPEN_TIME * 0.38
	await _capture(output_dir + "/rift_opening_1280x720%s.png" % suffix, Vector2i(1280, 720))

	game.shop_rift["state"] = rift_controller.STATE_OPEN
	game.shop_rift["state_age"] = 2.0
	game.shop_rift["age"] = 4.0
	await _capture(output_dir + "/rift_open_1280x720%s.png" % suffix, Vector2i(1280, 720))
	await _capture(output_dir + "/rift_open_mobile_960x540%s.png" % suffix, Vector2i(960, 540))

	game.shop_rift_fragments = 1
	game.shop_rift["age"] = rift_controller.LIFETIME - 2.5
	game.player_pos = base + Vector2(90.0, 20.0)
	rift_controller.update(0.0)
	await _capture(output_dir + "/rift_unstable_near_1280x720%s.png" % suffix, Vector2i(1280, 720))

	game.shop_rift["age"] = 6.0
	game.shop_rift["warned_unstable"] = false
	game.player_pos = base + Vector2(250.0, -30.0) + Vector2(-1100.0, 380.0)
	game.player_pos = game.player_pos.clamp(Vector2(120.0, 120.0), game.WORLD_SIZE - Vector2(120.0, 120.0))
	await _capture(output_dir + "/rift_guide_offscreen_1280x720%s.png" % suffix, Vector2i(1280, 720))
	await _capture(output_dir + "/rift_guide_offscreen_mobile_960x540%s.png" % suffix, Vector2i(960, 540))

	game.player_pos = base
	game.shop_rift["state"] = rift_controller.STATE_COLLAPSING
	game.shop_rift["state_age"] = rift_controller.COLLAPSE_TIME * 0.55
	await _capture(output_dir + "/rift_collapsing_1280x720%s.png" % suffix, Vector2i(1280, 720))
	rift_controller.clear_active()

	var altar_captured := false
	if game.experimental_phase_controller.uses_definitive_world():
		game.experimental_boss_altar_discovered = true
		game.experimental_boss_altar_used = false
		var altar: Vector2 = Vector2(game.experimental_boss_altar_pos)
		var guide_pos: Vector2 = altar + Vector2(-950.0, 260.0)
		if guide_pos.x < 120.0:
			guide_pos = altar + Vector2(950.0, 260.0)
		game.player_pos = guide_pos.clamp(Vector2(120.0, 120.0), game.WORLD_SIZE - Vector2(120.0, 120.0))
		await _capture(output_dir + "/altar_mist_guide_1280x720%s.png" % suffix, Vector2i(1280, 720))
		game.player_pos = altar + (game.player_pos - altar).normalized() * 430.0
		await _capture(output_dir + "/altar_mist_arrival_1280x720%s.png" % suffix, Vector2i(1280, 720))
		altar_captured = true

	print("MERCHANT_RIFT_VISUAL_OK opening=true open=true unstable=true offscreen_guide=true collapsing=true altar_mist=%s low=%s dir=%s" % [str(altar_captured), str(game.gfx_low_resource), ProjectSettings.globalize_path(output_dir)])
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)


func _capture(path: String, size: Vector2i) -> void:
	root.size = size
	game.queue_redraw()
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	assert(image != null)
	assert(image.save_png(path) == OK)
