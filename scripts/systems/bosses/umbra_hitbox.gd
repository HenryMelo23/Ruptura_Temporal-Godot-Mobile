class_name RTUmbraHitbox
extends RefCounted

## Geometria de acerto da UMBRA contra a Geovana, alinhada com o que aparece
## na tela. O jogador e desenhado com 54x80 px e os pes em player_pos + (0, 40),
## entao um ponto unico em player_pos (como era antes) fazia o plasma
## atravessar a cabeca ou os pes sem dano e acertar so quando o miolo chegava
## ao peito.
##
## - corpo: capsula vertical (para projeteis, contato, lasers e cone);
## - pes: ponto no chao (para o que e desenhado no chao: vortice, prisao,
##   sifao, espinhos e ratos).

const BODY_TOP := Vector2(0.0, -22.0)
const BODY_BOTTOM := Vector2(0.0, 24.0)
const BODY_RADIUS := 14.0
const FEET := Vector2(0.0, 34.0)
const FEET_RADIUS := 8.0

## Plasma do ataque basico: o miolo brilhante da arte (bolt_NN, desenhado com
## 104 px) fica ~24 px a frente do centro do projetil e tem ~26 px de raio.
## O acerto usa 18 px: encosta no miolo, nao no rastro.
const PLASMA_HEAD := 24.0
const PLASMA_RADIUS := 18.0
## Saida do disparo: a mao estendida da UMBRA v3 (quadro ataque_03).
const HAND_HEIGHT := -34.0
const HAND_REACH := 60.0

## Corpo da UMBRA (paira; pes ~78 px abaixo de boss_pos, cabelo ~110 acima).
const UMBRA_TOP := Vector2(0.0, -72.0)
const UMBRA_BOTTOM := Vector2(0.0, 44.0)
const UMBRA_RADIUS := 38.0


static func segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var denom := ab.length_squared()
	if denom <= 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func segments_distance(a1: Vector2, b1: Vector2, a2: Vector2, b2: Vector2) -> float:
	if Geometry2D.segment_intersects_segment(a1, b1, a2, b2) != null:
		return 0.0
	return minf(minf(segment_distance(a1, a2, b2), segment_distance(b1, a2, b2)), minf(segment_distance(a2, a1, b1), segment_distance(b2, a1, b1)))


## Distancia da capsula do corpo ate um ponto.
static func body_distance(player: Vector2, p: Vector2) -> float:
	return segment_distance(p, player + BODY_TOP, player + BODY_BOTTOM)


static func body_hits_circle(player: Vector2, center: Vector2, radius: float) -> bool:
	return body_distance(player, center) <= radius + BODY_RADIUS


## Circulo que se moveu de `from` ate `to` neste quadro (sem atravessar o corpo).
static func body_hits_swept(player: Vector2, from: Vector2, to: Vector2, radius: float) -> bool:
	return segments_distance(from, to, player + BODY_TOP, player + BODY_BOTTOM) <= radius + BODY_RADIUS


static func feet(player: Vector2) -> Vector2:
	return player + FEET


static func feet_in_circle(player: Vector2, center: Vector2, radius: float) -> bool:
	return feet(player).distance_to(center) <= radius + FEET_RADIUS


static func feet_near_segment(player: Vector2, a: Vector2, b: Vector2, half_width: float) -> bool:
	return segment_distance(feet(player), a, b) <= half_width + FEET_RADIUS


## Raio infinito a partir de `origin` (lasers): menor distancia perpendicular
## do corpo ao feixe, so do lado da frente.
static func body_hits_ray(player: Vector2, origin: Vector2, dir: Vector2, half_width: float, length: float = 1400.0) -> bool:
	return segments_distance(origin, origin + dir * length, player + BODY_TOP, player + BODY_BOTTOM) <= half_width + BODY_RADIUS


## Cone com vertice em `origin`: entra se qualquer parte da capsula entra.
static func body_in_cone(player: Vector2, origin: Vector2, dir: Vector2, radius: float, half_angle: float) -> bool:
	for k in range(5):
		var p: Vector2 = (player + BODY_TOP).lerp(player + BODY_BOTTOM, float(k) / 4.0)
		var v: Vector2 = p - origin
		var dist: float = v.length()
		if dist > radius + BODY_RADIUS:
			continue
		if dist <= BODY_RADIUS:
			return true
		var slack: float = asin(clampf(BODY_RADIUS / dist, 0.0, 1.0))
		if absf(wrapf(v.angle() - dir.angle(), -PI, PI)) <= half_angle + slack:
			return true
	return false


static func plasma_head(pos: Vector2, dir: Vector2) -> Vector2:
	return pos + dir.normalized() * PLASMA_HEAD


static func umbra_hand(boss_pos: Vector2, dir: Vector2) -> Vector2:
	return boss_pos + Vector2(0.0, HAND_HEIGHT) + dir.normalized() * HAND_REACH


static func umbra_touches_body(boss_pos: Vector2, player: Vector2) -> bool:
	return segments_distance(boss_pos + UMBRA_TOP, boss_pos + UMBRA_BOTTOM, player + BODY_TOP, player + BODY_BOTTOM) <= UMBRA_RADIUS + BODY_RADIUS
