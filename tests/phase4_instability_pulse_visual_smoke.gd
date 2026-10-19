extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.gfx_low_resource = "--low" in OS.get_cmdline_user_args()
	game._advance_to_phase(4)
	game.mode = "game"
	game.boss_active = false
	game.boss_call_timer = -1.0
	game.player_pos = game.WORLD_SIZE * 0.5
	assert(game.phase4_instability_pulse_controller.force_start_for_test())
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs/phase4_instability_pulse"))
	var suffix: String = "_low" if game.gfx_low_resource else ""
	var output: String = "res://.agent_logs/phase4_instability_pulse/pulse%s.png" % suffix
	assert(image.save_png(output) == OK)
	print("PHASE4_INSTABILITY_PULSE_VISUAL_OK output=%s" % ProjectSettings.globalize_path(output))
	game.phase4_instability_pulse_controller.reset()
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)
