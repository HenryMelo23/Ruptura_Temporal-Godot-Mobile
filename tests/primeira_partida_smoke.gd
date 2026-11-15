extends SceneTree

## Opcao "PRIMEIRA PARTIDA" do menu de jogabilidade.
##
## Ligar devolve o comeco do jogo para quem empresta o aparelho a um testador:
## tutorial, dicas de contexto e a historia do Mercador. Desligar e o fim normal
## do tutorial e nao pode apagar nada. Ligar de novo com a opcao ja ligada
## tambem nao pode apagar, senao carregar um save ligado zeraria o jogador.

var game: Node
var checks := 0


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if cond:
		return
	push_error("PRIMEIRA_PARTIDA_FAIL " + msg)
	quit(1)


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	# Ferramenta de desenvolvimento ligada desativa a oferta por projeto; o
	# teste mede a opcao, nao o modo QA.
	game.qa_data_unlocked = false
	game.experimental_phase_active = false
	game.forced_initial_phase = 0
	game.is_multiplayer = false
	var npc: RTMerchantNpc = game._merchant_npc()
	_check(not npc.persist, "o teste nao pode gravar o save real do Mercador")

	# Estado de quem ja jogou muito: tutorial desligado e tudo visto.
	game._set_run_tutorial_enabled(false, false)
	game.shop_tutorial_seen = true
	game.boss_call_tutorial_seen = true
	npc.seen["intro"] = true
	npc.seen["stolen"] = true
	npc.visits = 9
	npc.parts = RTMerchantNpc.PARTS_REQUIRED
	npc.mission_offered = true
	npc.mission_done = true
	_check(not game._should_offer_run_tutorial(true), "veterano nao deveria receber a oferta de tutorial")

	# Liga: volta tudo do comeco.
	game._set_run_tutorial_enabled(true, false)
	_check(game.run_tutorial_enabled, "a opcao nao ligou")
	_check(not game.shop_tutorial_seen, "a dica da loja continuou marcada como vista")
	_check(not game.boss_call_tutorial_seen, "a dica do boss continuou marcada como vista")
	_check(npc.seen.is_empty(), "o Mercador ainda lembra da historia")
	_check(npc.visits == 0, "as visitas ao Mercador nao zeraram")
	_check(npc.parts == 0, "as pecas do teleportador nao zeraram")
	_check(not npc.mission_offered, "a missao continuou oferecida")
	_check(not npc.mission_done, "a fenda continuou estabilizada")
	_check(game._should_offer_run_tutorial(true), "a oferta de tutorial nao voltou")

	# Com a opcao ja ligada, nada pode ser apagado de novo: carregar um save
	# ligado passaria por aqui e zeraria o progresso do jogador.
	npc.parts = 3
	npc.seen["intro"] = true
	game.shop_tutorial_seen = true
	game._set_run_tutorial_enabled(true, false)
	_check(npc.parts == 3, "ligar de novo apagou as pecas (%d)" % npc.parts)
	_check(npc.seen.has("intro"), "ligar de novo apagou a historia")
	_check(game.shop_tutorial_seen, "ligar de novo apagou a dica da loja")

	# Desligar e o fim normal do tutorial: nao apaga nada.
	npc.mission_done = true
	game._set_run_tutorial_enabled(false, false)
	_check(not game.run_tutorial_enabled, "a opcao nao desligou")
	_check(npc.mission_done, "desligar nao pode desfazer a missao")
	_check(npc.parts == 3, "desligar nao pode mexer nas pecas")
	_check(not game._should_offer_run_tutorial(true), "a oferta continuou depois de desligar")

	print("PRIMEIRA_PARTIDA_OK checks=%d" % checks)
	quit(0)
