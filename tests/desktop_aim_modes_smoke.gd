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
	var viewport := Vector2(1280, 720)
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.last_facing = Vector2.RIGHT
	game.time_alive = 120.0
	game._update_button_layout(viewport)
	game.get_viewport().warp_mouse(Vector2(760, 360))

	game.manifestation_key = "bombastica"
	game.bombastica_bombs.clear()
	game.bombastica_q_recharges = [0.0, 0.0, 0.0]
	game._try_cast_bombastica_q()
	_check(game.bombastica_bombs.size() == 1, "dry Bombastica Q did not create exactly one bomb")
	_check(Vector2(game.bombastica_bombs[0]["target"]).distance_to(game.player_pos) < 1.0, "dry Bombastica Q was not placed on the player")
	game._try_cast_bombastica_q(game.player_pos + Vector2(180, 0))
	_check(game.bombastica_bombs.size() == 2, "second Bombastica Q should add one bomb, not unload all charges")
	_check(game._bombastica_ready_charges() == 1, "Bombastica Q consumed more than one charge per cast")

	game.manifestation_key = "eletrica"
	game.desktop_aim_mode = game.DESKTOP_AIM_CONFIRM
	game.keyboard_bindings["skill"] = game._key_input_binding(KEY_Q)
	game.eletrica_waves.clear()
	game.last_skill_time = -999.0
	game.desktop_action_gate_msec.clear()
	_check(game._handle_desktop_combat_key(_key_event(KEY_Q)), "confirm mode first Q was not consumed")
	_check(game.desktop_aim_action == "skill", "confirm mode did not arm skill aim")
	_check(game.eletrica_waves.is_empty(), "confirm mode fired skill on first press")
	game.desktop_action_gate_msec["skill"] = -1000000
	_check(game._handle_desktop_combat_key(_key_event(KEY_Q)), "confirm mode second Q was not consumed")
	_check(game.desktop_aim_action == "", "confirm mode did not clear after confirmation")
	_check(not game.eletrica_waves.is_empty(), "confirm mode did not fire skill on second press")

	game.desktop_aim_mode = game.DESKTOP_AIM_HOLD
	game.keyboard_bindings["secondary"] = game._key_input_binding(KEY_E)
	game.manifestation_secondaries.clear()
	game.last_secondary_time = -999.0
	game.desktop_action_gate_msec.clear()
	_check(game._handle_desktop_combat_key(_key_event(KEY_E)), "hold mode E press was not consumed")
	_check(game.desktop_aim_action == "secondary", "hold mode did not arm secondary aim")
	_check(game._active_eletrica_secondary().is_empty(), "hold mode fired secondary before key release")
	_check(game._handle_desktop_aim_release(_key_event(KEY_E, false)), "hold mode E release was not consumed")
	_check(not game._active_eletrica_secondary().is_empty(), "hold mode did not fire secondary on release")

	game.desktop_teleport_mode = game.DESKTOP_TELEPORT_AUTO
	game.keyboard_bindings["dash"] = game._key_input_binding(KEY_F)
	game.enemies.clear()
	game.boss_active = true
	game.boss_hp = 1000.0
	game.boss_pos = game.player_pos + Vector2(190, 0)
	game.last_dash_time = -999.0
	var before_pos: Vector2 = game.player_pos
	game.desktop_action_gate_msec.clear()
	_check(game._handle_desktop_combat_key(_key_event(KEY_F)), "auto teleport key was not consumed")
	_check(game.player_pos.distance_to(before_pos) > 20.0, "auto teleport did not move the player")
	_check(game.player_pos.x > before_pos.x, "auto teleport did not aim toward nearest enemy")

	game.desktop_teleport_mode = game.DESKTOP_AIM_CONFIRM
	game.last_dash_time = -999.0
	game.desktop_action_gate_msec.clear()
	var confirm_before: Vector2 = game.player_pos
	_check(game._handle_desktop_combat_key(_key_event(KEY_F)), "confirm teleport first key was not consumed")
	_check(game.desktop_aim_action == "dash", "confirm teleport did not arm dash aim")
	_check(game.player_pos == confirm_before, "confirm teleport moved on first press")
	game._cancel_desktop_aim_feedback()
	_check(game.desktop_aim_action == "" and not game.teleport_dragging, "right-click style cancel did not clear teleport aim")

	print("DESKTOP_AIM_MODES_SMOKE_OK bombastica_single=true aim_confirm=true aim_hold=true teleport_auto=true")
	game.boss_active = false
	game.boss_hp = 0.0
	game.manifestation_secondaries.clear()
	game.eletrica_waves.clear()
	game._exit_tree()
	await process_frame
	quit(0)


func _key_event(keycode: int, pressed := true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	return event
