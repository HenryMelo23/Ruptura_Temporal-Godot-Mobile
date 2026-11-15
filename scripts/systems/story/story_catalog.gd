class_name RTStoryCatalog
extends RefCounted

## Roteiro das mini cenas em HQ (motion comic). Cada painel aponta para uma
## imagem em res://assets/story/<img>.jpg (1280x720; originais do Codex em
## assets/story/_source, ignorados pelo Godot). Sem a
## imagem, o player desenha um quadro provisório com o texto de "art".
##
## Painel: img, art (descrição p/ o Codex), rect (x,y,w,h normalizado na página),
##   enter (slide_left|slide_right|slide_up|zoom|fade|impact), cam ([zoom0, zoom1,
##   pan0, pan1] Ken Burns), focus (ponto do assunto na imagem, 0..1; o recorte
##   centraliza nele), fx ("speed"|"flash"|""), lines (falas). type "card" = quadro
##   sem imagem (cartao de dimensao desenhado pelo jogo).
## Fala: [tipo, texto, x, y] tipo = caption | speech | thought | sfx | hud.
## {frag} vira "n/7" (fragmentos coletados na run).

const IMAGE_DIR := "res://assets/story/"

const SCENES := {
	"prologo": {"pages": [
		{"panels": [
			{"img": "intro_01", "focus": Vector2(0.4, 0.3), "rect": [0.0, 0.0, 1.0, 0.52], "enter": "fade", "cam": [1.12, 1.0, Vector2(-0.04, 0.0), Vector2(0.03, 0.0)],
				"art": "Laboratório subterrâneo à noite. Geovana e Henrique de jaleco diante de um grande arco de contenção metálico com núcleos azuis. Eles riem, cúmplices.",
				"lines": [["caption", "Antes da Ruptura, havia um laboratório... e duas pessoas que acreditavam no tempo.", 0.03, 0.06]]},
			{"img": "intro_02", "focus": Vector2(0.5, 0.38), "rect": [0.0, 0.54, 1.0, 0.46], "enter": "impact", "cam": [1.0, 1.18, Vector2.ZERO, Vector2(0.02, -0.02)], "fx": "flash",
				"art": "Acidente: o arco explode em luz roxa; um raio de energia atinge Henrique, que é arremessado. Geovana grita, braço estendido.",
				"lines": [["sfx", "KRAAAACK!", 0.62, 0.3], ["speech", "HENRIQUE!", 0.12, 0.2]]},
		]},
		{"panels": [
			{"img": "intro_03", "focus": Vector2(0.42, 0.42), "rect": [0.0, 0.0, 0.62, 1.0], "enter": "slide_left", "cam": [1.0, 1.1, Vector2(0.02, 0.0), Vector2(-0.02, 0.02)],
				"art": "Ala médica fria. Henrique pálido numa cápsula de isolamento; Geovana com a mão espalmada no vidro, olhos marejados.",
				"lines": [["thought", "Foi a nossa tecnologia que fez isso com ele.", 0.05, 0.08], ["speech", "Eu vou te trazer de volta. Eu prometo.", 0.08, 0.72]]},
			{"img": "intro_04", "focus": Vector2(0.5, 0.27), "rect": [0.64, 0.0, 0.36, 1.0], "enter": "slide_right", "cam": [1.08, 1.0, Vector2(0.0, -0.03), Vector2(0.0, 0.02)],
				"art": "General Aires em contraluz, farda escura, olhar frio. Ao fundo, soldados.",
				"lines": [["speech", "Sua genialidade só vale se for controlável, doutora.", 0.06, 0.1]]},
		]},
		{"panels": [
			{"img": "intro_05", "focus": Vector2(0.45, 0.45), "rect": [0.0, 0.0, 1.0, 0.5], "enter": "fade", "cam": [1.15, 1.0, Vector2(0.03, 0.02), Vector2(-0.02, 0.0)],
				"art": "Bunker improvisado: Geovana sozinha montando o bracelete quântico, cadernos, fórmulas na parede, café frio. Luz de uma única lâmpada.",
				"lines": [["caption", "Sozinha, ela terminou o que o governo queria transformar em arma.", 0.03, 0.08]]},
			{"img": "intro_06", "focus": Vector2(0.6, 0.42), "rect": [0.0, 0.52, 0.49, 0.48], "enter": "zoom", "cam": [1.0, 1.25, Vector2.ZERO, Vector2(0.0, -0.03)],
				"art": "Close no pulso de Geovana: o bracelete encaixa e acende em azul; um visor holográfico projeta dados.",
				"lines": [["hud", "INTERFACE NEURAL: 91%", 0.08, 0.12]]},
			{"img": "intro_07", "focus": Vector2(0.45, 0.5), "rect": [0.51, 0.52, 0.49, 0.48], "enter": "slide_up", "cam": [1.05, 1.15, Vector2(0.02, 0.0), Vector2(-0.02, 0.0)], "fx": "speed",
				"art": "O arco abre um portal instável e faminto; o General surge atrás do vidro gritando. Geovana, de costas, encara o portal.",
				"lines": [["speech", "Se o tempo não volta... eu vou atrás dele.", 0.05, 0.1]]},
		]},
		{"panels": [
			{"img": "intro_08", "focus": Vector2(0.4, 0.42), "rect": [0.0, 0.0, 1.0, 0.5], "enter": "impact", "cam": [1.25, 1.0, Vector2.ZERO, Vector2.ZERO], "fx": "speed",
				"art": "Geovana caindo por um túnel de fragmentos do tempo: relógios quebrados, cenas da vida dela, luz roxa e azul.",
				"lines": [["sfx", "VRRRUUUM", 0.55, 0.5]]},
			{"img": "intro_09", "focus": Vector2(0.45, 0.38), "rect": [0.0, 0.52, 1.0, 0.48], "enter": "fade", "cam": [1.0, 1.1, Vector2(-0.02, 0.0), Vector2(0.02, 0.0)],
				"art": "Geovana caída numa terra estranha, céu roxo; o visor do bracelete mostra sete pontos espalhados num mapa.",
				"lines": [["hud", "NÚCLEO PARTIDO: 7 FRAGMENTOS EM 7 DIMENSÕES", 0.5, 0.08], ["caption", "Cada fragmento, uma dimensão. Cada dimensão, um guardião.", 0.5, 0.7]]},
		]},
	]},
}

## Uma cena pós-chefe por chefe (defeat + fragmento + salto). O salto é
## compartilhado; só a fala muda.
const BOSS_SCENES := {
	1: {"defeat": "boss1_defeat", "fragment": "boss1_fragment", "defeat_focus": Vector2(0.45, 0.42), "fragment_focus": Vector2(0.6, 0.45),
		"defeat_art": "O Caranguejo do Nulo (Cronoguejo) desaba; o relógio no peito estilhaça, ponteiros voando. Geovana em pé, punhos fumegando energia azul.",
		"fragment_art": "Geovana segura um fragmento luminoso arrancado do relógio; o pequeno golem Petro espia por trás de uma pedra.",
		"line": "Seu tempo acabou, relógio ambulante.", "after": "Um a menos."},
	2: {"defeat": "boss2_defeat", "fragment": "boss2_fragment", "defeat_focus": Vector2(0.55, 0.33), "fragment_focus": Vector2(0.62, 0.62),
		"defeat_art": "A Sentinela Glacial (pinguim gigante de gelo) congela e racha inteira no meio da nevasca; neve explode para os lados.",
		"fragment_art": "Dentro de um bloco de gelo partido, o fragmento brilha; Geovana quebra o gelo com o punho eletrificado.",
		"line": "Nem a nevasca segura quem tem pra onde ir.", "after": "Ainda sinto o frio nos ossos."},
	3: {"defeat": "boss3_defeat", "fragment": "boss3_fragment", "defeat_focus": Vector2(0.45, 0.4), "fragment_focus": Vector2(0.6, 0.5),
		"defeat_art": "O Pai-Rato cai sobre o altar de queijo rachado na catedral do esgoto; ratos fiéis recuam assustados.",
		"fragment_art": "Stiff, o rato de olhos tristes, entrega o fragmento a Geovana com as duas patas.",
		"line": "Sua fé tinha fome. A minha tem pressa.", "after": "Obrigada, Stiff. Cuida deles."},
	4: {"defeat": "boss4_defeat", "fragment": "boss4_fragment", "defeat_focus": Vector2(0.5, 0.45), "fragment_focus": Vector2(0.4, 0.35),
		"defeat_art": "O Nexo Anfíbio, sapo astronauta colossal, ajoelha com o traje vazando energia; o visor do capacete trinca.",
		"fragment_art": "Geovana com o fragmento na mão; ao fundo, a silhueta do Capitão de quatro metros observando em silêncio.",
		"line": "Eu não sou a vilã... sou?", "after": "Entre uma vida e o mundo... eu escolho ele."},
	5: {"defeat": "boss5_defeat", "fragment": "boss5_fragment", "defeat_focus": Vector2(0.5, 0.5), "fragment_focus": Vector2(0.5, 0.5),
		"defeat_art": "A UMBRA se estilhaça como um espelho gigante que refletia a própria Geovana; cacos com memórias dela.",
		"fragment_art": "No centro dos cacos, o fragmento flutua; o reflexo de Geovana sorri de um jeito que ela não sorri.",
		"line": "Você aprendeu os meus passos. Não aprendeu por que eu ando.", "after": "Saia da minha cabeça."},
	6: {"defeat": "boss6_defeat", "fragment": "boss6_fragment", "defeat_focus": Vector2(0.4, 0.4), "fragment_focus": Vector2(0.5, 0.42),
		"defeat_art": "A Matriarca da Chaga se desfaz em âmbar líquido; o ninho racha e libera luz.",
		"fragment_art": "Geovana puxa o fragmento preso numa gota de âmbar, como um inseto antigo.",
		"line": "Nada fica preso pra sempre. Nem eu.", "after": "Quase lá, Henrique."},
	7: {"defeat": "boss7_defeat", "fragment": "boss7_fragment", "defeat_focus": Vector2(0.45, 0.4), "fragment_focus": Vector2(0.45, 0.4),
		"defeat_art": "A Fênix explode em cinzas sobre a floresta queimada; brasas giram em espiral ao redor de Geovana.",
		"fragment_art": "Das cinzas, o último fragmento sobe brilhando até a mão de Geovana.",
		"line": "Até as cinzas aprendem a voltar.", "after": "Agora só falta você."},
	8: {"defeat": "boss8_defeat", "fragment": "boss8_fragment", "defeat_focus": Vector2(0.5, 0.4), "fragment_focus": Vector2(0.5, 0.5),
		"defeat_art": "O jabuti colossal Casco-de-Sol desaba; o casco-relógio racha, engrenagens de bronze e luz dourada saem das fissuras, o gnômon tomba. Geovana de costas, jaleco ao vento.",
		"fragment_art": "As mãos de Geovana seguram o fragmento achado entre as engrenagens; ele projeta a sombra de um ponteiro de relógio na palma dela.",
		"line": "Pode descansar. Eu ainda tenho pressa.", "after": "O relógio parou. Eu não."},
}

const JUMP_IMAGES := {
	"jump_a": "Geovana corre e salta para dentro de uma fenda dimensional roxa que se abre no ar, cabelo ao vento, bracelete aceso.",
	"jump_b": "Geovana atravessa a fenda de costas para o leitor, a mão estendida, o portal girando como um olho.",
}

## Chegada em cada dimensão (ordem aleatória: cada uma se basta).
const ARRIVAL_SCENES := {
	1: {"name": "RUÍNAS CÓSMICAS", "wide": "arrive1_wide", "react": "arrive1_react", "react_focus": Vector2(0.45, 0.35), "wide_art": "Ruínas Cósmicas: castelo em ruínas sob céu roxo com relâmpagos lentos, névoa rastejando nas dunas.",
		"react_art": "Geovana levantando do chão, olhando para cima, jaleco rasgado.", "line": "Céu roxo, ruínas flutuando... isso aqui já foi um castelo?"},
	2: {"name": "FENDA GLACIAL", "wide": "arrive2_wide", "react": "arrive2_react", "react_focus": Vector2(0.45, 0.4), "wide_art": "Fenda Glacial: cânion de gelo azul, nevasca, cristais gigantes.",
		"react_art": "Geovana se abraçando de frio, respiração virando vapor.", "line": "Frio que corta até o tempo. Ótimo."},
	3: {"name": "CATEDRAL DO ESGOTO", "wide": "arrive3_wide", "react": "arrive3_react", "react_focus": Vector2(0.35, 0.35), "wide_art": "Catedral do Esgoto: colunas douradas com limo, vitrais quebrados, canais de água verde, velas de queijo.",
		"react_art": "Geovana tapando o nariz, careta.", "line": "Que cheiro é esse? ...Queijo?"},
	4: {"name": "CORAÇÃO DO NEXO", "wide": "arrive4_wide", "react": "arrive4_react", "react_focus": Vector2(0.4, 0.35), "wide_art": "Coração do Nexo: cidade alienígena de cristal e pedra negra, sol artificial, anfíbios de traje.",
		"react_art": "Geovana boquiaberta, reflexos da cidade nos óculos.", "line": "Uma cidade inteira... alguém sobreviveu aqui."},
	5: {"name": "MENTE DA UMBRA", "wide": "arrive5_wide", "react": "arrive5_react", "react_focus": Vector2(0.45, 0.4), "wide_art": "Mente da Umbra: vazio escuro com fragmentos de memórias da Geovana flutuando (o laboratório, a casa, o casamento).",
		"react_art": "Geovana tocando uma memória flutuante de Henrique, que se desfaz.", "line": "Isso não é um lugar. É uma lembrança... minha."},
	6: {"name": "CHAGA DE ÂMBAR", "wide": "arrive6_wide", "react": "arrive6_react", "react_focus": Vector2(0.35, 0.4), "wide_art": "Chaga de Âmbar: pântano de âmbar com criaturas presas, fungos pulsando.",
		"react_art": "Geovana com o pé grudado no âmbar, puxando.", "line": "Tudo aqui está preso. Como insetos no tempo."},
	7: {"name": "CINZAS DA RUPTURA", "wide": "arrive7_wide", "react": "arrive7_react", "react_focus": Vector2(0.4, 0.38), "wide_art": "Cinzas da Ruptura: floresta queimada, brasas no ar, troncos em chamas, céu alaranjado.",
		"react_art": "Geovana segurando cinzas na mão, expressão de culpa.", "line": "Uma floresta queimada... fui eu que fiz isso?"},
	8: {"name": "SERTÃO DAS TARTARUGAS", "wide": "arrive8_wide", "react": "arrive8_react", "react_focus": Vector2(0.45, 0.4), "wide_art": "Sertão das Tartarugas: caatinga sem fim ao meio-dia eterno, sol branco parado no céu, fila de jabutis no horizonte e a silhueta de um jabuti colossal com relógio de sol no casco.",
		"react_art": "Geovana ajoelhada no barro rachado, protegendo os olhos do sol; um pequeno jabuti olha para ela de perto.", "line": "Até o sol parou aqui. Que inveja."},
}


static func boss_scene(phase: int) -> Dictionary:
	var b: Dictionary = BOSS_SCENES.get(phase, {})
	if b.is_empty():
		return {}
	var jump: String = "jump_a" if phase % 2 == 1 else "jump_b"
	return {"pages": [
		{"panels": [
			{"img": b["defeat"], "art": b["defeat_art"], "focus": b.get("defeat_focus", Vector2(0.5, 0.42)), "rect": [0.0, 0.0, 1.0, 0.58], "enter": "impact", "cam": [1.2, 1.0, Vector2.ZERO, Vector2(0.0, 0.02)], "fx": "flash",
				"lines": [["speech", b["line"], 0.05, 0.08]]},
			{"img": b["fragment"], "art": b["fragment_art"], "focus": b.get("fragment_focus", Vector2(0.5, 0.45)), "rect": [0.0, 0.6, 0.56, 0.4], "enter": "zoom", "cam": [1.0, 1.2, Vector2.ZERO, Vector2(0.0, -0.02)],
				"lines": [["hud", "FRAGMENTO RECUPERADO  {frag}", 0.05, 0.12]]},
			{"img": jump, "art": JUMP_IMAGES[jump], "focus": Vector2(0.55, 0.45) if jump == "jump_a" else Vector2(0.5, 0.5), "rect": [0.58, 0.6, 0.42, 0.4], "enter": "slide_right", "cam": [1.05, 1.2, Vector2(0.02, 0.0), Vector2(-0.02, 0.0)], "fx": "speed",
				"lines": [["speech", b["after"], 0.05, 0.1]]},
		]},
	]}


static func arrival_scene(phase: int) -> Dictionary:
	var a: Dictionary = ARRIVAL_SCENES.get(phase, {})
	if a.is_empty():
		return {}
	return {"pages": [
		{"panels": [
			{"img": a["wide"], "art": a["wide_art"], "focus": Vector2(0.5, 0.45), "hold": 2.2, "rect": [0.0, 0.0, 1.0, 0.56], "enter": "fade", "cam": [1.18, 1.0, Vector2(0.04, 0.0), Vector2(-0.03, 0.0)],
				"lines": []},
			{"type": "card", "hold": 1.9, "img": "", "art": "", "title": String(a.get("name", "")), "rect": [0.0, 0.58, 0.34, 0.42], "enter": "slide_left", "cam": [1.0, 1.0, Vector2.ZERO, Vector2.ZERO],
				"lines": []},
			{"img": a["react"], "art": a["react_art"], "focus": a.get("react_focus", Vector2(0.45, 0.4)), "rect": [0.36, 0.58, 0.64, 0.42], "enter": "slide_up", "cam": [1.0, 1.12, Vector2.ZERO, Vector2(0.02, 0.0)],
				"lines": [["speech", a["line"], 0.05, 0.1]]},
		]},
	]}


static func scene(id: String) -> Dictionary:
	if id.begins_with("boss_"):
		return boss_scene(int(id.substr(5)))
	if id.begins_with("arrive_"):
		return arrival_scene(int(id.substr(7)))
	return Dictionary(SCENES.get(id, {}))


## Lista completa de imagens (para o pedido ao Codex e para testes).
static func all_images() -> Array:
	var out: Array = []
	for id in ["prologo"]:
		for page in Array(Dictionary(SCENES[id])["pages"]):
			for panel in Array(page["panels"]):
				out.append([panel["img"], panel["art"]])
	for k in BOSS_SCENES.keys():
		var b: Dictionary = BOSS_SCENES[k]
		out.append([b["defeat"], b["defeat_art"]])
		out.append([b["fragment"], b["fragment_art"]])
	for j in JUMP_IMAGES.keys():
		out.append([j, JUMP_IMAGES[j]])
	for k in ARRIVAL_SCENES.keys():
		var a: Dictionary = ARRIVAL_SCENES[k]
		out.append([a["wide"], a["wide_art"]])
		out.append([a["react"], a["react_art"]])
	return out
