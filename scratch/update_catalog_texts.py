import json
import sys

json_path = 'docs/catalogo_temporal_textos.json'

with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Dictionary of updates by entry id
updates = {
    "ruptura": {
        "nome": "Ruptura",
        "subtitulo": "Cicatriz temporal e colapso espacial",
        "classificacao": "Fenomeno e cicatriz dimensional",
        "resumo": "O acidente dimensional gerado pela explosão do dispositivo temporal, deixando uma cicatriz entre universos por onde suas peças foram arremessadas.",
        "descricao_detalhada": "A Ruptura foi o acidente provocado pela explosão do dispositivo temporal. A violenta descarga espacial rasgou o tecido entre as dimensões, quase destruindo a realidade original de Geovana e espalhando os componentes do aparelho por múltiplos universos preexistentes.",
        "lore": "A Ruptura não criou as dimensões nem as criaturas que habitam cada mundo — esses universos já existiam de forma independente. A energia viva do dispositivo rasgou o espaço-tempo e deixou um rastro dimensional pontilhado entre os locais por onde suas peças passaram. A jornada de Geovana consiste em seguir esse rastro, encontrar a peça presente em cada universo, recuperá-la e atravessar para a próxima dimensão até reconstituir o aparelho.",
        "mecanicas": "Conecta as diferentes dimensões da travessia e dita o rastro energético que Geovana deve seguir. Em cada universo, a presença de um componente do dispositivo altera a estabilidade local e atrai a fauna nativa, exigindo que Geovana recupere a peça para abrir passagem ao próximo limiar.",
        "nota_de_campo": "Nota de Geovana: A Ruptura não inventou nenhum desses monstros nem o frio congelante da Fase 2. Ela só quebrou a parede do meu mundo e me jogou no território deles. O dispositivo se despedaçou e a energia dele deixou uma trilha viva. Cada peça é um degrau de volta para casa. Eu só preciso sobreviver a cada mundo até pegar todas."
    },
    "comum": {
        "nome": "Errante",
        "nome_curto": "Errante",
        "subtitulo": "Habitante telúrico das Ruínas Cósmicas",
        "classificacao": "Organismo orgânico-mineral",
        "resumo": "Organismo base das Ruínas Cósmicas formado por matéria orgânica, terra e energia cósmica. Representa a base do ecossistema local.",
        "descricao_detalhada": "Organismo telúrico nativo das Ruínas Cósmicas, formado pela agregação de matéria orgânica vegetal, sedimentos minerais e traços de energia cósmica ambiental. É a fauna mais abundante e a base alimentar daquele ecossistema.",
        "lore": "Muito antes da chegada do rastro do dispositivo temporal, os Errantes vagavam pelos leitos minerais das Ruínas Cósmicas em ciclos lentos de nutrição, absorvendo radiação cósmica passiva do solo. São criaturas territoriais simples que respondem a vibrações no chão. A chegada de uma estranha como Geovana ativa seus instintos defensivos de manada.",
        "mecanicas": "Avança em contato corpo a corpo, ocupando espaço e pressionando o posicionamento na arena. Atua em grupo para fechar rotas de fuga do jogador.",
        "nota_de_campo": "Nota de Geovana: Eles pertencem a este solo. Quando piso na terra solta das Ruínas, sinto a vibração sob as botas. Não são abominações criadas pelo meu acidente; são apenas os habitantes nativos defendendo o chão que pisam."
    },
    "espreitador": {
        "nome": "Espreitador",
        "nome_curto": "Espreitador",
        "subtitulo": "Predador subterrâneo de emboscada",
        "classificacao": "Ramificação evolutiva dos Errantes",
        "resumo": "Ramificação evolutiva da linhagem dos Errantes. Abandonou as pernas para rastejar, camuflar-se na terra e desferir botes rápidos.",
        "descricao_detalhada": "Predador subterrâneo da mesma linhagem biológica dos Errantes. Sua anatomia evoluiu ao longo de eras para abandonar as pernas vestigiais em favor de dois braços musculosos e placas minerais de camuflagem.",
        "lore": "Ao longo de gerações nas Ruínas Cósmicas, uma ramificação da linhagem dos Errantes especializou-se na caça de emboscada. Em vez de vagar em bando, o Espreitador desenvolveu a capacidade de desmanchar sua forma na terra solta e rastejar silenciosamente, usando seus braços frontais para tracionar o corpo contra o solo antes de disparar em um bote letal.",
        "mecanicas": "Persegue a presa rastejando e se camuflando no solo. Aproxima-se lentamente até encurtar a distância e desferir um bote rápido, pressionando os flancos da arena.",
        "nota_de_campo": "Nota de Geovana: Ele não mudou ontem por causa da fenda. Os sulcos na terra mostram que essa espécie caça assim há séculos. A diferença é que agora a presa sou eu. Se eu ficar parada olhando para a frente, o bote vem pelas costas."
    },
    "projetador": {
        "nome": "Projetador",
        "nome_curto": "Projetador",
        "subtitulo": "Atirador estático de longo alcance",
        "classificacao": "Organismo de compressão mineral",
        "resumo": "Espécie das Ruínas Cósmicas adaptada para ataques a distância com projéteis minerais expelidos em alta pressão.",
        "descricao_detalhada": "Organismo estático das Ruínas Cósmicas adaptado para ataque à distância através do disparo de nódulos minerais expelidos por compressão orgânica.",
        "lore": "Vivendo nas cristas rochosas e encostas das Ruínas Cósmicas, o Projetador desenvolveu glândulas internas de alta pressão que cristalizam sedimentos de sílica e minerais cósmicos em seus pulmões secundários. Quando ameaçado ou ao detectar presas, ele expele esses projéteis calcificados com extrema precisão, atuando como um elemento de controle no ecossistema local.",
        "mecanicas": "Mantém distância da presa e dispara projéteis calcificados de longo alcance com grande precisão. Permanece fixo enquanto ataca, mas altera seu padrão de esquiva se a presa encurta o espaço.",
        "nota_de_campo": "Nota de Geovana: Os projéteis deles são fragmentos de quartzo cósmico compactado pela própria biologia do bicho. Dói como um tiro de fuzil. Eles não gostam de combate próximo; quando me aproximo, entram em pânico."
    },
    "aglomerador": {
        "nome": "Aglomerador",
        "nome_curto": "Aglomerador",
        "subtitulo": "Organismo coletivo fundido",
        "classificacao": "Superorganismo de fusão telúrica",
        "resumo": "Surge quando múltiplos Errantes são comprimidos juntos por tempo suficiente, fundindo tecidos para aumentar as chances de sobrevivência.",
        "descricao_detalhada": "Organismo coletivo maciço formado pela fusão biológica de múltiplos Errantes compactados por pressão mecânica ambiental.",
        "lore": "Nas Ruínas Cósmicas, a fusão de Errantes é um mecanismo biológico natural de preservação contra grandes predadores e tempestades de poeira cósmica. Quando um bando de Errantes fica sob extrema pressão ou confinamento, suas membranas orgânicas e minerais se entrelaçam, fundindo seus tecidos em um único superorganismo coletivo com consciência compartilhada e carapaça fortalecida.",
        "mecanicas": "Funciona como ancoragem pesada na arena, possuindo alta resistência a impactos. Ao cair em combate, sua estrutura se desfaz, liberando os organismos individuais que o compunham.",
        "nota_de_campo": "Nota de Geovana: A fusão não é um feitiço nem uma mutação da fenda; é a biologia deles dizendo que dez corpos juntos sobrevivem onde um sozinho morreria. Derrubar essa massa significa ter que lidar com o que sobrou dentro dela."
    },
    "cristalizado": {
        "nome": "Cristalizador",
        "nome_curto": "Cristalizador",
        "subtitulo": "Organismo de couraça mineralizada",
        "classificacao": "Organismo orgânico-cristalino",
        "resumo": "Variante da fauna das Ruínas Cósmicas cuja derme incorporou alta concentração de minerais, formando uma armadura de cristais.",
        "descricao_detalhada": "Variante mineralizada dos organismos das Ruínas Cósmicas, cuja derme absorveu altas concentrações de geodos de quartzo e ferro mineral.",
        "lore": "Em regiões das Ruínas Cósmicas onde os depósitos de minerais pesados e geodos são densos, a fauna local desenvolveu uma simbiose profunda com o substrato. O Cristalizador metaboliza a sílica do solo ao longo de sua vida, expelindo-a para a epiderme até formar uma armadura rígida de cristais facetados que protege seus órgãos vitais contra ataques e deslizamentos de terra.",
        "mecanicas": "Atua como barreira pesada de alta resistência mecânica, absorvendo impactos e bloqueando rotas de movimentação do jogador.",
        "nota_de_campo": "Nota de Geovana: A pele desse bicho parece uma parede de ametista bruta. Meus disparos normais ricocheteiam na carapaça cristalina. Tive que aprender a contornar o ângulo blindado dele para achar a carne por baixo."
    },
    "curater": {
        "nome": "Curater",
        "nome_curto": "Curater",
        "subtitulo": "Hospedeiro simbiótico de esporos curativos",
        "classificacao": "Organismo fúngico-simbiótico",
        "resumo": "Organismo em simbiose com fungos regenerativos que cura seus aliados, mas é incapaz de usar a capacidade em si mesmo.",
        "descricao_detalhada": "Organismo simbiótico que carrega colônias de fungos bioluminosos com alta capacidade de regeneração tecidual, atuando como restaurador da fauna local.",
        "lore": "O Curater evoluiu em simbiose com os esporos curativos dos fungos das cavernas profundas das Ruínas Cósmicas. Ele metaboliza a seiva desse micélio e a projeta sobre outros organismos feridos, selando rasgos e tecidos em segundos. No entanto, o metabólito do fungo requer um hospedeiro receptor compatível, tornando o próprio Curater imune à sua regeneração, incapaz de curar a si próprio.",
        "mecanicas": "Em combate, canaliza jatos de esporos regenerativos para restaurar a saúde de inimigos aliados próximos. Sua estrutura física é frágil e ele depende da proteção da manada.",
        "nota_de_campo": "Nota de Geovana: É o médico da espécie. Ele espalha esporos que fecham as feridas dos outros instantaneamente, mas a biologia dele não aceita a própria seiva. Ele consegue ajudar todos ao seu redor, menos a si mesmo."
    },
    "larapio": {
        "nome": "Larápio",
        "nome_curto": "Larápio",
        "subtitulo": "Coletor inteligente e manipulador espacial",
        "classificacao": "Humanoide bípede catador",
        "resumo": "Espécie inteligente e oportunista com obsessão por objetos valiosos e a capacidade biológica de abrir micro-portais de fuga.",
        "descricao_detalhada": "Humanoide bípede altamente inteligente e oportunista nativo das Ruínas Cósmicas, caracterizado por sua cultura de coleta e habilidade biológica de manipulação micro-focal de dobras espaciais.",
        "lore": "Diferente dos organismos baseados em matéria telúrica simples, os Larápios pertencem a uma espécie ancestral de catadores bípedes. Sua sociedade se desenvolveu ao redor da acumulação de minérios raros e relíquias reluzentes das Ruínas. Sua anatomia possui órgãos de ressonância vestigiais que lhes permitem dobrar o espaço em uma escala microscópica, criando pequenas fendas temporárias para escapar com seus saques quando acuados por predadores.",
        "mecanicas": "Arremessa pedras compactas para atordoar a presa, aproxima-se para roubar recursos e abre um micro-portal sob os próprios pés para fugir, arremessando moedas e fragmentos para trás para desorientar quem o persegue.",
        "nota_de_campo": "Nota de Geovana: Ele não é um humano fantasiado de ladrão; é um bicho incrivelmente esperto que venera objetos brilhantes. A capacidade dele de rasgar o espaço por alguns segundos é natural da espécie. Se ele me atordoar e levar meu estoque, preciso agir rápido antes que o portal sob os pés dele se feche."
    },
    "rebobinador": {
        "nome": "Rebobinador",
        "nome_curto": "Rebobinador",
        "subtitulo": "Catalisador de reinjeção energética",
        "classificacao": "Entidade de plasma cósmico",
        "resumo": "Organismo composto por 80% de energia cósmica que re-injeta carga em corpos derrotados, reanimando-os mais fracos porém mais rápidos.",
        "descricao_detalhada": "Entidade energética das Ruínas Cósmicas composta por 80% de energia cósmica purificada e 20% de casca mineral.",
        "lore": "Formado em jazidas saturadas de radiação cósmica nas profundezas do planeta, o Rebobinador é um catalisador ambulante de carga energética. Ele não viaja no tempo; sua biologia consegue absorver, armazenar e re-injetar surtos violentos de energia cósmica em corpos orgânicos recém-colapsados ao seu redor, reativando seus tecidos celulares de forma instável. Os corpos reanimados voltam com menor massa biológica, mas sobrecarregados e eletrizados.",
        "mecanicas": "Emite uma onda de reinjeção energética que restaura inimigos abatidos nas proximidades. Os organismos reanimados retornam com vida reduzida, mas com velocidade de movimento e ataque aceleradas.",
        "nota_de_campo": "Nota de Geovana: Ele não volta no tempo. O que esse organismo faz é injetar um choque brutal de energia cósmica nos cadáveres ao redor, religando os músculos na marra. Os monstros voltam mais magros e furiosos. Eliminar esse catalisador é a prioridade."
    },
    "briguer_escudeiro": {
        "nome": "Briguer Escudeiro",
        "nome_curto": "Briguer Escudeiro",
        "subtitulo": "Defensor de repulsão bioenergética",
        "classificacao": "Organismo peitoral blindado",
        "resumo": "Organismo especializado que emite um campo bioelétrico frontal refletindo disparos e forçando adversários a sofrer os próprios ataques.",
        "descricao_detalhada": "Defensor especializado da fauna das Ruínas Cósmicas, equipado com órgãos vitais frontais que geram uma membrana de repulsão cinético-energética.",
        "lore": "Desenvolvido nas zonas de constante queda de meteoritos e predadores de projeção das Ruínas Cósmicas, o Briguer Escudeiro evoluiu placas peitorais condutoras. Quando sob ameaça, ele contrai seus músculos peitorais e expele um campo bioelétrico frontal denso que absorve a energia de impactos e projéteis recebidos, devolvendo o vetor de movimento contra a origem do ataque.",
        "mecanicas": "Ergue uma barreira bioenergética frontal que reflete disparos e projéteis de volta para o atacante. Evita avanço desordenado, forçando a presa a contornar sua guarda ou sofrer dano com o próprio ataque.",
        "nota_de_campo": "Nota de Geovana: A membrana biológica no peito dele funciona como um espelho cinético. Se eu disparar direto na barreira, a energia volta no meu rosto. A única saída é flanquear ou esperar a janela em que ele abaixa a guarda."
    },
    "pinguim_atirador": {
        "nome": "Pinguim Atirador",
        "nome_curto": "Pinguim Atirador",
        "subtitulo": "Soldado territorial da Dimensão Gelada",
        "classificacao": "Habitante aviário congelante",
        "resumo": "Defensor padrão da sociedade aviária que projeta disparos salivares glaciais condensados a temperaturas anômalas de até -280 °C.",
        "descricao_detalhada": "Habitante nativo e soldado territorial da civilização aviária da Dimensão Gelada, adaptado para a defesa de seu reino e habitat.",
        "lore": "Os Pinguns são os defensores da sociedade organizada que prospera nas estepes congeladas. Muito antes da chegada do rastro do dispositivo temporal, eles construíram suas cidades e hierarquias sob a autoridade de seu Rei. Quando Geovana surge através da fenda, eles a identificam como uma invasora forasteira hostil e organizam suas patrulhas para proteger suas famílias e terras.",
        "mecanicas": "Condensa o ar congelante em suas glândulas salivares e projeta cuspes/disparos glaciais que atingem temperaturas anômalas de até -280 °C na física local, reduzindo a mobilidade e infligindo dano de frio a longa distância.",
        "nota_de_campo": "Nota de Geovana: Preciso me lembrar de que eu é que invadi a casa deles. Eles não são monstros sem mente; são soldados defendendo seu reino e suas famílias contra uma estranha que caiu do céu com armas na mão. Mas se esse cuspe de -280 °C me acertar, não haverá conversa."
    },
    "pinguim_kamikaze": {
        "nome": "Pinguim Kamikaze",
        "nome_curto": "Pinguim Kamikaze",
        "subtitulo": "Defensor militar voluntário",
        "classificacao": "Aviário de assalto explosivo",
        "resumo": "Soldado voluntário da Dimensão Gelada que carrega explosivos e aceita o próprio fim para proteger seu reino contra invasores.",
        "descricao_detalhada": "Defensor militar voluntário da Dimensão Gelada, equipado com cargas minerais explosivas para a proteção de pontos estratégicos de seu território.",
        "lore": "Na cultura militar da sociedade dos pinguins, o sacrifício pessoal pela preservação da colônia e da linhagem real é visto como a mais alta honra defensiva. Quando ameaças existenciais como a intrusão de Geovana colocam em risco os ninhos e o Reino, esses defensores voluntários equipam-se com compostos nitro-glaciais e arremessam-se contra a ameaça com convicção inabalável.",
        "mecanicas": "Avança em alta velocidade diretamente contra a invasora e detona sua carga explosiva ao encurtar a distância, causando dano massivo em área ao custo de sua própria vida.",
        "nota_de_campo": "Nota de Geovana: Não há loucura irracional nos olhos dele, apenas uma determinação terrível. Ele carrega aqueles explosivos e se lança contra mim porque me vê como uma ameaça mortal ao seu povo. É um sacrifício consciente. Tenho que mantê-lo longe antes que seja tarde."
    },
    "pinguim_incendiario": {
        "nome": "Pinguim Incendiario",
        "nome_curto": "Fireguim",
        "subtitulo": "Variação biológica térmica",
        "classificacao": "Aviário de contenção pirofórica",
        "resumo": "Variação rara capaz de sintetizar fósforo e emitir massas de fogo para abrir galerias no gelo e controlar território em combate.",
        "descricao_detalhada": "Variação biológica térmica da espécie aviária, cujos órgãos internos sintetizam vesículas de fósforo mineral e óleo térmico.",
        "lore": "Em uma dimensão dominada pelo gelo absoluto, uma linhagem rara de pinguins desenvolveu glândulas pirofóricas capazes de gerar combustão endotérmica. Essa adaptação evolutiva era originalmente utilizada pela civilização para derreter galerias no gelo profundo e aquecer os ninhos reais. Em tempos de guerra e invasão, essa capacidade é empregada para erguer barreiras de chamas e confluir invasores para zonas de abate.",
        "mecanicas": "Projeta blocos e massas de fogo que permanecem queimando no terreno, cortando rotas de fuga e cercando a presa em áreas restritas.",
        "nota_de_campo": "Nota de Geovana: Ver fogo emergindo do peito de um pinguim no meio de uma tempestade de gelo parece absurdo, mas a biologia dele usa isso para escavar o gelo e proteger as galerias do reino. Em combate, ele usa essa chama para cortar minha fuga."
    },
    "devoto": {
        "nome": "Devoto",
        "nome_curto": "Devoto",
        "subtitulo": "Guardião ritual do templo",
        "classificacao": "Cultista murino sagrado",
        "resumo": "Rato cultista responsável pela guarda da Catedral e serviço ao Pai-Rato, enxergando Geovana como uma profanadora impura.",
        "descricao_detalhada": "Neófito e guardião da ordem sagrada na Catedral dos Ratos, dedicado à preservação do templo e ao culto do Pai-Rato.",
        "lore": "A Catedral é o coração espiritual e a fortaleza sagrada de uma antiga civilização murina. Os Devotos passam suas vidas estudando escrituras rituais, mantendo as relíquias e vigiando os corredores do templo. A chegada de Geovana é vista pela ordem como uma profanación impura do solo sagrado, levando os Devotos a pegarem em armas para defender seu senhor e sua fé.",
        "mecanicas": "Avança em patrulhas coordenadas no combate corpo a corpo, cercando o invasor para proteger as câmaras sagradas e os sacerdotes do templo.",
        "nota_de_campo": "Nota de Geovana: Entrei na igreja deles sem pedir licença. Para esses ratos, eu não sou apenas uma oponente; sou uma sacrílega profanando o templo sagrado do Pai-Rato. Eles lutam com o fervor de quem defende a própria fé."
    },
    "incensario": {
        "nome": "Incensário",
        "nome_curto": "Incensário",
        "subtitulo": "Sacerdote purificador de alfaias",
        "classificacao": "Hierarca murino turiferário",
        "resumo": "Sacerdote que carrega a substância sagrada do culto murino, volatilizando-a em gás corrosivo ao contato com o ar.",
        "descricao_detalhada": "Sacerdote sênior da ordem murina, incumbido de purificar as naves do templo com o incenso sagrado do Pai-Rato.",
        "lore": "Na hierarquia eclesiástica da Catedral, o Incensário ocupa o posto de purificador ritual. Ele carrega turíbulos bronzados contendo o bálsamo sagrado da ordem — uma substância fluida venerada como água benta pelos devotos. Ao entrar em contato com o ar ambiente, o elixir volatiliza-se em uma névoa corrosiva e densa, usada para abençoar os fiéis e repelir os profanos que tentam violar o altar.",
        "mecanicas": "Espalha nuvens de gás ritual que cobrem extensas áreas do mapa, infligindo dano contínuo e bloqueando a visibilidade e movimentação do jogador.",
        "nota_de_campo": "Nota de Geovana: O líquido no incensário dele é a água benta da religião deles. Quando o ar toca aquela substância, ela vira uma fumaça pesada que queima os pulmões. Ele acha que está purificando o templo ao me sufocar."
    },
    "guardiao": {
        "nome": "Guardião",
        "nome_curto": "Guardião",
        "subtitulo": "Paladino consagrado da Catedral",
        "classificacao": "Cavaleiro murino de armadura",
        "resumo": "Rato militarizado de grande porte e fé inabalável, responsável pela defesa direta do altar e do Pai-Rato.",
        "descricao_detalhada": "Cavaleiro e paladino de elite da Catedral dos Ratos, cuja força física avantajada é consagrada aos rituais de proteção do Pai-Rato.",
        "lore": "Escolhidos entre os murinos de maior porte e submetidos a jejuns e unções sagradas, os Guardiões formam a guarda de ferro do altar. Sua devoção religiosa e seu treinamento militar os tornam incapazes de recuar; para um Guardião, tombar na defesa da Catedral perante o Pai-Rato é o cume da santidade.",
        "mecanicas": "Avança pesadamente na linha de frente, absorvendo uma grande quantidade de dano e desferindo golpes corpo a corpo devastadores para proteger os Devotos e Incensários.",
        "nota_de_campo": "Nota de Geovana: Um gigante de armadura e fé inabalável. Ele não hesita, não recua e não sente medo. Cada passo dele faz o chão da Catedral tremer. Ele está ali para ser o escudo do Pai-Rato até o último suspiro."
    },
    "cartografo_vazio": {
        "nome": "Cartógrafo do Vazio",
        "nome_curto": "Cartógrafo do Vazio",
        "subtitulo": "Intérprete probabilístico do Vazio",
        "classificacao": "Anfíbio preditivo vetorial",
        "resumo": "Organismo anfíbio que lê oscilações de probabilidade do Vazio, fazendo previsões incompletas porém desconfortavelmente precisas que incomodam Geovana.",
        "descricao_detalhada": "Organismo anfíbio senciente do Vazio, dotado de órgãos sensoriais capazes de interpretar as correntes de probabilidade das linhas temporais.",
        "lore": "Nativo das margens pantanosas e fendas do Vazio, o Cartógrafo assemelha-se a um sapo de olhos facetados e pele luminescente. Ele não é onisciente; sua biologia percebe as oscilações de probabilidade e as vibrações quânticas do ambiente, permitindo-lhe traçar mapas mentais dos caminhos que a presa provavelmente tomará nos segundos seguintes.",
        "mecanicas": "Mapeia as trajetórias de deslocamento do jogador na arena, antecipando posições futuras e lançando armadilhas vetoriais onde Geovana tentará se abrigar.",
        "nota_de_campo": "Nota de Geovana: Ele parece um sapo luminescente encarando o nada, mas os olhos dele veem para onde meu corpo vai se mover daqui a três segundos. As previsões dele não são mágicas, são cálculos de probabilidade do Vazio... e são desconfortavelmente precisas."
    }
}

updated_count = 0

for tab in data.get('abas', []):
    for entry in tab.get('entradas', []):
        eid = entry.get('id')
        if eid in updates:
            up = updates[eid]
            for k, v in up.items():
                entry[k] = v
                if 'campos_originais' in entry:
                    # Sync common fields
                    if k == 'nome':
                        entry['campos_originais']['name'] = v
                    elif k == 'subtitulo':
                        entry['campos_originais']['subtitle'] = v
                    elif k == 'resumo':
                        entry['campos_originais']['summary'] = v
                        entry['campos_originais']['desc'] = v
                    elif k == 'descricao_detalhada':
                        entry['campos_originais']['identity_text'] = v
                    elif k == 'lore':
                        entry['campos_originais']['history_text'] = v
                    elif k == 'mecanicas':
                        entry['campos_originais']['mechanics_text'] = v
                    elif k == 'nota_de_campo':
                        entry['campos_originais']['field_note'] = v
            # Also keep texto_curto_lista, texto_identidade_bruto, texto_historia_bruto, texto_mecanicas_bruto in sync
            entry['texto_curto_lista'] = up.get('resumo', entry.get('texto_curto_lista'))
            entry['texto_identidade_bruto'] = up.get('descricao_detalhada', entry.get('texto_identidade_bruto'))
            entry['texto_historia_bruto'] = up.get('lore', entry.get('texto_historia_bruto'))
            entry['texto_mecanicas_bruto'] = up.get('mecanicas', entry.get('texto_mecanicas_bruto'))
            updated_count += 1
            print(f"Updated JSON entry '{eid}'")

with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=4)

print(f"Total entries updated in JSON: {updated_count}")
