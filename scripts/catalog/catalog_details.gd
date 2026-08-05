extends RefCounted


static func aura_details(name: String) -> Dictionary:
	match name:
		"Racional":
			return {
				"funcao": "Controle e leitura. Recompensa ficar calma, parar por instantes e usar o tempo contra a fase.",
				"disparo": "Fique imovel para gerar Analise; use Teleporte para ativar Dilatacao.",
				"habilidade": "Dilatacao",
				"desc_hab": "Desacelera o mundo por 8s e cria Rebote por 3s.",
				"traco": "Controle, leitura e reposicionamento seguro.",
				"risco": "Perde valor se voce nunca para ou teleporta sem plano."
			}
		"Impulsiva":
			return {
				"funcao": "Ritmo agressivo. Quanto mais abates sem tomar dano, maior a pressao ofensiva.",
				"disparo": "A cada 5 abates sem dano, ativa Frenesi.",
				"habilidade": "Frenesi",
				"desc_hab": "Acelera o ritmo ofensivo e premia sequencias limpas.",
				"traco": "Explosiva, rapida e focada em limpar ondas.",
				"risco": "Tomar dano quebra a sequencia e reduz o pico."
			}
		"Devota":
			return {
				"funcao": "Sobrevivencia por fe. Cria margem para errar e abre pequenas janelas de recuperacao.",
				"disparo": "Comeca com 3 cargas de protecao.",
				"habilidade": "Fe Restaurada",
				"desc_hab": "Anula impactos, cura parte da vida perdida e recarrega depois.",
				"traco": "Defensiva, estavel e boa para sobrevivencia.",
				"risco": "Gastar cargas em dano fraco deixa voce exposta."
			}
		"Vanguarda":
			return {
				"funcao": "Transforma dano recebido em area perigosa para inimigos.",
				"disparo": "Sofrer dano acende fogo ao redor de Geovana.",
				"habilidade": "Incendio Cronal",
				"desc_hab": "Queimaduras causam dano por vida maxima nos inimigos.",
				"traco": "Combate de contato, punicao e controle de cerco.",
				"risco": "Depende de tomar dano; force troca apenas com vida."
			}
		"Insana":
			return {
				"funcao": "Eco e repeticao. Cria copias atrasadas dos disparos e bagunca o campo.",
				"disparo": "Quando pronta, seus tiros criam ecos atrasados.",
				"habilidade": "Eco Insano",
				"desc_hab": "Ecos repetem disparos apos 1s e multiplicam pressao.",
				"traco": "Caotica, forte em corredores e tiros bem mirados.",
				"risco": "Mira ruim desperdiça os ecos."
			}
		"Voraz":
			return {
				"funcao": "Fome crescente. Coleta coagulos, cura vida perdida e fortalece o combate com ciclos.",
				"disparo": "Coagulos alimentam Fome e curam vida perdida.",
				"habilidade": "Mordida Voraz",
				"desc_hab": "Fome alta fortalece disparos, recargas e mordidas.",
				"traco": "Cresce em lutas longas e mapas cheios.",
				"risco": "Sem coleta, a Fome demora a virar poder."
			}
		"Nula":
			return {
				"funcao": "Precisao e paciencia. Carrega Vazio quando Geovana fica sem atacar.",
				"disparo": "Ficar sem atacar carrega Nulo.",
				"habilidade": "Nulificacao",
				"desc_hab": "O proximo tiro enfraquece alvo robusto e aumenta o dano.",
				"traco": "Precisao, paciencia e alto valor contra elites.",
				"risco": "Atirar sem pensar consome a janela carregada."
			}
		"Abissal":
			return {
				"funcao": "Escala com cerco. Quanto mais inimigos perto, mais Profundidade acumula.",
				"disparo": "Cerco e inimigos proximos carregam Profundidade.",
				"habilidade": "Mare Negra",
				"desc_hab": "Com 100%, invoca Mare Negra que puxa e fere alvos.",
				"traco": "Forte contra hordas e cercos densos.",
				"risco": "Posicionamento ruim pode prender Geovana no cerco."
			}
		"Profetica":
			return {
				"funcao": "Destino marcado. Escolhe pressagios e recompensa cumprir o alvo correto.",
				"disparo": "Marca um alvo por tempo limitado.",
				"habilidade": "Pressagio",
				"desc_hab": "Acertar o alvo marcado aumenta dano e sequencia.",
				"traco": "Foco, prioridade e leitura limpa de alvo.",
				"risco": "Ignorar o alvo marcado desperdiça a recompensa."
			}
		"Sanguinaria":
			return {
				"funcao": "Feridas e sede. Dano repetido no mesmo alvo cria Feridas e alimenta Sede.",
				"disparo": "Acertos repetidos no mesmo alvo abrem Feridas.",
				"habilidade": "Carnificina Controlada",
				"desc_hab": "Feridas alimentam Sede e preparam Carnificina.",
				"traco": "Foco constante e pico contra alvos resistentes.",
				"risco": "Trocar muito de alvo derruba Feridas e Sede."
			}
		"Crepuscular":
			return {
				"funcao": "Alterna entre Alvorada defensiva e Ocaso ofensivo. Se carregar a fase ate 100%, ativa Eclipse.",
				"disparo": "Ocaso carrega com dano direto e abates; Alvorada carrega com cura real e tempo sem dano.",
				"habilidade": "Eclipse",
				"desc_hab": "Combina parte da defesa da Alvorada com parte do dano e cadencia do Ocaso.",
				"traco": "Controle de transicao, leitura de risco e janela perfeita de teleporte.",
				"risco": "Tomar dano reduz carga; usar TP fora da janela nao acelera o Eclipse."
			}
		"Peregrino":
			return {
				"funcao": "Explora setores diferentes da arena para iniciar Jornada e marcar um Refugio.",
				"disparo": "Cada setor novo concede Passos; repetir os ultimos setores nao conta.",
				"habilidade": "Jornada",
				"desc_hab": "Aumenta velocidade, coleta e regeneracao por vida perdida ate voltar ao Refugio.",
				"traco": "Mobilidade planejada, rotas e reposicionamento constante.",
				"risco": "Ficar parado ou pingar entre os mesmos setores perde Passos."
			}
		"Equilibrista":
			return {
				"funcao": "Fica mais forte mantendo a vida entre 35% e 80%.",
				"disparo": "Dentro da faixa, carrega Equilibrio; fora dela, a barra cai.",
				"habilidade": "Equilibrio",
				"desc_hab": "Concede dano e reducao de dano. Overheal acima de 80% vira escudo temporario.",
				"traco": "Jogo fino de vida, risco controlado e sobrevivencia ativa.",
				"risco": "Dano que cruza 35% vira Divida e pode matar se ignorada."
			}
		"Avarento":
			return {
				"funcao": "Pontos guardados viram Lastro: defesa e resistencia a impacto em troca de peso.",
				"disparo": "Quanto mais pontos em relacao ao custo da loja, maior o Lastro.",
				"habilidade": "Rompimento do Cofre",
				"desc_hab": "Ao comprar carta, suspende o peso, concede velocidade e escudo.",
				"traco": "Economia defensiva, timing de compra e explosao curta apos gastar.",
				"risco": "Guardar muito pesa a movimentacao; fragmentos de TP nao dao pontos."
			}
		"Oportunista":
			return {
				"funcao": "Procura Aberturas durante preparacao, recuperacao, stun ou janela de ataque inimiga.",
				"disparo": "Acertos diretos em Abertura carregam o proximo Golpe de Oportunidade.",
				"habilidade": "Golpe de Oportunidade",
				"desc_hab": "O proximo dano direto recebe bonus, atrasa o inimigo e recupera parte de Q ou E.",
				"traco": "Precisao, leitura de telegraph e punicao de ataques inimigos.",
				"risco": "Dano de cartas, areas persistentes e aliados nao carregam Aberturas."
			}
	return {
		"funcao": "Estado espectral em leitura.",
		"disparo": "Gatilho ainda instavel.",
		"habilidade": "Indefinida",
		"desc_hab": "A aurea ainda nao estabilizou.",
		"traco": "Espectro desconhecido.",
		"risco": "Instavel demais para combate."
	}


static func manifestation_details(host: Node, key: String) -> Dictionary:
	match key:
		"eletrica":
			return {
				"funcao": "Mais facil de entender e jogar. Boa para primeira partida, fase cheia e troca rapida de alvo.",
				"disparo": "ATK: tiro eletrico reto. A cada 4 tiros, sai uma Sobrecarga mais forte que explode em area pequena.",
				"habilidade": "Q - Onda Cinetica",
				"desc_hab": "Empurra inimigos proximos, causa dano em area e abre espaco quando a tela fecha.",
				"traco": "E - Bobina de Tesla: cria uma zona eletrica. Inimigos dentro do raio tomam choque a cada 0,4s e ficam levemente atordoados.",
				"risco": "E drena vida depois de 2 minutos. TP: vira eletricidade por 3s e causa 0,5% da vida maxima a cada 300ms nos alvos atravessados; so entao recarrega."
			}
		"lacerante":
			return {
				"funcao": "Cacadora de alto risco e recompensa. Eliminar qualquer inimigo incomum concede 50% mais pontos.",
				"disparo": "ATK: sequencia de 3 laminas espaciais. A cada 20 Coagulos, o alcance do corte aumenta +5px.",
				"habilidade": "Q - Circulo Lacerante",
				"desc_hab": "A lamina gira 5 voltas em 1,5s. Cada volta causa dano e cura 0,25% da vida perdida por alvo atingido. Ganha +1 volta a cada 10 Coagulos.",
				"traco": "REFORCO (3s): arma o proximo ATK. Se executar um alvo, gera +1 Coagulo. Cada Coagulo concede +0,30% dano e +0,25% velocidade de ataque.",
				"risco": "TP: possui 2 cargas. Apos a primeira, ha 800ms para usar a segunda. Ao atravessar ate 3 alvos, fica invulneravel e aplica 10 cortes em 3s; a recarga de 2s inicia depois dos cortes.",
				"info_rows": [
					{"label": "ATK", "text": "3 laminas com +15px base. +5px de alcance a cada 20 Coagulos. Corpos grandes recebem dano maior."},
					{"label": "Q", "text": "5 voltas em 1,5s, cada uma com dano e cura. +1 volta a cada 10 Coagulos."},
					{"label": "REFORCO", "text": "Recarga de 3s. Arma o proximo ATK; executar um alvo com ele gera +1 Coagulo."},
					{"label": "PASSIVAS", "text": "Incomuns valem +50% pontos. Cada Coagulo concede +0,30% dano e +0,25% velocidade de ataque."},
					{"label": "E / TP", "text": "TP tem 2 cargas e janela de 800ms. Carnificina e TP ganham +2 cortes a cada 20 Coagulos."}
				]
			}
		"prismatica":
			return {
				"funcao": "Tecnica de mira. Recompensa angulo, ricochete e preparo antes de apertar os botoes.",
				"disparo": "ATK: feixe rapido e fino. Ricocheteia em parede ou inimigo e pode acertar mais de uma vez.",
				"habilidade": "Q - Prisma de Refracao",
				"desc_hab": "Coloca um prisma na posicao da Geovana. Tiros que atravessam o prisma se dividem em 5 feixes.",
				"traco": "E - Coroa Espectral: Geovana fica invulneravel; linhas de luz giram e causam dano. Aperte E novamente para cancelar.",
				"risco": "TP: cria no destino um prisma maior, atravessavel por disparos. A recarga comeca quando o prisma termina."
			}
		"retornante":
			return {
				"funcao": "Dano atrasado. O tiro vai mais fraco e volta mais perigoso para perto da Geovana.",
				"disparo": "ATK: pulso que sai, atravessa o campo e depois retorna. A volta causa mais dano que a ida.",
				"habilidade": "Q - Memoria Instavel",
				"desc_hab": "Marca um pulso ativo para procurar alvos e voltar fortalecido. Se nao houver pulso, o proximo tiro recebe a memoria.",
				"traco": "E - Paradoxo de Retorno: prolonga os retornos ativos e cria linhas temporais que causam dano entre Geovana e os pulsos.",
				"risco": "TP: durante 850ms, toque novamente para voltar a origem. Usando ou nao o retorno, a recarga de 1,2s comeca depois da janela."
			}
		"parasitica":
			return {
				"funcao": "Infestacao com janela curta. Cada acerto mantem larvas visiveis no alvo por 6 segundos.",
				"disparo": "ATK: verme parasita reforcado. Causa dano e adiciona larvas; novos acertos renovam a marca de 6s.",
				"habilidade": "Q - Cuspe Infestante",
				"desc_hab": "Cospe um bolo de vermes na direcao da mira. O impacto cria uma area viva que causa dano e contamina inimigos dentro dela.",
				"traco": "E - Enxame Subterraneo: vermes entram pelas bordas, escavam ate cada alvo marcado e devoram por 8s, causando 5% da vida atual por segundo.",
				"risco": "TP: deixa 3 ovos na origem; os vermes perseguem e atordoam por 1,8s. Chefes usando habilidade resistem ao atordoamento."
			}
		"gravitante":
			return {
				"funcao": "Controle automatico. Ajuda quando a tela esta cheia porque parte do dano segue os alvos sozinho.",
				"disparo": "ATK: orbe gravitante. Ao acertar, cria uma orbita no alvo e causa pequenos ticks de dano.",
				"habilidade": "Q - Colisao Gravitacional",
				"desc_hab": "Colide todos os alvos marcados pelos ATKs, causa dano e empurra inimigos nao marcados que estiverem proximos.",
				"traco": "E - Nucleo Gravitante: prende e gira inimigos e chefes, causando dano crescente perto da borda antes do colapso.",
				"risco": "TP: a origem libera uma onda de 230px que empurra inimigos comuns e elites, mas nao move chefes."
			}
		"ancorada":
			return {
				"funcao": "Manifestacao de firmeza. Ficar parada por 3s inicia acumulo de critico: +2% a cada 3s ate +50%. Ao mover, o bonus some imediatamente.",
				"disparo": "ATK - Bala Ancorada: quanto mais tempo Geovana fica parada, mais pesado o disparo fica. O empurrao comeca em 5px e cresce +2px a cada 2s, ate 50px.",
				"habilidade": "Q - Modo Ancorado",
				"desc_hab": "Liga/desliga o estado ancorado. Enquanto ativo, Geovana fica travada no lugar, recebe mais armadura, toma menos dano, ganha +20% velocidade de ataque, +35% dano base e disparos 45% maiores.",
				"traco": "E - Queda das Ancoras: todos os inimigos em 380px recebem ancoras do ceu, sofrem 120% do dano atual e ficam enraizados por 3s. Funciona tambem em chefes.",
				"risco": "A forca vem de escolher quando parar. Se mover cedo demais, perde critico e peso; ao sair do Modo Ancorado, Q entra em recarga de 5s.",
				"info_rows": [
					{"label": "PASSIVA", "text": "3s parada inicia carga. +2% critico a cada 3s, maximo +50%. Critico acima de 100% vira dano critico extra."},
					{"label": "PESO", "text": "Disparo ganha empurrao enquanto parada: 5px base, +2px a cada 2s, maximo 50px."},
					{"label": "Q", "text": "Ativacao manual. Trava Geovana, aumenta defesa, cadencia, dano base e tamanho do disparo. Desativar inicia cooldown de 5s."},
					{"label": "E", "text": "Raio 380px. Ancoras caem do ceu, causam 120% do dano atual e enraizam por 3s, inclusive bosses."}
				]
			}
		"cartografica":
			return {
				"funcao": "Controle espacial sem roubar sua mira. Marca ate 3 coordenadas e transforma tiros que atravessam essas rotas em golpes mais fortes.",
				"disparo": "ATK - Agulha de Levantamento: sempre nasce na Geovana e segue sua mira. Ao expirar cria coordenada no chao; ao acertar alvo cria coordenada nele.",
				"habilidade": "Q - Dobra Cartografica",
				"desc_hab": "Fixa coordenada no alvo ou na direcao da mira e ativa rotas. Com 3 coordenadas abre Mapa Completo, ampliando o triangulo de controle.",
				"traco": "E - Mapa Rasgado: por alguns segundos dispara agulhas de leitura a partir da Geovana contra alvos importantes e reforca as rotas ja preparadas.",
				"risco": "TP: Passo Cartografico respeita o destino escolhido e deixa uma coordenada no ponto final. Tiros que cruzam 1/2/3 coordenadas ganham dano, perfuracao e explosao."
			}
		"mnesica":
			return {
				"funcao": "Punicao de padroes. Registra lembrancas de dor, ataque ou perseguicao e transforma a memoria do inimigo contra ele.",
				"disparo": "ATK - Estilhaco de Lembranca: dano baixo que grava ate 3 lembrancas no alvo. Com 3, ativa Deja-vu.",
				"habilidade": "Q - Revivencia",
				"desc_hab": "Detona lembrancas proximas. Dor repete dano, ataque atrasa e erra alvo, perseguicao forca trajetoria instavel.",
				"traco": "E - Arquivo Vivo: por alguns segundos, ataques proximos gravam memorias rapidamente para preparar uma punicao maior.",
				"risco": "TP: Apagao Mnemico faz inimigos mirarem a posicao antiga e o proximo golpe contra enganados causa mais dano. Chefes abrem janela curta de vulnerabilidade."
			}
		"ressonante":
			return {
				"funcao": "Manifestacao de timing. Um compasso visual de 4 batidas recompensa ataques no ritmo certo.",
				"disparo": "ATK - Nota Curta: fora do tempo causa dano normal; no tempo perfeito causa mais dano e aplica Grave, Aguda ou Quebrada.",
				"habilidade": "Q - Silencio Absoluto",
				"desc_hab": "Detona notas aplicadas, atrasa ataques inimigos e usa sua sequencia perfeita para aumentar o efeito.",
				"traco": "E - Crescendo: garante proxima Nota Perfeita, gera acordes ao redor e melhora o ritmo ofensivo por poucos segundos.",
				"risco": "TP: Contratempo. Se usado na janela perfeita, ganha invulnerabilidade maior, velocidade curta e proxima nota garantida."
			}
		"contratual":
			return {
				"funcao": "Regras e sentencas. Marca inimigos com clausulas e pune quem quebra agressao, aproximacao ou fuga. Letras: A = agressao, P = aproximacao, F = fuga.",
				"disparo": "ATK - Selo de Clausula: aplica regra conforme comportamento do alvo. O dano direto e baixo, mas prepara execucao e infracoes.",
				"habilidade": "Q - Execucao de Contrato",
				"desc_hab": "Executa contratos ativos. Mais infracoes aumentam dano, postura quebrada, stun curto e vulnerabilidade.",
				"traco": "E - Ordem Judicial: sorteia uma ordem de 15s, mostra o contrato no centro e depois fixa o progresso no canto. Cumprir concede uma bencao poderosa por 60s; falhar ativa Confisco por 2min.",
				"risco": "TP: Notificacao Judicial deixa uma armadilha na origem. Quebras de contrato reduzem um pouco a recarga da Ordem Judicial. Usar Q em muitos contratos sem infracao ainda ativa Multa de Ruptura."
			}
		"acorrentada":
			return {
				"funcao": "Controle e ruptura. Prende inimigos, acumula Tensao e transforma Elos em golpes pesados.",
				"disparo": "ATK - Ciclo dos Tres Elos: golpe 1 aplica Elo em linha, golpe 2 varre em arco e golpe 3 rompe os Elos com duas correntes cruzadas.",
				"habilidade": "Q - Prisao Geminada",
				"desc_hab": "Liga dois inimigos, prende um alvo ao chao ou contem boss sem puxar. Parte do dano direto em um alvo ligado passa para o outro.",
				"traco": "E - Sentenca dos Grilhoes: aperta alvos com Elo, ligados pelo Q ou dentro da area; dano cresce por Elo e consome as marcas.",
				"risco": "Tensao chega a 100 e fortalece o proximo Q ou E, depois volta para 35. TP deixa uma corrente que aplica Elo e pode avancar o combo.",
				"info_rows": [
					{"label": "ELOS", "text": "Cada alvo acumula ate 3 Elos por 6s. O terceiro ATK consome tudo para aumentar o dano."},
					{"label": "TENSAO", "text": "40+ aumenta alcance; 70+ aumenta dano/area; 100 fortalece o proximo Q ou E."},
					{"label": "Q", "text": "Dois alvos compartilham 18% do dano direto. Com Sobretensao prende ate 3 e sobe para 24%."},
					{"label": "E", "text": "Raio de 420px, preparo curto e dano por Elo. Em boss aplica Rachadura para reforcar o proximo golpe 3."},
					{"label": "TP", "text": "Troca de Elo deixa rastro de corrente por 1,2s, aplica 1 Elo por alvo e nao consome Sobretensao."}
				]
			}
		"eclipsada":
			var passive_timer := float(host.get("eclipsada_passive_timer"))
			var trait_timer := float(host.get("eclipsada_trait_timer"))
			var trait_status := "Passiva pronta para copiar um traco no proximo abate." if passive_timer <= 0.0 else "Passiva recarrega em %.0fs." % passive_timer
			if trait_timer > 0.0:
				trait_status = "Traco ativo: %s por %.0fs. Cor e comportamento das habilidades mudam enquanto durar." % [String(host.get("eclipsada_trait_name")), trait_timer]
			var form_status := "Forma atual: SOL. Shurikens explodem, HAB1 dispara rajada solar e ULT cria uma coroa de dano em area." if bool(host.call("_eclipsada_is_sol")) else "Forma atual: LUA. ATK usa duas laminas de 180px, HAB1 liga/desliga furtividade com drenagem progressiva e ULT cria um eclipse de cortes proximos."
			return {
				"funcao": "Duelista hibrida de curto alcance. O botao REFORCO alterna entre Lua e Sol a qualquer momento, mudando ATK, HAB1 e ULT.",
				"disparo": "ATK - Lua usa duas laminas proximas em tres direcoes, com o terceiro corte sempre critico. Sol usa shuriken de 280px; aos 285px a lamina perde forca e cai.",
				"habilidade": "Q - Lua Rasante / Estilhaco Solar",
				"desc_hab": "Lua: liga/desliga furtividade. Depois de 3s invisivel, perde vida a cada segundo e o custo aumenta a cada 3s. Sol: dispara 3 shurikens solares em leque com explosao no impacto.",
				"traco": "E - Eclipse Laminar / Coroa Solar: Lua cria um campo movel de cortes ao redor da Geovana; Sol cria uma zona pulsante de cortes no ponto mirado.",
				"risco": form_status + " " + trait_status,
				"info_rows": [
					{"label": "FORMA", "text": "REFORCO troca Lua/Sol sem recarga e cria um anel visual ao redor da Geovana."},
					{"label": "ATK LUA", "text": "Duas laminas de 180px. O combo corta esquerda, direita e centro; o terceiro hit sempre crita e escala com critico."},
					{"label": "ATK SOL", "text": "Shuriken curto mais forte, nao perfura, mas explode em raio pequeno no impacto."},
					{"label": "Q", "text": "Lua e uma ativacao: invisivel ate desligar, com cooldown de 10s apos revelar. Sol foca rajada direta e area curta."},
					{"label": "E", "text": "Lua invoca um eclipse que pulsa cortes em ate 3 alvos proximos; Sol coloca uma coroa pulsante ate 260px."},
					{"label": "PASSIVA", "text": "Lua ganha dano nas laminas enquanto segue oculta. Sol deixa queimadura curta nas explosoes. A cada 80s, um abate ainda copia traco inimigo por 60s."}
				]
			}
		"bombastica":
			return {
				"funcao": "Especialista em explosoes e reacao em cadeia. Fraca se atira sem preparar terreno, muito forte quando controla onde a luta acontece.",
				"disparo": "ATK - Estopim Instavel: tiro mais lento que aplica Polvora Instavel. Cada alvo segura ate 3 cargas por 5s.",
				"habilidade": "Q - Triade de Demolicao",
				"desc_hab": "Possui 3 cargas independentes. Cada Q planta ou arremessa uma bomba com fusivel entre 3s e 6s, raio de 105px e dano alto 25% maior. Bombas proximas podem acionar cadeia.",
				"traco": "E - Bomba-Cometario: solta uma bomba redonda que quica por 10s, desloca a 85px/s e explode em raio de 280px sempre que toca o chao.",
				"risco": "Aos 3 acumulos de Polvora, a proxima explosao consome as cargas e causa Ignicao. A Bomba-Cometario so colide perto do chao; tiros nesse momento aumentam seu dano e redirecionam o salto.",
				"info_rows": [
					{"label": "ATK", "text": "0,62x dano atual, 92% da velocidade padrao e cadencia de 0,58s. Serve para preparar Polvora, nao para ser a unica fonte de dano."},
					{"label": "POLVORA", "text": "Ate 3 cargas por alvo, 5s. Cada carga aumenta em 6% o dano explosivo Bombastica recebido."},
					{"label": "Q", "text": "3 cargas, cada uma recarrega em 7s. Bomba perto da Geovana e plantada; alvo distante vira arremesso."},
					{"label": "DETONADOR", "text": "Toque curto detona uma bomba. Segurar por 0,62s aciona Detonacao Total com penalidade de controle."},
					{"label": "E", "text": "Bola explosiva por 10s, raio de explosao de 280px e movimento de 85px/s. Sem colisao no alto; vulneravel a tiros perto do chao."}
				]
			}
		"necronada":
			return {
				"funcao": "Manifestacao de Reconstrucao Mortuaria e jardim funerario. A cada 4 ataques, Geovana cura uma pequena porcentagem da vida maxima; mortes deixam rosas azuis no chao quando ainda ha espaco para invocar.",
				"disparo": "ATK - Epitafio Curto: projetil violeta/cian que marca Epitafio ate 5 camadas por 8s. O inimigo mostra E xN acima da cabeca e arcos concentricos indicam a profundidade.",
				"habilidade": "Q - Levante do Ossuario",
				"desc_hab": "Invoca todos os vestigios em forma de rosa dentro de 350px. Cada rosa vira um necro-aliado inspirado na especie morta, com limite de 7 aliados ativos.",
				"traco": "REFORCO - Poeira Funeraria: arma o proximo ataque por 3s. Ele vira uma poeira inclinada ate 300px, causa dano leve, marca o alvo e faz necro-aliados focarem nele com mais dano e velocidade por 3s.",
				"risco": "E - Onda Necrotica: carrega a cada 30 inimigos revividos e tem cooldown de 10s. A poeira percorre 420px, causa 120% perto da origem e cai ate 60% longe, aplicando slow e janela de critico.",
				"info_rows": [
					{"label": "ROSAS", "text": "Maximo de 7 no mapa. Se nao houver espaco para novo aliado, uma morte nao cria rosa. As rosas nao sao coletaveis; HAB1 usa o raio."},
					{"label": "ALIADOS", "text": "Necro-aliados usam movimento e habilidade inspirados no inimigo original, mas com dano, vida e duracao balanceados."},
					{"label": "BOSS", "text": "Em boss fight, reforcar um alvo e acertar 4 ataques nele cria uma rosa se ainda houver espaco para invocar."},
					{"label": "TP", "text": "Ao teleportar, solta poeira em leque na frente da Geovana, causando dano e empurrando inimigos."},
					{"label": "E", "text": "Onda Necrotica nasce em Geovana, dissipa ao bater em alvos e perde dano com distancia. Alvos marcados recebem chance de critico."}
				]
			}
	return {
		"funcao": "Forma em leitura.",
		"disparo": "Sinal incompleto.",
		"habilidade": "Indefinida",
		"desc_hab": "Eco ainda nao dominado.",
		"traco": "Aguardando dominio.",
		"risco": "Instavel demais para combate."
	}

