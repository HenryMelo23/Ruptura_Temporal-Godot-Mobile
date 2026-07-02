extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	var viewport = Vector2(1280, 720)
	game._start_game()
	game.active_screen_touches[4] = true
	assert(game._try_start_move_touch(4, game._joy_center(viewport) + Vector2(62, 0), viewport))
	assert(game.move_touch_index == 4)
	assert(game.touch_move.x > 0.4)
	game.active_screen_touches.clear()
	game._sync_touch_state()
	assert(game.move_touch_index == -1)
	assert(game.touch_move == Vector2.ZERO)

	game.move_touch_index = -2
	game.touch_move = Vector2.RIGHT
	game.pointer_down = true
	game._sync_touch_state()
	assert(game.move_touch_index == -1)
	assert(game.touch_move == Vector2.ZERO)

	game.mode = "manifest"
	game.selected_manifestation = 0
	game.manifest_scroll_pos = 0.0
	game._start_manifest_drag(2, Vector2(640, 310), viewport)
	game._update_manifest_drag(Vector2(460, 310), viewport)
	assert(game.manifest_is_dragging)
	assert(game.manifest_drag_moved)
	assert(game.selected_manifestation == 1)
	assert(game.manifest_scroll_pos > 0.85 and game.manifest_scroll_pos < 1.15)
	game._finish_manifest_drag(Vector2(460, 310), viewport)
	assert(not game.manifest_is_dragging)
	assert(game.selected_manifestation == 1)
	assert(is_equal_approx(game.manifest_scroll_pos, 1.0))

	game.mode = "menu"
	game._block_ui_input(1000)
	game._handle_press(game._menu_rects(viewport)["start"].get_center(), viewport)
	assert(game.mode == "menu")

	print("MOBILE_INPUT_SMOKE_OK analog_stale_cleared=true emulated_mouse_cleared=true manifest_drag=fluid ui_guard=true")
	quit(0)
