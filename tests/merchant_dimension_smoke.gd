extends SceneTree

## Oficina do Mercador: entrada pela fenda, conversa, cronometro, expulsao com
## confisco da essencia, missao das pecas e o tempo ilimitado depois dela.

var game: Node
var checks := 0


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		push_error("MERCHANT_DIMENSION_FAIL " + msg)
		quit(1)


## Companheiro vivo de mentira, do jeito que o runtime reconhece.
func _live_peer() -> Dictionary:
	return {"has_snapshot": true, "dead": false, "eliminated": false, "alive": true, "hp": 100.0}


func _skip_dialogue(talk: RTDialogueController) -> int:
	var lines := 0
	while talk.busy() and lines < 40:
		talk.grace = 0.0
		talk.revealed = 99999.0
		talk.advance_input()
		lines += 1
	return lines


func _run() -> void:
	await process_frame
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	var dim: RTMerchantDimension = game._merchant_dimension()
	var npc: RTMerchantNpc = game._merchant_npc()
	var talk: RTDialogueController = game._dialogue()
	_check(not npc.persist, "o teste nao pode gravar o save real do Mercador")
	npc.seen.clear()
	npc.parts = 0
	npc.mission_offered = false
	npc.mission_done = false
	npc.visits = 0

	# ------------------------------------------------------------ entrada
	var phase_world: Vector2 = game.WORLD_SIZE
	game.player_pos = Vector2(900, 700)
	var phase_pos: Vector2 = game.player_pos
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(950, 700))
	_check(game.enemies.size() == 1, "inimigo de apoio nao nasceu")
	game.shop_cards = [{}, {}, {}, {}]
	# O tempo sai do bolso dela: 500 de essencia a 100 por carta = 5 compras.
	game.card_cost = 100
	game.score = 500
	_check(dim.budget_cards() == 5, "orcamento deveria ser 5 cartas (%d)" % dim.budget_cards())
	_check(dim.enter(), "nao entrou na oficina")
	_check(dim.active, "a oficina nao ficou ativa")
	_check(game.WORLD_SIZE == RTMerchantDimension.WORLD_SIZE, "o mundo nao encolheu")
	_check(game.enemies.is_empty(), "a horda entrou junto")
	_check(is_equal_approx(dim.limit, 100.0), "cronometro deveria ser 20s por carta compravel (%.0f)" % dim.limit)
	game.enemy_manager.spawn_wave()
	_check(game.enemies.is_empty(), "a oficina gerou horda")
	# Nem horda, nem miniboss, nem evento: a fase fica suspensa aqui dentro.
	game.current_phase = 2
	game.sineiro_boreal_state = {"active": false, "spawned": false}
	game.sineiro_boreal_controller.spawn_now()
	_check(game.enemies.is_empty(), "o Sineiro nasceu dentro da oficina")
	for _frame in range(6):
		game._update_game(1.0 / 30.0)
	_check(game.enemies.is_empty(), "a fase continuou gerando dentro da oficina (%d)" % game.enemies.size())
	_check(game.heal_orbs.is_empty(), "apareceu orbe dentro da oficina")

	# ------------------------------------------------------- primeira fala
	game.player_pos = RTMerchantDimension.MERCHANT_POS + Vector2(40, 40)
	dim.update(0.05)
	_check(talk.busy(), "o Mercador nao se apresentou")
	_check(talk.speaker() == "mercador", "quem fala primeiro e o Mercador")
	_check(talk.visible_text().length() < talk.full_text().length(), "o texto deveria aparecer aos poucos")
	talk.update(10.0)
	_check(talk.fully_revealed(), "o texto nunca terminou de aparecer")
	# O cronometro nao corre durante a conversa.
	var before: float = dim.timer
	dim.update(1.0)
	_check(is_equal_approx(dim.timer, before), "o cronometro correu durante a conversa")
	var lines: int = _skip_dialogue(talk)
	_check(lines >= 5, "a apresentacao tinha poucas falas (%d)" % lines)
	_check(not talk.busy(), "a conversa nao terminou")
	_check(npc.seen.has("intro"), "a apresentacao nao foi marcada como vista")

	# ----------------------------------------------- cronometro e expulsao
	dim.update(1.0)
	_check(dim.timer > 0.0, "o cronometro nao voltou a correr")
	game._apply_score_delta(5000 - int(game.score), true, "teste_a")
	var saved_score: int = int(game.score)
	_check(saved_score > 0, "o teste precisa de essencia no bolso")
	dim.timer = dim.limit - 0.01
	dim.update(0.1)
	_check(dim.collapsing > 0.0, "a fenda nao comecou a colapsar")
	_check(dim.active, "a expulsao foi instantanea demais")
	dim.update(RTMerchantDimension.COLLAPSE_TIME + 0.1)
	_check(not dim.active, "a expulsao nao aconteceu")
	_check(int(game.score) == 0, "o Mercador nao ficou com a essencia (%d)" % int(game.score))
	_check(dim.confiscated == saved_score, "o confisco nao bateu")
	_check(game.WORLD_SIZE == phase_world, "o mundo da fase nao voltou")
	_check(game.player_pos == phase_pos, "a Geovana nao voltou para onde estava")
	_check(game.enemies.size() == 1, "a horda nao voltou")

	# ------------------------------------- segunda visita: ela cobra os pontos
	game.shop_cards = [{}, {}, {}]
	_check(dim.enter(), "nao entrou na segunda vez")
	game.player_pos = RTMerchantDimension.MERCHANT_POS
	dim.talked_this_visit = false
	dim.update(0.05)
	_check(talk.busy(), "o Mercador ficou mudo na segunda visita")
	var complained := false
	while talk.busy():
		if talk.full_text().to_lower().contains("achado"):
			complained = true
		talk.grace = 0.0
		talk.revealed = 99999.0
		talk.advance_input()
	_check(complained, "ninguem falou do achado nao e roubado")
	_check(is_equal_approx(dim.limit, 60.0), "sem essencia o piso de 3 cartas da 60s (%.0f)" % dim.limit)
	dim.leave(false)
	_check(int(game.score) == 0, "a saida pelo portal nao deveria confiscar nada")

	# ------------------------------------------------- missao das pecas
	npc.mission_offered = true
	npc.parts = 0
	for i in range(400):
		npc.on_extraordinary_killed(Vector2(100, 100))
		if npc.parts >= RTMerchantNpc.PARTS_REQUIRED:
			break
	_check(npc.parts == RTMerchantNpc.PARTS_REQUIRED, "as pecas nao foram coletadas")
	_check(not npc.mission_done, "a missao nao fecha longe dele")
	_check(not dim.stable(), "a fenda estabilizou cedo demais")
	game.shop_cards = [{}, {}, {}, {}]
	_check(dim.enter(), "nao entrou com as pecas")
	_check(npc.mission_done, "entregar as pecas nao fechou a missao")
	_check(dim.stable(), "a fenda nao estabilizou")
	_skip_dialogue(talk)
	var stable_before: float = dim.timer
	dim.update(5.0)
	_check(is_equal_approx(dim.timer, stable_before), "o cronometro correu com a fenda estavel")
	game._apply_score_delta(900, true, "teste_b")
	dim.update(1.0)
	_check(int(game.score) == 900, "a fenda estavel nao pode confiscar (score=%d)" % int(game.score))
	dim.leave(false)

	# ------------------------------------------------- oficina com a equipe
	# Sala de 3: o tempo segue quem tem mais para comprar e o portal so cospe
	# o grupo quando todos tocarem nele.
	game.is_multiplayer = true
	# A fenda volta a ser instavel: sem missao entregue e sem pecas na mao.
	npc.mission_done = false
	npc.parts = 0
	npc.seen["intro"] = true
	game.card_cost = 100
	game.score = 300
	# Dois companheiros vivos na sala: a oficina recalcula o tamanho do grupo
	# sozinha, entao a sala precisa existir de verdade para o teste valer.
	game.net_players_by_peer = {77: _live_peer(), 78: _live_peer()}
	_check(dim.enter(), "a equipe nao entrou na oficina")
	game.mode = "game"
	_check(int(game.shop_mp_expected_count) == 3, "a sala deveria ter 3 (%d)" % int(game.shop_mp_expected_count))
	dim.talked_this_visit = true
	dim.entry_age = 5.0
	_check(is_equal_approx(dim.limit, 60.0), "o tempo local deveria ser 60s (%.0f)" % dim.limit)
	dim.on_remote_budget(9)
	_check(is_equal_approx(dim.limit, 180.0), "o tempo deveria seguir quem compra mais (%.0f)" % dim.limit)
	dim.on_remote_budget(2)
	_check(is_equal_approx(dim.limit, 180.0), "o tempo da sala nao pode encolher (%.0f)" % dim.limit)
	game.player_pos = RTMerchantDimension.EXIT_PORTAL_POS
	dim.update(0.05)
	_check(dim.mp_ready, "nao registrou que ela chegou na saida")
	_check(dim.active, "ela saiu sozinha e deixou a equipe para tras")
	_check(dim.mp_waiting_count() == 2, "deveriam faltar 2 companheiros (%d)" % dim.mp_waiting_count())
	dim.on_remote_exit_ready(77)
	dim.update(0.05)
	_check(dim.active, "a saida aconteceu faltando um companheiro")
	dim.on_remote_exit_ready(78)
	dim.update(0.05)
	_check(not dim.active, "a equipe toda chegou e o portal nao abriu")
	_check(int(game.score) == 300, "a saida coletiva nao pode confiscar (%d)" % int(game.score))

	# Companheiro que cai da sala nao pode prender quem sobrou la dentro.
	game.net_players_by_peer = {77: _live_peer(), 78: _live_peer()}
	_check(dim.enter(), "nao reentrou para o teste de desconexao")
	game.mode = "game"
	dim.talked_this_visit = true
	dim.entry_age = 5.0
	game.player_pos = RTMerchantDimension.EXIT_PORTAL_POS
	dim.update(0.05)
	dim.on_remote_exit_ready(77)
	dim.update(0.05)
	_check(dim.active and dim.mp_ready, "deveria estar esperando o companheiro 78")
	game.net_players_by_peer = {77: _live_peer()}
	dim.update(0.05)
	_check(not dim.active, "a sala encolheu e o portal continuou travado")

	# Tempo esgotado com alguem fora da saida: todos perdem a essencia.
	game.net_players_by_peer = {77: _live_peer()}
	_check(dim.enter(), "nao reentrou para o teste do tempo coletivo")
	dim.talked_this_visit = true
	dim.timer = dim.limit - 0.01
	dim.update(0.1)
	_check(dim.collapsing > 0.0, "a fenda nao colapsou com a equipe dentro")
	dim.update(RTMerchantDimension.COLLAPSE_TIME + 0.1)
	_check(not dim.active, "o colapso coletivo nao expulsou")
	_check(int(game.score) == 0, "o colapso coletivo nao confiscou (%d)" % int(game.score))
	_check(dim.collapses == 2, "o segundo confisco precisa de id proprio (%d)" % dim.collapses)
	game.is_multiplayer = false

	print("MERCHANT_DIMENSION_OK checks=%d cartas_x20s=%.0fs pecas=%d equipe=ok" % [checks, RTMerchantDimension.SECONDS_PER_CARD, RTMerchantNpc.PARTS_REQUIRED])
	quit(0)
