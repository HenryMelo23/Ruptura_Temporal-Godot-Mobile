extends SceneTree

## Lote de 2026-11-24: oficina do Mercador como sala segura (fases 1-10),
## Racional pontuando na oficina, conversa com o Mercador sem gastar tempo,
## fonte das conversas, UMBRA so avanca com toque, chip quantico de raridade
## so no modo Drop e a Profetica (gravar 10 s e voltar ao ser atingida).
## godot4 --headless --path . --script tests/gameplay_batch_nov24_smoke.gd

const UserFileGuard = preload("res://tests/support/user_file_guard.gd")
const DT := 1.0 / 30.0

var game: Node
var failures: Array[String] = []
var guards: Array = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GAMEPLAY_BATCH_NOV24_FAIL " + message)


func _initialize() -> void:
	for path in ["user://hud_config.save", "user://interrupted_run.save", "user://merchant_npc.cfg", "user://story_progress.cfg", "user://quantum_chips.cfg"]:
		guards.append(UserFileGuard.new(path))
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _fresh_run(phase: int = 1) -> void:
	game.forced_initial_phase = phase
	game.run_tutorial_enabled = false
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.mode = "game"
	game.is_multiplayer = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0


func _frames(seconds: float) -> void:
	for _i in range(int(round(seconds / DT))):
		game._process(DT)


func _enter_workshop() -> RTMerchantDimension:
	var dim: RTMerchantDimension = game._merchant_dimension()
	dim.enter()
	var waited := 0.0
	while game._rift_transition().busy() and waited < 6.0:
		game._process(DT)
		waited += DT
	return dim


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game.vol_master = 0.0
	_check_workshop_is_safe_room()
	_check_racional_in_workshop()
	_check_merchant_talk_freezes_rift()
	_check_dialogue_text_scale()
	_check_rarity_chip_drop_only()
	_check_prophecy_rewind()
	_check_prophecy_unspent_and_multiplayer()
	game.mode = "menu"
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	for guard in guards:
		guard.restore()
	if failures.is_empty():
		print("GAMEPLAY_BATCH_NOV24_SMOKE_OK")
		quit(0)
	else:
		print("GAMEPLAY_BATCH_NOV24_SMOKE_FAILED %d" % failures.size())
		quit(1)


# ------------------------------------------------------------------ item 3
## Fases 1-10: a fase roda la fora (com horda, Arauto, cristais do Nexo,
## UMBRA...), ela entra na oficina e o loop real roda varios segundos.
## Nada nasce, atira, age ou causa dano la dentro; na saida a horda volta.
func _check_workshop_is_safe_room() -> void:
	for phase in range(1, 11):
		_fresh_run(phase)
		game.time_alive = 420.0
		game.score = int(game.card_cost) * 4
		_frames(3.0)
		var outside_enemies: int = game.enemies.size()
		var dim := _enter_workshop()
		_check(dim.active, "fase %d: oficina nao abriu" % phase)
		var arauto_pos: Vector2 = Vector2(game.arauto.get("pos", Vector2.ZERO)) if game._arauto_active() else Vector2.INF
		var boss_hp_before: float = float(game.boss_hp)
		var fragment_before: Dictionary = Dictionary(game.phase_fragment).duplicate(true)
		dim.world_leaks = 0
		dim.leak_sources.clear()
		game.player_hp_max = 100000
		game.player_hp = 100000
		var damage_events: int = game.run_damage_events.size()
		var worst_enemies := 0
		var worst_bullets := 0
		for i in range(180):
			game._process(DT)
			worst_enemies = maxi(worst_enemies, game.enemies.size())
			worst_bullets = maxi(worst_bullets, game.enemy_bullets.size())
		# Loja aberta dentro da oficina tambem nao deixa a fase acordar.
		game.shop_controller.open_shop(true)
		for i in range(60):
			game._process(DT)
			worst_enemies = maxi(worst_enemies, game.enemies.size())
			worst_bullets = maxi(worst_bullets, game.enemy_bullets.size())
		game.shop_controller.finish()
		game.mode = "game"
		_check(worst_enemies == 0, "fase %d: %d inimigos na oficina" % [phase, worst_enemies])
		_check(worst_bullets == 0, "fase %d: %d projeteis inimigos na oficina" % [phase, worst_bullets])
		_check(dim.world_leaks == 0, "fase %d: vazamentos removidos pelo selo %s" % [phase, str(dim.leak_sources)])
		_check(int(game.player_hp) == 100000, "fase %d: dano na oficina (%d)" % [phase, 100000 - int(game.player_hp)])
		_check(game.run_damage_events.size() == damage_events, "fase %d: eventos de dano na oficina" % phase)
		_check(is_equal_approx(float(game.boss_hp), boss_hp_before), "fase %d: chefe agiu na oficina" % phase)
		if arauto_pos.is_finite():
			_check(Vector2(game.arauto.get("pos", Vector2.ZERO)) == arauto_pos, "fase %d: Arauto se moveu na oficina" % phase)
		_check(Dictionary(game.phase_fragment) == fragment_before, "fase %d: fragmento mudou na oficina" % phase)
		# Entrada direta (miniboss, evento, rede) tambem nao cria inimigo.
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(80, 0))
		_check(game.enemies.is_empty(), "fase %d: _spawn_enemy criou inimigo na oficina" % phase)
		game._damage_player(50, "teste_oficina")
		_check(int(game.player_hp) == 100000, "fase %d: _damage_player feriu na oficina" % phase)
		dim.leave(false)
		_check(game.enemies.size() == outside_enemies or game.boss_active, "fase %d: horda nao voltou (%d de %d)" % [phase, game.enemies.size(), outside_enemies])
	# O selo remove e conta qualquer coisa injetada por fora do fluxo.
	_fresh_run(1)
	var dim := _enter_workshop()
	dim.world_leaks = 0
	game.enemies.append({"type": "intruso", "pos": game.player_pos, "hp": 10.0})
	game.enemy_bullets.append({"source": "intruso", "pos": game.player_pos})
	game._process(DT)
	_check(game.enemies.is_empty() and game.enemy_bullets.is_empty(), "selo nao limpou o intruso")
	_check(dim.world_leaks == 2 and dim.leak_sources.has("enemy:intruso"), "selo nao contou o intruso: %s" % str(dim.leak_sources))
	dim.leave(false)


# ------------------------------------------------------------------ item 2
func _check_racional_in_workshop() -> void:
	_fresh_run(1)
	game.aura_state = AuraSystem.create("Racional", 1)
	var dim := _enter_workshop()
	game.score = 0
	_frames(AuraSystem.RATIONAL_STILL_TIME + 0.4)
	var expected: int = (5 + 2) * AuraSystem.RATIONAL_POINT_SCALE
	_check(int(game.score) == expected, "Racional parada na oficina: esperado %d, veio %d" % [expected, int(game.score)])
	# O HUD mostra pontos /10: "ANALISE +7" precisa aparecer como +7.
	_check(game.hud_feedback.display_points(game, game.score) == "7", "HUD nao mostra +7 da Analise (%s)" % game.hud_feedback.display_points(game, game.score))
	# Loja aberta (relogio correndo): continua pontuando.
	game.shop_controller.open_shop(true)
	var before_shop: int = int(game.score)
	_frames(AuraSystem.RATIONAL_STILL_TIME + 0.4)
	_check(int(game.score) > before_shop, "Racional parada com a loja aberta nao pontuou")
	game.shop_controller.finish()
	game.mode = "game"
	# Conversa com o Mercador: relogio parado, a analise congela (sem farm).
	game._dialogue().start([{"who": "mercador", "text": "Teste de conversa."}])
	var before_talk: int = int(game.score)
	_frames(AuraSystem.RATIONAL_STILL_TIME * 2.0)
	_check(int(game.score) == before_talk, "Racional pontuou com o relogio da oficina parado")
	game._dialogue().clear()
	dim.leave(false)


# ------------------------------------------------------------------ item 7
func _check_merchant_talk_freezes_rift() -> void:
	_fresh_run(1)
	var dim := _enter_workshop()
	var npc: RTMerchantNpc = game._merchant_npc()
	var talk: RTDialogueController = game._dialogue()
	npc.seen["intro"] = true
	talk.clear()
	npc.open_menu(dim)
	_check(talk.busy() and talk.choice_labels().has("COMPRAR"), "menu do balcao nao abriu")
	var t0: float = dim.timer
	_frames(2.0)
	_check(is_equal_approx(dim.timer, t0), "menu do balcao gastou %.2fs da fenda" % (dim.timer - t0))
	_check(not dim.clock_running(), "relogio marcado como correndo na conversa")
	talk.revealed = 99999.0
	talk.grace = 0.0
	talk.choose(0) # COMPRAR: a loja aberta gasta tempo
	_check(game.mode == "shop" or game.mode == "shop_opening", "COMPRAR nao abriu a loja (%s)" % game.mode)
	var t1: float = dim.timer
	_frames(1.0)
	_check(dim.timer > t1 + 0.5, "loja aberta nao gastou o tempo da fenda")
	game.shop_controller.finish()
	game.mode = "game"
	var t2: float = dim.timer
	_frames(1.0)
	_check(dim.timer > t2 + 0.5, "andar pela oficina nao gastou o tempo da fenda")
	dim.leave(false)


# ------------------------------------------------------------------ item 1
func _check_dialogue_text_scale() -> void:
	_fresh_run(1)
	game.mode = "settings_gameplay"
	game.dialogue_text_scale = 1.0
	var keys: Array = game._gameplay_preference_keys()
	_check(keys.has("dialogue_text"), "opcao TEXTO DAS CONVERSAS ausente: %s" % str(keys))
	game.settings_selected = game._gameplay_preference_index("dialogue_text")
	var right := InputEventKey.new()
	right.pressed = true
	right.keycode = KEY_RIGHT
	game.SettingsController.handle_key(game, right)
	game.SettingsController.handle_key(game, right)
	_check(is_equal_approx(game.dialogue_text_scale, 1.5), "seta direita nao aumentou a fonte (%.2f)" % game.dialogue_text_scale)
	for _i in range(8):
		game.SettingsController.handle_key(game, right)
	_check(is_equal_approx(game.dialogue_text_scale, RTDialogueTextScale.MAX), "fonte passou do maximo")
	var left := InputEventKey.new()
	left.pressed = true
	left.keycode = KEY_LEFT
	game.SettingsController.handle_key(game, left)
	_check(is_equal_approx(game.dialogue_text_scale, 1.75), "seta esquerda nao diminuiu a fonte")
	# Persistente: salva, zera e carrega de volta.
	game._save_config()
	game.dialogue_text_scale = 1.0
	game._load_config()
	_check(is_equal_approx(game.dialogue_text_scale, 1.75), "fonte das conversas nao persistiu (%.2f)" % game.dialogue_text_scale)
	# Efeito na hora: a fala usa o tamanho maior (e encolhe so ate caber).
	var rect := Rect2(Vector2.ZERO, Vector2(700, 160))
	var short_size: int = RTDialogueTextScale.fit_size(game, "Oi.", rect, int(17 * 1.75), 17)
	_check(short_size == int(17 * 1.75), "fala curta nao ficou maior (%d)" % short_size)
	var long_text: String = "Pergunta. Velho adora pergunta: e a unica hora que alguem escuta a gente inteiro. ".repeat(4)
	var long_size: int = RTDialogueTextScale.fit_size(game, long_text, rect, int(17 * 2.0), 17)
	_check(long_size >= 17 and long_size < int(17 * 2.0), "fala longa nao foi ajustada para caber (%d)" % long_size)
	game.dialogue_text_scale = 1.0
	game.mode = "game"


# ------------------------------------------------------------------ item 5
func _check_rarity_chip_drop_only() -> void:
	var chips: RTQuantumChipController = game._quantum_chips()
	var saved_selected: Dictionary = chips.selected.duplicate()
	var saved_random: bool = chips.random_mode
	chips.selected = {RTQuantumChipController.CORRUPTOR: true}
	chips.random_mode = false
	game._set_run_mode_local(game.RUN_MODE_SHOP)
	_check(not chips.allowed_in_current_mode(RTQuantumChipController.CORRUPTOR), "Corruptor liberado no modo Loja")
	chips.on_run_started()
	_check(not chips.corruptor_active(), "Corruptor ligou no modo Loja")
	_check(chips.selected_count() == 0, "Corruptor contado como ligado no modo Loja")
	_check(not chips.prepare_team_config()["active"].has(RTQuantumChipController.CORRUPTOR), "host mandou Corruptor no modo Loja")
	chips.selected.clear()
	chips.random_mode = true
	for _i in range(40):
		chips.on_run_started()
		_check(chips.random_rolled != RTQuantumChipController.CORRUPTOR, "Aleatorio sorteou o Corruptor no modo Loja")
	game._set_run_mode_local(game.RUN_MODE_DROP)
	chips.random_mode = false
	chips.selected = {RTQuantumChipController.CORRUPTOR: true}
	chips.on_run_started()
	_check(chips.corruptor_active(), "Corruptor nao ligou no modo Drop")
	chips.selected = saved_selected
	chips.random_mode = saved_random
	game._set_run_mode_local(game.RUN_MODE_SHOP)
	chips.on_run_started()


# ------------------------------------------------------------------ item 6
func _prophecy_run() -> RTPropheticRewind:
	_fresh_run(1)
	game.aura_state = AuraSystem.create("Profetica", 1)
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.player_pos = Vector2(1400, 1000)
	for offset in [Vector2(950, 0), Vector2(-950, 100), Vector2(0, 950)]:
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + offset)
		game.enemies[-1]["hp"] = 100000.0
		game.enemies[-1]["max_hp"] = 100000.0
	game.spawn_timer = 99999.0
	game.player_hp_max = 1000
	game.player_hp = 1000
	var rewind: RTPropheticRewind = game.prophetic_rewind
	_check(rewind.available() and rewind.state == RTPropheticRewind.STATE_COOLDOWN, "Profecia nao comecou em recarga")
	rewind.cooldown = 0.0
	return rewind


func _uid_positions() -> Dictionary:
	var out := {}
	for enemy in game.enemies:
		out[int(enemy["uid"])] = Vector2(enemy["pos"])
	return out


func _check_prophecy_rewind() -> void:
	var rewind := _prophecy_run()
	game._process(DT)
	_check(rewind.state == RTPropheticRewind.STATE_OMEN and rewind.eye_open() == 0.0, "presagio nao comecou com o olho fechado")
	var opened_midway := false
	while rewind.state == RTPropheticRewind.STATE_OMEN:
		game._process(DT)
		if rewind.state == RTPropheticRewind.STATE_OMEN and rewind.eye_open() > 0.2 and rewind.eye_open() < 0.9:
			opened_midway = true
	_check(opened_midway, "o olho nao abriu aos poucos antes da contagem")
	_check(rewind.state == RTPropheticRewind.STATE_RECORDING and rewind.time_left() > 9.9, "contagem de 10 s nao comecou")
	_check(AuraSystem.speed_multiplier(game.aura_state) > 1.2 and AuraSystem.attack_interval_multiplier(game.aura_state) < 0.8, "sem buff de velocidade/ataque na profecia")
	var start_pos: Vector2 = game.player_pos
	var start_time: float = game.time_alive
	var start_enemies: Dictionary = _uid_positions()
	var at_one := {}
	var shot_marker := {"source": "teste_profecia", "pos": game.player_pos + Vector2(500, 0), "dir": Vector2.LEFT, "speed": 0.0, "life": 30.0, "damage": 1}
	while rewind.clock < 2.0:
		if at_one.is_empty() and rewind.clock >= 1.0:
			at_one = _uid_positions()
			game.enemy_bullets.append(shot_marker.duplicate(true))
		game.player_pos += Vector2(0.0, -120.0) * DT
		game._process(DT)
	_check(rewind.bullet_events.size() >= 1, "disparo inimigo nao foi gravado")
	var hp_before: int = game.player_hp
	_check(rewind.state == RTPropheticRewind.STATE_RECORDING, "profecia parou de gravar antes do golpe (%s, clock %.2f)" % [rewind.state, rewind.clock])
	game._damage_player(80, "inimigo_teste")
	_check(game.player_hp == hp_before, "golpe dentro da profecia entrou")
	_check(rewind.state == RTPropheticRewind.STATE_REWINDING and rewind.rewinds == 1, "golpe nao voltou o tempo")
	_frames(RTPropheticRewind.REWIND_TIME + DT)
	_check(rewind.state == RTPropheticRewind.STATE_REPLAY, "replay nao comecou")
	_check(game.player_pos.distance_to(start_pos) < 1.0, "ela nao voltou ao inicio da profecia")
	_check(absf(game.time_alive - start_time) < DT * 2.0, "relogio da run nao voltou (%.2f -> %.2f)" % [start_time, game.time_alive])
	var restored: Dictionary = _uid_positions()
	_check(restored.size() == start_enemies.size(), "inimigos do inicio nao voltaram")
	for uid in start_enemies.keys():
		_check(restored.has(uid) and Vector2(restored[uid]).distance_to(start_enemies[uid]) < 1.0, "inimigo %d fora da posicao do inicio" % int(uid))
	# Agora ela anda para o lado oposto: os inimigos repetem a 1a linha do tempo.
	var marker_seen_at := -1.0
	var compared := false
	while rewind.clock < 1.6:
		game.player_pos += Vector2(-100.0, -80.0) * DT
		game._process(DT)
		if marker_seen_at < 0.0:
			for b in game.enemy_bullets:
				if String(Dictionary(b).get("source", "")) == "teste_profecia":
					marker_seen_at = rewind.clock
		if not compared and rewind.clock >= 1.0:
			compared = true
			var now: Dictionary = _uid_positions()
			for uid in at_one.keys():
				_check(now.has(uid) and Vector2(now[uid]).distance_to(at_one[uid]) < 1.0, "inimigo %d nao repetiu o movimento (%.1f px)" % [int(uid), Vector2(now.get(uid, Vector2.INF)).distance_to(at_one[uid])])
	_check(compared, "replay nao chegou a 1 s")
	_check(marker_seen_at >= 0.95 and marker_seen_at <= 1.15, "disparo gravado nao voltou no mesmo instante (%.2f)" % marker_seen_at)
	_check(rewind.past_self_position().is_finite(), "sem o 'eu do passado' no replay")
	# Segundo golpe, ja no replay: entra normalmente.
	while rewind.clock < 2.5:
		game._process(DT)
	var hp_replay: int = game.player_hp
	game._damage_player(80, "inimigo_teste")
	_check(game.player_hp < hp_replay, "golpe no replay nao entrou")
	while rewind.state == RTPropheticRewind.STATE_REPLAY:
		game._process(DT)
	_check(rewind.state == RTPropheticRewind.STATE_COOLDOWN and is_equal_approx(rewind.cooldown, RTPropheticRewind.COOLDOWN_SPENT), "recarga apos profecia gasta deveria ser 50 s (%.1f)" % rewind.cooldown)
	_check(is_equal_approx(AuraSystem.speed_multiplier(game.aura_state), 1.0), "buff ficou depois da profecia")


func _check_prophecy_unspent_and_multiplayer() -> void:
	var rewind := _prophecy_run()
	var guard := 0
	while rewind.state != RTPropheticRewind.STATE_RECORDING and guard < 200:
		game._process(DT)
		guard += 1
	# Sem ninguem por perto: ela nao e atingida e a profecia termina inteira.
	game.enemies.clear()
	while rewind.state == RTPropheticRewind.STATE_RECORDING:
		game._process(DT)
	_check(is_equal_approx(rewind.cooldown, RTPropheticRewind.COOLDOWN_UNSPENT), "recarga sem golpe deveria ser 30 s (%.1f)" % rewind.cooldown)
	game.is_multiplayer = true
	_check(not rewind.available(), "profecia ligada no multiplayer")
	game.is_multiplayer = false
	# Na oficina do Mercador nao comeca.
	rewind.cooldown = 0.0
	var dim := _enter_workshop()
	_frames(2.0)
	_check(rewind.state == RTPropheticRewind.STATE_COOLDOWN, "profecia comecou dentro da oficina")
	dim.leave(false)
