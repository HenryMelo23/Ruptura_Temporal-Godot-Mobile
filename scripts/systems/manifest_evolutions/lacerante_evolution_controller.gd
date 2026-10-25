extends RefCounted
class_name RTLaceranteEvolutionController

# Bridges the five legacy projectile-shaped Lacerante contracts to its real
# melee hit route. State is choice-scoped, bounded and safe for run snapshots.

const EV1_HEMORRAGIA_CRESCENTE := "lacerante_ev1_hemorragia_crescente"
const EV1_CICATRIZ_ABERTA := "lacerante_ev1_cicatriz_aberta"
const EV1_PREDADOR_RUBRO := "lacerante_ev1_predador_rubro"
const EV2_CICATRIZ_PERSISTENTE := "lacerante_ev2_cicatriz_persistente"
const EV2_EXECUCAO_CADEIA := "lacerante_ev2_execucao_cadeia"

const MAX_WOUNDS := 6
const WOUND_TICKS := 3
const WOUND_INTERVAL := 0.50


static func is_active(game: Node) -> bool:
	if String(game.manifestation_key) != "lacerante":
		return false
	for choice_value in Array(game.manifest_evolution_state.get("choices", [])):
		var evolution_id := String(Dictionary(choice_value).get("evolution", ""))
		if evolution_id in [EV1_HEMORRAGIA_CRESCENTE, EV1_CICATRIZ_ABERTA, EV1_PREDADOR_RUBRO, EV2_CICATRIZ_PERSISTENTE, EV2_EXECUCAO_CADEIA]:
			return true
	return false


static func on_hit(game: Node, target: Dictionary, target_pos: Vector2) -> void:
	var ids := _active_ids(game)
	var state := _state(game)
	if ids.has(EV1_HEMORRAGIA_CRESCENTE):
		var hits := int(state.get("growing_hits", 0)) + 1
		state["growing_hits"] = hits
		if hits % 4 == 0:
			_damage_target(game, target, float(game.player_damage) * 0.34, "evolucao_lacerante_hemorragia")
			target["laceracao"] = int(target.get("laceracao", 0)) + 1
			_mark(state, EV1_HEMORRAGIA_CRESCENTE)
			_add_cut(game, game.player_pos, target_pos, Color(1.0, 0.12, 0.24))
	if ids.has(EV1_CICATRIZ_ABERTA):
		var pierced := _line_targets(game, target, target_pos, 190.0, 62.0, 2)
		for enemy_value in pierced:
			var enemy: Dictionary = Dictionary(enemy_value)
			_damage_target(game, enemy, float(game.player_damage) * 0.45, "evolucao_lacerante_cicatriz_aberta")
			_add_cut(game, target_pos, Vector2(enemy.get("pos", target_pos)), Color(1.0, 0.24, 0.30))
		if not pierced.is_empty():
			_mark(state, EV1_CICATRIZ_ABERTA)
	if ids.has(EV1_PREDADOR_RUBRO):
		var prey := _nearest_enemy(game, target, target_pos, 350.0)
		if not prey.is_empty():
			_damage_target(game, prey, float(game.player_damage) * 0.40, "evolucao_lacerante_predador")
			_add_cut(game, target_pos, Vector2(prey.get("pos", target_pos)), Color(0.96, 0.04, 0.18))
			_mark(state, EV1_PREDADOR_RUBRO)
	if ids.has(EV2_CICATRIZ_PERSISTENTE):
		var persistent_hits := int(state.get("persistent_hits", 0)) + 1
		state["persistent_hits"] = persistent_hits
		if persistent_hits % 3 == 0:
			_add_wound(state, str(target.get("uid", target.get("kind", ""))), target_pos)
			_mark(state, EV2_CICATRIZ_PERSISTENTE)
	if ids.has(EV2_EXECUCAO_CADEIA) and _is_execution_window(target):
		var chained := _nearest_enemies(game, target, target_pos, 260.0, 3)
		for enemy_value in chained:
			var enemy: Dictionary = Dictionary(enemy_value)
			_damage_target(game, enemy, float(game.player_damage) * 0.60, "evolucao_lacerante_execucao")
			_add_cut(game, target_pos, Vector2(enemy.get("pos", target_pos)), Color(1.0, 0.58, 0.18))
		if not chained.is_empty():
			_mark(state, EV2_EXECUCAO_CADEIA)
			game._play_sfx("atk_lacerante_3", 0.026, 0.82, 1.08)
	_store(game, state)


static func update_effects(game: Node, delta: float) -> void:
	var state := _state(game)
	var remaining: Array = []
	for wound_value in Array(state.get("wounds", [])):
		var wound: Dictionary = Dictionary(wound_value)
		wound["tick"] = float(wound.get("tick", WOUND_INTERVAL)) - delta
		if float(wound["tick"]) <= 0.0 and int(wound.get("ticks_left", 0)) > 0:
			wound["tick"] = WOUND_INTERVAL
			wound["ticks_left"] = int(wound.get("ticks_left", 0)) - 1
			var target := _target_by_uid(game, String(wound.get("uid", "")))
			if not target.is_empty():
				_damage_target(game, target, float(game.player_damage) * 0.18, "evolucao_lacerante_cicatriz_persistente")
				var pos := Vector2(target.get("pos", wound.get("pos", game.player_pos)))
				wound["pos"] = pos
				_add_cut(game, pos + Vector2(-18.0, -12.0), pos + Vector2(18.0, 12.0), Color(0.82, 0.02, 0.12))
		if int(wound.get("ticks_left", 0)) > 0:
			remaining.append(wound)
	state["wounds"] = remaining
	_store(game, state)


static func _active_ids(game: Node) -> Dictionary:
	var ids: Dictionary = {}
	for choice_value in Array(game.manifest_evolution_state.get("choices", [])):
		var evolution_id := String(Dictionary(choice_value).get("evolution", ""))
		if evolution_id != "":
			ids[evolution_id] = true
	return ids


static func _state(game: Node) -> Dictionary:
	var state := Dictionary(game.manifest_evolution_state.get("lacerante", {}))
	if state.is_empty():
		state = {"growing_hits": 0, "persistent_hits": 0, "wounds": [], "metrics": {}}
		game.manifest_evolution_state["lacerante"] = state
	return state


static func _store(game: Node, state: Dictionary) -> void:
	game.manifest_evolution_state["lacerante"] = state


static func _mark(state: Dictionary, evolution_id: String) -> void:
	var metrics: Dictionary = Dictionary(state.get("metrics", {}))
	metrics[evolution_id] = int(metrics.get(evolution_id, 0)) + 1
	state["metrics"] = metrics


static func _damage_target(game: Node, target: Dictionary, amount: float, source: String) -> void:
	var kind := String(target.get("kind", ""))
	if kind == "boss":
		game._damage_boss(amount * 0.45, source)
	elif kind == "arauto":
		game._damage_arauto(amount * 0.55, source, false)
	elif float(target.get("hp", 0.0)) > 0.0:
		game._damage_enemy(target, amount, source, false)


static func _line_targets(game: Node, source: Dictionary, origin: Vector2, reach: float, half_width: float, limit: int) -> Array:
	var direction := (origin - Vector2(game.player_pos)).normalized()
	if direction.length() <= 0.05:
		direction = Vector2(game.last_facing).normalized()
	var candidates: Array = []
	var source_uid := str(source.get("uid", source.get("kind", "")))
	for enemy_value in game.enemies:
		var enemy: Dictionary = Dictionary(enemy_value)
		if float(enemy.get("hp", 0.0)) <= 0.0 or str(enemy.get("uid", "")) == source_uid:
			continue
		var offset := Vector2(enemy.get("pos", origin)) - origin
		var forward := offset.dot(direction)
		if forward <= 0.0 or forward > reach or absf(offset.cross(direction)) > half_width:
			continue
		candidates.append({"target": enemy, "distance": forward})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary): return float(a["distance"]) < float(b["distance"]))
	var result: Array = []
	for candidate_value in candidates:
		result.append(Dictionary(candidate_value).get("target", {}))
		if result.size() >= limit:
			break
	return result


static func _nearest_enemy(game: Node, source: Dictionary, origin: Vector2, radius: float) -> Dictionary:
	var targets := _nearest_enemies(game, source, origin, radius, 1)
	return Dictionary(targets[0]) if not targets.is_empty() else {}


static func _nearest_enemies(game: Node, source: Dictionary, origin: Vector2, radius: float, limit: int) -> Array:
	var source_uid := str(source.get("uid", source.get("kind", "")))
	var candidates: Array = []
	for enemy_value in game.enemies:
		var enemy: Dictionary = Dictionary(enemy_value)
		if float(enemy.get("hp", 0.0)) <= 0.0 or str(enemy.get("uid", "")) == source_uid:
			continue
		var distance := origin.distance_to(Vector2(enemy.get("pos", origin)))
		if distance <= radius:
			candidates.append({"target": enemy, "distance": distance})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary): return float(a["distance"]) < float(b["distance"]))
	var result: Array = []
	for candidate_value in candidates:
		result.append(Dictionary(candidate_value).get("target", {}))
		if result.size() >= limit:
			break
	return result


static func _is_execution_window(target: Dictionary) -> bool:
	var hp := float(target.get("hp", 0.0))
	var max_hp := maxf(1.0, float(target.get("max_hp", hp)))
	return hp <= 0.0 or hp / max_hp <= 0.30


static func _add_wound(state: Dictionary, uid: String, pos: Vector2) -> void:
	if uid == "":
		return
	var wounds: Array = Array(state.get("wounds", []))
	for wound_value in wounds:
		var wound: Dictionary = Dictionary(wound_value)
		if String(wound.get("uid", "")) == uid:
			wound["ticks_left"] = WOUND_TICKS
			wound["tick"] = WOUND_INTERVAL
			wound["pos"] = pos
			state["wounds"] = wounds
			return
	if wounds.size() >= MAX_WOUNDS:
		wounds.pop_front()
	wounds.append({"uid": uid, "pos": pos, "ticks_left": WOUND_TICKS, "tick": WOUND_INTERVAL})
	state["wounds"] = wounds


static func _target_by_uid(game: Node, uid: String) -> Dictionary:
	if uid == "boss" and bool(game.boss_active) and float(game.boss_hp) > 0.0:
		return {"uid": "boss", "kind": "boss", "pos": game.boss_pos, "hp": game.boss_hp, "max_hp": game.boss_hp_max}
	if uid == "arauto" and game._arauto_active():
		return {"uid": "arauto", "kind": "arauto", "pos": game.arauto.get("pos", game.player_pos), "hp": game.arauto.get("hp", 0.0), "max_hp": game.arauto.get("max_hp", 1.0)}
	for enemy_value in game.enemies:
		var enemy: Dictionary = Dictionary(enemy_value)
		if str(enemy.get("uid", "")) == uid and float(enemy.get("hp", 0.0)) > 0.0:
			return enemy
	return {}


static func _add_cut(game: Node, from: Vector2, to: Vector2, color: Color) -> void:
	game.slashes.append({"a": from, "b": to, "life": 0.18, "max": 0.18, "color": color, "width": 7.0, "kind": "lacerante_evolution"})
