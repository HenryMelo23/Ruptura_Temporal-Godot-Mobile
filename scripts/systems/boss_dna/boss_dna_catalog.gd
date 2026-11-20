class_name RTBossDnaCatalog
extends RefCounted

## Rede do Petro: o DNA de cada chefe derrotado vira uma arvore de 3
## habilidades que a Geovana funde na maquina da oficina do Mercador.
##
## So dados (nada de estado): o controller (RTBossDnaController) executa os
## gatilhos e as primitivas de efeito; a tela e a apresentacao leem nomes,
## cores e textos daqui. A UMBRA (fase 5) nao tem DNA.
##
## Gatilhos:
## - "cooldown": dispara sozinho quando recarrega e ha inimigo por perto.
## - "on_hit": dispara ao sofrer um golpe (com recarga).
## - "near_death": golpe grande perto da morte. O golpe que ativa NUNCA mata:
##   ele e anulado antes de tirar vida.
## - "on_kill": a cada N abates (com recarga curta).
##
## Dano das primitivas em multiplos do dano base da Geovana (player_damage).
## Rank 2/3 (DNA repetido do mesmo chefe): -15% recarga e +30% potencia por rank.

const MAX_RANK := 3
const RANK_COOLDOWN_STEP := 0.15
const RANK_POTENCY_STEP := 0.30
## Golpe "grande" para os gatilhos de quase-morte (fracao da vida maxima).
const NEAR_DEATH_BIG_HIT := 0.12
## Vida que sobra depois do golpe para contar como "perto da morte".
const NEAR_DEATH_HP_RATIO := 0.25
## Raio em que um inimigo conta como "por perto" para gatilhos de recarga.
const AUTO_CAST_RANGE := 560.0

## Custo da fusao em multiplos do preco atual da carta (card_cost): cada
## fusao custa o mesmo que ~3 cartas e a seguinte na mesma run custa +1 carta.
## E de proposito: fundir agora compete com montar o deck.
const FUSION_COST_CARD_RATIO := 3.0
const FUSION_COST_STEP_RATIO := 1.0

const PHASES: Array[int] = [1, 2, 3, 4, 6, 7, 8, 9, 10]

const BOSSES: Dictionary = {
	1: {"name": "CARANGUEJO CÓSMICO", "color": Color(1.0, 0.52, 0.16), "abilities": ["mare_cosmica", "distorcao_relogio", "ressaca_temporal"]},
	2: {"name": "SENTINELA GLACIAL", "color": Color(0.5, 0.86, 1.0), "abilities": ["nevasca_particular", "congelamento_subito", "couraca_de_gelo"]},
	3: {"name": "PAI-RATO", "color": Color(0.72, 0.92, 0.24), "abilities": ["miasma_do_esgoto", "ninhada_roedora", "fuga_pelo_bueiro"]},
	4: {"name": "NEXO ANFÍBIO", "color": Color(0.3, 1.0, 0.7), "abilities": ["salto_esmagador", "lingua_arpao", "vampirismo_dimensional"]},
	6: {"name": "MATRIARCA DA CHAGA", "color": Color(1.0, 0.68, 0.2), "abilities": ["foices_de_ambar", "carapaca_de_ambar", "mergulho_na_chaga"]},
	7: {"name": "FÊNIX", "color": Color(1.0, 0.32, 0.16), "abilities": ["asas_de_brasa", "rastro_de_cinzas", "renascer_das_cinzas"]},
	8: {"name": "CASCO-DE-SOL", "color": Color(1.0, 0.88, 0.36), "abilities": ["casco_de_sol", "rajada_do_sertao", "sol_a_pino"]},
	9: {"name": "MATRIARCA DOS OITO OLHOS", "color": Color(0.78, 0.42, 1.0), "abilities": ["teia_de_seda", "picada_dos_oito_olhos", "casulo_de_seda"]},
	10: {"name": "DONA BOLETA", "color": Color(1.0, 0.36, 0.72), "abilities": ["drop_do_paredao", "congela_o_baile", "tamborzao"]},
}

## id -> {name, phase, trigger, cooldown, [kills], desc, effects}
const ABILITIES: Dictionary = {
	# ---------------------------------------------------- 1 Caranguejo Cosmico
	"mare_cosmica": {"name": "Maré Cósmica", "phase": 1, "trigger": "cooldown", "cooldown": 40.0,
		"desc": "Uma maré do relógio cobre o mapa: TODOS os inimigos ficam 45% mais lentos por 15 s (o chefe, 25%).",
		"effects": [{"kind": "slow_all", "duration": 15.0, "mult": 0.55, "boss_ratio": 0.25}]},
	"distorcao_relogio": {"name": "Distorção do Relógio", "phase": 1, "trigger": "near_death", "cooldown": 150.0,
		"desc": "Golpe grande perto da morte: o golpe é anulado (ela NUNCA morre por ele) e o espaço-tempo volta 10 s para ela e para todos os inimigos. O dano já causado nos inimigos fica.",
		"effects": [{"kind": "rewind", "seconds": 10.0, "min_hp": 0.4}, {"kind": "invuln", "duration": 1.5}]},
	"ressaca_temporal": {"name": "Ressaca Temporal", "phase": 1, "trigger": "on_hit", "cooldown": 14.0,
		"desc": "Ao levar um golpe, solta uma onda que atravessa o mapa: dano e lentidão de 40% por 4 s em quem ela tocar.",
		"effects": [{"kind": "wave", "radius": 1100.0, "speed": 760.0, "damage": 2.5, "slow": 4.0, "mult": 0.6}]},
	# ---------------------------------------------------- 2 Sentinela Glacial
	"nevasca_particular": {"name": "Nevasca Particular", "phase": 2, "trigger": "cooldown", "cooldown": 32.0,
		"desc": "Uma nevasca a acompanha por 8 s: fere e deixa 50% mais lento quem estiver a até 220 de distância.",
		"effects": [{"kind": "zone", "radius": 220.0, "duration": 8.0, "dps": 0.6, "mult": 0.5, "follow": true}]},
	"congelamento_subito": {"name": "Congelamento Súbito", "phase": 2, "trigger": "on_hit", "cooldown": 20.0,
		"desc": "Ao levar um golpe, congela por 2,5 s e fere os inimigos ao redor.",
		"effects": [{"kind": "freeze", "radius": 300.0, "duration": 2.5}, {"kind": "nova", "radius": 300.0, "damage": 1.5}]},
	"couraca_de_gelo": {"name": "Couraça de Gelo", "phase": 2, "trigger": "near_death", "cooldown": 120.0,
		"desc": "Golpe grande perto da morte: anulado (ela NUNCA morre por ele). Ganha um escudo de 35% da vida por 10 s e congela quem estiver perto.",
		"effects": [{"kind": "shield", "amount": 0.35, "duration": 10.0}, {"kind": "freeze", "radius": 260.0, "duration": 1.5}]},
	# ---------------------------------------------------- 3 Pai-Rato
	"miasma_do_esgoto": {"name": "Miasma do Esgoto", "phase": 3, "trigger": "cooldown", "cooldown": 26.0,
		"desc": "Deixa uma nuvem de miasma por 9 s onde está: dano contínuo e 20% de lentidão.",
		"effects": [{"kind": "zone", "radius": 240.0, "duration": 9.0, "dps": 0.9, "mult": 0.8, "follow": false}]},
	"ninhada_roedora": {"name": "Ninhada Roedora", "phase": 3, "trigger": "on_kill", "kills": 12, "cooldown": 6.0,
		"desc": "A cada 12 abates, quatro ratos de energia correm em volta dela por 7 s mordendo quem encostar.",
		"effects": [{"kind": "orbit", "count": 4, "radius": 96.0, "duration": 7.0, "damage": 0.8}]},
	"fuga_pelo_bueiro": {"name": "Fuga pelo Bueiro", "phase": 3, "trigger": "near_death", "cooldown": 100.0,
		"desc": "Golpe grande perto da morte: anulado (ela NUNCA morre por ele). Some na fumaça por 2,2 s, recupera 20% da vida e atordoa quem estava perto.",
		"effects": [{"kind": "invuln", "duration": 2.2}, {"kind": "heal", "amount": 0.2}, {"kind": "nova", "radius": 200.0, "damage": 0.5, "stun": 1.2}]},
	# ---------------------------------------------------- 4 Nexo Anfibio
	"salto_esmagador": {"name": "Salto Esmagador", "phase": 4, "trigger": "cooldown", "cooldown": 18.0,
		"desc": "Pisa com a força do Nexo: dano em área, atordoa 0,9 s e empurra.",
		"effects": [{"kind": "nova", "radius": 230.0, "damage": 3.2, "stun": 0.9, "push": 120.0}]},
	"lingua_arpao": {"name": "Língua-Arpão", "phase": 4, "trigger": "cooldown", "cooldown": 22.0,
		"desc": "Puxa os inimigos de até 480 de distância para perto e estala um golpe neles.",
		"effects": [{"kind": "pull", "radius": 480.0, "strength": 220.0}, {"kind": "nova", "radius": 160.0, "damage": 2.0}]},
	"vampirismo_dimensional": {"name": "Vampirismo Dimensional", "phase": 4, "trigger": "on_hit", "cooldown": 16.0,
		"desc": "Ao levar um golpe, drena os inimigos ao redor e cura 40% do dano drenado.",
		"effects": [{"kind": "drain", "radius": 320.0, "damage": 1.6, "heal_ratio": 0.4}]},
	# ---------------------------------------------------- 6 Matriarca da Chaga
	"foices_de_ambar": {"name": "Foices de Âmbar", "phase": 6, "trigger": "cooldown", "cooldown": 24.0,
		"desc": "Três foices de âmbar giram em volta dela por 8 s cortando quem encostar.",
		"effects": [{"kind": "orbit", "count": 3, "radius": 120.0, "duration": 8.0, "damage": 1.1}]},
	"carapaca_de_ambar": {"name": "Carapaça de Âmbar", "phase": 6, "trigger": "on_hit", "cooldown": 25.0,
		"desc": "Ao levar um golpe, cria uma carapaça que absorve 25% da vida máxima por 8 s.",
		"effects": [{"kind": "shield", "amount": 0.25, "duration": 8.0}]},
	"mergulho_na_chaga": {"name": "Mergulho na Chaga", "phase": 6, "trigger": "near_death", "cooldown": 110.0,
		"desc": "Golpe grande perto da morte: anulado (ela NUNCA morre por ele). Mergulha no âmbar por 1,8 s e emerge ferindo e desacelerando tudo ao redor.",
		"effects": [{"kind": "invuln", "duration": 1.8}, {"kind": "nova", "radius": 260.0, "damage": 3.5, "slow": 3.0, "mult": 0.6}]},
	# ---------------------------------------------------- 7 Fenix
	"asas_de_brasa": {"name": "Asas de Brasa", "phase": 7, "trigger": "cooldown", "cooldown": 20.0,
		"desc": "Abre asas de fogo: explosão ao redor e chão em brasa por 5 s.",
		"effects": [{"kind": "nova", "radius": 300.0, "damage": 2.4}, {"kind": "zone", "radius": 160.0, "duration": 5.0, "dps": 0.7, "mult": 1.0, "follow": false}]},
	"rastro_de_cinzas": {"name": "Rastro de Cinzas", "phase": 7, "trigger": "on_kill", "kills": 15, "cooldown": 4.0,
		"desc": "A cada 15 abates, o chão em volta dela pega fogo por 4 s.",
		"effects": [{"kind": "zone", "radius": 150.0, "duration": 4.0, "dps": 1.0, "mult": 1.0, "follow": true}]},
	"renascer_das_cinzas": {"name": "Renascer das Cinzas", "phase": 7, "trigger": "near_death", "cooldown": 180.0,
		"desc": "Golpe grande perto da morte: anulado (ela NUNCA morre por ele). Renasce com +60% de vida e uma explosão de fogo.",
		"effects": [{"kind": "heal", "amount": 0.6}, {"kind": "invuln", "duration": 1.5}, {"kind": "nova", "radius": 360.0, "damage": 4.0}]},
	# ---------------------------------------------------- 8 Casco-de-Sol
	"casco_de_sol": {"name": "Casco de Sol", "phase": 8, "trigger": "on_hit", "cooldown": 18.0,
		"desc": "Ao levar um golpe, se fecha no casco: 55% menos dano por 5 s.",
		"effects": [{"kind": "guard", "reduction": 0.55, "duration": 5.0}]},
	"rajada_do_sertao": {"name": "Rajada do Sertão", "phase": 8, "trigger": "cooldown", "cooldown": 16.0,
		"desc": "Um anel de chumbo solar se abre a partir dela e fere tudo até 520 de distância.",
		"effects": [{"kind": "wave", "radius": 520.0, "speed": 900.0, "damage": 1.8}]},
	"sol_a_pino": {"name": "Sol a Pino", "phase": 8, "trigger": "cooldown", "cooldown": 45.0,
		"desc": "O sol do meio-dia queima todos os inimigos da tela e os deixa lentos por 2 s.",
		"effects": [{"kind": "nova", "radius": 900.0, "damage": 2.0, "slow": 2.0, "mult": 0.6}]},
	# ---------------------------------------------------- 9 Matriarca dos Oito Olhos
	"teia_de_seda": {"name": "Teia de Seda", "phase": 9, "trigger": "cooldown", "cooldown": 22.0,
		"desc": "Estende uma teia de 260 por 8 s: quem pisar fica 65% mais lento.",
		"effects": [{"kind": "zone", "radius": 260.0, "duration": 8.0, "dps": 0.3, "mult": 0.35, "follow": false}]},
	"picada_dos_oito_olhos": {"name": "Picada dos Oito Olhos", "phase": 9, "trigger": "on_hit", "cooldown": 10.0,
		"desc": "Ao levar um golpe, oito ferrões atingem quem estiver perto: dano e lentidão por 2 s.",
		"effects": [{"kind": "nova", "radius": 190.0, "damage": 2.2, "slow": 2.0, "mult": 0.6}]},
	"casulo_de_seda": {"name": "Casulo de Seda", "phase": 9, "trigger": "near_death", "cooldown": 120.0,
		"desc": "Golpe grande perto da morte: anulado (ela NUNCA morre por ele). Se fecha num casulo por 2,5 s, recupera 35% da vida e prende os inimigos próximos.",
		"effects": [{"kind": "invuln", "duration": 2.5}, {"kind": "heal", "amount": 0.35}, {"kind": "freeze", "radius": 200.0, "duration": 2.0}]},
	# ---------------------------------------------------- 10 Dona Boleta
	"drop_do_paredao": {"name": "Drop do Paredão", "phase": 10, "trigger": "cooldown", "cooldown": 30.0,
		"desc": "O grave estoura: uma onda atravessa o mapa, fere e atordoa 0,8 s.",
		"effects": [{"kind": "wave", "radius": 1000.0, "speed": 820.0, "damage": 2.0, "stun": 0.8}]},
	"congela_o_baile": {"name": "Congela o Baile", "phase": 10, "trigger": "cooldown", "cooldown": 50.0,
		"desc": "\"Congela!\": todos os inimigos do mapa param por 3 s e o chefe fica 30% mais lento.",
		"effects": [{"kind": "freeze", "radius": 0.0, "duration": 3.0, "boss_ratio": 0.3}]},
	"tamborzao": {"name": "Tamborzão", "phase": 10, "trigger": "on_hit", "cooldown": 12.0,
		"desc": "Ao levar um golpe, a batida empurra os inimigos para longe e fere.",
		"effects": [{"kind": "nova", "radius": 240.0, "damage": 1.2, "push": 220.0}]},
}


static func has_boss(phase: int) -> bool:
	return BOSSES.has(phase)


static func boss(phase: int) -> Dictionary:
	return Dictionary(BOSSES.get(phase, {}))


static func boss_color(phase: int) -> Color:
	return Color(boss(phase).get("color", Color(0.6, 0.9, 1.0)))


static func boss_abilities(phase: int) -> Array:
	return Array(boss(phase).get("abilities", []))


static func ability(id: String) -> Dictionary:
	return Dictionary(ABILITIES.get(id, {}))


static func ability_ids() -> Array:
	return ABILITIES.keys()


static func cooldown_for(id: String, rank: int) -> float:
	var base: float = float(ability(id).get("cooldown", 30.0))
	return base * maxf(0.4, 1.0 - RANK_COOLDOWN_STEP * float(clampi(rank, 1, MAX_RANK) - 1))


static func potency_for(rank: int) -> float:
	return 1.0 + RANK_POTENCY_STEP * float(clampi(rank, 1, MAX_RANK) - 1)


## Texto curto do gatilho para a tela e o HUD.
static func trigger_label(id: String, rank: int = 1) -> String:
	var data := ability(id)
	var cd := cooldown_for(id, rank)
	match String(data.get("trigger", "")):
		"cooldown":
			return "AUTOMÁTICA · RECARGA %d s" % int(round(cd))
		"on_hit":
			return "AO SOFRER GOLPE · RECARGA %d s" % int(round(cd))
		"near_death":
			return "QUASE-MORTE (NUNCA MATA) · RECARGA %d s" % int(round(cd))
		"on_kill":
			return "A CADA %d ABATES · RECARGA %d s" % [int(data.get("kills", 10)), int(round(cd))]
	return ""


## Preco da proxima fusao (pontos). `fusions_done` = fusoes desta run.
static func fusion_cost(card_cost: int, fusions_done: int) -> int:
	var ratio := FUSION_COST_CARD_RATIO + FUSION_COST_STEP_RATIO * float(maxi(0, fusions_done))
	return maxi(1, int(round(float(maxi(1, card_cost)) * ratio)))


## Sanidade dos dados: 9 chefes x 3 habilidades validas, sem UMBRA.
static func validate() -> String:
	if BOSSES.has(5):
		return "UMBRA nao tem DNA"
	if PHASES.size() != 9:
		return "esperados 9 chefes"
	for phase in PHASES:
		var ids := boss_abilities(phase)
		if ids.size() != 3:
			return "chefe %d sem 3 habilidades" % phase
		for id in ids:
			var data := ability(String(id))
			if data.is_empty() or int(data.get("phase", 0)) != phase:
				return "habilidade %s invalida" % id
			if Array(data.get("effects", [])).is_empty() or String(data.get("desc", "")) == "":
				return "habilidade %s sem efeito/descricao" % id
	if ABILITIES.size() != 27:
		return "esperadas 27 habilidades"
	return ""
