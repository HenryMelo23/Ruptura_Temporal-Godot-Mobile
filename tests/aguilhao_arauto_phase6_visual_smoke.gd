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
	var image: Image = root.get_texture().get_image()
	_check(image != null and not image.is_empty() and image.get_size() == size, "invalid screenshot " + label)
	if image != null and not image.is_empty():
		var output: String = ProjectSettings.globalize_path("%s/aguilhao_%s_%dx%d.png" % [OUTPUT_DIR, label, size.x, size.y])
		_check(image.save_png(output) == OK, "could not save " + output)


func _remote_state(pos: Vector2) -> Dictionary:
	return {
		"has_snapshot": true,
		"dead": false,
		"eliminated": false,
		"alive": true,
		"hp": 800.0,
		"hp_max": 800.0,
		"pos": pos,
		"stealthed": false,
	}


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.current_phase = 6
	game.phase_started_at = 0.0
	game.time_alive = game._arauto_spawn_time() + 0.1
	game.boss_ready = false
	game.event_alert_text = ""
	game.event_alert_timer = 0.0
	game.bargain_capsule.clear()
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(790, 420)
	game.enemies.clear()
	game._prepare_phase_texture_assets(6)
	game._spawn_aguilhao_arauto(Vector2(470, 410))
	game.arauto["entry_timer"] = 0.0
	game._start_aguilhao_charge(false)
	await _capture("charge_lane", Vector2i(1280, 720))
	await _capture("charge_lane", Vector2i(960, 540))

	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = true
	game.net_players_by_peer = {
		42: _remote_state(Vector2(620, 280)),
		43: _remote_state(Vector2(980, 520)),
	}
	game._start_aguilhao_pulse()
	await _capture("pulse_targets", Vector2i(1280, 720))
	await _capture("pulse_targets", Vector2i(960, 540))
	game._start_aguilhao_seed(true)
	await _capture("seed_distribution", Vector2i(1280, 720))
	await _capture("seed_distribution", Vector2i(960, 540))

	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _frame in range(3):
		await process_frame
	if not failures.is_empty():
		for failure in failures:
			printerr("AGUILHAO_ARAUTO_PHASE6_VISUAL_FAIL " + failure)
		quit(1)
		return
	print("AGUILHAO_ARAUTO_PHASE6_VISUAL_OK captures=6 charge=true pulse=true seed=true")
	quit(0)
