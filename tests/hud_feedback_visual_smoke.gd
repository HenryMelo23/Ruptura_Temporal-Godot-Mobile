extends SceneTree

const OUTPUT := "res://.agent_logs/hud_after"
var game: Node
var failed: bool = false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("HUD_FEEDBACK_FAIL " + message)


func _advance(seconds: float) -> void:
	for i in range(ceili(seconds * 60.0)):
		game.hud_feedback.update(game, 1.0 / 60.0)


func _capture(name: String) -> void:
	game.queue_redraw()
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size() == root.size, "wrong viewport " + name)
	_check(image.save_png(OUTPUT + "/" + name + ".png") == OK, "capture " + name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i.ZERO
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game._start_game(false)
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_hp_max = 400
	game.player_hp = 400
	game.time_alive = 20.0
	game.gfx_health_warning_start = 0.55
	game.gfx_health_warning_strength = 1.0
	game.hud_feedback.reset(game)
	_check(game.hud_feedback.severity(game) == 0.0, "healthy warning")
	game.player_hp = 200
	_check(game.hud_feedback.severity(game) > 0.0, "warning starts too late")
	game.player_hp = 96
	var quarter_danger: float = game.hud_feedback.severity(game)
	game.player_hp = 32
	_check(game.hud_feedback.severity(game) > quarter_danger, "critical state not stronger")
	for viewport in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = viewport
		game.ui_platform_override_unlocked = true
		game.ui_platform_override = "desktop" if viewport.x == 1280 else "android"
		for hp in [400, 200, 96, 32]:
			game.player_hp = hp
			game.hud_feedback.reset(game)
			_advance(1.0)
			await _capture("%d_hp_%d" % [viewport.x, hp])
		var beat_before: float = game.hud_feedback.pulse()
		_advance(0.15)
		_check(not is_equal_approx(beat_before, game.hud_feedback.pulse()), "pulse is static")
		await _capture("%d_critical_pulse" % viewport.x)
		game.player_hp = 400
		game.hud_feedback.reset(game)
		game.last_damage_time = -100.0
		game._damage_player(140, "hud_smoke")
		_check(game.player_hp < 400, "actual damage path did not run")
		_advance(0.03)
		_check(game.hud_feedback.trail > game.hud_feedback.fill, "missing delayed damage trail")
		_check(game.hud_feedback.damage > 0.0, "missing damage response")
		await _capture("%d_damage" % viewport.x)
		game.damage_flash_timer = 0.0
		_advance(0.7)
		game._heal_player(100.0, "hud_smoke")
		_advance(0.05)
		_check(game.hud_feedback.healing > 0.0, "missing healing response")
		_check(game.hud_feedback.fill < float(game.player_hp) / 400.0, "healing fill snaps")
		await _capture("%d_heal" % viewport.x)
		_advance(1.5)
		_check(absf(game.hud_feedback.fill - float(game.player_hp) / 400.0) < 0.001, "health fill never settles")
		_check(game.hud_feedback.danger < 0.01, "danger does not recede after healing")
		await _capture("%d_recovered" % viewport.x)
		game.mode = "settings_graphics"
		await _capture("%d_settings" % viewport.x)
		var rects: Dictionary = game._graphics_settings_rects(Vector2(viewport))
		for key in rects:
			_check(Rect2(Vector2.ZERO, Vector2(viewport)).encloses(rects[key]), "setting outside viewport " + key)
			_check(Rect2(rects[key]).size.y >= 44, "small settings target")
		game.mode = "game"
	# Maximum-health upgrades and run resets should not masquerade as healing.
	game.player_hp_max = 600
	game.player_hp = 450
	_advance(0.02)
	_check(game.hud_feedback.healing == 0.0 and game.hud_feedback.damage == 0.0, "max HP change triggers false hit/heal")
	_check(is_equal_approx(game.hud_feedback.fill, 0.75), "max HP normalization")
	game.is_dead = true
	_advance(0.02)
	_check(game.hud_feedback.danger == 0.0 and game._low_health_red_alpha() == 0.0, "dead player retains warning")
	game.is_dead = false
	game.gfx_health_warning_start = 0.55
	for i in range(3):
		game._activate_graphics_setting("health_warning_start")
	_check(is_equal_approx(game.gfx_health_warning_start, 0.55), "warning threshold cycle")
	for i in range(4):
		game._activate_graphics_setting("health_warning_strength")
	_check(is_equal_approx(game.gfx_health_warning_strength, 1.0), "warning strength cycle")
	game.gfx_health_warning_start = 0.7
	game.gfx_health_warning_strength = 1.35
	game._save_config()
	game.gfx_health_warning_start = 0.35
	game.gfx_health_warning_strength = 0.0
	game._load_config()
	_check(is_equal_approx(game.gfx_health_warning_start, 0.7) and is_equal_approx(game.gfx_health_warning_strength, 1.35), "warning preferences not persisted")
	game.player_hp = 20
	game.gfx_health_warning_strength = 0.0
	_check(game._low_health_red_alpha() == 0.0, "off setting ignored")
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	if not failed:
		print("HUD_FEEDBACK_VISUAL_OK damage=true healing=true critical=true pulse=true recovery=true settings=true persistence=true desktop=true mobile=true")
	quit(1 if failed else 0)
