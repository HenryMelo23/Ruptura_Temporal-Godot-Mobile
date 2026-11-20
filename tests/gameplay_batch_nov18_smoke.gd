extends SceneTree

## Lote de ajustes de 2026-11-18: escolha aleatoria oculta, atalhos da loja,
## Cinzas (reposicao, fonte exclusiva), Mercador (run, encomendas, fisica),
## Espreitador, Projetador, Coracao Piedoso, Racional na oficina, Pinguim
## Incendiario sem teto e arrancada do laser da UMBRA.

var game: Node
var failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("GAMEPLAY_BATCH_NOV18_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _fresh_run() -> void:
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.run_tutorial_enabled = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0


func _run() -> void:
	await process_frame
	_fresh_run()
	_check_random_build_slot()
	_fresh_run()
	_check_shop_hints_and_cinzas()
	_fresh_run()
	_check_merchant_run_and_orders()
	_fresh_run()
	_check_workshop_physics()
	_fresh_run()
	_check_stalker_camouflage()
	_fresh_run()
	_check_projector_and_porcao()
	_fresh_run()
	_check_racional_in_workshop()
	_fresh_run()
	_check_pyro_and_umbra_laser()
	_fresh_run()
	_check_boss_call_vs_workshop()
	if failures.is_empty():
		print("GAMEPLAY_BATCH_NOV18_SMOKE_OK")
		quit(0)
	else:
		print("GAMEPLAY_BATCH_NOV18_SMOKE_FAILED %d" % failures.size())
		quit(1)


# ------------------------------------------------------------------ item 1
func _check_random_build_slot() -> void:
	game.mode = "manifest"
	game.manifest_select_stage = game.MANIFEST_STAGE_MANIFESTATION
	game._clear_build_random()
	var visible_count: int = game._manifest_selection_visible_indices(false).size()
	_check(game._manifest_selection_slot_count(false) == visible_count + 1, "carrossel deveria ter o slot aleatorio")
	var first: int = game._manifest_selection_index_for_slot(0, false)
	game._set_selected_manifestation(first, false)
	game._step_manifest_build_selection(false, -1)
	_check(game._build_random_focused("manifest"), "voltar do primeiro slot deveria focar ALEATORIA")
	var model: Dictionary = game.MenusPresentation._geovana_build_model(game)
	var items: Array = model.get("items", [])
	_check(bool(items[int(model.get("selected_slot", 0))].get("random", false)), "modelo deveria destacar a carta aleatoria")
	_check(not Dictionary(model.get("keys", {})).has("random"), "botao aleatorio do rodape deveria sair (virou slot)")
	_check(game._resolve_build_random_pick(false), "sorteio oculto da manifestacao falhou")
	_check(game._manifestation_unlocked(game.selected_manifestation), "sorteio escolheu manifestacao bloqueada")
	_check(bool(game.build_random_hidden.get("manifest", false)), "manifestacao sorteada deveria ficar oculta")
	game.manifest_select_stage = game.MANIFEST_STAGE_AURA
	var aura_model: Dictionary = game.MenusPresentation._geovana_build_model(game)
	_check(String(aura_model.get("summary", "")).contains("???"), "etapa do espectro revelou a manifestacao sorteada: %s" % String(aura_model.get("summary", "")))
	game._step_manifest_build_selection(true, -1)
	game._set_selected_aura(game.BUILD_RANDOM_INDEX, false)
	_check(game._build_random_focused("aura"), "espectro deveria aceitar o slot aleatorio")
	_check(game._resolve_build_random_pick(true), "sorteio oculto do espectro falhou")
	_check(game._spectrum_unlocked(game.selected_aura), "sorteio escolheu espectro bloqueado")
	# Henry: placa aleatoria nas duas etapas.
	game._clear_build_random()
	game.mode = "mutation_select"
	game.selected_mutation = 0
	game._step_henry_build_selection(false, -1)
	_check(game._build_random_focused("mutation"), "Henry: mutacao aleatoria nao recebeu foco")
	var henry_model: Dictionary = RTCharacterSelectPresentation._henry_build_model(game)
	var henry_items: Array = henry_model.get("items", [])
	_check(bool(henry_items[int(henry_model.get("selected_slot", 0))].get("random", false)), "Henry: modelo nao destacou a placa aleatoria")
	game._step_henry_build_selection(false, 1)
	_check(not game._build_random_focused("mutation") and game.selected_mutation == 0, "Henry: sair da placa aleatoria deveria voltar a primeira")
	game._step_henry_build_selection(false, -1)
	game._resolve_build_random_pick(false)
	_check(game.selected_mutation >= 0 and game.selected_mutation < game.HENRY_MUTATIONS.size(), "Henry: mutacao sorteada invalida")
	game.mode = "effect_select"
	var effect_model: Dictionary = RTCharacterSelectPresentation._henry_build_model(game)
	_check(String(effect_model.get("summary", "")).contains("???"), "Henry: etapa de efeito revelou a mutacao sorteada")
	game._clear_build_random()
	game.mode = "game"


# --------------------------------------------------------------- itens 2-4
func _check_shop_hints_and_cinzas() -> void:
	var cinzas: Dictionary = game._find_card_by_id(game.CARD_CINZAS_ID)
	var moeda: Dictionary = game._find_card_by_id(game.CARD_MOEDA_ESTAVEL_ID)
	game._apply_card(cinzas)
	# Atalhos de teclado: fixa o desktop (o config do usuario pode estar em Android).
	var saved_override = game.ui_platform_override
	var saved_unlocked = game.ui_platform_override_unlocked
	game.ui_platform_override_unlocked = true
	game.ui_platform_override = "desktop"
	var saved_gamepad = game.is_gamepad_active
	game.is_gamepad_active = false
	var hints: Array = game.shop_presentation.input_hints(game)
	game.ui_platform_override = saved_override
	game.ui_platform_override_unlocked = saved_unlocked
	game.is_gamepad_active = saved_gamepad
	var labels: Array = hints.map(func(h): return String(h[1]))
	_check(labels.has("QUEIMAR") and labels.has("COMPRAR") and labels.has("TROCAR"), "atalhos da loja incompletos: %s" % str(labels))
	_check(not game._shop_card_eligible_for_roll(cinzas, {}), "Cinzas ainda pode sair na loja")
	_check(not game._shop_card_eligible_for_roll(moeda, {}), "Moeda Estavel ainda pode sair na loja")
	_check(not game._card_available_for_reward(cinzas), "Cinzas ainda entra em sorteio de recompensa")
	for i in range(40):
		for card in game._roll_shop_cards("reroll"):
			var cid: String = game._card_id(card)
			_check(cid != game.CARD_CINZAS_ID and cid != game.CARD_MOEDA_ESTAVEL_ID, "loja sorteou carta exclusiva %s" % cid)
	_check(String(cinzas.get("desc", "")).contains("anomalias com muita energia") and String(cinzas.get("desc", "")).contains("chefe"), "descricao da Cinzas nao explica a origem")
	# Chefe (anomalia com muita energia) deixa uma Cinzas pelo mesmo helper.
	game.arauto_card_drops.clear()
	if game._card_drop_texture_registered(cinzas):
		game._spawn_supreme_cinzas_drop(game.player_pos + Vector2(200, 0))
		var found := false
		for drop in game.arauto_card_drops:
			if game._card_id(Dictionary(drop.get("card", {}))) == game.CARD_CINZAS_ID:
				found = true
		_check(found, "helper de Cinzas dos chefes nao deixou Cinzas da Escolha")
	else:
		print("GAMEPLAY_BATCH_NOV18 nota: textura da Cinzas sem registro no headless; drop nao verificado")


# ----------------------------------------------------------------- itens 5-6
func _check_merchant_run_and_orders() -> void:
	var npc: RTMerchantNpc = game._merchant_npc()
	npc.mission_offered = true
	npc.mission_done = true
	npc.capsules_saved = npc.CAPSULES_REQUIRED
	game._start_game()
	game.set_process(false)
	_check(not npc.mission_done and npc.capsules_saved == 0 and not npc.mission_offered, "fenda estavel sobreviveu a uma nova run")
	# Snapshot da run carrega o estado da missao.
	npc.mission_done = true
	var snap: Dictionary = game._merchant_dimension().save_state()
	npc.begin_run()
	game._merchant_dimension().load_state(snap)
	_check(npc.mission_done, "retomar a run perdeu a fenda estabilizada")
	# Encomenda de zona.
	var missions: RTMerchantMissionController = npc.missions
	game.mode = "game"
	var offer: Dictionary = missions.offer(Vector2(game.WORLD_SIZE), game.player_pos)
	offer["kind"] = RTMerchantMissionController.KIND_ZONE
	offer["target"] = RTMerchantMissionController.ZONE_KILLS
	offer["zone_pos"] = game.player_pos
	offer["zone_phase"] = game.current_phase
	missions.accept(offer)
	for i in range(RTMerchantMissionController.ZONE_KILLS):
		missions.on_enemy_killed({"type": game.ENEMY_COMMON}, game.player_pos + Vector2(10, 0))
	missions.on_enemy_killed({"type": game.ENEMY_COMMON}, game.player_pos + Vector2(2000, 0))
	_check(missions.ready_to_turn_in(), "zona: %d abates dentro da marca deveriam concluir" % RTMerchantMissionController.ZONE_KILLS)
	var moeda_before: int = game._card_count_by_id(game.CARD_MOEDA_ESTAVEL_ID)
	_check(missions.turn_in(), "entrega da encomenda falhou")
	_check(game._card_count_by_id(game.CARD_MOEDA_ESTAVEL_ID) == moeda_before + 1, "entrega nao deu Moeda Estavel")
	# Encomenda de entrega: engrenagens no chao.
	missions.accept({"kind": RTMerchantMissionController.KIND_DELIVER, "target": 2, "progress": 0})
	missions.on_enemy_killed({"type": game.ENEMY_LARAPIO}, game.player_pos + Vector2(20, 0))
	missions.on_enemy_killed({"type": game.ENEMY_LARAPIO}, game.player_pos + Vector2(-20, 0))
	_check(missions.gears.size() == 2, "inimigos supremos deveriam derrubar engrenagem")
	missions.update(0.1)
	_check(missions.ready_to_turn_in(), "pegar as engrenagens deveria concluir a entrega")
	missions.turn_in()
	# Doacao.
	var common: Dictionary = game._find_card_by_id("Disparo crescente")
	game._apply_card(common)
	missions.accept({"kind": RTMerchantMissionController.KIND_DONATE, "target": 1, "progress": 0, "card_id": game._card_id(common), "card_name": "Disparo"})
	var copies: int = game._card_count_by_id(game._card_id(common))
	_check(missions.donate(), "doacao falhou com a carta no deck")
	_check(game._card_count_by_id(game._card_id(common)) == copies - 1, "doacao nao tirou a carta do deck")
	_check(missions.turn_in(), "doacao pronta nao entregou a moeda")
	# Menu do balcao so oferece encomendas com a fenda estavel.
	npc.mission_done = false
	var line: Dictionary = npc._menu_line("teste")
	_check(not Array(line["choices"]).any(func(c): return String(c["id"]) == RTMerchantNpc.CHOICE_MISSION), "encomendas apareceram sem fenda estavel")
	npc.mission_done = true
	line = npc._menu_line("teste")
	_check(Array(line["choices"]).any(func(c): return String(c["id"]) == RTMerchantNpc.CHOICE_MISSION), "encomendas nao apareceram com fenda estavel")


# ------------------------------------------------------------------ item 7
func _check_workshop_physics() -> void:
	var dim: RTMerchantDimension = game._merchant_dimension()
	_check(dim.enter(), "nao entrou na oficina")
	var physics: RTMerchantWorkshopPhysics = dim.physics
	_check(physics.is_ready(), "fisica da oficina nao montou os corpos")
	var crate: Dictionary = {}
	for body in physics.bodies:
		if bool(body["movable"]) and String(body["name"]) == "barrel":
			crate = body
	_check(not crate.is_empty(), "barril nao virou corpo solto")
	if not crate.is_empty():
		var home: Vector2 = Vector2(crate["pos"])
		game.player_pos = home + Vector2(-60, 0)
		game.player_pos = game._clamp_player_world(home + Vector2(-30, 0))
		_check(Vector2(crate["vel"]).length() > 1.0, "chutar o barril nao deu velocidade")
		for i in range(30):
			physics.update(1.0 / 30.0)
		_check(Vector2(crate["pos"]).distance_to(home) > 4.0, "barril chutado nao se moveu")
	var merchant_center: Vector2 = RTMerchantDimension.MERCHANT_POS + RTMerchantWorkshopPhysics.MERCHANT_BODY_OFFSET
	game.player_pos = merchant_center + Vector2(120, 0)
	var pushed: Vector2 = game._clamp_player_world(merchant_center + Vector2(5, 0))
	_check(pushed.distance_to(merchant_center) >= RTMerchantWorkshopPhysics.MERCHANT_RADIUS + RTMerchantWorkshopPhysics.PLAYER_RADIUS - 0.5, "Geovana atravessou o Mercador")
	_check(absf(physics.merchant_lean_vel) > 0.0, "Mercador nao cambaleou com o esbarrao")
	_check(game.player_pos.distance_to(RTMerchantDimension.MERCHANT_POS) <= RTMerchantDimension.TALK_RADIUS + 200.0, "sanidade")
	_check(merchant_center.distance_to(RTMerchantDimension.MERCHANT_POS) + RTMerchantWorkshopPhysics.MERCHANT_RADIUS + RTMerchantWorkshopPhysics.PLAYER_RADIUS < RTMerchantDimension.TALK_RADIUS + 20.0, "corpo do Mercador impede chegar ao balcao")
	dim.leave(false)


# ------------------------------------------------------------------ item 8
func _check_stalker_camouflage() -> void:
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_STALKER, game.player_pos + Vector2(600, 0))
	var stalker: Dictionary = game.enemies[-1]
	game._update_stalker(stalker, 0.016)
	_check(bool(stalker.get("invisible", false)), "espreitador longe deveria camuflar")
	_check(float(stalker["alpha"]) <= 0.27, "camuflagem deveria ser mais transparente (alpha %.2f)" % float(stalker["alpha"]))
	var hp_before: float = float(stalker["hp"])
	game._damage_enemy(stalker, 50.0, "eletrica")
	_check(is_equal_approx(float(stalker["hp"]), hp_before), "espreitador camuflado levou dano")
	game.auto_target_priority = "nearest"
	var target: Dictionary = game.runtime_targeting_controller.auto_target_enemy() if game.get("runtime_targeting_controller") != null else {}
	_check(target.is_empty() or target != stalker, "mira automatica escolheu espreitador camuflado")
	stalker["pos"] = game.player_pos + Vector2(120, 0)
	game._update_stalker(stalker, 0.016)
	_check(not bool(stalker.get("invisible", false)), "espreitador perto deveria se revelar")
	game._damage_enemy(stalker, 5.0, "eletrica")
	_check(float(stalker["hp"]) < hp_before, "espreitador revelado deveria levar dano")
	stalker["pos"] = game.player_pos + Vector2(600, 0)
	game._update_stalker(stalker, 0.016)
	_check(not bool(stalker.get("invisible", false)), "camuflagem deveria estar em recarga logo apos revelar")
	game.time_alive += game.STALKER_CAMO_COOLDOWN + 0.1
	game._update_stalker(stalker, 0.016)
	_check(bool(stalker.get("invisible", false)), "camuflagem deveria voltar apos a recarga")


# --------------------------------------------------------------- itens 9-10
func _check_projector_and_porcao() -> void:
	game.enemies.clear()
	game.enemy_bullets.clear()
	game._spawn_enemy(game.ENEMY_PROJECTOR, game.player_pos + Vector2(200, 0))
	var projector: Dictionary = game.enemies[-1]
	projector["shoot_cd"] = 0.0
	game._update_projector(projector, 0.016)
	_check(game.enemy_bullets.size() == 1, "projetador nao atirou")
	if not game.enemy_bullets.is_empty():
		_check(float(game.enemy_bullets[0].get("speed_mult", 1.0)) > 1.2, "projetil do projetador nao ficou mais rapido")
	_check(float(projector["shoot_cd"]) < 2.5, "projetador nao ficou com cadencia maior")
	game.player_hp_max = 100
	game.player_hp = 50
	var porcao: Dictionary = game._find_card_by_id("Porcao")
	game._apply_card(porcao)
	_check(game.player_hp_max == 110, "Coracao Piedoso 1: esperado 110, veio %d" % game.player_hp_max)
	game._apply_card(porcao)
	_check(game.player_hp_max == 121, "Coracao Piedoso 2 deveria escalar sobre 110 (121), veio %d" % game.player_hp_max)


# ----------------------------------------------------------------- item 12
func _check_racional_in_workshop() -> void:
	game.aura_state = AuraSystem.create("Racional", 1)
	var dim: RTMerchantDimension = game._merchant_dimension()
	dim.enter()
	game._merchant_npc().mission_done = false
	game.shop_controller.open_shop(true)
	_check(game.mode == "shop", "loja da oficina nao abriu")
	game.aura_state["still"] = 0.0
	var score_before: int = int(game.score)
	for i in range(int(AuraSystem.RATIONAL_STILL_TIME * 30.0) + 6):
		game._update_shop(1.0 / 30.0)
	_check(int(game.score) > score_before, "Racional parada na loja da oficina nao pontuou")
	game.aura_state["rational_dilation"] = 4.0
	var t0: float = dim.timer
	game._update_shop(1.0)
	_check(dim.timer - t0 < 0.6, "Dilatacao da Racional nao segurou o relogio da fenda (%.2f)" % (dim.timer - t0))
	game.shop_controller.finish()
	dim.leave(false)


# ----------------------------------------------------------- itens 13 e 15
func _check_pyro_and_umbra_laser() -> void:
	game.enemies.clear()
	game.current_phase = 2
	for i in range(3):
		game._spawn_enemy(game.ENEMY_PYRO_PENGUIN, game.player_pos + Vector2(300 + i * 40, 0))
	_check(game._enemy_type_count(game.ENEMY_PYRO_PENGUIN) == 3, "Pinguim Incendiario ainda tem teto (%d)" % game._enemy_type_count(game.ENEMY_PYRO_PENGUIN))
	game.enemies.clear()
	game.current_phase = 5
	game.phase5_hazards.clear()
	var center: Vector2 = game.experimental_phase_controller.boss_encounter_center()
	game.boss_pos = center + Vector2(900, 0)
	game.boss5_velocity = Vector2.ZERO
	game.phase5_hazards.append({"kind": "umbra_overload_laser", "fase": "caminhando", "life": 30.0})
	var start: Vector2 = game.boss_pos
	for i in range(30):
		game._move_umbra(1.0 / 30.0)
	_check(start.distance_to(game.boss_pos) > 400.0, "UMBRA nao arrancou para o centro (%.0f u em 1 s)" % start.distance_to(game.boss_pos))
	_check(game._boss5_overload_laser_rotation_speed(2) > PI * 0.25, "laser nao gira mais rapido")
	game.phase5_hazards.clear()


# ----------------------------------------------------------------- item 11
func _check_boss_call_vs_workshop() -> void:
	game.enemies.clear()
	for i in range(6):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(300 + i * 20, 0))
	game.boss_ready = true
	game.boss_active = false
	game.boss_call_timer = -1.0
	game.experimental_boss_altar_authorized = true
	var dim: RTMerchantDimension = game._merchant_dimension()
	dim.enter()
	_check(not game._boss_call_can_start(false), "boss pode ser chamado de dentro da oficina (horda voltaria na saida)")
	# Mesmo que o boss ja esteja ativo ao sair, a horda guardada nao volta.
	game.boss_active = true
	dim.leave(false)
	_check(game.enemies.is_empty(), "horda guardada voltou com o boss ativo (%d)" % game.enemies.size())
	game.boss_active = false
	for i in range(6):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(300 + i * 20, 0))
	game.mode = "game"
	_check(not game._boss_call_can_start(false), "chamada do boss deveria esperar a fenda terminar de cuspir a Geovana")
	for i in range(200):
		if not game._rift_transition().busy():
			break
		game._rift_transition().update(0.05)
	game.mode = "game"
	game._start_boss_call()
	_check(game.enemies.is_empty() and game.mode == "boss_call", "chamada normal do boss deixou inimigos (%d, %s)" % [game.enemies.size(), game.mode])
