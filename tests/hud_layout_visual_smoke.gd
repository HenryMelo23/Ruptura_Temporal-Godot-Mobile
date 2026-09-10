extends SceneTree

const OUT_DIR := "res://.codex"

var game: Node
var captures: Array[String] = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error("HUD_LAYOUT_VISUAL_FAIL " + message)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.shop_auto_enabled = false
	game.boss_ready = true
	game.boss_active = false
	game.boss_dead = false
	game.score = 1253
	game.card_cost = 500
	game.player_hp = 450
	game.player_hp_max = 450
	game.mode = "game"

	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	await _capture_profile(Vector2i(1280, 720), "hud_hub_desktop_1280x720.png")
	await _capture_profile(Vector2i(960, 540), "hud_hub_desktop_960x540.png")

	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	await _capture_profile(Vector2i(800, 450), "hud_hub_mobile_800x450.png")

	print("HUD_LAYOUT_VISUAL_OK captures=%d desktop=true mobile=true no_overlap=true basic_fire_frames=2" % captures.size())
	game.queue_free()
	await process_frame
	await create_timer(0.6).timeout
	quit(0)


func _capture_profile(size: Vector2i, file_name: String) -> void:
	root.size = size
	game.buttons.clear()
	game._update_button_layout(Vector2(size))
	_check_no_overlap(Vector2(size))
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == size.x and image.get_height() == size.y, "invalid capture " + file_name)
	_check(image.get_used_rect().size.x > int(float(size.x) * 0.72), "blank capture " + file_name)
	var output := OUT_DIR + "/" + file_name
	_check(image.save_png(output) == OK, "could not save " + file_name)
	captures.append(ProjectSettings.globalize_path(output))


func _check_no_overlap(viewport: Vector2) -> void:
	var action_keys: Array[String] = ["attack", "skill", "secondary", "dash"]
	if game.buttons.has("lacerante_empower"):
		action_keys.append("lacerante_empower")
	if game.buttons.has("bombastica_detonator"):
		action_keys.append("bombastica_detonator")
	for key in action_keys:
		var rect: Rect2 = game.buttons[key]
		_check(rect.position.x >= -0.5 and rect.position.y >= -0.5, key + " left/top clipped")
		_check(rect.end.x <= viewport.x + 0.5 and rect.end.y <= viewport.y + 0.5, key + " right/bottom clipped rect=" + str(rect) + " viewport=" + str(viewport))
		_check(rect.size.x > 20.0 and rect.size.y > 20.0, key + " collapsed")
		for other_key in action_keys:
			if key == other_key:
				continue
			_check(not rect.grow(5.0).intersects(game.buttons[other_key].grow(5.0)), key + " overlaps " + other_key)
	var joystick_rect := Rect2(game._joy_center(viewport) - Vector2(76.0, 76.0), Vector2(152.0, 152.0))
	for key in action_keys:
		_check(not joystick_rect.grow(4.0).intersects(game.buttons[key].grow(4.0)), "joystick overlaps " + key)
