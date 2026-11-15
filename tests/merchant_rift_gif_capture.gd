extends SceneTree

## Captura uma visita completa a Fenda do Mercador (mergulho, queda na oficina,
## saida, volta) a 15 quadros/s, para montar GIF de revisao.
## Uso (com tela): godot --path . --script res://tests/merchant_rift_gif_capture.gd -- scared|resigned|stylish|ejected
## Saida: res://.codex/rift_gif/<humor>_<n>.png

var game: Node
var shots := 0
var mood := "scared"
var mood_suffix := ""


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	for a in OS.get_cmdline_user_args():
		if a in ["scared", "resigned", "stylish", "ejected"]:
			mood = a
	if "nofx" in OS.get_cmdline_user_args():
		for n in ["tear", "floor_hole", "dust", "shock", "flash", "ring", "speed", "stars", "sweat", "sigh", "tunnel"]:
			MerchantRiftTransitionPresentation._frame_cache["fx:" + n] = []
		mood_suffix = "_nofx"
	call_deferred("_run")


func _shot() -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var dir_path := ProjectSettings.globalize_path("res://.codex/rift_gif")
	DirAccess.make_dir_recursive_absolute(dir_path)
	root.get_texture().get_image().save_png(dir_path + "/%s%s_%03d.png" % [mood, mood_suffix, shots])
	shots += 1


func _play(max_seconds: float, until_idle: bool = true) -> void:
	var dt := 1.0 / 30.0
	var elapsed := 0.0
	var n := 0
	while elapsed < max_seconds:
		if until_idle and not game._rift_transition().busy():
			return
		game._update_game(dt)
		elapsed += dt
		n += 1
		if n % 2 == 0:
			await _shot()


func _run() -> void:
	await process_frame
	game.run_tutorial_enabled = false
	game.active_character_key = game.CHARACTER_GEOVANA
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game._finish_startup_thanks()
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.mode = "game"
	game.is_multiplayer = false
	game.boss_active = false
	game.spawn_timer = 99999.0
	game.shop_rift_controller.allow_rift = true
	game.shop_auto_enabled = true
	game._merchant_npc().seen.clear()
	var tr: RTMerchantRiftTransition = game._rift_transition()
	var dim: RTMerchantDimension = game._merchant_dimension()
	tr.reset_run()
	tr.entries = {"scared": 0, "resigned": 1, "stylish": 4, "ejected": 1}[mood]
	game.player_pos = Vector2(1400.0, 1000.0)
	game.enemies.clear()
	for i in range(8):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(float(i) * TAU / 8.0) * (110.0 + float(i) * 20.0))
	for i in range(4):
		await _play(0.1, false)
	var rc = game.shop_rift_controller
	rc.clear_active()
	game.shop_rift_next_allowed_time = 0.0
	var pos: Vector2 = game.player_pos + Vector2(30.0, 0.0)
	rc.spawn("test", pos)
	game.shop_rift["state"] = rc.STATE_OPEN
	game.player_pos = pos
	rc.update(0.016)
	await _play(2.0, false)
	await _play(2.5)
	await _play(0.6, false)
	if mood == "ejected":
		dim.leave(true)
	else:
		game.player_pos = RTMerchantDimension.EXIT_PORTAL_POS
		dim.entry_age = 5.0
		dim._reach_exit()
		await _play(1.3, false)
	await _play(2.0)
	await _play(0.4, false)
	print("RIFT_GIF_OK mood=%s shots=%d" % [mood, shots])
	quit(0)
