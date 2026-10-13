extends SceneTree

const OUTPUT_DIR := "res://.agent_logs"

var game: Node
var failures: Array[String] = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _capture(label: String, size: Vector2i) -> void:
	root.size = size
	root.content_scale_size = size
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image != null and not image.is_empty() and image.get_size() == size, "invalid screenshot " + label)
	if image != null and not image.is_empty():
		var output := ProjectSettings.globalize_path("%s/amber_suturer_%s_%dx%d.png" % [OUTPUT_DIR, label, size.x, size.y])
		_check(image.save_png(output) == OK, "could not save " + output)


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	game.run_tutorial_enabled = false
	game._start_game()
	game.mode = "game"
	game.boss_call_tutorial_seen = true
	game.shop_tutorial_seen = true
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.current_phase = 6
	game.phase_started_at = 0.0
	game.time_alive = 205.0
	game.boss_active = false
	game.boss_dead = false
	game.boss_ready = false
	game.boss_call_timer = -1.0
	game.phase_transition_timer = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(780, 470)
	game.geovana_bark_controller.active_text = ""
	game.geovana_bark_controller.active_timer = 0.0
	game.geovana_bark_controller.next_ambient_at = INF
	game.enemies.clear()
	game._prepare_phase_texture_assets(6)
	var controller = game.amber_suturer_controller
	controller.reset_for_new_run()
	var enemy: Dictionary = controller.spawn_now()
	_check(not enemy.is_empty(), "visual fixture could not spawn Suturador")
	var atlas: Texture2D = game.textures.get("enemy_phase_6_suturador_ambar")
	_check(atlas != null and atlas.get_size() == Vector2(724, 540), "Suturador sprite sheet is missing or malformed")
	enemy["pos"] = Vector2(510, 410)
	controller._history_by_peer = {0: [{"time": 203.8, "pos": Vector2(470, 470)}, {"time": 204.9, "pos": Vector2(780, 470)}]}
	controller._begin_suture_cycle(enemy)
	await _capture("telegraph", Vector2i(1280, 720))
	await _capture("telegraph", Vector2i(960, 540))
	controller._activate_sutures(enemy)
	await _capture("active", Vector2i(1280, 720))
	await _capture("active", Vector2i(960, 540))
	controller.on_enemy_defeated(enemy)
	game.enemies.erase(enemy)
	await _capture("death_cleanup", Vector2i(1280, 720))

	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _frame in range(3):
		await process_frame
	if not failures.is_empty():
		for failure in failures:
			printerr("PHASE6_AMBER_SUTURER_VISUAL_FAIL " + failure)
		quit(1)
		return
	print("PHASE6_AMBER_SUTURER_VISUAL_OK captures=5 sprite=true telegraph=true active=true cleanup=true")
	quit(0)
