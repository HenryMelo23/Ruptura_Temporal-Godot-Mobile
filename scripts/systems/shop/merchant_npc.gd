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
## Guarda o que ele ja contou (nao repete historia) e o progresso da missao das
## pecas do teleportador, que estabiliza a fenda de vez.

const SAVE_PATH := "user://merchant_npc.cfg"
## Pecas do teleportador necessarias para ele estabilizar a fenda.
const PARTS_REQUIRED := 5
const PART_DROP_CHANCE := 0.34

var core: Node = null
var persist := true
## Marcos de historia ja contados (nao repetem).
var seen: Dictionary = {}
var parts := 0
var mission_offered := false
var mission_done := false
var visits := 0
var anim_time := 0.0
## Fala curta no balao sobre a cabeca dele.
var bubble := ""
var bubble_timer := 0.0


func configure(runtime_core: Node) -> void:
	core = runtime_core
	var loop = Engine.get_main_loop()
	if loop != null and loop.get_script() != null:
		persist = false
	_load()


## "Primeira partida": ele volta a nunca ter visto a Geovana. Apaga a historia
## contada, as visitas e o progresso das pecas, senao o testador encontraria um
## Mercador intimo e uma fenda ja estabilizada logo na primeira entrada.
func forget_story() -> void:
	seen.clear()
	visits = 0
	parts = 0
	mission_offered = false
	mission_done = false
	bubble = ""
	bubble_timer = 0.0
	_save()


func mission_complete() -> bool:
	return mission_done


func parts_missing() -> int:
	return maxi(0, PARTS_REQUIRED - parts)


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
		dialogue.start([
			{"who": "mercador", "text": "Escuta aqui. Eu andei pensando, e pensar me dá fome, então vai ser rápido."},
			{"who": "mercador", "text": "Quando a geringonça travou, ela não travou limpa. Ela se abriu no meio e espalhou as tripas na SUA linha do tempo. Peças do núcleo, as que mantêm a porta no prumo."},
			{"who": "geovana", "text": "E onde elas foram parar?", "mood": "desconfiada"},
			{"who": "mercador", "text": "Dentro do que havia de maior por perto. Essas criaturas grandes que te perseguem engoliram as minhas peças achando que era comida. Não era. Mas desceu.", "mood": "triste"},
			{"who": "mercador", "text": "São %d. Eu preciso das %d. Com elas eu paro de deixar a porta escolher sozinha e passo a mirar onde ela abre." % [PARTS_REQUIRED, PARTS_REQUIRED], "mood": "triste"},
			{"who": "geovana", "text": "Então vá buscar.", "mood": "decidida"},
			{"who": "mercador", "text": "Ah, querida. Se eu pudesse eu já teria ido, com chapéu e tudo."},
			{"who": "mercador", "text": "Eu não atravesso. Eu abro. São ofícios diferentes. O que me segura inteiro aqui dentro é justamente estar aqui dentro - se eu passo pra sua linha, o tempo de vocês me pega e eu viro pó em três segundos. Já vi acontecer com um primo."},
			{"who": "mercador", "text": "Você, não. Você já vive lá. Pra você é só mais um bicho grande pra derrubar."},
			{"who": "mercador", "text": "Me traz as %d peças e eu te dou o que eu não dou pra ninguém: a porta no prumo." % PARTS_REQUIRED},
			{"who": "mercador", "text": "Sem tremor. Sem contagem. Sem a fenda sacudindo o seu bolso na saída. Você entra, senta, escolhe no seu tempo e toma um chá."},
			{"who": "mercador", "text": "E eu passo a abrir pra você de propósito, toda vez que você juntar essência. Cliente boa a gente busca em casa."},
		])
		return
	_ambient_line()


## Falas curtas que podem repetir, no balao sobre a cabeca dele.
func _ambient_line() -> void:
	var lines: Array[String] = []
	if mission_done:
		lines = [
			"A casa é sua. Olha com os olhos, compra com a essência.",
			"Teleportador consertado. Quase. Setenta por cento.",
			"Sem pressa hoje. Hoje eu sou um anfitrião.",
			"Bússola, pra você. O nome completo cansa.",
		]
	elif mission_offered and parts > 0:
		lines = [
			"%d de %d peças. Vai indo." % [parts, PARTS_REQUIRED],
			"Faltam %d. Não me decepciona." % parts_missing(),
			"Bicho grande, barriga cheia. É ali que está a minha peça.",
		]
	else:
		lines = [
			"Olha o estoque, olha o estoque!",
			"Esse aqui saiu de uma dimensão que não existe mais. Coisa fina.",
			"Rapidinho, rapidinho. A fenda não é paciente.",
			"Não repara na bagunça. A oficina é a minha cabeça.",
			"Quintiliano Bussolaro. Anota aí, vai que fica famoso.",
			"A porta abre quando quer. Eu só varro o chão.",
		]
	say(String(lines[core.rng.randi_range(0, lines.size() - 1)]))


# ================================================================ missao
## Inimigo extraordinario derrubado: chance de largar uma peca.
func on_extraordinary_killed(pos: Vector2) -> void:
	if not mission_offered or mission_done or core == null:
		return
	if parts >= PARTS_REQUIRED or core.rng.randf() > PART_DROP_CHANCE:
		return
	parts += 1
	_save()
	core._add_text("PEÇA DO TELEPORTADOR %d/%d" % [parts, PARTS_REQUIRED], pos + Vector2(-120, -84), Color(1.0, 0.86, 0.3), 2.2, 20)
	core._spawn_radial_particles(pos, Color(1.0, 0.82, 0.34), 18)


## Chamado quando ela chega na dimensao com as pecas na mao.
func on_dimension_entered(_confiscated: int) -> void:
	if mission_done or not mission_offered or parts < PARTS_REQUIRED:
		return
	mission_done = true
	seen["mission_done"] = true
	_save()
	if not narrative_enabled():
		return
	core._dialogue().start([
		{"who": "mercador", "text": "Não acredito. VOCÊ ACHOU TODAS.", "mood": "animado"},
		{"who": "mercador", "text": "Me dá aqui. Calma. CALMA! Isso aqui é mais velho que a sua espécie.", "mood": "preocupado"},
		{"who": "mercador", "text": "...", "mood": "triste"},
		{"who": "mercador", "text": "Pronto. Está no prumo."},
		{"who": "geovana", "text": "Acabou o tremor?", "mood": "preocupada"},
		{"who": "mercador", "text": "Acabou a sorte. A porta parou de decidir sozinha. Agora quem decide sou eu, e eu decido abrir pra você.", "mood": "animado"},
		{"who": "mercador", "text": "Juntou essência lá fora, eu abro. Você entra, senta, escolhe sem ninguém no seu cangote. Pode ficar o tempo que quiser."},
		{"who": "mercador", "text": "E o seu troco fica no seu bolso. Eu já te roubei o suficiente pra uma vida."},
		{"who": "mercador", "text": "Agora senta aí que eu vou fazer um chá. Faz séculos que eu não faço chá pra duas xícaras."},
	])


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
	parts = int(cfg.get_value("mission", "parts", 0))
	mission_offered = bool(cfg.get_value("mission", "offered", false))
	mission_done = bool(cfg.get_value("mission", "done", false))
	visits = int(cfg.get_value("mission", "visits", 0))
	for key in Array(cfg.get_value("story", "seen", [])):
		seen[String(key)] = true


func _save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("mission", "parts", parts)
	cfg.set_value("mission", "offered", mission_offered)
	cfg.set_value("mission", "done", mission_done)
	cfg.set_value("mission", "visits", visits)
	cfg.set_value("story", "seen", seen.keys())
	cfg.save(SAVE_PATH)
