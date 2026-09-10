extends SceneTree

var game: Node
var failed := false
var baseline := false
var output := "res://.agent_logs/pause_hud_after"


func _initialize() -> void:
	baseline = "--before" in OS.get_cmdline_user_args()
	if baseline:
		output = "res://.agent_logs/pause_hud_before"
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("PAUSE_HUD_FAIL " + message)


func _capture(label: String) -> void:
	game._update_menu_presentation(0.35)
	game.queue_redraw()
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(output + "/" + label + ".png") == OK, label)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i.ZERO
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game._start_game(false)
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 187.0
	game.score = 1253
	game.player_hp_max = 400
	game.player_hp = 96
	game.gfx_health_warning_start = 0.55
	game.gfx_health_warning_strength = 1.0
	game.hud_feedback.reset(game)
	for i in range(60):
		game.hud_feedback.update(game, 1.0 / 60.0)
	for viewport in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(800, 450), Vector2i(640, 360)]:
		root.size = viewport
		game.ui_platform_override_unlocked = true
		game.ui_platform_override = "desktop" if viewport.x == 1280 else "android"
		game.mode = "game"
		await _capture("%d_hud" % viewport.x)
		game._apply_pause_state(true)
		game.pause_selected = 0
		game.pause_keyboard_active = true
		game.menu_page_age = 1.0
		await _capture("%d_pause" % viewport.x)
		var keys := ["pause_resume", "pause_deck", "pause_settings", "pause_menu"]
		for i in range(keys.size()):
			var rect: Rect2 = game.buttons[keys[i]]
			_check(Rect2(Vector2.ZERO, viewport).encloses(rect), "outside viewport " + keys[i])
			_check(rect.size.y >= 44, "small touch target " + keys[i])
			for j in range(i):
				_check(not rect.intersects(game.buttons[keys[j]]), "overlapping actions")
		game._move_pause_selection(1)
		await _capture("%d_focus" % viewport.x)
		game._activate_pause_selection()
		_check(game.mode == "pause_deck", "deck navigation")
		_key(KEY_ESCAPE)
		_check(game.mode == "paused", "Escape from deck")
		game.pause_selected = 2
		game._activate_pause_selection()
		_check(game.mode == "settings" and game.settings_previous_mode == "paused", "settings return context")
		_key(KEY_ESCAPE)
		_check(game.mode == "paused", "Escape from settings")
		_key(KEY_ESCAPE)
		_check(game.mode == "game", "resume previous mode")
		game._apply_pause_state(true)
		game.ui_input_block_until_msec = 0
		game._handle_touch_press(0, game.buttons.pause_deck.get_center(), Vector2(viewport))
		_check(game.mode == "pause_deck", "touch deck action")
		game._return_from_deck()
		game.ui_input_block_until_msec = 0
		game._handle_touch_press(0, game.buttons.pause_resume.get_center(), Vector2(viewport))
		_check(game.mode == "game", "touch resume action")
	if not baseline:
		root.size = Vector2i(1280, 720)
		game.ui_platform_override = "desktop"
		_key(KEY_ESCAPE)
		_check(game.mode == "paused" and game.pause_selected == 0, "Escape opens with Continue selected")
		await _capture("1280_pause_input")
		var frozen_time: float = game.time_alive
		var frozen_pulse: float = game.hud_feedback.clock
		game._process(0.1)
		_check(game.time_alive == frozen_time and game.hud_feedback.clock == frozen_pulse, "pause advances run or heartbeat")
		_key(KEY_UP)
		_check(game.pause_selected == 3, "keyboard wraps upward")
		_key(KEY_DOWN)
		game._update_menu_pointer(game.buttons.pause_settings.get_center(), Vector2(root.size))
		_check(game.pause_selected == 2 and not game.pause_keyboard_active, "pointer takes focus from keyboard")
		_key(KEY_UP)
		_key(KEY_UP)
		_key(KEY_ENTER)
		_check(game.mode == "game", "Enter resumes")
		game._apply_pause_state(true)
		game.is_gamepad_active = true
		game._handle_gamepad_ui_action("attack")
		_check(game.mode == "game", "controller confirm resumes")
		game.is_gamepad_active = false
		game.last_secondary_time = -100.0
		game._use_secondary_skill()
		var active: Dictionary = game._active_eletrica_secondary()
		_check(not active.is_empty(), "activate actual electrical ultimate")
		active["active_time"] = 16.0
		game.last_skill_time = game.time_alive - 1.0
		await _capture("1280_ability_overload")
		_check(game.hud_feedback.ability_status({"active": true, "sub": "SOBRECARGA", "cd_elapsed": 0.0, "cd_max": 20.0}) == "SOBRECARGA", "active warning hidden by cooldown")
		game._use_secondary_skill()
		_check(game._active_eletrica_secondary().is_empty(), "cancel ultimate")
		await _capture("1280_ability_cooldown")
		game._apply_pause_state(true)
		game.pause_selected = 3
		game._activate_pause_selection()
		_check(game.mode == "menu", "return to main menu")
		await _capture("1280_main_menu")
	print("PAUSE_HUD_VISUAL_SMOKE %s" % ("FAIL" if failed else "PASS"))
	game.queue_free()
	await process_frame
	await create_timer(0.6).timeout
	quit(1 if failed else 0)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._handle_key(event)
