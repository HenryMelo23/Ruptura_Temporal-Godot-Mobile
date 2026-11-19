extends SceneTree
## Capturas do Fragmento Instável / Impulso / Colapso em desktop e mobile
## landscape. Saída em res://.agent_logs/dimension_rupture_*.png
## godot4 --path . --audio-driver Dummy --script tests/dimension_rupture_visual_smoke.gd

const UserFileGuard = preload("res://tests/support/user_file_guard.gd")
const R := preload("res://scripts/systems/phase/dimension_rupture_controller.gd")
const OUTPUT_DIR := "res://.agent_logs"
const SIZES := {"desktop": Vector2i(1280, 720), "mobile": Vector2i(1600, 720)}

var game: Node
var failures: Array[String] = []
var save_guard: UserFileGuard
var config_guard: UserFileGuard
var shots := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	save_guard = UserFileGuard.new("user://interrupted_run.save")
	config_guard = UserFileGuard.new("user://hud_config.save")
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _rupture() -> RTDimensionRuptureController:
	return game._dimension_rupture()


func _capture(label: String) -> void:
	for platform in SIZES.keys():
		var size: Vector2i = SIZES[platform]
		game.ui_platform_override_unlocked = true
		game.ui_platform_override = "desktop" if platform == "desktop" else "android"
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		root.min_size = Vector2i.ZERO
		root.content_scale_size = Vector2i.ZERO
		DisplayServer.window_set_size(size)
		root.size = size
		game.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		_check(image != null and not image.is_empty(), "invalid screenshot " + label)
		if image != null and not image.is_empty():
			var output := ProjectSettings.globalize_path("%s/dimension_rupture_%s_%s.png" % [OUTPUT_DIR, label, platform])
			_check(image.save_png(output) == OK, "could not save " + output)
			shots += 1


func _setup() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.boss_call_tutorial_seen = true
	game.shop_tutorial_seen = true
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.current_phase = 3
	game.time_alive = 600.0
	game.boss_active = false
	game.boss_ready = false
	game.boss_call_timer = -1.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(1200, 900)
	game.speech_bubbles.clear()
	game.unlock_notifications.clear()
	game.enemies.clear()
	game._prepare_phase_texture_assets(3)


func _tick(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		var d := minf(0.5, left)
		_rupture().update(d)
		game.time_alive += d
		left -= d


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_setup()
	game._phase_flow()._spawn_phase_fragment(Vector2(1420, 820), 4)
	_tick(1.0)
	await _capture("01_activation")
	_tick(20.0)
	game.event_alert_timer = 0.0
	await _capture("02_band_perfect")
	_tick(69.0)
	await _capture("03_band_stable")
	_tick(40.0)
	await _capture("04_collapse_start")
	game.player_pos = Vector2(400, 300) # portal longe: seta de direção
	_tick(25.0)
	await _capture("05_collapse_late_far_portal")
	_tick(25.0)
	await _capture("06_emergency")
	# Chegada após travessia perfeita (Impulso II).
	_rupture().state["momentum"] = 1
	_rupture().state["state"] = R.STATE_UNSTABLE
	_rupture().state["elapsed"] = 20.0
	game._phase_flow()._start_phase_transition(4)
	game._phase_flow()._advance_to_phase(int(game.pending_phase))
	game.mode = "game"
	_tick(0.5)
	await _capture("07_arrival_perfect")
	# Chegada após ejeção.
	game._phase_flow()._spawn_phase_fragment(Vector2(1420, 820), 6)
	_tick(200.0)
	game.player_hp = float(game.player_hp_max) * 0.2
	game.mode = "game"
	game._phase_flow()._advance_to_phase(int(game.pending_phase))
	game.mode = "game"
	_tick(0.5)
	_check(float(game.player_hp) >= float(game.player_hp_max) * 0.5, "visual: HP floor not applied")
	_check(_rupture().banner_text == R.MSG_EJECTED, "visual: ejection banner missing")
	await _capture("08_arrival_ejected")
	_rupture().state["disorientation"] = 0.0
	for level in range(1, 5):
		_rupture().state["momentum"] = level
		_rupture().state["token"] = {"event_id": "v%d" % level, "tier": R.BAND_PERFECT, "attempts": 1 + level}
		game.event_alert_timer = 0.0
		await _capture("09_momentum_%s" % R.roman(level))
	_finish()


func _finish() -> void:
	game.mode = "menu"
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	save_guard.restore()
	config_guard.restore()
	if failures.is_empty():
		print("DIMENSION_RUPTURE_VISUAL_SMOKE_OK shots=%d" % shots)
		quit(0)
	else:
		for f in failures:
			printerr("DIMENSION_RUPTURE_VISUAL_SMOKE_FAIL " + f)
		quit(1)
