# -*- coding: utf-8 -*-

AUREAS_DADOS = [
    {
        "id": "Racional",
        "nome": "RACIONAL",
        "categoria": "Analise e Precisao Temporal",
        "descricao": "Utilidade: controle de ritmo e reposicionamento seguro. Ficar totalmente imovel por 5s gera pontos bonus (+3 + nivel). Ao usar Teleporte com a recarga pronta, ativa Dilatacao Temporal por 8s: inimigos e projeteis ficam 58% mais lentos, Geovana ganha +35% de movimento e atira 28% mais rapido. Quando acaba, vem o Rebote por 3s: inimigos/projeteis aceleram 50%.",
        "resumo": "Controle de ritmo: ficar imovel gera pontos; Teleporte pronto desacelera inimigos/projeteis e acelera Geovana por 8s. Depois ha Rebote: inimigos aceleram por 3s.",
        "lore": "\"A mente fria nao preve o futuro. Ela obriga o futuro a se revelar.\"",
        "imagem_path": "Sprites/aurea_cientista.png",
        "cor": (0, 180, 255),
        "estilo": "racional",
        "beneficios": {
            0: "Nenhum efeito ativo.",
            1: "Parado 5s: +4 pontos. Teleporte ativa 8s de lentidao global; ao desfazer, inimigos +50% por 3s.",
            2: "Parado 5s: +5 pontos. Teleporte ativa 8s de lentidao global; ao desfazer, inimigos +50% por 3s.",
            3: "Parado 5s: +6 pontos. Teleporte ativa 8s de lentidao global; ao desfazer, inimigos +50% por 3s.",
            4: "Parado 5s: +7 pontos. Teleporte ativa 8s de lentidao global; ao desfazer, inimigos +50% por 3s.",
            5: "Parado 5s: +8 pontos. Teleporte ativa 8s de lentidao global; ao desfazer, inimigos +50% por 3s."
        },
        "destaques": [
            "- Fique parado 5s para ganhar pontuacao bonus.",
            "- Teleporte pronto: 8s de mundo lento e Geovana mais rapida.",
            "- Custo: depois da Dilatacao, inimigos aceleram por 3s."
        ]
    },
    {
        "id": "Impulsiva",
        "nome": "IMPULSIVA",
        "categoria": "Agressividade e Velocidade",
        "descricao": "Utilidade: agressao continua e limpeza rapida de grupos. A cada 5 abates sem sofrer dano, ativa um Frenesi temporario ligado a dano e/ou velocidade. Nas fases com sistema completo, renovar com tempo sobrando aumenta o nivel do Frenesi e os multiplicadores; se Geovana levar hit durante o Frenesi, ele quebra e arma Panico, fazendo o proximo dano recebido escalar pelo nivel alcancado.",
        "resumo": "Agressao continua: 5 abates sem dano ativam Frenesi de dano/velocidade. Manter sequencia renova o efeito; sofrer hit quebra a pressao.",
        "lore": "\"A hesitacao e uma fresta pela qual o tempo escorre. Nao pense, aja.\"",
        "imagem_path": "Sprites/aurea_impulsiva.png",
        "cor": (255, 60, 60),
        "estilo": "impulsiva",
        "beneficios": {
            0: "Nenhum efeito ativo.",
            1: "Frenesi dura 3.5s. A cada ciclo de 5 abates: renova; com 1s sobrando: sobe nivel. Hit sofrido quebra e arma Panico.",
            2: "Frenesi dura 4.0s. A cada ciclo de 5 abates: renova; com 1s sobrando: sobe nivel. Hit sofrido quebra e arma Panico.",
            3: "Frenesi dura 4.5s. A cada ciclo de 5 abates: renova; com 1s sobrando: sobe nivel. Hit sofrido quebra e arma Panico.",
            4: "Frenesi dura 5.0s. A cada ciclo de 5 abates: renova; com 1s sobrando: sobe nivel. Hit sofrido quebra e arma Panico.",
            5: "Frenesi dura 5.5s. A cada ciclo de 5 abates: renova; com 1s sobrando: sobe nivel. Hit sofrido quebra e arma Panico."
        },
        "destaques": [
            "- 5 abates sem dano ativam Frenesi.",
            "- Frenesi melhora dano/velocidade e favorece jogo agressivo.",
            "- Custo: sofrer hit quebra a sequencia; no sistema completo arma Panico."
        ]
    },
    {
        "id": "Devota",
        "nome": "DEVOTA",
        "categoria": "Protecao e Sobrevivencia",
        "descricao": "Utilidade: transformar erro em contra-ataque. A aura cria 3 cargas de escudo que anulam impactos. Cada bloqueio cura 10% da vida perdida e concede +25% dano por 3s. Ao quebrar a ultima carga, Geovana recebe Fe Ardente: +65% dano por 4.5s, com apenas -10% velocidade. Upgrade reduz a recarga.",
        "resumo": "Sobrevivencia ofensiva: 3 cargas anulam hits, curam parte da vida perdida e viram janela de dano.",
        "lore": "\"O tempo e a melhor armadura. Ele consome tudo, exceto a fe.\"",
        "imagem_path": "Sprites/aurea_devota.png",
        "cor": (255, 200, 0),
        "estilo": "devota",
        "beneficios": {
            0: "Nenhum efeito ativo.",
            1: "3 cargas anulam hits. Bloqueio cura 10% da vida perdida e da +25% dano por 3s. Recarga: 19.5s.",
            2: "3 cargas anulam hits. Fe Ardente na ultima quebra: +65% dano por 4.5s e so -10% velocidade. Recarga: 17s.",
            3: "3 cargas anulam hits. Bloqueios viram cura e janela de contra-ataque. Recarga: 14.5s.",
            4: "3 cargas anulam hits. Mais uptime defensivo para lutas longas. Recarga: 12s.",
            5: "3 cargas anulam hits. Devota sustenta erro, cura e resposta agressiva. Recarga: 9.5s."
        },
        "destaques": [
            "- 3 cargas de escudo anulam impactos.",
            "- Cada bloqueio cura parte da vida perdida e aumenta o dano por poucos segundos.",
            "- Quando a ultima carga quebra, Fe Ardente entrega um pico de dano com lentidao leve."
        ]
    },
    {
        "id": "Vanguarda",
        "nome": "VANGUARDA",
        "categoria": "Dominio de Area e Incendio",
        "descricao": "Utilidade: transformar proximidade perigosa em dano de area. Inimigos tocados ou proximos podem ficar em chamas e sofrem dano por segundo baseado em vida maxima. Nas fases com sistema completo, sofrer hit ativa um circulo de fogo por 5s que incendeia alvos ao redor. Upgrade aumenta a duracao da queimadura; cada inimigo queimando aumenta o cooldown do Teleporte em 15%.",
        "resumo": "Area e queimadura: inimigos proximos/tocados podem pegar fogo e tomar dano continuo. Upgrade aumenta a duracao; queimando aumenta cooldown do Teleporte.",
        "lore": "\"A marcha do progresso nao pode ser contida por meros segundos.\"",
        "imagem_path": "Sprites/aurea_vanguarda.png",
        "cor": (230, 0, 230),
        "estilo": "vanguarda",
        "beneficios": {
            0: "Nenhum efeito ativo.",
            1: "Hit recebido desenha fogo por 5s. Queimadura dura 6s. Cada inimigo queimando: Teleporte +15%.",
            2: "Hit recebido desenha fogo por 5s. Queimadura dura 7s. Cada inimigo queimando: Teleporte +15%.",
            3: "Hit recebido desenha fogo por 5s. Queimadura dura 8s. Cada inimigo queimando: Teleporte +15%.",
            4: "Hit recebido desenha fogo por 5s. Queimadura dura 9s. Cada inimigo queimando: Teleporte +15%.",
            5: "Hit recebido desenha fogo por 5s. Queimadura dura 10s. Cada inimigo queimando: Teleporte +15%."
        },
        "destaques": [
            "- Inimigos proximos/tocados podem queimar.",
            "- Queimadura causa dano por segundo e dura mais com upgrade.",
            "- Custo: cada inimigo queimando aumenta o cooldown do Teleporte em 15%."
        ]
    },
    {
        "id": "Insana",
        "nome": "INSANA",
        "categoria": "Insanidade Temporal e Ecos",
        "descricao": "Utilidade: duplicar pressao ofensiva e desviar pressao inimiga em janelas curtas. A cada 20s, a aura fica pronta; quando Geovana atira, ecos temporais parados surgem no lugar dela, atraem a prioridade dos inimigos e repetem tiros com 1s de atraso. Cada ativacao comeca com 4 ecos, podendo chegar a 5 se um eco finalizar um inimigo. Os disparos dos ecos causam dano reduzido e usam energia verde no centro com raios roxos. Depois que o ultimo eco e gasto, Geovana sofre desorientacao temporal: o Teleporte recebe 2s extras de recarga.",
        "resumo": "Cria ecos temporais parados que atraem inimigos e repetem seus tiros com atraso. Se um eco matar, a proxima ativacao ganha +1 eco. Depois vem desorientacao: Teleporte recarrega mais lento por 2s.",
        "lore": "\"Nem toda Geovana que atira ainda esta viva no mesmo segundo.\"",
        "imagem_path": "Sprites/aurea_insana.png",
        "cor": (160, 55, 255),
        "estilo": "insana",
        "beneficios": {
            0: "Nenhum efeito ativo.",
            1: "4 ecos por ativacao. Tiros dos ecos causam 17% do dano. Cooldown 19s apos o ultimo eco.",
            2: "4 ecos por ativacao. Tiros dos ecos causam 22% do dano. Cooldown 18s apos o ultimo eco.",
            3: "4 ecos por ativacao. Tiros dos ecos causam 27% do dano. Cooldown 17s apos o ultimo eco.",
            4: "4 ecos por ativacao. Tiros dos ecos causam 32% do dano. Cooldown 16s apos o ultimo eco.",
            5: "4 ecos por ativacao. Tiros dos ecos causam 37% do dano. Cooldown 15s apos o ultimo eco."
        },
        "destaques": [
            "- A cada 20s, seus tiros criam ecos parados.",
            "- Inimigos priorizam os ecos enquanto eles existem.",
            "- Ecos repetem tiros com 1s de atraso e dano reduzido.",
            "- Se um eco finalizar inimigo, a proxima ativacao tem 5 ecos.",
            "- Custo: depois do ultimo eco, Teleporte recebe +2s de recarga."
        ]
    },
    {
        "id": "Voraz",
        "nome": "VORAZ",
        "categoria": "Fome, Consumo e Risco",
        "descricao": "Utilidade: agressao sustentada por coleta ativa. Inimigos derrotados deixam coagulos de sangue por 3 segundos; coletar esse coagulo enche a barra Fome e cura 0.8% da vida perdida, aumentando 1.2% por ciclo de Fome ate 6.8%. Ao completar a barra, ela sobe para X1, X2 e assim por diante: cada ciclo exige bem mais Fome, a barra cai mais rapido e a parte alta da barra e mais dificil de manter. Com Fome sustentada, os tiros ficam maiores, causam um bonus leve de dano e habilidades recarregam ate 12% mais rapido. Inimigos bem proximos sao puxados com pouca forca e contato causa mordidas a cada 1.3s: cada mordida causa 10% do dano do auto attack, +2.5% por ciclo de Fome, e usa a mesma cura por Fome. Se ficar mais de 30s sem coletar coagulos, a aura cobra 1% da vida a cada 1.5s.",
        "resumo": "Coleta agressiva: coagulos de sangue enchem Fome e curam 0.8% da vida perdida +1.2% por ciclo, ate 6.8%. Mordidas causam 10% do auto attack +2.5% por ciclo de Fome. Sem coleta por 30s, drena vida.",
        "lore": "\"Nesta realidade, Geovana provou o gosto das rupturas. Ela se alimenta dos inimigos para se fortalecer, mas sua fome e insaciavel: quanto mais devora, mais poder ela sente e quer.\"",
        "imagem_path": "Sprites/aurea_voraz.png",
        "cor": (255, 112, 24),
        "estilo": "voraz",
        "beneficios": {
            0: "Nenhum efeito ativo.",
            1: "Coagulos de sangue alimentam Fome e curam 0.8% da vida perdida, +1.2% por ciclo de Fome, ate 6.8%. Mordidas causam 10% do auto attack +2.5% por ciclo.",
            2: "Fome sustentada aumenta levemente dano dos tiros, tamanho dos tiros e velocidade de recarga. A barra escala ao completar ciclos XN.",
            3: "Puxao e mordidas ajudam no corpo a corpo, mas o dano da mordida segue 10% do auto attack +2.5% por ciclo de Fome.",
            4: "Tiros crescem com Fome sustentada e a pressao ofensiva dura melhor se voce continuar coletando coagulos.",
            5: "Maior recompensa agressiva, mas ciclos altos decaem rapido, exigem coleta constante e mantem o mesmo calculo claro de mordida."
        },
        "destaques": [
            "- Abates deixam coagulos de sangue flutuantes por 3 segundos.",
            "- Coletar coagulos enche Fome e cura 0.8% da vida perdida, +1.2% por ciclo de Fome, ate 6.8%.",
            "- Barra completada sobe para proximo ciclo. Ciclos altos pedem mais Fome e decaem muito mais rapido.",
            "- Inimigos sao puxados levemente e sofrem mordidas a cada 1.3s.",
            "- Custo: 30s sem coletar coagulos drena 1% de vida a cada 1.5s."
        ]
    },
    {
        "id": "Nula",
        "nome": "NULA",
        "categoria": "Vazio, Cancelamento e Ruptura",
        "descricao": "Utilidade: preparar um disparo de anulacao. Enquanto a aura esta ativa, a barra Vazio enche com o tempo, mais rapido quando ha poucos inimigos vivos. Ao completar 100%, o proximo auto attack fica Nulo: causa dano bonus moderado e deixa o alvo nulificado por alguns segundos. Alvos nulificados ficam mais vulneraveis a dano, mas a barra zera apos o tiro.",
        "resumo": "Carrega Vazio com o tempo. Com 100%, o proximo auto attack nulifica o alvo, causando dano bonus e abrindo uma janela curta de vulnerabilidade.",
        "lore": "\"Onde o tempo falha, o vazio aprende a responder.\"",
        "imagem_path": "Sprites/aurea_nula.png",
        "cor": (220, 240, 255),
        "estilo": "nula",
        "beneficios": {
            0: "Nenhum efeito ativo.",
            1: "Vazio carrega com o tempo. Com 100%, o proximo tiro nulifica e causa +15.8% de dano.",
            2: "Vazio carrega um pouco mais rapido. Nulificar dura mais e causa +17.6% de dano.",
            3: "Melhor ritmo de carga e janela de nulificacao. Tiro Nulo causa +19.4% de dano.",
            4: "Vazio fica mais confiavel em lutas com poucos alvos. Tiro Nulo causa +21.2% de dano.",
            5: "Anulacao mais frequente e precisa. Tiro Nulo causa +23% de dano."
        },
        "destaques": [
            "- Barra Vazio carrega automaticamente.",
            "- Com 100%, o proximo auto attack vira Tiro Nulo.",
            "- Tiro Nulo causa dano bonus e deixa o alvo vulneravel por poucos segundos."
        ]
    },
    {
        "id": "Abissal",
        "nome": "ABISSAL",
        "categoria": "Pressao de Area e Colapso",
        "descricao": "Utilidade: controlar grupos sem explodir o dano do jogador. Inimigos perto de Geovana ficam expostos ao Abismo, sofrem erosao leve e recebem dano bonus pequeno dos tiros. A barra Colapso enche conforme a pressao de inimigos na tela; ao completar, causa um pulso de dano em alvos proximos.",
        "resumo": "Inimigos proximos sofrem erosao leve e ficam expostos. A pressao enche Colapso; com 100%, um pulso atinge alvos ao redor.",
        "lore": "\"O abismo nao corre. Ele espera tudo cair.\"",
        "imagem_path": "Sprites/aurea_abissal.png",
        "cor": (60, 160, 255),
        "estilo": "abissal",
        "beneficios": {
            0: "Nenhum efeito ativo.",
            1: "Alvos proximos ficam expostos e tomam erosao leve. Colapso causa 21.5% do auto attack.",
            2: "Raio maior e exposicao mais estavel. Colapso causa 25% do auto attack.",
            3: "Mais alcance de pressao. Colapso causa 28.5% do auto attack.",
            4: "Controle de grupo melhor em ondas densas. Colapso causa 32% do auto attack.",
            5: "Pressao abissal mais constante. Colapso causa 35.5% do auto attack."
        },
        "destaques": [
            "- Pressiona inimigos proximos com erosao leve.",
            "- Inimigos expostos recebem um pequeno bonus de dano dos tiros.",
            "- Colapso enche com inimigos na tela e pulsa em area quando completa."
        ]
    },
    {
        "id": "Profetica",
        "nome": "PROFETICA",
        "categoria": "Pressagio e Alvo Marcado",
        "descricao": "Utilidade: escolher uma vitima prioritaria sem automatizar a luta. A cada poucos segundos, a aura marca um inimigo proximo com Pressagio. Acertar esse alvo consome a marca, aplica dano bonus e antecipa o proximo Pressagio. Contra chefes, o Pressagio vira uma janela periodica de dano bonus no auto attack.",
        "resumo": "Marca periodicamente um inimigo proximo. Acertar o Pressagio consome a marca, causa dano bonus e acelera a proxima marca.",
        "lore": "\"Prever nao e saber o fim. E escolher onde o golpe deve cair.\"",
        "imagem_path": "Sprites/aurea_profetica.png",
        "cor": (255, 220, 80),
        "estilo": "profetica",
        "beneficios": {
            0: "Nenhum efeito ativo.",
            1: "Pressagio em alvo proximo. Acertar a marca causa +20.8% de dano.",
            2: "Marca dura um pouco mais. Acertar a marca causa +23.6% de dano.",
            3: "Pressagio volta mais rapido apos acerto. Marca causa +26.4% de dano.",
            4: "Janela de marcacao mais confortavel. Marca causa +29.2% de dano.",
            5: "Melhor ritmo de alvos marcados. Marca causa +32% de dano."
        },
        "destaques": [
            "- Marca periodicamente um inimigo proximo.",
            "- Acertar o alvo marcado consome Pressagio e causa dano bonus.",
            "- Em chefes, a aura gera janelas periodicas de dano bonus."
        ]
    },
    {
        "id": "Sanguinaria",
        "nome": "SANGUINARIA",
        "categoria": "Feridas, Sede e Carnificina",
        "descricao": "Utilidade: recompensar foco de alvo e agressao continua. Acertar o mesmo inimigo repetidas vezes abre uma Ferida. Alvos feridos recebem dano bonus moderado e alimentam a barra Sede. Ao completar Sede, ativa Carnificina por poucos segundos, aumentando o dano contra alvos feridos. A barra decai quando o jogador para de bater.",
        "resumo": "Hits repetidos abrem Ferida. Alvos feridos alimentam Sede; com 100%, Carnificina aumenta dano contra feridos por poucos segundos.",
        "lore": "\"Algumas rupturas nao cicatrizam. Elas chamam o proximo golpe.\"",
        "imagem_path": "Sprites/aurea_sanguinaria.png",
        "cor": (255, 70, 95),
        "estilo": "sanguinaria",
        "beneficios": {
            0: "Nenhum efeito ativo.",
            1: "Dois hits no mesmo alvo abrem Ferida. Feridos recebem +8.8% de dano.",
            2: "Ferida dura mais e Sede sobe melhor. Feridos recebem +10.6% de dano.",
            3: "Carnificina dura mais. Feridos recebem +12.4% de dano.",
            4: "Sede decai mais lentamente. Feridos recebem +14.2% de dano.",
            5: "Pressao sustentada mais forte. Feridos recebem +16% de dano; Carnificina amplia a janela."
        },
        "destaques": [
            "- Hits repetidos no mesmo alvo abrem Ferida.",
            "- Feridas alimentam Sede e aumentam o dano recebido.",
            "- Com Sede cheia, Carnificina melhora dano contra feridos por poucos segundos."
        ]
    }
]
