extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("GEOVANA_BARK_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless":
		return
	var dir_path := ProjectSettings.globalize_path("res://.codex")
	DirAccess.make_dir_recursive_absolute(dir_path)
	var texture := root.get_texture()
	_check(texture != null, "viewport texture missing")
	var image := texture.get_image()
	_check(image != null, "viewport image missing")
	var path := ProjectSettings.globalize_path("res://.codex/geovana_bark_%s_%dx%d.png" % [label, root.size.x, root.size.y])
	_check(image.save_png(path) == OK, "screenshot save failed")


func _run() -> void:
	await process_frame
	game._start_game()
	game._finish_startup_thanks()
	game.set_process(false)
	game.run_tutorial_enabled = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.mode = "game"
	game.time_alive = 120.0
	game.player_pos = Vector2(620.0, 420.0)
	game.player_hp = game.player_hp_max
	game.current_phase = 1

	_check(game._geovana_bark("skill_cooldown", {"ability": "Q"}), "skill cooldown bark rejected")
	_check(game.geovana_bark_controller.active_text != "", "active text missing")
	_check(String(game.geovana_bark_controller.active_context) == "skill_cooldown", "wrong active context")
	var short_duration: float = game.geovana_bark_controller._reading_duration_for("Toma essa.")
	var long_duration: float = game.geovana_bark_controller._reading_duration_for("Acham que vao me parar, mas eu preciso chegar la, por voce, meu amor.")
	_check(long_duration > short_duration + 2.0, "reading duration is not scaling with words")
	var first_text: String = String(game.geovana_bark_controller.active_text)
	_check(not game._geovana_bark("enemy_hit", {"damage": 999.0}), "low-priority hit replaced active cooldown bark")
	_check(String(game.geovana_bark_controller.active_text) == first_text, "active bark changed despite lower priority")

	game.geovana_bark_controller.active_timer = 0.0
	game.geovana_bark_controller.global_cooldown = 0.0
	game.geovana_bark_controller.context_cooldowns.clear()
	game.player_hp = int(float(game.player_hp_max) * 0.22)
	game.geovana_bark_controller.update(game, 0.1)
	_check(String(game.geovana_bark_controller.active_context) == "low_health", "low health bark did not trigger")

	game.geovana_bark_controller.active_timer = 0.0
	game.geovana_bark_controller.global_cooldown = 0.0
	game.geovana_bark_controller.context_cooldowns.clear()
	_check(game._geovana_bark("boss_kill", {"phase": 3}), "boss kill bark rejected")
	_check(String(game.geovana_bark_controller.active_context) == "boss_kill", "boss kill context missing")
	game.geovana_bark_controller.update(game, 0.35)

	await _capture("active")
	root.size = Vector2i(960, 540)
	root.content_scale_size = root.size
	game.player_pos = Vector2(560.0, 390.0)
	await _capture("active")
	print("GEOVANA_BARK_CONTROLLER_SMOKE_OK contexts=skill_cooldown,low_health,boss_kill")
	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	quit(0)
