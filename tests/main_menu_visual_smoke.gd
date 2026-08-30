extends SceneTree

const OUTPUT_DIR := "res://.agent_logs"

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _save_view(name: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Failed to capture image for " + name)
		return
	var path := OUTPUT_DIR + "/" + name
	var err := image.save_png(path)
	if err != OK:
		push_error("Failed to save image for " + name + ": " + str(err))
		return
	print("IMAGE_SAVED: ", ProjectSettings.globalize_path(path), " size: ", image.get_size())


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	game.mode = "menu"
	game.startup_thanks_done = true
	game.interrupted_run_available = false

	await process_frame
	await process_frame
	_check(game._menu_rects(Vector2(1280, 720)).has("multiplayer"), "main menu should expose multiplayer button")
	_save_view("main_menu_desktop_standard.png")

	game.interrupted_run_available = true
	game.queue_redraw()
	await process_frame
	await process_frame
	_save_view("main_menu_desktop_continue.png")

	root.size = Vector2i(960, 540)
	game.interrupted_run_available = false
	game.menu_selected = 0
	game.queue_redraw()
	await process_frame
	await process_frame
	await process_frame
	_save_view("main_menu_mobile_landscape.png")

	print("MAIN_MENU_VISUAL_SMOKE_OK desktop=true continue=true mobile_landscape=true")
	quit(0)
