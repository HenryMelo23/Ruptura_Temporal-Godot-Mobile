extends RefCounted

const CATEGORIES: = ["Manifestacoes", "Inimigos", "Chefes", "Fracoes", "Espectros", "Cartas"]
const FILTERS: = ["all", "combat", "lore", "support"]
const EXTERNAL_TEXT_PATH: = "res://docs/catalogo_temporal_textos.json"

static var _external_text_loaded: = false
static var _external_text_by_id: = {}


static func normalize_id(value: String) -> String:
	var text: = value.strip_edges().to_lower()
	var pairs: = {
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
	var clean_query: = query.strip_edges().to_lower()
	var output: Array = []
	for raw_item in items:
		var item: Dictionary = Dictionary(raw_item)
		if filter_mode != "" and filter_mode != "all":
			var role: = String(item.get("role", "combat"))
			var classification: = String(item.get("classification", ""))
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
	var output: = ""
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
	var file: = FileAccess.open(EXTERNAL_TEXT_PATH, FileAccess.READ)
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
			var entry: = Dictionary(raw_entry)
			var id: = String(entry.get("id", entry.get("key", ""))).strip_edges()
			if _is_removed_lore_id(id):
				continue
			if id != "":
				_external_text_by_id[id] = entry
	return _external_text_by_id


static func _apply_external_text(base: Dictionary) -> Dictionary:
	var id: = String(base.get("id", base.get("key", base.get("name", "")))).strip_edges()
	var output: = base.duplicate(true)
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
		var role: = String(external.get("funcao", "")).strip_edges()
		if FILTERS.has(role):
			output["role"] = role
		if external.has("ids_relacionados") and external["ids_relacionados"] is Array:
			output["related_entry_ids"] = _clean_id_array(external["ids_relacionados"])
		if external.has("palavras_chave") and external["palavras_chave"] is Array:
			output["keywords"] = _clean_id_array(external["palavras_chave"], false)
		if external.has("cor") and external["cor"] is Dictionary:
			var color: = _color_from_external(Dictionary(external["cor"]), output.get("color", Color.WHITE))
			output["color"] = color
			output["accent_color"] = color
	return _sanitize_entry(output)


static func _copy_text_field(source: Dictionary, target: Dictionary, source_key: String, target_key: String) -> void :
	var value: = String(source.get(source_key, "")).strip_edges()
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


static func _clean_id_array(values: Array, drop_removed_ids: = true) -> Array:
	var output: Array = []
	for value in values:
		var text: = String(value).strip_edges()
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
	var clean: = item.duplicate(true)
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
	var output: = value
	var removed_upper: = "AP" + "OLO"
	var removed_title: = "Ap" + "olo"
	var removed_lower: = _removed_lore_token_lower()
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
		var key: = String(base.get("key", normalize_id(String(base.get("name", "manifestacao_%d" % index)))))
		var display: = String(base.get("name", key.capitalize()))
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
		var key: = String(base.get("key", normalize_id(String(base.get("name", "espectro_%d" % index)))))
		var display: = String(base.get("name", key.capitalize()))
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
		var display: = String(base.get("name", "Carta %d" % index))
		var key: = String(base.get("id", normalize_id(display)))
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
		_entry("enemy", "comum", "Errante", "Habitante telúrico das Ruínas Cósmicas", "Organismo base das Ruínas Cósmicas formado por matéria orgânica, terra e energia cósmica.", "Organismo telúrico nativo das Ruínas Cósmicas, formado pela agregação de matéria orgânica vegetal, sedimentos minerais e traços de energia cósmica ambiental. É a fauna mais abundante e a base alimentar daquele ecossistema.", "Muito antes da chegada do rastro do dispositivo temporal, os Errantes vagavam pelos leitos minerais das Ruínas Cósmicas em ciclos lentos de nutrição, absorvendo radiação cósmica passiva do solo. São criaturas territoriais simples que respondem a vibrações no chão.", "Avança em contato corpo a corpo, ocupando espaço e pressionando o posicionamento na arena. Atua em grupo para fechar rotas de fuga do jogador.", "enemy_common_phase_1", Color(0.8, 0.86, 0.95), ["ruptura", "caranguejo_cosmico"], "combat"), 
		_entry("enemy", "espreitador", "Espreitador", "Predador subterrâneo de emboscada", "Ramificação evolutiva da linhagem dos Errantes adaptada para caça subterrânea.", "Predador subterrâneo da mesma linhagem biológica dos Errantes. Sua anatomia evoluiu ao longo de eras para abandonar as pernas vestigiais em favor de dois braços musculosos e placas minerais de camuflagem.", "Ao longo de gerações nas Ruínas Cósmicas, uma ramificação da linhagem dos Errantes especializou-se na caça de emboscada. Rasteja silenciosamente e dispara em botes letais.", "Persegue a presa rastejando e se camuflando no solo. Aproxima-se lentamente até encurtar a distância e desferir um bote rápido, pressionando os flancos da arena.", "stalker", Color(0.62, 0.86, 1.0), ["comum", "ruptura"], "combat"), 
		_entry("enemy", "projetador", "Projetador", "Atirador estático de longo alcance", "Espécie adaptada para ataques à distância com projéteis minerais.", "Organismo estático das Ruínas Cósmicas adaptado para ataque à distância através do disparo de nódulos minerais expelidos por compressão orgânica.", "Desenvolveu glândulas internas de alta pressão que cristalizam sedimentos de sílica e minerais cósmicos em seus pulmões secundários.", "Mantém distância da presa e dispara projéteis calcificados de longo alcance com grande precisão.", "projector", Color(0.65, 0.45, 1.0), ["espreitador", "enguia_miasma"], "combat"), 
		_entry("enemy", "aglomerador", "Aglomerador", "Organismo coletivo fundido", "Surge quando múltiplos Errantes são comprimidos juntos por tempo suficiente.", "Organismo coletivo maciço formado pela fusão biológica de múltiplos Errantes compactados por pressão mecânica ambiental.", "Nas Ruínas Cósmicas, a fusão de Errantes é um mecanismo biológico natural de preservação contra grandes predadores e tempestades de poeira cósmica.", "Funciona como ancoragem pesada na arena, possuindo alta resistência a impactos. Ao cair em combate, sua estrutura se desfaz, liberando os organismos individuais que o compunham.", "agglomerator", Color(0.56, 0.56, 1.0), ["comum", "rebobinador"], "combat"), 
		_entry("enemy", "cristalizado", "Cristalizador", "Organismo de couraça mineralizada", "Variante cuja derme incorporou alta concentração de minerais.", "Variante mineralizada dos organismos das Ruínas Cósmicas, cuja derme absorveu altas concentrações de geodos de quartzo e ferro mineral.", "Metaboliza a sílica do solo ao longo de sua vida, expelindo-a para a epiderme até formar uma armadura rígida de cristais facetados.", "Atua como barreira pesada de alta resistência mecânica, absorvendo impactos e bloqueando rotas de movimentação do jogador.", "crystal", Color(0.56, 1.0, 0.96), ["briguer_escudeiro", "ruptura"], "combat"), 
		_entry("enemy", "curater", "Curater", "Hospedeiro simbiótico de esporos curativos", "Organismo em simbiose com fungos regenerativos que cura aliados.", "Organismo simbiótico que carrega colônias de fungos bioluminosos com alta capacidade de regeneração tecidual, atuando como restaurador da fauna local.", "Evoluiu em simbiose com os esporos curativos dos fungos das cavernas profundas das Ruínas Cósmicas. O metabólito requer um hospedeiro receptor compatível, sendo incapaz de curar a si próprio.", "Em combate, canaliza jatos de esporos regenerativos para restaurar a saúde de inimigos aliados próximos.", "curater", Color(0.34, 1.0, 0.42), ["aglomerador", "ruptura"], "support"), 
		_entry("enemy", "larapio", "Larápio", "Coletor inteligente e manipulador espacial", "Espécie inteligente com obsessão por objetos valiosos e capacidade de abrir micro-portais.", "Humanoide bípede altamente inteligente e oportunista nativo das Ruínas Cósmicas, caracterizado por sua cultura de coleta e habilidade biológica de manipulação micro-focal de dobras espaciais.", "Pertence a uma espécie ancestral de catadores bípedes. Sua anatomia possui órgãos de ressonância vestigiais que lhes permitem dobrar o espaço em uma escala microscópica.", "Arremessa pedras compactas para atordoar a presa, aproxima-se para roubar recursos e abre um micro-portal sob os próprios pés para fugir.", "larapio", Color(0.74, 0.24, 1.0), ["avarento", "cartas"], "combat"), 
		_entry("enemy", "rebobinador", "Rebobinador", "Catalisador de reinjeção energética", "Organismo composto por 80% de energia cósmica que re-injeta carga em corpos derrotados.", "Entidade energética das Ruínas Cósmicas composta por 80% de energia cósmica purificada e 20% de casca mineral.", "Formado em jazidas saturadas de radiação cósmica nas profundezas do planeta. Sua biologia consegue absorver, armazenar e re-injetar surtos violentos de energia cósmica em corpos orgânicos recém-colapsados.", "Emite uma onda de reinjeção energética que restaura inimigos abatidos nas proximidades.", "enemy_common_phase_1", Color(1.0, 0.58, 0.16), ["cronofago", "ressonante"], "support"), 
		_entry("enemy", "briguer_escudeiro", "Briguer Escudeiro", "Defensor de repulsão bioenergética", "Organismo especializado que emite um campo bioelétrico frontal refletindo disparos.", "Defensor especializado da fauna das Ruínas Cósmicas, equipado com órgãos vitais frontais que geram uma membrana de repulsão cinético-energética.", "Desenvolvido nas zonas de constante queda de meteoritos, evoluiu placas peitorais condutoras que expelem um campo bioelétrico frontal denso que absorve e devolve o vetor de movimento.", "Ergue uma barreira bioenergética frontal que reflete disparos e projéteis de volta para o atacante.", "enemy_common_phase_1", Color(0.42, 0.92, 1.0), ["cristalizado", "comum"], "combat"), 
		_entry("enemy", "pinguim_atirador", "Pinguim Atirador", "Soldado territorial da Dimensão Gelada", "Defensor padrão que projeta disparos salivares glaciais a temperaturas anômalas.", "Habitante nativo e soldado territorial da civilização aviária da Dimensão Gelada, adaptado para a defesa de seu reino e habitat.", "Os Pinguns são os defensores da sociedade organizada que prospera nas estepes congeladas sob a autoridade de seu Rei. Identificam Geovana como invasora hostil.", "Condensa o ar congelante em suas glândulas salivares e projeta cuspes/disparos glaciais que atingem temperaturas anômalas de até -280 °C na física local.", "enemy_common_phase_2_left", Color(0.54, 0.88, 1.0), ["nevasca", "pinguim_incendiario"], "combat"), 
		_entry("enemy", "pinguim_kamikaze", "Pinguim Kamikaze", "Defensor militar voluntário", "Soldado voluntário que aceita o próprio fim para proteger seu reino.", "Defensor militar voluntário da Dimensão Gelada, equipado com cargas minerais explosivas para a proteção de pontos estratégicos de seu território.", "Na cultura militar da sociedade dos pinguins, o sacrifício pessoal pela preservação da colônia é a mais alta honra defensiva.", "Avança em alta velocidade diretamente contra a invasora e detona sua carga explosiva ao encurtar a distância.", "enemy_phase_2_kamikaze", Color(0.82, 0.94, 1.0), ["nevasca", "pinguim_atirador"], "combat"),
		_entry("enemy", "pinguim_incendiario", "Pinguim Incendiario", "Variação biológica térmica", "Variação rara capaz de sintetizar fósforo e emitir massas de fogo para controlar território.", "Variação biológica térmica da espécie aviária, cujos órgãos internos sintetizam vesículas de fósforo mineral e óleo térmico.", "Desenvolveu glândulas pirofóricas capazes de gerar combustão endotérmica para derreter galerias no gelo e aquecer ninhos reais. Em guerra, usa fogo para conter invasores.", "Projeta blocos e massas de fogo que permanecem queimando no terreno, cortando rotas de fuga.", "enemy_phase_2_pyro", Color(1.0, 0.46, 0.2), ["nevasca", "pinguim_atirador"], "combat"),
		_entry("enemy", "devoto", "Devoto", "Guardião ritual do templo", "Rato cultista responsável pela guarda da Catedral e serviço ao Pai-Rato.", "Neófito e guardião da ordem sagrada na Catedral dos Ratos, dedicado à preservação do templo e ao culto do Pai-Rato.", "A Catedral é o coração espiritual e a fortaleza sagrada de uma antiga civilização murina. A chegada de Geovana é vista pela ordem como uma profanação impura do solo sagrado.", "Avança em patrulhas coordenadas no combate corpo a corpo, cercando o invasor para proteger as câmaras sagradas.", "enemy_phase_3_left", Color(0.74, 1.0, 0.46), ["pai_rato", "incensario"], "combat"), 
		_entry("enemy", "incensario", "Incensario", "Sacerdote purificador de alfaias", "Sacerdote que carrega a substância sagrada, volatilizando-a em gás corrosivo.", "Sacerdote sênior da ordem murina, incumbido de purificar as naves do templo com o incenso sagrado do Pai-Rato.", "Carrega turíbulos bronzados contendo o bálsamo sagrado da ordem — uma substância fluida venerada como água benta pelos devotos, que volatiliza em névoa corrosiva ao ar.", "Espalha nuvens de gás ritual que cobrem extensas áreas do mapa, infligindo dano contínuo.", "enemy_phase_3_right", Color(0.68, 1.0, 0.28), ["pai_rato", "devoto"], "combat"), 
		_entry("enemy", "guardiao", "Guardiao", "Paladino consagrado da Catedral", "Rato militarizado de grande porte e fé inabalável, responsável pela defesa do altar.", "Cavaleiro e paladino de elite da Catedral dos Ratos, cuja força física avantajada é consagrada aos rituais de proteção do Pai-Rato.", "Escolhidos entre os murinos de maior porte e submetidos a jejuns e unções sagradas, formam a guarda de ferro do altar com devoção inabalável.", "Avança pesadamente na linha de frente, absorvendo uma grande quantidade de dano e desferindo golpes corpo a corpo devastadores.", "enemy_phase_3_left", Color(0.94, 0.86, 0.54), ["pai_rato", "devoto"], "support"), 
		_entry("enemy", "cartografo_vazio", "Cartografo do Vazio", "Intérprete probabilístico do Vazio", "Organismo anfíbio que lê oscilações de probabilidade do Vazio, fazendo previsões precisas.", "Organismo anfíbio senciente do Vazio, dotado de órgãos sensoriais capazes de interpretar as correntes de probabilidade das linhas temporais.", "Nativo das margens pantanosas e fendas do Vazio, percebe as oscilações de probabilidade e vibrações quânticas do ambiente para traçar mapas mentais de trajetórias.", "Mapeia as trajetórias de deslocamento do jogador na arena, antecipando posições futuras e lançando armadilhas vetoriais.", "enemy_phase_4_left", Color(0.26, 1.0, 0.82), ["nexo_ruptura", "cartografica"], "combat"), 
		_entry("enemy", "cronofago", "Cronofago", "Fome de segundos", "Uma fome especifica por segundos.", "Nao devora corpo primeiro; devora margem. Perto dele, cada atraso parece maior e cada decisao fica curta.", "O Cronofago e a parte da Ruptura que descobriu que tempo tambem pode sangrar.", "Atrapalha ritmo e janelas. Trate como inimigo de cadencia, nao apenas de posicao.", "enemy_phase_4_right", Color(0.86, 0.58, 1.0), ["nexo_ruptura", "rebobinador"], "combat"), 
		_entry("enemy", "refrator_hostil", "Refrator Hostil", "Espelho do erro", "Desvia intencao e devolve confusao.", "Parece estar no caminho, mas o perigo real e fazer o jogador mirar como sempre e receber uma resposta torta.", "Refratores sao espelhos da quarta ruptura. Eles nao copiam imagem; copiam erro.", "Altera leitura de disparos e posicionamento. Observe antes de despejar habilidade.", "enemy_phase_4_left", Color(0.6, 0.86, 1.0), ["nexo_ruptura", "prismatica"], "combat"), 
		_entry("enemy", "tecelao_vetorial", "Tecelao Vetorial", "Costureiro de trajetorias", "Costura trajetorias invisiveis.", "O problema aparece quando o mapa inteiro comeca a obedecer linhas que voce nao escolheu.", "O Tecelao trata movimento como tecido. Cada rota repetida vira fio facil de puxar.", "Manipula espaco e favorece combate consciente de rota. Jogar em linha reta e aceitar o desenho da fase.", "enemy_phase_4_right", Color(1.0, 0.74, 0.3), ["nexo_ruptura", "cartografica"], "combat"), 
		_entry("enemy", "eco_entropico", "Eco Entropico", "Acao que nao terminou", "O resto de uma acao que nao terminou.", "Alguns inimigos morrem. O Eco parece continuar vindo de uma decisao antiga, repetindo um perigo que ja devia ter passado.", "Sobra de calculos falhos da Ruptura, presa no mesmo impulso ate alguem interromper.", "Cria repeticao e distracao visual/tatica; limpe prioridade antes que o campo acumule ruido.", "enemy_phase_4_left", Color(1.0, 0.42, 0.86), ["nexo_ruptura", "mnesica"], "combat"), 
		_entry("enemy", "enguia_miasma", "Enguia do Miasma", "Febre subterranea", "Uma febre que aprendeu a nadar na fenda.", "Desliza como se o ar fosse lama. Nao ocupa muito espaco, mas deixa a leitura da arena mais venenosa.", "Sintoma da sexta ruptura: um corpo fino carregando o odor vivo de algo que apodreceu fora do tempo.", "Pressao movel da fase 6. Fica parada apos se deslocar e prepara terreno para ameacas mais pesadas.", "enemy_phase_6_enguia_miasma", Color(0.58, 1.0, 0.78), ["matriarca_chaga", "pustula_fossil"], "combat"), 
		_entry("enemy", "lodario", "Lodario", "Peso mole da Chaga", "O peso mole da Chaga.", "Arrasta-se como lama com vontade propria. Onde passa, a fase parece ficar mais espessa e menos generosa com erro.", "Mistura de sedimento, memoria e carne cansada. A Matriarca nao o comanda como soldado; ela o derrama pelo mapa.", "Corpo de bloqueio que salta em intervalos. Feromonios de pustulas deixam seus saltos mais agressivos.", "enemy_phase_6_lodario", Color(0.86, 0.7, 0.46), ["matriarca_chaga", "pustula_fossil"], "combat"), 
		_entry("enemy", "pustula_fossil", "Pustula Fossil", "Ferida antiga", "Uma ferida antiga que ainda pulsa.", "Parece parada demais para ser urgente, ate a arena obrigar Geovana a encostar no que devia estar enterrado.", "A sexta ruptura conserva suas dores como reliquias. Cada pustula tenta voltar a ser carne.", "Explode perto do jogador, deixa area perigosa e contamina com feromonios que atraem Lodarios.", "enemy_phase_6_pustula_fossil", Color(1.0, 0.62, 0.32), ["matriarca_chaga", "lodario"], "combat"), 
		_entry("enemy", "sanguessuga_cronal", "Sanguessuga Cronal", "Parasita de instante", "Bebe segundos antes de beber sangue.", "Primeiro cai, se enterra no mapa e espera Geovana cruzar perto demais para saltar em linha reta.", "Parasita de instante: gruda no presente e tenta tornar todo futuro curto demais para escapar.", "Armadilha viva da fase 6. Ativa perto do jogador e aplica parasitismo temporario com lentidao e sangramento leve.", "enemy_phase_6_sanguessuga_cronal", Color(0.92, 0.42, 0.72), ["matriarca_chaga", "enguia_miasma"], "combat")
	]


static func boss_entries() -> Array:
	return [
		_entry("boss", "caranguejo_cosmico", "Caranguejo Cosmico", "Primeira muralha viva", "A primeira muralha viva da Ruptura.", "Grande demais para parecer justo e antigo demais para parecer perdido. Ele testa se Geovana aprendeu a ler areas, janelas e reposicionamento.", "O primeiro chefe e a fenda usando um corpo simples para perguntar uma coisa cruel: voce sabe sair do lugar certo na hora certa?", "Alterna perseguicao, saltos, ondas, bolhas e eventos de tempo. O combate ensina leitura de telegráficos e punicao de ganancia.", "boss_stage1", Color(1.0, 0.32, 0.18), ["comum", "rebobinador"], "combat"), 
		_entry("boss", "nevasca", "Nevasca", "Centro frio da segunda ruptura", "O centro frio da segunda ruptura.", "A Nevasca nao quer apenas acertar Geovana. Quer controlar onde ela acredita que pode ficar.", "Nasceu quando o mapa congelado parou de ser cenario e virou vontade. Cada vento tenta empurrar o jogador para uma decisao ruim.", "Usa vento, gelo, zonas seguras e congelamento. A luta e leitura de arena, nao corrida cega.", "boss2", Color(0.62, 0.94, 1.0), ["pinguim_atirador", "pinguim_kamikaze", "pinguim_incendiario"], "combat"), 
		_entry("boss", "pai_rato", "Pai-Rato", "Ritual e miasma", "Ritual, miasma e provocacao.", "Mistura nojo, humor ruim e perigo real. Parece baguncado ate os rituais tomarem partes da tela.", "Comanda a terceira ruptura como culto de sobreviventes deformados. Nao vence por honra; vence por insistencia.", "Trabalha com nuvens, clones, rituais e perseguicao. Tira conforto e forca resposta ativa.", "boss3", Color(0.74, 1.0, 0.3), ["devoto", "incensario", "guardiao"], "combat"), 
		_entry("boss", "nexo_ruptura", "Nexo da Ruptura", "Geometria hostil", "A arena pensando contra voce.", "Na quarta ruptura o chefe parece menos bicho e mais fenomeno. Transforma mapa, trajetoria e espaco em parte do combate.", "Uma inteligencia de geometria quebrada. Ele nao odeia Geovana; apenas recalcula o mundo sem incluir a sobrevivencia dela.", "Invoca planetas, fendas, gravidade, lasers e ancoras. Vencer e entender quais objetos sustentam a ameaca.", "boss4", Color(1.0, 0.78, 0.26), ["cartografo_vazio", "cronofago", "tecelao_vetorial"], "combat"), 
		_entry("boss", "umbra", "UMBRA", "Mente inevitavel", "A mente inevitavel da quinta fase.", "UMBRA nao e so chefe. E uma leitura do jogador tentando aprender, responder e usar memoria contra habitos repetidos.", "Os registros da Ruptura tratam UMBRA com cautela incomum. Alguns arquivos sugerem que ela conversa com o modo como Geovana joga.", "Alterna dimensoes, teletransportes, prisao, descarga e adaptacao. Pune rotina e recompensa variacao consciente.", "boss5", Color(0.56, 1.0, 0.68), ["mnesica", "ruptura"], "lore"), 
		_entry("boss", "matriarca_chaga", "Matriarca da Chaga", "Sexta ruptura em corpo aberto", "A sexta ruptura em corpo aberto.", "Nao corre atras do jogador: controla o mapa como organismo parado, escolhendo quando fermentar o chao, rachar a arena e expor o nucleo.", "A Matriarca parece uma mae de sintomas: nada nela nasce inteiro, mas tudo que perde tenta voltar com fome.", "Chefe de estados da fase 6: carapaca quebravel, poças acidas, rachaduras perseguidoras, foices vertebrais, cauda condutiva, mare de carnificina, nevoa e refluxo organico.", "boss6_form_1", Color(1.0, 0.64, 0.18), ["enguia_miasma", "lodario", "pustula_fossil", "sanguessuga_cronal"], "combat")
	]


static func faction_entries() -> Array:
	return [
		_entry("fraction", "ruptura", "Ruptura", "Cicatriz temporal e colapso espacial", "O acidente dimensional gerado pela explosão do dispositivo temporal.", "A Ruptura foi o acidente provocado pela explosão do dispositivo temporal. A violenta descarga espacial rasgou o tecido entre as dimensões, quase destruindo a realidade original de Geovana e espalhando os componentes por universos preexistentes.", "A Ruptura não criou as dimensões nem as criaturas que habitam cada mundo. A energia viva do dispositivo rasgou o espaço-tempo e deixou um rastro dimensional pontilhado entre os locais por onde suas peças passaram. A jornada de Geovana consiste em seguir esse rastro, recuperar cada peça e atravessar para a próxima dimensão.", "Conecta as diferentes dimensões da travessia e dita o rastro energético que Geovana deve seguir.", "map_phase_1", Color(1.0, 0.08, 0.78), ["geovana", "arauto"], "lore"), 
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
