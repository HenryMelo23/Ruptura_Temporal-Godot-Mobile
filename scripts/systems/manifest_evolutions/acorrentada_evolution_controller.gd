extends RefCounted
class_name RTAcorrentadaEvolutionController

# Acorrentada is a melee/link manifestation. Its evolution contracts therefore
# consume resolved combo, tension, Q/E and teleport events rather than borrowing
# projectile presets. Persistent collections and target scans are hard-capped.

const EV1_CORRENTE_TRIPLA := "acorrentada_ev1_corrente_tripla"
const EV1_TENSAO_RESIDUAL := "acorrentada_ev1_tensao_residual"
const EV1_GRILHAO_MOVEL := "acorrentada_ev1_grilhao_movel"
const EV1_ELO_ESPELHADO := "acorrentada_ev1_elo_espelhado"
const EV1_ANCORA_CORRENTE := "acorrentada_ev1_ancora_corrente"
const EV1_SOBRETENSAO_CONTINUA := "acorrentada_ev1_sobretensao_continua"
const EV2_TEIA_GRILHOES := "acorrentada_ev2_teia_grilhoes"
const EV2_RUPTURA_SEQUENCIAL := "acorrentada_ev2_ruptura_sequencial"
const EV2_CORRENTE_ARRASTO := "acorrentada_ev2_corrente_arrasto"
const EV2_PRISAO_TOTAL := "acorrentada_ev2_prisao_total"
const EV2_SOBRECARGA_TENSAO := "acorrentada_ev2_sobrecarga_tensao"
const EV2_SENTENCA_FERRO := "acorrentada_ev2_sentenca_ferro"

const MAX_SHACKLES := 2
const MAX_ANCHORS := 2
const MAX_WEB_TARGETS := 4
const MAX_SEQUENCE_EVENTS := 6
const MAX_VERDICTS := 6
const COLOR_COLD := Color(0.18, 0.86, 1.0)
const COLOR_HOT := Color(0.96, 0.16, 0.12)
const COLOR_IRON := Color(0.72, 0.68, 0.60)


static func is_active(game: Node) -> bool:
	if String(game.manifestation_key) != "acorrentada":
		return false
	for choice_value in Array(game.manifest_evolution_state.get("choices", [])):
		if String(Dictionary(choice_value).get("evolution", "")).begins_with("acorrentada_ev"):
			return true
	return false


static func _ids(game: Node) -> Dictionary:
	var ids: Dictionary = {}
	for choice_value in Array(game.manifest_evolution_state.get("choices", [])):
		var evolution_id := String(Dictionary(choice_value).get("evolution", ""))
		if evolution_id != "":
			ids[evolution_id] = true
	return ids


static func _has(ids: Dictionary, evolution_id: String) -> bool:
	return bool(ids.get(evolution_id, false))


static func _state(game: Node) -> Dictionary:
	var state: Dictionary = Dictionary(game.manifest_evolution_state.get("acorrentada", {}))
	if state.is_empty():
		state = {
			"residual": 0.0,
			"shackles": [],
			"anchors": [],
			"webs": [],
			"sequence_buffer": [],
			"ruptures": [],
			"verdicts": {},
			"mirror_cooldowns": {},
			"prison_cooldown": 0.0,
			"overload_timer": 0.0,
			"overload_gate": 0.0,
			"continuous_tick": 1.0,
			"metrics": {}
		}
		game.manifest_evolution_state["acorrentada"] = state
	return state


static func _store(game: Node, state: Dictionary) -> void:
	game.manifest_evolution_state["acorrentada"] = state


static func _metric(state: Dictionary, key: String, amount: int = 1) -> void:
	var metrics: Dictionary = Dictionary(state.get("metrics", {}))
	metrics[key] = int(metrics.get(key, 0)) + amount
	state["metrics"] = metrics


static func debug_snapshot(game: Node) -> Dictionary:
	return _state(game).duplicate(true)


static func on_tension_added(game: Node, amount: float) -> void:
	if amount <= 0.0 or not is_active(game):
		return
	var ids := _ids(game)
	var state := _state(game)
	if _has(ids, EV1_TENSAO_RESIDUAL):
		state["residual"] = minf(30.0, float(state.get("residual", 0.0)) + amount * 0.35)
		_metric(state, EV1_TENSAO_RESIDUAL)
	_store(game, state)


static func on_overcharge_consumed(game: Node) -> void:
	if not is_active(game):
		return
	var ids := _ids(game)
	var state := _state(game)
	if _has(ids, EV1_TENSAO_RESIDUAL):
		var residual := clampf(float(state.get("residual", 0.0)), 0.0, 30.0)
		if residual > 0.0:
			game.acorrentada_tension = minf(100.0, float(game.acorrentada_tension) + residual)
			game.acorrentada_overcharge_ready = float(game.acorrentada_tension) >= 100.0
			state["residual"] = 0.0
			_metric(state, EV1_TENSAO_RESIDUAL)
			game._add_text("TENSAO RESIDUAL +%d" % int(round(residual)), game.player_pos + Vector2(0, -118), COLOR_COLD, 0.8, 17)
	if _has(ids, EV2_SOBRECARGA_TENSAO):
		state["overload_timer"] = 4.0
		state["overload_gate"] = 0.0
		_metric(state, EV2_SOBRECARGA_TENSAO)
		game._add_text("SOBRECARGA CONDUTORA", game.player_pos + Vector2(0, -138), COLOR_HOT, 0.9, 19)
		game._play_sfx("acorrentada_hit_3", 0.04, 0.92, 1.12)
	_store(game, state)


static func on_combo_resolved(game: Node, stage: int, primary: Dictionary, impact: Vector2, event_id: String) -> void:
	if stage != 3 or not is_active(game):
		return
	var ids := _ids(game)
	if not _has(ids, EV1_CORRENTE_TRIPLA):
		return
	var excluded := _target_key(primary)
	var extra: Dictionary = {}
	for candidate_value in game._acorrentada_targets_near(impact, 210.0, 8, true):
		var candidate := Dictionary(candidate_value)
		if _target_key(candidate) == excluded or not game._acorrentada_target_alive(candidate):
			continue
		extra = _target_descriptor(candidate)
		break
	if extra.is_empty():
		return
	var extra_pos: Vector2 = Vector2(game._acorrentada_target_pos(extra))
	game._acorrentada_damage_target(extra, float(game.player_damage) * 0.46, "acorrentada_ev1_corrente_tripla", "manifestation_secondary", game.player_pos)
	game._acorrentada_apply_elo_to_target(extra, 1)
	game.acorrentada_visuals.append({"kind": "light", "a": game.player_pos, "b": extra_pos, "life": 0.42, "max": 0.42})
	game._play_sfx("acorrentada_hit_3", 0.025, 0.82, 1.18)
	# The third segment is a real resolved hit, so the selected EV2 may consume
	# it (sequence, overload or verdict) through the same typed hook.
	game._manifest_evolution_on_combat_hit("%s:third:%s" % [event_id, _target_key(extra)], "acorrentada_corrente_tripla", extra, extra_pos)
	var state := _state(game)
	state["last_triple_event"] = "%s:third:%s" % [event_id, _target_key(extra)]
	_metric(state, EV1_CORRENTE_TRIPLA)
	_store(game, state)


static func on_hit(game: Node, event_id: String, target: Dictionary, target_pos: Vector2) -> void:
	if target.is_empty() or not is_active(game):
		return
	var ids := _ids(game)
	var state := _state(game)
	var descriptor := _target_descriptor(target)
	if _has(ids, EV1_GRILHAO_MOVEL):
		_add_mobile_shackle(state, descriptor, target_pos)
		game._acorrentada_apply_elo_to_target(descriptor, 1)
		_metric(state, EV1_GRILHAO_MOVEL)
	if _has(ids, EV1_ELO_ESPELHADO):
		_try_mirror_hit(game, state, descriptor, target_pos)
	if _has(ids, EV2_RUPTURA_SEQUENCIAL):
		_queue_sequential_rupture(state, descriptor, target_pos, event_id)
	if _has(ids, EV2_SOBRECARGA_TENSAO) and float(state.get("overload_timer", 0.0)) > 0.0 and float(state.get("overload_gate", 0.0)) <= 0.0:
		_conduct_overload(game, state, descriptor, target_pos)
	if _has(ids, EV2_SENTENCA_FERRO):
		_consume_verdict(game, state, descriptor, target_pos)
	_store(game, state)


static func on_skill(game: Node, center: Vector2) -> bool:
	if not is_active(game):
		return false
	var ids := _ids(game)
	var state := _state(game)
	var triggered := false
	if _has(ids, EV1_ANCORA_CORRENTE):
		var anchors: Array = Array(state.get("anchors", []))
		while anchors.size() >= MAX_ANCHORS:
			anchors.pop_front()
		anchors.append({"pos": center, "life": 5.0, "max": 5.0, "tick": 0.0, "flash": 0.3})
		state["anchors"] = anchors
		_metric(state, EV1_ANCORA_CORRENTE)
		triggered = true
	if _has(ids, EV2_TEIA_GRILHOES):
		var nodes: Array = []
		for target_value in game._acorrentada_targets_near(center, 260.0, MAX_WEB_TARGETS, true):
			var target := Dictionary(target_value)
			if game._acorrentada_target_alive(target):
				nodes.append(_target_descriptor(target))
		if nodes.size() >= 2:
			state["webs"] = [{"nodes": nodes, "life": 4.5, "max": 4.5, "tick": 0.0, "flash": 0.35}]
			_metric(state, EV2_TEIA_GRILHOES)
			triggered = true
	if _has(ids, EV2_PRISAO_TOTAL) and float(state.get("prison_cooldown", 0.0)) <= 0.0:
		var imprisoned := 0
		for target_value in game._acorrentada_targets_near(center, 245.0, 5, true):
			var target := Dictionary(target_value)
			if not game._acorrentada_target_alive(target):
				continue
			_apply_prison(game, target)
			imprisoned += 1
		if imprisoned > 0:
			state["prison_cooldown"] = 7.0
			state["prison_flash"] = 0.55
			state["prison_center"] = center
			_metric(state, EV2_PRISAO_TOTAL, imprisoned)
			triggered = true
	if triggered:
		game._play_sfx("skill_acorrentada", 0.035, 0.84, 1.08)
		game._add_text("GRILHOES EVOLUIDOS", center + Vector2(0, -98), COLOR_COLD, 0.8, 18)
	_store(game, state)
	return triggered


static func on_teleport(game: Node, origin: Vector2, destination: Vector2) -> void:
	if not is_active(game) or not _has(_ids(game), EV2_CORRENTE_ARRASTO):
		return
	var state := _state(game)
	var midpoint := (origin + destination) * 0.5
	var search_radius := origin.distance_to(destination) * 0.5 + 84.0
	var moved := 0
	for target_value in game._acorrentada_targets_near(midpoint, search_radius, 12, false):
		if moved >= 5:
			break
		var target := Dictionary(target_value)
		var target_pos: Vector2 = Vector2(game._acorrentada_target_pos(target))
		if _distance_to_segment(target_pos, origin, destination) > 72.0:
			continue
		var enemy = game._enemy_by_uid(int(target.get("uid", -1)))
		if enemy == null:
			continue
		var old_pos := Vector2(enemy.get("pos", target_pos))
		var travel := minf(160.0, old_pos.distance_to(destination) * 0.55)
		enemy["pos"] = old_pos.move_toward(destination, travel).clamp(Vector2(40, 40), game.WORLD_SIZE - Vector2(40, 40))
		enemy["acorrentada_slow"] = maxf(float(enemy.get("acorrentada_slow", 0.0)), 0.55)
		game.acorrentada_visuals.append({"kind": "heavy", "a": old_pos, "b": Vector2(enemy["pos"]), "life": 0.38, "max": 0.38})
		moved += 1
	if bool(game.boss_active) and float(game.boss_hp) > 0.0 and _distance_to_segment(Vector2(game.boss_pos), origin, destination) <= 112.0:
		game.boss_tp_stun_timer = maxf(float(game.boss_tp_stun_timer), 0.12)
		game.acorrentada_visuals.append({"kind": "light", "a": origin, "b": game.boss_pos, "life": 0.28, "max": 0.28})
	if moved > 0:
		_metric(state, EV2_CORRENTE_ARRASTO, moved)
		game._play_sfx("acorrentada_hit_2", 0.03, 0.78, 0.94)
	_store(game, state)


static func on_sentence_started(game: Node, secondary: Dictionary) -> void:
	if not is_active(game) or not _has(_ids(game), EV2_SENTENCA_FERRO):
		return
	var state := _state(game)
	var verdicts: Dictionary = {}
	for target_value in Array(secondary.get("targets", [])):
		if verdicts.size() >= MAX_VERDICTS:
			break
		var target := Dictionary(target_value)
		if game._acorrentada_target_alive(target):
			var descriptor := _target_descriptor(target)
			verdicts[_target_key(descriptor)] = {"target": descriptor, "life": 4.0, "max": 4.0}
	state["verdicts"] = verdicts
	if not verdicts.is_empty():
		_metric(state, EV2_SENTENCA_FERRO)
		game._add_text("SENTENCA DE FERRO", Vector2(secondary.get("center", game.player_pos)) + Vector2(0, -118), COLOR_IRON, 0.9, 20)
	_store(game, state)


static func update_effects(game: Node, delta: float) -> void:
	if not is_active(game):
		return
	var ids := _ids(game)
	var state := _state(game)
	state["prison_cooldown"] = maxf(0.0, float(state.get("prison_cooldown", 0.0)) - delta)
	state["overload_timer"] = maxf(0.0, float(state.get("overload_timer", 0.0)) - delta)
	state["overload_gate"] = maxf(0.0, float(state.get("overload_gate", 0.0)) - delta)
	state["prison_flash"] = maxf(0.0, float(state.get("prison_flash", 0.0)) - delta)
	_update_cooldowns(state, delta)
	_update_shackles(game, state, delta)
	_update_anchors(game, state, delta)
	_update_webs(game, state, delta)
	_update_ruptures(game, state, delta)
	_update_verdicts(state, delta)
	if _has(ids, EV1_SOBRETENSAO_CONTINUA):
		_update_continuous_tension(game, state, delta)
	_store(game, state)


static func draw_world(game: Node2D, camera: Vector2) -> void:
	if not is_active(game):
		return
	var state := _state(game)
	var now := float(Time.get_ticks_msec()) * 0.001
	for shackle_value in Array(state.get("shackles", [])):
		var shackle := Dictionary(shackle_value)
		var target := Dictionary(shackle.get("target", {}))
		if not game._acorrentada_target_alive(target):
			continue
		var target_pos: Vector2 = Vector2(game._acorrentada_target_pos(target))
		var fade := clampf(float(shackle.get("life", 0.0)) / 0.7, 0.0, 1.0)
		game._draw_acorrentada_chain(game.player_pos - camera, target_pos - camera, Color(COLOR_COLD, 0.62), 5.0, fade, true)
		game.draw_arc(target_pos - camera, 29.0 + sin(now * 7.0) * 3.0, 0.0, TAU, 24, Color(COLOR_COLD, 0.72 * fade), 2.4)
	for anchor_value in Array(state.get("anchors", [])):
		var anchor := Dictionary(anchor_value)
		var pos := Vector2(anchor.get("pos", game.player_pos)) - camera
		var fade := clampf(float(anchor.get("life", 0.0)) / 0.8, 0.0, 1.0)
		game.draw_arc(pos, 34.0 + sin(now * 5.0) * 4.0, -now, TAU - now, 30, Color(COLOR_IRON, 0.78 * fade), 4.0)
		game.draw_circle(pos, 7.0, Color(COLOR_HOT, 0.58 * fade))
	for web_value in Array(state.get("webs", [])):
		var web := Dictionary(web_value)
		var nodes := _living_node_positions(game, Array(web.get("nodes", [])))
		var fade := clampf(float(web.get("life", 0.0)) / 0.8, 0.0, 1.0)
		for i in range(nodes.size()):
			for j in range(i + 1, nodes.size()):
				game._draw_acorrentada_chain(Vector2(nodes[i]) - camera, Vector2(nodes[j]) - camera, Color(COLOR_HOT, 0.76), 6.5, fade, false)
	for rupture_value in Array(state.get("ruptures", [])):
		var rupture := Dictionary(rupture_value)
		var pos: Vector2 = _target_position(game, Dictionary(rupture.get("target", {})), Vector2(rupture.get("pos", game.player_pos))) - camera
		var ratio := clampf(float(rupture.get("delay", 0.0)) / 0.5, 0.0, 1.0)
		game.draw_arc(pos, 30.0 + ratio * 34.0, 0.0, TAU, 32, Color(COLOR_HOT, 0.82), 3.0)
	for verdict_value in Dictionary(state.get("verdicts", {})).values():
		var verdict := Dictionary(verdict_value)
		var target := Dictionary(verdict.get("target", {}))
		if game._acorrentada_target_alive(target):
			var pos: Vector2 = Vector2(game._acorrentada_target_pos(target)) - camera
			game.draw_arc(pos, 42.0, now * 1.8, now * 1.8 + PI * 1.55, 34, Color(COLOR_IRON, 0.84), 3.5)
	if float(state.get("overload_timer", 0.0)) > 0.0:
		game.draw_arc(game.player_pos - camera, 54.0 + sin(now * 10.0) * 5.0, 0.0, TAU, 40, Color(COLOR_HOT, 0.68), 3.0)


static func _add_mobile_shackle(state: Dictionary, target: Dictionary, target_pos: Vector2) -> void:
	var shackles: Array = Array(state.get("shackles", []))
	var key := _target_key(target)
	for shackle_value in shackles:
		var shackle := Dictionary(shackle_value)
		if _target_key(Dictionary(shackle.get("target", {}))) == key:
			shackle["life"] = 4.2
			shackle["pos"] = target_pos
			state["shackles"] = shackles
			return
	while shackles.size() >= MAX_SHACKLES:
		shackles.pop_front()
	shackles.append({"target": target, "pos": target_pos, "life": 4.2, "max": 4.2, "tick": 0.0})
	state["shackles"] = shackles


static func _try_mirror_hit(game: Node, state: Dictionary, source: Dictionary, source_pos: Vector2) -> void:
	var cooldowns: Dictionary = Dictionary(state.get("mirror_cooldowns", {}))
	var source_key := _target_key(source)
	if float(cooldowns.get(source_key, 0.0)) > 0.0:
		return
	for candidate_value in game._acorrentada_targets_near(source_pos, 240.0, 8, true):
		var candidate := Dictionary(candidate_value)
		if _target_key(candidate) == source_key or not game._acorrentada_target_alive(candidate):
			continue
		var target := _target_descriptor(candidate)
		var target_pos: Vector2 = Vector2(game._acorrentada_target_pos(target))
		game._acorrentada_damage_target(target, float(game.player_damage) * 0.22, "acorrentada_ev1_elo_espelhado", "manifestation_secondary", source_pos)
		game._acorrentada_apply_elo_to_target(target, 1)
		game.acorrentada_visuals.append({"kind": "light", "a": source_pos, "b": target_pos, "life": 0.30, "max": 0.30})
		cooldowns[source_key] = 0.35
		state["mirror_cooldowns"] = cooldowns
		_metric(state, EV1_ELO_ESPELHADO)
		return


static func _queue_sequential_rupture(state: Dictionary, target: Dictionary, target_pos: Vector2, event_id: String) -> void:
	var buffer: Array = Array(state.get("sequence_buffer", []))
	buffer.append({"target": target, "pos": target_pos, "event_id": event_id})
	if buffer.size() < 3:
		state["sequence_buffer"] = buffer
		return
	var ruptures: Array = Array(state.get("ruptures", []))
	for index in range(3):
		var entry := Dictionary(buffer[index])
		entry["delay"] = 0.06 + float(index) * 0.16
		ruptures.append(entry)
	while ruptures.size() > MAX_SEQUENCE_EVENTS:
		ruptures.pop_front()
	state["ruptures"] = ruptures
	state["sequence_buffer"] = buffer.slice(3)
	_metric(state, EV2_RUPTURA_SEQUENCIAL)


static func _conduct_overload(game: Node, state: Dictionary, source: Dictionary, source_pos: Vector2) -> void:
	var conducted := 0
	for candidate_value in game._acorrentada_targets_near(source_pos, 230.0, 8, true):
		if conducted >= 2:
			break
		var candidate := Dictionary(candidate_value)
		if _target_key(candidate) == _target_key(source) or not game._acorrentada_target_alive(candidate):
			continue
		var target := _target_descriptor(candidate)
		var target_pos: Vector2 = Vector2(game._acorrentada_target_pos(target))
		game._acorrentada_damage_target(target, float(game.player_damage) * 0.18, "acorrentada_ev2_sobrecarga_tensao", "manifestation_secondary", source_pos)
		game.acorrentada_visuals.append({"kind": "light", "a": source_pos, "b": target_pos, "life": 0.22, "max": 0.22})
		conducted += 1
	if conducted > 0:
		state["overload_gate"] = 0.24
		_metric(state, EV2_SOBRECARGA_TENSAO, conducted)


static func _consume_verdict(game: Node, state: Dictionary, target: Dictionary, target_pos: Vector2) -> void:
	var verdicts: Dictionary = Dictionary(state.get("verdicts", {}))
	var key := _target_key(target)
	if not verdicts.has(key):
		return
	verdicts.erase(key)
	state["verdicts"] = verdicts
	var boss_like := String(target.get("kind", "enemy")) in ["boss", "arauto"]
	game._acorrentada_damage_target(target, float(game.player_damage) * (0.18 if boss_like else 0.55), "acorrentada_ev2_sentenca_ferro", "manifestation_secondary", game.player_pos)
	game._acorrentada_apply_elo_to_target(target, 1)
	if String(target.get("kind", "enemy")) == "boss":
		game.boss_tp_stun_timer = maxf(float(game.boss_tp_stun_timer), 0.08)
	elif String(target.get("kind", "enemy")) == "arauto" and game._arauto_active():
		game.arauto["stun"] = maxf(float(game.arauto.get("stun", 0.0)), 0.08)
	else:
		var enemy = game._enemy_by_uid(int(target.get("uid", -1)))
		if enemy != null:
			enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), 0.35)
	game.acorrentada_visuals.append({"kind": "cross", "a": game.player_pos, "b": target_pos, "life": 0.42, "max": 0.42})
	game._play_sfx("acorrentada_hit_3", 0.035, 0.72, 0.88)
	_metric(state, EV2_SENTENCA_FERRO)


static func _apply_prison(game: Node, target: Dictionary) -> void:
	match String(target.get("kind", "enemy")):
		"boss":
			game.boss_tp_stun_timer = maxf(float(game.boss_tp_stun_timer), 0.18)
		"arauto":
			if game._arauto_active():
				game.arauto["stun"] = maxf(float(game.arauto.get("stun", 0.0)), 0.28)
		_:
			var enemy = game._enemy_by_uid(int(target.get("uid", -1)))
			if enemy != null:
				enemy["stun"] = maxf(float(enemy.get("stun", 0.0)), 1.15)
				enemy["acorrentada_slow"] = maxf(float(enemy.get("acorrentada_slow", 0.0)), 1.15)


static func _update_cooldowns(state: Dictionary, delta: float) -> void:
	var cooldowns: Dictionary = Dictionary(state.get("mirror_cooldowns", {}))
	for key in cooldowns.keys():
		var value := maxf(0.0, float(cooldowns.get(key, 0.0)) - delta)
		if value <= 0.0:
			cooldowns.erase(key)
		else:
			cooldowns[key] = value
	state["mirror_cooldowns"] = cooldowns


static func _update_shackles(game: Node, state: Dictionary, delta: float) -> void:
	var shackles: Array = []
	for shackle_value in Array(state.get("shackles", [])):
		var shackle := Dictionary(shackle_value)
		shackle["life"] = float(shackle.get("life", 0.0)) - delta
		shackle["tick"] = float(shackle.get("tick", 0.0)) - delta
		var target := Dictionary(shackle.get("target", {}))
		if float(shackle["life"]) <= 0.0 or not game._acorrentada_target_alive(target):
			continue
		var center: Vector2 = Vector2(game._acorrentada_target_pos(target))
		shackle["pos"] = center
		if float(shackle["tick"]) <= 0.0:
			shackle["tick"] = 0.45
			var pulled := 0
			for candidate_value in game._acorrentada_targets_near(center, 150.0, 5, false):
				if pulled >= 2:
					break
				var candidate := Dictionary(candidate_value)
				if _target_key(candidate) == _target_key(target):
					continue
				var enemy = game._enemy_by_uid(int(candidate.get("uid", -1)))
				if enemy == null:
					continue
				enemy["pos"] = Vector2(enemy.get("pos", center)).move_toward(center, 52.0)
				enemy["acorrentada_slow"] = maxf(float(enemy.get("acorrentada_slow", 0.0)), 0.38)
				pulled += 1
			if pulled > 0:
				_metric(state, "mobile_pulls", pulled)
		shackles.append(shackle)
	state["shackles"] = shackles


static func _update_anchors(game: Node, state: Dictionary, delta: float) -> void:
	var anchors: Array = []
	for anchor_value in Array(state.get("anchors", [])):
		var anchor := Dictionary(anchor_value)
		anchor["life"] = float(anchor.get("life", 0.0)) - delta
		anchor["tick"] = float(anchor.get("tick", 0.0)) - delta
		anchor["flash"] = maxf(0.0, float(anchor.get("flash", 0.0)) - delta)
		if float(anchor["life"]) <= 0.0:
			continue
		if float(anchor["tick"]) <= 0.0:
			anchor["tick"] = 0.55
			anchor["flash"] = 0.22
			var center := Vector2(anchor.get("pos", game.player_pos))
			for target_value in game._acorrentada_targets_near(center, 150.0, 3, false):
				var target := Dictionary(target_value)
				var enemy = game._enemy_by_uid(int(target.get("uid", -1)))
				if enemy == null:
					continue
				enemy["pos"] = Vector2(enemy.get("pos", center)).move_toward(center, 38.0)
				game._acorrentada_apply_elo_to_target(target, 1)
				game.acorrentada_visuals.append({"kind": "light", "a": center, "b": Vector2(enemy["pos"]), "life": 0.20, "max": 0.20})
				_metric(state, "anchor_pulls")
		anchors.append(anchor)
	state["anchors"] = anchors


static func _update_webs(game: Node, state: Dictionary, delta: float) -> void:
	var webs: Array = []
	for web_value in Array(state.get("webs", [])):
		var web := Dictionary(web_value)
		web["life"] = float(web.get("life", 0.0)) - delta
		web["tick"] = float(web.get("tick", 0.0)) - delta
		web["flash"] = maxf(0.0, float(web.get("flash", 0.0)) - delta)
		var positions := _living_node_positions(game, Array(web.get("nodes", [])))
		if float(web["life"]) <= 0.0 or positions.size() < 2:
			continue
		if float(web["tick"]) <= 0.0:
			web["tick"] = 0.35
			web["flash"] = 0.18
			_tick_web(game, state, positions)
		webs.append(web)
	state["webs"] = webs


static func _tick_web(game: Node, state: Dictionary, positions: Array) -> void:
	var center := Vector2.ZERO
	for position_value in positions:
		center += Vector2(position_value)
	center /= float(positions.size())
	var hit: Dictionary = {}
	for i in range(positions.size()):
		for j in range(i + 1, positions.size()):
			var a := Vector2(positions[i])
			var b := Vector2(positions[j])
			var midpoint := (a + b) * 0.5
			var radius := a.distance_to(b) * 0.5 + 44.0
			for target_value in game._acorrentada_targets_near(midpoint, radius, 12, true):
				var target := Dictionary(target_value)
				var key := _target_key(target)
				if hit.has(key):
					continue
				var target_pos: Vector2 = Vector2(game._acorrentada_target_pos(target))
				if _distance_to_segment(target_pos, a, b) > (58.0 if String(target.get("kind", "")) == "boss" else 26.0):
					continue
				hit[key] = true
				var boss_like := String(target.get("kind", "enemy")) in ["boss", "arauto"]
				game._acorrentada_damage_target(target, float(game.player_damage) * (0.028 if boss_like else 0.075), "acorrentada_ev2_teia_grilhoes", "manifestation_secondary", a)
				if not boss_like:
					var enemy = game._enemy_by_uid(int(target.get("uid", -1)))
					if enemy != null:
						enemy["pos"] = Vector2(enemy.get("pos", center)).move_toward(center, 30.0)
						enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), 0.42)
						enemy["evolution_slow_mult"] = minf(float(enemy.get("evolution_slow_mult", 1.0)), 0.66)
	if not hit.is_empty():
		_metric(state, "web_hits", hit.size())


static func _update_ruptures(game: Node, state: Dictionary, delta: float) -> void:
	var ruptures: Array = []
	for rupture_value in Array(state.get("ruptures", [])):
		var rupture := Dictionary(rupture_value)
		rupture["delay"] = float(rupture.get("delay", 0.0)) - delta
		if float(rupture["delay"]) > 0.0:
			ruptures.append(rupture)
			continue
		var target := Dictionary(rupture.get("target", {}))
		var center := _target_position(game, target, Vector2(rupture.get("pos", game.player_pos)))
		var hit_count := 0
		for candidate_value in game._acorrentada_targets_near(center, 82.0, 4, true):
			var candidate := Dictionary(candidate_value)
			if not game._acorrentada_target_alive(candidate):
				continue
			var boss_like := String(candidate.get("kind", "enemy")) in ["boss", "arauto"]
			game._acorrentada_damage_target(candidate, float(game.player_damage) * (0.055 if boss_like else 0.16), "acorrentada_ev2_ruptura_sequencial", "manifestation_secondary", center)
			hit_count += 1
		game.shockwaves.append({"pos": center, "radius": 10.0, "max": 82.0, "life": 0.28, "damage": 0.0, "hit": {}, "visual_only": true, "color": COLOR_HOT})
		game._play_sfx("acorrentada_hit_2", 0.018, 0.74, 1.08)
		_metric(state, "sequence_pulses")
		if hit_count > 0:
			_metric(state, "sequence_hits", hit_count)
	state["ruptures"] = ruptures


static func _update_verdicts(state: Dictionary, delta: float) -> void:
	var verdicts: Dictionary = Dictionary(state.get("verdicts", {}))
	for key in verdicts.keys():
		var verdict := Dictionary(verdicts.get(key, {}))
		verdict["life"] = float(verdict.get("life", 0.0)) - delta
		if float(verdict["life"]) <= 0.0:
			verdicts.erase(key)
		else:
			verdicts[key] = verdict
	state["verdicts"] = verdicts


static func _update_continuous_tension(game: Node, state: Dictionary, delta: float) -> void:
	var active_binding: bool = not Array(state.get("shackles", [])).is_empty() or not Array(state.get("anchors", [])).is_empty() or not Array(state.get("webs", [])).is_empty() or not game.acorrentada_links.is_empty()
	if not active_binding:
		state["continuous_tick"] = minf(1.0, float(state.get("continuous_tick", 1.0)))
		return
	game.acorrentada_last_hit_timer = 0.0
	state["continuous_tick"] = float(state.get("continuous_tick", 1.0)) - delta
	if float(state["continuous_tick"]) <= 0.0:
		state["continuous_tick"] = 1.0
		game._add_acorrentada_tension(1.0)
		_metric(state, EV1_SOBRETENSAO_CONTINUA)


static func _living_node_positions(game: Node, nodes: Array) -> Array:
	var positions: Array = []
	for node_value in nodes:
		var target := Dictionary(node_value)
		if game._acorrentada_target_alive(target):
			positions.append(game._acorrentada_target_pos(target))
	return positions


static func _target_descriptor(target: Dictionary) -> Dictionary:
	var kind := String(target.get("kind", "enemy"))
	return {"kind": kind, "uid": -1 if kind in ["boss", "arauto"] else int(target.get("uid", -1)), "pos": Vector2(target.get("pos", Vector2.ZERO))}


static func _target_key(target: Dictionary) -> String:
	var kind := String(target.get("kind", "enemy"))
	if kind in ["boss", "arauto"]:
		return kind
	return "enemy:%d" % int(target.get("uid", -1))


static func _target_position(game: Node, target: Dictionary, fallback: Vector2) -> Vector2:
	if not target.is_empty() and game._acorrentada_target_alive(target):
		return game._acorrentada_target_pos(target)
	return fallback


static func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var segment := b - a
	var length_sq := segment.length_squared()
	if length_sq <= 0.001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	return point.distance_to(a + segment * t)
