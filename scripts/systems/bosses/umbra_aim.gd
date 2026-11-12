class_name RTUmbraAim
extends RefCounted

## Mira da UMBRA: resolve o ponto de interceptacao do jogador para projeteis.
## `lead` 0 = mira na posicao atual; 1 = interceptacao perfeita. A UMBRA usa
## um valor intermediario (aprendido pela mente) para continuar desviavel.

const DEFAULT_LEAD := 0.72
const MAX_LEAD_TIME := 1.6


## Velocidade do jogador estimada pelo historico (amostras a cada 0.1 s).
static func history_velocity(history: Array, current: Vector2, sample_dt: float = 0.1, window: int = 3) -> Vector2:
	if history.size() < 2:
		return Vector2.ZERO
	var idx: int = maxi(0, history.size() - 1 - window)
	var older: Vector2 = Vector2(history[idx])
	var steps: int = history.size() - 1 - idx
	var elapsed: float = maxf(sample_dt, float(steps) * sample_dt)
	return (current - older) / elapsed


## Tempo ate o projetil alcancar um alvo em movimento constante (ou -1).
static func intercept_time(shooter: Vector2, target: Vector2, target_velocity: Vector2, speed: float) -> float:
	var rel: Vector2 = target - shooter
	var a: float = target_velocity.dot(target_velocity) - speed * speed
	var b: float = 2.0 * rel.dot(target_velocity)
	var c: float = rel.dot(rel)
	if absf(a) < 0.001:
		return -c / b if absf(b) > 0.001 and -c / b > 0.0 else -1.0
	var disc: float = b * b - 4.0 * a * c
	if disc < 0.0:
		return -1.0
	var sq: float = sqrt(disc)
	var t1: float = (-b - sq) / (2.0 * a)
	var t2: float = (-b + sq) / (2.0 * a)
	var t: float = minf(t1, t2)
	if t <= 0.0:
		t = maxf(t1, t2)
	return t if t > 0.0 else -1.0


## Ponto para onde atirar. `jitter` em radianos e aplicado pelo chamador.
static func aim_point(shooter: Vector2, target: Vector2, target_velocity: Vector2, speed: float, lead: float = DEFAULT_LEAD) -> Vector2:
	var t: float = intercept_time(shooter, target, target_velocity, speed)
	if t < 0.0:
		t = shooter.distance_to(target) / maxf(1.0, speed)
	t = minf(t, MAX_LEAD_TIME)
	return target + target_velocity * t * clampf(lead, 0.0, 1.2)


static func aim_direction(shooter: Vector2, target: Vector2, target_velocity: Vector2, speed: float, lead: float = DEFAULT_LEAD) -> Vector2:
	var dir: Vector2 = (aim_point(shooter, target, target_velocity, speed, lead) - shooter).normalized()
	if dir.length() <= 0.01:
		dir = (target - shooter).normalized()
	return dir if dir.length() > 0.01 else Vector2.RIGHT
