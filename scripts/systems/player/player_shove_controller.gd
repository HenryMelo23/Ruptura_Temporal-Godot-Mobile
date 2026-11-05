extends RefCounted
class_name RTPlayerShoveController

## Empurroes e puxoes de impacto viram deslocamento rapido em vez de teleporte.
## Cada impulso entra em `remaining` e e consumido com desaceleracao exponencial
## (~95% em 0,2 s), respeitando parede de fogo e limite do mundo a cada passo.

const DECAY_RATE: float = 15.0
const MAX_REMAINING: float = 360.0
const SNAP_DISTANCE: float = 1.2
## Se o jogador "pular" mais que isso fora do empurrao (teleporte, dash de habilidade),
## o resto do empurrao e descartado.
const EXTERNAL_JUMP_CANCEL: float = 120.0

var remaining: Vector2 = Vector2.ZERO
var last_pos: Vector2 = Vector2.ZERO
var active: bool = false


func reset() -> void:
	remaining = Vector2.ZERO
	active = false


func push(core: Node, offset: Vector2) -> void:
	if offset.length_squared() < 0.01:
		return
	if not active:
		last_pos = core.player_pos
	remaining = (remaining + offset).limit_length(MAX_REMAINING)
	active = true


func update(core: Node, delta: float) -> void:
	if not active:
		return
	var pos: Vector2 = core.player_pos
	if pos.distance_to(last_pos) > EXTERNAL_JUMP_CANCEL:
		reset()
		return
	var step: Vector2 = remaining * (1.0 - exp(-DECAY_RATE * maxf(delta, 0.0)))
	if remaining.length() - step.length() <= SNAP_DISTANCE:
		step = remaining
	remaining -= step
	var desired: Vector2 = pos + step
	var resolved: Vector2 = core._clamp_player_world(core._resolve_phase2_fire_wall_movement(pos, desired))
	# Bateu na borda/parede: perde a componente bloqueada.
	if resolved.distance_to(desired) > 0.5:
		var blocked: Vector2 = desired - resolved
		if absf(blocked.x) > 0.5:
			remaining.x = 0.0
		if absf(blocked.y) > 0.5:
			remaining.y = 0.0
	core.player_pos = resolved
	last_pos = resolved
	if remaining.length() <= SNAP_DISTANCE:
		reset()
