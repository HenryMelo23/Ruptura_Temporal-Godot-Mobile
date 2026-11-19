class_name RTGravitanteController
extends RefCounted

## Gravitante (rework 2026-11):
## - Passiva Massa Critica: cada ATK prende uma orbita no alvo (max. 3 por alvo). Com 3, o
##   alvo vira uma Estrela que puxa os inimigos em volta (agrupa a horda para o Q).
## - Q Colisao Gravitacional: os marcados sao puxados (0,3 s, sem teleporte) para o centro
##   de massa e colidem; o dano sobe por alvo e por orbita.
## - TP Poco de Partida: a origem vira um poco por 2,5 s que puxa e marca inimigos e
##   colapsa no fim.
## Orbitas continuam em core.orbitals (tick de dano em _update_orbitals).

const MAX_ORBITALS_PER_TARGET := 3
const ORBITAL_LIFE := 4.0
const ORBITAL_DAMAGE_RATIO := 0.18
const ORBITAL_BOSS_DAMAGE_RATIO := 0.14
const STAR_RADIUS := 120.0
const STAR_PULL_SPEED := 85.0
const STAR_ELITE_MULT := 0.5
const COLLISION_PULL_TIME := 0.3
const COLLISION_BASE := 1.1
const COLLISION_PER_TARGET := 0.22
const COLLISION_PER_EXTRA_ORBITAL := 0.3
const COLLISION_BOSS_MULT := 1.35
const COLLISION_PUSH_RADIUS := 190.0
const COLLISION_PUSH_SPEED := 520.0
const WELL_DURATION := 2.5
const WELL_RADIUS := 200.0
const WELL_PULL_MIN := 70.0
const WELL_PULL_MAX := 190.0
const WELL_COLLAPSE_RADIUS := 95.0
const WELL_COLLAPSE_BASE := 0.9
const WELL_COLLAPSE_PER_ORBITAL := 0.3
const WELL_MARK_CAP := 10
const PUSH_DRAG := 1500.0

var core: Node
var collisions: Array = []
var wells: Array = []
var pushes: Dictionary = {}


func configure(owner: Node) -> void:
	core = owner


func reset() -> void:
	collisions.clear()
	wells.clear()
	pushes.clear()


func _enabled() -> bool:
	return core != null and String(core.manifestation_key) == "gravitante"


# --- orbitas / massa -------------------------------------------------------------

func attach_orbital(target_kind: String, uid: int, pos: Vector2, bullet: Dictionary = {}) -> void:
	var existing: Array = []
	for orbital in core.orbitals:
		if float(orbital.get("life", 0.0)) > 0.0 and String(orbital.get("target_kind", "enemy")) == target_kind and (target_kind != "enemy" or int(orbital.get("enemy_uid", -1)) == uid):
			existing.append(orbital)
	if existing.size() >= MAX_ORBITALS_PER_TARGET:
		# Ja esta no limite: renova a mais antiga (sem empilhar infinito).
		var oldest: Dictionary = existing[0]
		for orbital in existing:
			if float(orbital["life"]) < float(oldest["life"]):
				oldest = orbital
		oldest["life"] = ORBITAL_LIFE
		return
	var boss_like: bool = target_kind != "enemy"
	var orbital := {
		"target_kind": target_kind,
		"enemy_uid": uid if target_kind == "enemy" else -1,
		"origin_pos": pos,
		"angle": core.rng.randf_range(0.0, TAU),
		"life": ORBITAL_LIFE,
		"tick": 0.1,
		"damage": float(core.player_damage) * (ORBITAL_BOSS_DAMAGE_RATIO if boss_like else ORBITAL_DAMAGE_RATIO),
		"sfx_cd": 0.0,
	}
	core.orbitals.append(orbital)
	if not bullet.is_empty():
		core.GravitanteVfx.capture(orbital, bullet)
	else:
		orbital["vfx_from"] = pos
		orbital["vfx_direction"] = Vector2.UP
		orbital["vfx_start_life"] = ORBITAL_LIFE
	if target_kind == "enemy" and existing.size() + 1 == MAX_ORBITALS_PER_TARGET:
		core.GravitanteVfx.push_event(core, {"kind": "gravity_star_birth", "pos": pos, "life": 0.5, "max": 0.5})


func mass_by_uid() -> Dictionary:
	var out: Dictionary = {}
	for orbital in core.orbitals:
		if float(orbital.get("life", 0.0)) <= 0.0 or String(orbital.get("target_kind", "enemy")) != "enemy":
			continue
		var uid: int = int(orbital.get("enemy_uid", -1))
		out[uid] = mini(MAX_ORBITALS_PER_TARGET, int(out.get(uid, 0)) + 1)
	return out


func boss_mass() -> int:
	var count := 0
	for orbital in core.orbitals:
		if float(orbital.get("life", 0.0)) > 0.0 and String(orbital.get("target_kind", "")) == "boss":
			count += 1
	return mini(MAX_ORBITALS_PER_TARGET, count)


## Inimigos com massa critica (para o VFX e o puxao).
func stars() -> Array:
	var out: Array = []
	var mass: Dictionary = mass_by_uid()
	for uid in mass.keys():
		if int(mass[uid]) >= MAX_ORBITALS_PER_TARGET:
			var enemy = core._enemy_by_uid(int(uid))
			if enemy != null and float(enemy.get("hp", 0.0)) > 0.0:
				out.append(enemy)
	return out


# --- loop ------------------------------------------------------------------------

func update(delta: float) -> void:
	if core == null:
		return
	_update_pushes(delta)
	_update_collisions(delta)
	_update_wells(delta)
	if not _enabled() or not core._is_world_authority():
		return
	var star_list: Array = stars()
	if star_list.is_empty():
		return
	var star_uids: Dictionary = {}
	for star in star_list:
		star_uids[int(star.get("uid", -1))] = true
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0 or star_uids.has(int(enemy.get("uid", -1))):
			continue
		var pos: Vector2 = Vector2(enemy["pos"])
		for star in star_list:
			var to_star: Vector2 = Vector2(star["pos"]) - pos
			var dist: float = to_star.length()
			if dist > STAR_RADIUS or dist < 26.0:
				continue
			var speed: float = STAR_PULL_SPEED * (STAR_ELITE_MULT if bool(core._is_uncommon_enemy(enemy)) else 1.0)
			enemy["pos"] = pos + to_star / dist * minf(dist - 24.0, speed * delta)
			break


func _update_pushes(delta: float) -> void:
	if pushes.is_empty():
		return
	for uid in pushes.keys():
		var enemy = core._enemy_by_uid(int(uid))
		var vel: Vector2 = pushes[uid]
		if enemy == null or vel.length() < 8.0:
			pushes.erase(uid)
			continue
		enemy["pos"] = (Vector2(enemy["pos"]) + vel * delta).clamp(Vector2(40, 40), core.WORLD_SIZE - Vector2(40, 40))
		pushes[uid] = vel.move_toward(Vector2.ZERO, PUSH_DRAG * delta)


func _push(enemy: Dictionary, dir: Vector2, speed: float) -> void:
	pushes[int(enemy.get("uid", -1))] = dir.normalized() * speed


# --- Q: colisao gravitacional ------------------------------------------------------

func begin_collision() -> bool:
	var mass: Dictionary = mass_by_uid()
	var bmass: int = boss_mass()
	var targets: Array = []
	var center := Vector2.ZERO
	var weight := 0.0
	for enemy in core.enemies:
		var uid: int = int(enemy.get("uid", -1))
		if not mass.has(uid) or float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var m: int = int(mass[uid])
		targets.append({"uid": uid, "from": Vector2(enemy["pos"]), "mass": m})
		center += Vector2(enemy["pos"]) * float(m)
		weight += float(m)
	if targets.is_empty() and bmass <= 0:
		core._add_text("MARQUE ALVOS COM ATK", core.player_pos + Vector2(0, -90), Color(0.7, 0.82, 1.0), 0.9, 18)
		return false
	if weight > 0.0:
		center /= weight
	else:
		center = core.boss_pos
	var points := PackedVector2Array()
	for t in targets:
		points.append(Vector2(t["from"]))
	collisions.append({"center": center, "targets": targets, "boss_mass": bmass, "t": 0.0, "points": points})
	core.GravitanteVfx.push_event(core, {"kind": "gravity_q_pull", "pos": center, "points": points, "life": COLLISION_PULL_TIME + 0.05, "max": COLLISION_PULL_TIME + 0.05})
	# As orbitas sao consumidas pela colisao.
	for orbital in core.orbitals:
		orbital["life"] = 0.0
	return true


func _update_collisions(delta: float) -> void:
	for collision in collisions:
		collision["t"] = float(collision["t"]) + delta
		var p: float = clampf(float(collision["t"]) / COLLISION_PULL_TIME, 0.0, 1.0)
		var eased: float = p * p
		var center: Vector2 = collision["center"]
		for t in collision["targets"]:
			var enemy = core._enemy_by_uid(int(t["uid"]))
			if enemy == null:
				continue
			var slot: Vector2 = center + Vector2.from_angle(float(int(t["uid"])) * 0.017) * 18.0
			enemy["pos"] = Vector2(t["from"]).lerp(slot, eased)
			enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), 0.3)
		if p >= 1.0 and not bool(collision.get("done", false)):
			collision["done"] = true
			_resolve_collision(collision)
	collisions = collisions.filter(func(c): return not bool(c.get("done", false)))


func _resolve_collision(collision: Dictionary) -> void:
	var center: Vector2 = collision["center"]
	var targets: Array = collision["targets"]
	var count: int = targets.size()
	var hit_uids: Dictionary = {}
	core.GravitanteVfx.collision(core, targets.map(func(t): return {"pos": center}), center)
	for t in targets:
		var enemy = core._enemy_by_uid(int(t["uid"]))
		if enemy == null:
			continue
		hit_uids[int(t["uid"])] = true
		enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), 0.55)
		var ratio: float = COLLISION_BASE + COLLISION_PER_TARGET * float(count) + COLLISION_PER_EXTRA_ORBITAL * float(int(t["mass"]) - 1)
		core._damage_enemy(enemy, float(core.player_damage) * ratio, "gravitante", true, true, center, "skill_q")
	for enemy in core.enemies:
		if hit_uids.has(int(enemy.get("uid", -1))) or float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var offset: Vector2 = Vector2(enemy["pos"]) - center
		if offset.length() <= COLLISION_PUSH_RADIUS:
			_push(enemy, offset if offset.length() > 0.01 else Vector2.RIGHT, COLLISION_PUSH_SPEED)
			enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), 0.24)
	var bmass: int = int(collision.get("boss_mass", 0))
	if bmass > 0 and bool(core.boss_active) and float(core.boss_hp) > 0.0:
		core._damage_boss(float(core.player_damage) * (COLLISION_BOSS_MULT + COLLISION_PER_EXTRA_ORBITAL * float(bmass - 1)), "gravitante", true, true, "skill_q", center)
	core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.18)
	core.screen_shake_strength = maxf(float(core.screen_shake_strength), 7.0)
	core._add_text("COLISAO GRAVITACIONAL x%d" % (count + (1 if bmass > 0 else 0)), center + Vector2(0, -92), Color(0.6, 0.82, 1.0), 1.1, 22)


# --- TP: poco de partida ------------------------------------------------------------

func begin_well(origin: Vector2) -> void:
	wells.append({"pos": origin, "life": WELL_DURATION, "max": WELL_DURATION, "marked": {}})
	core._add_text("POCO DE PARTIDA", origin + Vector2(0, -96), Color(0.52, 0.78, 1.0), 0.9, 18)


func _update_wells(delta: float) -> void:
	if wells.is_empty():
		return
	var authority: bool = core._is_world_authority()
	for well in wells:
		well["life"] = float(well["life"]) - delta
		var center: Vector2 = well["pos"]
		if authority:
			var marked: Dictionary = well["marked"]
			for enemy in core.enemies:
				if float(enemy.get("hp", 0.0)) <= 0.0:
					continue
				var to_center: Vector2 = center - Vector2(enemy["pos"])
				var dist: float = to_center.length()
				if dist > WELL_RADIUS or dist < 10.0:
					continue
				var speed: float = lerpf(WELL_PULL_MAX, WELL_PULL_MIN, dist / WELL_RADIUS) * (0.6 if bool(core._is_uncommon_enemy(enemy)) else 1.0)
				enemy["pos"] = Vector2(enemy["pos"]) + to_center / dist * minf(dist - 8.0, speed * delta)
				var uid: int = int(enemy.get("uid", -1))
				if not marked.has(uid) and marked.size() < WELL_MARK_CAP:
					marked[uid] = true
					attach_orbital("enemy", uid, Vector2(enemy["pos"]))
		if float(well["life"]) <= 0.0 and not bool(well.get("collapsed", false)):
			well["collapsed"] = true
			_collapse_well(well)
	wells = wells.filter(func(w): return not bool(w.get("collapsed", false)))


func _collapse_well(well: Dictionary) -> void:
	var center: Vector2 = well["pos"]
	core.GravitanteVfx.push_event(core, {"kind": "gravity_well_collapse", "pos": center, "life": 0.5, "max": 0.5})
	if not core._is_world_authority():
		return
	var mass: Dictionary = mass_by_uid()
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var offset: Vector2 = Vector2(enemy["pos"]) - center
		if offset.length() > WELL_COLLAPSE_RADIUS:
			continue
		var m: int = int(mass.get(int(enemy.get("uid", -1)), 0))
		core._damage_enemy(enemy, float(core.player_damage) * (WELL_COLLAPSE_BASE + WELL_COLLAPSE_PER_ORBITAL * float(m)), "gravitante", true, true, center, "teleport")
		_push(enemy, offset if offset.length() > 0.01 else Vector2.from_angle(float(enemy.get("uid", 0))), 260.0)
	if bool(core.boss_active) and float(core.boss_hp) > 0.0 and core.boss_pos.distance_to(center) <= WELL_COLLAPSE_RADIUS + 60.0:
		core._damage_boss(float(core.player_damage) * WELL_COLLAPSE_BASE, "gravitante", true, true, "teleport", center)
