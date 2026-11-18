class_name RTBargainCapsuleBalance
extends RefCounted

## Resistencia das capsulas da Barganha. Antes a vida era fixa (170) e o dano dos
## inimigos crescia a run inteira: a partir de certo ponto um golpe so quebrava a
## capsula. Agora:
## - a vida acompanha o golpe tipico dos inimigos NO MOMENTO em que ela cai
##   (qualquer curva de dano, linear ou exponencial, mantem o mesmo numero de
##   golpes para quebrar);
## - um escudo rigido absorve a maior parte de cada golpe, mas perde uma fatia
##   fixa a cada hit, entao enxame de golpes fracos tambem o derruba.

## Golpes tipicos que a vida (sem escudo) aguenta.
const HITS_TO_BREAK_HP := 6.0
## Escudo inicial em relacao a vida maxima.
const SHIELD_RATIO := 1.0
## Fracao do golpe que o escudo segura enquanto existe.
const SHIELD_ABSORB := 0.8
## Fatia do escudo maximo que cada golpe arranca, alem do que absorveu.
const SHIELD_DECAY_PER_HIT := 0.12
## Quantos inimigos amostrar para estimar o golpe tipico.
const REFERENCE_SAMPLE := 24
## Percentil do golpe amostrado (ignora o elite isolado de dano absurdo).
const REFERENCE_PERCENTILE := 0.75


## Golpe tipico atual dos inimigos vivos (0 quando nao ha ninguem para amostrar).
static func reference_hit(game: Node) -> float:
	var hits: Array[float] = []
	for enemy_value in game.enemies:
		if hits.size() >= REFERENCE_SAMPLE:
			break
		var enemy: Dictionary = enemy_value
		if String(enemy.get("type", "")) == "boss" or float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		hits.append(float(game._enemy_damage(enemy)))
	if hits.is_empty():
		return 0.0
	hits.sort()
	return hits[int(floor(REFERENCE_PERCENTILE * float(hits.size() - 1)))]


static func max_hp(base_hp: float, party_mult: float, ref_hit: float) -> float:
	return maxf(60.0, maxf(base_hp, ref_hit * HITS_TO_BREAK_HP) * party_mult)


static func shield_for(hp_max: float) -> float:
	return hp_max * SHIELD_RATIO


## Aplica um golpe na capsula: o escudo absorve e decai, o resto vai para a
## vida. Devolve a vida efetivamente perdida.
static func apply_hit(capsule: Dictionary, amount: float) -> float:
	var hit: float = maxf(1.0, amount)
	var shield: float = float(capsule.get("shield", 0.0))
	var to_hp: float = hit
	if shield > 0.0:
		var absorbed: float = minf(shield, hit * SHIELD_ABSORB)
		to_hp = hit - absorbed
		var decay: float = float(capsule.get("shield_max", shield)) * SHIELD_DECAY_PER_HIT
		capsule["shield"] = maxf(0.0, shield - absorbed - decay)
		capsule["shield_flash"] = 0.22
	var hp_before: float = float(capsule.get("hp", 0.0))
	capsule["hp"] = maxf(0.0, hp_before - to_hp)
	return hp_before - float(capsule["hp"])
