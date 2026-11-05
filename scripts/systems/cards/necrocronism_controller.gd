class_name RTNecrocronismController
extends RefCounted

## Necrocronismo (rara): a cada N mortes validas o inimigo "volta no tempo" e vira um
## Eco espectral aliado. O Eco ressurge (rebobinando), da investidas encadeadas que
## atravessam a horda aplicando lentidao e, quando o tempo dele acaba, implode.
## Estado dos Ecos vive em core.active_necro_specters (salvo junto da run).

const CARD_ID := "necrocronismo"
const RISE_TIME := 0.5
const DASH_SPEED := 980.0
const DASH_OVERSHOOT := 90.0
const DASH_MIN_LENGTH := 180.0
const DASH_WIDTH := 30.0
const DASH_MAX_LENGTH := 360.0
const RECOVER_TIME := 0.2
const SEEK_RADIUS := 430.0
const ORBIT_RADIUS := 78.0
const ORBIT_SPEED := 2.2
const COLLAPSE_TIME := 0.42
const COLLAPSE_RADIUS := 96.0
const BASE_ALIVE_CAP := 4
const MAX_ALIVE_CAP := 6
const DASH_DAMAGE_BASE := 0.42
const DASH_DAMAGE_PER_EXTRA := 0.07
const COLLAPSE_DAMAGE_BASE := 0.85
const COLLAPSE_DAMAGE_PER_EXTRA := 0.12
const ELITE_DAMAGE_MULT := 1.25
const BOSS_DAMAGE_MULT := 0.55
const SLOW_TIME := 1.1
const SLOW_MULT := 0.6
const STREAK_LIFE := 0.22
const STREAK_CAP := 24
const AFTERIMAGE_COUNT := 4
const AFTERIMAGE_SPACING := 0.035

var core: Node
## Riscos das investidas (so visual, nao salvos).
var streaks: Array = []


func configure(owner: Node) -> void:
	core = owner


func reset() -> void:
	streaks.clear()


func card_count() -> int:
	return int(core._rare_card_count(CARD_ID)) if core != null else 0


func alive_cap() -> int:
	return mini(MAX_ALIVE_CAP, BASE_ALIVE_CAP + maxi(0, card_count() - 1))


func dash_damage(specter: Dictionary) -> float:
	var ratio: float = DASH_DAMAGE_BASE + DASH_DAMAGE_PER_EXTRA * float(core._rare_sqrt_extra(CARD_ID))
	return maxf(1.0, float(core.player_damage) * ratio * (ELITE_DAMAGE_MULT if bool(specter.get("elite", false)) else 1.0))


func collapse_damage(specter: Dictionary) -> float:
	var ratio: float = COLLAPSE_DAMAGE_BASE + COLLAPSE_DAMAGE_PER_EXTRA * float(core._rare_sqrt_extra(CARD_ID))
	return maxf(1.0, float(core.player_damage) * ratio * (ELITE_DAMAGE_MULT if bool(specter.get("elite", false)) else 1.0))


func spawn_from(enemy: Dictionary) -> void:
	if card_count() <= 0:
		return
	var specters: Array = core.active_necro_specters
	# No limite, o Eco mais antigo implode para abrir espaco (nada se perde).
	if _living_count() >= alive_cap():
		for specter in specters:
			if String(specter.get("state", "")) != "collapse":
				_begin_collapse(specter)
				break
	var pos: Vector2 = Vector2(enemy.get("pos", core.player_pos))
	var duration: float = float(core._necro_duration(enemy))
	specters.append({
		"type": String(enemy.get("type", core.ENEMY_COMMON)),
		"pos": pos,
		"life": duration,
		"max": duration,
		"state": "rise",
		"state_time": 0.0,
		"dash_from": pos,
		"dash_to": pos,
		"hit_uids": [],
		"orbit": core.rng.randf_range(0.0, TAU),
		"phase": core.rng.randf_range(0.0, TAU),
		"facing": 1.0,
		"trail": [pos, pos, pos, pos],
		"trail_clock": 0.0,
		"elite": core._is_uncommon_enemy(enemy),
		"source_uid": int(enemy.get("uid", 0)),
		"is_necro_specter": true,
		"power": DASH_DAMAGE_BASE + DASH_DAMAGE_PER_EXTRA * float(core._rare_sqrt_extra(CARD_ID)),
	})


func _living_count() -> int:
	var count := 0
	for specter in core.active_necro_specters:
		if String(specter.get("state", "")) != "collapse":
			count += 1
	return count


func update(delta: float) -> void:
	if core == null:
		return
	for streak in streaks:
		streak["life"] = float(streak.get("life", 0.0)) - delta
	streaks = streaks.filter(func(s): return float(s.get("life", 0.0)) > 0.0)
	var specters: Array = core.active_necro_specters
	if specters.is_empty():
		return
	var claimed: Dictionary = {}
	for specter in specters:
		if String(specter.get("state", "")) == "dash":
			claimed[int(specter.get("target_uid", -1))] = true
	for specter in specters:
		_migrate_legacy(specter)
		specter["state_time"] = float(specter.get("state_time", 0.0)) + delta
		var state: String = String(specter.get("state", "seek"))
		if state != "collapse":
			specter["life"] = float(specter.get("life", 0.0)) - delta
			if float(specter["life"]) <= 0.0:
				_begin_collapse(specter)
				state = "collapse"
		match state:
			"rise":
				if float(specter["state_time"]) >= RISE_TIME:
					_set_state(specter, "seek")
			"seek", "recover":
				if state == "recover" and float(specter["state_time"]) < RECOVER_TIME:
					_orbit_step(specter, delta)
				elif not _try_begin_dash(specter, claimed):
					_orbit_step(specter, delta)
			"dash":
				_dash_step(specter, delta)
			"collapse":
				if float(specter["state_time"]) >= COLLAPSE_TIME and not bool(specter.get("collapsed", false)):
					specter["collapsed"] = true
					_detonate(specter)
		_sample_trail(specter, delta)
	core.active_necro_specters = specters.filter(func(s): return not bool(s.get("collapsed", false)))


## Saves antigos (antes do rework) nao tinham maquina de estados.
func _migrate_legacy(specter: Dictionary) -> void:
	if specter.has("state"):
		return
	var pos: Vector2 = Vector2(specter.get("pos", core.player_pos))
	specter["state"] = "seek"
	specter["state_time"] = 0.0
	specter["dash_from"] = pos
	specter["dash_to"] = pos
	specter["hit_uids"] = []
	specter["orbit"] = 0.0
	specter["facing"] = 1.0
	specter["trail"] = [pos, pos, pos, pos]
	specter["trail_clock"] = 0.0


func _set_state(specter: Dictionary, state: String) -> void:
	specter["state"] = state
	specter["state_time"] = 0.0


func _begin_collapse(specter: Dictionary) -> void:
	specter["life"] = 0.0
	_set_state(specter, "collapse")


func _orbit_step(specter: Dictionary, delta: float) -> void:
	specter["orbit"] = float(specter.get("orbit", 0.0)) + ORBIT_SPEED * delta
	var anchor: Vector2 = core.player_pos + Vector2.from_angle(float(specter["orbit"])) * ORBIT_RADIUS
	var pos: Vector2 = Vector2(specter["pos"])
	specter["pos"] = pos.lerp(anchor, 1.0 - exp(-5.0 * delta))


func _try_begin_dash(specter: Dictionary, claimed: Dictionary) -> bool:
	var pos: Vector2 = Vector2(specter["pos"])
	var best: Dictionary = {}
	var best_score := INF
	var radius_sq := SEEK_RADIUS * SEEK_RADIUS
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var d: float = pos.distance_squared_to(Vector2(enemy.get("pos", pos)))
		if d > radius_sq:
			continue
		# Prefere alvos que nenhum outro Eco esta perseguindo.
		var score: float = d * (3.0 if claimed.has(int(enemy.get("uid", -2))) else 1.0)
		if score < best_score:
			best_score = score
			best = enemy
	var target_pos: Vector2
	if not best.is_empty():
		target_pos = Vector2(best.get("pos", pos))
		specter["target_uid"] = int(best.get("uid", -1))
		claimed[int(specter["target_uid"])] = true
	elif bool(core.boss_active) and float(core.boss_hp) > 0.0 and pos.distance_to(core.boss_pos) <= SEEK_RADIUS:
		target_pos = core.boss_pos
		specter["target_uid"] = -1
	else:
		return false
	var dir: Vector2 = target_pos - pos
	if dir.length() < 4.0:
		dir = Vector2.from_angle(float(specter.get("phase", 0.0)))
	var length: float = clampf(dir.length() + DASH_OVERSHOOT, DASH_MIN_LENGTH, DASH_MAX_LENGTH)
	specter["dash_from"] = pos
	specter["dash_to"] = core._clamp_player_world(pos + dir.normalized() * length)
	specter["hit_uids"] = []
	specter["boss_hit"] = false
	specter["facing"] = -1.0 if dir.x < 0.0 else 1.0
	_set_state(specter, "dash")
	return true


func _dash_step(specter: Dictionary, delta: float) -> void:
	var from: Vector2 = Vector2(specter["pos"])
	var goal: Vector2 = Vector2(specter["dash_to"])
	var next: Vector2 = from.move_toward(goal, DASH_SPEED * delta)
	specter["pos"] = next
	_hit_segment(specter, from, next)
	if next.distance_to(goal) <= 0.5:
		if streaks.size() < STREAK_CAP:
			streaks.append({"a": Vector2(specter["dash_from"]), "b": next, "life": STREAK_LIFE, "max": STREAK_LIFE, "elite": bool(specter.get("elite", false))})
		_set_state(specter, "recover")


func _hit_segment(specter: Dictionary, a: Vector2, b: Vector2) -> void:
	if not core._is_world_authority():
		return
	var hit_uids: Array = specter.get("hit_uids", [])
	var damage: float = dash_damage(specter)
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var uid: int = int(enemy.get("uid", 0))
		if hit_uids.has(uid):
			continue
		var enemy_pos: Vector2 = Vector2(enemy.get("pos", a))
		if core._distance_to_segment(enemy_pos, a, b) > DASH_WIDTH + float(core._enemy_radius(enemy)) * 0.6:
			continue
		hit_uids.append(uid)
		_slow(enemy)
		core._spawn_radial_particles(enemy_pos, Color(0.5, 1.0, 0.86), 5)
		if core._damage_enemy(enemy, damage, core.RARE_SOURCE_NECRO, true, false, a, "necro_specter"):
			core._kill_enemy(enemy)
	specter["hit_uids"] = hit_uids
	if not bool(specter.get("boss_hit", false)) and bool(core.boss_active) and float(core.boss_hp) > 0.0 and core._distance_to_segment(core.boss_pos, a, b) <= DASH_WIDTH + 60.0:
		specter["boss_hit"] = true
		core._damage_boss(damage * BOSS_DAMAGE_MULT, core.RARE_SOURCE_NECRO, true, false, "necro_specter", a)


func _detonate(specter: Dictionary) -> void:
	var center: Vector2 = Vector2(specter["pos"])
	core.rare_card_effects.append({"kind": "necro_collapse", "pos": center, "life": 0.5, "max": 0.5, "radius": COLLAPSE_RADIUS})
	core._spawn_radial_particles(center, Color(0.62, 1.0, 0.9), 14)
	if not core._is_world_authority():
		return
	var damage: float = collapse_damage(specter)
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		if center.distance_to(Vector2(enemy.get("pos", center))) > COLLAPSE_RADIUS + float(core._enemy_radius(enemy)) * 0.5:
			continue
		_slow(enemy)
		if core._damage_enemy(enemy, damage, core.RARE_SOURCE_NECRO, true, false, center, "necro_specter"):
			core._kill_enemy(enemy)
	if bool(core.boss_active) and float(core.boss_hp) > 0.0 and center.distance_to(core.boss_pos) <= COLLAPSE_RADIUS + 60.0:
		core._damage_boss(damage * BOSS_DAMAGE_MULT, core.RARE_SOURCE_NECRO, true, false, "necro_specter", center)


func _slow(enemy: Dictionary) -> void:
	enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), SLOW_TIME)
	enemy["evolution_slow_mult"] = minf(float(enemy.get("evolution_slow_mult", 1.0)), SLOW_MULT)


func _sample_trail(specter: Dictionary, delta: float) -> void:
	specter["trail_clock"] = float(specter.get("trail_clock", 0.0)) + delta
	if float(specter["trail_clock"]) < AFTERIMAGE_SPACING:
		return
	specter["trail_clock"] = 0.0
	var trail: Array = specter.get("trail", [])
	trail.push_front(Vector2(specter["pos"]))
	while trail.size() > AFTERIMAGE_COUNT:
		trail.pop_back()
	specter["trail"] = trail
