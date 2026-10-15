extends SceneTree

const OUTPUT_DIR := "res://.agent_logs/fps_counter"

var game: Node
var failures: Array[String] = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
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
	_check(image != null and not image.is_empty(), "empty capture " + label)
	if image != null and not image.is_empty():
		var path: String = ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT_DIR, label])
		_check(image.get_size() == size, "wrong capture size " + label)
		_check(image.save_png(path) == OK, "could not save " + path)


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.current_phase = 1
	game.show_fps_counter = true
	game.ui_platform_override_unlocked = true
	game.ui_platform_override = "desktop"
	_check(game._should_draw_desktop_fps_counter(), "desktop counter inactive")
	_check(not game._should_draw_compact_fps_counter(), "desktop would draw duplicate compact counter")
	await _capture("desktop_single_counter_1280x720", Vector2i(1280, 720))

	game.ui_platform_override = "android"
	_check(not game._should_draw_desktop_fps_counter(), "mobile would draw desktop counter")
	_check(game._should_draw_compact_fps_counter(), "mobile compact counter inactive")
	await _capture("mobile_single_counter_960x540", Vector2i(960, 540))

	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	for _frame in range(3):
		await process_frame
	if not failures.is_empty():
		for failure in failures:
			printerr("FPS_COUNTER_VISUAL_FAIL " + failure)
		quit(1)
		return
	print("FPS_COUNTER_VISUAL_OK desktop=1 mobile=1 duplicate=false")
	quit(0)
