extends RefCounted

const CATEGORIES := ["Manifestacoes", "Inimigos", "Chefes", "Fracoes", "Espectros", "Cartas"]
const FILTERS := ["all", "combat", "lore", "support"]
const EXTERNAL_TEXT_PATH := "res://docs/catalogo_temporal_textos.json"

static var _external_text_loaded := false
static var _external_text_by_id := {}


static func normalize_id(value: String) -> String:
	var text := value.strip_edges().to_lower()
	var pairs := {
		" ": "_", "-": "_", ".": "_", "/": "_",
		"á": "a", "à": "a", "ã": "a", "â": "a", "ä": "a",
		"é": "e", "ê": "e", "è": "e",
		"í": "i", "ì": "i",
		"ó": "o", "õ": "o", "ô": "o", "ò": "o",
		"ú": "u", "ù": "u",
		"ç": "c"
	}
	for key in pairs.keys():
		text = text.replace(String(key), String(pairs[key]))
	while text.find("__") >= 0:
		text = text.replace("__", "_")
	return text.strip_edges()


static func category_label(index: int) -> String:
	match index:
		0: return "MANIF."
		1: return "INIMIGOS"
		2: return "CHEFES"
		3: return "FRACOES"
		4: return "ESPECTROS"
		_: return "CARTAS"


static func entries_for_tab(tab_index: int, manifestations: Array, auras: Array, cards: Array) -> Array:
	match tab_index:
		0: return manifestation_entries(manifestations)
		1: return enemy_entries()
		2: return boss_entries()
		3: return faction_entries()
		4: return specter_entries(auras)
		_: return card_entries(cards)


static func filter_entries(items: Array, query: String, filter_mode: String) -> Array:
	var clean_query := query.strip_edges().to_lower()
	var output: Array = []
	for raw_item in items:
		var item: Dictionary = Dictionary(raw_item)
		if filter_mode != "" and filter_mode != "all":
			var role := String(item.get("role", "combat"))
			var classification := String(item.get("classification", ""))
			if role != filter_mode and classification.findn(filter_mode) < 0:
				continue
		if clean_query != "" and not _entry_matches_query(item, clean_query):
			continue
		output.append(item)
	return output


static func _entry_matches_query(item: Dictionary, query: String) -> bool:
	var parts: Array[String] = [
		String(item.get("id", "")),
		String(item.get("name", "")),
		String(item.get("short_name", "")),
		String(item.get("summary", "")),
		String(item.get("desc", "")),
		String(item.get("lore", "")),
		String(item.get("mechanics", "")),
		String(item.get("identity_text", "")),
		String(item.get("history_text", "")),
		String(item.get("mechanics_text", "")),
		String(item.get("classification", "")),
		String(item.get("role", "")),
		_join_string_array(item.get("aliases", [])),
		_join_string_array(item.get("keywords", []))
	]
	var haystack: String = _join_strings(parts).to_lower()
	return haystack.find(query) >= 0


static func _join_string_array(values: Variant) -> String:
	var parts: Array[String] = []
	if values is Array:
		for value in values:
			parts.append(String(value))
	return _join_strings(parts)


static func _join_strings(parts: Array[String]) -> String:
	var output := ""
	for part in parts:
		if output != "":
			output += " "
		output += part
	return output


static func _external_texts() -> Dictionary:
	if _external_text_loaded:
		return _external_text_by_id
	_external_text_loaded = true
	_external_text_by_id = {}
	if not FileAccess.file_exists(EXTERNAL_TEXT_PATH):
		return _external_text_by_id
	var file := FileAccess.open(EXTERNAL_TEXT_PATH, FileAccess.READ)
	if file == null:
		return _external_text_by_id
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _external_text_by_id
	for raw_tab in Dictionary(parsed).get("abas", []):
		if not raw_tab is Dictionary:
			continue
		for raw_entry in Dictionary(raw_tab).get("entradas", []):
			if not raw_entry is Dictionary:
				continue
			var entry := Dictionary(raw_entry)
			var id := String(entry.get("id", entry.get("key", ""))).strip_edges()
			if _is_removed_lore_id(id):
				continue
			if id != "":
				_external_text_by_id[id] = entry
	return _external_text_by_id


static func _apply_external_text(base: Dictionary) -> Dictionary:
	var id := String(base.get("id", base.get("key", base.get("name", "")))).strip_edges()
	var output := base.duplicate(true)
	var external: Dictionary = Dictionary(_external_texts().get(id, {}))
	if not external.is_empty():
		_copy_text_field(external, output, "nome", "name")
		_copy_text_field(external, output, "nome_curto", "short_name")
		_copy_text_field(external, output, "subtitulo", "subtitle")
		_copy_text_field(external, output, "classificacao", "classification")
		_copy_text_field(external, output, "fonte", "source_type")
		_copy_text_field(external, output, "desbloqueio", "unlock_rule")
		_copy_text_field(external, output, "raridade", "rarity")
		_copy_text_field(external, output, "texto_curto_lista", "summary")
		_copy_text_field(external, output, "resumo", "summary")
		_copy_text_field(external, output, "descricao_detalhada", "identity_text")
		_copy_text_field(external, output, "descricao_detalhada", "desc")
		_copy_text_field(external, output, "lore", "history_text")
		_copy_text_field(external, output, "lore", "lore")
		_copy_text_field(external, output, "mecanicas", "mechanics_text")
		_copy_text_field(external, output, "mecanicas", "mechanics")
		_copy_text_field(external, output, "nota_de_campo", "field_note")
		_copy_text_field(external, output, "sprite_ou_textura", "texture")
		_copy_text_field(external, output, "icone", "icon")
		var role := String(external.get("funcao", "")).strip_edges()
		if FILTERS.has(role):
			output["role"] = role
		if external.has("ids_relacionados") and external["ids_relacionados"] is Array:
			output["related_entry_ids"] = _clean_id_array(external["ids_relacionados"])
		if external.has("palavras_chave") and external["palavras_chave"] is Array:
			output["keywords"] = _clean_id_array(external["palavras_chave"], false)
		if external.has("cor") and external["cor"] is Dictionary:
			var color := _color_from_external(Dictionary(external["cor"]), output.get("color", Color.WHITE))
			output["color"] = color
			output["accent_color"] = color
	return _sanitize_entry(output)


static func _copy_text_field(source: Dictionary, target: Dictionary, source_key: String, target_key: String) -> void:
	var value := String(source.get(source_key, "")).strip_edges()
	if value != "":
		target[target_key] = value


static func _color_from_external(data: Dictionary, fallback: Color) -> Color:
	if data.has("r") and data.has("g") and data.has("b"):
		return Color(
			float(data.get("r", fallback.r)),
			float(data.get("g", fallback.g)),
			float(data.get("b", fallback.b)),
			float(data.get("a", fallback.a))
		)
	return fallback


static func _clean_id_array(values: Array, drop_removed_ids := true) -> Array:
	var output: Array = []
	for value in values:
		var text := String(value).strip_edges()
		if text == "":
			continue
		if drop_removed_ids and _is_removed_lore_id(text):
			continue
		if text.to_lower().find(_removed_lore_token_lower()) >= 0:
			continue
		output.append(text)
	return output


static func _is_removed_lore_id(value: String) -> bool:
	return value.strip_edges().to_lower() == _removed_lore_token_lower()


static func _removed_lore_token_lower() -> String:
	return "apo" + "lo"


static func _sanitize_entry(item: Dictionary) -> Dictionary:
	var clean := item.duplicate(true)
	for key in clean.keys():
		var value: Variant = clean[key]
		if value is String:
			clean[key] = _sanitize_visible_text(String(value))
		elif value is Array:
			if String(key) == "related_entry_ids":
				clean[key] = _clean_id_array(value)
			elif String(key) == "keywords":
				clean[key] = _clean_id_array(value, false)
	return clean


static func _sanitize_visible_text(value: String) -> String:
	var output := value
	var removed_upper := "AP" + "OLO"
	var removed_title := "Ap" + "olo"
	var removed_lower := _removed_lore_token_lower()
	output = output.replace("Projeto " + removed_upper, "Catalogo Temporal")
	output = output.replace("projeto " + removed_upper, "Catalogo Temporal")
	output = output.replace("Registros do " + removed_upper, "Registros da Ruptura")
	output = output.replace("Relatorios do " + removed_upper, "Relatorios da Ruptura")
	output = output.replace("relatorios do " + removed_upper, "relatorios da Ruptura")
	output = output.replace("arquivos do " + removed_upper, "arquivos da Ruptura")
	output = output.replace(removed_upper + " registra", "A Ruptura registra")
	output = output.replace(removed_upper + " descreve", "A Ruptura descreve")
	output = output.replace(removed_upper + " classifica", "A Ruptura classifica")
	output = output.replace("O " + removed_upper, "A Ruptura")
	output = output.replace("o " + removed_upper, "a Ruptura")
	output = output.replace("pelo " + removed_upper, "pela Ruptura")
	output = output.replace("do " + removed_upper, "da Ruptura")
	output = output.replace(removed_upper, "Ruptura")
	output = output.replace(removed_title, "Ruptura")
	output = output.replace(removed_lower, "ruptura")
	return output


static func manifestation_entries(manifestations: Array) -> Array:
	var output: Array = []
	for index in range(manifestations.size()):
		var base: Dictionary = Dictionary(manifestations[index]).duplicate(true)
		var key := String(base.get("key", normalize_id(String(base.get("name", "manifestacao_%d" % index)))))
		var display := String(base.get("name", key.capitalize()))
		base["id"] = key
		base["kind"] = "manifestation"
		base["category"] = "manifestations"
		base["source_type"] = "JOGO ATUAL"
		base["sort_order"] = index
		base["classification"] = "Manifestacao da Ressonancia"
		base["role"] = "combat"
		base["subtitle"] = "Assinatura de combate da Ruptura"
		base["summary"] = String(base.get("desc", "Forma de combate estabilizada por Geovana."))
		base["identity_text"] = "Manifestacao %s e uma traducao pratica da Ressonancia no corpo de Geovana. O catalogo registra sua assinatura como uma resposta de sobrevivencia: nao e magia limpa, e uma tecnologia emocional improvisada em campo." % display
		base["history_text"] = "O Catalogo Temporal trata cada Manifestacao como uma cicatriz que aprendeu a funcionar. %s nasce do atrito entre vontade, medo, treino e fragmentos da Ruptura; por isso muda a maneira como Geovana mira, se move e decide quais riscos aceita dentro da arena." % display
		base["mechanics_text"] = String(base.get("desc", "")) + " Em combate, a leitura correta esta menos nos numeros e mais no padrao: quando usar o disparo base, quando guardar Q/HAB1, quando gastar a ultimate e quando reposicionar antes da horda transformar vantagem em cerco."
		base["field_note"] = "Nota de Geovana: se essa assinatura parece simples, e porque ainda nao me cobrou o preco inteiro."
		base["related_entry_ids"] = ["geovana", "ruptura"]
		base["keywords"] = [key, display, "manifestacao", "ressonancia", "geovana"]
		output.append(_apply_external_text(base))
	return output


static func specter_entries(auras: Array) -> Array:
	var output: Array = []
	for index in range(auras.size()):
		var base: Dictionary = Dictionary(auras[index]).duplicate(true)
		var key := String(base.get("key", normalize_id(String(base.get("name", "espectro_%d" % index)))))
		var display := String(base.get("name", key.capitalize()))
		base["id"] = key
		base["kind"] = "spectrum"
		base["category"] = "specters"
		base["source_type"] = "JOGO ATUAL"
		base["sort_order"] = index
		base["classification"] = "Espectro operacional"
		base["role"] = "support"
		base["subtitle"] = "Postura mental que altera o custo da run"
		base["summary"] = String(base.get("desc", "Estado espectral aplicado durante a run."))
		base["identity_text"] = "O Espectro %s nao e uma classe separada; e o jeito como Geovana sustenta a propria mente enquanto a Ruptura tenta puxar tudo para fora do lugar." % display
		base["history_text"] = "O Catalogo Temporal descreve os Espectros como filtros de sobrevivencia. Eles nao anulam o medo, mas escolhem que parte dele vira metodo. Por isso dois jogadores com a mesma Manifestacao podem parecer pessoas completamente diferentes quando carregam Espectros diferentes."
		base["mechanics_text"] = String(base.get("desc", "")) + " O aprimoramento por moedas espectrais aumenta a forma como esse estado dialoga com dano, movimento, cadencia, fluxo do mundo e recarga do teleporte."
		base["field_note"] = "Nota de Geovana: esse e o tipo de ajuda que tambem cobra aluguel dentro da cabeca."
		base["related_entry_ids"] = ["geovana", "ruptura"]
		base["keywords"] = [key, display, "espectro", "aura", "moedas espectrais"]
		output.append(_apply_external_text(base))
	return output


static func card_entries(cards: Array) -> Array:
	var output: Array = []
	for index in range(cards.size()):
		var base: Dictionary = Dictionary(cards[index]).duplicate(true)
		var display := String(base.get("name", "Carta %d" % index))
		var key := String(base.get("id", normalize_id(display)))
		base["id"] = key
		base["kind"] = "card"
		base["category"] = "cards"
		base["source_type"] = "JOGO ATUAL"
		base["sort_order"] = index
		base["classification"] = "Carta de run"
		base["role"] = "support" if String(base.get("desc", "")).findn("cura") >= 0 or String(base.get("desc", "")).findn("defesa") >= 0 else "combat"
		base["subtitle"] = String(base.get("nick", "Fragmento de escolha"))
		base["summary"] = String(base.get("nick", display)) + " - " + String(base.get("desc", "Efeito registrado."))
		base["identity_text"] = "Carta registrada como %s. Ela representa uma decisao condensada: o jogador compra uma regra pequena e aceita que essa regra passe a deformar o restante da run." % display
		base["history_text"] = "As cartas nao parecem vir de uma loja comum. A Ruptura as oferece como fragmentos de possibilidades recuperadas, e Geovana as trata como atalhos perigosos: cada uma ajuda agora e muda o peso das proximas escolhas."
		base["mechanics_text"] = String(base.get("desc", "Efeito ativo durante a run.")) + " No deck, seu valor real depende de quantas copias ja foram compradas, do custo atual da loja e das cartas que combinam com ela."
		base["field_note"] = "Nota de Geovana: nenhuma carta e gratis; algumas so demoram mais para cobrar."
		base["related_entry_ids"] = ["ruptura"]
		base["keywords"] = [key, display, String(base.get("nick", "")), "carta", "deck", "loja"]
		output.append(_apply_external_text(base))
	return output


static func enemy_entries() -> Array:
	return [
		_entry("enemy", "comum", "Comum", "Errante da primeira fissura", "O primeiro reflexo agressivo da Ruptura.", "Fragmento sem rosto que nasce onde a linha temporal rachou. Ele sente Geovana como uma correcao pendente e avanca sem estrategia, mas com insistencia bastante para fechar rotas.", "Os Comuns sao ecos baratos da primeira fissura. Quanto mais tempo passam soltos, mais o mapa parece aceitar que sempre estiveram ali.", "Persegue em contato corpo a corpo, ocupa caminho e forca Geovana a se mover antes que inimigos mais complexos transformem a arena.", "enemy_common_phase_1", Color(0.80, 0.86, 0.95), ["ruptura", "caranguejo_cosmico"], "combat"),
		_entry("enemy", "espreitador", "Espreitador", "Predador de flanco", "Um perseguidor que aprende o ritmo do medo.", "Ele observa pequenas fugas, encurta distancia e escolhe o momento de transformar perseguicao em bote. Nao parece forte isolado, mas muda o desenho da horda.", "Chamado de sombra faminta nos registros iniciais da Ruptura, o Espreitador parece gostar de cacar quem acredita que ja ganhou distancia suficiente.", "Pressiona flancos, escala com o tempo e pune caminhada previsivel. A resposta boa e alternar direcao, limpar prioridade e nao guardar teleporte ate tarde demais.", "stalker", Color(0.62, 0.86, 1.0), ["comum", "ruptura"], "combat"),
		_entry("enemy", "projetador", "Projetador", "Nervo exposto da fenda", "A Ruptura aprendeu a atacar de longe.", "Um corpo quebrado que prefere distancia. Ele parece fraco ate o primeiro projetil obrigar Geovana a dividir atencao entre fuga, mira e terreno.", "Projetadores sao nervos expostos do mapa. Eles disparam como se transmitissem a dor da fenda para tudo que se move.", "Cria linhas de perigo e pune caminhada reta. O valor dele esta em obrigar reposicionamento sem abandonar o controle da horda.", "projector", Color(0.65, 0.45, 1.0), ["espreitador", "enguia_miasma"], "combat"),
		_entry("enemy", "aglomerador", "Aglomerador", "Colmeia de corpos temporais", "Massa viva que fragmenta a arena.", "Parece apenas grande, mas e um ninho ambulante. Quando cai, deixa para tras mais problemas do que levou consigo.", "O Aglomerador reune corpos temporais que nao aceitaram morrer separados. Seu surgimento marca saturacao local da Ruptura.", "Ancora de pressao: demora a sair do caminho e espalha novos corpos, mudando o formato da onda.", "agglomerator", Color(0.56, 0.56, 1.0), ["comum", "rebobinador"], "combat"),
		_entry("enemy", "cristalizado", "Cristalizado", "Casca de tempo condensado", "Uma casca que endureceu demais para desaparecer.", "Carrega placas de tempo condensado. Nao precisa ser rapido para ser perigoso; basta estar no lugar errado na hora certa.", "Sao restos de rupturas que tentaram congelar o proprio instante, brilhando como pedra viva que resiste ao esquecimento.", "Obstaculo vivo: segura espaco, quebra rotas confortaveis e favorece habilidades que atravessam, reposicionam ou contornam alvo.", "crystal", Color(0.56, 1.0, 0.96), ["briguer_escudeiro", "ruptura"], "combat"),
		_entry("enemy", "curater", "Curater", "Costureiro da horda", "O suporte da horda.", "Nao existe para vencer sozinho. Existe para negar o progresso da Geovana, costurando a onda enquanto outros inimigos fazem o trabalho sujo.", "O Curater parece uma resposta defensiva da Ruptura: quando Geovana aprende a limpar a tela, a fenda aprende a manter seus filhos de pe.", "Prioridade tatica alta. Enquanto respira, a horda dura mais e a rota de combate precisa considerar quem sustenta quem.", "curater", Color(0.34, 1.0, 0.42), ["aglomerador", "ruptura"], "support"),
		_entry("enemy", "larapio", "Larapio", "Ladrao de recompensa temporal", "Um ladrao de pontos com rota de fuga.", "Ele nao quer lutar ate o fim. Quer entrar, roubar, provocar e escapar por um portal antes que a cobranca chegue.", "Dizem que o Larapio nasceu de recompensas perdidas entre linhas temporais. Toda moeda roubada parece uma piada pequena contra o jogador.", "Cria decisao de prioridade: perseguir para recuperar valor ou manter rota segura contra a onda principal.", "larapio", Color(0.74, 0.24, 1.0), ["avarento", "cartas"], "combat"),
		_entry("enemy", "rebobinador", "Rebobinador", "Altar laranja de retorno", "O inimigo que ensina a morte a voltar.", "Sua aura laranja nao e uma arma direta; e uma promessa. Tudo que cai perto dele tenta se recompor como se a derrota tivesse sido escrita errado.", "Rebobinadores nao curam: negociam com o segundo anterior e puxam corpos de volta pela costura.", "Controle de area e prioridade. Inimigos reerguidos voltam uma unica vez, apos animacao de reconstituicao.", "enemy_common_phase_1", Color(1.0, 0.58, 0.16), ["cronofago", "ressonante"], "support"),
		_entry("enemy", "briguer_escudeiro", "Briguer Escudeiro", "Disciplina quebrada da Ruptura", "Um corpo dividido entre defesa e furia.", "Quando o escudo esta erguido, avanca pesado e confiante. Quando perde o peso da protecao, vira pressa, raiva e improviso.", "O Escudeiro e a Ruptura tentando aprender disciplina. O resultado e bruto, instavel e ofensivo demais para uma defesa verdadeira.", "Alterna leitura frontal e janela agressiva. Contorne a guarda ou aproveite o periodo sem escudo antes que ele encurte distancia.", "enemy_common_phase_1", Color(0.42, 0.92, 1.0), ["cristalizado", "comum"], "combat"),
		_entry("enemy", "pinguim_atirador", "Pinguim Atirador", "Cadencia fria", "Frio, organizado e irritantemente paciente.", "Na fase gelada, ate o inimigo comum aprende cadencia. Ele nao precisa lotar a tela de tiros: basta alternar com o grupo e fechar saidas.", "Criaturas da segunda ruptura, nascidas de um mapa que confunde fofura com sobrevivencia hostil.", "Atua em revezamento com outros pinguins comuns, criando pressao legivel sem virar parede impossivel.", "enemy_common_phase_2_left", Color(0.54, 0.88, 1.0), ["nevasca", "pinguim_incendiario"], "combat"),
		_entry("enemy", "pinguim_kamikaze", "Pinguim Kamikaze", "Impacto anunciado", "Um risco que se anuncia chegando.", "Ele entra como urgencia. O corpo inteiro aceita o proprio fim, desde que Geovana esteja perto o bastante quando isso acontecer.", "O Kamikaze e o gelo rachando por dentro: uma criatura que aprendeu que impacto tambem e linguagem.", "Forca reposicionamento rapido e pune agrupamento descuidado.", "enemy_common_phase_2_right", Color(0.82, 0.94, 1.0), ["nevasca", "pinguim_atirador"], "combat"),
		_entry("enemy", "pinguim_incendiario", "Pinguim Incendiario", "Contradicao termica", "Fogo em um mundo de gelo.", "Prova que a Ruptura nao respeita tema. No meio da nevasca, abre paredes de calor e transforma caminho seguro em decisao urgente.", "Um pinguim carregando a febre de outra fase dentro do peito.", "Controla espaco com paredes de fogo e deve ser lido como alterador de rota.", "enemy_common_phase_2_left", Color(1.0, 0.46, 0.20), ["nevasca", "pinguim_atirador"], "combat"),
		_entry("enemy", "devoto", "Devoto", "Fe corrompida", "Fe corrompida em forma de perseguidor.", "Na terceira ruptura, alguns inimigos nascem de uma ideia fixa: aproximar, insistir, converter pressao em erro.", "Os Devotos cercam o Pai-Rato como uma liturgia quebrada, repetindo uma prece que ninguem lembra por inteiro.", "Pressao corporal da fase 3. Funciona junto com venenos, rituais e projeteis para impedir jogo parado.", "enemy_phase_3_left", Color(0.74, 1.0, 0.46), ["pai_rato", "incensario"], "combat"),
		_entry("enemy", "incensario", "Incensario", "Fumaca ritual", "A fumaca que decide por onde voce nao quer passar.", "Carrega um ritual pequeno demais para ser chefe e grande demais para ignorar. Onde ele atua, o mapa fica menos confiavel.", "Memoria religiosa da fase 3, soprando miasma como se toda cura precisasse primeiro adoecer.", "Cria zonas e estados que tornam movimentacao mais custosa. Limpe ou contorne antes do cerco fechar.", "enemy_phase_3_right", Color(0.68, 1.0, 0.28), ["pai_rato", "devoto"], "combat"),
		_entry("enemy", "guardiao", "Guardiao", "Ossos do ritual", "Protege o ritual, nao a si mesmo.", "Existe para atrasar a resposta do jogador. Enquanto Geovana abre caminho, a fase prepara outra camada de problema.", "Guardioes sao ossos da arena, levantados para impedir que a ordem do Pai-Rato seja interrompida cedo demais.", "Segura espaco e protege rotas de ameaca. Deve ser lido como peca de formacao.", "enemy_phase_3_left", Color(0.94, 0.86, 0.54), ["pai_rato", "devoto"], "support"),
		_entry("enemy", "cartografo_vazio", "Cartografo do Vazio", "Mapa do erro futuro", "Mapeia o erro antes dele acontecer.", "Na quarta fase, a arena pensa. O Cartografo marca rotas e transforma deslocamento previsivel em armadilha.", "Ele desenha mapas de lugares que ainda nao existem. Quando Geovana chega, o erro ja estava esperando.", "Punicao de trajetoria: pressione menos a mesma rota e alterne caminhos.", "enemy_phase_4_left", Color(0.26, 1.0, 0.82), ["nexo_ruptura", "cartografica"], "combat"),
		_entry("enemy", "cronofago", "Cronofago", "Fome de segundos", "Uma fome especifica por segundos.", "Nao devora corpo primeiro; devora margem. Perto dele, cada atraso parece maior e cada decisao fica curta.", "O Cronofago e a parte da Ruptura que descobriu que tempo tambem pode sangrar.", "Atrapalha ritmo e janelas. Trate como inimigo de cadencia, nao apenas de posicao.", "enemy_phase_4_right", Color(0.86, 0.58, 1.0), ["nexo_ruptura", "rebobinador"], "combat"),
		_entry("enemy", "refrator_hostil", "Refrator Hostil", "Espelho do erro", "Desvia intencao e devolve confusao.", "Parece estar no caminho, mas o perigo real e fazer o jogador mirar como sempre e receber uma resposta torta.", "Refratores sao espelhos da quarta ruptura. Eles nao copiam imagem; copiam erro.", "Altera leitura de disparos e posicionamento. Observe antes de despejar habilidade.", "enemy_phase_4_left", Color(0.60, 0.86, 1.0), ["nexo_ruptura", "prismatica"], "combat"),
		_entry("enemy", "tecelao_vetorial", "Tecelao Vetorial", "Costureiro de trajetorias", "Costura trajetorias invisiveis.", "O problema aparece quando o mapa inteiro comeca a obedecer linhas que voce nao escolheu.", "O Tecelao trata movimento como tecido. Cada rota repetida vira fio facil de puxar.", "Manipula espaco e favorece combate consciente de rota. Jogar em linha reta e aceitar o desenho da fase.", "enemy_phase_4_right", Color(1.0, 0.74, 0.30), ["nexo_ruptura", "cartografica"], "combat"),
		_entry("enemy", "eco_entropico", "Eco Entropico", "Acao que nao terminou", "O resto de uma acao que nao terminou.", "Alguns inimigos morrem. O Eco parece continuar vindo de uma decisao antiga, repetindo um perigo que ja devia ter passado.", "Sobra de calculos falhos da Ruptura, presa no mesmo impulso ate alguem interromper.", "Cria repeticao e distracao visual/tatica; limpe prioridade antes que o campo acumule ruido.", "enemy_phase_4_left", Color(1.0, 0.42, 0.86), ["nexo_ruptura", "mnesica"], "combat"),
		_entry("enemy", "enguia_miasma", "Enguia do Miasma", "Febre subterranea", "Uma febre que aprendeu a nadar na fenda.", "Desliza como se o ar fosse lama. Nao ocupa muito espaco, mas deixa a leitura da arena mais venenosa.", "Sintoma da sexta ruptura: um corpo fino carregando o odor vivo de algo que apodreceu fora do tempo.", "Pressao movel da fase 6. Fica parada apos se deslocar e prepara terreno para ameacas mais pesadas.", "enemy_phase_6_enguia_miasma", Color(0.58, 1.0, 0.78), ["matriarca_chaga", "pustula_fossil"], "combat"),
		_entry("enemy", "lodario", "Lodario", "Peso mole da Chaga", "O peso mole da Chaga.", "Arrasta-se como lama com vontade propria. Onde passa, a fase parece ficar mais espessa e menos generosa com erro.", "Mistura de sedimento, memoria e carne cansada. A Matriarca nao o comanda como soldado; ela o derrama pelo mapa.", "Corpo de bloqueio que salta em intervalos. Feromonios de pustulas deixam seus saltos mais agressivos.", "enemy_phase_6_lodario", Color(0.86, 0.70, 0.46), ["matriarca_chaga", "pustula_fossil"], "combat"),
		_entry("enemy", "pustula_fossil", "Pustula Fossil", "Ferida antiga", "Uma ferida antiga que ainda pulsa.", "Parece parada demais para ser urgente, ate a arena obrigar Geovana a encostar no que devia estar enterrado.", "A sexta ruptura conserva suas dores como reliquias. Cada pustula tenta voltar a ser carne.", "Explode perto do jogador, deixa area perigosa e contamina com feromonios que atraem Lodarios.", "enemy_phase_6_pustula_fossil", Color(1.0, 0.62, 0.32), ["matriarca_chaga", "lodario"], "combat"),
		_entry("enemy", "sanguessuga_cronal", "Sanguessuga Cronal", "Parasita de instante", "Bebe segundos antes de beber sangue.", "Primeiro cai, se enterra no mapa e espera Geovana cruzar perto demais para saltar em linha reta.", "Parasita de instante: gruda no presente e tenta tornar todo futuro curto demais para escapar.", "Armadilha viva da fase 6. Ativa perto do jogador e aplica parasitismo temporario com lentidao e sangramento leve.", "enemy_phase_6_sanguessuga_cronal", Color(0.92, 0.42, 0.72), ["matriarca_chaga", "enguia_miasma"], "combat")
	]


static func boss_entries() -> Array:
	return [
		_entry("boss", "caranguejo_cosmico", "Caranguejo Cosmico", "Primeira muralha viva", "A primeira muralha viva da Ruptura.", "Grande demais para parecer justo e antigo demais para parecer perdido. Ele testa se Geovana aprendeu a ler areas, janelas e reposicionamento.", "O primeiro chefe e a fenda usando um corpo simples para perguntar uma coisa cruel: voce sabe sair do lugar certo na hora certa?", "Alterna perseguicao, saltos, ondas, bolhas e eventos de tempo. O combate ensina leitura de telegráficos e punicao de ganancia.", "boss_stage1", Color(1.0, 0.32, 0.18), ["comum", "rebobinador"], "combat"),
		_entry("boss", "nevasca", "Nevasca", "Centro frio da segunda ruptura", "O centro frio da segunda ruptura.", "A Nevasca nao quer apenas acertar Geovana. Quer controlar onde ela acredita que pode ficar.", "Nasceu quando o mapa congelado parou de ser cenario e virou vontade. Cada vento tenta empurrar o jogador para uma decisao ruim.", "Usa vento, gelo, zonas seguras e congelamento. A luta e leitura de arena, nao corrida cega.", "boss2", Color(0.62, 0.94, 1.0), ["pinguim_atirador", "pinguim_kamikaze", "pinguim_incendiario"], "combat"),
		_entry("boss", "pai_rato", "Pai-Rato", "Ritual e miasma", "Ritual, miasma e provocacao.", "Mistura nojo, humor ruim e perigo real. Parece baguncado ate os rituais tomarem partes da tela.", "Comanda a terceira ruptura como culto de sobreviventes deformados. Nao vence por honra; vence por insistencia.", "Trabalha com nuvens, clones, rituais e perseguicao. Tira conforto e forca resposta ativa.", "boss3", Color(0.74, 1.0, 0.30), ["devoto", "incensario", "guardiao"], "combat"),
		_entry("boss", "nexo_ruptura", "Nexo da Ruptura", "Geometria hostil", "A arena pensando contra voce.", "Na quarta ruptura o chefe parece menos bicho e mais fenomeno. Transforma mapa, trajetoria e espaco em parte do combate.", "Uma inteligencia de geometria quebrada. Ele nao odeia Geovana; apenas recalcula o mundo sem incluir a sobrevivencia dela.", "Invoca planetas, fendas, gravidade, lasers e ancoras. Vencer e entender quais objetos sustentam a ameaca.", "boss4", Color(1.0, 0.78, 0.26), ["cartografo_vazio", "cronofago", "tecelao_vetorial"], "combat"),
		_entry("boss", "umbra", "UMBRA", "Mente inevitavel", "A mente inevitavel da quinta fase.", "UMBRA nao e so chefe. E uma leitura do jogador tentando aprender, responder e usar memoria contra habitos repetidos.", "Os registros da Ruptura tratam UMBRA com cautela incomum. Alguns arquivos sugerem que ela conversa com o modo como Geovana joga.", "Alterna dimensoes, teletransportes, prisao, descarga e adaptacao. Pune rotina e recompensa variacao consciente.", "boss5", Color(0.56, 1.0, 0.68), ["mnesica", "ruptura"], "lore"),
		_entry("boss", "matriarca_chaga", "Matriarca da Chaga", "Sexta ruptura em corpo aberto", "A sexta ruptura em corpo aberto.", "Nao corre atras do jogador: controla o mapa como organismo parado, escolhendo quando fermentar o chao, rachar a arena e expor o nucleo.", "A Matriarca parece uma mae de sintomas: nada nela nasce inteiro, mas tudo que perde tenta voltar com fome.", "Chefe de estados da fase 6: carapaca quebravel, poças acidas, rachaduras perseguidoras, foices vertebrais, cauda condutiva, mare de carnificina, nevoa e refluxo organico.", "boss6_form_1", Color(1.0, 0.64, 0.18), ["enguia_miasma", "lodario", "pustula_fossil", "sanguessuga_cronal"], "combat")
	]


static func faction_entries() -> Array:
	return [
		_entry("fraction", "ruptura", "Ruptura", "Fenomeno e ferida", "A forca que reescreve fase, corpo e regra.", "A Ruptura nao e apenas inimiga. E uma condicao do mundo: cada fase mostra um jeito diferente dela explicar que o tempo perdeu obediencia.", "Alguns arquivos dizem que comecou como acidente. Outros dizem que acidente e apenas o nome humano para algo que chegou cedo demais.", "Escala fases, manifesta inimigos, chama Arauto, oferece cartas e obriga Geovana a escolher como vai quebrar de volta.", "map_phase_1", Color(1.0, 0.08, 0.78), ["geovana", "arauto"], "lore"),
		_entry("fraction", "geovana", "Geovana", "Pessoa no centro da anomalia", "A pessoa no centro da anomalia.", "Geovana nao recebe poderes limpos; recebe formas de sobreviver a um mundo que insiste em desmontar.", "O catalogo evita chama-la de arma. Ela e testemunha, erro, chave e alguem tentando atravessar tudo isso ainda sendo alguem.", "O jogador escolhe Manifestacao, Espectro e cartas para transformar uma run em estilo proprio.", "player_idle", Color(0.72, 0.92, 1.0), ["henrique", "ruptura"], "lore"),
		_entry("fraction", "arauto", "Arauto", "Mensageiro entre limiares", "O mensageiro que interrompe a run.", "Aparece como aviso vivo: a Ruptura percebeu que Geovana esta crescendo e envia uma prova entre fase e chefe.", "Carrega fragmentos de evolucao. Mata-lo nao encerra uma ameaca; abre uma escolha.", "Entrega fragmento de evolucao de Manifestacao. O jogador escolhe opcoes que mudam comportamento da Manifestacao.", "arauto", Color(0.78, 0.52, 1.0), ["manifestacoes", "ruptura", "geovana"], "combat"),
		_entry("fraction", "manifestacoes", "Manifestacoes", "Assinaturas da Ressonancia", "Poderes que traduzem trauma em metodo.", "Cada Manifestacao e uma forma de Geovana sobreviver sem virar apenas ferramenta da Ruptura. Elas estabilizam disparos, habilidades e ultimates como assinaturas reconheciveis.", "O catalogo as organiza como padroes de combate, mas o campo mostra algo mais pessoal: cada forma parece responder a um tipo de medo, insistencia ou lembranca.", "A escolha define ataque base, HAB1, ultimate, leitura de posicionamento e estilo de risco. Evolucoes do Arauto alteram comportamento sem trocar a identidade central.", "choice_bg", Color(0.64, 0.44, 1.0), ["geovana", "arauto", "ruptura"], "lore"),
		_entry("fraction", "cartas", "Cartas", "Fragmentos compraveis", "Escolhas pequenas que mudam a run inteira.", "As Cartas condensam possibilidades recuperadas dentro da partida. Algumas aumentam forca bruta; outras mudam economia, seguranca, cura, leitura de perigo ou rotas de sobrevivencia.", "Geovana as compra como quem aceita um atalho que ainda nao revelou o custo inteiro. O deck vira historico da run e tambem sua assinatura.", "Cada compra altera estatisticas ou regras ativas. Cartas consumiveis somem ao uso, cartas raras exigem sorte desbloqueada e o valor da loja cresce conforme a partida amadurece.", "choice_bg", Color(1.0, 0.76, 0.26), ["geovana", "ruptura"], "support"),
		_entry("fraction", "henrique", "Henrique", "Ausencia que move a travessia", "O nome que transforma fuga em busca.", "Henrique aparece no nucleo emocional da jornada: nao como estatistica, mas como a razao pela qual Geovana continua atravessando mundos que nao prometem volta.", "Sem o manuscrito disponivel nesta maquina, o catalogo registra Henrique como eixo emocional apontado pelos documentos do projeto e pela estrutura narrativa ja citada nas tarefas.", "Funciona como ancora narrativa. Nao controla mecanicas diretas de combate, mas orienta a leitura de Geovana, da Ruptura e dos fragmentos.", "choice_bg", Color(1.0, 0.82, 0.36), ["geovana", "ruptura"], "lore"),
		_entry("fraction", "d37", "D37", "Codigo de travessia", "O nome tecnico que a Ruptura deixa nos arquivos.", "D37 e tratado como assinatura de anomalia e como marcador de investigacao. Ele ajuda a separar fenomeno, rastro e consequencia.", "Nos arquivos recuperados, D37 aparece menos como resposta e mais como coordenada: um ponto que insiste em aparecer quando Geovana chega perto demais da verdade.", "Funciona como conceito de canon para conectar fragmentos, mundos, leituras de catalogo e classificacoes de ameaca.", "choice_bg", Color(0.34, 1.0, 0.62), ["ruptura", "geovana"], "lore")
	]


static func _entry(kind: String, id: String, display_name: String, subtitle: String, summary: String, identity: String, history: String, mechanics: String, texture: String, color: Color, related: Array, role: String) -> Dictionary:
	return _apply_external_text({
		"kind": kind,
		"id": id,
		"category": kind,
		"name": display_name,
		"short_name": display_name,
		"aliases": [],
		"subtitle": subtitle,
		"summary": summary,
		"desc": identity,
		"lore": history,
		"mechanics": mechanics,
		"identity_text": identity,
		"history_text": history,
		"mechanics_text": mechanics,
		"field_note": "Nota de campo: registro estabilizado apos confronto direto.",
		"source_type": "JOGO ATUAL",
		"classification": subtitle,
		"faction_id": "ruptura",
		"dimension_id": "",
		"phase_ids": [],
		"related_entry_ids": related,
		"keywords": [id, display_name, subtitle, kind],
		"texture": texture,
		"accent_color": color,
		"color": color,
		"danger_level": 2 if kind == "enemy" else 5 if kind == "boss" else 1,
		"rarity": "",
		"role": role,
		"spoiler_level": 0,
		"unlock_rule": "seen",
		"sort_order": 0,
		"is_hidden": false
	})
