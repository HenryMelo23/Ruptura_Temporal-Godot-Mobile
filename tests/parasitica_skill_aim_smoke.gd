extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("PARASITICA_SKILL_AIM_FAIL " + message)
	quit(1)


func _key_event(keycode: int, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


func _reset_skill() -> void:
	game.last_skill_time = -999.0
	game.effects.clear()
	game.parasite_spit_zones.clear()
	game.desktop_action_gate_msec.clear()


func _run() -> void:
	var viewport := Vector2(1280, 720)
	game._start_game()
	game.manifestation_key = "parasitica"
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

	_check(Vector2(game._parasitica_quick_skill_target(false)).distance_to(Vector2(nearest["pos"])) < 0.1, "mobile quick target was not the nearest enemy")
	game.auto_target_priority = "hp_low"
	_check(Vector2(game._parasitica_quick_skill_target(true)).distance_to(Vector2(lowest_hp["pos"])) < 0.1, "configured current-life priority was ignored")
	game.auto_target_priority = "max_hp_low"
	_check(Vector2(game._parasitica_quick_skill_target(true)).distance_to(Vector2(lowest_max_hp["pos"])) < 0.1, "configured maximum-life priority was ignored")

	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	game._update_button_layout(viewport)
	_reset_skill()
	var skill_center: Vector2 = game.buttons["skill"].get_center()
	game._handle_touch_press(21, skill_center, viewport)
	game._handle_touch_release(21, skill_center, viewport)
	_check(game.parasite_spit_zones.size() == 1, "mobile quick tap did not cast HAB1")
	_check(Vector2(game.parasite_spit_zones[0]["target"]).distance_to(Vector2(nearest["pos"])) < 0.1, "mobile quick tap did not choose the nearest enemy")

	_reset_skill()
	var actual_viewport: Vector2 = game.get_viewport_rect().size
	game._update_button_layout(actual_viewport)
	var event_skill_center: Vector2 = game.buttons["skill"].get_center()
	var touch_press := InputEventScreenTouch.new()
	touch_press.index = 23
	touch_press.position = event_skill_center
	touch_press.pressed = true
	game._unhandled_input(touch_press)
	_check(game.skill_touch_index == 23, "mobile event path did not arm HAB1")
	var touch_release := InputEventScreenTouch.new()
	touch_release.index = 23
	touch_release.position = event_skill_center
	touch_release.pressed = false
	game._unhandled_input(touch_release)
	_check(game.parasite_spit_zones.size() == 1, "mobile event path did not cast HAB1 on release")
	_check(Vector2(game.parasite_spit_zones[0]["target"]).distance_to(Vector2(nearest["pos"])) < 0.1, "mobile event path did not choose the nearest enemy")

	_reset_skill()
	game._update_button_layout(viewport)
	game._handle_touch_press(22, skill_center, viewport)
	game.player_control_controller.skill_press_started_msec -= game.player_control_controller.PARASITICA_SKILL_HOLD_MSEC + 10
	var dragged_pos := skill_center + Vector2(-118.0, -70.0)
	game._handle_touch_drag(22, dragged_pos, viewport)
	var mobile_aim_target: Vector2 = game._ground_target_world(dragged_pos, viewport, false)
	game._handle_touch_release(22, dragged_pos, viewport)
	_check(game.parasite_spit_zones.size() == 1, "mobile held aim did not cast HAB1")
	_check(Vector2(game.parasite_spit_zones[0]["target"]).distance_to(mobile_aim_target) < 0.1, "mobile held aim ignored the selected reticle position")

	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game.keyboard_bindings["skill"] = game._key_input_binding(KEY_Q)
	game.auto_target_priority = "hp_low"
	game.get_viewport().warp_mouse(Vector2(1030.0, 620.0))
	_reset_skill()
	_check(game._handle_desktop_combat_key(_key_event(KEY_Q, true)), "desktop quick press was not consumed")
	_check(game.desktop_aim_action == "skill", "desktop Parasitica press did not arm held cursor aim")
	_check(game._handle_desktop_aim_release(_key_event(KEY_Q, false)), "desktop quick release was not consumed")
	_check(game.parasite_spit_zones.size() == 1, "desktop quick press did not cast HAB1")
	_check(Vector2(game.parasite_spit_zones[0]["target"]).distance_to(Vector2(lowest_hp["pos"])) < 0.1, "desktop quick press ignored the configured target priority")

	_reset_skill()
	game.get_viewport().warp_mouse(Vector2(880.0, 260.0))
	_check(game._handle_desktop_combat_key(_key_event(KEY_Q, true)), "desktop held press was not consumed")
	game.player_control_controller.skill_press_started_msec -= game.player_control_controller.PARASITICA_SKILL_HOLD_MSEC + 10
	var cursor_target = game._desktop_cursor_ground_target(false)
	_check(cursor_target is Vector2, "desktop cursor target was unavailable")
	_check(game._handle_desktop_aim_release(_key_event(KEY_Q, false)), "desktop held release was not consumed")
	_check(game.parasite_spit_zones.size() == 1, "desktop held aim did not cast HAB1")
	var expected_cursor_target: Vector2 = Vector2(cursor_target).clamp(Vector2(game.PARASITE_SPIT_RADIUS, game.PARASITE_SPIT_RADIUS), game.WORLD_SIZE - Vector2(game.PARASITE_SPIT_RADIUS, game.PARASITE_SPIT_RADIUS))
	_check(Vector2(game.parasite_spit_zones[0]["target"]).distance_to(expected_cursor_target) < 0.1, "desktop held aim did not cast toward the cursor (expected %s, got %s)" % [expected_cursor_target, game.parasite_spit_zones[0]["target"]])

	print("PARASITICA_SKILL_AIM_OK mobile_quick=nearest mobile_event=true mobile_hold=reticle desktop_quick=config desktop_hold=cursor threshold_ms=%d" % game.player_control_controller.PARASITICA_SKILL_HOLD_MSEC)
	game._cleanup_runtime_resources()
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
