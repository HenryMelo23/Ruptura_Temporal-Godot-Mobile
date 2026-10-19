extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game._ensure_runtime_controllers_bound()
	_check(game.player_control_controller.core == game, "player control controller was not bound to the runtime")

	var viewport: Vector2 = game.get_viewport_rect().size
	game._update_button_layout(viewport)
	var fixed_joy: Vector2 = game._joy_center(viewport)
	game.analog_fixed = true
	_check(game._try_start_move_touch(31, fixed_joy + Vector2(60, 0), viewport), "fixed joystick did not claim a valid touch")
	_check(game.move_touch_index == 31 and game.touch_move.x > 0.4, "fixed joystick direction was not preserved")
	game._cancel_touch_index(31)

	game.analog_fixed = false
	var dynamic_pos := Vector2(viewport.x * 0.3, viewport.y * 0.6)
	_check(game._try_start_move_touch(32, dynamic_pos, viewport), "dynamic joystick did not claim left-side touch")
	_check(game.joystick_origin == dynamic_pos, "dynamic joystick did not retain touch origin")
	game._cancel_touch_index(32)

	game.attack_drag_touch_index = 41
	_check(not game._try_start_move_touch(41, dynamic_pos, viewport), "an action touch was incorrectly reused as movement")
	game.attack_drag_touch_index = -1
	game.gamepad_bindings["attack"] = "77"
	game.last_attack_time = -999.0
	game._handle_gamepad_virtual_button("77", true, viewport)
	_check(game.attack_drag_touch_index == -3, "gamepad attack did not enter the shared touch action path")
	game._handle_gamepad_virtual_button("77", false, viewport)
	_check(game.attack_drag_touch_index == -1, "gamepad attack release did not clear its transient state")

	game.is_dead = true
	game.player_hp = 0.0
	_check(not game._try_start_move_touch(33, fixed_joy, viewport), "dead player incorrectly regained movement control")
	game.is_dead = false
	game.player_hp = game.player_hp_max
	game._go_to_menu()
	game._start_game()
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game._update_button_layout(viewport)
	_check(game._try_start_move_touch(36, game._joy_center(viewport) + Vector2(58, 0), viewport), "movement did not recover after returning through the menu")
	game._cancel_touch_index(36)

	game.move_touch_index = 34
	game.touch_move = Vector2.RIGHT
	game.active_screen_touches[34] = {"pos": dynamic_pos, "last_ms": Time.get_ticks_msec() - 1200}
	_check(game._try_start_move_touch(35, dynamic_pos, viewport), "stale touch did not yield to a new multitouch movement claim")
	_check(game.move_touch_index == 35, "stale touch did not switch movement owner")
	game._cancel_all_touch_state()
	_check(game.move_touch_index == -1 and game.touch_move == Vector2.ZERO and game.active_screen_touches.is_empty(), "input cleanup left a transient touch state")

	game.queue_free()
	print("PLAYER_CONTROL_CONTROLLER_SMOKE_OK fixed=true dynamic=true gamepad=true multitouch=true lock=true menu_return=true cleanup=true")
	await process_frame
	quit(0)
