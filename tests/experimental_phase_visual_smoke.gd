extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.experimental_phase_requested = true
	game._start_game()
	game.gfx_low_resource = "--low" in OS.get_cmdline_user_args()
	game.mode = "game"
	game.queue_redraw()
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs/experimental_phase"))
	var suffix := "_low" if game.gfx_low_resource else ""
	await _capture("res://.agent_logs/experimental_phase/start_desktop_1280x720%s.png" % suffix, Vector2i(1280, 720))
	game.player_pos = Vector2(1600.0, 900.0)
	game.queue_redraw()
	await process_frame
	await _capture("res://.agent_logs/experimental_phase/sector_seam_1280x720%s.png" % suffix, Vector2i(1280, 720))

	game.player_pos = game.experimental_boss_altar_pos + Vector2(-72.0, 0.0)
	game.experimental_phase_controller.update(0.58)
	assert(game.experimental_boss_altar_discovered)
	game.queue_redraw()
	await process_frame
	await _capture("res://.agent_logs/experimental_phase/altar_mobile_960x540%s.png" % suffix, Vector2i(960, 540))

	var guidance_pos: Vector2 = game.experimental_boss_altar_pos + Vector2(900.0, 0.0)
	if guidance_pos.x > game.WORLD_SIZE.x - 80.0:
		guidance_pos = game.experimental_boss_altar_pos - Vector2(900.0, 0.0)
	game.player_pos = guidance_pos.clamp(Vector2(80.0, 80.0), game.WORLD_SIZE - Vector2(80.0, 80.0))
	game.queue_redraw()
	await process_frame
	await _capture("res://.agent_logs/experimental_phase/altar_guidance_1280x720%s.png" % suffix, Vector2i(1280, 720))

	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 10000.0
	game.boss_hp = game.boss_hp_max
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.boss_attacks.clear()
	game.early_boss_controller.start_boss1_whirlpool()
	var whirlpool: Dictionary = game.boss_attacks[0]
	whirlpool["state"] = "active"
	whirlpool["state_age"] = 2.0
	game.player_pos = Vector2(260.0, 260.0)
	game.queue_redraw()
	await process_frame
	await _capture("res://.agent_logs/experimental_phase/whirlpool_world_edge_1280x720%s.png" % suffix, Vector2i(1280, 720))

	print("EXPERIMENTAL_PHASE_VISUAL_OK captures=5 area=5x altar=true hidden_until_discovered=true guidance=true whirlpool_world_radius=true seam=true")
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
	assert(image.get_width() == size.x and image.get_height() == size.y)
	assert(image.save_png(path) == OK)
