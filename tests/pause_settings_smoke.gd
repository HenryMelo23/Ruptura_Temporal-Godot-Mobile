extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _pause_settings_rect(viewport: Vector2) -> Rect2:
	var panel = Rect2(viewport.x * 0.18, viewport.y * 0.22, viewport.x * 0.64, viewport.y * 0.52)
	var btn_w = 160.0
	var btn_h = 48.0
	var start_x = viewport.x * 0.5 - (btn_w * 4.0 + 36.0) * 0.5
	return Rect2(start_x + (btn_w + 12.0) * 2.0, panel.end.y - btn_h - 24.0, btn_w, btn_h)


func _run() -> void:
	var viewport = Vector2(1280, 720)
	game._start_game()
	game._update_button_layout(viewport)

	game._handle_touch_press(10, game.buttons["pause"].get_center(), viewport)
	assert(game.mode == "paused")
	assert(game.previous_mode == "game")

	game.ui_input_block_until_msec = 0
	game.buttons["pause_settings"] = _pause_settings_rect(viewport)
	game._handle_press(game.buttons["pause_settings"].get_center(), viewport)
	assert(game.mode == "settings")
	assert(game.settings_previous_mode == "paused")
	assert(game._ui_input_blocked())
	if Input.get_connected_joypads().is_empty():
		assert(not game._settings_rects(viewport).has("gamepad"))
		assert(game._settings_index_for("gameplay") == 1)

	game._handle_press(game._settings_rects(viewport)["graphics"].get_center(), viewport)
	assert(game.mode == "settings")

	game.ui_input_block_until_msec = 0
	game._handle_press(game._settings_rects(viewport)["gameplay"].get_center(), viewport)
	assert(game.mode == "settings_gameplay")
	assert(game._ui_input_blocked())

	game.ui_input_block_until_msec = 0
	game._handle_press(game._gameplay_preferences_rects(viewport)["back"].get_center(), viewport)
	assert(game.mode == "settings")
	assert(game._ui_input_blocked())

	game._handle_press(game._settings_rects(viewport)["graphics"].get_center(), viewport)
	assert(game.mode == "settings")

	game.ui_input_block_until_msec = 0
	game._handle_press(game._settings_rects(viewport)["back"].get_center(), viewport)
	assert(game.mode == "paused")
	assert(game._ui_input_blocked())

	print("PAUSE_SETTINGS_SMOKE_OK pause_first_tap=true settings_hub=true no_touch_leak=true back_to_pause=true")
	quit(0)
