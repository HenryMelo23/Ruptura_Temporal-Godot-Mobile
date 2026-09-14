extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("DESKTOP_HUD_SCALE_FAIL " + message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	var viewport := Vector2(1280, 720)
	game.startup_thanks_done = true
	game.ui_platform_override = "desktop"
	game.desktop_hud_scale = game.DESKTOP_HUD_SCALE_MIN
	game.mode = "game"
	game.manifestation_key = "eletrica"
	game.shop_auto_enabled = false
	_check(not game._settings_option_keys().has("controls"), "desktop exposed layout move option")
	_check(game._gameplay_preference_keys().has("desktop_hud_scale"), "desktop missing HUD scale option")
	var gameplay: Dictionary = game._gameplay_preferences_rects(viewport)
	_check(gameplay.has("desktop_hud_scale"), "desktop HUD scale rect missing")
	game._handle_gameplay_settings_touch(game._desktop_hud_scale_plus_rect(gameplay["desktop_hud_scale"]).get_center(), viewport)
	_check(is_equal_approx(game.desktop_hud_scale, game.DESKTOP_HUD_SCALE_MIN + game.DESKTOP_HUD_SCALE_STEP), "plus did not increase HUD scale")
	game._handle_gameplay_settings_touch(game._desktop_hud_scale_minus_rect(gameplay["desktop_hud_scale"]).get_center(), viewport)
	_check(is_equal_approx(game.desktop_hud_scale, game.DESKTOP_HUD_SCALE_MIN), "minus did not restore HUD scale")
	game._update_button_layout(viewport)
	var min_attack: Rect2 = game.buttons["attack"]
	_check(is_equal_approx(min_attack.size.x, 92.0 * game.DESKTOP_HUD_SCALE_MIN), "default attack hitbox is not 50 percent")
	game.desktop_hud_scale = game.DESKTOP_HUD_SCALE_MAX
	game._update_button_layout(viewport)
	var max_attack: Rect2 = game.buttons["attack"]
	_check(is_equal_approx(max_attack.size.x, 92.0 * game.DESKTOP_HUD_SCALE_MAX), "max attack hitbox is not 75 percent")
	_check(max_attack.size.x > min_attack.size.x, "larger desktop HUD scale did not enlarge hitbox")
	game.ui_platform_override = "android"
	_check(game._settings_option_keys().has("controls"), "mobile lost layout move option")
	_check(not game._gameplay_preference_keys().has("desktop_hud_scale"), "mobile exposed desktop HUD scale option")
	print("DESKTOP_HUD_SCALE_SMOKE_OK default=50 max=75 desktop_controls_hidden=true mobile_controls=true")
	game.queue_free()
	await process_frame
	await process_frame
	quit(0)
