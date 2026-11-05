class_name RTFieldArtifactController
extends RefCounted

## Artefatos de campo: o mesmo drop por carga/pity do "x2 pontos" agora sorteia
## entre quatro efeitos. O orbe continua com kind "point_boost" (rede, coleta e
## expiracao ja existentes) e carrega "artifact_type".
##  - pontos : x2 pontos por 12 s (comportamento antigo)
##  - ima    : puxa para Geovana cartas soltas, pontos e cristais do mapa por 1,6 s
##  - furia  : +50% de dano direto por 10 s
##  - expurgo: elimina todos os inimigos comuns na tela (nunca chefes/mini chefes)

const TYPE_POINTS := "pontos"
const TYPE_MAGNET := "ima"
const TYPE_FURY := "furia"
const TYPE_PURGE := "expurgo"

const WEIGHTS := {
	TYPE_POINTS: 1.0,
	TYPE_MAGNET: 1.0,
	TYPE_FURY: 0.9,
	TYPE_PURGE: 0.7,
}
const PURGE_MIN_ENEMIES_ON_SCREEN := 10
const FURY_DURATION := 10.0
const FURY_MULTIPLIER := 1.5
const MAGNET_DURATION := 1.6
const MAGNET_SPEED := 1150.0
const MAGNET_RANGE := 2600.0
const PURGE_FLASH_TIME := 0.55

const INFO := {
	TYPE_POINTS: {"label": "PONTOS x2", "spawn": "ARTEFATO DE PONTOS", "color": Color(1.0, 0.82, 0.16), "accent": Color(0.2, 1.0, 0.8)},
	TYPE_MAGNET: {"label": "IMA TEMPORAL", "spawn": "ARTEFATO: IMA", "color": Color(0.36, 0.76, 1.0), "accent": Color(1.0, 0.3, 0.36)},
	TYPE_FURY: {"label": "FURIA +50% DANO", "spawn": "ARTEFATO: FURIA", "color": Color(1.0, 0.3, 0.16), "accent": Color(1.0, 0.86, 0.3)},
	TYPE_PURGE: {"label": "EXPURGO", "spawn": "ARTEFATO: EXPURGO", "color": Color(0.94, 0.96, 1.0), "accent": Color(0.66, 0.4, 1.0)},
}

var core
var fury_remaining := 0.0
var magnet_remaining := 0.0
var magnet_peer_id := 0
var purge_flash := 0.0
var purge_center := Vector2.ZERO
var _sequence := 0


func configure(runtime_core) -> void:
	core = runtime_core


func reset() -> void:
	fury_remaining = 0.0
	magnet_remaining = 0.0
	magnet_peer_id = 0
	purge_flash = 0.0
	_sequence = 0


static func info(kind: String) -> Dictionary:
	return Dictionary(INFO.get(kind, INFO[TYPE_POINTS]))


## Escolhe o tipo do proximo artefato. x2 nao sai com o evento de pontos ativo e o
## expurgo so sai com a tela cheia (senao seria desperdicado).
func choose_type(event_points_active: bool, points_boost_active: bool) -> String:
	var pool: Dictionary = {}
	for key in WEIGHTS.keys():
		var kind: String = String(key)
		if kind == TYPE_POINTS and (event_points_active or points_boost_active):
			continue
		if kind == TYPE_FURY and fury_remaining > 0.0:
			continue
		if kind == TYPE_PURGE and count_purgeable_on_screen() < PURGE_MIN_ENEMIES_ON_SCREEN:
			continue
		pool[kind] = float(WEIGHTS[key])
	if pool.is_empty():
		return TYPE_MAGNET
	var total := 0.0
	for w in pool.values():
		total += float(w)
	var roll: float = core.rng.randf_range(0.0, total)
	for key in pool.keys():
		roll -= float(pool[key])
		if roll <= 0.0:
			return String(key)
	return String(pool.keys()[-1])


func update(delta: float) -> void:
	if fury_remaining > 0.0:
		fury_remaining = maxf(0.0, fury_remaining - delta)
		if fury_remaining <= 0.0 and core != null and not core.dedicated_server_mode:
			core._add_text("FURIA ENCERRADA", core.player_pos + Vector2(-60, -96), Color(0.9, 0.6, 0.5), 0.7, 15)
	if purge_flash > 0.0:
		purge_flash = maxf(0.0, purge_flash - delta)
	if magnet_remaining > 0.0:
		magnet_remaining = maxf(0.0, magnet_remaining - delta)
		_pull_resources(delta)


func damage_multiplier() -> float:
	return FURY_MULTIPLIER if fury_remaining > 0.0 else 1.0


func activate(kind: String, collector_peer_id: int, pos: Vector2, authority: bool) -> void:
	_sequence += 1
	match kind:
		TYPE_MAGNET:
			magnet_remaining = MAGNET_DURATION
			magnet_peer_id = collector_peer_id if collector_peer_id > 0 else core._mp_unique_id()
		TYPE_FURY:
			fury_remaining = FURY_DURATION
		TYPE_PURGE:
			purge_flash = PURGE_FLASH_TIME
			purge_center = pos
			if authority:
				purge_screen()


func _pull_resources(delta: float) -> void:
	if core == null:
		return
	var local_peer: int = core._mp_unique_id()
	var target: Vector2 = core.player_pos if magnet_peer_id == local_peer or magnet_peer_id == 0 else core._enemy_point_target_position(magnet_peer_id)
	if target == Vector2.INF:
		return
	var step: float = MAGNET_SPEED * delta
	for orb in core.heal_orbs:
		var kind: String = String(orb.get("kind", ""))
		if kind == core.POINT_BOOST_PICKUP_KIND:
			continue
		var p: Vector2 = Vector2(orb.get("pos", target))
		if p.distance_to(target) > MAGNET_RANGE:
			continue
		if kind == core.ENEMY_POINT_ORB_KIND:
			orb["magnet_peer_id"] = magnet_peer_id if magnet_peer_id != 0 else local_peer
			orb["magnet_speed"] = maxf(float(orb.get("magnet_speed", 0.0)), MAGNET_SPEED)
			continue
		orb["pos"] = p.move_toward(target, step)
		orb["life"] = maxf(float(orb.get("life", 0.0)), 1.0)
	for drop in core.arauto_card_drops:
		var owner: int = int(drop.get("owner_peer", 0))
		if owner != 0 and owner != magnet_peer_id and magnet_peer_id != 0:
			continue
		var dp: Vector2 = Vector2(drop.get("pos", target))
		if dp.distance_to(target) > MAGNET_RANGE:
			continue
		drop["pos"] = dp.move_toward(target, step)
		drop["life"] = maxf(float(drop.get("life", 0.0)), 1.2)


func is_purgeable(enemy: Dictionary) -> bool:
	if core._is_boss_or_mini_boss_or_larapio(enemy):
		return false
	var kind: String = String(enemy.get("type", ""))
	if kind == core.ENEMY_SINEIRO_BOREAL or kind == core.ENEMY_AMBER_SUTURER or kind == core.ENEMY_AMBER_SUTURE_NODE:
		return false
	if bool(enemy.get("aguilhao_nodule", false)):
		return false
	return float(enemy.get("hp", 0.0)) > 0.0


func _camera() -> Vector2:
	return core._camera(core.get_viewport_rect().size)


func count_purgeable_on_screen() -> int:
	if core == null or core.enemies.is_empty():
		return 0
	var cam: Vector2 = _camera()
	var count := 0
	for enemy in core.enemies:
		if is_purgeable(enemy) and core._world_point_in_view(Vector2(enemy.get("pos", Vector2.INF)), cam, 0.0):
			count += 1
	return count


func purge_screen() -> int:
	var cam: Vector2 = _camera()
	var victims: Array = []
	for enemy in core.enemies:
		if is_purgeable(enemy) and core._world_point_in_view(Vector2(enemy.get("pos", Vector2.INF)), cam, 0.0):
			victims.append(enemy)
	for enemy in victims:
		if not core.enemies.has(enemy):
			continue
		enemy["hp"] = 0.0
		core._spawn_enemy_desfragmentation(Vector2(enemy["pos"]), Color(0.9, 0.94, 1.0), 6 if core._memory_saver_active() else 10)
		core._kill_enemy(enemy)
	return victims.size()


func snapshot() -> Dictionary:
	return {"fury": snappedf(fury_remaining, 0.1), "magnet": snappedf(magnet_remaining, 0.1), "magnet_peer": magnet_peer_id, "seq": _sequence}


func apply_remote_snapshot(data: Dictionary) -> void:
	fury_remaining = maxf(0.0, float(data.get("fury", fury_remaining)))
	magnet_remaining = maxf(0.0, float(data.get("magnet", magnet_remaining)))
	magnet_peer_id = int(data.get("magnet_peer", magnet_peer_id))
