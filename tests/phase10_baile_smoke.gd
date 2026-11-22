extends SceneTree

## Smoke da Dimensao 10 (Bailao da Dona Boleta): rota, relogio de batida,
## passinho/drop, os 4 especiais, garrafas/Teor, palco solido, Lagartona,
## invocacao, ataques e Roda da Dona Boleta, Remix e morte. Solo apenas.

var game: Node
var failed: bool = false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PHASE10_BAILE_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _step(seconds: float, with_boss: bool = false, pin: Vector2 = Vector2.INF, heal: bool = true) -> void:
	var dt := 1.0 / 30.0
	for i in range(int(seconds / dt)):
		game.time_alive += dt
		game._update_enemies(dt)
		game.baile_controller.update(dt)
		if with_boss:
			game._update_boss(dt)
		if pin != Vector2.INF:
			game.player_pos = pin
		if heal:
			game.player_hp = game.player_hp_max


func _clear_enemies() -> void:
	game.enemies.clear()


func _last_enemy(kind: String) -> Dictionary:
	for i in range(game.enemies.size() - 1, -1, -1):
		if String(game.enemies[i].get("type", "")) == kind:
			return game.enemies[i]
	return {}


func _run() -> void:
	await process_frame
	var c: RTBaileController = game.baile_controller
	var b10: RTBoss10Controller = game.boss10_controller
	game._start_game()
	game.mode = "game"

	# ---------------- rota: Bailao so existe no ciclo de farm
	var flow = game._phase_flow()
	_check(not (10 in game.DIMENSION_ROUTE_POOL), "bailao nao pode estar na rota inicial")
	_check(10 in game.DIMENSION_FARM_POOL, "bailao fora do pool de farm")
	var hits := 0
	for i in range(300):
		game.dimension_route_last_phase = 4
		game._begin_farm_dimension_cycle()
		if 10 in game.dimension_route_queue:
			hits += 1
	_check(hits > 100 and hits < 210, "bailao deveria sair em ~50%% dos ciclos: %d/300" % hits)

	# ---------------- entrar
	game._advance_to_phase(10)
	game._story().queue.clear()
	game.mode = "game"
	_check(game.current_phase == 10, "nao entrou na fase 10")
	var boss_packet: PackedFloat32Array = game.RTNetContractScript.pack_boss(Vector2(640, 400), 800.0, false, true, 10, 1200.0, 2.0)
	var boss_decoded: Dictionary = game.RTNetContractScript.unpack_boss_snapshot(boss_packet, Vector2.ZERO, 0.0, false, false, 1, 1.0, 0.0, false)
	_check(int(boss_decoded.get("phase_index", 0)) == 10, "identidade da chefe foi truncada no pacote multiplayer")
	for kind in RTBaileController.KINDS:
		var enemy_packet: PackedFloat32Array = game.RTNetContractScript.pack_enemies([{"uid": 101, "type": kind, "pos": Vector2(700, 500), "hp": 20.0}], game.NET_ENEMY_TYPES, game.ENEMY_COMMON, game.NET_LEECH_STATES, game.SANGUESSUGA_STATE_DORMANT)
		var enemies_decoded: Array = game.RTNetContractScript.unpack_enemy_snapshot(enemy_packet, {}, game.NET_ENEMY_TYPES, game.ENEMY_COMMON, game.NET_LEECH_STATES, game.ENEMY_CHRONAL_LEECH, Time.get_ticks_msec())
		_check(enemies_decoded.size() == 1 and String(enemies_decoded[0].get("type", "")) == kind, "inimigo da fase 10 perdeu a identidade na rede: " + kind)
	_check(flow.phase_region_name(10) == "BAILAO DA DONA BOLETA", "nome da regiao")
	_check(game.experimental_phase_controller.map_key() == "map_phase_ex10", "mapa da fase 10")
	_check(game._current_map_texture() != null, "textura do mapa")
	_check(game.boss_name == "DONA BOLETA", "nome do chefe")
	_check(game.WORLD_SIZE == RTExperimentalPhaseController.EXPERIMENTAL_WORLD_SIZE, "mundo expandido")
	_check(game._enemy_type_count(c.MONARCA) >= 2, "comum inicial")
	for key in ["b10_monarca_0", "b10_garrafeira_2", "b10_sombrinha_3", "b10_paredinha_1", "b10_hype_0", "b10_lagartona_0", "b10_segmento_1", "b10_garrafa_gin", "b10_palco", "boss10_sing_3", "boss10_death_3", "b10_dancarina_1"]:
		_check(RTBailePresentation.tex(key) != null, "textura ausente: " + key)
	_check(b10.on_stage(), "dona boleta deveria estar no palco antes da invocacao")

	# ---------------- relogio de batida
	var beat := RTBaileBeatClock.new()
	_check(absf(beat.beat_len() - 60.0 / 130.0) < 0.0001, "BPM base 130")
	var sum := 0.0
	var n := 0
	for i in range(1600):
		beat.update(1.0 / 100.0 * beat.beat_len() * 0.16)
		if not beat.is_freeze() and not beat.is_drop():
			sum += beat.step_multiplier()
			n += 1
	_check(absf(sum / float(n) - 1.0) < 0.12, "velocidade media do passinho ~1.0: %.3f" % (sum / float(n)))
	beat.reset()
	beat.beat_pos = 14.5
	beat.update(0.0)
	_check(beat.is_freeze() and beat.step_multiplier() == 0.0, "batida 15 deveria congelar")
	beat.beat_pos = 15.0
	beat.update(0.0)
	_check(beat.is_drop() and beat.bar_beat() == 3, "batida 16 = drop no 4")
	_check(RTBaileBeatClock.pulse_envelope(0.0) > 0.99 and RTBaileBeatClock.pulse_envelope(0.5) < 0.01, "envelope do tamborzao")

	# ---------------- passinho: congela no aviso, anda no resto
	game.player_hp_max = 999999
	game.player_hp = 999999
	var home: Vector2 = c.fight_anchor() + Vector2(0, 400)
	game.player_pos = home
	_clear_enemies()
	game._spawn_enemy(c.MONARCA, home + Vector2(500, 0))
	var mon: Dictionary = _last_enemy(c.MONARCA)
	c.beat.beat_pos = 14.05
	c.beat.update(0.0)
	var p0: Vector2 = mon["pos"]
	game._update_enemies(1.0 / 60.0)
	_check(Vector2(mon["pos"]).distance_to(p0) < 0.5, "monarca deveria congelar no aviso do drop")
	c.beat.beat_pos = 16.0
	c.beat.update(0.0)
	_step(1.0, false, home)
	_check(Vector2(mon["pos"]).distance_to(home) < p0.distance_to(home) - 40.0, "monarca nao avancou no passinho")

	# ---------------- liberacao gradual, tetos e fallback
	_clear_enemies()
	game.phase_started_at = game.time_alive - 20.0
	var early_special := false
	for i in range(200):
		if c.choose_enemy_type() != c.MONARCA:
			early_special = true
	_check(not early_special, "especial antes dos 35 s")
	game.phase_started_at = game.time_alive - 400.0
	var seen: Dictionary = {}
	for i in range(3000):
		c._last_spawn_time.clear()
		seen[c.choose_enemy_type()] = true
	for kind in c.SPECIALS:
		_check(seen.has(kind), "especial nunca sorteado: " + kind)
	for i in range(4):
		game._spawn_enemy(c.GARRAFEIRA, home + Vector2(300 + i * 10, 0))
	c._last_spawn_time.clear()
	_check(not c.special_available(c.GARRAFEIRA, 400.0), "teto da garrafeira ignorado")
	_clear_enemies()
	c._last_spawn_time[c.HYPE] = 395.0
	_check(not c.special_available(c.HYPE, 400.0), "intervalo minimo da hype ignorado")

	# ---------------- Garrafeira: arremessa no 4, garrafa cai no marcador, Teor sobe
	_clear_enemies()
	c.reset()
	game._spawn_enemy(c.GARRAFEIRA, home + Vector2(300, 0))
	var gar: Dictionary = _last_enemy(c.GARRAFEIRA)
	gar["b10_throw_parity"] = 0
	_step(c.beat.bar_len() * 1.2, false, home)
	_check(not c.bottles.is_empty() or c.teor > 0.0, "garrafeira nao arremessou no compasso")
	_clear_enemies()
	c.bottles.clear()
	game.run_retry_invulnerability_timer = 0.0
	game.player_hp = int(game.player_hp_max * 0.5)
	var hp_b: int = game.player_hp
	c.throw_bottle(home + Vector2(200, 0), RTUmbraHitbox.feet(home), "vodka")
	_step(c.beat.beat_len() * 2.2, false, home, false)
	_check(game.player_hp < hp_b, "garrafa nao feriu no marcador")
	_check(c.teor > 15.0, "vodka nao subiu o Teor: %.1f" % c.teor)
	c.teor_by_peer[game._mp_unique_id()] = 95.0
	c.add_teor(0, 10.0)
	c._update_teor(0.0)
	_check(c.blackout > 0.0 and absf(c.teor - c.TEOR_BLACKOUT_RESET) < 0.1, "Teor 100 deveria apagar e voltar a 60")
	c.teor_by_peer.clear()
	c.blackout = 0.0
	c.throw_bottle(home + Vector2(200, 0), RTUmbraHitbox.feet(home), "gin")
	_step(c.beat.beat_len() * 2.2, false, home)
	_check(not c.puddles.is_empty() and c.move_multiplier() < 1.0, "poca de gin nao deixou lenta")
	_check(game._environment_player_slow_mult() < 1.0, "lentidao do gin nao chegou no jogador")
	c.puddles.clear()
	_step(0.5, false, home)

	# ---------------- Sombrinha: bloqueia pela frente, nao pelas costas; devolve no drop
	game._spawn_enemy(c.SOMBRINHA, home + Vector2(220, 0))
	var som: Dictionary = _last_enemy(c.SOMBRINHA)
	som["b10_guard"] = Vector2.LEFT
	_check(c.damage_taken_multiplier(som) < 0.2, "sombrinha nao bloqueou de frente")
	som["b10_guard"] = Vector2.RIGHT
	_check(c.damage_taken_multiplier(som) == 1.0, "sombrinha bloqueou pelas costas")
	som["b10_blocked"] = 2
	c.beat.beat_pos = 14.98
	c.beat.update(0.0)
	_step(0.1, false, home)
	_check(not c.shots.is_empty(), "sombrinha nao devolveu o tiro no drop")
	_clear_enemies()
	c.shots.clear()

	# ---------------- Paredinha: se planta e solta aneis que empurram
	game._spawn_enemy(c.PAREDINHA, home + Vector2(300, 0))
	var par: Dictionary = _last_enemy(c.PAREDINHA)
	_step(c.beat.bar_len() * 2.5, false, home)
	_check(String(par.get("b10_state", "")) == "plant", "paredinha nao se plantou")
	_check(not c.rings.is_empty(), "paredinha nao soltou anel")
	c.rings.clear()
	var ring_center: Vector2 = RTUmbraHitbox.feet(home) + Vector2(-100, 0)
	c.rings.append({"pos": ring_center, "t": c.beat.beat_len() * 2.0 * (100.0 / c.RING_MAX), "life": c.beat.beat_len() * 2.0, "hit": {}})
	game.player_pos = home
	c._update_rings(1.0 / 30.0, true)
	_check(game.player_pos.x > home.x + 0.5, "anel de grave nao empurrou")
	c.rings.clear()
	_clear_enemies()

	# ---------------- Hype: embalo e corte do embalo
	game._spawn_enemy(c.HYPE, home + Vector2(500, 0))
	var hype: Dictionary = _last_enemy(c.HYPE)
	game._spawn_enemy(c.MONARCA, Vector2(hype["pos"]) + Vector2(60, 0))
	var ally: Dictionary = _last_enemy(c.MONARCA)
	c._refresh_embalo()
	_check(bool(ally.get("b10_embalo", false)), "aliado perto da hype sem embalo")
	game._kill_enemy(hype)
	_check(float(ally.get("stun", 0.0)) > 0.0, "matar a hype nao tirou o ritmo dos aliados")
	_clear_enemies()

	# ---------------- palco: solido e absorve tiros antes da invocacao
	game.player_pos = c.stage_rect().get_center()
	c.update(1.0 / 30.0)
	_check(not c.stage_rect().has_point(RTUmbraHitbox.feet(game.player_pos)), "palco deveria ser solido")
	_check(c.bullet_hit(c.stage_rect().get_center()), "palco deveria absorver tiro")
	_check(not c.bullet_hit(c.fight_anchor()), "tiro fora do palco absorvido")
	game.player_pos = home

	# ---------------- Lagartona do Paredao (miniboss)
	c.miniboss_spawned = false
	game.boss_active = false
	game.phase_started_at = game.time_alive - (c.LAGARTONA_SPAWN_TIME + 1.0)
	c.update(1.0 / 30.0)
	_check(c.miniboss_alive(), "lagartona nao apareceu aos 200s")
	_check(not game._boss_call_can_start(false), "chamada do chefe deveria travar com a lagartona viva")
	var lag: Dictionary = c.miniboss()
	lag["pos"] = home + Vector2(450, 0)
	var lg_states: Dictionary = {}
	for i in range(int(24.0 * 30.0)):
		game.time_alive += 1.0 / 30.0
		game._update_enemies(1.0 / 30.0)
		c.update(1.0 / 30.0)
		game.player_pos = home
		game.player_hp = game.player_hp_max
		lg_states[String(lag.get("b10_state", ""))] = true
	# O passeio pode aproximar a Lagartona antes da batida de ataque; nesse caso
	# force a distancia exigida e deixe o estado real executar o trenzinho.
	if not lg_states.has("trem_warn"):
		lag["pos"] = home + Vector2(650, 0)
		lag["lg_cycle"] = 0
		c.lagartona._go(lag, "walk")
		c.lagartona._choose_attack(lag, c._info(lag))
		for i in range(int(8.0 * 30.0)):
			game.time_alive += 1.0 / 30.0
			game._update_enemies(1.0 / 30.0)
			c.update(1.0 / 30.0)
			game.player_pos = home
			game.player_hp = game.player_hp_max
			lg_states[String(lag.get("b10_state", ""))] = true
	for st in ["walk", "trem_warn", "trem", "ofegante", "vira", "tonta"]:
		_check(lg_states.has(st), "lagartona nunca entrou em " + st + " " + str(lg_states.keys()))
	_check(c.lagartona.segments.size() == RTBaileLagartona.SEGMENTS, "segmentos da lagartona")
	lag["hp"] = float(lag["max_hp"]) * 0.3
	lag["b10_state"] = "walk"
	c.lagartona.state = "walk"
	_step(0.1, false, home)
	_check(String(lag.get("b10_state", "")) == "casulo", "lagartona nao fez casulo a 35%%")
	_check(c.damage_taken_multiplier(lag) < 0.3, "casulo sem armadura")
	_step(RTBaileLagartona.CASULO_TIME + 0.3, false, home)
	_check(c.lagartona.seg_count == RTBaileLagartona.SEGMENTS - RTBaileLagartona.CASULO_LOST_SEGMENTS, "casulo nao tirou segmentos")
	game._kill_enemy(lag)
	_check(not c.miniboss_alive() and c.miniboss_defeated, "lagartona nao morreu")
	_check(c.lagartona.segments.is_empty(), "segmentos sobraram")
	_step(0.2, false, home)
	_check(not c.miniboss_alive(), "lagartona reapareceu")

	# ---------------- invocacao: desce do palco
	c.throw_bottle(home + Vector2(100, 0), home, "whisky")
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
	_check(c.bottles.is_empty(), "chamada do chefe nao limpou as garrafas")
	_check(not b10.on_stage(), "boss ativo ainda no palco")
	_check(b10.mode == "entry", "chefe deveria descer do palco")
	_check(game._boss_texture() != null, "textura do chefe")
	_check(b10.damage_taken_multiplier() == 0.0, "chefe nao deveria levar dano descendo")
	var pin: Vector2 = c.fight_anchor() + Vector2(0, 330)
	_step(RTBoss10Controller.ENTRY_TIME + 0.2, true, pin)
	_check(b10.mode != "entry" and Vector2(game.boss_pos).distance_to(c.fight_anchor()) < 200.0, "chefe nao chegou a ancora: %s" % b10.mode)

	# ---------------- ataques do estagio 1 e a Roda
	var modes: Dictionary = {}
	var spot_hit := false
	var roda_seen := false
	for i in range(int(60.0 * 30.0)):
		game.time_alive += 1.0 / 30.0
		game._update_enemies(1.0 / 30.0)
		c.update(1.0 / 30.0)
		game._update_boss(1.0 / 30.0)
		game.player_hp = game.player_hp_max
		game.boss_hp = game.boss_hp_max * 0.9
		modes[b10.mode] = true
		for s in b10.spots:
			if String(s["state"]) == "lock":
				spot_hit = true
		if b10.roda_active():
			roda_seen = true
			var rc: Vector2 = b10.roda["center"]
			var rr: float = float(b10.roda["r"])
			game.player_pos = rc + Vector2(rr + 400.0, 0)
			c.update(0.0)
			b10._apply_roda_limits(1.0 / 30.0, true)
			_check(RTUmbraHitbox.feet(game.player_pos).distance_to(rc) <= rr, "jogador saiu da roda")
			_check(Vector2(game.boss_pos).distance_to(rc) <= rr, "chefe saiu da roda")
		else:
			game.player_pos = Vector2(game.boss_pos) + Vector2(0, 330 if i % 600 < 300 else 180)
	for m in ["walk", "holofote", "chuva", "pose", "grito"]:
		_check(modes.has(m), "chefe nunca entrou em " + m + " " + str(modes.keys()))
	_check(modes.has("inhale") or modes.has("dash_warn"), "chefe nunca usou grave nem sarrada " + str(modes.keys()))
	_check(spot_hit, "holofote nunca travou")
	_check(roda_seen, "a roda nunca abriu")

	# ---------------- rojao acerta quem fica no circulo travado
	b10.spots.clear()
	game.player_pos = c.fight_anchor() + Vector2(0, 300)
	b10.spots.append({"pos": RTUmbraHitbox.feet(game.player_pos), "peer": game._mp_unique_id(), "state": "fall", "t": 0.0, "delay": 0.0})
	game.run_retry_invulnerability_timer = 0.0
	game.player_hp = int(game.player_hp_max * 0.5)
	var hp_r: int = game.player_hp
	b10._update_spots(RTBoss10Controller.SPOT_FALL + 0.01)
	_check(game.player_hp < hp_r, "rojao nao feriu dentro do circulo")

	# ---------------- Remix Mandelao
	b10.roda.clear()
	b10.mode = "walk"
	game.boss_hp = game.boss_hp_max * 0.45
	_step(0.1, true, game.player_pos)
	_check(b10.stage == 2 and is_equal_approx(c.beat.bpm, RTBaileBeatClock.BPM_REMIX), "remix nao subiu para 150 BPM")
	_check(b10.mode == "remix", "chefe nao entrou no remix")
	_step(RTBoss10Controller.REMIX_TIME + 0.2, true, game.player_pos)
	_check(not b10.roda.is_empty(), "remix deveria abrir a roda")

	# ---------------- morte
	b10.mode = "walk"
	game._damage_boss(game.boss_hp_max * 10.0, "teste")
	_check(game.boss_dead, "chefe nao morreu")
	_check(b10.roda.is_empty() and b10.spots.is_empty(), "morte nao limpou roda/holofotes")
	_check(is_equal_approx(c.beat.bpm, RTBaileBeatClock.BPM_BASE), "BPM nao voltou ao normal")
	_step(1.0, false)

	# ---------------- snapshot visual (contrato de replica, sem rede)
	var snap: Dictionary = c.visual_snapshot()
	var other := RTBaileController.new()
	other.configure(game)
	other.apply_remote_visual_snapshot(snap)
	_check(absf(other.beat.beat_pos - c.beat.beat_pos) < 0.001, "snapshot nao levou a batida")
	var bsnap: Dictionary = b10.visual_snapshot()
	_check(bsnap.has("mode") and bsnap.has("roda"), "snapshot do chefe")

	if not failed:
		print("PHASE10_BAILE_SMOKE_OK modes=%s lagartona=%s" % [str(modes.keys()), str(lg_states.keys())])
	game.queue_free()
	await process_frame
	await process_frame
	await process_frame
	quit(1 if failed else 0)
