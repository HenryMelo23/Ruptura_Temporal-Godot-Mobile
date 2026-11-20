extends SceneTree

## Rede do Petro (fusao de DNA dos chefes): catalogo, DNA ao matar chefe,
## fusao paga, as 3 habilidades do chefe 1, as 27 disparando sem erro, a
## maquina e as falas do Mercador, save da run e nova run limpa, e os
## Inimigos Supremos pagando pontos em vez de cartas.

var game: Node
var checks := 0
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failed = true
		push_error("BOSS_DNA_FAIL " + msg)


func _skip_dialogue(talk: RTDialogueController) -> void:
	var lines := 0
	while talk.busy() and not talk.awaiting_choice() and lines < 40:
		talk.grace = 0.0
		talk.revealed = 99999.0
		talk.advance_input()
		lines += 1
	talk.grace = 0.0
	talk.revealed = 99999.0


func _ring(count: int, center: Vector2, radius: float) -> void:
	for i in range(count):
		game._spawn_enemy(game.ENEMY_COMMON, center + Vector2.from_angle(TAU * float(i) / float(count)) * radius)


func _fresh_field() -> void:
	game.mode = "game"
	game.enemies.clear()
	game.boss_active = false
	game.is_dead = false
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_defense = 0.0
	game.run_retry_invulnerability_timer = 0.0
	game.player_pos = Vector2(900, 700)


func _run() -> void:
	await process_frame
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.is_multiplayer = false
	var dim: RTMerchantDimension = game._merchant_dimension()
	var dna: RTBossDnaController = dim.dna
	_check(RTBossDnaCatalog.validate() == "", "catalogo invalido: %s" % RTBossDnaCatalog.validate())
	_check(dna.owned.is_empty() and dna.bank.is_empty(), "run nova ja comeca com DNA")
	_check(not game._shop_card_eligible_for_roll(game._find_card_by_id("Petro"), {}), "Petro ainda sai na loja")

	_check_boss_kill_grants_dna(dna)
	_check_fusion_cost(dna)
	_check_boss1_abilities(dna)
	_check_all_abilities(dna)
	_check_machine_and_lines(dim, dna)
	_check_save_and_new_run(dim, dna)
	_check_supreme_points()

	if failed:
		quit(1)
		return
	print("BOSS_DNA_FUSION_OK checks=%d habilidades=%d custo_base=%.1fx carta arauto=%.1fx sineiro=%.1fx" % [checks, RTBossDnaCatalog.ABILITIES.size(), RTBossDnaCatalog.FUSION_COST_CARD_RATIO, RTSupremeEnemyRewards.ARAUTO_RATIO, RTSupremeEnemyRewards.SINEIRO_RATIO])
	quit(0)


# ------------------------------------------------------------ DNA do chefe
func _check_boss_kill_grants_dna(dna: RTBossDnaController) -> void:
	_fresh_field()
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 1000.0
	game.boss_hp = 1.0
	game.boss1_rewind_cooldown = 999.0
	game.arauto_card_drops.clear()
	game._damage_boss(99999.0, "smoke")
	_check(bool(game.boss_dead), "chefe 1 nao morreu no fixture")
	_check(dna.dna_count(1) == 1, "matar o chefe 1 nao guardou DNA (%d)" % dna.dna_count(1))
	_check(dna.rift_requested, "chefe morto nao pediu a fenda do Mercador")
	var cinzas: Dictionary = game._find_card_by_id(game.CARD_CINZAS_ID)
	if game._card_drop_texture_registered(cinzas):
		var found := false
		for drop in game.arauto_card_drops:
			found = found or game._card_id(Dictionary(drop.get("card", {}))) == game.CARD_CINZAS_ID
		_check(found, "chefe nao deixou a Cinzas da Escolha")
	_check(not dna.on_boss_defeated(5, Vector2.ZERO), "UMBRA nao pode dar DNA")
	game.boss_active = false


# ------------------------------------------------------------ fusao
func _check_fusion_cost(dna: RTBossDnaController) -> void:
	game.card_cost = 100
	game.score = 10
	var cost := dna.next_cost()
	_check(cost == 300, "fusao deveria custar 3 cartas (%d)" % cost)
	_check(dna.fusion_block_reason(1, "mare_cosmica") == "PONTOS INSUFICIENTES", "fundiu sem pontos")
	game.score = 1000
	_check(dna.fuse(1, "mare_cosmica"), "fusao valida falhou")
	_check(int(game.score) == 700, "fusao cobrou errado (%d)" % int(game.score))
	_check(dna.rank("mare_cosmica") == 1 and dna.dna_count(1) == 0, "fusao nao consumiu DNA/nao deu habilidade")
	_check(dna.next_cost() == 400, "segunda fusao deveria custar 4 cartas")
	_check(dna.fusion_block_reason(1, "distorcao_relogio").begins_with("SEM DNA"), "fundiu outra do chefe 1 sem enfrentar de novo")
	_check(dna.fusion_block_reason(2, "nevasca_particular").begins_with("SEM DNA"), "DNA de um chefe destrava outro")
	# Enfrentar de novo: mais DNA do mesmo chefe destrava a proxima.
	dna.on_boss_defeated(1, Vector2.ZERO)
	dna.on_boss_defeated(1, Vector2.ZERO)
	game.score = 99999
	_check(dna.fuse(1, "distorcao_relogio"), "nao fundiu a 2a habilidade do chefe 1")
	_check(dna.fuse(1, "ressaca_temporal"), "nao fundiu a 3a habilidade do chefe 1")


# ------------------------------------------------------------ chefe 1
func _check_boss1_abilities(dna: RTBossDnaController) -> void:
	# Mare: todos os inimigos lentos por 15 s, inclusive quem nasce depois.
	_fresh_field()
	_ring(6, game.player_pos, 240.0)
	_ring(3, game.player_pos, 2000.0)
	dna.fire("mare_cosmica")
	dna.update(0.6)
	var slowed := 0
	for enemy in game.enemies:
		if float(enemy.get("evolution_slow", 0.0)) > 0.0 and float(enemy.get("evolution_slow_mult", 1.0)) <= 0.56:
			slowed += 1
	_check(slowed == game.enemies.size(), "mare nao pegou TODOS os inimigos (%d/%d)" % [slowed, game.enemies.size()])
	_check(dna.slow_all_timer > 14.0, "mare deveria durar 15 s")
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(300, 0))
	dna.update(0.6)
	_check(float(game.enemies[-1].get("evolution_slow", 0.0)) > 0.0, "inimigo novo escapou da mare")
	dna.slow_all_timer = 0.0

	# Distorcao: golpe letal perto da morte vira volta de 10 s, sem morrer.
	_fresh_field()
	_ring(4, game.player_pos + Vector2(400, 0), 60.0)
	var start_pos: Vector2 = game.player_pos
	var enemy_start: Vector2 = Vector2(game.enemies[0]["pos"])
	dna.rewind_history.clear()
	for i in range(24):
		game.time_alive += 0.5
		dna.update(0.5)
		game.player_pos += Vector2(12, 0)
		game.enemies[0]["pos"] = Vector2(game.enemies[0]["pos"]) + Vector2(-14, 0)
		dna.cooldowns["mare_cosmica"] = 99.0
		dna.cooldowns["ressaca_temporal"] = 99.0
	var moved_pos: Vector2 = game.player_pos
	game.player_hp = 120
	dna.cooldowns["distorcao_relogio"] = 0.0
	game._damage_player(5000, "smoke_lethal", true)
	_check(not bool(game.is_dead) and int(game.player_hp) > 0, "a distorcao deixou ela morrer")
	_check(int(game.player_hp) >= 400, "vida apos o rewind abaixo do piso de 40%% (%d)" % int(game.player_hp))
	_check(Vector2(game.player_pos).distance_to(moved_pos) > 150.0 and Vector2(game.player_pos).x < moved_pos.x, "ela nao voltou no tempo")
	_check(Vector2(game.enemies[0]["pos"]).x > Vector2(enemy_start).x - 24 * 14 + 100, "inimigos nao voltaram no tempo")
	_check(float(dna.cooldowns["distorcao_relogio"]) > 100.0, "distorcao sem recarga longa")
	_check(float(game.run_retry_invulnerability_timer) > 0.0, "distorcao sem invulnerabilidade curta")
	_check(start_pos != Vector2.ZERO, "fixture")

	# Ressaca: golpe comum solta a onda (dano + lentidao), com recarga.
	_fresh_field()
	_ring(5, game.player_pos, 420.0)
	var hp_before: Array = game.enemies.map(func(e): return float(e["hp"]))
	dna.cooldowns["ressaca_temporal"] = 0.0
	dna.cooldowns["distorcao_relogio"] = 99.0
	game._damage_player(20, "smoke_hit", true)
	_check(dna.waves.size() == 1, "golpe nao soltou a onda")
	_check(float(dna.cooldowns["ressaca_temporal"]) > 10.0, "onda sem recarga")
	for i in range(30):
		dna.update(0.05)
	var hit := 0
	for i in range(game.enemies.size()):
		if float(game.enemies[i]["hp"]) < float(hp_before[i]) and float(game.enemies[i].get("evolution_slow", 0.0)) > 0.0:
			hit += 1
	_check(hit >= 4 or game.enemies.size() < 5, "a onda nao feriu/desacelerou os inimigos (%d)" % hit)
	game._damage_player(20, "smoke_hit", true)
	_check(dna.waves.size() <= 1, "onda disparou dentro da recarga")


# ------------------------------------------------------------ as 27
func _check_all_abilities(dna: RTBossDnaController) -> void:
	var owned_before: Dictionary = dna.owned.duplicate()
	for id in RTBossDnaCatalog.ability_ids():
		_fresh_field()
		_ring(6, game.player_pos, 150.0)
		dna.owned[String(id)] = 1
		_check(dna.fire(String(id)), "%s nao disparou" % id)
		for i in range(6):
			dna.update(0.25)
		_check(float(dna.cooldowns.get(String(id), 0.0)) > 0.0, "%s sem recarga" % id)
		_check(RTBossDnaCatalog.trigger_label(String(id)) != "", "%s sem texto de gatilho" % id)
	game.enemies.clear()
	dna.owned = owned_before
	dna._clear_transient()


# ------------------------------------------------------------ maquina
func _check_machine_and_lines(dim: RTMerchantDimension, dna: RTBossDnaController) -> void:
	var npc: RTMerchantNpc = game._merchant_npc()
	var talk: RTDialogueController = game._dialogue()
	_fresh_field()
	npc.seen.clear()
	npc.seen["intro"] = true
	dna.presented = false
	dna.on_boss_defeated(2, Vector2.ZERO)
	_check(dim.enter(), "nao entrou na oficina")
	dim.talked_this_visit = true
	dim.machine.update(1.2)
	_check(talk.busy() and dna.presented, "Mercador nao apresentou a maquina depois do chefe")
	_skip_dialogue(talk)
	_check(not talk.busy(), "apresentacao travou")
	game.player_pos = RTBossDnaMachine.POS + Vector2(0, 40)
	dim.machine.update(2.0)
	_check(talk.busy() and npc.seen.has(RTBossDnaMachine.SEEN_KEY), "primeira interacao nao explicou a maquina")
	_skip_dialogue(talk)
	_check(talk.awaiting_choice(), "explicacao sem oferta de abrir a maquina")
	talk.choose(0)
	var screen: RTBossDnaFusionScreen = dim.fusion_screen
	_check(game.mode == RTBossDnaFusionScreen.MODE, "escolher abrir nao abriu a tela")
	_check(RTBossDnaCatalog.PHASES[screen.selected_phase_index] == 2, "tela nao focou o chefe com DNA")
	game.score = 99999
	screen.selected_ability = 1
	_check(screen.confirm(), "tela nao fundiu")
	_check(dna.rank("congelamento_subito") == 1 and screen.fusing_id != "", "fusao pela tela nao aplicou/animou")
	screen.fusing_started -= RTBossDnaFusionScreen.ANIM_TIME + 0.1
	screen._tick_animation()
	screen.close()
	_check(game.mode == "game", "fechar a tela nao voltou ao jogo")
	dim.machine.update(2.0)
	_check(game.mode == "game", "maquina reabriu sem ela se afastar")
	# Segunda visita com DNA novo: so o lembrete no balao.
	dim.leave(false)
	dna.on_boss_defeated(3, Vector2.ZERO)
	_check(dim.enter(), "nao reentrou")
	dim.machine.update(1.2)
	_check(not talk.busy() and npc.bubble != "", "lembrete do DNA nao apareceu")
	dim.leave(false)


# ------------------------------------------------------------ save
func _check_save_and_new_run(dim: RTMerchantDimension, dna: RTBossDnaController) -> void:
	var snap: Dictionary = dim.save_state()
	var owned_before: Dictionary = dna.owned.duplicate()
	var bank_before: int = dna.total_dna()
	dna.reset_run()
	dim.load_state(snap)
	_check(dna.owned == owned_before, "retomar perdeu as habilidades fundidas")
	_check(dna.total_dna() == bank_before and bank_before > 0, "retomar perdeu o DNA guardado")
	_check(dna.presented, "retomar perdeu a fala ja vista")
	game._start_game()
	game.set_process(false)
	_check(dna.owned.is_empty() and dna.total_dna() == 0 and dna.fusions_done == 0 and not dna.presented, "nova run herdou DNA")
	dim.load_state({})
	_check(dna.owned.is_empty(), "save antigo sem DNA nao zerou")


# ------------------------------------------------------------ supremos
func _check_supreme_points() -> void:
	_fresh_field()
	game.current_phase = 1
	game.boss_call_timer = -1.0
	game.card_cost = 100
	game.arauto_card_drops.clear()
	game._spawn_arauto()
	_check(game._arauto_active(), "fixture do Arauto")
	var score_before: int = int(game.score)
	game.arauto["entry_timer"] = 0.0
	game.arauto["hp"] = 1.0
	game._damage_arauto(99999.0, "smoke", false)
	var gained: int = int(game.score) - score_before
	_check(gained == RTSupremeEnemyRewards.points_for("arauto", 100), "Arauto nao pagou 7 cartas em pontos (%d)" % gained)
	var cards := 0
	for drop in game.arauto_card_drops:
		if not Dictionary(drop.get("card", {})).is_empty():
			cards += 1
	_check(cards == 0, "Arauto ainda dropou %d cartas" % cards)
	_check(RTSupremeEnemyRewards.points_for("larapio_clean", 100) > RTSupremeEnemyRewards.points_for("larapio", 100), "Larapio sem roubo deveria pagar mais")
	_check(RTSupremeEnemyRewards.points_for("aguilhao", 100) > RTSupremeEnemyRewards.points_for("arauto", 100), "Aguilhao deveria pagar mais que o Arauto")
