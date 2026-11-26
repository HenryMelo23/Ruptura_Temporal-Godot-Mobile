class_name RTSupremeEnemyRewards
extends RefCounted

## Recompensa dos Inimigos Supremos (Larapio, Sineiro, Suturador, Arauto,
## Aguilhao). Desde a Rede do Petro eles NAO dao mais cartas nem Cinzas:
## pagam pontos, em multiplos do preco atual da carta (card_cost), para o
## jogador escolher entre comprar cartas e pagar fusoes de DNA.
##
## Conta (antes -> agora), valorando carta sorteada = 1,0 card_cost e
## Cinzas = 0,75 card_cost:
## - Larapio: 2-3 cartas + Cinzas (2,75-3,75) -> 3,0 / 4,0 sem roubo.
##   O mais facil dos supremos; as moedas roubadas continuam voltando.
## - Sineiro Boreal: 0,75 + 1 carta + Cinzas (2,5) -> 3,5. Pede leitura de
##   eco e geada, com pressao de dano.
## - Suturador de Ambar: 1 carta + Cinzas + 420 pontos fixos (1,75 + 420)
##   -> 4,0 + 420. Rouba cartas (as roubadas continuam voltando: sao do
##   jogador, nao sao premio).
## - Arauto Condutor: 1,0 + 4 cartas + Cinzas (5,75) -> 7,0. Miniboss com
##   escolta e evolucao.
## - Aguilhao (Arauto da fase 6): mesma base (5,75) -> 8,0; e a versao mais
##   dura do Arauto.
## Uma fusao custa 3,0 card_cost (RTBossDnaCatalog): um Sineiro paga uma
## fusao, um Arauto paga duas.

const LARAPIO_RATIO := 3.0
const LARAPIO_CLEAN_RATIO := 4.0
const SINEIRO_RATIO := 3.5
const SUTURADOR_RATIO := 4.0
const ARAUTO_RATIO := 7.0
const AGUILHAO_RATIO := 8.0

const RATIOS := {
	"larapio": LARAPIO_RATIO,
	"larapio_clean": LARAPIO_CLEAN_RATIO,
	"sineiro": SINEIRO_RATIO,
	"suturador": SUTURADOR_RATIO,
	"arauto": ARAUTO_RATIO,
	"aguilhao": AGUILHAO_RATIO,
}


static func points_for(kind: String, card_cost: int) -> int:
	return maxi(1, int(round(float(maxi(1, card_cost)) * float(RATIOS.get(kind, 1.0)))))


## Credita os pontos (autoridade) e mostra o valor no mundo.
static func grant(core: Node, kind: String, pos: Vector2, event_id: String) -> int:
	var points := points_for(kind, int(core.card_cost))
	core._apply_score_delta(points, true, event_id)
	core._add_text("+%s PONTOS" % core._format_points(points), pos + Vector2(-82.0, -174.0), Color(1.0, 0.84, 0.28), 2.1, 24)
	return points
