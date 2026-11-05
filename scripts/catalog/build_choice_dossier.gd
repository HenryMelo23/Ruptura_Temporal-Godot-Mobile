class_name RTBuildChoiceDossier
extends RefCounted

## Textos da tela de escolha (Geovana: Manifestacao + Espectro; Henry: Mutacao + Efeito).
## Conferidos contra o codigo em 2026-11-04. Ao mudar uma mecanica, atualize aqui:
## tests/build_choice_dossier_smoke.gd confere alguns numeros contra as constantes reais.
## Formato: {tagline, style, difficulty (1-3), rows: [{label, title, text}], note}

const AURA_LEVEL_NOTE := "Valores do nível 1. Sobem conforme o espectro evolui na conta."


static func manifestation(key: String) -> Dictionary:
	match key:
		"eletrica":
			return {
				"tagline": "Simples e segura: dano constante, controle e raios por combinação.",
				"style": "Alcance médio · fácil",
				"difficulty": 1,
				"rows": [
					{"label": "ATAQUE", "title": "Tiro elétrico", "text": "Disparo reto com 100% do dano."},
					{"label": "PASSIVA", "title": "Estática", "text": "Acertar o mesmo alvo alternando fontes (ATK, Q, E, TP) soma cargas. Na terceira cai um raio de 340% do dano (10% de crítico) que respinga 50% em 140 px."},
					{"label": "Q · 10 s", "title": "Onda Cinética", "text": "Onda na mira que para no primeiro inimigo e eletrifica a corrente em até 250 px por 5 s: 10% da vida máx. + 30% do dano por segundo, dividido entre os alvos, e atordoa 0,5 s. Chefes levam 500% do dano. Empurra a Geovana para trás."},
					{"label": "E · 10 s", "title": "Anel de Tesla", "text": "Anel de 156 px que dá choque a cada 0,4 s (0,5% da vida máx. + 50% do dano, crescendo com o tempo) e atordoa 0,2 s. Fica ligado até apertar E de novo; após 15 s drena sua vida (1% da vida atual/s, dobrando a cada 4 s)."},
					{"label": "TP · 4 s", "title": "Descarga", "text": "Vira eletricidade por 3 s no caminho, invulnerável: quem for atravessado leva 0,5% da vida máx. a cada 0,3 s."},
				],
				"note": "",
			}
		"lacerante":
			return {
				"tagline": "Corpo a corpo de alto risco: executa, junta Coágulos e escala.",
				"style": "Curto alcance · difícil",
				"difficulty": 3,
				"rows": [
					{"label": "ATAQUE", "title": "Três lâminas", "text": "Sequência de 3 cortes de perto; cada corte soma 1 Laceração (o terceiro soma 2). +5 px de alcance a cada 20 Coágulos; alvos grandes levam até +18%."},
					{"label": "PASSIVA", "title": "Caçadora", "text": "Recebe 22% menos dano. Laceração: até 5 cargas por 4 s; cada uma dá +4% de dano dos cortes e sangra 5% do dano a cada 0,5 s. Incomuns valem +50% de pontos. Cada Coágulo: +0,3% de dano e +0,25% de velocidade de ataque."},
					{"label": "REFORÇO · 10 s", "title": "Execução", "text": "Arma o próximo ATK. Se o corte pegar um inimigo dentro da barra de execução, a Geovana o executa: 0,9 s invulnerável, alvo reservado só para ela e 1 Coágulo garantido (recarga de 10 s). Se não, sai um golpe com +45% sem execução (recarga de 15 s). Cada ATK que acerta adianta a recarga em 0,3 s, até um piso de 4 s; a carta Intervalo Fraturado baixa esse piso."},
					{"label": "Q · 10 s", "title": "Círculo Lacerante", "text": "A lâmina dá 5 voltas em 1,5 s (128 px). Cada volta fere e cura 0,25% da vida perdida por alvo. +1 volta a cada 10 Coágulos."},
					{"label": "E · 75 s", "title": "Carnificina Temporal", "text": "15 cortes em 3 s na área mirada, com a Geovana parada e invulnerável. Cada corte: 6% da vida máx. ou 65% do dano (o maior); alvos já lacerados levam 10% / 115%. +2 cortes a cada 20 Coágulos."},
					{"label": "TP · 2 cargas", "title": "Execução", "text": "Depois do primeiro teleporte há 2,5 s para o segundo. Atravessar até 3 alvos aplica 10 cortes em 3 s (50 + 0,5% da vida máx. cada), invulnerável. Recarga de 2 s após os cortes."},
				],
				"note": "",
			}
		"prismatica":
			return {
				"tagline": "Técnica de ângulo: ricochetes, prismas e invulnerabilidade curta.",
				"style": "Longo alcance · médio",
				"difficulty": 2,
				"rows": [
					{"label": "ATAQUE", "title": "Feixe", "text": "Feixe rápido (60% do dano) que atravessa inimigos e ricocheteia nas bordas até 3 vezes, +2% de dano por ricochete. A mira automática só dispara em alvos até 420 px."},
					{"label": "PASSIVA", "title": "Horizonte refratado", "text": "Cada carta Horizonte da Ruptura vira +3% de crítico nos feixes que já ricochetearam, em vez de alcance."},
					{"label": "Q · 7,5 s", "title": "Prisma de Refração", "text": "Prisma no ponto mirado por 6,2 s. Feixes que passam por ele viram 5 (mais abertos quanto mais perto você atira). O prisma queima 75% do dano/s em volta."},
					{"label": "E · 75 s", "title": "Coroa Espectral", "text": "Até 10 s parada e invulnerável: feixes giram (350 px) e descargas acertam até 4 alvos a cada 0,24 s (430 px). Aperte E para encerrar antes."},
					{"label": "TP · 4 s", "title": "Prisma de chegada", "text": "Deixa um prisma grande (76 px) no destino por 10 s, que também divide feixes. A recarga começa quando ele some."},
				],
				"note": "",
			}
		"parasitica":
			return {
				"tagline": "Infestação: marque com larvas e solte o enxame nos marcados.",
				"style": "Alcance médio · médio",
				"difficulty": 2,
				"rows": [
					{"label": "ATAQUE", "title": "Verme", "text": "Projétil lento com 88% do dano. Cada acerto põe 1 larva (máx. 5) e renova a marca por 6 s."},
					{"label": "Q · 8 s", "title": "Cuspe Infestante", "text": "Bolo de vermes na mira que vira um viveiro de 155 px por 4,8 s: 50% do dano a cada 0,55 s e larvas em quem estiver dentro."},
					{"label": "E · 75 s", "title": "Enxame Subterrâneo", "text": "Só funciona com alvos marcados. Os vermes chegam em cerca de 2 s e devoram cada marcado por 8 s: 6% da vida atual por segundo, com lentidão. Chefes também."},
					{"label": "TP", "title": "Ninhada", "text": "Deixa 3 ovos na origem; os vermes perseguem e atordoam por 1,8 s. Chefes usando habilidade resistem ao atordoamento."},
				],
				"note": "Dica: espalhe larvas com ATK e Q antes de usar o E.",
			}
		"gravitante":
			return {
				"tagline": "Controle gravitacional: acumula massa, agrupa a horda e esmaga.",
				"style": "Alcance médio · fácil",
				"difficulty": 1,
				"rows": [
					{"label": "ATAQUE", "title": "Orbe gravitante", "text": "Orbe lento com 52% do dano. Cada acerto prende uma órbita no alvo (até 3) que causa pequenos danos por 4 s."},
					{"label": "PASSIVA", "title": "Massa crítica", "text": "Com 3 órbitas, o alvo vira uma Estrela que puxa os inimigos a até 120 px para perto dele, agrupando a horda."},
					{"label": "Q · 8,3 s", "title": "Colisão Gravitacional", "text": "Puxa todos os marcados para o centro de massa em 0,3 s e os colide: 110% do dano + 22% por alvo + 30% por órbita extra. Empurra quem estiver por perto."},
					{"label": "E · 75 s", "title": "Núcleo Gravitante", "text": "Núcleo de 330 px por 8 s que encolhe: prende, atordoa e gira inimigos, chefes inclusos. Quanto mais perto da borda, mais dano; no colapso final, 335%."},
					{"label": "TP", "title": "Poço de Partida", "text": "A origem vira um poço por 2,5 s que puxa inimigos em 200 px e prende uma órbita em cada um. No fim colapsa: 90% do dano + 30% por órbita."},
				],
				"note": "",
			}
	return {}


static func spectrum(name: String) -> Dictionary:
	match name:
		"Racional":
			return _aura("Controle do tempo para quem joga com calma.", [
				["GATILHO", "Parar e teleportar", "Fique parada 4,5 s: +7 pontos (Análise). O Teleporte ativa a Dilatação."],
				["EFEITO", "Dilatação", "Por 8 s o mundo anda a 42% da velocidade; você fica 35% mais rápida e ataca 28% mais rápido."],
				["CUSTO", "Rebote", "Depois, 3 s com o mundo 18% mais rápido. Nova Dilatação só 30 s após o fim."],
			])
		"Impulsiva":
			return _aura("Ritmo agressivo: abates em sequência viram Frenesi.", [
				["GATILHO", "5 abates", "Cada 5 abates ativam Frenesi por 3,5 s. Abates durante o Frenesi sobem o nível."],
				["EFEITO", "Frenesi", "+30% de dano e +20% de velocidade, +15% em ambos por nível de Frenesi."],
				["CUSTO", "Pânico", "Levar dano em Frenesi encerra e arma Pânico: o próximo golpe que você levar causa 2,5× ou mais."],
			])
		"Devota":
			return _aura("Margem de erro: cargas que anulam golpes.", [
				["GATILHO", "3 cargas de Fé", "Começa com 3 cargas; cada golpe recebido gasta uma."],
				["EFEITO", "Anular", "Cada carga anula o golpe, cura 10% da vida perdida e dá +25% de dano por 3 s. A última dá +65% por 4,5 s."],
				["CUSTO", "Sem fé", "Sem cargas: 10% mais lenta por 4,5 s e 19,5 s para recarregar as 3."],
			])
		"Vanguarda":
			return _aura("Troca de dano: apanhar acende fogo em volta.", [
				["GATILHO", "Levar dano", "Cada golpe recebido acende um anel de fogo (150 px) por 5 s."],
				["EFEITO", "Queimadura", "Inimigos queimando perdem 1,2% da vida máx. por segundo."],
				["CUSTO", "Peso no TP", "Cada inimigo queimando deixa a recarga do Teleporte 15% maior."],
			])
		"Insana":
			return _aura("Ecos atrasados que repetem seus tiros.", [
				["GATILHO", "Ciclo de 20 s", "A cada 20 s, os próximos 4 tiros deixam Ecos no ponto do disparo."],
				["EFEITO", "Eco", "Cada Eco repete o tiro 1 s depois com 17% do dano. Matar com um Eco faz o próximo ciclo ter 5."],
				["CUSTO", "Exaustão", "Quando o ciclo acaba, o próximo Teleporte ganha +2 s de recarga."],
			])
		"Voraz":
			return _aura("Fome: colete Coágulos para curar e acelerar.", [
				["GATILHO", "Coágulos", "Inimigos mortos soltam Coágulos (somem em 6,8 s); chefes soltam ao serem atingidos."],
				["EFEITO", "Fome", "Coletar cura 2% da vida perdida (até 14,5% em ciclos altos). Fome alta dá mais dano por tiro e ataques até 12% mais rápidos."],
				["CUSTO", "Abstinência", "A Fome cai sozinha. 30 s sem coletar drena 1% da vida a cada 1,5 s."],
			])
		"Nula":
			return _aura("Paciência: pausas carregam um tiro anulador.", [
				["GATILHO", "Pausa", "Ficar 2,3 s sem atacar carrega Vazio; cada abate dá +18%."],
				["EFEITO", "Nulificação", "Com 100%, o próximo tiro marca o alvo como Nulo por 4,5 s; se ele tiver 55%+ de vida, leva +21,5% de dano."],
				["CUSTO", "Carga lenta", "Enquanto há Vazio, o Teleporte recarrega 4% mais devagar."],
			])
		"Abissal":
			return _aura("Cresce no cerco: quanto mais perto a horda, mais forte.", [
				["GATILHO", "Profundidade", "Inimigos na arena e, principalmente, a até 190 px enchem a barra (chefe ativo também)."],
				["EFEITO", "Maré Negra", "Com 100%, por 5,75 s puxa quem estiver a 190 px e fere os com 21,5% de vida ou menos. Seu dano sobe 7,5% (26% contra feridos)."],
				["CUSTO", "Peso", "A Profundidade te deixa até 22% mais lenta e alonga a recarga do Teleporte."],
			])
		"Profetica":
			return _aura("Prioridade de alvo: cumpra os presságios.", [
				["GATILHO", "Presságio", "A cada 10 s, um inimigo é marcado por 6,4 s."],
				["EFEITO", "Cumprir", "Acertar o marcado causa +26% de dano nesse golpe e sobe a sequência."],
				["CUSTO", "Destino quebrado", "Se o tempo acabar, a sequência zera e o Teleporte fica 12% mais lento por 3,5 s."],
			])
		"Sanguinaria":
			return _aura("Foco no mesmo alvo e caçadas com regra.", [
				["GATILHO", "Feridas e Caçada", "3 acertos no mesmo alvo abrem uma Ferida por 8 s. Um inimigo é marcado para Caçada com uma regra de abate."],
				["EFEITO", "Sede e combo", "Feridos levam +15,5% de dano (mais com Sede). Com 4 Feridas, o próximo golpe num ferido faz +35%. Cumprir a Caçada soma combo: +dano, +velocidade e +recarga em rodízio."],
				["CUSTO", "Abstinência", "8,5 s sem ferir faz a Sede cair; zerada, 5% mais lenta. Matar o caçado do jeito errado perde o combo."],
			])
		"Crepuscular":
			return _aura("Duas fases que se alternam e um Eclipse na virada.", [
				["GATILHO", "Fases de 8 s", "Alvorada (defesa) carrega sem levar dano por 1,5 s e com curas. Ocaso (ataque) carrega com dano direto e abates."],
				["EFEITO", "Alvorada / Ocaso / Eclipse", "Alvorada: -12,5% de dano recebido e curas +12%. Ocaso: +13,5% de dano e ataques 6% mais rápidos. Com 100% na virada (ou TP no fim da fase com 70%+), Eclipse por 3 s com 65% dos dois bônus."],
				["CUSTO", "Instável", "Levar dano tira 18% da carga. No Ocaso, curas rendem 18% menos."],
			])
		"Peregrino":
			return _aura("Mobilidade: explore a arena e volte ao Refúgio.", [
				["GATILHO", "Passos", "Cada setor novo (blocos de 300 px) dá 1 Passo; Teleporte dá 2. Os 3 últimos setores não contam."],
				["EFEITO", "Jornada", "Com 5 Passos, Jornada por 5,5 s: +10,5% de velocidade e regeneração. Voltar ao ponto onde começou (Refúgio) cura 5% da vida perdida."],
				["CUSTO", "Parada", "4 s parada faz perder 1 Passo a cada 2 s."],
			])
		"Equilibrista":
			return _aura("Jogo fino de vida entre 35% e 80%.", [
				["GATILHO", "Faixa de vida", "Com a vida entre 35% e 80%, a barra de Equilíbrio enche; fora disso, esvazia."],
				["EFEITO", "Equilíbrio", "Cheia: 6 s com +10% de dano; cura acima do máximo vira escudo (até 17% da vida)."],
				["CUSTO", "Dívida", "Golpe que te levaria abaixo de 35% vira Dívida: o excedente é cobrado aos poucos (4,5% da vida a cada 0,65 s)."],
			])
		"Avarento":
			return _aura("Economia defensiva: guardar pesa, gastar explode.", [
				["GATILHO", "Lastro", "Quanto mais pontos guardados em relação ao preço da loja, maior o Lastro."],
				["EFEITO", "Cofre", "Lastro reduz o dano recebido (até 30%). Gastar pontos rompe o Cofre por 3,9 s: velocidade, sem peso e escudo. O Teleporte deixa 3 fragmentos que dão escudo curto."],
				["CUSTO", "Peso", "Lastro alto te deixa até 15% mais lenta."],
			])
		"Oportunista":
			return _aura("Punição: ataque quando o inimigo se expõe.", [
				["GATILHO", "Aberturas", "Acertar inimigos preparando ataque, se recuperando, atordoados ou prestes a atirar dá cargas; desviar de um ataque telegrafado com Teleporte dá 2."],
				["EFEITO", "Golpe de Oportunidade", "Com 4 cargas, o próximo dano direto causa +62% do seu dano, atrasa o inimigo e devolve parte da recarga de Q/E."],
				["CUSTO", "Janela", "12 s sem Abertura começa a perder cargas. Cartas, áreas persistentes e aliados não contam."],
			])
	return {}


static func mutation(key: String) -> Dictionary:
	match key:
		"incendiario":
			return {
				"tagline": "Fogo acumulado: Queimaduras que viram dano verdadeiro.",
				"style": "Alcance médio · médio",
				"difficulty": 2,
				"rows": [
					{"label": "ATAQUE", "title": "Estalo Ígneo", "text": "Estalos de fogo; o terceiro golpe é uma bola de fogo que explode em área. Acertos somam Queimadura (máx. 5)."},
					{"label": "HAB1", "title": "Cone de fogo", "text": "Cone de fogo + 3 explosões defensivas que empurram. Ao usar, deixa lentos os inimigos perto e afasta quem encosta. Teleporte ou apertar de novo cancela."},
					{"label": "ULT", "title": "Ondas de Calor", "text": "3 ondas (150 / 225 / 300 px) que consomem Queimaduras em dano verdadeiro e empurram com lentidão. Repele a horda ao começar; Teleporte ou apertar de novo cancela."},
					{"label": "DASH", "title": "Rastro de Brasa", "text": "Investida giratória de até 300 px que deixa o chão em chamas por 3 s."},
				],
				"note": "",
			}
		"barometrico":
			return {
				"tagline": "Pressão e vento: lâminas, corredor e tempestade.",
				"style": "Alcance médio · médio",
				"difficulty": 2,
				"rows": [
					{"label": "ATAQUE", "title": "Lâmina de pressão", "text": "Atravessa um alvo e curva no segundo; o terceiro disparo é maior."},
					{"label": "HAB1", "title": "Corredor de baixa pressão", "text": "Corredor móvel que puxa e empurra inimigos, acelera suas lâminas e desvia tiros."},
					{"label": "ULT", "title": "Olho da Tempestade", "text": "Tempestade que acompanha o Henry por 6,5 s; chefes sofrem cortes sem serem puxados."},
				],
				"note": "",
			}
		"colosso":
			return {
				"tagline": "Corpo a corpo pesado que vira gigante por 30 s.",
				"style": "Curto alcance · médio",
				"difficulty": 2,
				"rows": [
					{"label": "ATAQUE", "title": "Combo de 3 socos", "text": "Golpes pesados acumulam Ímpeto; o terceiro solta um cone de choque com 40% do dano."},
					{"label": "HAB1", "title": "Guarda", "text": "Guarda e contra-ataca. No gigante, vira uma investida que abre sulcos no chão."},
					{"label": "ULT", "title": "Hipertrofia Absoluta", "text": "30 s como gigante: mais alcance, dano e proteção. A transformação termina num estouro que empurra tudo em 180 px."},
					{"label": "DASH", "title": "Salto (gigante)", "text": "No gigante, o Teleporte vira um salto que racha o chão na aterrissagem."},
				],
				"note": "",
			}
	return {}


static func effect(key: String) -> Dictionary:
	match key:
		"incandescencia":
			return _aura("Mortes queimando viram reação em cadeia.", [
				["GATILHO", "Morte queimando", "Inimigo que morre com Queimadura explode."],
				["EFEITO", "Combustão em Cadeia", "A explosão passa as cargas para quem estiver perto; mais cargas, explosão maior e mais forte."],
				["COMBINA", "Outras mutações", "Com Barométrico ou Colosso, cada terceiro golpe no mesmo alvo acende 1 Queimadura."],
			], "")
		"nimbo":
			return _aura("Uma nuvem que repete seus ataques.", [
				["GATILHO", "Terceiro ataque", "A cada terceiro ataque, a nuvem repete o golpe."],
				["EFEITO", "Nimbo", "A pequena nuvem acompanha o Henry e dispara da própria posição."],
				["COMBINA", "Barométrico", "No Barométrico, ocupa a frente do corredor e circula a borda do Olho da Tempestade."],
			], "")
		"lastro":
			return _aura("Peso acumulado que prende inimigos.", [
				["GATILHO", "Golpes confirmados", "Cada acerto põe peso no alvo; multi-hits têm trava curta."],
				["EFEITO", "Âncora", "No quinto acúmulo, inimigos comuns ficam ancorados e chefes sofrem uma desaceleração curta."],
				["COMBINA", "Qualquer mutação", "Funciona igual com Incendiário, Barométrico e Colosso."],
			], "")
	return {}


static func _aura(tagline: String, rows: Array, note: String = AURA_LEVEL_NOTE) -> Dictionary:
	var out_rows: Array = []
	for row in rows:
		out_rows.append({"label": String(row[0]), "title": String(row[1]), "text": String(row[2])})
	return {"tagline": tagline, "style": "", "difficulty": 0, "rows": out_rows, "note": note}
