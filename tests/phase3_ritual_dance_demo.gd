extends SceneTree

## Demo visual do Ritual da Catedral: procissao, dança, reverencia dos fieis,
## jogador seguindo a runa no compasso, selo quebrado, oficiante ajoelhado,
## circulo dissolvido e o outro consumado (fervor).
## Args: --mobile  --gif

var game: Node
var ctl
var mobile := false
var gif := false
var frame_i := 0
var prefix := "desk"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--mobile":
			mobile = true
		elif arg == "--gif":
			gif = true
	prefix = "mob" if mobile else "desk"
	root.size = Vector2i(844, 390) if mobile else Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _grab(name: String = "") -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if name != "":
		img.save_png(ProjectSettings.globalize_path("res://.agent_logs/ritual/%s_%s.png" % [prefix, name]))
	if gif:
		img.resize(640, int(640.0 * float(img.get_height()) / float(img.get_width())))
		img.save_png(ProjectSettings.globalize_path("res://.agent_logs/ritual/gif_%s_%03d.png" % [prefix, frame_i]))
		frame_i += 1


func _tick(dt: float) -> void:
	game.time_alive += dt
	for e in game.enemies.duplicate():
		if float(Dictionary(e).get("hp", 0.0)) > 0.0 and bool(Dictionary(e).get("phase3_ritual_marked", false)):
			game._update_phase3_enemy(e, dt)
	ctl.update(dt, true)
	for i in range(game.enemies.size() - 1, -1, -1):
		if float(game.enemies[i].get("hp", 0.0)) <= 0.0:
			game._kill_enemy(game.enemies[i])
	game._update_effects(dt)


func _circle(id: int) -> Dictionary:
	for value in Array(ctl._active.get("circles", [])):
		if int(Dictionary(value).get("id", -1)) == id:
			return value
	return {}


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs/ritual"))
	game.forced_initial_phase = 3
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.startup_thanks_done = true
	game.set_process(false)
	game.ui_platform_override = game.UI_PLATFORM_ANDROID if mobile else game.UI_PLATFORM_DESKTOP
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.boss_active = false
	game.boss_call_timer = -1.0
	game.time_alive = 300.0
	game.player_hp_max = 1000.0
	game.player_hp = 1000.0
	game.player_pos = game.WORLD_SIZE * 0.5
	game.camera_follow_initialized = false
	game.enemies.clear()
	game.effects.clear()
	game._update_button_layout(Vector2(root.size))
	ctl = game.phase3_ritual_pulse_controller
	ctl.reset()
	game._spawn_enemy(game.ENEMY_DEVOTO, game.player_pos + Vector2(-420, -120))
	game._spawn_enemy(game.ENEMY_DEVOTO, game.player_pos + Vector2(430, 140))
	for i in range(5):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(float(i) * 1.25) * 380.0)
	for e in game.enemies:
		e["damage"] = 0.0
	ctl.force_start_for_test()
	# Procissao.
	for k in range(30):
		_tick(1.0 / 20.0)
		await _grab("01_procession" if k == 22 else "")
	# Acelera ate todos dançarem.
	for k in range(80):
		_tick(1.0 / 20.0)
	await _grab("02_dance_worship")
	# Jogador entra no circulo do primeiro oficiante e segue a runa.
	var officiants: Array = game.enemies.filter(func(e): return String(Dictionary(e).get("phase3_ritual_role", "")) == "officiant")
	var target: Dictionary = officiants[0]
	var cid: int = int(target["phase3_ritual_circle_id"])
	var circle: Dictionary = _circle(cid)
	var center: Vector2 = Vector2(circle["pos"])
	var walk_from: Vector2 = game.player_pos
	for k in range(20):
		game.player_pos = walk_from.lerp(center + Vector2(0, 40), float(k + 1) / 20.0)
		game.last_facing = (center - walk_from).normalized()
		_tick(1.0 / 20.0)
		await _grab("")
	var shot_taken := false
	var guard := 0
	while not bool(_circle(cid).get("profaned", false)) and guard < 200:
		guard += 1
		var c: Dictionary = _circle(cid)
		var w: int = int(c.get("safe_wedge", 0))
		var spot: Vector2 = center + Vector2.from_angle((float(w) + 0.5) * TAU / 4.0) * float(c["radius"]) * 0.5
		game.player_pos = game.player_pos.move_toward(spot, 420.0 / 20.0)
		_tick(1.0 / 20.0)
		if not shot_taken and float(c.get("profane", 0.0)) > 0.45:
			shot_taken = true
			await _grab("03_profaning_on_beat")
		else:
			await _grab("")
	for k in range(6):
		_tick(1.0 / 20.0)
		await _grab("04_seal_broken_kneel" if k == 4 else "")
	# Golpes no oficiante vulneravel.
	for k in range(16):
		if float(target.get("hp", 0.0)) > 0.0:
			game._damage_enemy(target, maxf(40.0, float(target.get("max_hp", 200.0)) * 0.22), "eletrica", true, true, game.player_pos, "basic_attack")
		_tick(1.0 / 20.0)
		await _grab("05_dissolved" if k == 12 else "")
	# O outro circulo se consuma: fervor.
	for value in Array(ctl._active.get("circles", [])):
		if int(Dictionary(value).get("id", -1)) != cid and String(Dictionary(value).get("outcome", "")) == "":
			Dictionary(value)["progress"] = 0.985
			game.player_pos = Vector2(Dictionary(value)["pos"]) + Vector2(-260, 60)
	for k in range(30):
		_tick(1.0 / 20.0)
		await _grab("06_consummated_fervor" if k == 10 else "")
	print("RITUAL_DEMO_DONE frames=%d" % frame_i)
	quit(0)
