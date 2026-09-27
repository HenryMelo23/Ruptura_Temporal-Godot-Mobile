extends RefCounted

var core: Node

func configure(p_core: Node) -> void:
	core = p_core

func _cancel_combat_aim_state(clear_movement: = false) -> void :
	core.attack_touch_index = -1
	core.attack_drag_touch_index = -1
	core.skill_touch_index = -1
	core.secondary_touch_index = -1
	core.dash_touch_index = -1
	core.attack_holding = false
	core.attack_dragging = false
	core.attack_hold_timer = 0.0
	core.attack_lock_selecting = false
	core.attack_lock_candidate_kind = ""
	core.attack_lock_candidate_uid = -1
	core.attack_drag_direction = Vector2.ZERO
	core.teleport_dragging = false
	core.teleport_drag_screen = Vector2.ZERO
	core.teleport_drag_origin = Vector2.ZERO
	_clear_desktop_aim_state()
	core.skill_touch_pos = Vector2.ZERO
	core.secondary_touch_pos = Vector2.ZERO
	if clear_movement:
		core.pointer_down = false
		core.active_screen_touches.clear()
		core.move_touch_index = -1
		core.touch_move = Vector2.ZERO

func _spectator_controls_locked() -> bool:
	return core.is_multiplayer and core.online_local_spectator

func _player_start_down_controls_locked() -> bool:
	if core.player_start_down_fall_timer > 0.0:
		return true
	if core.player_start_down_landing_timer <= 0.0:
		return false
	return core.player_start_down_landing_timer > core.PLAYER_START_DOWN_LAND_TIME - core.PLAYER_START_DOWN_CONTROL_LOCK_AFTER_LAND

func _local_player_controls_locked() -> bool:
	return core.is_dead or core.player_hp <= 0.0 or _spectator_controls_locked() or _player_start_down_controls_locked()

func _combat_controls_active() -> bool:
	return not _local_player_controls_locked() and (core.mode == "game" or core.mode == "shop_countdown" or core.mode == "boss_call" or core.mode == "pause_countdown")

func _read_move() -> Vector2:
	if core._apolo_phase5_exhibition_active():
		return core.apolo_phase5_exhibition_move.normalized() if core.apolo_phase5_exhibition_move.length() > 1.0 else core.apolo_phase5_exhibition_move
	var move = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move.y += 1
	if core.move_touch_index != -1 and core.touch_move.length() > 0.05:
		move = core.touch_move
	if core.is_gamepad_active:
		var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		var joy_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		var joy_vec = Vector2(joy_x, joy_y)
		if joy_vec.length() > 0.15:
			move = joy_vec
	if core.controls_inverted_timer > 0.0:
		move = - move
	var vector_rotation: float = core._phase4_vector_rotation()
	if not is_zero_approx(vector_rotation) and move.length() > 0.05:
		move = move.rotated(vector_rotation)
	return move.normalized() if move.length() > 1.0 else move

func _right_aim_vector() -> Vector2:
	if not core.is_gamepad_active:
		return Vector2.ZERO
	var r_vec = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	return r_vec.normalized() if r_vec.length() > 0.15 else Vector2.ZERO

func _aim_direction() -> Vector2:
	if core._apolo_phase5_exhibition_active():
		if core.apolo_phase5_exhibition_aim.length() > 0.05:
			return core.apolo_phase5_exhibition_aim.normalized()
		if core.boss_active and core.boss_hp > 0.0:
			return (core.boss_pos - core.player_pos).normalized()
	var right_aim: = _right_aim_vector()
	if right_aim.length() > 0.05:
		return right_aim
	if core.lacerante_preparing and core.lacerante_prepare_dir.length() > 0.05:
		return core.lacerante_prepare_dir.normalized()
	if core.attack_dragging and core.attack_drag_direction.length() > 0.05:
		return core.attack_drag_direction.normalized()
	if core._uses_desktop_ui() and core._sanitize_desktop_attack_aim_mode(core.desktop_attack_aim_mode) == core.DESKTOP_ATTACK_AIM_CURSOR:
		var cursor_dir: Vector2 = (_desktop_aim_target_world() - core.player_pos).normalized()
		if cursor_dir.length() > 0.05:
			return cursor_dir
	var target = core._nearest_target()
	if target != Vector2.ZERO:
		return (target - core.player_pos).normalized()
	return core.last_facing.normalized() if core.last_facing.length() > 0.05 else Vector2.RIGHT

func _set_player_attack_visual_dir(direction: Vector2) -> void:
	if direction.length() > 0.05:
		core.player_attack_visual_dir = direction.normalized()
	elif core.last_facing.length() > 0.05:
		core.player_attack_visual_dir = core.last_facing.normalized()
	else:
		core.player_attack_visual_dir = Vector2.RIGHT

func _clamp_player_world(pos: Vector2) -> Vector2:
	return pos.clamp(core.PLAYER_WORLD_MARGIN, core.WORLD_SIZE - core.PLAYER_WORLD_MARGIN)

func _should_ignore_emulated_mouse() -> bool:
	return not core.active_screen_touches.is_empty() or Time.get_ticks_msec() <= core.ignore_mouse_until_msec

func _mouse_release_has_active_action() -> bool:
	return core.move_touch_index == -2 or core.attack_drag_touch_index == -2 or core.skill_touch_index == -2 or core.secondary_touch_index == -2 or core.dash_touch_index == -2 or core.bombastica_detonator_touch_index == -2 or core.manifest_drag_touch_index == -2 or core.deck_drag_touch_index == -2

func _block_ui_input(duration_ms: int) -> void :
	core.ui_input_block_until_msec = max(core.ui_input_block_until_msec, Time.get_ticks_msec() + duration_ms)

func _ui_input_blocked() -> bool:
	return Time.get_ticks_msec() <= core.ui_input_block_until_msec

func _sync_touch_state() -> void :
	if core.move_touch_index >= 0 and not core.active_screen_touches.has(core.move_touch_index):
		_stop_move_touch()
	elif core.move_touch_index == -2 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_stop_move_touch()
	if core.attack_drag_touch_index >= 0 and not core.active_screen_touches.has(core.attack_drag_touch_index):
		core.attack_drag_touch_index = -1
		core.attack_dragging = false
		core.attack_holding = false
		core.attack_hold_timer = 0.0
		core.attack_lock_selecting = false
		core.attack_lock_candidate_kind = ""
		core.attack_lock_candidate_uid = -1
	if core.skill_touch_index >= 0 and not core.active_screen_touches.has(core.skill_touch_index):
		core.skill_touch_index = -1
	if core.secondary_touch_index >= 0 and not core.active_screen_touches.has(core.secondary_touch_index):
		core.secondary_touch_index = -1
	if core.dash_touch_index >= 0 and not core.active_screen_touches.has(core.dash_touch_index):
		core.dash_touch_index = -1
		core.teleport_dragging = false
	if core.bombastica_detonator_touch_index >= 0 and not core.active_screen_touches.has(core.bombastica_detonator_touch_index):
		core.bombastica_detonator_touch_index = -1
		core.bombastica_detonator_hold = 0.0
	elif core.bombastica_detonator_touch_index == -2 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		core.bombastica_detonator_touch_index = -1
		core.bombastica_detonator_hold = 0.0
	if core.active_screen_touches.is_empty() and core.move_touch_index == -1:
		core.pointer_down = false

func _stop_move_touch() -> void :
	core.move_touch_index = -1
	core.touch_move = Vector2.ZERO
	core.pointer_down = false

func _touch_record(pos: Vector2) -> Dictionary:
	return {"pos": pos, "last_ms": Time.get_ticks_msec()}

func _touch_last_ms(index: int) -> int:
	if not core.active_screen_touches.has(index):
		return 0
	var record = core.active_screen_touches[index]
	if record is Dictionary:
		return int(record.get("last_ms", 0))
	return Time.get_ticks_msec()

func _move_touch_is_stale(timeout_ms: int) -> bool:
	if core.move_touch_index < 0:
		return false
	var last_ms: = _touch_last_ms(core.move_touch_index)
	return last_ms > 0 and Time.get_ticks_msec() - last_ms >= timeout_ms

func _cancel_touch_index(index: int) -> void :
	core.active_screen_touches.erase(index)
	if index == core.move_touch_index:
		_stop_move_touch()
	if index == core.attack_touch_index:
		core.attack_touch_index = -1
	if index == core.attack_drag_touch_index:
		core.attack_drag_touch_index = -1
		core.attack_dragging = false
		core.attack_holding = false
		core.attack_hold_timer = 0.0
		core.attack_lock_selecting = false
		core.attack_lock_candidate_kind = ""
		core.attack_lock_candidate_uid = -1
	if index == core.skill_touch_index:
		core.skill_touch_index = -1
	if index == core.secondary_touch_index:
		core.secondary_touch_index = -1
	if index == core.dash_touch_index:
		core.dash_touch_index = -1
		core.teleport_dragging = false
	if index == core.edit_layout_touch_index:
		core.edit_layout_touch_index = -1
	if index == core.manifest_drag_touch_index:
		core.manifest_drag_touch_index = -999
		core.manifest_is_dragging = false
		core.manifest_drag_moved = false
	if index == core.manifest_preview_drag_touch_index:
		core.manifest_preview_drag_touch_index = -999
	if index == core.manifest_preview_consumed_touch_index:
		core.manifest_preview_consumed_touch_index = -999
	if index == core.deck_drag_touch_index:
		core.deck_drag_touch_index = -999
		core.deck_is_dragging = false
		core.deck_drag_moved = false
	if core.active_screen_touches.is_empty() and core.move_touch_index == -1:
		core.pointer_down = false

func _cancel_all_touch_state() -> void :
	core.active_screen_touches.clear()
	_cancel_combat_aim_state(true)
	core.edit_layout_touch_index = -1
	core.edit_layout_selected = ""
	core.edit_layout_resize_visible = false
	core.manifest_drag_touch_index = -999
	core.manifest_preview_drag_touch_index = -999
	core.manifest_preview_consumed_touch_index = -999
	core.manifest_is_dragging = false
	core.manifest_drag_moved = false
	core.deck_drag_touch_index = -999
	core.deck_is_dragging = false
	core.deck_drag_moved = false

func _claim_action_touch(index: int) -> void :
	if core.move_touch_index == index:
		_stop_move_touch()
	elif index >= 0 and core.move_touch_index != -1 and not core.active_screen_touches.has(core.move_touch_index):
		_stop_move_touch()

func _touch_index_has_action(index: int) -> bool:
	return index == core.attack_drag_touch_index or index == core.skill_touch_index or index == core.secondary_touch_index or index == core.dash_touch_index or index == core.bombastica_detonator_touch_index or index == core.dance_wheel_touch_index

func _try_start_move_touch(index: int, pos: Vector2, viewport: Vector2) -> bool:
	if _local_player_controls_locked():
		return false
	if core.move_touch_index != -1:
		if index != core.move_touch_index and _move_touch_is_stale(900):
			_stop_move_touch()
		else:
			return false
	if _touch_index_has_action(index):
		return false
	var joy = core._joy_center(viewport)
	var joy_radius = 116.0 * core._joy_scale()
	var fixed_hit = pos.distance_to(joy) < joy_radius
	var dynamic_hit = not core.analog_fixed and pos.x <= viewport.x * 0.48
	if not fixed_hit and not dynamic_hit:
		return false
	core.move_touch_index = index
	core.pointer_down = true
	core.joystick_origin = joy if core.analog_fixed or fixed_hit else pos
	core.touch_move = ((pos - core.joystick_origin) / (76.0 * core._joy_scale())).limit_length(1.0)
	return true

func _clear_desktop_aim_state() -> void :
	core.desktop_aim_action = ""
	core.desktop_aim_event_binding = ""
	core.desktop_aim_is_hold = false

func _desktop_dash_mode() -> String:
	return core._sanitize_desktop_teleport_mode(core.desktop_teleport_mode)

func _desktop_aim_target_world() -> Vector2:
	var viewport: Vector2 = core.get_viewport_rect().size
	var mouse_pos: Vector2 = core.get_viewport().get_mouse_position()
	return (mouse_pos + core._camera(viewport)).clamp(Vector2.ZERO, core.WORLD_SIZE)

func _desktop_auto_teleport_target() -> Vector2:
	var target: Vector2 = core._nearest_target()
	if target != Vector2.ZERO:
		var offset: Vector2 = target - core.player_pos
		if offset.length() > 0.05:
			return core.player_pos + offset.limit_length(core.PLAYER_DASH_DISTANCE)
	var dir: = _aim_direction()
	if dir.length() <= 0.05:
		dir = core.last_facing.normalized() if core.last_facing.length() > 0.05 else Vector2.RIGHT
	return core.player_pos + dir.normalized() * core.PLAYER_DASH_DISTANCE

func _desktop_dash_target() -> Vector2:
	if _desktop_dash_mode() == core.DESKTOP_TELEPORT_AUTO:
		return _desktop_auto_teleport_target()
	var viewport: Vector2 = core.get_viewport_rect().size
	var screen_pos: Vector2 = core.get_viewport().get_mouse_position()
	var camera: Vector2 = core._camera(viewport)
	var world: Vector2 = (screen_pos + camera).clamp(Vector2.ZERO, core.WORLD_SIZE)
	var offset: Vector2 = world - core.player_pos
	if offset.length() <= 8.0:
		offset = _aim_direction() * core.PLAYER_DASH_DISTANCE
	if offset.length() <= 0.05:
		offset = (core.last_facing.normalized() if core.last_facing.length() > 0.05 else Vector2.RIGHT) * core.PLAYER_DASH_DISTANCE
	return core.player_pos + offset.limit_length(core.PLAYER_DASH_DISTANCE)

func _desktop_action_uses_aim(action: String) -> bool:
	return action in ["skill", "secondary", "dash"]

func _desktop_action_aim_mode(action: String) -> String:
	if action == "dash":
		var dash_mode: = _desktop_dash_mode()
		if dash_mode in [core.DESKTOP_AIM_HOLD, core.DESKTOP_AIM_CONFIRM]:
			return dash_mode
		return core.DESKTOP_AIM_QUICK
	return core._desktop_skill_mode()

func _begin_desktop_aim(action: String, binding: String, hold: bool) -> void :
	core.desktop_aim_action = action
	core.desktop_aim_event_binding = binding
	core.desktop_aim_is_hold = hold
	if action == "dash":
		core.teleport_dragging = true
		core.teleport_drag_origin = core.get_viewport().get_mouse_position()
		core.teleport_drag_screen = core.teleport_drag_origin
	elif action == "skill":
		core.skill_touch_index = -20
		core.skill_touch_pos = core.get_viewport().get_mouse_position()
	elif action == "secondary":
		core.secondary_touch_index = -20
		core.secondary_touch_pos = core.get_viewport().get_mouse_position()

func _confirm_desktop_aim() -> void :
	var action: String = core.desktop_aim_action
	_clear_desktop_aim_state()
	core.skill_touch_index = -1
	core.secondary_touch_index = -1
	core.dash_touch_index = -1
	core.teleport_dragging = false
	if action != "":
		core._execute_desktop_action(action)

func _cancel_desktop_aim_feedback() -> void :
	if core.desktop_aim_action == "":
		return
	core._add_text("CANCELADO", core.player_pos + Vector2(0, -84), Color(1.0, 0.3, 0.3), 0.55, 17)
	_clear_desktop_aim_state()
	core.skill_touch_index = -1
	core.secondary_touch_index = -1
	core.dash_touch_index = -1
	core.teleport_dragging = false

func _handle_desktop_aim_press(action: String, binding: String) -> bool:
	if not _desktop_action_uses_aim(action):
		core._execute_desktop_action(action)
		return true
	var mode_selected: = _desktop_action_aim_mode(action)
	if mode_selected == core.DESKTOP_AIM_QUICK:
		core._execute_desktop_action(action)
		return true
	if mode_selected == core.DESKTOP_AIM_CONFIRM:
		if core.desktop_aim_action == action:
			_confirm_desktop_aim()
		else:
			_begin_desktop_aim(action, binding, false)
		return true
	_begin_desktop_aim(action, binding, true)
	return true

func _handle_desktop_aim_release(event: InputEvent) -> bool:
	if core.desktop_aim_action == "" or not core.desktop_aim_is_hold:
		return false
	if core._desktop_event_binding(event) != core.desktop_aim_event_binding:
		return false
	_confirm_desktop_aim()
	return true

func _handle_desktop_combat_key(event: InputEventKey) -> bool:
	if not core._uses_desktop_ui() or not _combat_controls_active() or event.echo:
		return false
	for action in core._keyboard_action_order():
		if not core._event_matches_keyboard_action(event, String(action)):
			continue
		if not core._desktop_action_allowed(String(action)):
			return true
		return _handle_desktop_aim_press(String(action), core._desktop_event_binding(event))
	return false

func _handle_desktop_combat_mouse(event: InputEventMouseButton, viewport: Vector2) -> bool:
	if not core._uses_desktop_ui() or not _combat_controls_active() or not event.pressed:
		return false
	if core.desktop_aim_action != "" and event.button_index == MOUSE_BUTTON_RIGHT:
		_cancel_desktop_aim_feedback()
		return true
	for action in core._keyboard_action_order():
		if not core._event_matches_keyboard_action(event, action):
			continue
		if not core._desktop_action_allowed(action):
			return true
		return _handle_desktop_aim_press(action, core._desktop_event_binding(event))
	return false
