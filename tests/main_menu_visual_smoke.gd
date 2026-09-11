extends SceneTree

const OUTPUT_DIR := "res://.agent_logs/menu_after"
var game: Node
var failed: bool = false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("MAIN_MENU_VISUAL_FAIL " + message)


func _capture(name: String, viewport: Vector2i) -> void:
	root.size = viewport
	game.queue_redraw()
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var screenshot: Image = root.get_texture().get_image()
	_check(screenshot.get_size() == viewport, "wrong size " + name)
	_check(screenshot.save_png(OUTPUT_DIR + "/" + name + ".png") == OK, "save " + name)
	var rects: Dictionary = game._menu_rects(Vector2(viewport))
	var keys: Array = game._menu_option_keys()
	for i in range(keys.size()):
		var rect: Rect2 = rects[keys[i]]
		_check(Rect2(Vector2.ZERO, Vector2(viewport)).encloses(rect), "offscreen " + str(keys[i]))
		_check(rect.size.y >= 44.0, "small touch target " + str(keys[i]))
		for j in range(i + 1, keys.size()):
			_check(not rect.intersects(rects[keys[j]]), "overlapping actions")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i.ZERO
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.mode = "menu"
	game.interrupted_run_available = false
	game.online_mode_unlocked = false
	game.qa_streaming_unlocked = false
	await _capture("main_desktop", Vector2i(1280, 720))
	_check(game._menu_rects(Vector2(1280, 720)).has("multiplayer") == game._online_menu_available(), "online visibility contract")
	game.online_mode_unlocked = true
	game.interrupted_run_available = true
	await _capture("main_continue", Vector2i(1280, 720))
	game.qa_streaming_unlocked = true
	await _capture("main_mobile_all_options", Vector2i(960, 540))
	game.qa_streaming_unlocked = false
	game.interrupted_run_available = false
	await _capture("main_mobile", Vector2i(960, 540))
	await _capture("main_ultrawide", Vector2i(1560, 720))
	root.size = Vector2i(1280, 720)
	await create_timer(0.1).timeout
	var rects: Dictionary = game._menu_rects(Vector2(1280, 720))
	var motion := InputEventMouseMotion.new()
	motion.position = Rect2(rects["settings"]).get_center()
	Input.parse_input_event(motion)
	await process_frame
	_check(game.menu_selected == game._menu_index_for("settings"), "mouse hover did not select settings")
	await _capture("main_hover", Vector2i(1280, 720))
	game._simulate_key_press(KEY_UP)
	_check(game.menu_selected == game._menu_index_for("catalog"), "keyboard navigation after hover")
	# Capture the original alternating image sequence during its glitch burst.
	while Time.get_ticks_msec() % 6950 < 5000 or Time.get_ticks_msec() % 6950 > 6300:
		await create_timer(0.05).timeout
	await _capture("main_glitch", Vector2i(1280, 720))
	game.ui_input_block_until_msec = 0
	game._handle_press(Rect2(rects["settings"]).get_center(), Vector2(1280, 720))
	_check(game.mode == "settings", "settings button did not open settings")
	print("MAIN_MENU_VISUAL_SMOKE_OK desktop=true continue=true mobile=true ultrawide=true hover=true keyboard=true glitch=true")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	quit(1 if failed else 0)
