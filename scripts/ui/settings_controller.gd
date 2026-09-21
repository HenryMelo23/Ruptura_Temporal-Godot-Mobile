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
	var actions = game._keyboard_action_order()
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
	if game.settings_buttons["analog"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game.analog_fixed = not game.analog_fixed
		game._save_config()
	elif game.settings_buttons["shop_mode"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game._set_shop_auto_enabled( not game.shop_auto_enabled)
		game._save_config()
	elif game.settings_buttons["shop_interval"].has_point(pos):
		game._close_gameplay_cheat_popup()
		if not game.shop_auto_enabled:
			return
		var interval_panel: Rect2 = game.settings_buttons["shop_interval"]
		if game._shop_interval_minus_rect(interval_panel).has_point(pos):
			game.shop_auto_interval = max(180.0, game.shop_auto_interval - 60.0)
		elif game._shop_interval_plus_rect(interval_panel).has_point(pos):
			game.shop_auto_interval = min(480.0, game.shop_auto_interval + 60.0)
		else:
			return
		game.shop_auto_elapsed = 0.0
		game.next_forced_shop_time = game.shop_auto_interval
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
			game.damage_text_scale = max(0.7, game.damage_text_scale - 0.1)
			game._save_config()
		elif game._damage_text_plus_rect(damage_panel).has_point(pos):
			game.damage_text_scale = min(1.8, game.damage_text_scale + 0.1)
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
	elif game.settings_buttons["fps"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game.show_fps_counter = not game.show_fps_counter
		game._save_config()
	elif game.settings_buttons["tutorial"].has_point(pos):
		game._close_gameplay_cheat_popup()
		game._set_run_tutorial_enabled(not game.run_tutorial_enabled)
	elif game.settings_buttons["retornante_cheat"].has_point(pos):
		if not game.retornante_unlocked or not game.qa_data_unlocked:
			game._open_gameplay_cheat_popup()
	elif game.settings_buttons["haptics"].has_point(pos):
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
			game._activate_graphics_setting(option)
			return
