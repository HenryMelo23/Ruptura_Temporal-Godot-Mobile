class_name RTBossDnaMachine
extends RefCounted

## Maquina de fusao no canto da oficina do Mercador (Rede do Petro).
##
## - Primeira vez que ela encosta: o Bussola explica o que e e como usar.
## - Entrou na oficina com DNA novo: na primeira vez da run ele apresenta a
##   maquina; depois so lembra num balao.
## - Encostar de novo abre a tela de fusao (RTBossDnaFusionScreen).
## Em sala multiplayer nao ha historia: encostar abre a tela direto.

## Canto de baixo a esquerda da oficina (pe da maquina), longe da rota
## entrada -> balcao -> saida.
const POS := Vector2(338.0, 892.0)
const SOLID_RADIUS := 56.0
const USE_RADIUS := 104.0
const SEEN_KEY := "dna_machine"

const CHOICE_OPEN := "dna_open"
const CHOICE_LATER := "dna_later"

var core: Node = null
var armed := true


func configure(runtime_core: Node) -> void:
	core = runtime_core


func on_dimension_entered() -> void:
	armed = true


func dna() -> RTBossDnaController:
	return core._merchant_dimension().dna


## Chamado pela oficina quando o mundo esta livre (modo game, sem fala).
func update(entry_age: float) -> void:
	var npc: RTMerchantNpc = core._merchant_npc()
	_maybe_remind(npc, entry_age)
	if core._dialogue().busy() or String(core.mode) != "game":
		return
	var dist: float = Vector2(core.player_pos).distance_to(POS + Vector2(0.0, -24.0))
	if dist > USE_RADIUS * 1.4:
		armed = true
	if dist > USE_RADIUS or not armed:
		return
	armed = false
	if npc.narrative_enabled() and not npc.seen.has(SEEN_KEY):
		npc.seen[SEEN_KEY] = true
		npc._save()
		core._dialogue().start(explain_lines(dna().total_dna() > 0), _on_choice)
		return
	open_screen()


func open_screen() -> void:
	core._merchant_dimension().fusion_screen.open()


func _on_choice(id: String) -> void:
	if id == CHOICE_OPEN:
		open_screen()


func _maybe_remind(npc: RTMerchantNpc, entry_age: float) -> void:
	var controller := dna()
	if not controller.reminder_pending or controller.total_dna() <= 0 or entry_age < 0.9:
		return
	if core._rift_transition().busy_in_dimension() or core._dialogue().busy() or String(core.mode) != "game":
		return
	if not npc.narrative_enabled():
		controller.reminder_pending = false
		return
	# A apresentacao espera ele ja ter se apresentado (fala de estreia).
	if not npc.seen.has("intro"):
		return
	controller.reminder_pending = false
	if not controller.presented:
		controller.presented = true
		core._dialogue().start(present_lines())
		return
	var lines: Array[String] = [
		"Tem DNA de chefe fresquinho no seu bolso. A máquina ali no canto está com fome.",
		"Psst! O Petro já sentiu o cheiro do DNA novo. Canto de baixo, querida.",
		"DNA guardado não estraga, mas também não te protege. Só digo isso.",
	]
	npc.say(lines[core.rng.randi_range(0, lines.size() - 1)], 4.6)


## Fala de quando ela entra pela primeira vez na run depois de um chefe.
static func present_lines() -> Array:
	return [
		{"who": "mercador", "text": "Opa, opa! Espera. Você está com um cheiro... de chefe. De chefe MORTO.", "mood": "animado"},
		{"who": "mercador", "text": "Quando um bicho daquele tamanho cai, sobra DNA no ar. E você trouxe um pouco grudado no jaleco."},
		{"who": "geovana", "text": "Isso é bom ou ruim?", "mood": "desconfiada"},
		{"who": "mercador", "text": "Para mim é ótimo, para você pode ser melhor ainda. Olha lá no canto, embaixo: a minha máquina de fusão.", "mood": "animado"},
		{"who": "mercador", "text": "Você tem uma coisa interessante aí. Chega perto dela quando quiser. Tudo tem um custo, claro: eu cobro em essência."},
	]


## Explicacao da primeira vez que ela encosta na maquina.
static func explain_lines(has_dna: bool) -> Array:
	var lines: Array = [
		{"who": "mercador", "text": "Ei, ei! Essa aí não é carrinho de mão. É a Rede do Petro.", "mood": "preocupado"},
		{"who": "geovana", "text": "Petro? O meu Petro?", "mood": "surpresa"},
		{"who": "mercador", "text": "O núcleo do seu golem de bolso estava zumbindo no meu chão. Eu dei um emprego para ele: virou o coração da máquina. Ele é seu amigo, só mudou de casa."},
		{"who": "mercador", "text": "Funciona assim: cada chefe que você derruba deixa um DNA. Cada DNA tem três habilidades. Você escolhe UMA, entra na máquina e o Petro costura em você."},
		{"who": "mercador", "text": "Algumas disparam sozinhas quando recarregam. Outras acordam quando você apanha. E as de quase-morte seguram o golpe que ia te derrubar: esse golpe nunca te mata."},
		{"who": "mercador", "text": "Quer as outras duas do mesmo chefe, ou deixar uma mais forte? Derruba ele de novo. Cada DNA só serve para o chefe de onde veio."},
		{"who": "mercador", "text": "DNA que você não usa fica guardado e viaja com você de dimensão em dimensão. E a fusão custa essência. Bastante. Comprar item ou fundir: escolha sua."},
	]
	if has_dna:
		lines.append({"who": "mercador", "text": "E olha só: você já tem DNA. Quer abrir a máquina agora?", "mood": "animado", "choices": [
			{"label": "ABRIR A MÁQUINA", "id": CHOICE_OPEN},
			{"label": "DEPOIS", "id": CHOICE_LATER},
		]})
	else:
		lines.append({"who": "mercador", "text": "Vazia, por enquanto. Derruba um chefe e volta aqui, que o Petro está com fome.", "mood": "animado"})
	return lines
