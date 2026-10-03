extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("RUNTIME_SAVE_CONTROLLER_SMOKE_FAIL " + message)
	_cleanup(1)


func _remove_user_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _write_user_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "could not write " + path)
	file.store_string(content)
	file.close()


func _cleanup(code := 0) -> void:
	if game != null:
		game.mode = "menu"
		game.visible = false
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)


func _prepare_solo_run() -> void:
	game.is_multiplayer = false
	game.dedicated_server_mode = false
	game.online_connected = false
	game.is_dead = false
	game.player_hp = max(1.0, float(game.player_hp_max))
	game.mode = "game"


func _assert_interrupted_save_blocked(flag_name: String) -> void:
	_remove_user_file(game.INTERRUPTED_RUN_SAVE_PATH)
	_prepare_solo_run()
	game.set(flag_name, true)
	game._save_interrupted_run(true)
	_check(not FileAccess.file_exists(game.INTERRUPTED_RUN_SAVE_PATH), "interrupted run persisted with " + flag_name)
	game.set(flag_name, false)


func _run() -> void:
	_remove_user_file("user://hud_config.save")
	_remove_user_file(game.INTERRUPTED_RUN_SAVE_PATH)

	game.interrupted_run_available = true
	_check(game.save_controller.interrupted_run_available, "interrupted availability adapter did not write controller state")
	game.save_controller.interrupted_run_available = false
	_check(not game.interrupted_run_available, "interrupted availability adapter did not read controller state")
	game.retry_charges_used = 2
	_check(game.save_controller.retry_charges_used == 2, "retry charge adapter did not write controller state")
	game.save_controller.retry_charges_used = 0
	_check(game.retry_charges_used == 0, "retry charge adapter did not read controller state")

	game._load_config()
	_check(not game.qa_streaming_enabled, "missing config should keep qa streaming disabled")

	game.hud_joy_pos = Vector2(101, 202)
	game.hud_attack_pos = Vector2(303, 404)
	game.vol_master = 0.42
	game.online_mode_unlocked = true
	game._save_config()
	game.hud_joy_pos = Vector2.ZERO
	game.hud_attack_pos = Vector2.ZERO
	game.vol_master = 1.0
	game.online_mode_unlocked = false
	game._load_config()
	_check(game.hud_joy_pos == Vector2(101, 202), "config joy_pos was not restored")
	_check(game.hud_attack_pos == Vector2(303, 404), "config attack_pos was not restored")
	_check(is_equal_approx(game.vol_master, 0.42), "config volume was not restored")
	_check(game.online_mode_unlocked, "config unlock flag was not restored")

	_write_user_text("user://hud_config.save", "not_config\nbad=line=with=extra\n")
	game.online_mode_unlocked = true
	game._load_config()
	_check(not game.online_mode_unlocked, "corrupt config should fall back to locked online")

	_write_user_text(game.INTERRUPTED_RUN_SAVE_PATH, "not a snapshot")
	game._load_interrupted_run_summary()
	_check(not game.interrupted_run_available, "corrupt interrupted snapshot should not be available")
	_check(not game._resume_interrupted_run(), "corrupt interrupted snapshot should not resume")
	_check(not FileAccess.file_exists(game.INTERRUPTED_RUN_SAVE_PATH), "corrupt interrupted snapshot should be cleared on resume")

	game._start_game()
	game.mode = "game"
	game.current_phase = 3
	game.time_alive = 123.0
	game.score = 987
	game.player_pos = Vector2(555, 444)
	game.pointer_down = true
	game.move_touch_index = 7
	game.attack_touch_index = 8
	game._update_interrupted_run_autosave(game.INTERRUPTED_RUN_AUTOSAVE_INTERVAL)
	_check(FileAccess.file_exists(game.INTERRUPTED_RUN_SAVE_PATH), "autosave did not create interrupted run snapshot")
	_check(game.interrupted_run_available, "autosave did not mark interrupted run available")
	game.pointer_down = true
	game.move_touch_index = 7
	game.attack_touch_index = 8
	_check(game._resume_interrupted_run(), "interrupted run did not resume")
	_check(game.current_phase == 3, "resume did not restore phase")
	_check(game.score == 987, "resume did not restore score")
	_check(game.player_pos == Vector2(555, 444), "resume did not restore player position")
	_check(not game.pointer_down and game.move_touch_index == -1 and game.attack_touch_index == -1, "resume did not reset transient input")

	game._capture_retry_run_snapshot()
	game.is_dead = true
	game.player_hp = 0.0
	game.mode = "game_over"
	_check(game._retry_available(), "retry snapshot should be available")
	_check(game._use_run_retry(), "retry snapshot did not restore")
	_check(not game.is_dead and game.mode == "game", "retry did not return to active game")

	_assert_interrupted_save_blocked("is_multiplayer")
	_assert_interrupted_save_blocked("dedicated_server_mode")
	_assert_interrupted_save_blocked("online_connected")

	game._clear_interrupted_run_save()
	print("RUNTIME_SAVE_CONTROLLER_SMOKE_OK config=true corrupt=true autosave=true resume=true retry=true blocks=true")
	_cleanup(0)
