extends RefCounted
class_name RTManifestEvolutionCatalog

const MANIFESTATION_COUNT := 15
const EVOLUTIONS_PER_STAGE := 6
const TOTAL_EVOLUTIONS := 180

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
	"retornante": {"label": "Retornante", "essence": "retorno, memória de trajeto e paradoxo", "visual": "afterimages e curvas reversas", "tag": "tempo"},
	"parasitica": {"label": "Parasítica", "essence": "infestação, hospedeiros e colônia", "visual": "larvas, raízes orgânicas e ovos", "tag": "organico"},
	"gravitante": {"label": "Gravitante", "essence": "massa, órbita e singularidade", "visual": "lentes, órbitas e horizontes de evento", "tag": "gravidade"},
	"ancorada": {"label": "Ancorada", "essence": "fundação, peso e território", "visual": "placas, marcos e impacto de estrutura", "tag": "territorio"},
	"cartografica": {"label": "Cartográfica", "essence": "rotas, coordenadas e mapas hostis", "visual": "grades, linhas e marcadores de rota", "tag": "mapa"},
	"mnesica": {"label": "Mnésica", "essence": "memória, replay e trauma temporal", "visual": "fragmentos de lembrança e fantasmas", "tag": "memoria"},
	"ressonante": {"label": "Ressonante", "essence": "ondas, compasso e harmonia", "visual": "notas, círculos sonoros e batidas", "tag": "som"},
	"contratual": {"label": "Contratual", "essence": "cláusulas, julgamento e prova", "visual": "selos, documentos e sentença", "tag": "contrato"},
	"acorrentada": {"label": "Acorrentada", "essence": "tensão, grilhões e prisão", "visual": "correntes, ganchos e elos físicos", "tag": "corrente"},
	"eclipsada": {"label": "Eclipsada", "essence": "Sol, Lua, sombra e totalidade", "visual": "coroas negras, ouro e penumbra", "tag": "eclipse"},
	"bombastica": {"label": "Bombástica", "essence": "pólvora, estilhaço e detonação", "visual": "fumaça, faíscas e explosões físicas", "tag": "explosao"},
	"necronada": {"label": "Necronada", "essence": "rosas azuis, ossuário e cortejo", "visual": "raízes funerárias, espíritos e pétalas", "tag": "funerario"}
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
	"retornante|ev1|retornante_ev1_retorno_duplo|Retorno Duplo",
	"retornante|ev1|retornante_ev1_memoria_trajeto|Memória De Trajeto",
	"retornante|ev1|retornante_ev1_corte_cruzado|Corte Cruzado",
	"retornante|ev1|retornante_ev1_cacador_reverso|Caçador Reverso",
	"retornante|ev1|retornante_ev1_ancora_temporal|Âncora Temporal",
	"retornante|ev1|retornante_ev1_rastro_paradoxal|Rastro Paradoxal",
	"retornante|ev2|retornante_ev2_repeticao_impossivel|Repetição Impossível",
	"retornante|ev2|retornante_ev2_convergencia|Convergência",
	"retornante|ev2|retornante_ev2_paradoxo_fechado|Paradoxo Fechado",
	"retornante|ev2|retornante_ev2_rebobinamento_violento|Rebobinamento Violento",
	"retornante|ev2|retornante_ev2_passado_persistente|Passado Persistente",
	"retornante|ev2|retornante_ev2_ciclo_temporal|Ciclo Temporal",
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
	"ancorada|ev1|ancorada_ev1_fundacao_profunda|Fundação Profunda",
	"ancorada|ev1|ancorada_ev1_muralha_ruptura|Muralha De Ruptura",
	"ancorada|ev1|ancorada_ev1_peso_absoluto|Peso Absoluto",
	"ancorada|ev1|ancorada_ev1_territorio_jurado|Território Jurado",
	"ancorada|ev1|ancorada_ev1_contra_impacto|Contra-Impacto",
	"ancorada|ev1|ancorada_ev1_linha_fundacao|Linha De Fundação",
	"ancorada|ev2|ancorada_ev2_fortaleza_autoportante|Fortaleza Autoportante",
	"ancorada|ev2|ancorada_ev2_coracao_fortaleza|Coração Da Fortaleza",
	"ancorada|ev2|ancorada_ev2_queda_monumental|Queda Monumental",
	"ancorada|ev2|ancorada_ev2_rede_fundacoes|Rede De Fundações",
	"ancorada|ev2|ancorada_ev2_ultimo_bastiao|Último Bastião",
	"ancorada|ev2|ancorada_ev2_continente_imovel|Continente Imóvel",
	"cartografica|ev1|cartografica_ev1_coordenada_fantasma|Coordenada Fantasma",
	"cartografica|ev1|cartografica_ev1_rota_interceptacao|Rota De Interceptação",
	"cartografica|ev1|cartografica_ev1_triangulacao_hostil|Triangulação Hostil",
	"cartografica|ev1|cartografica_ev1_marco_movel|Marco Móvel",
	"cartografica|ev1|cartografica_ev1_cartografia_residual|Cartografia Residual",
	"cartografica|ev1|cartografica_ev1_atalho_dimensional|Atalho Dimensional",
	"cartografica|ev2|cartografica_ev2_mapa_completo|Mapa Completo",
	"cartografica|ev2|cartografica_ev2_fronteira_proibida|Fronteira Proibida",
	"cartografica|ev2|cartografica_ev2_cartografia_recursiva|Cartografia Recursiva",
	"cartografica|ev2|cartografica_ev2_convergencia_meridianos|Convergência De Meridianos",
	"cartografica|ev2|cartografica_ev2_rota_emergencia|Rota De Emergência",
	"cartografica|ev2|cartografica_ev2_atlas_ruptura|Atlas Da Ruptura",
	"mnesica|ev1|mnesica_ev1_memoria_dolorosa|Memória Dolorosa",
	"mnesica|ev1|mnesica_ev1_reflexo_comportamental|Reflexo Comportamental",
	"mnesica|ev1|mnesica_ev1_falso_passado|Falso Passado",
	"mnesica|ev1|mnesica_ev1_lembranca_compartilhada|Lembrança Compartilhada",
	"mnesica|ev1|mnesica_ev1_arquivo_profundo|Arquivo Profundo",
	"mnesica|ev1|mnesica_ev1_eco_dor|Eco De Dor",
	"mnesica|ev2|mnesica_ev2_dejavu_coletivo|Déjà-Vu Coletivo",
	"mnesica|ev2|mnesica_ev2_memoria_recursiva|Memória Recursiva",
	"mnesica|ev2|mnesica_ev2_arquivo_vivo|Arquivo Vivo",
	"mnesica|ev2|mnesica_ev2_reencenacao|Reencenação",
	"mnesica|ev2|mnesica_ev2_esquecimento_forcado|Esquecimento Forçado",
	"mnesica|ev2|mnesica_ev2_trauma_temporal|Trauma Temporal",
	"ressonante|ev1|ressonante_ev1_contraponto|Contraponto",
	"ressonante|ev1|ressonante_ev1_acorde_crescente|Acorde Crescente",
	"ressonante|ev1|ressonante_ev1_harmonia_compartilhada|Harmonia Compartilhada",
	"ressonante|ev1|ressonante_ev1_nota_sustentada|Nota Sustentada",
	"ressonante|ev1|ressonante_ev1_improviso|Improviso",
	"ressonante|ev1|ressonante_ev1_sincope|Síncope",
	"ressonante|ev2|ressonante_ev2_orquestra_ruptura|Orquestra Da Ruptura",
	"ressonante|ev2|ressonante_ev2_crescendo_absoluto|Crescendo Absoluto",
	"ressonante|ev2|ressonante_ev2_refrao|Refrão",
	"ressonante|ev2|ressonante_ev2_harmonico_superior|Harmônico Superior",
	"ressonante|ev2|ressonante_ev2_batida_ruptura|Batida De Ruptura",
	"ressonante|ev2|ressonante_ev2_sinfonia_temporal|Sinfonia Temporal",
	"contratual|ev1|contratual_ev1_clausula_dupla|Cláusula Dupla",
	"contratual|ev1|contratual_ev1_jurisprudencia|Jurisprudência",
	"contratual|ev1|contratual_ev1_agravante|Agravante",
	"contratual|ev1|contratual_ev1_notificacao_cadeia|Notificação Em Cadeia",
	"contratual|ev1|contratual_ev1_testemunha|Testemunha",
	"contratual|ev1|contratual_ev1_processo_coletivo|Processo Coletivo",
	"contratual|ev2|contratual_ev2_precedente|Precedente",
	"contratual|ev2|contratual_ev2_sentenca_coletiva|Sentença Coletiva",
	"contratual|ev2|contratual_ev2_tribunal_ruptura|Tribunal Da Ruptura",
	"contratual|ev2|contratual_ev2_acumulo_provas|Acúmulo De Provas",
	"contratual|ev2|contratual_ev2_mandado_automatico|Mandado Automático",
	"contratual|ev2|contratual_ev2_clausula_suprema|Cláusula Suprema",
	"acorrentada|ev1|acorrentada_ev1_corrente_tripla|Corrente Tripla",
	"acorrentada|ev1|acorrentada_ev1_tensao_residual|Tensão Residual",
	"acorrentada|ev1|acorrentada_ev1_grilhao_movel|Grilhão Móvel",
	"acorrentada|ev1|acorrentada_ev1_elo_espelhado|Elo Espelhado",
	"acorrentada|ev1|acorrentada_ev1_ancora_corrente|Âncora De Corrente",
	"acorrentada|ev1|acorrentada_ev1_sobretensao_continua|Sobretensão Contínua",
	"acorrentada|ev2|acorrentada_ev2_teia_grilhoes|Teia De Grilhões",
	"acorrentada|ev2|acorrentada_ev2_ruptura_sequencial|Ruptura Sequencial",
	"acorrentada|ev2|acorrentada_ev2_corrente_arrasto|Corrente De Arrasto",
	"acorrentada|ev2|acorrentada_ev2_prisao_total|Prisão Total",
	"acorrentada|ev2|acorrentada_ev2_sobrecarga_tensao|Sobrecarga De Tensão",
	"acorrentada|ev2|acorrentada_ev2_sentenca_ferro|Sentença De Ferro",
	"eclipsada|ev1|eclipsada_ev1_dualidade_residual|Dualidade Residual",
	"eclipsada|ev1|eclipsada_ev1_horizonte_eclipse|Horizonte Eclipse",
	"eclipsada|ev1|eclipsada_ev1_orbita_celeste|Órbita Solar / Lunar",
	"eclipsada|ev1|eclipsada_ev1_crepusculo|Crepúsculo",
	"eclipsada|ev1|eclipsada_ev1_reflexo_celeste|Reflexo Celeste",
	"eclipsada|ev1|eclipsada_ev1_conjuncao|Conjunção",
	"eclipsada|ev2|eclipsada_ev2_eclipse_parcial|Eclipse Parcial",
	"eclipsada|ev2|eclipsada_ev2_coroa_negra|Coroa Negra",
	"eclipsada|ev2|eclipsada_ev2_umbra_solar|Umbra Solar",
	"eclipsada|ev2|eclipsada_ev2_penumbra_viva|Penumbra Viva",
	"eclipsada|ev2|eclipsada_ev2_conjuncao_perfeita|Conjunção Perfeita",
	"eclipsada|ev2|eclipsada_ev2_totalidade|Totalidade",
	"bombastica|ev1|bombastica_ev1_polvora_volatil|Pólvora Volátil",
	"bombastica|ev1|bombastica_ev1_estilhaco_persistente|Estilhaço Persistente",
	"bombastica|ev1|bombastica_ev1_fusivel_compartilhado|Fusível Compartilhado",
	"bombastica|ev1|bombastica_ev1_mina_improvisada|Mina Improvisada",
	"bombastica|ev1|bombastica_ev1_bomba_reativa|Bomba Reativa",
	"bombastica|ev1|bombastica_ev1_barril_ruptura|Barril De Ruptura",
	"bombastica|ev2|bombastica_ev2_reacao_cadeia|Reação Em Cadeia",
	"bombastica|ev2|bombastica_ev2_detonacao_fractal|Detonação Fractal",
	"bombastica|ev2|bombastica_ev2_campo_minado|Campo Minado",
	"bombastica|ev2|bombastica_ev2_estopim_errante|Estopim Errante",
	"bombastica|ev2|bombastica_ev2_supernova_polvora|Supernova De Pólvora",
	"bombastica|ev2|bombastica_ev2_demolicao_total|Demolição Total",
	"necronada|ev1|necronada_ev1_rosa_epitafio|Rosa Epitáfio",
	"necronada|ev1|necronada_ev1_ossuario_ambulante|Ossuário Ambulante",
	"necronada|ev1|necronada_ev1_memoria_morto|Memória Do Morto",
	"necronada|ev1|necronada_ev1_cortejo_funebre|Cortejo Fúnebre",
	"necronada|ev1|necronada_ev1_jardim_azul|Jardim Azul",
	"necronada|ev1|necronada_ev1_epitafio_profundo|Epitáfio Profundo",
	"necronada|ev2|necronada_ev2_jardim_mortos|Jardim Dos Mortos",
	"necronada|ev2|necronada_ev2_procissao|Procissão",
	"necronada|ev2|necronada_ev2_heranca_mortuaria|Herança Mortuária",
	"necronada|ev2|necronada_ev2_ossuario_recursivo|Ossuário Recursivo",
	"necronada|ev2|necronada_ev2_rei_vestigios|Rei Dos Vestígios",
	"necronada|ev2|necronada_ev2_ressurreicao_massa|Ressurreição Em Massa",
]

static func all_entries() -> Array:
	var entries: Array = []
	var stage_slots: Dictionary = {}
	for raw in RAW_ROWS:
		var parts := String(raw).split("|")
		if parts.size() < 4:
			continue
		var manifestation := String(parts[0])
		var stage := String(parts[1])
		var slot_key := "%s|%s" % [manifestation, stage]
		var slot := int(stage_slots.get(slot_key, 0))
		stage_slots[slot_key] = slot + 1
		entries.append(_build_entry(manifestation, stage, String(parts[2]), String(parts[3]), slot))
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
		if id == "":
			errors.append("empty id")
		if name == "":
			errors.append("empty name for %s" % id)
		if description == "":
			errors.append("empty description for %s" % id)
		if stage != "ev1" and stage != "ev2":
			errors.append("invalid stage for %s" % id)
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


static func _build_entry(manifestation: String, stage: String, evolution_id: String, display_name: String, slot: int) -> Dictionary:
	var theme: Dictionary = MANIFEST_THEMES.get(manifestation, {"label": manifestation.capitalize(), "essence": manifestation, "visual": "ruptura temporal", "tag": manifestation})
	var profile := _profile_for(manifestation, stage, slot)
	return {
		"id": evolution_id,
		"manifestation": manifestation,
		"stage": stage,
		"name": display_name,
		"family": String(profile.get("effect", "specific")),
		"effect": String(profile.get("effect", "specific")),
		"effect_label": String(profile.get("label", "efeito próprio")),
		"summary": _short_description(display_name, theme, profile, stage),
		"short_description": _short_description(display_name, theme, profile, stage),
		"tags": [String(theme.get("tag", manifestation)), stage, String(profile.get("hook", "hybrid"))],
		"profile": profile
	}


static func _profile_for(manifestation: String, stage: String, slot: int) -> Dictionary:
	var stage_table: Array = STAGE_EFFECTS.get(stage, [])
	var base: Dictionary = Dictionary(stage_table[slot % max(1, stage_table.size())]).duplicate(true)
	var manifest_index := MANIFEST_THEMES.keys().find(manifestation)
	if manifest_index < 0:
		manifest_index = 0
	var m := float(manifest_index % 5)
	base["slot"] = slot
	base["manifestation"] = manifestation
	base["signature"] = "%s_%s_%02d" % [manifestation, stage, slot + 1]
	base["visual_tag"] = String(MANIFEST_THEMES.get(manifestation, {}).get("tag", manifestation))
	base["every"] = max(2, int(base.get("every", 4)) - int(slot == 4))
	base["radius"] = float(base.get("radius", 145.0)) + m * 6.0
	base["force"] = float(base.get("force", 82.0)) + m * 5.0
	base["range"] = float(base.get("range", 330.0)) + m * 12.0
	base["spread"] = float(base.get("spread", 0.18)) + float(slot) * 0.012
	return base


static func _short_description(display_name: String, theme: Dictionary, profile: Dictionary, stage: String) -> String:
	var label := "EV1" if stage == "ev1" else "EV2"
	return "%s — %s converte %s em %s, com leitura visual de %s." % [label, display_name.capitalize(), String(theme.get("essence", "ruptura")), String(profile.get("label", "efeito próprio")), String(theme.get("visual", "ruptura temporal"))]
