extends SceneTree

## Smoke da Dimensao 9 (Cripta de Seda): rota, visao em cone, pilastras,
## lamparinas, ecos/mimicas, cada aranha, Noiva de Seda e a Matriarca.

var game: Node
var failed: bool = false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE9_CRIPTA_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


var dark := false


func _step(seconds: float, with_boss: bool = false, pin: Vector2 = Vector2.INF) -> void:
	var dt := 1.0 / 30.0
	for i in range(int(seconds / dt)):
		if dark:
			for l in game.cripta_controller.lamps:
				l["on"] = false
		game.time_alive += dt
		game._update_enemies(dt)
		game.cripta_controller.update(dt)
		if with_boss:
			game._update_boss(dt)
		if pin != Vector2.INF:
			game.player_pos = pin


func _face(c: RTCriptaController, dir: Vector2) -> void:
	c.facing = dir.normalized()
	game.last_facing = dir.normalized()


func _run() -> void:
	await process_frame
	var c: RTCriptaController = game.cripta_controller
	var b9: RTBoss9Controller = game.boss9_controller
	game._start_game()
	game.mode = "game"

	# ---------------- rota: Cripta so existe no ciclo de farm (7 + 3 de 1/2/3/8/9)
	var flow = game._phase_flow()
	_check(not (9 in game.DIMENSION_ROUTE_POOL), "cripta nao pode estar na rota inicial")
	var hits := 0
	for i in range(300):
		game.dimension_route_last_phase = 4
		game._begin_farm_dimension_cycle()
		if 9 in game.dimension_route_queue:
			hits += 1
	_check(hits > 120 and hits < 240, "cripta deveria sair em ~60%% dos ciclos: %d/300" % hits)
	_check(flow._sanitize_farm_route([9, 9, 1]).is_empty(), "rota com repeticao deveria ser recusada")
	_check(flow._sanitize_farm_route([4, 6, 1]).is_empty(), "rota fora do sorteio deveria ser recusada")

	# ---------------- entrar
	game._advance_to_phase(9)
	game._story().queue.clear()
	game.mode = "game"
	_check(game.current_phase == 9, "nao entrou na fase 9")
	_check(flow.phase_region_name(9) == "CRIPTA DE SEDA", "nome da regiao")
	_check(game.experimental_phase_controller.map_key() == "map_phase_ex9", "mapa da fase 9")
	_check(game._current_map_texture() != null, "textura do mapa")
	_check(game.boss_name == "MATRIARCA DOS OITO OLHOS", "nome do chefe")
	_check(c.pillars.size() >= 12, "pilastras: %d" % c.pillars.size())
	_check(c.lamps.size() >= 6, "lamparinas: %d" % c.lamps.size())
	var lit := 0
	for l in c.lamps:
		if bool(l["on"]):
			lit += 1
	_check(lit >= 1, "nenhuma lamparina acesa no inicio")
	for key in ["s9_lobo_0", "s9_viuva_0", "s9_viuva_freeze", "s9_alcapao_lid", "s9_saltadora_3", "s9_mimica_2", "s9_noiva_15", "s9_filhote_1", "s9_olho_1", "s9_pillar_1", "s9_lamp_on", "s9_echo_3", "boss9_walk_0", "boss9_death_3", "s9_scare_matriarca"]:
		_check(RTCriptaPresentation.tex(key) != null, "textura faltando: " + key)

	# ---------------- cone de visao + pilastra
	game.enemies.clear()
	# Cena controlada: uma pilastra so, longe das bordas (o mapa e sorteado).
	c.pillars = [{"pos": Vector2(1700, 1100), "r": 40.0}]
	var center: Vector2 = c.pillars[0]["pos"] + Vector2(-260, 0)
	game.player_pos = center
	_face(c, Vector2.RIGHT)
	dark = true
	for l in c.lamps:
		l["on"] = false
	_check(c.in_cone(center + Vector2(400, 0)), "frente deveria estar no cone")
	_check(not c.in_cone(center + Vector2(-400, 0)), "costas fora do cone")
	_check(c.in_cone(center + Vector2(-80, 0)), "halo curto em volta")
	_check(c.occluded(c.eye(), Vector2(c.pillars[0]["pos"]) + Vector2(200, -10)), "pilastra deveria tampar a visao")
	# lobo atras: nao e alvo do tiro automatico e faz ondulacao
	game._spawn_enemy(c.LOBO, center + Vector2(-380, 0))
	var lobo: Dictionary = game.enemies.back()
	c.ripples.clear()
	_step(0.6, false, center)
	_face(c, Vector2.RIGHT)
	_check(bool(lobo.get("untargetable", false)), "lobo nas costas deveria ser invisivel ao alvo")
	_check(not c.ripples.is_empty(), "lobo fora da vista nao fez ondulacao")
	_check(game._targeting().find_target() == null if game.has_method("_targeting") else true, "alvo automatico pegou inimigo invisivel")

	c._build_layout()  # volta o mapa sorteado (os fios da Noiva precisam das pilastras)
	# ---------------- luz: regenera, aranhas evitam, chefe toma mais dano
	game.enemies.clear()
	dark = false
	var lamp: Dictionary = c.lamps[0]
	c._light(lamp, 30.0)
	game.player_pos = Vector2(lamp["pos"])
	_check(c.player_in_light(), "jogador deveria estar na luz")
	game.player_hp = int(game.player_hp_max * 0.5)
	var hp0: int = game.player_hp
	_step(3.0, false, Vector2(lamp["pos"]))
	_check(game.player_hp > hp0, "luz nao regenerou")
	var steer: Vector2 = c._avoid_light(Vector2(lamp["pos"]) + Vector2(c.LAMP_RADIUS + 60, 0), Vector2.LEFT, 40.0)
	_check(steer.dot(Vector2.LEFT) < 0.5, "aranha entrou direto na luz")

	# ---------------- ecos de luar (recompensa fora da luz)
	c.echoes.clear()
	game.player_pos = Vector2(1200, 900)
	c.echoes.append({"pos": game.player_pos + Vector2(0, 30), "t": 0.0, "uid": 999})
	var score0: int = int(game.score)
	c._update_echoes(0.016)
	_check(c.echoes.is_empty() and int(game.score) > score0, "eco nao foi coletado / sem pontos")

	# ---------------- ecos aumentam a visao (acumula e reinicia o tempo)
	c.lose_sight()
	c.sight_k = 0.0
	var r0: float = c.cone_range()
	for k in range(3):
		c.apply_local_event("echo", 0.0, game.player_pos)
	_check(c.sight_stacks == 3 and is_equal_approx(c.sight_timer, RTCriptaController.SIGHT_TIME), "3 ecos deveriam dar 3 cargas")
	for i in range(30):
		c._update_sight(1.0 / 30.0)
	_check(c.cone_range() > r0 * 1.25 and c.aura() > RTCriptaController.AURA, "visao nao cresceu: %.0f -> %.0f" % [r0, c.cone_range()])
	for i in range(150):
		c._update_sight(1.0 / 30.0)
	c.apply_local_event("echo", 0.0, game.player_pos)
	_check(c.sight_stacks == 4 and is_equal_approx(c.sight_timer, RTCriptaController.SIGHT_TIME), "eco novo deveria somar e reiniciar o tempo")
	for i in range(int(30 * (RTCriptaController.SIGHT_TIME + 0.2))):
		c._update_sight(1.0 / 30.0)
	_check(c.sight_stacks == 0, "bonus deveria acabar sem eco novo")
	c.apply_local_event("echo", 0.0, game.player_pos)
	c.apply_local_event("dim", 0.0, game.player_pos)
	_check(c.sight_stacks == 0, "mordida da mimica deveria apagar o bonus")
	c.sight_k = 0.0

	# ---------------- cada aranha faz a coisa dela
	dark = true
	for l in c.lamps:
		l["on"] = false
	game.player_hp_max = 999999
	game.player_hp = 999999
	game.phase_started_at = game.time_alive - 120.0
	var home := Vector2(1600, 1100)
	for p in c.pillars:
		if Vector2(p["pos"]).distance_to(home) < 260.0:
			home += Vector2(300, 0)
	game.player_pos = home
	_face(c, Vector2.RIGHT)
	# viuva: congela vista, ataca pelas costas
	game.enemies.clear()
	game._spawn_enemy(c.VIUVA, home + Vector2(300, 0))
	var viuva: Dictionary = game.enemies.back()
	_step(1.0, false, home)
	_face(c, Vector2.RIGHT)
	_check(String(viuva.get("cr_anim", "")) == "freeze", "viuva deveria congelar quando vista: " + String(viuva.get("cr_anim", "")))
	_check(c.contact_blocked(viuva), "viuva nao machuca por contato")
	var vp0: Vector2 = viuva["pos"]
	_step(0.5, false, home)
	_check(Vector2(viuva["pos"]).distance_to(vp0) < 6.0, "viuva andou sendo vista")
	_face(c, Vector2.LEFT)
	game.last_facing = Vector2.LEFT
	var hp_v: int = game.player_hp
	for i in range(120):
		_step(1.0 / 30.0, false, home)
		c.facing = Vector2.LEFT
	_check(Vector2(viuva["pos"]).distance_to(home) < Vector2(vp0).distance_to(home) - 50.0, "viuva nao avancou pelas costas")
	_check(game.player_hp < hp_v, "viuva nao mordeu pelas costas")
	# alcapao: enterrada, sai quando chega perto
	game.enemies.clear()
	_face(c, Vector2.RIGHT)
	game._spawn_enemy(c.ALCAPAO, home + Vector2(600, 0))
	var alc: Dictionary = game.enemies.back()
	alc["pos"] = home + Vector2(400, 0)
	_check(String(alc["cr_state"]) == "buried" and c.contact_blocked(alc), "alcapao deveria nascer enterrada")
	_step(0.5, false, home)
	_check(String(alc["cr_state"]) == "buried", "alcapao saiu longe demais")
	_step(0.8, false, Vector2(alc["pos"]) + Vector2(-60, 0))
	_check(String(alc["cr_state"]) != "buried", "alcapao nao emergiu perto")
	# saltadora: agacha e salta
	game.enemies.clear()
	game._spawn_enemy(c.SALTADORA, home + Vector2(340, 0))
	var sal: Dictionary = game.enemies.back()
	sal["cr_cd"] = 0.0
	var states := {}
	for i in range(180):
		_step(1.0 / 30.0, false, home)
		states[String(sal.get("cr_state", ""))] = true
	_check(states.has("crouch") and states.has("air"), "saltadora nao saltou: %s" % str(states.keys()))
	# mimica: disfarcada de eco, revela perto
	game.enemies.clear()
	game._spawn_enemy(c.MIMICA, home + Vector2(400, 0))
	var mim: Dictionary = game.enemies.back()
	_check(String(mim["cr_state"]) == "disguise" and bool(mim["untargetable"]), "mimica sem disfarce")
	var tex_dis: Texture2D = RTCriptaPresentation.enemy_texture(game, mim)
	_check(tex_dis != null and tex_dis.resource_path.find("s9_echo") >= 0, "disfarce deveria parecer eco")
	_step(0.5, false, Vector2(mim["pos"]) + Vector2(-70, 0))
	_check(String(mim["cr_state"]) != "disguise", "mimica nao se revelou")
	_check(not c.scare.is_empty() or c.scare_cd > 0.0, "mimica nao deu susto")

	# ---------------- pontos: a Cripta paga mais
	var keep_phase: int = game.current_phase
	game.current_phase = 1
	var p1: int = game._points_for_enemy({"points": 100})
	game.current_phase = keep_phase
	var p9: int = game._points_for_enemy({"points": 100})
	_check(float(p9) >= float(p1) * (RTCriptaController.POINT_MULT - 0.05), "pontos da cripta nao aumentaram: %d vs %d" % [p9, p1])

	# ---------------- controle: laco da Boleadeira (arrasta) e fuga apertando o disparo
	var g: RTCriptaGrapple = c.grapple
	g.reset()
	game.enemies.clear()
	c.webs.clear()
	c.pillars = []
	_face(c, Vector2.RIGHT)
	game._spawn_enemy(RTCriptaGrapple.BOLEADEIRA, home + Vector2(330, 0))
	var bol: Dictionary = game.enemies.back()
	bol["cr_cd"] = 0.0
	var states_b := {}
	for i in range(30 * 4):
		_step(1.0 / 30.0, false, home if not g.held() else Vector2.INF)
		states_b[String(bol.get("cr_state", ""))] = true
		if g.held():
			break
	_check(states_b.has("spin") and g.held() and String(g.grab["kind"]) == "drag", "boleadeira nao lacou: %s" % str(states_b.keys()))
	if g.held():
		var p_before: Vector2 = game.player_pos
		_step(1.2)
		_check(game.player_pos.distance_to(p_before) > 25.0, "laco nao arrastou a Geovana")
		var hp_before_drag: float = game.player_hp
		game._try_attack()
		game._try_attack()  # mesmo quadro: segurar nao conta
		_check(is_equal_approx(float(g.grab["progress"]), 1.0 / float(RTCriptaGrapple.DRAG_PRESSES)), "segurar o botao contou como varios toques")
		for k in range(RTCriptaGrapple.DRAG_PRESSES):
			await process_frame
			await process_frame
			game._try_attack()
		_check(not g.held(), "apertar o disparo nao soltou do laco")
		_check(String(bol.get("cr_state", "")) == "recover" and int(bol.get("gp", 0)) == 0, "boleadeira deveria ficar tonta depois da fuga")
		_check(not g.can_hold(int(game._mp_unique_id())), "deveria ter imunidade logo depois de se soltar")

	# ---------------- controle: casulo da Armadeira + veneno
	g.reset()
	game.enemies.clear()
	game.player_hp = game.player_hp_max
	game._spawn_enemy(RTCriptaGrapple.ARMADEIRA, home + Vector2(110, 0))
	var arma: Dictionary = game.enemies.back()
	var states_a := {}
	var got_cocoon := false
	for i in range(30 * 20):
		arma["cr_cd"] = minf(float(arma.get("cr_cd", 0.0)), 0.3)
		arma["cr_casulo_cd"] = 0.0
		_step(1.0 / 30.0, false, home)
		states_a[String(arma.get("cr_state", ""))] = true
		if g.held() and String(g.grab["kind"]) == "cocoon":
			got_cocoon = true
			break
	_check(got_cocoon, "armadeira nao enrolou no casulo: %s" % str(states_a.keys()))
	if got_cocoon:
		_step(1.6, false, home)
		_check(g.poison_stacks > 0, "guarda do casulo deveria envenenar")
		for k in range(RTCriptaGrapple.COCOON_PRESSES):
			await process_frame
			await process_frame
			game._try_attack()
		_check(not g.held(), "apertar o disparo nao rompeu o casulo")
	g.reset()
	game.run_retry_invulnerability_timer = 0.0
	g.add_poison(3)
	_check(g.vision_mult() < 0.8 and c.cone_range() < RTCriptaController.CONE_RANGE, "veneno deveria encolher a visao")
	var hp_p: float = game.player_hp
	_step(2.0, false, home)
	_check(game.player_hp < hp_p, "veneno nao tirou vida")
	var t_dark: float = g.poison_t
	c._light(c.lamps[0], 30.0)
	game.player_pos = Vector2(c.lamps[0]["pos"])
	g.update_local(0.5)
	_check(t_dark - g.poison_t > 1.2, "a luz deveria purgar o veneno mais rapido")
	g.reset()
	for l in c.lamps:
		l["on"] = false
	c._build_layout()

	# ---------------- populacao
	game.phase_started_at = game.time_alive
	for i in range(20):
		_check(game._choose_enemy_type() == c.LOBO, "comeco so lobos")
	game.phase_started_at = game.time_alive - 300.0
	game.enemies.clear()
	var kinds := {}
	for i in range(400):
		kinds[game._choose_enemy_type()] = true
	for k in [c.LOBO, c.VIUVA, c.ALCAPAO, c.SALTADORA]:
		_check(kinds.has(k), "tipo nunca sorteado: " + k)
	_check(not kinds.has(c.NOIVA), "noiva nao pode sair no sorteio")

	# ---------------- Noiva de Seda
	game.enemies.clear()
	c.miniboss_spawned = false
	game.boss_active = false
	game.phase_started_at = game.time_alive - (c.NOIVA_SPAWN_TIME + 1.0)
	c.update(0.016)
	_check(c.miniboss_alive(), "noiva nao apareceu aos 150s")
	var noiva: Dictionary = c.miniboss()
	_check(not game._boss_call_can_start(false), "chamada do chefe deveria travar com a noiva viva")
	noiva["pos"] = home + Vector2(300, 0)
	noiva["hp"] = float(noiva["max_hp"]) * 0.4
	var seen_att := {}
	var saw_threads := false
	for i in range(30 * 40):
		_step(1.0 / 30.0, false, home)
		seen_att[String(noiva.get("cr_state", ""))] = true
		if not c.threads.is_empty():
			saw_threads = true
		game.player_hp = game.player_hp_max
	for st in ["fios", "veu", "cantiga", "bolsa"]:
		_check(seen_att.has(st), "noiva nunca usou: " + st)
	_check(saw_threads, "fios nao apareceram")
	if not c.threads.is_empty():
		var th: Dictionary = c.threads[0]
		var mid: Vector2 = Vector2(th["a"]).lerp(Vector2(th["b"]), 0.5)
		for k in range(3):
			c.bullet_hit(mid)
		_check(int(th["hp"]) <= 0, "3 tiros deveriam romper o fio")
	var cores0: int = int(game.get("spectral_cores")) if game.get("spectral_cores") != null else 0
	noiva["hp"] = 0.0
	c.on_enemy_defeated(noiva)
	game.enemies.clear()
	_check(not c.miniboss_alive() and c.miniboss_defeated, "noiva viva")

	# ---------------- Matriarca
	dark = false
	game.boss_ready = true
	game.experimental_boss_altar_authorized = true
	game.experimental_boss_altar_used = true
	game.boss_call_timer = -1.0
	game.boss_active = false
	game.boss_dead = false
	game._start_boss_call_local()
	game.boss_call_timer = 0.0
	game._update_boss_call(0.016)
	_check(game.boss_active, "chefe nao ficou ativo")
	_check(game._boss_texture() != null, "textura do chefe")
	var pin: Vector2 = Vector2(game.boss_pos) + Vector2(0, 320)
	game.player_pos = pin
	_step(2.0, true, pin)
	_check(b9.mode != "entry", "chefe nao saiu da entrada")
	var modes := {}
	var saw_blackout := false
	var saw_eyes := false
	var saw_eggs := false
	for i in range(30 * 70):
		_step(1.0 / 30.0, true, pin)
		modes[b9.mode] = true
		game.player_hp = game.player_hp_max
		if b9.blackout > 0.0:
			saw_blackout = true
		if not b9.watchers().is_empty():
			saw_eyes = true
		if not b9.eggs.is_empty():
			saw_eggs = true
		if i == 25 * 30:
			game.boss_hp = game.boss_hp_max * 0.55
		if i == 45 * 30:
			game.boss_hp = game.boss_hp_max * 0.2
		if i == 60 * 30:
			for e in b9.watchers():
				e["hp"] = -1.0
	for m in ["olhar", "rede", "ovos", "ceiling", "mil_olhos"]:
		_check(modes.has(m), "chefe nunca usou: " + m)
	_check(modes.has("pounce") or modes.has("pounce_warn"), "chefe nunca saltou")
	_check(saw_blackout and b9.blackout_done, "apagao nao aconteceu")
	_check(saw_eyes and b9.thousand_done, "mil olhos nao aconteceu")
	_check(saw_eggs, "ovos nao cairam")
	# ---------------- espreita: some do cone, rodeia, aviso e bote
	dark = true
	for e in b9.watchers():
		e["hp"] = -1.0
	game.enemies.clear()
	var hide_pin: Vector2 = Vector2(1500, 1100)
	c.pillars = []
	b9.blackout = 0.0
	b9.daze = 0.0
	b9.blind = 0.0
	b9.height = 0.0
	b9._set_mode("walk", "walk")
	b9.ambush_cd = 0.0
	b9.attack_cd = 99.0
	game.boss_pos = hide_pin + Vector2(0, -420)
	var amb_modes := {}
	var warn_behind := false
	for i in range(30 * 6):
		game.last_facing = Vector2.DOWN
		c.facing = Vector2.DOWN
		_step(1.0 / 30.0, true, hide_pin)
		game.player_hp = game.player_hp_max
		amb_modes[b9.mode] = true
		if b9.mode == "ambush_warn":
			warn_behind = b9.ambush_dir_from(hide_pin).dot(Vector2.DOWN) < -0.3
		if b9.mode == "pounce":
			break
	_check(amb_modes.has("espreita") and amb_modes.has("ambush_warn") and amb_modes.has("pounce"), "espreita incompleta: %s" % str(amb_modes.keys()))
	_check(warn_behind, "o aviso deveria vir de tras do jogador")
	# visto no caminho: desiste
	b9._set_mode("walk", "walk")
	b9.daze = 0.0
	b9.blind = 0.0
	b9.height = 0.0
	b9.ambush_cd = 0.0
	game.boss_pos = hide_pin + Vector2(0, -420)
	c.facing = Vector2.DOWN
	game.last_facing = Vector2.DOWN
	_step(1.0 / 30.0, true, hide_pin)
	_check(b9.mode == "espreita", "deveria comecar a espreita")
	var gave_up := false
	for i in range(30 * 2):
		c.facing = (Vector2(game.boss_pos) - hide_pin).normalized()
		game.last_facing = c.facing
		_step(1.0 / 30.0, true, hide_pin)
		if b9.mode == "walk" or b9.mode == "olhar" or b9.mode == "rede" or b9.mode == "ovos":
			gave_up = true
			break
	_check(gave_up, "vista no caminho, deveria desistir da espreita (modo %s)" % b9.mode)

	# mais dano na luz
	var lamp2: Dictionary = c.lamps[0]
	c._light(lamp2, 20.0)
	game.boss_pos = Vector2(lamp2["pos"])
	b9.height = 0.0
	b9.blackout = 0.0
	b9.mode = "walk"
	b9.daze = 0.0
	b9.blind = 0.0
	_check(b9.damage_taken_multiplier() > 1.0, "matriarca deveria tomar mais dano na luz")
	game._damage_boss(game.boss_hp_max * 10.0, "teste")
	_check(game.boss_dead, "chefe nao morreu")
	_step(2.0, false)

	# ---------------- Mercador conta a historia da Cripta (uma vez)
	var npc = game._merchant_npc()
	npc.persist = false
	npc.seen = {"intro": true, "stolen": true}
	npc.mission_offered = true
	game._dialogue().clear()
	npc.greet(null)
	_check(game._dialogue().busy() and npc.seen.has("cripta"), "mercador nao contou a historia da cripta")
	game._dialogue().clear()
	npc.greet(null)
	_check(not game._dialogue().busy() and npc.bubble != "", "historia da cripta repetiu (deveria ser so uma fala curta)")

	if not failed:
		print("PHASE9_CRIPTA_SMOKE_OK modes=%s" % str(modes.keys()))
	game.queue_free()
	await process_frame
	await process_frame
	await process_frame
	quit(1 if failed else 0)
