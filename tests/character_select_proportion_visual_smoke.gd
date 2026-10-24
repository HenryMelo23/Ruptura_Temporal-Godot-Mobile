extends SceneTree

const OUTPUT := "res://.agent_logs/character_select_proportion/"

var canvas: SubViewport
var game: Node
var failed := false


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("CHARACTER_SELECT_PROPORTION_VISUAL_FAIL requires rendered frames")
		quit(1)
		return
	canvas = SubViewport.new()
	canvas.size = Vector2i(1280, 720)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	game = load("res://scenes/Main.tscn").instantiate()
	canvas.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	printerr("CHARACTER_SELECT_PROPORTION_VISUAL_FAIL " + message)


func _run() -> void:
	await process_frame
	game.set_process(false)
	game.card_unlock_progress["umbra_victories"] = 1.0
	game.startup_thanks_done = true
	game.startup_thanks_timer = 0.0
	game.startup_thanks_fading = false
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.show_fps_counter = false
	game.mode = "character_select"
	game.character_select_index = 0
	await _capture("character_select_1280x720.png", Vector2i(1280, 720))
	_check(game.buttons.has("character_geovana") and game.buttons.has("character_henry"), "character cards are missing")
	canvas.size = Vector2i(960, 540)
	game.character_select_index = 1
	await _capture("character_select_960x540.png", Vector2i(960, 540))
	print("CHARACTER_SELECT_PROPORTION_VISUAL_OK desktop=1280x720 mobile=960x540 output=%s" % ProjectSettings.globalize_path(OUTPUT))
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	canvas.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _capture(file_name: String, expected_size: Vector2i) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = canvas.get_texture().get_image()
	_check(image != null and not image.is_empty(), "invalid capture " + file_name)
	_check(image.get_size() == expected_size, "wrong capture size for " + file_name)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	_check(image.save_png(OUTPUT + file_name) == OK, "could not save " + file_name)
