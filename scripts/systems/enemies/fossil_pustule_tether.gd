class_name RTFossilPustuleTether
extends RefCounted

## Cordao umbilical da Pustula Fossil. O cuspe virou um cordao de carne com
## ponta de osso afiada: quando acerta, a pustula ARRASTA o jogador ate ela
## (antes ela teleportava). Durante o puxao o jogador nao anda e nao toma golpe
## de outros inimigos; ao chegar, a pustula estoura como antes. Se a pustula
## morrer no meio do caminho o cordao arrebenta e o jogador fica onde esta.

const PULL_SPEED := 760.0
const MIN_TIME := 0.24
const MAX_TIME := 0.8
const ARRIVED_DISTANCE := 90.0
## Danos da propria pustula continuam valendo durante/depois do puxao.
const OWN_SOURCES: Array[String] = ["pustula_fossil_spit", "pustula_fossil_burn"]

var core: Node = null
var active := false
var source_uid := -1
var from := Vector2.ZERO
var anchor := Vector2.ZERO
var t := 0.0
var duration := 0.0
## Ultimo cordao arrebentado, so para o visual sumir com um estalo.
var snap_pos := Vector2.ZERO
var snap_timer := 0.0


func configure(owner: Node) -> void:
	core = owner


func reset() -> void:
	active = false
	source_uid = -1
	t = 0.0
	duration = 0.0
	snap_timer = 0.0


func is_pulling() -> bool:
	return active


func progress() -> float:
	return clampf(t / maxf(0.01, duration), 0.0, 1.0)


## Imunidade a golpes de outros inimigos enquanto o cordao arrasta.
func blocks_damage(source: String) -> bool:
	return active and not OWN_SOURCES.has(source)


func begin(pustule: Dictionary) -> bool:
	if core == null or bool(core.is_dead):
		return false
	if core.henry_incendiary_ability_controller.is_spin_invulnerable() or core.henry_colossus_ability_controller.is_leap_invulnerable():
		return false
	active = true
	source_uid = int(pustule.get("uid", -1))
	from = Vector2(core.player_pos)
	anchor = _destination(Vector2(pustule.get("pos", from)))
	t = 0.0
	duration = clampf(from.distance_to(anchor) / PULL_SPEED, MIN_TIME, MAX_TIME)
	core._add_text("PUXADA PELO CORDÃO", from + Vector2(-80, -76), Color(0.95, 0.62, 0.62), 0.8, 17)
	core._vibrate(60, 0.3)
	return true


func update(delta: float) -> void:
	snap_timer = maxf(0.0, snap_timer - delta)
	if not active:
		return
	var pustule: Dictionary = core._fossil_pustule_by_uid(source_uid)
	if pustule.is_empty() or bool(core.is_dead):
		# Ja chegou perto e a pustula estourou sozinha: fim normal do puxao.
		if not bool(core.is_dead) and Vector2(core.player_pos).distance_to(anchor) <= ARRIVED_DISTANCE:
			active = false
			return
		_snap()
		return
	# A pustula pode se mexer: o destino acompanha a ponta do cordao.
	anchor = _destination(Vector2(pustule.get("pos", anchor)))
	t += delta
	var k: float = progress()
	# Comeca devagar (o cordao estica) e chega rapido (a pustula recolhe).
	core.player_pos = core._clamp_player_world(from.lerp(anchor, k * k))
	if k >= 1.0:
		active = false
		core._spawn_radial_particles(core.player_pos, Color(1.0, 0.58, 0.16), 12)
		core._vibrate(85, 0.42)
		core._explode_fossil_pustule(pustule)


func _destination(pustule_pos: Vector2) -> Vector2:
	return pustule_pos.clamp(Vector2(40.0, 40.0), core.WORLD_SIZE - Vector2(40.0, 40.0))


func _snap() -> void:
	active = false
	snap_pos = core.player_pos
	snap_timer = 0.3
	core._add_text("CORDÃO ARREBENTOU", core.player_pos + Vector2(-80, -76), Color(1.0, 0.86, 0.6), 0.8, 16)
