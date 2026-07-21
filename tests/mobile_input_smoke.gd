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

	var cancel_press := InputEventScreenTouch.new()
	cancel_press.index = 8
	cancel_press.position = game._joy_center(viewport) + Vector2(64, 0)
	cancel_press.pressed = true
	game._unhandled_input(cancel_press)
	assert(game.move_touch_index == 8)
	var cancel_event := InputEventScreenTouch.new()
	cancel_event.index = 8
	cancel_event.position = cancel_press.position
	cancel_event.pressed = false
	cancel_event.canceled = true
	game._unhandled_input(cancel_event)
	assert(game.move_touch_index == -1)
	assert(game.touch_move == Vector2.ZERO)

	game.move_touch_index = 9
	game.touch_move = Vector2.RIGHT
	game.pointer_down = true
	game.active_screen_touches[9] = {"pos": game._joy_center(viewport) + Vector2(76, 0), "last_ms": Time.get_ticks_msec() - 1200}
	assert(game._try_start_move_touch(10, game._joy_center(viewport) + Vector2(-70, 0), viewport))
	assert(game.move_touch_index == 10)
	assert(game.touch_move.x < -0.4)
	game._cancel_touch_index(10)
	assert(game.touch_move == Vector2.ZERO)

	game._try_start_move_touch(11, game._joy_center(viewport) + Vector2(72, 0), viewport)
	game.boss3_miasma_qte_elapsed = 0.1
	game.boss3_miasma_qte_time_left = 3.0
	var qte_release := InputEventScreenTouch.new()
	qte_release.index = 11
	qte_release.position = game._joy_center(viewport) + Vector2(72, 0)
	qte_release.pressed = false
	game._unhandled_input(qte_release)
	assert(game.move_touch_index == -1)
	assert(game.touch_move == Vector2.ZERO)
	game.boss3_miasma_qte_time_left = 0.0
	game.boss3_miasma_qte_elapsed = 0.0

	game._try_start_move_touch(12, game._joy_center(viewport) + Vector2(72, 0), viewport)
	game.boss1_rewind_sequence = [{"t": 0.0}]
	var rewind_release := InputEventScreenTouch.new()
	rewind_release.index = 12
	rewind_release.position = game._joy_center(viewport) + Vector2(72, 0)
	rewind_release.pressed = false
	game._unhandled_input(rewind_release)
	assert(game.move_touch_index == -1)
	assert(game.touch_move == Vector2.ZERO)
	game.boss1_rewind_sequence.clear()

	game._try_start_move_touch(13, game._joy_center(viewport) + Vector2(72, 0), viewport)
	game.mode = "shop_opening"
	var shop_opening_release := InputEventScreenTouch.new()
	shop_opening_release.index = 13
	shop_opening_release.position = game._joy_center(viewport) + Vector2(72, 0)
	shop_opening_release.pressed = false
	game._unhandled_input(shop_opening_release)
	assert(game.move_touch_index == -1)
	assert(game.touch_move == Vector2.ZERO)
	game.mode = "game"

	game._try_start_move_touch(14, game._joy_center(viewport) + Vector2(72, 0), viewport)
	game._cancel_all_touch_state()
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

	print("MOBILE_INPUT_SMOKE_OK analog_stale_cleared=true canceled_touch_cleared=true early_return_release_cleared=true emulated_mouse_cleared=true manifest_drag=fluid ui_guard=true")
	game.queue_free()
	await process_frame
	quit(0)
