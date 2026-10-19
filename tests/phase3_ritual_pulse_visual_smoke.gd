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
	game._advance_to_phase(3)
	game.mode = "game"
	game.boss_active = false
	game.boss_call_timer = -1.0
	game.player_pos = game.WORLD_SIZE * 0.5
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(510.0, 360.0))
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(1080.0, 540.0))
	game._spawn_enemy(game.ENEMY_INCENSARIO, Vector2(1180.0, 280.0))
	assert(game.phase3_ritual_pulse_controller.force_start_for_test())
	var marked: Array = game.enemies.filter(func(enemy): return bool(Dictionary(enemy).get("phase3_ritual_marked", false)))
	if not marked.is_empty():
		var devotee: Dictionary = marked[0]
		var snapshot: Dictionary = game.phase3_ritual_pulse_controller.active_snapshot()
		for value in Array(snapshot.get("circles", [])):
			var circle: Dictionary = value
			if int(circle.get("id", -1)) == int(devotee.get("phase3_ritual_circle_id", -2)):
				devotee["pos"] = Vector2(circle.get("pos", devotee.get("pos", Vector2.ZERO)))
				game._update_phase3_enemy(devotee, 3.0)
				break
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs/phase3_ritual_pulse"))
	var suffix: String = "_low" if "--low" in OS.get_cmdline_user_args() else ""
	var output: String = "res://.agent_logs/phase3_ritual_pulse/ritual%s.png" % suffix
	assert(image.save_png(output) == OK)
	print("PHASE3_RITUAL_PULSE_VISUAL_OK output=%s" % ProjectSettings.globalize_path(output))
	game.phase3_ritual_pulse_controller.reset()
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)
