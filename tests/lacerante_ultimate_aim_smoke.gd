extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("LACERANTE_ULTIMATE_AIM_FAIL " + message)
	quit(1)


func _key_event(keycode: int, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


func _reset_ultimate() -> void:
	game.manifestation_secondaries.clear()
	game.last_secondary_time = -999.0
	game.desktop_action_gate_msec.clear()
	game.player_pos = Vector2(640.0, 360.0)


func _ultimate_center() -> Vector2:
	_check(game.manifestation_secondaries.size() == 1, "ultimate did not create exactly one secondary")
	return Vector2(game.manifestation_secondaries[0].get("center", Vector2.ZERO))


func _run() -> void:
	var viewport := Vector2(1280, 720)
	game._start_game()
	game.manifestation_key = "lacerante"
	game.selected_manifestation = game._manifestation_index_for_key("lacerante", -1)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 100.0
	game.player_pos = Vector2(640.0, 360.0)
	game.enemies.clear()
	game.boss_active = false
	game.arauto.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(120.0, 0.0))
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(250.0, -20.0))
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(350.0, 30.0))
	var nearest: Dictionary = game.enemies[0]
	var lowest_hp: Dictionary = game.enemies[1]
	var lowest_max_hp: Dictionary = game.enemies[2]
	nearest["hp"] = 900.0
	nearest["max_hp"] = 1000.0
	lowest_hp["hp"] = 40.0
	lowest_hp["max_hp"] = 800.0
	lowest_max_hp["hp"] = 500.0
	lowest_max_hp["max_hp"] = 600.0

	_check(Vector2(game._lacerante_quick_ultimate_target(false)).distance_to(Vector2(nearest["pos"])) < 0.1, "mobile quick target was not nearest")
	game.auto_target_priority = "hp_low"
	_check(Vector2(game._lacerante_quick_ultimate_target(true)).distance_to(Vector2(lowest_hp["pos"])) < 0.1, "current-life priority was ignored")
	game.auto_target_priority = "max_hp_low"
	_check(Vector2(game._lacerante_quick_ultimate_target(true)).distance_to(Vector2(lowest_max_hp["pos"])) < 0.1, "maximum-life priority was ignored")

	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	game._update_button_layout(viewport)
	_reset_ultimate()
	var secondary_center: Vector2 = game.buttons["secondary"].get_center()
	game._handle_touch_press(41, secondary_center, viewport)
	game._handle_touch_release(41, secondary_center, viewport)
	_check(_ultimate_center().distance_to(Vector2(nearest["pos"])) < 0.1, "mobile quick tap did not choose nearest")

	_reset_ultimate()
	var actual_viewport: Vector2 = game.get_viewport_rect().size
	game._update_button_layout(actual_viewport)
	var event_secondary_center: Vector2 = game.buttons["secondary"].get_center()
	var touch_press := InputEventScreenTouch.new()
	touch_press.index = 43
	touch_press.position = event_secondary_center
	touch_press.pressed = true
	game._unhandled_input(touch_press)
	_check(game.secondary_touch_index == 43, "mobile event path did not arm ultimate")
	var touch_release := InputEventScreenTouch.new()
	touch_release.index = 43
	touch_release.position = event_secondary_center
	touch_release.pressed = false
	game._unhandled_input(touch_release)
	_check(_ultimate_center().distance_to(Vector2(nearest["pos"])) < 0.1, "mobile event path did not choose nearest")

	_reset_ultimate()
	game._update_button_layout(viewport)
	secondary_center = game.buttons["secondary"].get_center()
	game._handle_touch_press(42, secondary_center, viewport)
	game.player_control_controller.secondary_press_started_msec -= game.player_control_controller.LACERANTE_ULTIMATE_HOLD_MSEC + 10
	var dragged_pos := secondary_center + Vector2(-118.0, -70.0)
	game._handle_touch_drag(42, dragged_pos, viewport)
	var mobile_target: Vector2 = game._ground_target_world(dragged_pos, viewport, true)
	game._handle_touch_release(42, dragged_pos, viewport)
	_check(_ultimate_center().distance_to(mobile_target) < 0.1, "mobile held aim ignored reticle")

	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game.keyboard_bindings["secondary"] = game._key_input_binding(KEY_E)
	game.auto_target_priority = "hp_low"
	game.get_viewport().warp_mouse(Vector2(1040.0, 620.0))
	_reset_ultimate()
	_check(game._handle_desktop_combat_key(_key_event(KEY_E, true)), "desktop quick press not consumed")
	_check(game.desktop_aim_action == "secondary", "desktop Lacerante press did not arm hold aim")
	_check(game._handle_desktop_aim_release(_key_event(KEY_E, false)), "desktop quick release not consumed")
	_check(_ultimate_center().distance_to(Vector2(lowest_hp["pos"])) < 0.1, "desktop quick release ignored configured priority")

	_reset_ultimate()
	game.get_viewport().warp_mouse(Vector2(870.0, 245.0))
	_check(game._handle_desktop_combat_key(_key_event(KEY_E, true)), "desktop held press not consumed")
	game.player_control_controller.secondary_press_started_msec -= game.player_control_controller.LACERANTE_ULTIMATE_HOLD_MSEC + 10
	var cursor_target = game._desktop_cursor_ground_target(true)
	_check(cursor_target is Vector2, "desktop cursor target unavailable")
	_check(game._handle_desktop_aim_release(_key_event(KEY_E, false)), "desktop held release not consumed")
	var expected := Vector2(cursor_target).clamp(Vector2(120.0, 120.0), game.WORLD_SIZE - Vector2(120.0, 120.0))
	_check(_ultimate_center().distance_to(expected) < 0.1, "desktop held aim ignored cursor")

	print("LACERANTE_ULTIMATE_AIM_OK mobile_quick=nearest mobile_event=true mobile_hold=reticle desktop_quick=config desktop_hold=cursor threshold_ms=%d" % game.player_control_controller.LACERANTE_ULTIMATE_HOLD_MSEC)
	game._cleanup_runtime_resources()
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
