extends RefCounted
class_name RTManifestEvolutionCatalog

const MANIFESTATION_COUNT := 5
const EVOLUTIONS_PER_STAGE := 6
const TOTAL_EVOLUTIONS := 60
const DEFINITION_SCHEMA_VERSION := 1

const LEGACY_FAMILIES := {
	"eco": true,
	"perfuracao": true,
	"caca": true,
	"elo": true,
	"pulso": true,
	"vortice": true,
	"selo": true,
	"campo": true,
	"passo": true
}

const MANIFEST_THEMES := {
	"eletrica": {"label": "Elétrica", "essence": "sobrecarga e condução", "visual": "arcos, corona e redes Tesla", "tag": "rede_eletrica"},
	"lacerante": {"label": "Lacerante", "essence": "cortes, cicatrizes e abate", "visual": "lâminas rubras e rasgos no chão", "tag": "corte"},
	"prismatica": {"label": "Prismática", "essence": "geometria, luz e refração", "visual": "prismas, triângulos e espectros", "tag": "luz"},
	"parasitica": {"label": "Parasítica", "essence": "infestação, hospedeiros e colônia", "visual": "larvas, raízes orgânicas e ovos", "tag": "organico"},
	"gravitante": {"label": "Gravitante", "essence": "massa, órbita e singularidade", "visual": "lentes, órbitas e horizontes de evento", "tag": "gravidade"}
}

const STAGE_EFFECTS := {
	"ev1": [
		{"effect": "projectile_echo", "label": "ecos ofensivos", "hook": "projectile", "every": 4, "scale": 0.34, "spread": 0.18, "limit": 10},
		{"effect": "projectile_pierce", "label": "travessia marcada", "hook": "projectile", "pierces": 1, "limit": 6},
		{"effect": "projectile_homing", "label": "leitura de alvo", "hook": "projectile", "turn": 0.16, "range": 330.0, "limit": 8},
		{"effect": "impact_link", "label": "vínculo entre inimigos", "hook": "impact", "radius": 150.0, "slow": 0.74, "limit": 18},
		{"effect": "impact_burst", "label": "pulso de ruptura", "hook": "impact", "every": 4, "radius": 145.0, "force": 82.0, "damage": 0.14, "limit": 12},
		{"effect": "impact_seal", "label": "marca persistente", "hook": "impact", "hits": 3, "duration": 0.72, "limit": 24}
	],
	"ev2": [
		{"effect": "impact_vortex", "label": "convergência local", "hook": "impact", "every": 4, "radius": 168.0, "force": 92.0, "damage": 0.12, "limit": 10},
		{"effect": "skill_field", "label": "campo persistente", "hook": "skill", "radius": 174.0, "duration": 3.6, "slow": 0.68, "damage": 0.055, "limit": 4},
		{"effect": "teleport_burst", "label": "rasgo de deslocamento", "hook": "teleport", "radius": 156.0, "force": 94.0, "damage": 0.12, "limit": 6},
		{"effect": "projectile_echo_plus", "label": "duplicação avançada", "hook": "projectile", "every": 3, "scale": 0.42, "spread": 0.28, "limit": 12},
		{"effect": "impact_chain_burst", "label": "cadeia de impacto", "hook": "impact", "every": 3, "radius": 158.0, "force": 96.0, "damage": 0.17, "limit": 10},
		{"effect": "grand_manifestation", "label": "estado supremo", "hook": "hybrid", "every": 4, "radius": 190.0, "force": 104.0, "damage": 0.13, "turn": 0.11, "range": 300.0, "pierces": 1, "limit": 8}
	]
}

# Phase 1 registry migration: every legacy ID is explicitly bound to its
# existing behavior.  Consumers resolve by stable ID; no mechanic is selected
# from an offer position.  Reworks replace one binding at a time without
# changing UI, save or network IDs.
const EXPLICIT_LEGACY_DEFINITION_IDS_BY_EFFECT := {
	"projectile_echo": "eletrica_ev1_arco_condutor|lacerante_ev1_hemorragia_crescente|parasitica_ev1_reproducao|gravitante_ev1_roche",
	"projectile_pierce": "eletrica_ev1_carga_residual|lacerante_ev1_cicatriz_aberta|parasitica_ev1_hospedeiro_alfa|gravitante_ev1_slingshot",
	"projectile_homing": "eletrica_ev1_polarizacao|lacerante_ev1_predador_rubro|parasitica_ev1_necrofagia|gravitante_ev1_mass_growth",
	"impact_link": "eletrica_ev1_bobina_ambulante|lacerante_ev1_carnificina_circular|parasitica_ev1_colonia|gravitante_ev1_binary",
	"impact_burst": "eletrica_ev1_relampago_critico|lacerante_ev1_coagulo_vivo|parasitica_ev1_ninho_ambulante|gravitante_ev1_captive_moon",
	"impact_seal": "eletrica_ev1_condutor_vivo|lacerante_ev1_linha_abate|parasitica_ev1_metamorfose|gravitante_ev1_tidal_step",
	"impact_vortex": "eletrica_ev2_tempestade_autonoma|lacerante_ev2_ruptura_arterial|parasitica_ev2_epidemia|gravitante_ev2_shared_singularity",
	"skill_field": "eletrica_ev2_sobrecarga_cascata|lacerante_ev2_danca_laminas|parasitica_ev2_colmeia_neural|gravitante_ev2_planetary_system",
	"teleport_burst": "eletrica_ev2_pararraios|lacerante_ev2_sangue_atrai_sangue|parasitica_ev2_super_hospedeiro|gravitante_ev2_tidal_event",
	"projectile_echo_plus": "eletrica_ev2_campo_ionizado|lacerante_ev2_cicatriz_persistente|parasitica_ev2_ciclo_biologico|gravitante_ev2_mass_collapse",
	"impact_chain_burst": "eletrica_ev2_ruptura_atmosferica|lacerante_ev2_coagulacao_violenta|parasitica_ev2_eclosao_coletiva|gravitante_ev2_chaotic_orbit",
	"grand_manifestation": "eletrica_ev2_tempestade_ruptura|lacerante_ev2_execucao_cadeia|parasitica_ev2_organismo_ruptura|gravitante_ev2_rupture_horizon"
}

const PRISMATICA_PROFILE_KEY_BY_ID := {
	"prismatica_ev1_reflexao_dupla": "prismatica_reflexao_dupla", "prismatica_ev1_prisma_espelhado": "prismatica_prisma_espelhado", "prismatica_ev1_triangulacao": "prismatica_triangulacao", "prismatica_ev1_espectro_separado": "prismatica_espectro_separado", "prismatica_ev1_prisma_encadeado": "prismatica_prisma_encadeado", "prismatica_ev1_reflexo_fantasma": "prismatica_reflexo_fantasma",
	"prismatica_ev2_geometria_perfeita": "prismatica_geometria_perfeita", "prismatica_ev2_luz_recursiva": "prismatica_luz_recursiva", "prismatica_ev2_prisma_harmonico": "prismatica_prisma_harmonico", "prismatica_ev2_foco_absoluto": "prismatica_foco_absoluto", "prismatica_ev2_rede_espectral": "prismatica_rede_espectral", "prismatica_ev2_colapso_cromatico": "prismatica_colapso_cromatico"
}

const LACERANTE_MELEE_PROFILE_OVERRIDES := {
	"lacerante_ev1_hemorragia_crescente": {"hook": "impact", "non_projectile": true, "summary": "Cada quarto corte repete 34% do dano-base no alvo e aprofunda 1 laceração. Conta somente acertos corpo a corpo resolvidos."},
	"lacerante_ev1_cicatriz_aberta": {"hook": "impact", "non_projectile": true, "summary": "O corte atravessa o primeiro alvo e atinge até 2 inimigos alinhados atrás dele por 45% do dano-base, em um corredor de 190 px."},
	"lacerante_ev1_predador_rubro": {"hook": "impact", "non_projectile": true, "summary": "Após acertar, a lâmina salta para o inimigo vivo mais próximo em 350 px e causa 40% do dano-base. Não retorna ao alvo original."},
	"lacerante_ev2_cicatriz_persistente": {"hook": "impact", "non_projectile": true, "summary": "Cada terceiro corte abre uma cicatriz com 3 pulsos de 18% do dano-base, separados por 0,5 s. Máximo: 6 cicatrizes."},
	"lacerante_ev2_execucao_cadeia": {"hook": "impact", "non_projectile": true, "summary": "Ao golpear um alvo derrotado ou abaixo de 30% da vida, encadeia até 3 inimigos próximos por 60% do dano-base. O encadeamento não se repete sozinho."}
}

# Prismatica deliberately does not use STAGE_EFFECTS.  Its evolutions are a
# small tactical grammar (surfaces, formations and light routes), not renamed
# variants of the generic manifest presets used by the remaining catalog.
const PRISMATICA_PROFILES := {
	"ev1": [
		{"effect": "prismatica_reflexao_dupla", "hook": "impact", "label": "dois ricochetes guiados", "summary": "Após acertar, o raio se reflete rumo a outro alvo; até 2 desvios por disparo.", "limit": 2},
		{"effect": "prismatica_prisma_espelhado", "hook": "skill", "label": "espelhos posicionados", "summary": "A habilidade posiciona até 2 prismas-espelho que viram raios ao tocar suas faces.", "limit": 2, "duration": 7.0},
		{"effect": "prismatica_triangulacao", "hook": "skill", "label": "triângulo de convergência", "summary": "A habilidade forma um triângulo; raios que atravessam sua área alinham a rota e explodem no próximo impacto.", "limit": 1, "duration": 6.5},
		{"effect": "prismatica_espectro_separado", "hook": "impact", "label": "espectro por impacto", "summary": "O primeiro impacto de cada raio separa duas cores laterais, uma vez e com trajetória curta.", "limit": 1},
		{"effect": "prismatica_prisma_encadeado", "hook": "impact", "label": "elos entre alvos", "summary": "Acertos ancoram prismas; o próximo acerto conecta dois nós e fere quem cruzar o elo luminoso.", "limit": 3, "duration": 5.5},
		{"effect": "prismatica_reflexo_fantasma", "hook": "teleport", "label": "eco do deslocamento", "summary": "Depois de teleportar, um reflexo repete o disparo na direção da fuga após um breve atraso.", "limit": 2, "delay": 0.42}
	],
	"ev2": [
		{"effect": "prismatica_geometria_perfeita", "hook": "skill", "label": "ângulos perfeitos", "summary": "Cria uma formação maior: raios dentro dela encontram uma linha direta e preservam um impacto perfurante.", "limit": 1, "duration": 7.5},
		{"effect": "prismatica_luz_recursiva", "hook": "impact", "label": "retorno condicionado", "summary": "Um raio já refletido pode retornar uma única vez se atingir um alvo marcado pela luz.", "limit": 1},
		{"effect": "prismatica_prisma_harmonico", "hook": "skill", "label": "pulsos de formação", "summary": "Três prismas harmônicos pulsam em compasso, ferindo e desacelerando a área entre eles.", "limit": 1, "duration": 6.0},
		{"effect": "prismatica_foco_absoluto", "hook": "impact", "label": "foco por alvo", "summary": "Acertos consecutivos no mesmo alvo acumulam foco; o quarto dispara uma linha de precisão e interrompe a reação.", "limit": 4},
		{"effect": "prismatica_rede_espectral", "hook": "skill", "label": "malha de interceptação", "summary": "Posiciona uma rede triangular; inimigos que cruzam seus segmentos recebem uma descarga limitada.", "limit": 1, "duration": 5.5},
		{"effect": "prismatica_colapso_cromatico", "hook": "skill", "label": "colapso das formações", "summary": "A habilidade consome formações ativas em uma única explosão cromática; sem formação, prepara uma semente geométrica.", "limit": 1}
	]
}

const RAW_ROWS := [
	"eletrica|ev1|eletrica_ev1_arco_condutor|Arco Condutor",
	"eletrica|ev1|eletrica_ev1_carga_residual|Carga Residual",
	"eletrica|ev1|eletrica_ev1_polarizacao|Polarização",
	"eletrica|ev1|eletrica_ev1_bobina_ambulante|Bobina Ambulante",
	"eletrica|ev1|eletrica_ev1_relampago_critico|Relâmpago Crítico",
	"eletrica|ev1|eletrica_ev1_condutor_vivo|Condutor Vivo",
	"eletrica|ev2|eletrica_ev2_tempestade_autonoma|Tempestade Autônoma",
	"eletrica|ev2|eletrica_ev2_sobrecarga_cascata|Sobrecarga Em Cascata",
	"eletrica|ev2|eletrica_ev2_pararraios|Para-Raios",
	"eletrica|ev2|eletrica_ev2_campo_ionizado|Campo Ionizado",
	"eletrica|ev2|eletrica_ev2_ruptura_atmosferica|Ruptura Atmosférica",
	"eletrica|ev2|eletrica_ev2_tempestade_ruptura|Tempestade De Ruptura",
	"lacerante|ev1|lacerante_ev1_hemorragia_crescente|Hemorragia Crescente",
	"lacerante|ev1|lacerante_ev1_cicatriz_aberta|Cicatriz Aberta",
	"lacerante|ev1|lacerante_ev1_predador_rubro|Predador Rubro",
	"lacerante|ev1|lacerante_ev1_carnificina_circular|Carnificina Circular",
	"lacerante|ev1|lacerante_ev1_coagulo_vivo|Coágulo Vivo",
	"lacerante|ev1|lacerante_ev1_linha_abate|Linha De Abate",
	"lacerante|ev2|lacerante_ev2_ruptura_arterial|Ruptura Arterial",
	"lacerante|ev2|lacerante_ev2_danca_laminas|Dança Das Lâminas",
	"lacerante|ev2|lacerante_ev2_sangue_atrai_sangue|Sangue Atrai Sangue",
	"lacerante|ev2|lacerante_ev2_cicatriz_persistente|Cicatriz Persistente",
	"lacerante|ev2|lacerante_ev2_coagulacao_violenta|Coagulação Violenta",
	"lacerante|ev2|lacerante_ev2_execucao_cadeia|Execução Em Cadeia",
	"prismatica|ev1|prismatica_ev1_reflexao_dupla|Reflexão Dupla",
	"prismatica|ev1|prismatica_ev1_prisma_espelhado|Prisma Espelhado",
	"prismatica|ev1|prismatica_ev1_triangulacao|Triangulação",
	"prismatica|ev1|prismatica_ev1_espectro_separado|Espectro Separado",
	"prismatica|ev1|prismatica_ev1_prisma_encadeado|Prisma Encadeado",
	"prismatica|ev1|prismatica_ev1_reflexo_fantasma|Reflexo Fantasma",
	"prismatica|ev2|prismatica_ev2_geometria_perfeita|Geometria Perfeita",
	"prismatica|ev2|prismatica_ev2_luz_recursiva|Luz Recursiva",
	"prismatica|ev2|prismatica_ev2_prisma_harmonico|Prisma Harmônico",
	"prismatica|ev2|prismatica_ev2_foco_absoluto|Foco Absoluto",
	"prismatica|ev2|prismatica_ev2_rede_espectral|Rede Espectral",
	"prismatica|ev2|prismatica_ev2_colapso_cromatico|Colapso Cromático",
	"parasitica|ev1|parasitica_ev1_reproducao|Reprodução",
	"parasitica|ev1|parasitica_ev1_hospedeiro_alfa|Hospedeiro Alfa",
	"parasitica|ev1|parasitica_ev1_necrofagia|Necrofagia",
	"parasitica|ev1|parasitica_ev1_colonia|Colônia",
	"parasitica|ev1|parasitica_ev1_ninho_ambulante|Ninho Ambulante",
	"parasitica|ev1|parasitica_ev1_metamorfose|Metamorfose",
	"parasitica|ev2|parasitica_ev2_epidemia|Epidemia",
	"parasitica|ev2|parasitica_ev2_colmeia_neural|Colmeia Neural",
	"parasitica|ev2|parasitica_ev2_super_hospedeiro|Super-Hospedeiro",
	"parasitica|ev2|parasitica_ev2_ciclo_biologico|Ciclo Biológico",
	"parasitica|ev2|parasitica_ev2_eclosao_coletiva|Eclosão Coletiva",
	"parasitica|ev2|parasitica_ev2_organismo_ruptura|Organismo Da Ruptura",
	"gravitante|ev1|gravitante_ev1_roche|Limite De Roche",
	"gravitante|ev1|gravitante_ev1_slingshot|Estilingue Gravitacional",
	"gravitante|ev1|gravitante_ev1_mass_growth|Massa Crescente",
	"gravitante|ev1|gravitante_ev1_binary|Sistema Binário",
	"gravitante|ev1|gravitante_ev1_captive_moon|Lua Cativa",
	"gravitante|ev1|gravitante_ev1_tidal_step|Maré De Passagem",
	"gravitante|ev2|gravitante_ev2_shared_singularity|Singularidade Compartilhada",
	"gravitante|ev2|gravitante_ev2_planetary_system|Sistema Planetário",
	"gravitante|ev2|gravitante_ev2_tidal_event|Evento De Maré",
	"gravitante|ev2|gravitante_ev2_mass_collapse|Colapso De Massa",
	"gravitante|ev2|gravitante_ev2_chaotic_orbit|Órbita Caótica",
	"gravitante|ev2|gravitante_ev2_rupture_horizon|Horizonte De Ruptura",
]

static func all_entries() -> Array:
	var entries: Array = []
	for raw in RAW_ROWS:
		var parts := String(raw).split("|")
		if parts.size() < 4:
			continue
		var manifestation := String(parts[0])
		var stage := String(parts[1])
		entries.append(_build_entry(manifestation, stage, String(parts[2]), String(parts[3])))
	return entries


static func entries_for_manifestation(manifestation: String, stage: String = "") -> Array:
	var result: Array = []
	for entry in all_entries():
		if String(entry.get("manifestation", "")) != manifestation:
			continue
		if stage != "" and String(entry.get("stage", "")) != stage:
			continue
		result.append(entry)
	return result


static func definition_by_id(evolution_id: String) -> Dictionary:
	for entry in all_entries():
		if String(entry.get("id", "")) == evolution_id:
			return entry
	return {}


static func normalize_saved_choice(choice: Dictionary) -> Dictionary:
	# Saves before schema v1 only carry evolution/profile/family.  Keep their
	# serialized profile intact, then attach metadata lazily so a load never
	# mutates its mechanical result or requires a save migration.
	var normalized := choice.duplicate(true)
	var evolution_id := String(normalized.get("evolution", normalized.get("id", "")))
	if evolution_id == "":
		return normalized
	var definition := definition_by_id(evolution_id)
	if definition.is_empty():
		normalized["definition_status"] = "unknown_legacy"
		return normalized
	normalized["definition_id"] = evolution_id
	normalized["definition_schema_version"] = DEFINITION_SCHEMA_VERSION
	normalized["definition_trigger"] = String(definition.get("trigger", ""))
	normalized["definition_conditions"] = Array(definition.get("conditions", [])).duplicate(true)
	normalized["definition_state_key"] = String(definition.get("state_key", ""))
	normalized["definition_status"] = "known"
	if String(normalized.get("effect", "")) == "":
		normalized["effect"] = String(definition.get("effect", ""))
	if String(normalized.get("family", "")) == "":
		normalized["family"] = String(definition.get("family", ""))
	if Dictionary(normalized.get("profile", {})).is_empty():
		normalized["profile"] = Dictionary(definition.get("profile", {})).duplicate(true)
	return normalized


static func validate_catalog() -> Array:
	var errors: Array = []
	var seen: Dictionary = {}
	var counts: Dictionary = {}
	var total := 0
	for entry in all_entries():
		total += 1
		var id := String(entry.get("id", ""))
		var name := String(entry.get("name", ""))
		var description := String(entry.get("short_description", ""))
		var manifestation := String(entry.get("manifestation", ""))
		var stage := String(entry.get("stage", ""))
		var definition := definition_by_id(id)
		if id == "":
			errors.append("empty id")
		elif definition.is_empty():
			errors.append("missing explicit definition for %s" % id)
		if name == "":
			errors.append("empty name for %s" % id)
		if description == "":
			errors.append("empty description for %s" % id)
		if stage != "ev1" and stage != "ev2":
			errors.append("invalid stage for %s" % id)
		if String(definition.get("trigger", "")) == "":
			errors.append("missing trigger for %s" % id)
		if String(definition.get("state_key", "")) == "":
			errors.append("missing state key for %s" % id)
		if String(definition.get("test_target", "")) == "":
			errors.append("missing test target for %s" % id)
		if stage == "ev1" and not id.contains("_ev1_"):
			errors.append("EV1 id mismatch %s" % id)
		if stage == "ev2" and not id.contains("_ev2_"):
			errors.append("EV2 id mismatch %s" % id)
		if seen.has(id):
			errors.append("duplicate id %s" % id)
		seen[id] = true
		var key := "%s|%s" % [manifestation, stage]
		counts[key] = int(counts.get(key, 0)) + 1
	if total != TOTAL_EVOLUTIONS:
		errors.append("expected %d evolutions, got %d" % [TOTAL_EVOLUTIONS, total])
	for manifestation in MANIFEST_THEMES.keys():
		for stage in ["ev1", "ev2"]:
			var key := "%s|%s" % [String(manifestation), stage]
			if int(counts.get(key, 0)) != EVOLUTIONS_PER_STAGE:
				errors.append("%s expected %d %s, got %d" % [String(manifestation), EVOLUTIONS_PER_STAGE, stage, int(counts.get(key, 0))])
	return errors


static func is_legacy_family(family: String) -> bool:
	return LEGACY_FAMILIES.has(family)


static func _build_entry(manifestation: String, stage: String, evolution_id: String, display_name: String) -> Dictionary:
	var theme: Dictionary = MANIFEST_THEMES.get(manifestation, {"label": manifestation.capitalize(), "essence": manifestation, "visual": "ruptura temporal", "tag": manifestation})
	var profile := _profile_for_id(manifestation, stage, evolution_id)
	var trigger := String(profile.get("hook", "hybrid"))
	return {
		"id": evolution_id,
		"definition_id": evolution_id,
		"definition_schema_version": DEFINITION_SCHEMA_VERSION,
		"manifestation": manifestation,
		"stage": stage,
		"name": display_name,
		"family": String(profile.get("effect", "specific")),
		"effect": String(profile.get("effect", "specific")),
		"effect_label": String(profile.get("label", "efeito próprio")),
		"summary": _short_description(display_name, theme, profile, stage),
		"short_description": _short_description(display_name, theme, profile, stage),
		"tags": [String(theme.get("tag", manifestation)), stage, trigger],
		"trigger": trigger,
		"conditions": _conditions_for_trigger(trigger),
		"state_key": "manifest_evolution.choice.%s" % evolution_id,
		"state_policy": "choice_scoped",
		"visual_tag": String(profile.get("visual_tag", theme.get("tag", manifestation))),
		"test_target": "manifest_evolution_public_contract_smoke:%s" % evolution_id,
		"profile": profile
	}


static func _profile_for_id(manifestation: String, stage: String, evolution_id: String) -> Dictionary:
	var effect_key := _explicit_effect_key(evolution_id)
	if effect_key == "":
		return {}
	if manifestation == "prismatica":
		for candidate in Array(PRISMATICA_PROFILES.get(stage, [])):
			var prismatica_profile := Dictionary(candidate)
			if String(prismatica_profile.get("effect", "")) != effect_key:
				continue
			prismatica_profile = prismatica_profile.duplicate(true)
			prismatica_profile["manifestation"] = manifestation
			prismatica_profile["signature"] = evolution_id
			prismatica_profile["visual_tag"] = "luz"
			return prismatica_profile
	var base := _shared_profile_for_effect(stage, effect_key)
	if base.is_empty():
		return {}
	var manifest_index := MANIFEST_THEMES.keys().find(manifestation)
	if manifest_index < 0:
		manifest_index = 0
	var m := float(manifest_index % 5)
	base["manifestation"] = manifestation
	base["signature"] = evolution_id
	base["visual_tag"] = String(MANIFEST_THEMES.get(manifestation, {}).get("tag", manifestation))
	base["every"] = max(2, int(base.get("every", 4)) - int(effect_key == "impact_burst" or effect_key == "impact_chain_burst"))
	base["radius"] = float(base.get("radius", 145.0)) + m * 6.0
	base["force"] = float(base.get("force", 82.0)) + m * 5.0
	base["range"] = float(base.get("range", 330.0)) + m * 12.0
	base["spread"] = float(base.get("spread", 0.18)) + float(_legacy_tuning_index(effect_key)) * 0.012
	if LACERANTE_MELEE_PROFILE_OVERRIDES.has(evolution_id):
		var melee_override: Dictionary = Dictionary(LACERANTE_MELEE_PROFILE_OVERRIDES[evolution_id])
		for key in melee_override:
			base[key] = melee_override[key]
	return base


static func _explicit_effect_key(evolution_id: String) -> String:
	if PRISMATICA_PROFILE_KEY_BY_ID.has(evolution_id):
		return String(PRISMATICA_PROFILE_KEY_BY_ID[evolution_id])
	for effect_key in EXPLICIT_LEGACY_DEFINITION_IDS_BY_EFFECT:
		if String(EXPLICIT_LEGACY_DEFINITION_IDS_BY_EFFECT[effect_key]).split("|").has(evolution_id):
			return String(effect_key)
	return ""


static func _shared_profile_for_effect(stage: String, effect_key: String) -> Dictionary:
	for candidate in Array(STAGE_EFFECTS.get(stage, [])):
		var profile := Dictionary(candidate)
		if String(profile.get("effect", "")) == effect_key:
			return profile.duplicate(true)
	return {}


static func _legacy_tuning_index(effect_key: String) -> int:
	var order := ["projectile_echo", "projectile_pierce", "projectile_homing", "impact_link", "impact_burst", "impact_seal", "impact_vortex", "skill_field", "teleport_burst", "projectile_echo_plus", "impact_chain_burst", "grand_manifestation"]
	var index := order.find(effect_key)
	if index < 0:
		return 0
	return index - EVOLUTIONS_PER_STAGE if index >= EVOLUTIONS_PER_STAGE else index


static func _conditions_for_trigger(trigger: String) -> Array:
	match trigger:
		"combo": return ["attack_emitted", "combo_stage_3", "non_projectile_hook"]
		"tension": return ["tension_gained", "overcharge_consumed"]
		"projectile": return ["attack_emitted", "projectile_owned_by_peer"]
		"impact": return ["hit_resolved", "valid_distinct_target"]
		"skill": return ["skill_cast", "successful_skill"]
		"teleport": return ["teleport", "successful_teleport"]
		"secondary": return ["secondary_cast", "bound_target"]
		"risk": return ["player_alive", "hp_at_or_below_threshold", "internal_cooldown_ready"]
		_: return ["attack_emitted", "hit_resolved"]


static func _short_description(display_name: String, theme: Dictionary, profile: Dictionary, stage: String) -> String:
	if String(profile.get("manifestation", "")) == "prismatica":
		return String(profile.get("summary", "%s — efeito Prismática." % display_name))
	var label := "EV1" if stage == "ev1" else "EV2"
	return "%s — %s converte %s em %s, com leitura visual de %s." % [label, display_name.capitalize(), String(theme.get("essence", "ruptura")), String(profile.get("label", "efeito próprio")), String(theme.get("visual", "ruptura temporal"))]
