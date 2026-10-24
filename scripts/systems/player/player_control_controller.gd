class_name PlayerControlController
extends RefCounted

## Owns player-facing input interpretation. Runtime state and gameplay execution
## remain on the root while the refactor is in progress, so this class never
## duplicates cooldowns, positions, touch indices, or multiplayer authority.

var core: Node
const PARASITICA_SKILL_HOLD_MSEC := 260
const LACERANTE_ULTIMATE_HOLD_MSEC := 260

var skill_press_started_msec: int = 0
var skill_press_origin: Vector2 = Vector2.ZERO
var secondary_press_started_msec: int = 0
var secondary_press_origin: Vector2 = Vector2.ZERO


func configure(runtime: Node) -> void:
	core = runtime


func read_move() -> Vector2:
	if core._apolo_phase5_exhibition_active():
		return core.apolo_phase5_exhibition_move.normalized() if core.apolo_phase5_exhibition_move.length() > 1.0 else core.apolo_phase5_exhibition_move
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move.y += 1.0
	if core.move_touch_index != -1 and core.touch_move.length() > 0.05:
		move = core.touch_move
	if core.is_gamepad_active:
		var gamepad_move := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
		if gamepad_move.length() > 0.15:
			move = gamepad_move
	if core.controls_inverted_timer > 0.0:
		move = -move
	var vector_rotation: float = core._phase4_vector_rotation()
	if not is_zero_approx(vector_rotation) and move.length() > 0.05:
		move = move.rotated(vector_rotation)
	return move.normalized() if move.length() > 1.0 else move


func right_aim_vector() -> Vector2:
	if not core.is_gamepad_active:
		return Vector2.ZERO
	var aim := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	return aim.normalized() if aim.length() > 0.15 else Vector2.ZERO


func aim_direction() -> Vector2:
	if core._apolo_phase5_exhibition_active():
		if core.apolo_phase5_exhibition_aim.length() > 0.05:
			return core.apolo_phase5_exhibition_aim.normalized()
		if core.boss_active and core.boss_hp > 0.0:
			return (core.boss_pos - core.player_pos).normalized()
	var gamepad_aim := right_aim_vector()
	if gamepad_aim != Vector2.ZERO:
		return gamepad_aim
	if core.lacerante_preparing and core.lacerante_prepare_dir.length() > 0.05:
		return core.lacerante_prepare_dir.normalized()
	if core.attack_dragging and core.attack_drag_direction.length() > 0.05:
		return core.attack_drag_direction.normalized()
	if core._uses_desktop_ui() and core._sanitize_desktop_attack_aim_mode(core.desktop_attack_aim_mode) == core.DESKTOP_ATTACK_AIM_CURSOR:
		var to_cursor: Vector2 = desktop_aim_target_world() - core.player_pos
		if to_cursor.length() > 0.05:
			return to_cursor.normalized()
	var target: Vector2 = core._nearest_target()
	if target != Vector2.ZERO:
		var to_target: Vector2 = target - core.player_pos
		if to_target.length() > 0.05:
			return to_target.normalized()
	return core.last_facing.normalized() if core.last_facing.length() > 0.05 else Vector2.RIGHT


func cancel_combat_aim_state(clear_movement := false) -> void:
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
	clear_desktop_aim_state()
	core.skill_touch_pos = Vector2.ZERO
	core.secondary_touch_pos = Vector2.ZERO
	skill_press_started_msec = 0
	skill_press_origin = Vector2.ZERO
	secondary_press_started_msec = 0
	secondary_press_origin = Vector2.ZERO
	if clear_movement:
		core.pointer_down = false
		core.active_screen_touches.clear()
		core.move_touch_index = -1
		core.touch_move = Vector2.ZERO


func should_ignore_emulated_mouse() -> bool:
	return not core.active_screen_touches.is_empty() or Time.get_ticks_msec() <= core.ignore_mouse_until_msec


func mouse_release_has_active_action() -> bool:
	return core.move_touch_index == -2 or core.attack_drag_touch_index == -2 or core.skill_touch_index == -2 or core.secondary_touch_index == -2 or core.dash_touch_index == -2 or core.bombastica_detonator_touch_index == -2 or core.manifest_drag_touch_index == -2 or core.deck_drag_touch_index == -2


func sync_touch_state() -> void:
	if core.move_touch_index >= 0 and not core.active_screen_touches.has(core.move_touch_index):
		stop_move_touch()
	elif core.move_touch_index == -2 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		stop_move_touch()
	if core.attack_drag_touch_index >= 0 and not core.active_screen_touches.has(core.attack_drag_touch_index):
		_clear_attack_drag_state()
	if core.skill_touch_index >= 0 and not core.active_screen_touches.has(core.skill_touch_index):
		core.skill_touch_index = -1
	if core.secondary_touch_index >= 0 and not core.active_screen_touches.has(core.secondary_touch_index):
		core.secondary_touch_index = -1
		secondary_press_started_msec = 0
		secondary_press_origin = Vector2.ZERO
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


func stop_move_touch() -> void:
	core.move_touch_index = -1
	core.touch_move = Vector2.ZERO
	core.pointer_down = false


func touch_record(pos: Vector2) -> Dictionary:
	return {"pos": pos, "last_ms": Time.get_ticks_msec()}


func touch_last_ms(index: int) -> int:
	if not core.active_screen_touches.has(index):
		return 0
	var record = core.active_screen_touches[index]
	return int(record.get("last_ms", 0)) if record is Dictionary else Time.get_ticks_msec()


func move_touch_is_stale(timeout_ms: int) -> bool:
	if core.move_touch_index < 0:
		return false
	var last_ms := touch_last_ms(core.move_touch_index)
	return last_ms > 0 and Time.get_ticks_msec() - last_ms >= timeout_ms


func cancel_touch_index(index: int) -> void:
	core.active_screen_touches.erase(index)
	if index == core.move_touch_index:
		stop_move_touch()
	if index == core.attack_touch_index:
		core.attack_touch_index = -1
	if index == core.attack_drag_touch_index:
		_clear_attack_drag_state()
	if index == core.skill_touch_index:
		core.skill_touch_index = -1
		skill_press_started_msec = 0
		skill_press_origin = Vector2.ZERO
	if index == core.secondary_touch_index:
		core.secondary_touch_index = -1
		secondary_press_started_msec = 0
		secondary_press_origin = Vector2.ZERO
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


func cancel_all_touch_state() -> void:
	core.active_screen_touches.clear()
	cancel_combat_aim_state(true)
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


func claim_action_touch(index: int) -> void:
	if core.move_touch_index == index:
		stop_move_touch()
	elif index >= 0 and core.move_touch_index != -1 and not core.active_screen_touches.has(core.move_touch_index):
		stop_move_touch()


func touch_index_has_action(index: int) -> bool:
	return index == core.attack_drag_touch_index or index == core.skill_touch_index or index == core.secondary_touch_index or index == core.dash_touch_index or index == core.bombastica_detonator_touch_index or index == core.dance_wheel_touch_index


func try_start_move_touch(index: int, pos: Vector2, viewport: Vector2) -> bool:
	if core._local_player_controls_locked():
		return false
	if core.move_touch_index != -1:
		if index != core.move_touch_index and move_touch_is_stale(900):
			stop_move_touch()
		else:
			return false
	if touch_index_has_action(index):
		return false
	var joy: Vector2 = core._joy_center(viewport)
	var joy_radius: float = 116.0 * core._joy_scale()
	var fixed_hit: bool = pos.distance_to(joy) < joy_radius
	var dynamic_hit: bool = not core.analog_fixed and pos.x <= viewport.x * 0.48
	if not fixed_hit and not dynamic_hit:
		return false
	core.move_touch_index = index
	core.pointer_down = true
	core.joystick_origin = joy if core.analog_fixed or fixed_hit else pos
	core.touch_move = ((pos - core.joystick_origin) / (76.0 * core._joy_scale())).limit_length(1.0)
	return true


func handle_touch_press(index: int, pos: Vector2, viewport: Vector2) -> void:
	if core._handle_revive_overlay_press(pos) or core._handle_pause_mp_overlay_press(pos) or core._handle_phase_mp_overlay_press(pos, viewport) or core._handle_shop_mp_overlay_press(pos, viewport) or core._handle_boss_mp_overlay_press(pos, viewport):
		return
	if core.mode not in ["game", "shop_countdown", "boss_call", "pause_countdown"]:
		core._handle_press(pos, viewport)
		return
	if core._local_player_controls_locked():
		cancel_combat_aim_state(true)
		return
	if core.buttons.has("lacerante_empower") and core.buttons["lacerante_empower"].has_point(pos):
		claim_action_touch(index)
		if core.manifestation_key == "eclipsada": core._toggle_eclipsada_form()
		elif core.manifestation_key == "necronada": core._try_arm_necronada_empower()
		else: core._try_arm_lacerante_empower()
		return
	if core.buttons.has("bombastica_detonator") and core.buttons["bombastica_detonator"].has_point(pos):
		claim_action_touch(index); core.bombastica_detonator_touch_index = index; core.bombastica_detonator_hold = 0.0; return
	if core._uses_touch_ui() and core._local_revival_altar_method() != "" and core.buttons.get("attack", Rect2()).has_point(pos):
		claim_action_touch(index); core._handle_revival_mobile_tap(); return
	if core.buttons["attack"].has_point(pos):
		claim_action_touch(index); core.attack_drag_touch_index = index; core.attack_holding = true; core.attack_hold_timer = 0.0; core.attack_dragging = false; core.attack_drag_start_pos = pos; core.attack_touch_pos = pos; core.attack_drag_direction = aim_direction(); core._try_attack(); return
	if core.buttons["skill"].has_point(pos):
		claim_action_touch(index); core.skill_touch_index = index; core.skill_touch_pos = pos; skill_press_started_msec = Time.get_ticks_msec(); skill_press_origin = pos; return
	if core.buttons["secondary"].has_point(pos):
		claim_action_touch(index); core.secondary_touch_index = index; core.secondary_touch_pos = pos; secondary_press_started_msec = Time.get_ticks_msec(); secondary_press_origin = pos; return
	if core.buttons["dash"].has_point(pos):
		claim_action_touch(index); core.dash_touch_index = index; core.teleport_dragging = true; core.teleport_drag_origin = pos; core.teleport_drag_screen = pos; return
	if core.buttons["pause"].has_point(pos): core._start_pause_countdown(); return
	if core.buttons.has("shop_manual") and core.buttons["shop_manual"].has_point(pos): core._try_open_manual_shop(); return
	if core.buttons["boss"].has_point(pos): core._start_boss_call(); return
	if not try_start_move_touch(index, pos, viewport):
		core.dance_wheel_touch_index = index; core.dance_wheel_start_pos = pos; core.dance_wheel_hold_timer = 0.0; core.dance_wheel_active = false


func handle_touch_drag(index: int, pos: Vector2, viewport: Vector2) -> void:
	if core._spectator_combat_mode():
		core._clear_spectator_local_combat_state(); return
	if index == core.attack_drag_touch_index:
		core.attack_touch_pos = pos
		var delta_vec: Vector2 = pos - core.attack_drag_start_pos
		if core.attack_lock_selecting: core._update_attack_lock_candidate(pos, viewport)
		elif delta_vec.length() > 25.0: core.attack_dragging = true
		if not core.attack_lock_selecting and delta_vec.length() > 10.0: core.attack_drag_direction = delta_vec.normalized()
	elif index == core.skill_touch_index: core.skill_touch_pos = pos
	elif index == core.secondary_touch_index: core.secondary_touch_pos = pos
	elif index == core.dash_touch_index: core.teleport_drag_screen = pos
	elif index == core.move_touch_index: core.touch_move = ((pos - core.joystick_origin) / (76.0 * core._joy_scale())).limit_length(1.0)
	elif index == core.dance_wheel_touch_index and (pos.distance_to(core.dance_wheel_start_pos) > 18.0 or core.dance_wheel_hold_timer > 0.2): core.dance_wheel_active = true


func handle_touch_release(index: int, pos: Vector2, viewport: Vector2) -> void:
	var combat_active: bool = core._combat_controls_active()
	if index == core.move_touch_index: stop_move_touch()
	if index == core.dance_wheel_touch_index:
		if core.dance_wheel_active:
			core.dance_wheel_active = false; core.player_dancing = true; core.player_dance_timer = 0.0
			core._add_text("DANCA PRISMATICA!", core.player_pos + Vector2(0, -60), Color(0.95, 0.45, 1.0), 1.25, 22)
		core.dance_wheel_touch_index = -1
	if index == core.attack_touch_index: core.attack_touch_index = -1
	if index == core.attack_drag_touch_index:
		if core.attack_lock_selecting and combat_active: core._update_attack_lock_candidate(pos, viewport); core._commit_attack_lock()
		_clear_attack_drag_state()
	if index == core.skill_touch_index:
		if core._ability_cancel_has_point(pos, viewport): core._add_text("CANCELADO", core.player_pos + Vector2(0, -84), Color(1.0, 0.3, 0.3), 0.55, 17)
		elif combat_active:
			var profile = core._ground_target_profile(false)
			if core.manifestation_key == "parasitica" and _parasitica_skill_quick_release(pos):
				_use_parasitica_quick_skill(not core._uses_touch_ui())
			elif profile.is_empty(): core._use_skill()
			else: core._use_skill(core._ground_target_world(pos, viewport, false))
		core.skill_touch_index = -1
		skill_press_started_msec = 0
		skill_press_origin = Vector2.ZERO
	if index == core.secondary_touch_index:
		if core._ability_cancel_has_point(pos, viewport): core._add_text("CANCELADO", core.player_pos + Vector2(0, -84), Color(1.0, 0.3, 0.3), 0.55, 17)
		elif combat_active:
			var profile = core._ground_target_profile(true)
			if core.manifestation_key == "lacerante" and _lacerante_ultimate_quick_release(pos):
				_use_lacerante_quick_ultimate(not core._uses_touch_ui())
			elif profile.is_empty(): core._use_secondary_skill()
			else: core._use_secondary_skill(core._ground_target_world(pos, viewport, true))
		core.secondary_touch_index = -1
		secondary_press_started_msec = 0
		secondary_press_origin = Vector2.ZERO
	if index == core.dash_touch_index:
		if core._ability_cancel_has_point(pos, viewport): core._add_text("CANCELADO", core.player_pos + Vector2(0, -84), Color(1.0, 0.3, 0.3), 0.55, 17)
		elif combat_active: core._try_dash_to_screen(pos, viewport)
		core.dash_touch_index = -1; core.teleport_dragging = false
	if index == core.bombastica_detonator_touch_index:
		if combat_active and core.bombastica_detonator_hold < 0.62: core._trigger_bombastica_detonator(false)
		core.bombastica_detonator_touch_index = -1; core.bombastica_detonator_hold = 0.0


func handle_mouse_press(pos: Vector2, viewport: Vector2) -> void:
	if core._handle_revive_overlay_press(pos) or core._handle_pause_mp_overlay_press(pos, viewport) or core._handle_shop_mp_overlay_press(pos, viewport) or core._handle_boss_mp_overlay_press(pos, viewport) or core._handle_phase_mp_overlay_press(pos, viewport): return
	if core.mode in ["game", "shop_countdown", "boss_call", "pause_countdown"]:
		if core._local_player_controls_locked(): cancel_combat_aim_state(true); return
		if core.buttons.has("lacerante_empower") and core.buttons["lacerante_empower"].has_point(pos):
			claim_action_touch(-2)
			if core.manifestation_key == "eclipsada": core._toggle_eclipsada_form()
			elif core.manifestation_key == "necronada": core._try_arm_necronada_empower()
			else: core._try_arm_lacerante_empower()
			return
		if core.buttons.has("bombastica_detonator") and core.buttons["bombastica_detonator"].has_point(pos): claim_action_touch(-2); core.bombastica_detonator_touch_index = -2; core.bombastica_detonator_hold = 0.0; return
		if core.buttons["attack"].has_point(pos): handle_touch_press(-2, pos, viewport); return
		if core.buttons["dash"].has_point(pos): handle_touch_press(-2, pos, viewport); return
		if core.buttons["skill"].has_point(pos): handle_touch_press(-2, pos, viewport); return
		if core.buttons["secondary"].has_point(pos): handle_touch_press(-2, pos, viewport); return
		if core._uses_desktop_ui(): core._try_attack(); return
	core._handle_press(pos, viewport)


func _clear_attack_drag_state() -> void:
	core.attack_drag_touch_index = -1
	core.attack_dragging = false
	core.attack_holding = false
	core.attack_hold_timer = 0.0
	core.attack_lock_selecting = false
	core.attack_lock_candidate_kind = ""
	core.attack_lock_candidate_uid = -1


func clear_desktop_aim_state() -> void:
	core.desktop_aim_action = ""
	core.desktop_aim_event_binding = ""
	core.desktop_aim_is_hold = false


func desktop_action_allowed(action: String, cooldown_ms := 160) -> bool:
	var now := Time.get_ticks_msec()
	var last := int(core.desktop_action_gate_msec.get(action, -1000000))
	if now - last < cooldown_ms: return false
	core.desktop_action_gate_msec[action] = now
	return true


func desktop_action_binding(action: String) -> String:
	return core._normalize_input_binding(core.keyboard_bindings.get(action, core.INPUT_BIND_NONE))


func desktop_event_binding(event: InputEvent) -> String:
	if event is InputEventKey: return core._key_input_binding(event.keycode if event.keycode > 0 else event.physical_keycode)
	if event is InputEventMouseButton: return core._mouse_input_binding(event.button_index)
	return core.INPUT_BIND_NONE


func desktop_skill_mode() -> String:
	return core._sanitize_desktop_aim_mode(core.desktop_aim_mode)


func desktop_dash_mode() -> String:
	return core._sanitize_desktop_teleport_mode(core.desktop_teleport_mode)


func desktop_aim_target_world() -> Vector2:
	var viewport: Vector2 = core.get_viewport_rect().size
	return (core.get_viewport().get_mouse_position() + core._camera(viewport)).clamp(Vector2.ZERO, core.WORLD_SIZE)


func desktop_cursor_ground_target(secondary: bool) -> Variant:
	if core._ground_target_profile(secondary).is_empty(): return null
	var profile: Dictionary = core._ground_target_profile(secondary)
	var delta: Vector2 = desktop_aim_target_world() - core.player_pos
	if delta.length() <= 0.05: delta = aim_direction() * float(profile.get("default", 160.0))
	if delta.length() <= 0.05: delta = Vector2.RIGHT * float(profile.get("default", 160.0))
	return core.player_pos + delta.normalized() * clampf(delta.length(), float(profile.get("minimum", 0.0)), float(profile.get("range", core.PLAYER_DASH_DISTANCE)))


func desktop_auto_teleport_target() -> Vector2:
	var target: Vector2 = core._nearest_target()
	if target != Vector2.ZERO:
		var offset: Vector2 = target - core.player_pos
		if offset.length() > 0.05: return core.player_pos + offset.limit_length(core.PLAYER_DASH_DISTANCE)
	var direction: Vector2 = aim_direction()
	if direction.length() <= 0.05: direction = core.last_facing.normalized() if core.last_facing.length() > 0.05 else Vector2.RIGHT
	return core.player_pos + direction.normalized() * core.PLAYER_DASH_DISTANCE


func desktop_last_direction_teleport_target() -> Vector2:
	var direction: Vector2 = core.last_facing.normalized()
	if direction.length() <= 0.05: direction = Vector2.RIGHT
	return core.player_pos + direction * core.PLAYER_DASH_DISTANCE


func desktop_dash_target() -> Vector2:
	if desktop_dash_mode() == core.DESKTOP_TELEPORT_AUTO: return desktop_auto_teleport_target()
	if desktop_dash_mode() == core.DESKTOP_TELEPORT_LAST_DIRECTION: return desktop_last_direction_teleport_target()
	var viewport: Vector2 = core.get_viewport_rect().size
	var offset: Vector2 = (core.get_viewport().get_mouse_position() + core._camera(viewport)).clamp(Vector2.ZERO, core.WORLD_SIZE) - core.player_pos
	if offset.length() <= 8.0: offset = aim_direction() * core.PLAYER_DASH_DISTANCE
	if offset.length() <= 0.05: offset = (core.last_facing.normalized() if core.last_facing.length() > 0.05 else Vector2.RIGHT) * core.PLAYER_DASH_DISTANCE
	return core.player_pos + offset.limit_length(core.PLAYER_DASH_DISTANCE)


func use_desktop_skill(secondary: bool) -> void:
	var target = desktop_cursor_ground_target(secondary)
	if secondary:
		if target is Vector2: core._use_secondary_skill(target)
		else: core._use_secondary_skill()
	else:
		if target is Vector2: core._use_skill(target)
		else: core._use_skill()


func execute_desktop_action(action: String) -> void:
	match action:
		"attack": core._try_attack()
		"skill": use_desktop_skill(false)
		"secondary": use_desktop_skill(true)
		"dash":
			if desktop_dash_mode() == core.DESKTOP_TELEPORT_AUTO: core._try_dash_to_world(desktop_auto_teleport_target())
			elif desktop_dash_mode() == core.DESKTOP_TELEPORT_LAST_DIRECTION: core._try_dash_to_world(desktop_last_direction_teleport_target())
			else: core._try_dash_to_world(desktop_dash_target())
		"lacerante_empower":
			if core.manifestation_key == "bombastica": core._trigger_bombastica_detonator(false)
			elif core.manifestation_key == "eclipsada": core._toggle_eclipsada_form()
			elif core.manifestation_key == "necronada": core._try_arm_necronada_empower()
			else: core._try_arm_lacerante_empower()
		"dance": core._toggle_player_dance()
		"interact": core._try_interact_revival_altar()
		"pause": core._start_pause_countdown()
		"shop": core._try_open_manual_shop()
		"boss": core._start_boss_call()


func desktop_action_uses_aim(action: String) -> bool:
	return action in ["skill", "secondary", "dash"]


func desktop_action_aim_mode(action: String) -> String:
	if action == "dash":
		var dash_mode := desktop_dash_mode()
		return dash_mode if dash_mode in [core.DESKTOP_AIM_HOLD, core.DESKTOP_AIM_CONFIRM] else core.DESKTOP_AIM_QUICK
	return desktop_skill_mode()


func begin_desktop_aim(action: String, binding: String, hold: bool) -> void:
	core.desktop_aim_action = action; core.desktop_aim_event_binding = binding; core.desktop_aim_is_hold = hold
	if action == "dash":
		core.teleport_dragging = true; core.teleport_drag_origin = core.get_viewport().get_mouse_position(); core.teleport_drag_screen = core.teleport_drag_origin
	elif action == "skill": core.skill_touch_index = -20; core.skill_touch_pos = core.get_viewport().get_mouse_position(); skill_press_started_msec = Time.get_ticks_msec(); skill_press_origin = core.skill_touch_pos
	elif action == "secondary": core.secondary_touch_index = -20; core.secondary_touch_pos = core.get_viewport().get_mouse_position(); secondary_press_started_msec = Time.get_ticks_msec(); secondary_press_origin = core.secondary_touch_pos


func confirm_desktop_aim() -> void:
	var action: String = core.desktop_aim_action
	clear_desktop_aim_state(); core.skill_touch_index = -1; core.secondary_touch_index = -1; core.dash_touch_index = -1; core.teleport_dragging = false
	skill_press_started_msec = 0
	skill_press_origin = Vector2.ZERO
	secondary_press_started_msec = 0
	secondary_press_origin = Vector2.ZERO
	if action != "": execute_desktop_action(action)


func cancel_desktop_aim_feedback() -> void:
	if core.desktop_aim_action == "": return
	core._add_text("CANCELADO", core.player_pos + Vector2(0, -84), Color(1.0, 0.3, 0.3), 0.55, 17)
	clear_desktop_aim_state(); core.skill_touch_index = -1; core.secondary_touch_index = -1; core.dash_touch_index = -1; core.teleport_dragging = false
	skill_press_started_msec = 0
	skill_press_origin = Vector2.ZERO
	secondary_press_started_msec = 0
	secondary_press_origin = Vector2.ZERO


func handle_desktop_aim_press(action: String, binding: String) -> bool:
	if not desktop_action_uses_aim(action): execute_desktop_action(action); return true
	if action == "skill" and core.manifestation_key == "parasitica":
		begin_desktop_aim(action, binding, true)
		return true
	if action == "secondary" and core.manifestation_key == "lacerante":
		begin_desktop_aim(action, binding, true)
		return true
	var selected := desktop_action_aim_mode(action)
	if selected == core.DESKTOP_AIM_QUICK: execute_desktop_action(action); return true
	if selected == core.DESKTOP_AIM_CONFIRM:
		if core.desktop_aim_action == action: confirm_desktop_aim()
		else: begin_desktop_aim(action, binding, false)
		return true
	begin_desktop_aim(action, binding, true)
	return true


func handle_desktop_aim_release(event: InputEvent) -> bool:
	if core.desktop_aim_action == "" or not core.desktop_aim_is_hold or desktop_event_binding(event) != core.desktop_aim_event_binding: return false
	if core.desktop_aim_action == "skill" and core.manifestation_key == "parasitica":
		var quick_release := _parasitica_skill_quick_release(core.get_viewport().get_mouse_position())
		clear_desktop_aim_state(); core.skill_touch_index = -1
		if quick_release: _use_parasitica_quick_skill(true)
		else: use_desktop_skill(false)
		skill_press_started_msec = 0
		skill_press_origin = Vector2.ZERO
		return true
	if core.desktop_aim_action == "secondary" and core.manifestation_key == "lacerante":
		var quick_release := _lacerante_ultimate_quick_release(core.get_viewport().get_mouse_position())
		clear_desktop_aim_state(); core.secondary_touch_index = -1
		if quick_release: _use_lacerante_quick_ultimate(true)
		else: use_desktop_skill(true)
		secondary_press_started_msec = 0
		secondary_press_origin = Vector2.ZERO
		return true
	confirm_desktop_aim(); return true


func _parasitica_skill_quick_release(release_pos: Vector2) -> bool:
	var held_msec := maxi(0, Time.get_ticks_msec() - skill_press_started_msec)
	return held_msec < PARASITICA_SKILL_HOLD_MSEC and release_pos.distance_to(skill_press_origin) <= core.ABILITY_TARGET_DRAG_DEADZONE


func _use_parasitica_quick_skill(use_configured_priority: bool) -> void:
	var target = core._parasitica_quick_skill_target(use_configured_priority)
	if target is Vector2: core._use_skill(target)
	else: core._use_skill()


func _lacerante_ultimate_quick_release(release_pos: Vector2) -> bool:
	var held_msec := maxi(0, Time.get_ticks_msec() - secondary_press_started_msec)
	return held_msec < LACERANTE_ULTIMATE_HOLD_MSEC and release_pos.distance_to(secondary_press_origin) <= core.ABILITY_TARGET_DRAG_DEADZONE


func _use_lacerante_quick_ultimate(use_configured_priority: bool) -> void:
	var target = core._lacerante_quick_ultimate_target(use_configured_priority)
	if target is Vector2: core._use_secondary_skill(target)
	else: core._use_secondary_skill()


func handle_desktop_combat_key(event: InputEventKey) -> bool:
	if not core._uses_desktop_ui() or not core._combat_controls_active() or event.echo: return false
	for action in core._keyboard_action_order():
		if core._event_matches_keyboard_action(event, String(action)):
			return true if not desktop_action_allowed(String(action)) else handle_desktop_aim_press(String(action), desktop_event_binding(event))
	return false


func handle_desktop_combat_mouse(event: InputEventMouseButton, _viewport: Vector2) -> bool:
	if not core._uses_desktop_ui() or not core._combat_controls_active() or not event.pressed: return false
	if core.desktop_aim_action != "" and event.button_index == MOUSE_BUTTON_RIGHT: cancel_desktop_aim_feedback(); return true
	for action in core._keyboard_action_order():
		if core._event_matches_keyboard_action(event, action):
			return true if not desktop_action_allowed(action) else handle_desktop_aim_press(action, desktop_event_binding(event))
	return false


func simulate_key_press(keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	core._handle_key(event)


func gamepad_action_for_button(button_id: String) -> String:
	for action in core._gamepad_action_order():
		if button_id == str(core.gamepad_bindings.get(action, -1)):
			return action
	return ""


func handle_gamepad_ui_action(action: String) -> void:
	if core.mode == "paused":
		if action == "pause" or action == "secondary": core._resume_from_pause()
		elif action in ["attack", "dash", "skill"]: simulate_key_press(KEY_ENTER)
		return
	if core.mode == "manifest_evolution":
		if action in ["attack", "dash", "skill"]: simulate_key_press(KEY_ENTER)
		elif action in ["pause", "secondary"]: simulate_key_press(KEY_RIGHT)
		return
	if core.mode == "shop":
		if core._shop_purchase_animating(): return
		if action in ["pause", "shop"]:
			if core._shop_can_exit(): core._request_shop_exit_or_finish()
		elif action in ["attack", "dash"]: core._buy_selected_card()
		elif action == "skill": core._reroll_shop()
		elif action == "secondary": core._open_deck("shop")
		return
	if action in ["pause", "secondary"]: simulate_key_press(KEY_ESCAPE)
	elif action in ["attack", "dash", "skill"]: simulate_key_press(KEY_ENTER)


func handle_gamepad_virtual_button(button_id: String, pressed: bool, viewport: Vector2) -> void:
	var action := gamepad_action_for_button(button_id)
	if action == "": return
	var combat_active: bool = core._combat_controls_active()
	if pressed:
		if core._pause_mp_request_visible() and core.pause_mp_request_incoming and action in ["attack", "pause"]: core._accept_pause_mp_request(); return
		if core._shop_mp_request_visible() and core.shop_mp_request_incoming and action in ["attack", "shop"]: core._accept_shop_mp_request(); return
		if core._boss_mp_request_visible() and core.boss_mp_request_incoming and action in ["attack", "boss"]: core._accept_boss_mp_request(); return
		if combat_active and action == "attack" and core.buttons.has("attack"): handle_touch_press(-3, core.buttons["attack"].get_center(), viewport)
		elif combat_active and action == "skill" and core.buttons.has("skill"): handle_touch_press(-4, core.buttons["skill"].get_center(), viewport)
		elif combat_active and action == "secondary" and core.buttons.has("secondary"): handle_touch_press(-5, core.buttons["secondary"].get_center(), viewport)
		elif combat_active and action == "dash" and core.buttons.has("dash"): handle_touch_press(-6, core.buttons["dash"].get_center(), viewport)
		elif combat_active and action == "pause": core._start_pause_countdown()
		elif combat_active and action == "shop": core._try_open_manual_shop()
		elif combat_active and action == "boss": core._start_boss_call()
		elif combat_active and action == "lacerante_empower" and core.buttons.has("lacerante_empower"): handle_touch_press(-8, core.buttons["lacerante_empower"].get_center(), viewport)
		elif combat_active and action == "bombastica_detonator" and core.buttons.has("bombastica_detonator"): handle_touch_press(-9, core.buttons["bombastica_detonator"].get_center(), viewport)
		elif not combat_active: handle_gamepad_ui_action(action)
	else:
		if action == "attack" and core.buttons.has("attack"): handle_touch_release(-3, core.buttons["attack"].get_center(), viewport)
		elif action == "skill" and core.buttons.has("skill"): handle_touch_release(-4, core.buttons["skill"].get_center(), viewport)
		elif action == "secondary" and core.buttons.has("secondary"): handle_touch_release(-5, core.buttons["secondary"].get_center(), viewport)
		elif action == "dash" and core.buttons.has("dash"): handle_touch_release(-6, core.buttons["dash"].get_center(), viewport)
		elif action == "bombastica_detonator" and core.buttons.has("bombastica_detonator"): handle_touch_release(-9, core.buttons["bombastica_detonator"].get_center(), viewport)
