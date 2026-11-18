extends SceneTree

## Capturas da Dimensao 9. Uso: ... --script res://tests/phase9_capture.gd -- [prefixo]
const OUT := "res://.codex/phase9/"
var game: Node
var prefix := "s9"


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
	root.get_texture().get_image().save_png(OUT + prefix + "_" + name + ".png")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(1280, 720)
	game.startup_thanks_done = true
	game.qa_data_unlocked = true  # sem avisos de tutorial por cima das capturas
	await process_frame
	game._start_game()
	game._story().queue.clear()
	game._advance_to_phase(9)
	game._story().queue.clear()
	game.mode = "game"
	game.player_hp_max = 99999
	game.player_hp = 99999
	var c: RTCriptaController = game.cripta_controller
	await _wait(0.8)
	# --- cone + pilastra + lamparina
	var pl: Vector2 = c.pillars[0]["pos"]
	game.player_pos = pl + Vector2(-240, 40)
	game.last_facing = Vector2.RIGHT
	c.facing = Vector2.RIGHT
	game.enemies.clear()
	game.phase_started_at = game.time_alive - 120.0
	var p: Vector2 = game.player_pos
	game._spawn_enemy(c.LOBO, p + Vector2(380, -120))
	game._spawn_enemy(c.LOBO, p + Vector2(-330, 60))
	game._spawn_enemy(c.SALTADORA, p + Vector2(300, 160))
	game._spawn_enemy(c.VIUVA, p + Vector2(-250, -200))
	c.echoes.append({"pos": p + Vector2(260, 60), "t": 0.0, "uid": 77})
	await _wait(0.5)
	await _shot("01_cone")
	# --- luz
	var lamp: Dictionary = c.lamps[1]
	c._light(lamp, 20.0)
	game.player_pos = Vector2(lamp["pos"])
	await _wait(0.6)
	await _shot("02_lamparina")
	# --- susto
	c.scare_cd = 0.0
	c.trigger_scare(c.VIUVA, game.player_pos + Vector2(80, 0))
	await _wait(0.12)
	await _shot("03_susto")
	# --- noiva
	game.enemies.clear()
	game.player_pos = Vector2(1600, 1100)
	game._spawn_enemy(c.NOIVA, game.player_pos + Vector2(280, -40))
	var noiva: Dictionary = c.miniboss()
	noiva["cr_state"] = "fios"
	noiva["cr_t"] = 0.0
	await _wait(1.6)
	await _shot("04_noiva_fios")
	noiva["hp"] = 0.0
	c.on_enemy_defeated(noiva)
	game.enemies.clear()
	# --- chefe
	game.boss_ready = true
	game.experimental_boss_altar_authorized = true
	game.experimental_boss_altar_used = true
	game._start_boss_call_local()
	game.boss_call_timer = 0.0
	await _wait(0.3)
	game.player_pos = game.boss_pos + Vector2(0, 330)
	await _wait(2.5)
	await _shot("05_matriarca")
	var b9: RTBoss9Controller = game.boss9_controller
	b9._set_mode("olhar", "gaze")
	await _wait(0.9)
	await _shot("06_olhar")
	game.boss_hp = game.boss_hp_max * 0.55
	b9._set_mode("walk", "walk")
	await _wait(2.4)
	await _shot("07_apagao")
	game.boss_hp = game.boss_hp_max * 0.2
	b9.blackout = 0.0
	b9._set_mode("walk", "walk")
	await _wait(1.0)
	await _shot("08_mil_olhos")
	# --- espreita: aviso de onde ela vem
	for e in b9.watchers():
		e["hp"] = -1.0
	game.boss_hp = game.boss_hp_max * 0.5
	b9.blackout = 0.0
	b9.daze = 0.0
	b9.blind = 0.0
	b9.height = 0.0
	game.player_pos = Vector2(1500, 1100)
	game.boss_pos = game.player_pos + Vector2(-60, -330)
	c.facing = Vector2.DOWN
	game.last_facing = Vector2.DOWN
	b9._set_mode("rede", "cast")
	b9.attack_cd = 99.0
	await _wait(0.6)  # camera chega no jogador
	game.boss_pos = game.player_pos + Vector2(-60, -330)
	b9.ambush_peer = game._mp_unique_id()
	b9._set_mode("ambush_warn", "crouch")
	b9.t = 0.2
	await _shot("09_espreita_aviso")
	b9._set_mode("walk", "walk")
	game.boss_pos = Vector2(400, 400)
	# --- ecos: visao maior
	c.lose_sight()
	c.sight_k = 0.0
	c.facing = Vector2.RIGHT
	game.last_facing = Vector2.RIGHT
	for l in c.lamps:
		l["on"] = false
		l["gap"] = 99.0
	await _wait(0.5)
	await _shot("10_visao_normal")
	for k in range(4):
		c.apply_local_event("echo", 0.0, game.player_pos)
	await _wait(1.0)
	await _shot("11_visao_4_ecos")
	# --- controle: bola girando, laco, casulo + veneno
	var g: RTCriptaGrapple = c.grapple
	game.enemies.clear()
	c.webs.clear()
	game.player_pos = Vector2(1500, 1100)
	c.facing = Vector2.RIGHT
	game.last_facing = Vector2.RIGHT
	game._spawn_enemy(RTCriptaGrapple.BOLEADEIRA, game.player_pos + Vector2(260, -40))
	var bol: Dictionary = game.enemies.back()
	bol["pos"] = game.player_pos + Vector2(260, -40)
	c._state(bol, "spin")
	await _wait(0.35)
	await _shot("13_boleadeira_girando")
	c._state(bol, "drag")
	bol["gp"] = int(game._mp_unique_id())
	g.apply_event("grab", float(bol["uid"]), Vector2(bol["pos"]))
	await _wait(0.9)
	g.grab["progress"] = 0.45
	await _shot("14_lacada_arrastada")
	g.reset()
	game.enemies.clear()
	game._spawn_enemy(RTCriptaGrapple.ARMADEIRA, game.player_pos + Vector2(60, 0))
	var arma: Dictionary = game.enemies.back()
	arma["pos"] = game.player_pos + Vector2(60, 0)
	c._state(arma, "guard")
	arma["gp"] = int(game._mp_unique_id())
	g.apply_event("cocoon", float(arma["uid"]), Vector2(arma["pos"]))
	g.add_poison(2)
	await _wait(0.7)
	g.grab["progress"] = 0.3
	await _shot("15_casulo_veneno")
	g.reset()
	game.enemies.clear()
	# --- oficina do Mercador durante a fase 9
	game.boss_active = false
	game.boss_dead = true
	game.enemies.clear()
	var entered: bool = game._merchant_dimension().enter()
	await _wait(1.2)
	await _shot("12_mercador" if entered else "12_mercador_nao_entrou")
	print("PHASE9_CAPTURE_OK")
	game.queue_free()
	await process_frame
	quit(0)
