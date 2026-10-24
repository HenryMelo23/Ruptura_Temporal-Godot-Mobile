class_name RTReactiveSurvivalCardController
extends RefCounted

## Runtime owner for Fragmentacao Reativa and Bastiao Inercial. The owner keeps
## moving fragment state outside the monolithic runtime and exposes only the
## two values the player loop needs: stationary armor and movement speed.

const FRAGMENT_CARD_ID := "fragmentacao_reativa"
const BASTION_CARD_ID := "bastiao_inercial"
const FRAGMENT_SOURCE := "card_fragmentacao_reativa"

const FRAGMENT_BASE_RADIUS := 150.0
const FRAGMENT_RADIUS_PER_COPY := 30.0
const FRAGMENT_BASE_DAMAGE_RATIO := 0.36
const FRAGMENT_DAMAGE_RATIO_PER_COPY := 0.14
const FRAGMENT_TARGET_COUNT := 4
const FRAGMENT_SPEED := 560.0
const FRAGMENT_HIT_RADIUS := 13.0
const FRAGMENT_LIFETIME := 0.72
const FRAGMENT_LIMIT := 32

const BASTION_SETTLE_TIME := 0.70
const BASTION_ARMOR_PER_COPY := 6.0
const BASTION_MOVE_SPEED_PER_COPY := 0.015
const BASTION_MOVE_EPSILON := 1.5

var core: Node
var fragments: Array = []
var stationary_time := 0.0
var stationary_strength := 0.0
var last_player_pos := Vector2.ZERO
var position_initialized := false


func configure(runtime_core: Node) -> void:
	core = runtime_core
	last_player_pos = Vector2(core.player_pos)
	position_initialized = true


func reset() -> void:
	fragments.clear()
	stationary_time = 0.0
	stationary_strength = 0.0
	position_initialized = false
	if core != null:
		last_player_pos = Vector2(core.player_pos)


func fragment_card_count() -> int:
	return _card_count(FRAGMENT_CARD_ID)


func bastion_card_count() -> int:
	return _card_count(BASTION_CARD_ID)


func fragment_radius(count: int = -1) -> float:
	var copies := fragment_card_count() if count < 0 else count
	return FRAGMENT_BASE_RADIUS + FRAGMENT_RADIUS_PER_COPY * float(maxi(0, copies - 1))


func fragment_damage_ratio(count: int = -1) -> float:
	var copies := fragment_card_count() if count < 0 else count
	if copies <= 0:
		return 0.0
	return FRAGMENT_BASE_DAMAGE_RATIO + FRAGMENT_DAMAGE_RATIO_PER_COPY * float(copies - 1)


func stationary_armor() -> float:
	return float(bastion_card_count()) * BASTION_ARMOR_PER_COPY * stationary_strength


func movement_speed_multiplier() -> float:
	return 1.0 + float(bastion_card_count()) * BASTION_MOVE_SPEED_PER_COPY


func on_player_damaged(actual_hp_damage: float) -> void:
	var copies := fragment_card_count()
	if core == null or copies <= 0 or actual_hp_damage <= 0.0:
		return
	var origin := Vector2(core.player_pos)
	var radius := fragment_radius(copies)
	var damage := maxf(1.0, float(core.player_damage) * fragment_damage_ratio(copies))
	var candidates := _targets_in_radius(origin, radius)
	var launch_count := mini(FRAGMENT_TARGET_COUNT, candidates.size())
	for index in range(launch_count):
		if fragments.size() >= FRAGMENT_LIMIT:
			break
		var candidate: Dictionary = candidates[index]
		fragments.append({
			"pos": origin,
			"origin": origin,
			"target_kind": String(candidate.get("kind", "")),
			"target_uid": int(candidate.get("uid", 0)),
			"target_ref": candidate.get("enemy", {}),
			"target_pos": Vector2(candidate.get("pos", origin)),
			"damage": damage,
			"life": FRAGMENT_LIFETIME,
			"max": FRAGMENT_LIFETIME,
			"seed": float(index) * 1.73 + float(core.time_alive),
		})
	if launch_count > 0:
		core.common_card_effects.append({"kind": "fragmentacao_reativa", "pos": origin,
			"life": 0.5, "max": 0.5, "radius": radius, "color": Color(0.92, 0.12, 0.28)})


func update(delta: float) -> void:
	if core == null:
		return
	_update_stationary_state(delta)
	_update_fragments(delta)


func _update_stationary_state(delta: float) -> void:
	var copies := bastion_card_count()
	var current_pos := Vector2(core.player_pos)
	if not position_initialized:
		last_player_pos = current_pos
		position_initialized = true
	var moved := current_pos.distance_to(last_player_pos) > BASTION_MOVE_EPSILON
	last_player_pos = current_pos
	if copies <= 0 or bool(core.is_dead):
		stationary_time = 0.0
		stationary_strength = move_toward(stationary_strength, 0.0, delta * 5.0)
		return
	if moved:
		stationary_time = 0.0
		stationary_strength = move_toward(stationary_strength, 0.0, delta * 6.0)
	else:
		stationary_time += delta
		var target_strength := 1.0 if stationary_time >= BASTION_SETTLE_TIME else 0.0
		stationary_strength = move_toward(stationary_strength, target_strength, delta * 3.5)


func _update_fragments(delta: float) -> void:
	for index in range(fragments.size() - 1, -1, -1):
		var fragment: Dictionary = fragments[index]
		fragment["life"] = float(fragment.get("life", 0.0)) - delta
		if float(fragment["life"]) <= 0.0:
			fragments.remove_at(index)
			continue
		var target_data := _live_target(fragment)
		if target_data.is_empty():
			fragments.remove_at(index)
			continue
		var target_pos := Vector2(target_data.get("pos", fragment.get("target_pos", fragment.get("pos", Vector2.ZERO))))
		fragment["target_pos"] = target_pos
		var current_pos := Vector2(fragment.get("pos", target_pos))
		var distance := current_pos.distance_to(target_pos)
		var step := FRAGMENT_SPEED * delta
		if distance <= step + FRAGMENT_HIT_RADIUS:
			_resolve_fragment_hit(fragment, target_data)
			core._spawn_radial_particles(target_pos, Color(0.88, 0.14, 0.28), 4)
			fragments.remove_at(index)
			continue
		fragment["pos"] = current_pos.move_toward(target_pos, step)
		fragments[index] = fragment


func _targets_in_radius(origin: Vector2, radius: float) -> Array:
	var result: Array = []
	for enemy in core.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var pos := Vector2(enemy.get("pos", origin))
		var distance := origin.distance_to(pos)
		if distance <= radius:
			result.append({"kind": "enemy", "enemy": enemy, "uid": int(enemy.get("uid", 0)), "pos": pos, "distance": distance})
	if core._arauto_active():
		var arauto_pos := Vector2(core.arauto.get("pos", origin))
		var arauto_distance := origin.distance_to(arauto_pos)
		if arauto_distance <= radius:
			result.append({"kind": "arauto", "uid": -2, "pos": arauto_pos, "distance": arauto_distance})
	if bool(core.boss_active) and float(core.boss_hp) > 0.0:
		var boss_distance := origin.distance_to(Vector2(core.boss_pos))
		if boss_distance <= radius:
			result.append({"kind": "boss", "uid": -1, "pos": Vector2(core.boss_pos), "distance": boss_distance})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("distance", INF)) < float(b.get("distance", INF)))
	return result


func _live_target(fragment: Dictionary) -> Dictionary:
	match String(fragment.get("target_kind", "")):
		"enemy":
			var enemy: Dictionary = fragment.get("target_ref", {})
			if not enemy.is_empty() and float(enemy.get("hp", 0.0)) > 0.0:
				return {"kind": "enemy", "enemy": enemy, "pos": Vector2(enemy.get("pos", fragment.get("target_pos", Vector2.ZERO)))}
		"boss":
			if bool(core.boss_active) and float(core.boss_hp) > 0.0:
				return {"kind": "boss", "pos": Vector2(core.boss_pos)}
		"arauto":
			if core._arauto_active():
				return {"kind": "arauto", "pos": Vector2(core.arauto.get("pos", fragment.get("target_pos", Vector2.ZERO)))}
	return {}


func _resolve_fragment_hit(fragment: Dictionary, target: Dictionary) -> void:
	var damage := float(fragment.get("damage", 0.0))
	var origin := Vector2(fragment.get("origin", core.player_pos))
	match String(target.get("kind", "")):
		"enemy":
			core._damage_enemy(target.get("enemy", {}), damage, FRAGMENT_SOURCE, false, false, origin, "common_card")
		"boss":
			core._damage_boss(damage, FRAGMENT_SOURCE, false, true, "common_card", origin)
		"arauto":
			core._damage_arauto(damage, FRAGMENT_SOURCE, false, false, "common_card", origin)


func _card_count(card_id: String) -> int:
	if core == null:
		return 0
	return maxi(0, int(core.cards_bought.get(card_id, 0)))
