extends SceneTree

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
	game.geovana_bark_controller.active_text = ""
	game.geovana_bark_controller.active_timer = 0.0
	root.size = size
	root.content_scale_size = size
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() == "headless":
		return
	var image := root.get_texture().get_image()
	_check(image != null and image.get_size() == size, "invalid capture " + label)
	if image != null:
		var output := ProjectSettings.globalize_path("res://.agent_logs/sineiro_%s_%dx%d.png" % [label, size.x, size.y])
		_check(image.save_png(output) == OK, "could not save " + output)


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs"))
	game.run_tutorial_enabled = false
	game._start_game()
	game.mode = "game"
	game.boss_call_tutorial_seen = true
	game.shop_tutorial_seen = true
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.current_phase = 2
	game.phase_started_at = 0.0
	game.time_alive = 310.0
	game.boss_ready = false
	game.geovana_bark_controller.next_ambient_at = INF
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(800, 450)
	game.enemies.clear()
	game.enemy_bullets.clear()
	game._prepare_phase_texture_assets(2)
	var controller = game.sineiro_boreal_controller
	controller.reset_for_new_run()
	var enemy: Dictionary = controller.spawn_now()
	_check(not enemy.is_empty(), "visual fixture could not spawn")
	var motion: Texture2D = game.textures.get("sineiro_boreal_motion")
	var death: Texture2D = game.textures.get("sineiro_boreal_death")
	_check(motion != null and motion.get_size() == Vector2(1536, 1024), "motion atlas missing or malformed")
	_check(death != null and death.get_size() == Vector2(1536, 256), "death atlas missing or malformed")
	enemy["pos"] = Vector2(620, 430)
	enemy["sineiro_state"] = controller.STATE_APPROACH
	enemy["last_move_dir"] = Vector2.RIGHT
	await _capture("idle_walk", Vector2i(1280, 720))

	controller._history_by_peer = {0: [{"time": 307.8, "pos": Vector2(720, 370)}, {"time": 308.8, "pos": Vector2(860, 500)}]}
	controller._begin_echo_attack(enemy)
	enemy["sineiro_state_timer"] = 0.58
	await _capture("echo_telegraph", Vector2i(1280, 720))
	await _capture("echo_telegraph", Vector2i(960, 540))
	controller._execute_echo_attack(enemy)
	await _capture("echo_impact_exhausted", Vector2i(1280, 720))

	enemy["sineiro_state"] = controller.STATE_APPROACH
	controller._begin_shard_attack(enemy, Vector2(1050, 420))
	await _capture("shard_telegraph", Vector2i(960, 540))
	controller._execute_shard_attack(enemy)
	await _capture("shard_attack", Vector2i(1280, 720))

	controller.on_enemy_defeated(enemy)
	game.enemies.erase(enemy)
	controller._update_local_visual_state(0.72)
	await _capture("death_reward", Vector2i(1280, 720))
	await _capture("death_reward", Vector2i(960, 540))

	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _frame in range(3):
		await process_frame
	if not failures.is_empty():
		for failure in failures:
			printerr("PHASE2_SINEIRO_VISUAL_FAIL " + failure)
		quit(1)
		return
	print("PHASE2_SINEIRO_VISUAL_OK captures=8 atlas=true telegraphs=true death=true")
	quit(0)
