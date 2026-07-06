extends SceneTree

var game: Node
var booted := false


func _init() -> void:
	call_deferred("_bootstrap")


func _initialize() -> void:
	call_deferred("_bootstrap")


func _process(_delta: float) -> bool:
	if not booted:
		_bootstrap()
	return false


func _bootstrap() -> void:
	if booted:
		return
	booted = true
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("KEYBOARD_POPUP_VISUAL_FAIL " + message)
	quit(1)


func _rect_above_keyboard(rect: Rect2, viewport: Vector2) -> bool:
	return rect.end.y <= game._keyboard_safe_bottom(viewport) + 1.0


func _run() -> void:
	var viewport := Vector2(1280, 720)
	game.mode = "nick_setup"
	game._update_nickname_input_visibility()
	game.nickname_edit.grab_focus()
	game._sync_nickname_input_rect(viewport)
	var nick_panel: Rect2 = game._nickname_panel_rect(viewport)
	_check(_rect_above_keyboard(nick_panel, viewport), "nick_panel_covered")
	_check(game.nickname_edit.position.y + game.nickname_edit.size.y <= game._keyboard_safe_bottom(viewport), "nick_input_covered")

	game.player_nickname = "GeoQA"
	game.mode = "settings_gameplay"
	game.gameplay_cheat_focused = false
	game.retornante_unlocked = false
	game.qa_data_unlocked = false
	var rects: Dictionary = game._gameplay_preferences_rects(viewport)
	game._handle_gameplay_settings_touch(rects["retornante_cheat"].get_center(), viewport)
	game._update_cheat_input_visibility()
	game.cheat_edit.grab_focus()
	game._sync_cheat_input_rect(viewport)
	var cheat_panel: Rect2 = game._cheat_popup_rect(viewport)
	_check(game.cheat_edit.visible, "cheat_input_not_visible")
	_check(_rect_above_keyboard(cheat_panel, viewport), "cheat_panel_covered")
	_check(game.cheat_edit.position.y + game.cheat_edit.size.y <= game._keyboard_safe_bottom(viewport), "cheat_input_covered")

	game.qa_data_unlocked = true
	game.mode = "settings_data"
	game._update_webhook_input_visibility()
	game.webhook_edit.grab_focus()
	game._sync_webhook_input_rect(viewport)
	var data_panel: Rect2 = game._data_settings_panel_rect(viewport)
	_check(_rect_above_keyboard(data_panel, viewport), "webhook_panel_covered")
	_check(game.webhook_edit.position.y + game.webhook_edit.size.y <= game._keyboard_safe_bottom(viewport), "webhook_input_covered")

	game.mode = "settings_gameplay"
	game.gameplay_cheat_focused = true
	game._update_cheat_input_visibility()
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == 1280 and image.get_height() == 720, "invalid_capture")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output := "res://.codex/keyboard_popup_qa_1280x720.png"
	_check(image.save_png(output) == OK, "save_failed")
	print("KEYBOARD_POPUP_VISUAL_OK " + ProjectSettings.globalize_path(output))
	quit(0)
