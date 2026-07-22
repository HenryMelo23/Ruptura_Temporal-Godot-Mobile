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

	game.ui_platform_override = game.UI_PLATFORM_AUTO
	_check(game._effective_ui_platform() in [game.UI_PLATFORM_ANDROID, game.UI_PLATFORM_DESKTOP], "auto platform did not resolve")

	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	_check(game._uses_desktop_ui(), "desktop override did not enable desktop UI")
	game.mode = "game"
	game.manifestation_key = "eletrica"
	game._update_button_layout(viewport)
	_check(game.buttons.has("attack") and game.buttons["attack"].size.x <= 60.0, "desktop attack button is not compact")
	_check(game.buttons.has("pause") and game.buttons["pause"].size.x <= 50.0, "desktop pause button is not compact")

	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	_check(game._uses_touch_ui(), "android override did not enable touch UI")
	game._update_button_layout(viewport)
	_check(game.buttons.has("attack") and game.buttons["attack"].size.x > 100.0, "android touch attack button stayed desktop-sized")

	game.gameplay_cheat_text = "Henry_meelo"
	_check(game._try_unlock_retornante_cheat(), "Henry_meelo cheat was not accepted")
	_check(game.ui_platform_override_unlocked, "Henry_meelo did not unlock UI platform selector")
	_check(game._sanitize_ui_platform_override(game.ui_platform_override) in [game.UI_PLATFORM_ANDROID, game.UI_PLATFORM_DESKTOP], "Henry_meelo did not choose a concrete profile")

	var actions: Array = game._keyboard_action_order()
	_check(actions.has("attack") and actions.has("skill") and actions.has("secondary") and actions.has("dash"), "keyboard actions missing combat basics")
	game._load_keyboard_bindings(PackedStringArray(["32", "81", "69", "70"]))
	_check(game._event_matches_keyboard_action(_key_event(KEY_SPACE), "attack"), "legacy keyboard binding load did not preserve attack")
	_check(game._compact_key_binding_name("skill") != "--", "keyboard HUD label is empty")
	game.keyboard_mapping_action = "skill"
	game.mode = "settings_keys"
	var mouse_extra := InputEventMouseButton.new()
	mouse_extra.button_index = MOUSE_BUTTON_XBUTTON1
	mouse_extra.pressed = true
	game._capture_keyboard_binding(mouse_extra)
	_check(game._compact_key_binding_name("skill") == "X1", "mouse extra binding was not captured")

	game.desktop_window_mode = game.DESKTOP_WINDOW_FULLSCREEN
	game._cycle_desktop_window_mode()
	_check(game.desktop_window_mode == game.DESKTOP_WINDOW_WINDOWED, "desktop window mode did not cycle to windowed")
	game._cycle_desktop_window_mode()
	_check(game.desktop_window_mode == game.DESKTOP_WINDOW_BORDERLESS, "desktop window mode did not cycle to borderless")

	game.mode = "settings_keys"
	var rects: Dictionary = game._keyboard_settings_rects(viewport)
	_check(rects.has("attack") and rects.has("reset") and rects.has("back"), "keyboard settings rects are incomplete")

	game.mode = "game"
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game.keyboard_bindings["dash"] = game._key_input_binding(KEY_F)
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	right_click.position = Vector2(640, 360)
	_check(not game._handle_desktop_combat_mouse(right_click, viewport), "right mouse button triggered dash without being bound")
	game.keyboard_bindings["pause"] = game._mouse_input_binding(MOUSE_BUTTON_RIGHT)
	_check(game._handle_desktop_combat_mouse(right_click, viewport), "bound right mouse button did not trigger desktop action")
	game.mode = "game"
	game.keyboard_bindings["pause"] = game._key_input_binding(KEY_ESCAPE)

	game.is_multiplayer = true
	game.mode = "game"
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game.keyboard_bindings["attack"] = game._mouse_input_binding(MOUSE_BUTTON_LEFT)
	game.last_attack_time = -999.0
	game.shop_mp_request_timer = 8.0
	game.shop_mp_request_incoming = true
	game.shop_mp_request_outgoing = false
	var shop_bullets_before: int = game.bullets.size()
	var shop_click := InputEventMouseButton.new()
	shop_click.button_index = MOUSE_BUTTON_LEFT
	shop_click.pressed = true
	shop_click.position = game._shop_mp_accept_rect(viewport).get_center()
	game._unhandled_input(shop_click)
	_check(not game.shop_mp_request_incoming and game.shop_mp_request_outgoing, "desktop shop accept click did not accept request")
	_check(game.bullets.size() == shop_bullets_before, "desktop shop accept click leaked into attack")

	game.boss_mp_request_timer = 8.0
	game.boss_mp_request_incoming = true
	game.boss_mp_request_outgoing = false
	_check(game._handle_desktop_request_overlay_press(game._boss_mp_accept_rect(viewport).get_center(), viewport), "desktop boss request click was not consumed")

	game._start_pause_mp_request(true, true, 1, 2)
	_check(game._handle_desktop_request_overlay_press(game._pause_mp_accept_rect(viewport).get_center(), viewport), "desktop pause request click was not consumed")
	game._start_pause_mp_request(true, true, 1, 2)
	_check(game._handle_multiplayer_request_key(_key_event(KEY_ENTER)), "desktop enter did not accept multiplayer request")
	game._clear_pause_mp_request()
	game._clear_shop_mp_request()
	game._clear_boss_mp_request()
	game.is_multiplayer = false
	game.keyboard_bindings["attack"] = game._key_input_binding(KEY_SPACE)

	game.mode = "game"
	game.manifestation_key = "eletrica"
	game.desktop_aim_mode = game.DESKTOP_AIM_QUICK
	game.time_alive = 120.0
	game.last_secondary_time = -999.0
	game.manifestation_secondaries.clear()
	game.desktop_action_gate_msec.clear()
	game.keyboard_bindings["secondary"] = game._key_input_binding(KEY_E)
	var e_key := _key_event(KEY_E)
	_check(game._handle_desktop_combat_key(e_key), "desktop E did not trigger secondary")
	_check(not game._active_eletrica_secondary().is_empty(), "desktop E did not keep electric ultimate active")
	_check(game._handle_desktop_combat_key(e_key), "desktop E duplicate was not consumed")
	_check(not game._active_eletrica_secondary().is_empty(), "desktop E duplicate canceled electric ultimate")

	print("DESKTOP_HYBRID_UI_SMOKE_OK platform=true cheat=true compact_hud=true keys=true window=true")
	game.manifestation_secondaries.clear()
	game.eletrica_waves.clear()
	game.eletrica_chains.clear()
	game._exit_tree()
	await process_frame
	quit(0)


func _key_event(keycode: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event
