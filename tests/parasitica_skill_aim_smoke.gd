extends SceneTree

## Simbiose Predatoria e aplicada sobre Geovana: nenhum caminho de input arma
## mira/reticulo. Toque rapido, toque arrastado, evento real, teclado e controle
## ativam a Simbiose direto.

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
	game.desktop_action_gate_msec.clear()
	game._parasitica().clear_all()


func _run() -> void:
	var viewport := Vector2(1280, 720)
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.startup_thanks_done = true
	game.manifestation_key = "parasitica"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 100.0
	game.player_pos = Vector2(640.0, 360.0)
	game.enemies.clear()
	game.boss_active = false
	game.arauto.clear()
	var ctl: RTParasiticaController = game._parasitica()

	_check(game._ground_target_profile(false).is_empty(), "HAB1 still has a ground-target profile")

	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	game._update_button_layout(viewport)
	_reset_skill()
	var skill_center: Vector2 = game.buttons["skill"].get_center()
	game._handle_touch_press(21, skill_center, viewport)
	game._handle_touch_release(21, skill_center, viewport)
	_check(ctl.sym_active, "mobile tap did not start the Symbiosis")
	_check(game.parasite_spit_zones.is_empty(), "mobile tap still spawned the old spit")

	_reset_skill()
	var actual_viewport: Vector2 = game.get_viewport_rect().size
	game._update_button_layout(actual_viewport)
	var event_center: Vector2 = game.buttons["skill"].get_center()
	var press := InputEventScreenTouch.new()
	press.index = 23
	press.position = event_center
	press.pressed = true
	game._unhandled_input(press)
	var release := InputEventScreenTouch.new()
	release.index = 23
	release.position = event_center
	release.pressed = false
	game._unhandled_input(release)
	_check(ctl.sym_active, "mobile event path did not start the Symbiosis")

	game._update_button_layout(viewport)
	skill_center = game.buttons["skill"].get_center()
	_reset_skill()
	game._handle_touch_press(22, skill_center, viewport)
	game._handle_touch_drag(22, skill_center + Vector2(-118.0, -70.0), viewport)
	game._handle_touch_release(22, skill_center + Vector2(-118.0, -70.0), viewport)
	_check(ctl.sym_active, "mobile drag did not start the Symbiosis (no reticle expected)")

	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game._update_button_layout(viewport)
	game.keyboard_bindings["skill"] = game._key_input_binding(KEY_Q)
	_reset_skill()
	_check(game._handle_desktop_combat_key(_key_event(KEY_Q, true)), "desktop Q was not consumed")
	_check(game.desktop_aim_action == "", "desktop Q still armed cursor aim")
	_check(ctl.sym_active, "desktop Q did not start the Symbiosis on press")

	print("PARASITICA_SKILL_AIM_OK self_cast=true mobile_tap=true mobile_drag=true mobile_event=true desktop_press=true")
	game._cleanup_runtime_resources()
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
