extends SceneTree

const OUTPUT_DIR := "res://.codex/umbra_knowledge"

var game: Node
var capture_size := Vector2i(1280, 720)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("UMBRA_KNOWLEDGE_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--mobile":
			capture_size = Vector2i(960, 540)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = capture_size
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _capture(file_name: String, size: Vector2i) -> void:
	root.size = size
	root.content_scale_size = size
	DisplayServer.window_set_size(size)
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_size() == size, "invalid capture %s expected=%s actual=%s" % [file_name, size, image.get_size() if image != null else Vector2i.ZERO])
	_check(image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR.path_join(file_name))) == OK, "save failed " + file_name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	game._finish_startup_thanks()
	game._start_game()
	game.set_process(false)
	game.mode = "victory"
	game.player_nickname = "OPERADOR TESTE"
	game.time_alive = 427.0
	game.current_phase = 5
	game.enemies_killed = 318
	game.run_damage_to_enemies = 48290.0
	game.run_points_earned = 12640
	game.run_points_spent = 7840
	game.run_report_status = "DOSSIE PREDATORIO CONSOLIDADO"
	game.umbra_run_knowledge = {
		"total_percent": 68,
		"archetype_label": "CORREDOR CIRCULAR",
		"categories": {
			"movement": {"percent": 82}, "shooting": {"percent": 71},
			"choices": {"percent": 64}, "preferences": {"percent": 73},
			"weaknesses": {"percent": 50}
		}
	}
	var file_name := "victory_mobile_960x540.png" if capture_size.x == 960 else "victory_desktop_1280x720.png"
	await _capture(file_name, capture_size)
	print("UMBRA_KNOWLEDGE_VISUAL_OK capture=%s categories=5" % file_name)
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _frame in range(4):
		await process_frame
	quit(0)
