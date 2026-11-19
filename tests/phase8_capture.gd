extends SceneTree

## Capturas da Dimensao 8. Uso: ... --script res://tests/phase8_capture.gd -- [prefixo]
const OUT := "res://.codex/phase8/"
var game: Node
var prefix := "s8"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		prefix = String(args[0])
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _wait(seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		game.player_hp = game.player_hp_max
		await process_frame


func _shot(name: String) -> void:
	game.queue_redraw()
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(OUT + prefix + "_" + name + ".png")


func _boss_attack(name: String, hp_pct: float) -> void:
	var b8: RTBoss8Controller = game.boss8_controller
	game.sertao_controller.bullets.clear()
	game.boss_hp = game.boss_hp_max * hp_pct
	b8.stage = 1 if hp_pct > 0.65 else (2 if hp_pct > 0.3 else 3)
	b8.eclipse_done = hp_pct <= 0.3 and name != "eclipse"
	b8.interlude_done = true
	if name == "eclipse":
		b8.eclipse_done = true
		b8._start_eclipse()
		return
	b8.bag = [name]
	b8.bag_stage = b8.stage
	b8._set_mode("walk", "walk")
	b8.attack_cd = 0.0


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(1280, 720)
	game.startup_thanks_done = true
	await process_frame
	game._start_game()
	game._story().queue.clear()
	game._advance_to_phase(8)
	game._story().queue.clear()
	game.mode = "game"
	game.player_hp_max = 99999
	game.player_hp = 99999
	await _wait(0.6)
	var s8: RTSertaoController = game.sertao_controller
	# --- inimigos
	game.enemies.clear()
	game.phase_started_at = game.time_alive - 60.0
	var p: Vector2 = game.player_pos
	game._spawn_enemy(RTSertaoController.MANDACARU, p + Vector2(280, -60))
	game._spawn_enemy(RTSertaoController.MORTEIRO, p + Vector2(-460, 120))
	game._spawn_enemy(RTSertaoController.PIAO, p + Vector2(-200, -230))
	for i in range(4):
		game._spawn_enemy(RTSertaoController.JABUTI, p + Vector2(-300 + i * 160, 250))
	for e in game.enemies:
		e["s8_cd"] = 0.0
	await _wait(2.6)
	await _shot("01_inimigos")
	# --- mini chefe
	game.enemies.clear()
	s8.bullets.clear()
	game._spawn_enemy(RTSertaoController.CANGACEIRO, game.player_pos + Vector2(260, -40))
	var canga: Dictionary = s8.miniboss()
	canga["s8_state"] = "walk"
	canga["s8_cd"] = 0.0
	canga["s8_bag"] = ["xaxado"]
	await _wait(1.7)
	await _shot("02_cangaceiro_xaxado")
	s8.bullets.clear()
	canga["hp"] = float(canga["max_hp"]) * 0.4
	canga["s8_state"] = "walk"
	canga["s8_cd"] = 0.0
	canga["s8_bag"] = ["tocaia"]
	canga["s8_bag_low"] = true
	await _wait(1.25)
	await _shot("03_cangaceiro_tocaia")
	canga["hp"] = 0.0
	s8.on_enemy_defeated(canga)
	game.enemies.clear()
	s8.bullets.clear()
	# --- chefe
	game.boss_ready = true
	game.experimental_boss_altar_authorized = true
	game.experimental_boss_altar_used = true
	game._start_boss_call_local()
	game.boss_call_timer = 0.0
	await _wait(0.3)
	game.player_pos = game.boss_pos + Vector2(0, 330)
	await _wait(1.0)
	await _shot("04_chefe_entrada")
	await _wait(2.0)
	_boss_attack("ponteiro", 0.5)
	await _wait(1.8)
	await _shot("05_ponteiro")
	_boss_attack("badaladas", 0.8)
	await _wait(1.6)
	await _shot("06_badaladas")
	_boss_attack("ampulheta", 0.8)
	await _wait(2.0)
	await _shot("07_ampulheta")
	_boss_attack("gnomon", 0.5)
	await _wait(2.6)
	await _shot("08_gnomon")
	_boss_attack("rolagem", 0.5)
	await _wait(0.85)
	await _shot("09_rolagem")
	_boss_attack("eclipse", 0.28)
	await _wait(4.3)
	await _shot("10_eclipse_parado")
	print("PHASE8_CAPTURE_OK")
	quit(0)
