class_name CardCatalogDefinitions
extends RefCounted

## Card Categories
const CATEGORY_DAMAGE: = "damage"
const CATEGORY_DEFENSE: = "defense"
const CATEGORY_SPEED: = "speed"
const CATEGORY_ATTACK_SPEED: = "attack_speed"
const CATEGORY_COOLDOWN: = "cooldown"
const CATEGORY_AREA: = "area"
const CATEGORY_DURATION: = "duration"
const CATEGORY_HEALING: = "healing"
const CATEGORY_LUCK: = "luck"
const CATEGORY_LIFESTEAL: = "lifesteal"
const CATEGORY_ECONOMY: = "economy"
const CATEGORY_RESISTANCE: = "resistance"
const CATEGORY_CROWD_CONTROL: = "crowd_control"
const CATEGORY_UTILITY: = "utility"
const CATEGORY_CONSUMABLE: = "consumable"
const CATEGORY_RARE: = "rare"

## Central Default Burn Scaling Factor (+50% of original card attributes per burn stack)
const DEFAULT_BURN_FACTOR: float = 0.50

## Category Burn Scaling Factor Multipliers (allow fine-tuning per category if needed)
const CATEGORY_BURN_FACTORS: Dictionary = {
	CATEGORY_DAMAGE: 0.50,
	CATEGORY_DEFENSE: 0.50,
	CATEGORY_SPEED: 0.50,
	CATEGORY_ATTACK_SPEED: 0.50,
	CATEGORY_COOLDOWN: 0.50,
	CATEGORY_AREA: 0.50,
	CATEGORY_DURATION: 0.50,
	CATEGORY_HEALING: 0.50,
	CATEGORY_LUCK: 0.50,
	CATEGORY_LIFESTEAL: 0.50,
	CATEGORY_ECONOMY: 0.50,
	CATEGORY_RESISTANCE: 0.50,
	CATEGORY_CROWD_CONTROL: 0.50,
	CATEGORY_UTILITY: 0.50,
}

## Canonical Card Registry with explicit attribute policies
const CARD_DEFINITIONS: Dictionary = {
	"Speed Boost": {
		"id": "Speed Boost",
		"name": "Speed Boost",
		"category": CATEGORY_SPEED,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["speed"],
		"burn_factor": 0.50,
		"stat_label": "velocidade de movimento",
		"float_text": "CINZAS: VELOCIDADE",
	},
	"Porcao": {
		"id": "Porcao",
		"name": "Porcao",
		"category": CATEGORY_HEALING,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["max_hp", "heal"],
		"burn_factor": 0.50,
		"stat_label": "vida maxima e cura",
		"float_text": "CINZAS: VITALIDADE",
	},
	"Disparo crescente": {
		"id": "Disparo crescente",
		"name": "Disparo crescente",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["damage"],
		"burn_factor": 0.50,
		"stat_label": "dano de auto attack",
		"float_text": "CINZAS: DANO",
	},
	"Tempestade": {
		"id": "Tempestade",
		"name": "Tempestade",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["flat_damage", "crit"],
		"burn_factor": 0.50,
		"stat_label": "dano e chance critica",
		"float_text": "CINZAS: TEMPESTADE",
	},
	"Trembo": {
		"id": "Trembo",
		"name": "Trembo",
		"category": CATEGORY_RARE,
		"can_burn": false,
		"policy": "rare_locked_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "efeito unico raro",
		"float_text": "CINZAS: REVERSAO",
	},
	"Roubo de Vida": {
		"id": "Roubo de Vida",
		"name": "Roubo de Vida",
		"category": CATEGORY_LIFESTEAL,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["lifesteal"],
		"burn_factor": 0.50,
		"stat_label": "roubo de vida",
		"float_text": "CINZAS: VAMPIRISMO",
	},
	"Speed Atack": {
		"id": "Speed Atack",
		"name": "Speed Atack",
		"category": CATEGORY_ATTACK_SPEED,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["attack_interval"],
		"burn_factor": 0.50,
		"stat_label": "cadencia de disparos",
		"float_text": "CINZAS: CADENCIA",
		"caps": {"min_interval": 0.28},
	},
	"Teleporte": {
		"id": "Teleporte",
		"name": "Teleporte",
		"category": CATEGORY_COOLDOWN,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["dash_cooldown"],
		"burn_factor": 0.50,
		"stat_label": "recarga do teleporte",
		"float_text": "CINZAS: RECARGA",
		"caps": {"min_cooldown": 0.5},
	},
	"Petro": {
		"id": "Petro",
		"name": "Petro",
		"category": CATEGORY_RARE,
		"can_burn": false,
		"policy": "rare_locked_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "constructo companheiro",
		"float_text": "CINZAS: SENTINELA",
	},
	"Defesa": {
		"id": "Defesa",
		"name": "Defesa",
		"category": CATEGORY_DEFENSE,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["defense"],
		"burn_factor": 0.50,
		"stat_label": "resistencia fasica",
		"float_text": "CINZAS: DEFESA",
		"caps": {"max_defense": 50.0},
	},
	"Sorte": {
		"id": "Sorte",
		"name": "Sorte",
		"category": CATEGORY_LUCK,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["luck"],
		"burn_factor": 0.50,
		"stat_label": "sorte de anomalia",
		"float_text": "CINZAS: SORTE",
	},
	"Poison": {
		"id": "Poison",
		"name": "Poison",
		"category": CATEGORY_RARE,
		"can_burn": false,
		"policy": "rare_locked_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "toxina rara",
		"float_text": "CINZAS: TOXINA",
	},
	"Coletora": {
		"id": "Coletora",
		"name": "Coletora",
		"category": CATEGORY_RARE,
		"can_burn": false,
		"policy": "rare_locked_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "execucao rara",
		"float_text": "CINZAS: CEIFADOR",
	},
	"Mercenaria": {
		"id": "Mercenaria",
		"name": "Mercenaria",
		"category": CATEGORY_RARE,
		"can_burn": false,
		"policy": "rare_locked_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "contrato raro",
		"float_text": "CINZAS: CONTRATO",
	},
	"devorador_destinos": {
		"id": "devorador_destinos",
		"name": "Devorador de Destinos",
		"category": CATEGORY_RARE,
		"can_burn": false,
		"policy": "rare_locked_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "marca de destino rara",
		"float_text": "CINZAS: DEVORADOR",
	},
	"escolha_adiada": {
		"id": "escolha_adiada",
		"name": "Escolha Adiada",
		"category": CATEGORY_CONSUMABLE,
		"can_burn": false,
		"policy": "utility_consumable_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "reserva consumivel",
		"float_text": "CINZAS: RESERVA",
	},
	"tregua_regenerativa": {
		"id": "tregua_regenerativa",
		"name": "Trégua Regenerativa",
		"category": CATEGORY_HEALING,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["regen"],
		"burn_factor": 0.50,
		"stat_label": "regeneracao passiva",
		"float_text": "CINZAS: REGENERACAO",
	},
	"cinzas_escolha": {
		"id": "cinzas_escolha",
		"name": "Cinzas da Escolha",
		"category": CATEGORY_CONSUMABLE,
		"can_burn": false,
		"policy": "utility_consumable_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "sacrificio de cinzas",
		"float_text": "CINZAS: MARCA",
	},
	"reserva_pulso": {
		"id": "reserva_pulso",
		"name": "Reserva de Pulso",
		"category": CATEGORY_HEALING,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["capacity"],
		"burn_factor": 0.50,
		"stat_label": "capacidade de cura guardada",
		"float_text": "CINZAS: PULSO",
	},
	"casulo_reativo": {
		"id": "casulo_reativo",
		"name": "Casulo Reativo",
		"category": CATEGORY_DEFENSE,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["defense_reduction", "duration"],
		"burn_factor": 0.50,
		"stat_label": "defesa e duracao do casulo",
		"float_text": "CINZAS: CASULO",
	},
	"passagem_intangivel": {
		"id": "passagem_intangivel",
		"name": "Passagem Intangível",
		"category": CATEGORY_DURATION,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["duration"],
		"burn_factor": 0.50,
		"stat_label": "duracao de fase fantasma",
		"float_text": "CINZAS: INTANGIBILIDADE",
	},
	"ancora_vital": {
		"id": "ancora_vital",
		"name": "Âncora Vital",
		"category": CATEGORY_HEALING,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["healing_ratio", "duration"],
		"burn_factor": 0.50,
		"stat_label": "retorno vital e duracao",
		"float_text": "CINZAS: ANCORA",
	},
	"inercia_cronal": {
		"id": "inercia_cronal",
		"name": "Inercia Cronal",
		"category": CATEGORY_RESISTANCE,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["control", "knockback"],
		"burn_factor": 0.50,
		"stat_label": "resistencia a controle e empurrao",
		"float_text": "CINZAS: INERCIA",
		"caps": {"max_control": 0.40, "max_knockback": 0.72},
	},
	"leitura_instante": {
		"id": "leitura_instante",
		"name": "Leitura do Instante",
		"category": CATEGORY_UTILITY,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["window"],
		"burn_factor": 0.50,
		"stat_label": "antecedencia visual",
		"float_text": "CINZAS: PREVISAO",
		"caps": {"max_window": 0.28},
	},
	"margem_segura": {
		"id": "margem_segura",
		"name": "Margem Segura",
		"category": CATEGORY_AREA,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["distance"],
		"burn_factor": 0.50,
		"stat_label": "distancia de spawn",
		"float_text": "CINZAS: DISTANCIA",
		"caps": {"max_distance": 140.0},
	},
	"moeda_estavel": {
		"id": "moeda_estavel",
		"name": "Moeda Estavel",
		"category": CATEGORY_ECONOMY,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["economy"],
		"burn_factor": 0.50,
		"stat_label": "economia de compras",
		"float_text": "CINZAS: ECONOMIA",
		"caps": {"min_increment": 64},
	},
	"orbita_coletora": {
		"id": "orbita_coletora",
		"name": "Orbita Coletora",
		"category": CATEGORY_AREA,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["radius"],
		"burn_factor": 0.50,
		"stat_label": "raio de coleta",
		"float_text": "CINZAS: ORBITA",
		"caps": {"max_radius": 1.10},
	},
	"pacto_possibilidades": {
		"id": "pacto_possibilidades",
		"name": "Pacto das Possibilidades",
		"category": CATEGORY_ECONOMY,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["discount"],
		"burn_factor": 0.50,
		"stat_label": "desconto de loja",
		"float_text": "CINZAS: PACTO",
		"caps": {"max_discount": 0.20},
	},
	"solo_consolidado": {
		"id": "solo_consolidado",
		"name": "Solo Consolidado",
		"category": CATEGORY_DURATION,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["duration_reduction"],
		"burn_factor": 0.50,
		"stat_label": "reducao de perigos de chao",
		"float_text": "CINZAS: ESTABILIDADE",
		"caps": {"max_reduction": 0.32},
	},
	"rastro_de_retorno": {
		"id": "rastro_de_retorno",
		"name": "Rastro de Retorno",
		"category": CATEGORY_SPEED,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["speed", "tp_recovery", "duration", "interval"],
		"burn_factor": 0.50,
		"stat_label": "vestigio e velocidade",
		"float_text": "CINZAS: VESTIGIO",
	},
	"municao_de_rebate": {
		"id": "municao_de_rebate",
		"name": "Municao de Rebate",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["damage", "chance", "radius"],
		"burn_factor": 0.50,
		"stat_label": "rebate e fragmentos",
		"float_text": "CINZAS: REBATE",
	},
	"impulso_de_sobras": {
		"id": "impulso_de_sobras",
		"name": "Impulso de Sobras",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["damage", "size", "charges"],
		"burn_factor": 0.50,
		"stat_label": "ataque fortalecido e area",
		"float_text": "CINZAS: IMPULSO",
	},
	"eco_de_impacto": {
		"id": "eco_de_impacto",
		"name": "Eco de Impacto",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["damage", "radius"],
		"burn_factor": 0.50,
		"stat_label": "eco de dano",
		"float_text": "CINZAS: ECO",
	},
	"zona_de_descompressao": {
		"id": "zona_de_descompressao",
		"name": "Zona de Descompressao",
		"category": CATEGORY_AREA,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["radius", "slow", "knockback"],
		"burn_factor": 0.50,
		"stat_label": "onda de descompressao",
		"float_text": "CINZAS: ZONA",
	},
	"folego_de_perseguicao": {
		"id": "folego_de_perseguicao",
		"name": "Folego de Perseguicao",
		"category": CATEGORY_SPEED,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["speed", "damage"],
		"burn_factor": 0.50,
		"stat_label": "perseguicao e impacto",
		"float_text": "CINZAS: FOLEGO",
	},
	"margem_de_erro": {
		"id": "margem_de_erro",
		"name": "Margem de Erro",
		"category": CATEGORY_DEFENSE,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["defer", "reduction"],
		"burn_factor": 0.50,
		"stat_label": "mitigacao e parcelamento de dano",
		"float_text": "CINZAS: MARGEM",
	},
	"ressonancia_de_alternancia": {
		"id": "ressonancia_de_alternancia",
		"name": "Ressonancia de Alternancia",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["damage", "speed", "duration"],
		"burn_factor": 0.50,
		"stat_label": "ressonancia de acoes",
		"float_text": "CINZAS: RESSONANCIA",
	},
	"intervalo_fraturado": {
		"id": "intervalo_fraturado",
		"name": "Intervalo Fraturado",
		"category": CATEGORY_COOLDOWN,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["hab1_cooldown", "ultimate_cooldown"],
		"burn_factor": 0.50,
		"stat_label": "recarga de Hab1 e Ultimate",
		"float_text": "CINZAS: INTERVALO",
	},
	"nucleo_revigorante": {
		"id": "nucleo_revigorante",
		"name": "Nucleo Revigorante",
		"category": CATEGORY_HEALING,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["heal_bonus"],
		"burn_factor": 0.50,
		"stat_label": "cura por orbes",
		"float_text": "CINZAS: NUCLEO",
	},
	"limiar_de_ruina": {
		"id": "limiar_de_ruina",
		"name": "Limiar de Ruina",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["damage_bonus"],
		"burn_factor": 0.50,
		"stat_label": "abertura contra alvos >90% HP",
		"float_text": "CINZAS: RUINA",
	},
	"estase_reparadora": {
		"id": "estase_reparadora",
		"name": "Estase Reparadora",
		"category": CATEGORY_HEALING,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["heal_rate"],
		"burn_factor": 0.50,
		"stat_label": "regeneracao em repouso",
		"float_text": "CINZAS: ESTASE",
	},
	"egide_hemofaga": {
		"id": "egide_hemofaga",
		"name": "Egide Hemofaga",
		"category": CATEGORY_RARE,
		"can_burn": false,
		"policy": "rare_locked_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "escudo hemofago raro",
		"float_text": "CINZAS: EGIDE",
	},
	"fratura_cronal": {
		"id": "fratura_cronal",
		"name": "Fratura Cronal",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["damage_bonus"],
		"burn_factor": 0.50,
		"stat_label": "vulnerabilidade por fragilidade",
		"float_text": "CINZAS: FRATURA",
	},
	"pulso_desestabilizador": {
		"id": "pulso_desestabilizador",
		"name": "Pulso Desestabilizador",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["damage", "radius"],
		"burn_factor": 0.50,
		"stat_label": "dano e raio da explosao",
		"float_text": "CINZAS: PULSO",
	},
	"pressao_cerco": {
		"id": "pressao_cerco",
		"name": "Pressao de Cerco",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["damage_bonus"],
		"burn_factor": 0.50,
		"stat_label": "dano em alvos cercados",
		"float_text": "CINZAS: CERCO",
	},
	"choque_fontes": {
		"id": "choque_fontes",
		"name": "Choque de Fontes",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["damage"],
		"burn_factor": 0.50,
		"stat_label": "descarga de choque de fontes",
		"float_text": "CINZAS: CHOQUE",
	},
	"ferrolho_ruptura": {
		"id": "ferrolho_ruptura",
		"name": "Ferrolho de Ruptura",
		"category": CATEGORY_CROWD_CONTROL,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["root_duration", "boss_slow"],
		"burn_factor": 0.50,
		"stat_label": "fixacao espacial e lentidao",
		"float_text": "CINZAS: FERROLHO",
	},
	"limiar_colapso": {
		"id": "limiar_colapso",
		"name": "Limiar de Colapso",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "numeric_attribute",
		"eligible_attributes": ["damage"],
		"burn_factor": 0.50,
		"stat_label": "ruptura por vida",
		"float_text": "CINZAS: COLAPSO",
	},
	"desvio_probabilidade": {
		"id": "desvio_probabilidade",
		"name": "Desvio de Probabilidade",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["bonus_damage", "near_miss_radius"],
		"burn_factor": 0.50,
		"stat_label": "dano de quase-acerto",
		"float_text": "CINZAS: DESVIO",
	},
	"ponto_cego": {
		"id": "ponto_cego",
		"name": "Ponto Cego",
		"category": CATEGORY_DAMAGE,
		"can_burn": true,
		"policy": "multi_attribute",
		"eligible_attributes": ["damage", "confusion"],
		"burn_factor": 0.50,
		"stat_label": "dano por tras e desorientacao",
		"float_text": "CINZAS: PONTO CEGO",
	},
	"mandamento_ruptura": {
		"id": "mandamento_ruptura",
		"name": "Mandamento da Ruptura",
		"category": CATEGORY_RARE,
		"can_burn": false,
		"policy": "rare_locked_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "lei de habilidades rara",
		"float_text": "CINZAS: MANDAMENTO",
	},
	"carta_zero": {
		"id": "carta_zero",
		"name": "Carta Zero",
		"category": CATEGORY_RARE,
		"can_burn": false,
		"policy": "rare_locked_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "origem numerica rara",
		"float_text": "CINZAS: ZERO",
	},
	"necrocronismo": {
		"id": "necrocronismo",
		"name": "Necrocronismo",
		"category": CATEGORY_RARE,
		"can_burn": false,
		"policy": "rare_locked_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "aliados espectrais raros",
		"float_text": "CINZAS: NECRO",
	},
	"coracao_antimateria": {
		"id": "coracao_antimateria",
		"name": "Coração de Antimatéria",
		"category": CATEGORY_RARE,
		"can_burn": false,
		"policy": "rare_locked_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "implosao instavel rara",
		"float_text": "CINZAS: ANTIMATERIA",
	},
	"cofre_excesso": {
		"id": "cofre_excesso",
		"name": "Cofre do Excesso",
		"category": CATEGORY_RARE,
		"can_burn": false,
		"policy": "rare_locked_non_burnable",
		"eligible_attributes": [],
		"burn_factor": 0.0,
		"stat_label": "reserva de overkill rara",
		"float_text": "CINZAS: EXCESSO",
	},
}


static func normalize_card_id(card_or_id: Variant) -> String:
	if card_or_id is Dictionary:
		var d: Dictionary = card_or_id
		return String(d.get("id", String(d.get("name", ""))))
	return String(card_or_id)


static func get_card_definition(card_or_id: Variant) -> Dictionary:
	var key: String = normalize_card_id(card_or_id)
	if CARD_DEFINITIONS.has(key):
		return Dictionary(CARD_DEFINITIONS[key])
	# Fallback by name search
	for def_key in CARD_DEFINITIONS.keys():
		var def: Dictionary = CARD_DEFINITIONS[def_key]
		if String(def.get("name", "")) == key or String(def.get("id", "")) == key:
			return def
	return {}


static func is_burn_eligible(card_or_id: Variant) -> bool:
	var def: Dictionary = get_card_definition(card_or_id)
	if def.is_empty():
		return false
	return bool(def.get("can_burn", false))


static func get_card_category(card_or_id: Variant) -> String:
	var def: Dictionary = get_card_definition(card_or_id)
	return String(def.get("category", CATEGORY_UTILITY))


static func get_eligible_attributes(card_or_id: Variant) -> Array:
	var def: Dictionary = get_card_definition(card_or_id)
	return Array(def.get("eligible_attributes", []))


static func get_burn_factor(card_or_id: Variant) -> float:
	var def: Dictionary = get_card_definition(card_or_id)
	if def.is_empty():
		return DEFAULT_BURN_FACTOR
	var factor: float = float(def.get("burn_factor", DEFAULT_BURN_FACTOR))
	var cat: String = String(def.get("category", ""))
	if CATEGORY_BURN_FACTORS.has(cat):
		factor = float(CATEGORY_BURN_FACTORS[cat])
	return maxf(0.05, factor)


static func get_floating_text_for_burn(card_or_id: Variant) -> String:
	var def: Dictionary = get_card_definition(card_or_id)
	if not def.is_empty() and def.has("float_text"):
		return String(def["float_text"])
	var cat: String = get_card_category(card_or_id)
	match cat:
		CATEGORY_DEFENSE: return "CINZAS: DEFESA"
		CATEGORY_SPEED: return "CINZAS: VELOCIDADE"
		CATEGORY_ATTACK_SPEED: return "CINZAS: CADENCIA"
		CATEGORY_COOLDOWN: return "CINZAS: RECARGA"
		CATEGORY_HEALING: return "CINZAS: VITALIDADE"
		CATEGORY_LIFESTEAL: return "CINZAS: VAMPIRISMO"
		CATEGORY_LUCK: return "CINZAS: SORTE"
		CATEGORY_AREA: return "CINZAS: AREA"
		CATEGORY_DURATION: return "CINZAS: DURACAO"
		CATEGORY_RESISTANCE: return "CINZAS: RESISTENCIA"
		CATEGORY_ECONOMY: return "CINZAS: ECONOMIA"
		_: return "CINZAS: FORTALECIMENTO"


static func get_burn_summary(card_or_id: Variant, stacks: int, base_damage: float = 30.0, base_speed: float = 280.0) -> String:
	var card_id: String = normalize_card_id(card_or_id)
	var factor: float = get_burn_factor(card_id)
	var effective_stacks: int = maxi(1, stacks)
	var total_scale_pct: int = int(round(float(effective_stacks) * factor * 100.0))

	match card_id:
		"Defesa":
			var bonus_val: float = 3.5 * float(effective_stacks) * factor
			return "Ao comprar: +%.2f de resistencia adicional (+%d%%) [limite: 50]" % [bonus_val, total_scale_pct]
		"Speed Boost":
			var bonus_pct: float = 6.5 * float(effective_stacks) * factor
			var speed_units: float = base_speed * (bonus_pct / 100.0)
			return "Ao comprar: +%.1f%% de velocidade (+%.1f unidades, +%d%%)" % [bonus_pct, speed_units, total_scale_pct]
		"Disparo crescente":
			var bonus_pct: float = 15.0 * float(effective_stacks) * factor
			var dmg_val: float = base_damage * (bonus_pct / 100.0)
			return "Ao comprar: +%.1f%% de dano base (+%.1f dano, +%d%%)" % [bonus_pct, dmg_val, total_scale_pct]
		"Tempestade":
			var flat_dmg: float = 5.0 * float(effective_stacks) * factor
			var crit_pct: float = 2.0 * float(effective_stacks) * factor
			return "Ao comprar: +%.1f de dano e +%.1f%% de critico adicional (+%d%%)" % [flat_dmg, crit_pct, total_scale_pct]
		"Speed Atack":
			var reduction_val: float = 0.014 * float(effective_stacks) * factor
			return "Ao comprar: -%.3fs de intervalo entre disparos (+%d%%) [min: 0.28s]" % [reduction_val, total_scale_pct]
		"Teleporte":
			var cd_val: float = 0.3 * float(effective_stacks) * factor
			return "Ao comprar: -%.2fs de recarga do teleporte (+%d%%) [min: 0.5s]" % [cd_val, total_scale_pct]
		"Roubo de Vida":
			var ls_pct: float = 0.1 * float(effective_stacks) * factor
			return "Ao comprar: +%.2f%% de roubo de vida adicional (+%d%%)" % [ls_pct, total_scale_pct]
		"Sorte":
			var luck_pct: float = 0.3 * float(effective_stacks) * factor
			return "Ao comprar: +%.2f%% de sorte adicional (+%d%%)" % [luck_pct, total_scale_pct]
		"Porcao":
			return "Ao comprar: +%d%% de ganho de vida maxima e cura obtida" % total_scale_pct
		"inercia_cronal":
			var ctrl_pct: float = 8.0 * float(effective_stacks) * factor
			var kb_pct: float = 18.0 * float(effective_stacks) * factor
			return "Ao comprar: +%.1f%% resist. controle e +%.1f%% resist. empurrao (+%d%%)" % [ctrl_pct, kb_pct, total_scale_pct]
		"leitura_instante":
			var win_pct: float = 7.0 * float(effective_stacks) * factor
			return "Ao comprar: +%.1f%% de antecedencia visual de ataques (+%d%%)" % [win_pct, total_scale_pct]
		"margem_segura":
			var dist_val: float = 35.0 * float(effective_stacks) * factor
			return "Ao comprar: +%.1f de distancia segura de spawn (+%d%%) [limite: 140]" % [dist_val, total_scale_pct]
		"moeda_estavel":
			var econ_val: float = 6.0 * float(effective_stacks) * factor
			return "Ao comprar: -%.1f no incremento de preco da loja (+%d%%)" % [econ_val, total_scale_pct]
		"orbita_coletora":
			var rad_pct: float = 22.0 * float(effective_stacks) * factor
			return "Ao comprar: +%.1f%% no raio de coleta de recursos (+%d%%)" % [rad_pct, total_scale_pct]
		"pacto_possibilidades":
			var disc_pct: float = 4.0 * float(effective_stacks) * factor
			return "Ao comprar: +%.1f%% de desconto para cartas novas (+%d%%)" % [disc_pct, total_scale_pct]
		"solo_consolidado":
			var sol_pct: float = 8.0 * float(effective_stacks) * factor
			return "Ao comprar: +%.1f%% de reducao na duracao de perigos de chao (+%d%%)" % [sol_pct, total_scale_pct]
		"intervalo_fraturado":
			return "Ao comprar: +%d%% na reducao de recarga de Hab1 e Ultimate" % total_scale_pct
		"tregua_regenerativa":
			return "Ao comprar: +%d%% na taxa de regeneracao passiva" % total_scale_pct
		"reserva_pulso":
			return "Ao comprar: +%d%% na capacidade de cura guardada" % total_scale_pct
		"casulo_reativo":
			return "Ao comprar: +%d%% na mitigacao e duracao do casulo reativo" % total_scale_pct
		"passagem_intangivel":
			return "Ao comprar: +%d%% na duracao de intangibilidade pos-teleporte" % total_scale_pct
		"ancora_vital":
			return "Ao comprar: +%d%% no retorno de vida e duracao da ancora" % total_scale_pct
		"nucleo_revigorante":
			return "Ao comprar: +%d%% na cura concedida por orbes no mapa" % total_scale_pct
		"limiar_de_ruina":
			return "Ao comprar: +%d%% no bonus de dano de abertura contra alvos >90%% HP" % total_scale_pct
		"estase_reparadora":
			return "Ao comprar: +%d%% na taxa de regeneracao em repouso" % total_scale_pct
		"fratura_cronal":
			return "Ao comprar: +%d%% no dano de fragilidade temporal" % total_scale_pct
		"pulso_desestabilizador":
			return "Ao comprar: +%d%% no dano e area da explosao instavel" % total_scale_pct
		"pressao_cerco":
			return "Ao comprar: +%d%% no bonus de dano por alvos cercados" % total_scale_pct
		"choque_fontes":
			return "Ao comprar: +%d%% no dano da descarga por fontes diferentes" % total_scale_pct
		"ferrolho_ruptura":
			return "Ao comprar: +%d%% na duracao de fixacao e lentidao em chefe" % total_scale_pct
		"limiar_colapso":
			return "Ao comprar: +%d%% no dano de ruptura por vida" % total_scale_pct
		"desvio_probabilidade":
			return "Ao comprar: +%d%% no contragolpe fortalecido por quase-acerto" % total_scale_pct
		"ponto_cego":
			return "Ao comprar: +%d%% no dano pelas costas e desorientacao" % total_scale_pct
		"rastro_de_retorno", "municao_de_rebate", "impulso_de_sobras", "eco_de_impacto", "zona_de_descompressao", "folego_de_perseguicao", "margem_de_erro", "ressonancia_de_alternancia":
			var def: Dictionary = get_card_definition(card_id)
			var label: String = String(def.get("stat_label", "atributos da carta"))
			return "Ao comprar: +%d%% de eficacia em %s" % [total_scale_pct, label]
		_:
			var def: Dictionary = get_card_definition(card_id)
			if not def.is_empty() and bool(def.get("can_burn", false)):
				var label: String = String(def.get("stat_label", "atributos da carta"))
				return "Ao comprar: +%d%% de poder adicional em %s" % [total_scale_pct, label]
			return "Ao comprar: carta nao elegivel para fortalecimento por cinzas"
