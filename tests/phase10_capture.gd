extends SceneTree

## Capturas da Dimensao 10 (arte provisoria). Uso (precisa de janela, nao headless):
##   godot --path . --script res://tests/phase10_capture.gd -- [prefixo] [--low]
const OUT := "res://.codex/phase10/"
var game: Node
var prefix := "s10"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and not String(args[0]).begins_with("--"):
		prefix = String(args[0])
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	if "--low" in args:
		prefix += "_low"
	call_deferred("_run")


func _wait(seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		game.player_hp = game.player_hp_max
		await process_frame


func _shot(name: String) -> void:
	game.queue_redraw()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + prefix + "_" + name + ".png")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(1280, 720)
	game.startup_thanks_done = true
	game.qa_data_unlocked = true
	await process_frame
	game._start_game()
	game._story().queue.clear()
	game._advance_to_phase(10)
	game._story().queue.clear()
	game.mode = "game"
	if "--low" in OS.get_cmdline_user_args():
		game.gfx_low_resource = true
	game.player_hp_max = 99999
	game.player_hp = 99999
	var c: RTBaileController = game.baile_controller
	var b: RTBoss10Controller = game.boss10_controller
	await _wait(0.6)
	# --- palco: Dona Boleta cantando antes da invocacao
	game.enemies.clear()
	game.player_pos = c.mic_pos() + Vector2(-60, 200)
	await _wait(0.6)
	await _shot("01_palco")
	# --- pista: os quatro especiais, garrafa e anel
	var p: Vector2 = c.fight_anchor() + Vector2(700, 300)
	game.player_pos = p
	game.phase_started_at = game.time_alive - 160.0
	game._spawn_enemy(c.MONARCA, p + Vector2(-260, -60))
	game._spawn_enemy(c.MONARCA, p + Vector2(240, 120))
	game._spawn_enemy(c.GARRAFEIRA, p + Vector2(330, -160))
	game._spawn_enemy(c.SOMBRINHA, p + Vector2(230, -120))
	game._spawn_enemy(c.PAREDINHA, p + Vector2(-320, 160))
	game._spawn_enemy(c.HYPE, p + Vector2(380, 40))
	c.throw_bottle(p + Vector2(330, -160), RTUmbraHitbox.feet(p) + Vector2(40, 10), "whisky")
	c.rings.append({"pos": p + Vector2(-320, 160), "t": 0.4, "life": 0.92, "hit": {}})
	c.puddles.append({"pos": p + Vector2(-90, 90), "r": 70.0, "life": 5.0, "t": 0.0})
	await _wait(0.45)
	await _shot("02_pista")
	# --- Teor alto: visao dupla e ilusoes
	c.teor_by_peer[game._mp_unique_id()] = 82.0
	c.teor_idle_by_peer[game._mp_unique_id()] = 0.0
	await _wait(0.4)
	await _shot("03_teor")
	c.teor_by_peer.clear()
	# --- Lagartona: aviso do Trenzinho
	game.enemies.clear()
	c.bottles.clear()
	c.rings.clear()
	c.puddles.clear()
	game._spawn_enemy(c.LAGARTONA, p + Vector2(380, 0))
	await _wait(2.4)
	var lag: Dictionary = c.miniboss()
	if not lag.is_empty():
		c.lagartona._build_trem_path(Vector2(lag["pos"]), p)
		c.lagartona._go(lag, "trem_warn")
	await _wait(0.3)
	await _shot("04_lagartona")
	game.enemies.clear()
	c.lagartona.clear()
	# --- chefe: descida, holofote e roda
	game.boss_ready = true
	game.experimental_boss_altar_authorized = true
	game.experimental_boss_altar_used = true
	game.boss_call_timer = -1.0
	game._start_boss_call_local()
	game.boss_call_timer = 0.0
	game._update_boss_call(0.016)
	game.player_pos = c.fight_anchor() + Vector2(0, 320)
	await _wait(1.0)
	await _shot("05_descida")
	await _wait(1.6)
	b._start_holofote()
	await _wait(1.5)
	await _shot("06_holofote")
	b._start_roda()
	await _wait(3.4)
	await _shot("07_roda")
	var frames := 0
	var end_t := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < end_t:
		game.player_hp = game.player_hp_max
		await process_frame
		frames += 1
	print("PHASE10_CROWD_COST instances=%d frames_2s=%d fps=%d" % [RTBaileCrowdPresentation.instance_count, frames, Engine.get_frames_per_second()])
	await _shot("07b_roda_cheia")
	game.boss_hp = game.boss_hp_max * 0.45
	b.mode = "walk"
	await _wait(0.4)
	await _shot("08_remix")
	print("PHASE10_CAPTURE_OK " + ProjectSettings.globalize_path(OUT))
	game.queue_free()
	await process_frame
	quit(0)
