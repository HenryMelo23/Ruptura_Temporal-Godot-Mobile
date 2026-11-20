class_name RTMerchantNpc
extends RefCounted

## QUINTILIANO BUSSOLARO, "o Bussola": mercador itinerante de outra especie,
## meio humanoide, bigode enorme. O teleportador dele e loja, carro e casa ao
## mesmo tempo - e quebrou no meio de um salto, bem na hora da Ruptura. Desde
## entao a geringonca vive meio aberta e vaza: a "fenda" que a Geovana
## atravessa e o defeito dele, nao um poder dela.
##
## PERSONALIDADE: falastrao, simpatico, vendedor de feira cosmico. Desvia de
## pergunta incomoda com charme, nunca com grosseria. Tem orgulho ferido do
## nome completo e finge que todo mundo deveria conhece-lo. E genuinamente
## carente de companhia: ha muito tempo so caem coisas mortas ou raivosas na
## oficina dele, e a Geovana e a primeira que chega viva, de pe e com dinheiro.
##
## Guarda o que ele ja contou (nao repete historia). A missao de estabilizar a
## fenda (salvar as capsulas da Barganha) vale SO PARA A RUN: ao morrer ou
## vencer, a porta volta a tremer e a historia da missao recomeca. Depois de
## estabilizada, o balcao oferece encomendas (RTMerchantMissionController),
## unica fonte da carta Moeda Estavel.

const SAVE_PATH := "user://merchant_npc.cfg"
## Capsulas da Barganha salvas (sobreviventes ao fim do evento) para estabilizar
## a fenda. Antes eram 5 pecas largadas por inimigos extraordinarios.
const CAPSULES_REQUIRED := 10
## A partir desta partida (contando as novas, nao as retomadas) o Bussola
## pula a explicacao de como estabilizar a fenda: so lembra no balao.
const SKIP_MISSION_TALK_FROM_RUN := 5

var core: Node = null
var persist := true
## Marcos de historia ja contados (nao repetem).
var seen: Dictionary = {}
var capsules_saved := 0
var mission_offered := false
## Partidas novas ja iniciadas (persistente; retomar partida nao conta).
var runs_started := 0
var mission_done := false
var visits := 0
var anim_time := 0.0
## Fala curta no balao sobre a cabeca dele.
var bubble := ""
var bubble_timer := 0.0
## Encomendas que valem Moeda Estavel (so depois da fenda estabilizada).
var missions := RTMerchantMissionController.new()
## Encomenda sorteada no balcao esperando o "aceito".
var _pending_offer: Dictionary = {}


func configure(runtime_core: Node) -> void:
	core = runtime_core
	missions.configure(runtime_core)
	var loop = Engine.get_main_loop()
	if loop != null and loop.get_script() != null:
		persist = false
	_load()


## Nova run: a fenda volta a ser instavel e a missao das capsulas recomeca.
## O que ele ja contou (historia, visitas) continua lembrado.
func begin_run(new_run: bool = true) -> void:
	if new_run:
		runs_started += 1
	capsules_saved = 0
	mission_offered = false
	mission_done = false
	seen.erase("mission_done")
	_pending_offer.clear()
	missions.reset_run()
	_save()


## Estado da run que entra no snapshot da oficina (retomar partida).
func run_state() -> Dictionary:
	return {"capsules": capsules_saved, "offered": mission_offered, "done": mission_done, "missions": missions.save_state()}


func load_run_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	capsules_saved = int(data.get("capsules", 0))
	mission_offered = bool(data.get("offered", false))
	mission_done = bool(data.get("done", false))
	missions.load_state(Dictionary(data.get("missions", {})))


## "Primeira partida": ele volta a nunca ter visto a Geovana. Apaga a historia
## contada, as visitas e o progresso das pecas, senao o testador encontraria um
## Mercador intimo e uma fenda ja estabilizada logo na primeira entrada.
func forget_story() -> void:
	seen.clear()
	visits = 0
	runs_started = 0
	capsules_saved = 0
	mission_offered = false
	mission_done = false
	bubble = ""
	bubble_timer = 0.0
	_save()


func mission_complete() -> bool:
	return mission_done


func mission_active() -> bool:
	return mission_offered and not mission_done


func capsules_missing() -> int:
	return maxi(0, CAPSULES_REQUIRED - capsules_saved)


func update(delta: float) -> void:
	anim_time += delta
	bubble_timer = maxf(0.0, bubble_timer - delta)
	if bubble_timer <= 0.0:
		bubble = ""


func narrative_enabled() -> bool:
	return core != null and not bool(core.is_multiplayer) and not bool(core.dedicated_server_mode)


func silence() -> void:
	bubble = ""
	bubble_timer = 0.0


func say(text: String, seconds: float = 3.4) -> void:
	if not narrative_enabled():
		silence()
		return
	bubble = text
	bubble_timer = seconds


# ================================================================ historia
## Primeira coisa que ele faz quando ela chega perto.
func greet(dimension) -> void:
	if not narrative_enabled():
		return
	visits += 1
	var dialogue = core._dialogue()
	if not seen.has("intro"):
		seen["intro"] = true
		_save()
		dialogue.start([
			{"who": "mercador", "text": "Opa! Opa opa opa. Não encosta nis... espera.", "mood": "preocupado"},
			{"who": "mercador", "text": "Você está de pé."},
			{"who": "geovana", "text": "É...?", "mood": "surpresa"},
			{"who": "mercador", "text": "Querida, faz tempo demais que só cai coisa morta ou coisa com fome aqui dentro. Você está de pé E está me ouvindo. Isso é uma festa.", "mood": "animado"},
			{"who": "mercador", "text": "Quintiliano Bussolaro, terceiro da linhagem, mercador de sete camadas. Pode me chamar de Bússola. Todo mundo chama.", "mood": "animado"},
			{"who": "geovana", "text": "Onde eu estou?", "mood": "surpresa"},
			{"who": "mercador", "text": "Dentro da minha loja. Que também é o meu carro. Que também é a minha casa. Esse troço no meio da sala é um teleportador - MEU teleportador."},
			{"who": "mercador", "text": "Eu estava no meio de um salto quando o tempo de vocês rasgou. Sabe quando alguém puxa a toalha com a mesa posta? Então. Eu era a mesa."},
			{"who": "mercador", "text": "A geringonça travou meio aberta. Nunca fechou direito desde aquele dia. E porta meio aberta, querida, vaza."},
			{"who": "geovana", "text": "Vaza pra onde?", "mood": "desconfiada"},
			{"who": "mercador", "text": "Pra onde você estiver. Ela se enche sozinha com a energia que você levanta correndo lá fora, e quando enche... PLOC. Abre do seu lado e te chupa pra cá."},
			{"who": "mercador", "text": "Eu não escolho a hora. Eu não escolho o lugar. Eu só varro o chão e espero. Hoje caiu você."},
			{"who": "mercador", "text": "Enfim! Enquanto eu não conserto, eu vendo. Você traz essência dessas criaturas, eu troco por coisa útil.", "mood": "animado"},
			{"who": "mercador", "text": "Só uma coisinha, e repare que eu estou avisando bonitinho: a fenda está instável. Enquanto a porta não estiver no prumo, ela se fecha sozinha do mesmo jeito que abre.", "mood": "preocupado"},
			{"who": "mercador", "text": "Então escolhe rápido. Rápido mesmo.", "mood": "preocupado"},
		])
		return
	# Primeira vez que ela chega na loja vinda da Cripta de Seda: ele conhece o
	# lugar, explica por que la rende mais (sem pop-up) e da as dicas de
	# sobrevivencia como fofoca de mercador.
	if int(core.current_phase) == RTCriptaController.PHASE and not seen.has("cripta"):
		seen["cripta"] = true
		_save()
		dialogue.start(CRIPTA_TALK.duplicate(true))  # const = somente leitura; o dialogo limpa as linhas
		return
	if visits >= 2 and not seen.has("stolen") and dimension != null and int(dimension.confiscated) > 0:
		seen["stolen"] = true
		_save()
		dialogue.start([
			{"who": "geovana", "text": "Você ficou com a minha essência.", "mood": "irritada"},
			{"who": "mercador", "text": "Eu? Não, não, não. Repara bem no que aconteceu.", "mood": "triste"},
			{"who": "mercador", "text": "Quando a porta se fecha mal fechada, ela dá um tranco. Puxa o que está solto. Você foi cuspida pra fora e o que estava no seu bolso ficou.", "mood": "triste"},
			{"who": "mercador", "text": "E caiu. Bem aqui. No meu balcão. Uma tragédia.", "mood": "triste"},
			{"who": "geovana", "text": "Devolve.", "mood": "irritada"},
			{"who": "mercador", "text": "Querida, se eu devolvesse tudo que essa porta derruba no meu chão eu já tinha fechado as portas. As que ainda fecham, digo."},
			{"who": "mercador", "text": "Achado não é roubado."},
			{"who": "geovana", "text": "...", "mood": "desconfiada"},
			{"who": "mercador", "text": "Olha. Vou ser honesto, coisa que eu faço pouco e com dor."},
			{"who": "mercador", "text": "Você é a melhor coisa que me aconteceu em muito tempo. Você volta, você paga, você não tenta me comer. Sabe quantos clientes assim eu tive este século? Um. E é você.", "mood": "animado"},
			{"who": "mercador", "text": "Então eu não quero te roubar. Eu quero te manter. Há uma diferença enorme e ela é o meu lucro."},
			{"who": "mercador", "text": "O problema não é a minha índole, é a porta. Enquanto ela abrir e fechar na hora que quiser, ela vai continuar sacudindo o seu bolso toda vez. E eu vou continuar com cara de culpado."},
		])
		return
	if not mission_offered and visits >= 2:
		mission_offered = true
		_save()
		if runs_started >= SKIP_MISSION_TALK_FROM_RUN:
			# Veterana: ela ja sabe a historia das capsulas; so o lembrete.
			say("Cápsulas de novo, querida: %d inteiras e a porta fica no prumo." % CAPSULES_REQUIRED, 4.2)
			return
		dialogue.start([
			{"who": "mercador", "text": "Escuta aqui. Eu andei pensando, e pensar me dá fome, então vai ser rápido."},
			{"who": "mercador", "text": "Quando a geringonça travou, ela não travou limpa. De vez em quando ela cospe uma cápsula de carga na SUA linha do tempo. Aquelas douradas que caem do céu, sabe?"},
			{"who": "geovana", "text": "As da barganha? Os bichos vivem quebrando elas.", "mood": "desconfiada"},
			{"who": "mercador", "text": "Pois é. Cada uma que quebra, a porta treme mais. Cada uma que chega inteira, eu puxo de volta e calibro um pouquinho.", "mood": "triste"},
			{"who": "mercador", "text": "Me salva %d. Inteiras, até o fim da queda. Com elas eu paro de deixar a porta escolher sozinha e passo a mirar onde ela abre." % CAPSULES_REQUIRED, "mood": "triste"},
			{"who": "geovana", "text": "Então vá buscar.", "mood": "decidida"},
			{"who": "mercador", "text": "Ah, querida. Se eu pudesse eu já teria ido, com chapéu e tudo."},
			{"who": "mercador", "text": "Eu não atravesso. Eu abro. São ofícios diferentes. O que me segura inteiro aqui dentro é justamente estar aqui dentro - se eu passo pra sua linha, o tempo de vocês me pega e eu viro pó em três segundos. Já vi acontecer com um primo."},
			{"who": "mercador", "text": "Você, não. Você já vive lá. Pra você é só ficar perto delas e espantar os bichos."},
			{"who": "mercador", "text": "Salva %d cápsulas e eu te dou o que eu não dou pra ninguém: a porta no prumo. O placar fica aqui na oficina, eu anoto tudo." % CAPSULES_REQUIRED},
			{"who": "mercador", "text": "Sem tremor. Sem contagem. Sem a fenda sacudindo o seu bolso na saída. Você entra, senta, escolhe no seu tempo e toma um chá."},
			{"who": "mercador", "text": "E eu passo a abrir pra você de propósito, toda vez que você juntar essência. Cliente boa a gente busca em casa."},
		])
		return
	_ambient_line()


# ================================================================ balcao
const CHOICE_BUY := "buy"
const CHOICE_ASK := "ask"
const CHOICE_LEAVE := "leave"
const CHOICE_MISSION := "mission"
const CHOICE_ACCEPT := "accept"
const CHOICE_DECLINE := "decline"
const CHOICE_DONATE := "donate"
const TOPIC_RUPTURE := "rupture"
const TOPIC_ABOUT := "about"
const TOPIC_BACK := "back"

## Dimensao atual da oficina (para abrir a bancada depois da escolha).
var _counter_dimension = null


## Ela encostou no balcao: comprar ou perguntar. Fora da historia (sala
## multiplayer) o balcao abre direto, como antes.
func open_menu(dimension) -> void:
	_counter_dimension = dimension
	if not narrative_enabled():
		_buy()
		return
	var openers: Array[String] = [
		"E aí, querida? Vai levar alguma coisa ou vai só alugar o meu ouvido?",
		"Balcão aberto! Pergunta é de graça. Por enquanto.",
		"Olha quem voltou. Compra, pergunta ou só veio me ver? Pode falar, eu aguento.",
	]
	core._dialogue().start([_menu_line(String(openers[core.rng.randi_range(0, openers.size() - 1)]))], _on_menu_choice)


func _menu_line(text: String, mood: String = "animado") -> Dictionary:
	var choices: Array = [
		{"label": "COMPRAR", "id": CHOICE_BUY},
		{"label": "PERGUNTAR", "id": CHOICE_ASK},
	]
	# Encomendas so com a porta no prumo nesta run.
	if mission_done:
		choices.append({"label": "ENTREGAR ENCOMENDA" if missions.ready_to_turn_in() else "ENCOMENDAS", "id": CHOICE_MISSION})
	choices.append({"label": "NADA AGORA", "id": CHOICE_LEAVE})
	# "rift_clock": so o menu de compra gasta o tempo da fenda; perguntas e
	# historia pausam o relogio.
	return {"who": "mercador", "text": text, "mood": mood, "choices": choices, "rift_clock": true}


func _on_menu_choice(id: String) -> void:
	match id:
		CHOICE_BUY:
			_buy()
		CHOICE_MISSION:
			_mission_talk()
		CHOICE_ASK:
			core._dialogue().start([{"who": "mercador", "text": "Pergunta. Velho adora pergunta: é a única hora que alguém escuta a gente inteiro.", "mood": "animado", "choices": [
				{"label": "IMPULSO, FRAGMENTO E COLAPSO", "id": TOPIC_RUPTURE},
				{"label": "QUEM É VOCÊ, AFINAL?", "id": TOPIC_ABOUT},
				{"label": "VOLTAR", "id": TOPIC_BACK},
			]}], _on_topic)
		_:
			say("Tá bom, tá bom. Olhar também é freguesia.", 2.6)


func _on_topic(id: String) -> void:
	var lines: Array = []
	match id:
		TOPIC_RUPTURE:
			lines = rupture_talk(seen.has(TOPIC_RUPTURE))
			if not seen.has(TOPIC_RUPTURE):
				seen[TOPIC_RUPTURE] = true
				_save()
		TOPIC_ABOUT:
			lines = ABOUT_TALK.duplicate(true)
		_:
			core._dialogue().start([_menu_line("Mudou de ideia? Acontece nas melhores famílias. Na minha, acontecia toda terça.")], _on_menu_choice)
			return
	lines.append(_menu_line("Mais alguma coisa? O balcão ainda está aberto, e eu também."))
	core._dialogue().start(lines, _on_menu_choice)


# ================================================================ encomendas
func _mission_talk() -> void:
	var dialogue = core._dialogue()
	if missions.ready_to_turn_in():
		missions.turn_in()
		dialogue.start([
			{"who": "mercador", "text": "Isso! Exatamente isso. Você é a melhor freguesa de sete camadas.", "mood": "animado"},
			{"who": "mercador", "text": "Toma. Moeda Estável: com ela a minha tabela não sobe tanto pra você. Coisa que eu não dou pra ninguém, e só dou por serviço prestado."},
			_menu_line("Mais alguma coisa? Tenho mais encomenda, se você tiver mais fôlego."),
		], _on_menu_choice)
		return
	if missions.active():
		if missions.kind() == RTMerchantMissionController.KIND_DONATE:
			var card_name: String = String(missions.mission.get("card_name", ""))
			var has_card: bool = int(core._card_count_by_id(String(missions.mission.get("card_id", "")))) > 0
			var choices: Array = []
			if has_card:
				choices.append({"label": "DOAR %s" % card_name.to_upper(), "id": CHOICE_DONATE})
			choices.append({"label": "AINDA NÃO", "id": CHOICE_DECLINE})
			dialogue.start([{"who": "mercador", "text": "E aquela %s? Eu ainda quero, viu. Coleção é coleção." % card_name, "mood": "animado", "choices": choices}], _on_mission_choice)
			return
		dialogue.start([
			{"who": "mercador", "text": "A encomenda ainda está aberta: %s." % missions.objective_text().to_lower(), "mood": "preocupado"},
			_menu_line("Enquanto isso, o balcão está aberto."),
		], _on_menu_choice)
		return
	if not missions.reward_available():
		dialogue.start([
			{"who": "mercador", "text": "Moeda Estável, querida? Acabou. Você levou o cofre inteiro. Eu estou orgulhoso e falido.", "mood": "triste"},
			_menu_line("Mas cartas eu ainda tenho. Sempre tenho."),
		], _on_menu_choice)
		return
	var world: Vector2 = Vector2(core.WORLD_SIZE)
	var origin: Vector2 = Vector2(core.player_pos)
	if _counter_dimension != null and not Dictionary(_counter_dimension.saved).is_empty():
		world = Vector2(_counter_dimension.saved.get("world", world))
		origin = Vector2(_counter_dimension.saved.get("player_pos", origin))
	_pending_offer = missions.offer(world, origin)
	dialogue.start([{"who": "mercador", "text": _offer_text(_pending_offer), "mood": "animado", "choices": [
		{"label": "ACEITO", "id": CHOICE_ACCEPT},
		{"label": "AGORA NÃO", "id": CHOICE_DECLINE},
	]}], _on_mission_choice)


func _offer_text(offered: Dictionary) -> String:
	match String(offered.get("kind", "")):
		RTMerchantMissionController.KIND_ZONE:
			return "Tem um ninho de bicho bem onde a minha porta encosta lá fora. Eu marquei no seu mapa. Derruba %d dentro da marca e eu te pago em Moeda Estável." % int(offered.get("target", 0))
		RTMerchantMissionController.KIND_DELIVER:
			return "Os bichos andam engolindo engrenagem do meu teleportador. Quando derrubar um, olha o chão. Me traz %d e eu te pago em Moeda Estável." % int(offered.get("target", 0))
		RTMerchantMissionController.KIND_DONATE:
			return "Eu coleciono, sabe? Me falta uma %s. Me dá uma das suas e eu te pago em Moeda Estável. Troca justa, palavra de mercador." % String(offered.get("card_name", ""))
	return "Tenho um servicinho pra você."


func _on_mission_choice(id: String) -> void:
	match id:
		CHOICE_ACCEPT:
			missions.accept(_pending_offer)
			_pending_offer.clear()
			if missions.kind() == RTMerchantMissionController.KIND_DONATE:
				_mission_talk()
				return
			core._dialogue().start([_menu_line("Combinado! Eu anoto aqui. Volta quando terminar.")], _on_menu_choice)
		CHOICE_DONATE:
			if missions.donate():
				_mission_talk()
			else:
				core._dialogue().start([_menu_line("Ué, cadê? Sem a carta não tem troca, querida.", "preocupado")], _on_menu_choice)
		_:
			_pending_offer.clear()
			core._dialogue().start([_menu_line("Sem pressa. A encomenda espera. Eu é que não.")], _on_menu_choice)


func _buy() -> void:
	if _counter_dimension != null and _counter_dimension.has_method("_open_counter"):
		_counter_dimension._open_counter()


## O Bussola explica o Fragmento Instavel, o Impulso de Ruptura e o Colapso
## Dimensional como velho que ja viu muita dimensao morrer. Os numeros vem do
## owner da mecanica, para a fala nunca mentir sobre o balanceamento.
static func rupture_talk(retold: bool) -> Array:
	var R := RTDimensionRuptureController
	var fast := int(R.FAST_WINDOW_SECONDS)
	var standard := int(R.STANDARD_WINDOW_SECONDS)
	var total := int(R.COLLAPSE_TOTAL_SECONDS)
	var escape := int(R.EMERGENCY_ESCAPE_SECONDS)
	if retold:
		return [
			{"who": "mercador", "text": "De novo? Tudo bem, velho repete mesmo. Resumo de feira, presta atenção:", "mood": "animado"},
			{"who": "mercador", "text": "Derrubou o que segura a dimensão, nasce o Fragmento Instável. Até %d segundos, travessia perfeita: o Impulso sobe e a próxima carta vem melhor." % fast},
			{"who": "mercador", "text": "Até %d, travessia estável: o Impulso fica e ainda sai um agradinho. Passou disso, colapso: o fragmento enfraquece e o Impulso vai embora." % standard, "mood": "preocupado"},
			{"who": "mercador", "text": "Aos %d começa a emergência. Você tem %d segundos pra achar uma ruptura, senão a dimensão te cospe onde ela quiser, tonta e sem Impulso." % [total, escape], "mood": "preocupado"},
			{"who": "geovana", "text": "Rápido é melhor. Já entendi.", "mood": "decidida"},
			{"who": "mercador", "text": "Rápido é melhor. Afobado é pior. Tem diferença, e ela costuma morder.", "mood": "preocupado"},
		]
	return [
		{"who": "geovana", "text": "Quando eu derrubo o maior bicho de um lugar, tudo começa a tremer. E tem um pedaço de luz que fica me puxando. O que é aquilo?", "mood": "desconfiada"},
		{"who": "mercador", "text": "Aaah. Senta. Quer dizer, não senta, que a fenda não espera. Mas finge que sentou.", "mood": "animado"},
		{"who": "mercador", "text": "Eu sou velho, querida. Velho vivido. Já vi mais dimensão nascer e morrer do que você viu aniversário. Abrir porta é o meu ofício há sete camadas."},
		{"who": "mercador", "text": "Toda dimensão que a sua Ruptura arrancou do lugar ficou presa por um prego. Um bicho grande, um guardião, uma coisa que segura o pano esticado."},
		{"who": "mercador", "text": "Você derruba o prego e o pano solta. O que sobra daquele lugar vira um caco vivo, querendo ir embora. Isso é o Fragmento Instável.", "mood": "preocupado"},
		{"who": "geovana", "text": "E por que ele vem atrás de mim?", "mood": "surpresa"},
		{"who": "mercador", "text": "Porque você é a única coisa ali dentro que ainda sabe sair. Ele não é seu, nem de ninguém da sua turma. É do grupo inteiro. Não cabe no bolso, nem no meu."},
		{"who": "mercador", "text": "Agora, a parte que me interessa, que é a parte do lucro.", "mood": "animado"},
		{"who": "mercador", "text": "Se você atravessa logo, nos primeiros %d segundos, o caco vai junto com a correnteza. Que nem pular num trem andando: o embalo te leva." % fast, "mood": "animado"},
		{"who": "mercador", "text": "Esse embalo é o Impulso de Ruptura. A próxima dimensão te recebe com ele, e a primeira carta que ela soltar pra você vem melhor. Não vem mais, vem MELHOR.", "mood": "animado"},
		{"who": "mercador", "text": "É feira, querida. Quem chega cedo leva a fruta boa. Quem chega tarde leva a mesma quantidade, só que machucada."},
		{"who": "geovana", "text": "E se eu fizer isso de novo, e de novo?", "mood": "decidida"},
		{"who": "mercador", "text": "Aí o embalo empilha. Impulso um, dois, três, quatro. Quatro é o teto: acima disso nem o corpo de vocês nem a minha porta aguentam o tranco.", "mood": "animado"},
		{"who": "mercador", "text": "Se você enrola um pouco, até uns %d segundos, a travessia ainda sai estável. Você não perde o embalo, só não ganha mais. E ainda leva um agradinho pequeno." % standard},
		{"who": "mercador", "text": "Depois disso, a dimensão sem prego começa a dobrar em cima de si mesma. Racha o chão, o ar fica vermelho, a luz pisca. Isso é o Colapso Dimensional.", "mood": "preocupado"},
		{"who": "mercador", "text": "O caco enfraquece. Você ainda pode atravessar, mas o Impulso morre ali. Zero. Volta pro começo da fila.", "mood": "triste"},
		{"who": "geovana", "text": "E se eu ficar? Tem muita essência lá dentro.", "mood": "desconfiada"},
		{"who": "mercador", "text": "Ganância é uma coisa linda. Eu vivo dela. Mas ganância com relógio, querida, é outro bicho.", "mood": "preocupado"},
		{"who": "mercador", "text": "Aos %d segundos começa a emergência. A dimensão grita, e você tem %d segundos pra achar uma ruptura e pular." % [total, escape], "mood": "preocupado"},
		{"who": "mercador", "text": "Se não achar, ela te cospe. Todo mundo junto, pra onde ela quiser. Ninguém fica pra trás, mas ninguém escolhe o endereço.", "mood": "preocupado"},
		{"who": "mercador", "text": "Não te tira o que é seu, e ainda te deixa de pé, com metade do fôlego no mínimo. Mas você chega tonta, lenta e sem embalo nenhum.", "mood": "triste"},
		{"who": "mercador", "text": "Eu já vi gente que ficou só mais um pouquinho. Mais um pouquinho virou costume, e o costume virou poeira. Eu vendia óleo pra um desses. Bom freguês. Pagava em dia.", "mood": "triste"},
		{"who": "geovana", "text": "Então é isso: derrubou, corre.", "mood": "decidida"},
		{"who": "mercador", "text": "Derrubou, olha em volta, respira, e corre. Nessa ordem. Rápido é melhor. Afobado é pior.", "mood": "preocupado"},
		{"who": "mercador", "text": "Toma cuidado, tá? Não é sermão de velho. É que cliente boa é difícil de achar, e você é a única que eu tenho.", "mood": "triste"},
	]


## Pergunta curta sobre ele: charme de vendedor, orgulho do nome e um fundo
## de solidao que ele disfarca com piada.
const ABOUT_TALK := [
	{"who": "mercador", "text": "Quem sou EU? Querida, isso ofende. Quintiliano Bussolaro, terceiro da linhagem, mercador de sete camadas!", "mood": "animado"},
	{"who": "mercador", "text": "Atravessei feira em lugar que não tem nome, vendi lamparina pra quem não tinha olho e guarda-chuva pra quem morava debaixo d'água."},
	{"who": "geovana", "text": "E agora está preso numa oficina.", "mood": "desconfiada"},
	{"who": "mercador", "text": "Preso não. Estacionado. Por tempo indeterminado. Com vista pro nada.", "mood": "triste"},
	{"who": "mercador", "text": "Mas olha pelo lado bom: tenho você. E você paga em essência, que é a moeda mais honesta que existe. Ninguém falsifica medo.", "mood": "animado"},
]


## A Cripta de Seda contada pelo Bussola: ele vendia oleo de lamparina numa feira
## que existia la embaixo antes da Ruptura. Explica por que la a essencia vale
## mais e ensina, como quem conta fofoca, o que fazer quando as aranhas prendem.
const CRIPTA_TALK := [
	{"who": "mercador", "text": "Espera. Espera, espera. Esse cheiro... cera velha, pedra molhada e medo.", "mood": "preocupado"},
	{"who": "mercador", "text": "Você veio da Catedral. A Cripta de Seda.", "mood": "preocupado"},
	{"who": "geovana", "text": "Você conhece aquele lugar?", "mood": "surpresa"},
	{"who": "mercador", "text": "Conheço? Querida, eu VENDI ali. Antes da Ruptura aquilo era a Feira das Oito Velas. As tecelãs vendiam seda, eu vendia óleo de lamparina."},
	{"who": "mercador", "text": "Aquelas lamparinas que ainda acendem sozinhas? Óleo meu. Nunca me pagaram. Calote de oitocentos anos.", "mood": "triste"},
	{"who": "mercador", "text": "Aí o tempo de vocês rasgou e a freguesa mais antiga, a dos oito olhos, decidiu que a feira inteira era a despensa dela.", "mood": "triste"},
	{"who": "geovana", "text": "E por que você está me contando isso agora?", "mood": "desconfiada"},
	{"who": "mercador", "text": "Porque você voltou com o bolso pesado. Repara.", "mood": "animado"},
	{"who": "mercador", "text": "Essência que nasce do medo é mais densa. Lá embaixo tudo que você derruba rende quase o dobro. Bicho, eco, a própria Matriarca, se você for maluca.", "mood": "animado"},
	{"who": "mercador", "text": "É por isso que nenhum mercador decente recusa aquele lugar. E é por isso que não sobrou nenhum mercador decente.", "mood": "preocupado"},
	{"who": "geovana", "text": "Elas quase não me machucam. Só me seguram.", "mood": "preocupada"},
	{"who": "mercador", "text": "Exato. Ali ninguém morde pra matar. Morde pra GUARDAR. Comida fresca dura mais.", "mood": "preocupado"},
	{"who": "mercador", "text": "Uma joga um novelo grudento e sai passeando com você enquanto as primas comem. A armadeira prefere embrulhar pra viagem, num casulo.", "mood": "preocupado"},
	{"who": "mercador", "text": "Se te pegarem: atira, atira, atira. Seda cede com tremedeira. Quem fica parada vira encomenda.", "mood": "animado"},
	{"who": "mercador", "text": "Gosto de moeda na boca é veneno. Corre pra luz das minhas lamparinas, ela puxa o veneno pra fora. Pelo menos isso o meu óleo ainda faz de graça."},
	{"who": "mercador", "text": "E aqueles brilhinhos azuis no chão... pega. Te deixam enxergar mais longe, e quanto mais seguido você pega, mais longe vai."},
	{"who": "mercador", "text": "Só olha duas vezes antes de agachar. Tem bicho lá embaixo que aprendeu a brilhar igual.", "mood": "preocupado"},
	{"who": "geovana", "text": "Mais pontos, mais perigo. Entendi.", "mood": "decidida"},
	{"who": "mercador", "text": "Entendeu a parte do lucro. A parte do perigo a gente só entende uma vez. Vai com cuidado, tá? Cliente boa é difícil de achar.", "mood": "triste"},
]


## Falas curtas que podem repetir, no balao sobre a cabeca dele.
func _ambient_line() -> void:
	var lines: Array[String] = []
	if int(core.current_phase) == RTCriptaController.PHASE and seen.has("cripta"):
		lines = [
			"Lá embaixo vale o dobro. E custa o dobro.",
			"Laçou? Atira até a seda ceder.",
			"Gosto de moeda na boca? Corre pra luz.",
			"Nem todo brilho é eco, querida.",
			"Manda um oi pra Matriarca. Ou melhor, não manda.",
		]
		say(String(lines[core.rng.randi_range(0, lines.size() - 1)]))
		return
	if mission_done:
		lines = [
			"A casa é sua. Olha com os olhos, compra com a essência.",
			"Teleportador consertado. Quase. Setenta por cento.",
			"Sem pressa hoje. Hoje eu sou um anfitrião.",
			"Bússola, pra você. O nome completo cansa.",
		]
	elif mission_offered and capsules_saved > 0:
		lines = [
			"%d de %d cápsulas. Vai indo." % [capsules_saved, CAPSULES_REQUIRED],
			"Faltam %d. Não me decepciona." % capsules_missing(),
			"Caiu cápsula, fica perto. Os bichos adoram quebrar.",
		]
	else:
		lines = [
			"Olha o estoque, olha o estoque!",
			"Esse aqui saiu de uma dimensão que não existe mais. Coisa fina.",
			"Rapidinho, rapidinho. A fenda não é paciente.",
			"Não repara na bagunça. A oficina é a minha cabeça.",
			"Quintiliano Bussolaro. Anota aí, vai que fica famoso.",
			"A porta abre quando quer. Eu só varro o chão.",
			"Pergunta do Impulso, querida. Velho sabe coisa.",
		]
	say(String(lines[core.rng.randi_range(0, lines.size() - 1)]))


# ================================================================ missao
## Evento da Barganha terminou com `count` capsulas inteiras: soma no placar.
func on_capsules_saved(count: int, pos: Vector2) -> void:
	if not mission_active() or count <= 0 or core == null:
		return
	capsules_saved = mini(CAPSULES_REQUIRED, capsules_saved + count)
	_save()
	core._add_text("CÁPSULAS SALVAS %d/%d" % [capsules_saved, CAPSULES_REQUIRED], pos + Vector2(-120, -150), Color(1.0, 0.86, 0.3), 2.2, 20)
	core._spawn_radial_particles(pos, Color(1.0, 0.82, 0.34), 18)


## Chamado quando ela chega na dimensao com as capsulas salvas.
func on_dimension_entered(_confiscated: int) -> void:
	if mission_done or not mission_offered or capsules_saved < CAPSULES_REQUIRED:
		return
	mission_done = true
	seen["mission_done"] = true
	_save()
	if not narrative_enabled():
		return
	core._dialogue().start([
		{"who": "mercador", "text": "Não acredito. VOCÊ SALVOU TODAS.", "mood": "animado"},
		{"who": "mercador", "text": "Me dá aqui. Calma. CALMA! Isso aqui é mais velho que a sua espécie.", "mood": "preocupado"},
		{"who": "mercador", "text": "...", "mood": "triste"},
		{"who": "mercador", "text": "Pronto. Está no prumo."},
		{"who": "geovana", "text": "Acabou o tremor?", "mood": "preocupada"},
		{"who": "mercador", "text": "Acabou a sorte. A porta parou de decidir sozinha. Agora quem decide sou eu, e eu decido abrir pra você.", "mood": "animado"},
		{"who": "mercador", "text": "Juntou essência lá fora, eu abro. Você entra, senta, escolhe sem ninguém no seu cangote. Pode ficar o tempo que quiser."},
		{"who": "mercador", "text": "E o seu troco fica no seu bolso. Eu já te roubei o suficiente pra uma vida."},
		{"who": "mercador", "text": "Agora senta aí que eu vou fazer um chá. Faz séculos que eu não faço chá pra duas xícaras."},
	])


## Esbarrao (dela ou de uma caixa chutada) no corpo dele.
func complain_bump() -> void:
	var lines: Array[String] = [
		"Ei! Olha o estoque!",
		"Devagar, isso aí é mais velho que a sua espécie!",
		"Quebrou, pagou. Brincadeira. Mais ou menos.",
		"Opa! Equilíbrio de mercador, querida.",
	]
	say(lines[core.rng.randi_range(0, lines.size() - 1)], 2.2)


func on_player_expelled() -> void:
	if not narrative_enabled():
		return
	say("Volta sempre! E deixa a essência!", 3.0)


# ================================================================ save
func _load() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	# Capsulas e fenda estavel valem so para a run (begin_run/run_state).
	visits = int(cfg.get_value("mission", "visits", 0))
	runs_started = int(cfg.get_value("mission", "runs", 0))
	for key in Array(cfg.get_value("story", "seen", [])):
		if String(key) != "mission_done":
			seen[String(key)] = true


func _save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("mission", "visits", visits)
	cfg.set_value("mission", "runs", runs_started)
	cfg.set_value("story", "seen", seen.keys())
	cfg.save(SAVE_PATH)
