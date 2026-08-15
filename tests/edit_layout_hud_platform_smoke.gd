extends SceneTree

const OUT_DIR := "res://.codex"

var game: Node


func _fail(message: String) -> void:
	push_error("EDIT_LAYOUT_HUD_PLATFORM_FAIL " + message)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.ui_platform_override_unlocked = true

	await _capture_edit_layout("desktop", Vector2i(1280, 720), "edit_layout_desktop_1280x720.png")
	_check_desktop_interaction(Vector2(1280, 720))

	await _capture_edit_layout("android", Vector2i(1280, 720), "edit_layout_mobile_1280x720.png")
	_check_mobile_interaction(Vector2(1280, 720))

	print("EDIT_LAYOUT_HUD_PLATFORM_OK captures=2 desktop_virtual_hidden=true mobile_virtual_visible=true safe_clamp=true")
	game.queue_free()
	await process_frame
	quit(0)


func _capture_edit_layout(platform: String, viewport: Vector2i, file_name: String) -> void:
	root.size = viewport
	game.ui_platform_override = platform
	game._open_edit_layout(Vector2(viewport))
	game._update_button_layout(Vector2(viewport))
	_check(game.mode == "edit_layout", "mode did not enter edit_layout")
	_check(game._edit_layout_uses_virtual_controls() == (platform == "android"), "virtual controls mode mismatch " + platform)
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null, "null capture " + file_name)
	_check(image.get_width() == viewport.x and image.get_height() == viewport.y, "wrong capture size " + file_name)
	_check(image.get_used_rect().size.x > viewport.x * 0.70 and image.get_used_rect().size.y > viewport.y * 0.55, "blank capture " + file_name)
	_check(image.save_png(OUT_DIR + "/" + file_name) == OK, "could not save " + file_name)


func _check_desktop_interaction(viewport: Vector2) -> void:
	game.ui_platform_override = "desktop"
	game._open_edit_layout(viewport)
	game._update_button_layout(viewport)
	game.edit_layout_selected = ""
	game._handle_edit_layout_press(-2, game._joy_center(viewport), viewport)
	_check(game.edit_layout_selected != "joy", "desktop selected hidden joystick")

	var left_rect: = Rect2(game._left_panel_pos(viewport), Vector2(236.0, 76.0))
	game._handle_edit_layout_press(-2, left_rect.get_center(), viewport)
	_check(game.edit_layout_selected == "left_panel", "desktop did not select left panel")
	game._handle_edit_layout_drag(-2, Vector2(-500.0, -500.0), viewport)
	_check(game.hud_left_panel_pos.x >= 27.0 and game.hud_left_panel_pos.y >= 27.0, "left panel not clamped to safe area")
	game._handle_edit_layout_release(-2, game.hud_left_panel_pos, viewport)


func _check_mobile_interaction(viewport: Vector2) -> void:
	game.ui_platform_override = "android"
	game._open_edit_layout(viewport)
	game._update_button_layout(viewport)
	game.edit_layout_selected = ""
	game._handle_edit_layout_press(-2, game._joy_center(viewport), viewport)
	_check(game.edit_layout_selected == "joy", "mobile did not select joystick")
	game._handle_edit_layout_release(-2, game._joy_center(viewport), viewport)
