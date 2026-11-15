extends SceneTree

## Smoke da Dimensao 8 (Sertao das Tartarugas): rota, populacao, inimigos,
## mini chefe, motor de projeteis e chefe Casco-de-Sol.

var game: Node
var failed: bool = false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE8_SERTAO_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _step(seconds: float, with_boss: bool = false) -> void:
	var dt := 1.0 / 30.0
	var n := int(seconds / dt)
	for i in range(n):
		game.time_alive += dt
		game._update_enemies(dt)
		game.sertao_controller.update(dt)
		if with_boss:
			game._update_boss(dt)


func _run() -> void:
	await process_frame
	var s8: RTSertaoController = game.sertao_controller
	var b8: RTBoss8Controller = game.boss8_controller
	game._start_game()
	game.mode = "game"

	# ---------------- rota: so depois de 7 dimensoes, autoridade, 1x por ciclo
	var flow = game._phase_flow()
	game.is_multiplayer = false
	game.dimension_route_completed_count = 5
	game.dimension_route_queue = [2, 3]
	game.dimension_route_farm_cycles = 1
	game.sertao_visited_cycle = -1
	_check(not flow._maybe_queue_sertao(true), "sertao entrou antes de 7 dimensoes")
	game.dimension_route_completed_count = 7
	_check(flow._maybe_queue_sertao(true), "sertao nao entrou com 7 dimensoes")
	_check(int(game.dimension_route_queue[0]) == 8 and game.dimension_route_queue.size() == 3, "sertao deveria entrar na frente da fila como bonus")
	game.dimension_route_queue = [2, 3]
	_check(not flow._maybe_queue_sertao(true), "sertao repetiu no mesmo ciclo")
	game.dimension_route_farm_cycles = 2
	game.is_multiplayer = true
	game.is_host = false
	game.online_room_owner = false
	_check(not flow._maybe_queue_sertao(true), "replica multiplayer alterou a rota")
	game.is_host = true
	_check(flow._maybe_queue_sertao(true), "autoridade multiplayer nao enfileirou o sertao")
	game.is_multiplayer = false
	var hits := 0
	for i in range(400):
		game.sertao_visited_cycle = -1
		game.dimension_route_queue = [2, 3]
		if flow._maybe_queue_sertao(false):
			hits += 1
	_check(hits > 70 and hits < 170, "chance do sertao fora de ~30%%: %d/400" % hits)

	# ---------------- entrar na fase 8
	game._advance_to_phase(8)
	game.mode = "game"
	_check(game.current_phase == 8, "nao entrou na fase 8")
	_check(flow.phase_region_name(8) == "SERTAO DAS TARTARUGAS", "nome da regiao")
	_check(game.experimental_phase_controller.map_key() == "map_phase_ex8", "mapa da fase 8")
	_check(game._current_map_texture() != null, "textura do mapa da fase 8")
	_check(game.boss_name == "CASCO-DE-SOL", "nome do chefe")
	_check(game.enemy_manager.get_desired_enemy_limit(true) >= RTSertaoController.ENEMY_LIMIT_BASE, "limite de inimigos")
	_check(game.enemies.size() >= 1 and String(game.enemies[0]["type"]) == RTSertaoController.JABUTI, "fase deveria comecar com jabutis")
	for key in ["s8_jabuti", "s8_mandacaru", "s8_morteiro", "s8_piao", "s8_cangaceiro", "s8_egg", "boss8_walk", "boss8_cast", "boss8_eclipse"]:
		var tex: Texture2D = RTSertaoPresentation._frame(game, key, 0)
		_check(tex != null, "textura faltando: " + key)

	# ---------------- escolha de inimigos ao longo do tempo
	game.phase_started_at = game.time_alive
	for i in range(20):
		_check(game._choose_enemy_type() == RTSertaoController.JABUTI, "primeiros 40s so jabuti")
	game.phase_started_at = game.time_alive - 300.0
	var seen := {}
	for i in range(400):
		seen[game._choose_enemy_type()] = true
	for kind in [RTSertaoController.JABUTI, RTSertaoController.MANDACARU, RTSertaoController.MORTEIRO, RTSertaoController.PIAO]:
		_check(seen.has(kind), "tipo nunca escolhido: " + kind)
	_check(not seen.has(RTSertaoController.CANGACEIRO), "mini chefe nao pode sair no sorteio")

	# ---------------- inimigos especiais disparam
	game.enemies.clear()
	s8.reset()
	game.player_pos = Vector2(1600, 1100)
	game.player_hp = game.player_hp_max * 50
	game.phase_started_at = game.time_alive - 60.0
	game._spawn_enemy(RTSertaoController.MANDACARU, game.player_pos + Vector2(320, 0))
	game._spawn_enemy(RTSertaoController.MORTEIRO, game.player_pos + Vector2(-500, 0))
	game._spawn_enemy(RTSertaoController.PIAO, game.player_pos + Vector2(0, 330))
	game._spawn_enemy(RTSertaoController.JABUTI, game.player_pos + Vector2(0, -250))
	for e in game.enemies:
		e["s8_cd"] = 0.0
	var saw_eggs := false
	var saw_thorns := false
	var saw_sand := false
	var saw_spin := false
	for i in range(240):
		_step(1.0 / 30.0)
		if not s8.hazards.is_empty():
			saw_eggs = true
		for b in s8.bullets:
			if String(b["src"]) == RTSertaoController.MANDACARU:
				saw_thorns = true
			if String(b["src"]) == RTSertaoController.PIAO:
				saw_sand = true
		for e in game.enemies:
			if String(e["type"]) == RTSertaoController.JABUTI and String(e.get("s8_state", "")) == "spin":
				saw_spin = true
		game.player_pos = Vector2(1600, 1100)
	_check(saw_thorns, "mandacaru nao disparou espinhos")
	_check(saw_eggs, "morteiro nao lancou ovos")
	_check(saw_sand, "piao nao deixou rastro de areia")
	_check(saw_spin, "jabuti nao girou no casco")
	_check(s8.bullets.size() <= RTSertaoController.MAX_BULLETS, "passou do limite de projeteis")

	# ---------------- trava de acerto: varios tiros juntos = 1 dano
	s8.bullets.clear()
	s8.hit_lock = 0.0
	game.player_hp = game.player_hp_max
	var hp_before: int = game.player_hp
	for i in range(8):
		s8.shoot(game.player_pos, Vector2.RIGHT, 0.0, RTSertaoController.COL_SUN, {"dmg": 10})
	s8._update_bullets(1.0 / 60.0)
	_check(hp_before - int(game.player_hp) <= 12, "levou mais de um tiro no mesmo quadro: %d" % (hp_before - int(game.player_hp)))
	_check(s8.bullets.is_empty(), "tiros que acertaram deveriam sumir")
	# raspao
	s8.hit_lock = 0.0
	var graze_before := s8.graze_count
	s8.shoot(game.player_pos + Vector2(30, -200), Vector2.DOWN, 600.0, RTSertaoController.COL_SAND, {})
	for i in range(30):
		s8._update_bullets(1.0 / 60.0)
	_check(s8.graze_count > graze_before, "raspao nao contou")

	# ---------------- tempo de tartaruga: congelar e mirar
	s8.bullets.clear()
	var frozen := s8.shoot(game.player_pos + Vector2(300, 0), Vector2.UP, 0.0, RTSertaoController.COL_GOLD, {"delay": 0.3, "aim": true, "aim_speed": 200.0})
	s8._update_bullets(0.35)
	s8._update_bullets(0.05)
	_check(Vector2(frozen["v"]).dot(Vector2.LEFT) > 0.95, "projetil congelado nao mirou no jogador")

	# ---------------- mini chefe
	game.enemies.clear()
	s8.reset()
	game.boss_ready = true
	game.phase_started_at = game.time_alive - (RTSertaoController.CANGACEIRO_SPAWN_TIME + 1.0)
	s8.update(0.016)
	_check(s8.miniboss_alive(), "cangaceiro nao apareceu aos 150s")
	var canga: Dictionary = s8.miniboss()
	_check(bool(canga.get("is_mini_boss", false)), "cangaceiro sem marca de mini chefe")
	_check(not game._boss_call_can_start(false), "chamada do chefe deveria travar com o cangaceiro vivo")
	canga["pos"] = game.player_pos + Vector2(300, 0)
	var attacks_seen := {}
	canga["hp"] = float(canga["max_hp"]) * 0.4
	for i in range(900):
		_step(1.0 / 30.0)
		attacks_seen[String(canga.get("s8_state", ""))] = true
		game.player_pos = Vector2(1600, 1100)
		game.player_hp = game.player_hp_max
	for st in ["rajada", "xaxado", "casco", "tocaia"]:
		_check(attacks_seen.has(st), "cangaceiro nunca usou: " + st)
	canga["hp"] = 0.0
	s8.on_enemy_defeated(canga)
	game.enemies.clear()
	_check(not s8.miniboss_alive(), "cangaceiro ainda vivo")

	# ---------------- chefe
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
	_check(game.boss_name == "CASCO-DE-SOL", "nome do chefe na chamada")
	_check(game._boss_texture() != null, "textura do chefe")
	_check(b8.mode == "entry", "chefe deveria entrar emergindo")
	game.player_pos = Vector2(game.boss_pos) + Vector2(0, 300)
	var modes := {}
	_step(3.0, true)
	_check(b8.mode != "entry", "chefe nao saiu da entrada")
	for i in range(60 * 30):
		_step(1.0 / 30.0, true)
		modes[b8.mode] = true
		game.player_hp = game.player_hp_max
		game.player_pos = Vector2(game.boss_pos) + Vector2(0, 300)
		if i == 20 * 30:
			game.boss_hp = game.boss_hp_max * 0.6
		if i == 45 * 30:
			game.boss_hp = game.boss_hp_max * 0.25
	for m in ["ponteiro", "badaladas", "ampulheta", "gnomon", "eclipse"]:
		_check(modes.has(m), "chefe nunca usou: " + m)
	_check(modes.has("roll") or modes.has("retract"), "chefe nunca rolou")
	_check(b8.stage == 3 and b8.eclipse_done, "estagio 3 / eclipse")
	_check(s8.bullets.size() <= RTSertaoController.MAX_BULLETS, "limite de projeteis no chefe")
	# sombra do gnomon
	b8.shadow_angle = 0.0
	_check(b8.point_in_shadow(Vector2(game.boss_pos) + Vector2(400, 0)), "ponto na sombra")
	_check(not b8.point_in_shadow(Vector2(game.boss_pos) + Vector2(-400, 0)), "ponto no sol")
	# morte
	game._damage_boss(game.boss_hp_max * 10.0, "teste")
	_check(game.boss_dead, "chefe nao morreu")
	_check(s8.bullets.is_empty(), "projeteis do chefe deveriam sumir na morte")

	if not failed:
		print("PHASE8_SERTAO_SMOKE_OK grazes=%d" % s8.graze_count)
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
