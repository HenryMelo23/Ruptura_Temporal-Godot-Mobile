extends RefCounted


static func _handle_settings_touch(game: Node, pos: Vector2, viewport: Vector2) -> void :
	game.settings_buttons = game._settings_rects(viewport)
	var option_keys: Array = game._settings_option_keys()
	for i in range(option_keys.size()):
		var key: = String(option_keys[i])
		if game.settings_buttons.has(key) and game.settings_buttons[key].has_point(pos):
			game.settings_selected = i
			game._activate_settings_option(i, viewport)
			return


static func _handle_keyboard_settings_touch(game: Node, pos: Vector2, viewport: Vector2) -> void :
	game.settings_buttons = game._keyboard_settings_rects(viewport)
	var actions: Array = game._keyboard_action_order()
	for i in range(actions.size()):
		var action: = String(actions[i])
		if game.settings_buttons.has(action) and game.settings_buttons[action].has_point(pos):
			game.settings_selected = i
			game.keyboard_mapping_action = action
			return
	if game.settings_buttons.has("reset") and game.settings_buttons["reset"].has_point(pos):
		game.settings_selected = actions.size()
		game._reset_keyboard_bindings()
		game._save_config()
		return
	if game.settings_buttons.has("back") and game.settings_buttons["back"].has_point(pos):
		game.keyboard_mapping_action = ""
		game._save_config()
		game.mode = "settings"
		game._block_ui_input()


static func _handle_gamepad_settings_touch(game: Node, pos: Vector2, viewport: Vector2) -> void :
	if game.gamepad_mapping_action != "":
		return
	game.settings_buttons = game._gamepad_settings_rects(viewport)
	for action in game._gamepad_action_order():
		if game.settings_buttons.has(action) and game.settings_buttons[action].has_point(pos):
			game.gamepad_mapping_action = action
			return
	if game.settings_buttons["back"].has_point(pos):
		game.gamepad_mapping_action = ""
		game.mode = "settings"
		game._block_ui_input()


static func _handle_gameplay_settings_touch(game: Node, pos: Vector2, viewport: Vector2) -> void :
	game.settings_buttons = game._gameplay_preferences_rects(viewport)
	if game.gameplay_cheat_focused:
		game.settings_buttons["cheat_ok"] = Rect2()
		game.settings_buttons["cheat_cancel"] = Rect2()
		var panel: Rect2 = game._cheat_popup_rect(viewport)
		game.settings_buttons["cheat_ok"] = Rect2(panel.position.x + panel.size.x * 0.5 - 168.0, panel.end.y - 62.0, 152.0, 44.0)
		game.settings_buttons["cheat_cancel"] = Rect2(panel.position.x + panel.size.x * 0.5 + 16.0, panel.end.y - 62.0, 152.0, 44.0)
		if game.settings_buttons["cheat_ok"].has_point(pos):
			game._submit_gameplay_cheat()
		elif game.settings_buttons["cheat_cancel"].has_point(pos):
			game._close_gameplay_cheat_popup()
			game._save_config()
		elif game.cheat_edit != null:
			game.cheat_edit.grab_focus()
		return
	if game.settings_buttons.has("analog") and game.settings_buttons["analog"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game.analog_fixed = not game.analog_fixed
		game._save_config()
	elif game.settings_buttons["target_priority"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game.auto_target_priority = game._next_target_priority(game.auto_target_priority)
		game._save_config()
	elif game.settings_buttons.has("desktop_aim") and game.settings_buttons["desktop_aim"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game._cycle_desktop_aim_mode()
		game._save_config()
	elif game.settings_buttons.has("desktop_teleport") and game.settings_buttons["desktop_teleport"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game._cycle_desktop_teleport_mode()
		game._save_config()
	elif game.settings_buttons.has("desktop_attack_aim") and game.settings_buttons["desktop_attack_aim"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game._cycle_desktop_attack_aim_mode()
		game._save_config()
	elif game.settings_buttons.has("desktop_hud_scale") and game.settings_buttons["desktop_hud_scale"].has_point(pos):
		game._close_gameplay_cheat_popup()
		var hud_panel: Rect2 = game.settings_buttons["desktop_hud_scale"]
		if game._desktop_hud_scale_minus_rect(hud_panel).has_point(pos):
			game._cycle_desktop_hud_scale(-1)
		elif game._desktop_hud_scale_plus_rect(hud_panel).has_point(pos):
			game._cycle_desktop_hud_scale(1)
		else:
			game._cycle_desktop_hud_scale(1)
		game._save_config()
	elif game.settings_buttons["damage_text"].has_point(pos):
		game._close_gameplay_cheat_popup()
		var damage_panel: Rect2 = game.settings_buttons["damage_text"]
		if game._damage_text_minus_rect(damage_panel).has_point(pos):
			game._adjust_damage_text_scale(-1)
			game._save_config()
		elif game._damage_text_plus_rect(damage_panel).has_point(pos):
			game._adjust_damage_text_scale(1)
			game._save_config()
	elif game.settings_buttons["interface_text"].has_point(pos):
		game._close_gameplay_cheat_popup()
		var interface_panel: Rect2 = game.settings_buttons["interface_text"]
		if game._interface_text_minus_rect(interface_panel).has_point(pos):
			game.interface_text_scale = max(0.9, snapped(game.interface_text_scale - 0.1, 0.1))
			game._save_config()
		elif game._interface_text_plus_rect(interface_panel).has_point(pos):
			game.interface_text_scale = min(1.6, snapped(game.interface_text_scale + 0.1, 0.1))
			game._save_config()
	elif game.settings_buttons["color_vision"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game.ColorVisionFilterScript.cycle(game)
		game._save_config()
	elif game.settings_buttons["fps"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game.show_fps_counter = not game.show_fps_counter
		game._save_config()
	elif game.settings_buttons["tutorial"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game._set_run_tutorial_enabled(not game.run_tutorial_enabled)
	elif game.settings_buttons["gameplay_cheat"].has_point(pos):
		game._open_gameplay_cheat_popup()
	elif game.settings_buttons.has("haptics") and game.settings_buttons["haptics"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game.haptics_enabled = not game.haptics_enabled
		if game.haptics_enabled:
			game._vibrate(55, 0.25)
		game._save_config()
	elif game.settings_buttons.has("ui_platform_profile") and game.settings_buttons["ui_platform_profile"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game._cycle_ui_platform_override()
		game._save_config()
	elif game.QA_STREAMING_FEATURE_ENABLED and game.settings_buttons.has("qa_stream_quality") and game.settings_buttons["qa_stream_quality"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game._cycle_qa_stream_quality_mode()
		game._save_config()
	elif game.settings_buttons["back"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game._save_config()
		game.mode = "settings"
		game._block_ui_input()


static func _handle_audio_settings_touch(game: Node, pos: Vector2, viewport: Vector2) -> void :
	game.settings_buttons = game._audio_settings_rects(viewport)
	var panel: Rect2 = game.settings_buttons["panel"]
	for i in range(4):
		if game._audio_minus_rect(panel, i).has_point(pos):
			game.settings_selected = i
			game._set_audio_volume_index(i, game._audio_volume_index(i) - 0.1)
			return
		if game._audio_plus_rect(panel, i).has_point(pos):
			game.settings_selected = i
			game._set_audio_volume_index(i, game._audio_volume_index(i) + 0.1)
			return
		if game._audio_slider_hit_rect(panel, i).has_point(pos):
			game.settings_selected = i
			game.audio_slider_drag_index = i
			game._update_audio_slider_from_pos(pos, viewport)
			return
	if game.settings_buttons["back"].has_point(pos):
		game._save_config()
		game.mode = "settings"
		game._block_ui_input()


static func _handle_data_settings_touch(game: Node, pos: Vector2, viewport: Vector2) -> void :
	game._sync_webhook_input_rect(viewport)
	if game.settings_buttons.get("data_save", Rect2()).has_point(pos):
		game._save_webhook_from_input()
	elif game.settings_buttons.get("data_clear", Rect2()).has_point(pos):
		game._clear_run_report_webhook()
	elif game.settings_buttons.get("data_back", Rect2()).has_point(pos):
		game.mode = "settings"
		game._update_webhook_input_visibility()
		game._block_ui_input()
	elif game.webhook_edit != null:
		game.webhook_edit.grab_focus()


static func _handle_graphics_settings_touch(game: Node, pos: Vector2, viewport: Vector2) -> void :
	game.settings_buttons = game._graphics_settings_rects(viewport)
	for key in game._graphics_setting_keys():
		var option: = String(key)
		if game.settings_buttons.has(option) and game.settings_buttons[option].has_point(pos):
			if option == "range_opacity":
				var panel: Rect2 = game.settings_buttons[option]
				if game._range_opacity_minus_rect(panel).has_point(pos):
					game.auto_attack_range_opacity = game.RangedAttackRange.sanitize_indicator_opacity(game.auto_attack_range_opacity - 0.1)
				elif game._range_opacity_plus_rect(panel).has_point(pos):
					game.auto_attack_range_opacity = game.RangedAttackRange.sanitize_indicator_opacity(game.auto_attack_range_opacity + 0.1)
				else:
					game._activate_graphics_setting(option)
				game._save_config()
				return
			game._activate_graphics_setting(option)
			return


## P1.02: navegação por teclado das telas de configurações (antes inline em
## `_handle_key` do core). Ordem dos ramos e condições preservadas.
const KEY_MODES: Array[String] = ["settings", "settings_gamepad", "settings_keys", "settings_gameplay", "settings_audio", "settings_graphics", "settings_data"]


static func handle_key(game: Node, event: InputEventKey) -> void :
	match String(game.mode):
		"settings": _settings_root_key(game, event)
		"settings_gamepad": _settings_gamepad_key(game, event)
		"settings_keys": _settings_keys_key(game, event)
		"settings_gameplay": _settings_gameplay_key(game, event)
		"settings_audio": _settings_audio_key(game, event)
		"settings_graphics": _settings_graphics_key(game, event)
		"settings_data": _settings_data_key(game, event)


static func _settings_root_key(game: Node, event: InputEventKey) -> void :
	if game._is_escape_or_pause_key(event):
		game._return_from_settings()
	elif event.keycode == KEY_UP or event.keycode == KEY_W:
		game.settings_selected = (game.settings_selected - 1 + game._settings_option_count()) % game._settings_option_count()
	elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
		game.settings_selected = (game.settings_selected + 1) % game._settings_option_count()
	elif event.keycode in [KEY_ENTER, KEY_SPACE]:
		game._activate_settings_option(game.settings_selected, game.get_viewport_rect().size)


static func _settings_gamepad_key(game: Node, event: InputEventKey) -> void :
	if event.keycode == KEY_ESCAPE:
		game.gamepad_mapping_action = ""
		game.mode = "settings"
	elif event.keycode == KEY_UP or event.keycode == KEY_W:
		game.settings_selected = (game.settings_selected - 1 + game._gamepad_action_order().size() + 1) % (game._gamepad_action_order().size() + 1)
	elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
		game.settings_selected = (game.settings_selected + 1) % (game._gamepad_action_order().size() + 1)
	elif event.keycode in [KEY_ENTER, KEY_SPACE]:
		var actions = game._gamepad_action_order()
		if game.settings_selected == actions.size():
			game.gamepad_mapping_action = ""
			game.mode = "settings"
		else:
			game.gamepad_mapping_action = actions[game.settings_selected]


static func _settings_keys_key(game: Node, event: InputEventKey) -> void :
	var actions: Array = game._keyboard_action_order()
	var option_count: int = actions.size() + 2
	if event.keycode == KEY_ESCAPE:
		game.keyboard_mapping_action = ""
		game._save_config()
		game.mode = "settings"
	elif event.keycode == KEY_UP or event.keycode == KEY_W:
		game.settings_selected = (game.settings_selected - 1 + option_count) % option_count
	elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
		game.settings_selected = (game.settings_selected + 1) % option_count
	elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
		if game.settings_selected >= 0 and game.settings_selected < actions.size():
			game.keyboard_bindings[String(actions[game.settings_selected])] = game.INPUT_BIND_NONE
			game._save_config()
	elif event.keycode in [KEY_ENTER, KEY_SPACE]:
		if game.settings_selected < actions.size():
			game.keyboard_mapping_action = String(actions[game.settings_selected])
		elif game.settings_selected == actions.size():
			game._reset_keyboard_bindings()
			game._save_config()
		else:
			game._save_config()
			game.mode = "settings"


static func _settings_gameplay_key(game: Node, event: InputEventKey) -> void :
	if game.gameplay_cheat_focused:
		if event.keycode == KEY_ESCAPE:
			game._close_gameplay_cheat_popup()
		elif event.keycode == KEY_BACKSPACE:
			if game.cheat_edit == null:
				if game.gameplay_cheat_text.length() > 0:
					game.gameplay_cheat_text = game.gameplay_cheat_text.substr(0, game.gameplay_cheat_text.length() - 1)
		elif event.keycode == KEY_ENTER:
			game._submit_gameplay_cheat()
		elif game.cheat_edit == null and event.unicode >= 32 and game.gameplay_cheat_text.length() < 24:
			game.gameplay_cheat_text += char(event.unicode)
	elif event.keycode == KEY_ESCAPE:
		game._save_config()
		game.mode = "settings"
	elif event.keycode == KEY_UP or event.keycode == KEY_W:
		var gameplay_count: int = game._gameplay_preference_count()
		game.settings_selected = (game.settings_selected - 1 + gameplay_count) % gameplay_count
	elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
		game.settings_selected = (game.settings_selected + 1) % game._gameplay_preference_count()
	elif event.keycode in [KEY_ENTER, KEY_SPACE]:
		match game._gameplay_selected_key():
			"analog": game.analog_fixed = not game.analog_fixed
			"target_priority": game._cycle_target_priority()
			"desktop_aim": game._cycle_desktop_aim_mode()
			"desktop_teleport": game._cycle_desktop_teleport_mode()
			"desktop_attack_aim": game._cycle_desktop_attack_aim_mode()
			"desktop_hud_scale": game._cycle_desktop_hud_scale()
			"color_vision": game.ColorVisionFilterScript.cycle(game)
			"fps": game.show_fps_counter = not game.show_fps_counter
			"tutorial": game._set_run_tutorial_enabled(not game.run_tutorial_enabled, false)
			"haptics": game.haptics_enabled = not game.haptics_enabled
			"ui_platform_profile": game._cycle_ui_platform_override()
			"qa_stream_quality": game._cycle_qa_stream_quality_mode()
			"back":
				game._save_config()
				game.mode = "settings"
		game._save_config()
	elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
		match game._gameplay_selected_key():
			"target_priority": game._cycle_target_priority(-1)
			"damage_text": game._adjust_damage_text_scale(-1)
			"interface_text": game.interface_text_scale = max(0.5, game.interface_text_scale - 0.25)
			"color_vision": game.ColorVisionFilterScript.cycle(game, -1)
			"desktop_aim": game._cycle_desktop_aim_mode(-1)
			"desktop_teleport": game._cycle_desktop_teleport_mode(-1)
			"desktop_attack_aim": game._cycle_desktop_attack_aim_mode(-1)
			"desktop_hud_scale": game._cycle_desktop_hud_scale(-1)
			"tutorial": game._set_run_tutorial_enabled(false, false)
			"ui_platform_profile": game._cycle_ui_platform_override(-1)
			"qa_stream_quality": game._cycle_qa_stream_quality_mode(-1)
		game._save_config()
	elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
		match game._gameplay_selected_key():
			"target_priority": game._cycle_target_priority(1)
			"damage_text": game._adjust_damage_text_scale(1)
			"interface_text": game.interface_text_scale = min(2.0, game.interface_text_scale + 0.25)
			"color_vision": game.ColorVisionFilterScript.cycle(game, 1)
			"desktop_aim": game._cycle_desktop_aim_mode(1)
			"desktop_teleport": game._cycle_desktop_teleport_mode(1)
			"desktop_attack_aim": game._cycle_desktop_attack_aim_mode(1)
			"desktop_hud_scale": game._cycle_desktop_hud_scale(1)
			"tutorial": game._set_run_tutorial_enabled(true, false)
			"ui_platform_profile": game._cycle_ui_platform_override(1)
			"qa_stream_quality": game._cycle_qa_stream_quality_mode(1)
		game._save_config()


static func _settings_audio_key(game: Node, event: InputEventKey) -> void :
	if event.keycode == KEY_ESCAPE:
		game._save_config()
		game.mode = "settings"
	elif event.keycode == KEY_UP or event.keycode == KEY_W:
		game.settings_selected = (game.settings_selected - 1 + 5) % 5
	elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
		game.settings_selected = (game.settings_selected + 1) % 5
	elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
		match game.settings_selected:
			0: game._set_audio_volume_index(0, game.vol_master - 0.1)
			1: game._set_audio_volume_index(1, game.vol_music - 0.1)
			2: game._set_audio_volume_index(2, game.vol_sfx - 0.1)
			3: game._set_audio_volume_index(3, game.vol_shots - 0.1)
		game._save_config()
	elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
		match game.settings_selected:
			0: game._set_audio_volume_index(0, game.vol_master + 0.1)
			1: game._set_audio_volume_index(1, game.vol_music + 0.1)
			2: game._set_audio_volume_index(2, game.vol_sfx + 0.1)
			3: game._set_audio_volume_index(3, game.vol_shots + 0.1)
		game._save_config()
	elif event.keycode in [KEY_ENTER, KEY_SPACE]:
		if game.settings_selected == 4:
			game._save_config()
			game.mode = "settings"


static func _settings_graphics_key(game: Node, event: InputEventKey) -> void :
	var graphics_keys: Array = game._graphics_setting_keys()
	var graphics_count: int = graphics_keys.size()
	if event.keycode == KEY_ESCAPE:
		game._save_config()
		game.mode = "settings"
	elif event.keycode == KEY_UP or event.keycode == KEY_W:
		game.settings_selected = (game.settings_selected - 1 + graphics_count) % graphics_count
	elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
		game.settings_selected = (game.settings_selected + 1) % graphics_count
	elif event.keycode in [KEY_ENTER, KEY_SPACE]:
		game.settings_selected = clampi(game.settings_selected, 0, graphics_count - 1)
		game._activate_graphics_setting(String(graphics_keys[game.settings_selected]))
	elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
		var selected_graphics_key: String = String(graphics_keys[clampi(game.settings_selected, 0, graphics_count - 1)])
		if selected_graphics_key == "range_color":
			game.RangedAttackRange.cycle_indicator_color(game, -1)
			game._save_config()
		elif selected_graphics_key == "range_opacity":
			game.auto_attack_range_opacity = game.RangedAttackRange.sanitize_indicator_opacity(game.auto_attack_range_opacity - 0.1)
			game._save_config()
		elif selected_graphics_key == "window_mode":
			game._cycle_desktop_window_mode(-1)
			game._apply_graphics_settings()
			game._save_config()
		elif selected_graphics_key == "fps_limit":
			game._cycle_graphics_fps_limit(-1)
			game._apply_graphics_settings()
			game._save_config()
	elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
		var selected_graphics_key: String = String(graphics_keys[clampi(game.settings_selected, 0, graphics_count - 1)])
		if selected_graphics_key == "range_color":
			game.RangedAttackRange.cycle_indicator_color(game, 1)
			game._save_config()
		elif selected_graphics_key == "range_opacity":
			game.auto_attack_range_opacity = game.RangedAttackRange.sanitize_indicator_opacity(game.auto_attack_range_opacity + 0.1)
			game._save_config()
		elif selected_graphics_key == "window_mode":
			game._cycle_desktop_window_mode(1)
			game._apply_graphics_settings()
			game._save_config()
		elif selected_graphics_key == "fps_limit":
			game._cycle_graphics_fps_limit(1)
			game._apply_graphics_settings()
			game._save_config()


static func _settings_data_key(game: Node, event: InputEventKey) -> void :
	if event.keycode == KEY_ESCAPE:
		game.mode = "settings"
		game._update_webhook_input_visibility()
	elif event.keycode == KEY_UP or event.keycode == KEY_W:
		game.settings_selected = (game.settings_selected - 1 + 3) % 3
	elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
		game.settings_selected = (game.settings_selected + 1) % 3
	elif event.keycode in [KEY_ENTER, KEY_SPACE]:
		if game.webhook_edit != null and game.webhook_edit.has_focus():
			game._save_webhook_from_input()
		else:
			match game.settings_selected:
				0: game._save_webhook_from_input()
				1: game._clear_webhook_input()
				2:
					game.mode = "settings"
					game._update_webhook_input_visibility()
