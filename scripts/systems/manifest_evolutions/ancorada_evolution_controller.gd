extends RefCounted
class_name RTAncoradaEvolutionController

# Ancorada evolves through persistent structures and territory rules.  The
# controller consumes resolved anchor/hit/Q/teleport/ultimate events; it never
# borrows the shared projectile presets.  Every persistent collection and scan
# is capped so the mobile and multiplayer simulations stay bounded.

const EV1_FUNDACAO_PROFUNDA := "ancorada_ev1_fundacao_profunda"
const EV1_MURALHA_RUPTURA := "ancorada_ev1_muralha_ruptura"
const EV1_PESO_ABSOLUTO := "ancorada_ev1_peso_absoluto"
const EV1_TERRITORIO_JURADO := "ancorada_ev1_territorio_jurado"
const EV1_CONTRA_IMPACTO := "ancorada_ev1_contra_impacto"
const EV1_LINHA_FUNDACAO := "ancorada_ev1_linha_fundacao"
const EV2_FORTALEZA_AUTOPORTANTE := "ancorada_ev2_fortaleza_autoportante"
const EV2_CORACAO_FORTALEZA := "ancorada_ev2_coracao_fortaleza"
const EV2_QUEDA_MONUMENTAL := "ancorada_ev2_queda_monumental"
const EV2_REDE_FUNDACOES := "ancorada_ev2_rede_fundacoes"
const EV2_ULTIMO_BASTIAO := "ancorada_ev2_ultimo_bastiao"
const EV2_CONTINENTE_IMOVEL := "ancorada_ev2_continente_imovel"

const MAX_WALLS := 2
const MAX_DOMAINS := 1
const MAX_FOUNDATION_LINES := 3
const MAX_FORTRESSES := 1
const MAX_MONUMENTS := 3
const MAX_NETWORK_NODES := 5
const MAX_ABSOLUTE_PINS := 3
const MAX_VISUAL_ARCS := 8
const STRUCTURE_SCAN_INTERVAL := 0.08
const DEFENSE_SCAN_INTERVAL := 0.10

const COLOR_STONE := Color(0.34, 0.44, 0.31)
const COLOR_FOUNDATION := Color(0.31, 1.0, 0.43)
const COLOR_LOAD := Color(0.28, 0.88, 1.0)
const COLOR_DANGER := Color(1.0, 0.42, 0.18)
const MAP_MARGIN := Vector2(42.0, 42.0)


static func is_active(game: Node) -> bool:
	if String(game.manifestation_key) != "ancorada":
		return false
	for choice_value in Array(game.manifest_evolution_state.get("choices", [])):
		if String(Dictionary(choice_value).get("evolution", "")).begins_with("ancorada_ev"):
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
	var state: Dictionary = Dictionary(game.manifest_evolution_state.get("ancorada", {}))
	if state.is_empty():
		state = {
			"walls": [],
			"domains": [],
			"foundation_lines": [],
			"fortresses": [],
			"monuments": [],
			"absolute_pins": [],
			"network_arcs": [],
			"bastion": {},
			"continent": {},
			"last_foundation_pos": Vector2.ZERO,
			"network_gate": 0.0,
			"bastion_cooldown": 0.0,
			"structure_scan": 0.0,
			"defense_scan": 0.0,
			"heart_tick": 0.0,
			"counter_cooldowns": {},
			"metrics": {}
		}
		game.manifest_evolution_state["ancorada"] = state
	return state


static func _store(game: Node, state: Dictionary) -> void:
	game.manifest_evolution_state["ancorada"] = state


static func _metric(state: Dictionary, key: String, amount: int = 1) -> void:
	var metrics: Dictionary = Dictionary(state.get("metrics", {}))
	metrics[key] = int(metrics.get(key, 0)) + amount
	state["metrics"] = metrics


static func debug_snapshot(game: Node) -> Dictionary:
	return _state(game).duplicate(true)


static func on_anchor_placed(game: Node, anchor: Dictionary) -> void:
	if not is_active(game) or anchor.is_empty():
		return
	var ids := _ids(game)
	var state := _state(game)
	var source := String(anchor.get("source", ""))
	var anchor_pos := Vector2(anchor.get("pos", game.player_pos))
	anchor["structure_hp"] = maxf(float(anchor.get("structure_hp", 0.0)), 140.0)
	anchor["structure_hp_max"] = maxf(float(anchor.get("structure_hp_max", 0.0)), 140.0)

	if _has(ids, EV1_FUNDACAO_PROFUNDA):
		anchor["life"] = maxf(float(anchor.get("life", 0.0)), 12.0)
		anchor["max"] = maxf(float(anchor.get("max", 0.0)), 12.0)
		anchor["deep_foundation"] = true
		anchor["deep_tick"] = 1.6
		anchor["deep_pulses"] = 0
		anchor["structure_hp"] = 220.0
		anchor["structure_hp_max"] = 220.0
		_metric(state, EV1_FUNDACAO_PROFUNDA)

	if bool(anchor.get("claimable", false)) and _has(ids, EV1_LINHA_FUNDACAO):
		var previous := Vector2(state.get("last_foundation_pos", Vector2.ZERO))
		if previous != Vector2.ZERO and previous.distance_to(anchor_pos) >= 48.0:
			var lines: Array = Array(state.get("foundation_lines", []))
			while lines.size() >= MAX_FOUNDATION_LINES:
				lines.pop_front()
			lines.append({"a": previous, "b": anchor_pos, "life": 6.5, "max": 6.5, "charges": 3, "hit_ids": {}})
			state["foundation_lines"] = lines
			_metric(state, EV1_LINHA_FUNDACAO)
		state["last_foundation_pos"] = anchor_pos

	if source == "ancorada_q":
		if _has(ids, EV1_MURALHA_RUPTURA):
			_create_wall(game, state, anchor_pos, Vector2(anchor.get("link_from", game.player_pos)))
		if _has(ids, EV1_TERRITORIO_JURADO):
			state["domains"] = [{"pos": anchor_pos, "life": 6.0, "max": 6.0, "radius": 178.0, "entered": {}, "pulse": 0.0}]
			_metric(state, EV1_TERRITORIO_JURADO)
		if _has(ids, EV2_FORTALEZA_AUTOPORTANTE):
			_create_fortress(game, state, anchor_pos)

	_store(game, state)


static func on_hit(game: Node, event_id: String, target: Dictionary, target_pos: Vector2) -> bool:
	if not is_active(game) or target.is_empty():
		return false
	var ids := _ids(game)
	var state := _state(game)
	if _has(ids, EV1_PESO_ABSOLUTO) and int(game.lastro_stacks) >= 3:
		_pin_target(game, state, target, target_pos)
	if _has(ids, EV2_REDE_FUNDACOES) and float(state.get("network_gate", 0.0)) <= 0.0:
		_transmit_network_load(game, state, target, target_pos, event_id)
	_store(game, state)
	return true


static func on_skill(game: Node, center: Vector2) -> bool:
	if not is_active(game):
		return false
	var state := _state(game)
	state["pending_skill_center"] = center.clamp(MAP_MARGIN, game.WORLD_SIZE - MAP_MARGIN)
	_store(game, state)
	return true


static func on_teleport(game: Node, _origin: Vector2, destination: Vector2) -> bool:
	if not is_active(game):
		return false
	var ids := _ids(game)
	var state := _state(game)
	if _has(ids, EV2_QUEDA_MONUMENTAL):
		var monuments: Array = Array(state.get("monuments", []))
		while monuments.size() >= MAX_MONUMENTS:
			monuments.pop_front()
		monuments.append({
			"pos": destination.clamp(MAP_MARGIN, game.WORLD_SIZE - MAP_MARGIN),
			"life": 5.25,
			"max": 5.25,
			"fall": 0.42,
			"landed": false,
			"hp": 300.0,
			"max_hp": 300.0,
			"hit_ids": {}
		})
		state["monuments"] = monuments
		_metric(state, EV2_QUEDA_MONUMENTAL)
		game._play_sfx("boss_impact", 0.025, 0.55, 0.76)
	_store(game, state)
	return true


static func on_ultimate_started(game: Node, center: Vector2) -> void:
	if not is_active(game) or not _has(_ids(game), EV2_CONTINENTE_IMOVEL):
		return
	var state := _state(game)
	var nodes: Array = []
	for anchor_value in game.anchors:
		var anchor := Dictionary(anchor_value)
		if String(anchor.get("source", "")).begins_with("ancorada_") and float(anchor.get("life", 0.0)) > 0.0:
			nodes.append(Vector2(anchor.get("pos", center)))
			if nodes.size() >= MAX_NETWORK_NODES:
				break
	if nodes.size() < 3:
		nodes.clear()
		for index in range(4):
			nodes.append((center + Vector2.from_angle(-PI * 0.25 + float(index) * TAU / 4.0) * 190.0).clamp(MAP_MARGIN, game.WORLD_SIZE - MAP_MARGIN))
	state["continent"] = {"nodes": nodes, "life": 7.0, "max": 7.0, "hit_ids": {}, "flash": 0.55}
	_metric(state, EV2_CONTINENTE_IMOVEL)
	game._add_text("CONTINENTE IMOVEL", center + Vector2(0, -128), COLOR_FOUNDATION, 1.1, 24)
	game._play_sfx("boss_impact", 0.035, 0.72, 0.68)
	_store(game, state)


static func update_effects(game: Node, delta: float) -> void:
	if not is_active(game):
		return
	var ids := _ids(game)
	var state := _state(game)
	state["network_gate"] = maxf(0.0, float(state.get("network_gate", 0.0)) - delta)
	state["bastion_cooldown"] = maxf(0.0, float(state.get("bastion_cooldown", 0.0)) - delta)
	state["structure_scan"] = float(state.get("structure_scan", 0.0)) - delta
	state["defense_scan"] = float(state.get("defense_scan", 0.0)) - delta
	state["heart_tick"] = float(state.get("heart_tick", 0.0)) - delta
	state["heart_flash"] = maxf(0.0, float(state.get("heart_flash", 0.0)) - delta)
	_update_cooldowns(state, delta)
	_update_deep_foundations(game, state, delta)
	_update_timed_state(state, delta)
	_update_monument_landings(game, state)
	_update_absolute_pins(game, state)
	if _has(ids, EV2_ULTIMO_BASTIAO):
		_update_last_bastion(game, state, delta)
	if _has(ids, EV2_CORACAO_FORTALEZA):
		_update_fortress_heart(game, state)
	if float(state.get("structure_scan", 0.0)) <= 0.0:
		state["structure_scan"] = STRUCTURE_SCAN_INTERVAL
		_update_structure_collisions(game, state, ids)
		_update_autonomous_fortress(game, state)
		_update_continent_boundaries(game, state)
	if float(state.get("defense_scan", 0.0)) <= 0.0:
		state["defense_scan"] = DEFENSE_SCAN_INTERVAL
		_update_domains(game, state)
		_update_foundation_lines(game, state)
		_update_bastion_projectiles(game, state)
	_store(game, state)


static func draw_world(game: Node2D, camera: Vector2) -> void:
	if not is_active(game):
		return
	var state := _state(game)
	var now := float(Time.get_ticks_msec()) * 0.001
	for anchor_value in game.anchors:
		var anchor := Dictionary(anchor_value)
		if not bool(anchor.get("deep_foundation", false)) or float(anchor.get("life", 0.0)) <= 0.0:
			continue
		var pos := Vector2(anchor.get("pos", game.player_pos)) - camera
		var fade := clampf(float(anchor.get("life", 0.0)) / 0.8, 0.0, 1.0)
		game.draw_circle(pos, 62.0 + sin(now * 3.5) * 4.0, Color(COLOR_FOUNDATION, 0.055 * fade))
		game.draw_arc(pos, 62.0 + sin(now * 3.5) * 4.0, 0.0, TAU, 36, Color(0.76, 1.0, 0.62, 0.72 * fade), 2.5)
	for wall_value in Array(state.get("walls", [])):
		var wall := Dictionary(wall_value)
		var fade := _fade(wall)
		var a := Vector2(wall.get("a", game.player_pos)) - camera
		var b := Vector2(wall.get("b", game.player_pos)) - camera
		game.draw_line(a, b, Color(0.03, 0.07, 0.03, 0.72 * fade), 22.0, true)
		game.draw_line(a, b, Color(COLOR_STONE, 0.92 * fade), 14.0, true)
		game.draw_line(a, b, Color(COLOR_FOUNDATION, 0.76 * fade), 3.0, true)
		_draw_health_bar(game, (a + b) * 0.5, float(wall.get("hp", 0.0)), float(wall.get("max_hp", 1.0)), fade)
	for domain_value in Array(state.get("domains", [])):
		var domain := Dictionary(domain_value)
		var center := Vector2(domain.get("pos", game.player_pos)) - camera
		var radius := float(domain.get("radius", 178.0))
		var fade := _fade(domain)
		game.draw_circle(center, radius, Color(COLOR_FOUNDATION, 0.055 * fade))
		game.draw_arc(center, radius + sin(now * 4.0) * 3.0, 0.0, TAU, 48, Color(COLOR_FOUNDATION, 0.72 * fade), 3.0)
	for line_value in Array(state.get("foundation_lines", [])):
		var line := Dictionary(line_value)
		var fade := _fade(line)
		var a := Vector2(line.get("a", game.player_pos)) - camera
		var b := Vector2(line.get("b", game.player_pos)) - camera
		game.draw_line(a, b, Color(COLOR_LOAD, 0.20 * fade), 11.0, true)
		game.draw_line(a, b, Color(COLOR_LOAD, 0.88 * fade), 2.5, true)
	for fortress_value in Array(state.get("fortresses", [])):
		var fortress := Dictionary(fortress_value)
		var points := PackedVector2Array()
		for pillar_value in Array(fortress.get("pillars", [])):
			var pillar := Dictionary(pillar_value)
			if float(pillar.get("hp", 0.0)) > 0.0:
				points.append(Vector2(pillar.get("pos", game.player_pos)) - camera)
		if points.size() >= 2:
			points.append(points[0])
			game.draw_polyline(points, Color(COLOR_FOUNDATION, 0.80 * _fade(fortress)), 5.0, true)
		for point in points:
			game.draw_circle(point, 12.0, Color(COLOR_STONE, 0.95 * _fade(fortress)))
	for monument_value in Array(state.get("monuments", [])):
		var monument := Dictionary(monument_value)
		var pos := Vector2(monument.get("pos", game.player_pos)) - camera
		var fade := _fade(monument)
		if not bool(monument.get("landed", false)):
			game.draw_arc(pos, 48.0, 0.0, TAU, 32, Color(COLOR_DANGER, 0.86), 4.0)
			game.draw_line(pos + Vector2(0, -120), pos, Color(COLOR_DANGER, 0.66), 5.0)
		else:
			game.draw_rect(Rect2(pos - Vector2(15, 42), Vector2(30, 58)), Color(COLOR_STONE, 0.94 * fade), true)
			game.draw_arc(pos + Vector2(0, 18), 42.0, PI, TAU, 24, Color(COLOR_FOUNDATION, 0.78 * fade), 3.0)
			_draw_health_bar(game, pos + Vector2(0, -52), float(monument.get("hp", 0.0)), float(monument.get("max_hp", 1.0)), fade)
	for pin_value in Array(state.get("absolute_pins", [])):
		var pin := Dictionary(pin_value)
		var pos := Vector2(pin.get("pos", game.player_pos)) - camera
		var fade := _fade(pin)
		game.draw_circle(pos, 25.0, Color(COLOR_STONE, 0.18 * fade))
		game.draw_arc(pos, 27.0, now, now + PI * 1.6, 28, Color(0.86, 1.0, 0.72, 0.90 * fade), 4.0)
		game.draw_line(pos + Vector2(-18, 0), pos + Vector2(18, 0), Color(COLOR_FOUNDATION, 0.75 * fade), 3.0)
	if state.has("heart_center"):
		var heart_center := Vector2(state.get("heart_center", game.player_pos)) - camera
		var heart_flash := clampf(float(state.get("heart_flash", 0.0)) / 0.5, 0.0, 1.0)
		game.draw_circle(heart_center, 22.0 + sin(now * 6.0) * 3.0, Color(COLOR_LOAD, 0.10 + heart_flash * 0.10))
		game.draw_arc(heart_center, 28.0 + heart_flash * 18.0, 0.0, TAU, 32, Color(COLOR_LOAD, 0.55 + heart_flash * 0.35), 3.0)
	var bastion := Dictionary(state.get("bastion", {}))
	if not bastion.is_empty():
		var center := Vector2(bastion.get("pos", game.player_pos)) - camera
		var radius := float(bastion.get("radius", 126.0))
		var fade := _fade(bastion)
		game.draw_circle(center, radius, Color(COLOR_DANGER, 0.045 * fade))
		game.draw_arc(center, radius, -now, TAU - now, 56, Color(COLOR_DANGER, 0.88 * fade), 5.0)
		_draw_health_bar(game, center + Vector2(0, -radius - 12.0), float(bastion.get("hp", 0.0)), float(bastion.get("max_hp", 1.0)), fade)
	var continent := Dictionary(state.get("continent", {}))
	if not continent.is_empty():
		var nodes: Array = Array(continent.get("nodes", []))
		var fade := _fade(continent)
		for index in range(nodes.size()):
			var a := Vector2(nodes[index]) - camera
			var b := Vector2(nodes[(index + 1) % nodes.size()]) - camera
			game.draw_line(a, b, Color(COLOR_FOUNDATION, 0.24 * fade), 16.0, true)
			game.draw_line(a, b, Color(0.86, 1.0, 0.68, 0.90 * fade), 3.5, true)
			game.draw_circle(a, 9.0, Color(COLOR_STONE, 0.95 * fade))
	for arc_value in Array(state.get("network_arcs", [])):
		var arc := Dictionary(arc_value)
		var fade := _fade(arc)
		game.draw_line(Vector2(arc.get("a", game.player_pos)) - camera, Vector2(arc.get("b", game.player_pos)) - camera, Color(COLOR_LOAD, 0.82 * fade), 3.0, true)


static func _create_wall(game: Node, state: Dictionary, center: Vector2, origin: Vector2) -> void:
	var forward := (center - origin).normalized()
	if forward.length_squared() <= 0.001:
		forward = Vector2.RIGHT
	var side := forward.orthogonal()
	var half_length := 104.0
	var walls: Array = Array(state.get("walls", []))
	while walls.size() >= MAX_WALLS:
		walls.pop_front()
	walls.append({
		"a": (center - side * half_length).clamp(MAP_MARGIN, game.WORLD_SIZE - MAP_MARGIN),
		"b": (center + side * half_length).clamp(MAP_MARGIN, game.WORLD_SIZE - MAP_MARGIN),
		"life": 5.4, "max": 5.4, "hp": 420.0, "max_hp": 420.0,
		"contact_cooldowns": {}
	})
	state["walls"] = walls
	_metric(state, EV1_MURALHA_RUPTURA)
	game._add_text("MURALHA DE RUPTURA", center + Vector2(0, -82), COLOR_FOUNDATION, 0.9, 19)
	game._play_sfx("boss_impact", 0.03, 0.66, 0.78)


static func _create_fortress(game: Node, state: Dictionary, center: Vector2) -> void:
	var pillars: Array = []
	for index in range(3):
		pillars.append({"pos": (center + Vector2.from_angle(-PI * 0.5 + float(index) * TAU / 3.0) * 88.0).clamp(MAP_MARGIN, game.WORLD_SIZE - MAP_MARGIN), "hp": 190.0, "max_hp": 190.0})
	state["fortresses"] = [{"center": center, "life": 8.0, "max": 8.0, "tick": 0.15, "pillars": pillars, "target_gate": {}}]
	_metric(state, EV2_FORTALEZA_AUTOPORTANTE)
	game._add_text("FORTALEZA AUTOPORTANTE", center + Vector2(0, -112), COLOR_FOUNDATION, 1.0, 21)


static func _pin_target(game: Node, state: Dictionary, target: Dictionary, target_pos: Vector2) -> void:
	var key := _target_key(target)
	var pins: Array = Array(state.get("absolute_pins", []))
	for pin_value in pins:
		var pin := Dictionary(pin_value)
		if String(pin.get("key", "")) == key:
			pin["life"] = 2.4
			state["absolute_pins"] = pins
			return
	while pins.size() >= MAX_ABSOLUTE_PINS:
		pins.pop_front()
	pins.append({"key": key, "target": _target_descriptor(target), "pos": target_pos, "life": 2.4, "max": 2.4})
	state["absolute_pins"] = pins
	_metric(state, EV1_PESO_ABSOLUTO)
	game._add_text("PESO ABSOLUTO", target_pos + Vector2(0, -64), COLOR_STONE.lightened(0.4), 0.7, 17)
	game._play_sfx("boss_impact", 0.018, 0.44, 0.88)


static func _transmit_network_load(game: Node, state: Dictionary, source: Dictionary, target_pos: Vector2, event_id: String) -> void:
	var nodes := _active_anchor_positions(game, MAX_NETWORK_NODES)
	if nodes.size() < 2:
		return
	var nearest_distance := INF
	for node_value in nodes:
		nearest_distance = minf(nearest_distance, target_pos.distance_to(Vector2(node_value)))
	if nearest_distance > 280.0:
		return
	var arcs: Array = Array(state.get("network_arcs", []))
	var damaged: Dictionary = {_target_key(source): true}
	var pulses := 0
	for index in range(nodes.size()):
		var node := Vector2(nodes[index])
		var next := Vector2(nodes[(index + 1) % nodes.size()])
		arcs.append({"a": node, "b": next, "life": 0.34, "max": 0.34, "event": event_id})
		var candidate := _nearest_enemy_descriptor(game, node, 125.0, damaged)
		if candidate.is_empty():
			continue
		damaged[_target_key(candidate)] = true
		_damage_target(game, candidate, float(game.player_damage) * 0.14, "ancorada_rede_fundacoes")
		pulses += 1
	while arcs.size() > MAX_VISUAL_ARCS:
		arcs.pop_front()
	state["network_arcs"] = arcs
	state["network_gate"] = 0.38
	if pulses > 0:
		_metric(state, EV2_REDE_FUNDACOES, pulses)
		game._play_sfx("boss_impact", 0.018, 0.48, 1.32)


static func _update_deep_foundations(game: Node, state: Dictionary, delta: float) -> void:
	for anchor_value in game.anchors:
		var anchor := Dictionary(anchor_value)
		if not bool(anchor.get("deep_foundation", false)) or float(anchor.get("life", 0.0)) <= 0.0:
			continue
		anchor["deep_tick"] = float(anchor.get("deep_tick", 0.0)) - delta
		if float(anchor["deep_tick"]) > 0.0 or int(anchor.get("deep_pulses", 0)) >= 4:
			continue
		anchor["deep_tick"] = 2.0
		if game.player_pos.distance_to(Vector2(anchor.get("pos", game.player_pos))) <= 170.0:
			anchor["deep_pulses"] = int(anchor.get("deep_pulses", 0)) + 1
			game.ancorada_ability_controller.add_lastro_points(1, "fundacao_profunda")
			_metric(state, "deep_lastro_pulses")


static func _update_timed_state(state: Dictionary, delta: float) -> void:
	for key in ["walls", "domains", "foundation_lines", "fortresses", "monuments", "absolute_pins", "network_arcs"]:
		var kept: Array = []
		for value in Array(state.get(key, [])):
			var item := Dictionary(value)
			item["life"] = float(item.get("life", 0.0)) - delta
			if key == "fortresses":
				var living_pillars := 0
				for pillar_value in Array(item.get("pillars", [])):
					living_pillars += int(float(Dictionary(pillar_value).get("hp", 0.0)) > 0.0)
				if living_pillars <= 0:
					continue
			if float(item["life"]) > 0.0 and float(item.get("hp", 1.0)) > 0.0:
				kept.append(item)
		state[key] = kept
	var continent := Dictionary(state.get("continent", {}))
	if not continent.is_empty():
		continent["life"] = float(continent.get("life", 0.0)) - delta
		continent["flash"] = maxf(0.0, float(continent.get("flash", 0.0)) - delta)
		state["continent"] = continent if float(continent["life"]) > 0.0 else {}


static func _update_monument_landings(game: Node, state: Dictionary) -> void:
	for monument_value in Array(state.get("monuments", [])):
		var monument := Dictionary(monument_value)
		if bool(monument.get("landed", false)) or float(monument.get("life", 0.0)) > float(monument.get("max", 0.0)) - float(monument.get("fall", 0.42)):
			continue
		monument["landed"] = true
		var center := Vector2(monument.get("pos", game.player_pos))
		var hit_count := 0
		for enemy in game.enemies:
			if hit_count >= 6 or float(enemy.get("hp", 0.0)) <= 0.0:
				continue
			var enemy_pos := Vector2(enemy.get("pos", Vector2.ZERO))
			if enemy_pos.distance_to(center) > 128.0:
				continue
			game._damage_enemy(enemy, float(game.player_damage) * 0.72, "ancorada_queda_monumental", false)
			var away := (enemy_pos - center).normalized()
			if away.length_squared() <= 0.001:
				away = Vector2.RIGHT
			enemy["pos"] = (enemy_pos + away * 82.0).clamp(Vector2(40, 40), game.WORLD_SIZE - Vector2(40, 40))
			hit_count += 1
		if game.boss_active and float(game.boss_hp) > 0.0 and game.boss_pos.distance_to(center) <= 148.0:
			game._damage_boss(float(game.player_damage) * 0.24, "ancorada_queda_monumental")
			game.boss_tp_stun_timer = maxf(float(game.boss_tp_stun_timer), 0.08)
		game._spawn_radial_particles(center, COLOR_DANGER, 20)
		game._play_sfx("boss_impact", 0.035, 0.86, 0.72)
		_metric(state, "monument_landings")


static func _update_absolute_pins(game: Node, state: Dictionary) -> void:
	for pin_value in Array(state.get("absolute_pins", [])):
		var pin := Dictionary(pin_value)
		var target := Dictionary(pin.get("target", {}))
		var fixed_pos := Vector2(pin.get("pos", game.player_pos))
		match String(target.get("kind", "enemy")):
			"boss":
				if game.boss_active and float(game.boss_hp) > 0.0:
					game.boss_tp_stun_timer = maxf(float(game.boss_tp_stun_timer), 0.05)
			"arauto":
				if game._arauto_active():
					game.arauto["stun"] = maxf(float(game.arauto.get("stun", 0.0)), 0.08)
			_:
				var enemy = game._enemy_by_uid(int(target.get("uid", -1)))
				if enemy != null and float(enemy.get("hp", 0.0)) > 0.0:
					enemy["pos"] = Vector2(enemy.get("pos", fixed_pos)).move_toward(fixed_pos, 52.0)
					enemy["velocity"] = Vector2.ZERO
					enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), 0.16)
					enemy["evolution_slow_mult"] = minf(float(enemy.get("evolution_slow_mult", 1.0)), 0.18)


static func _update_last_bastion(game: Node, state: Dictionary, delta: float) -> void:
	var bastion := Dictionary(state.get("bastion", {}))
	if bastion.is_empty() and float(state.get("bastion_cooldown", 0.0)) <= 0.0 and not bool(game.is_dead) and float(game.player_hp) <= float(game.player_hp_max) * 0.25:
		var hp := maxf(120.0, float(game.player_hp_max) * 0.42)
		bastion = {"pos": game.player_pos, "life": 5.0, "max": 5.0, "radius": 126.0, "hp": hp, "max_hp": hp}
		state["bastion"] = bastion
		state["bastion_cooldown"] = 32.0
		_metric(state, EV2_ULTIMO_BASTIAO)
		game._add_text("ULTIMO BASTIAO", game.player_pos + Vector2(0, -118), COLOR_DANGER, 1.0, 22)
		game._play_sfx("boss_impact", 0.035, 0.76, 0.82)
		for enemy in game.enemies:
			if float(enemy.get("hp", 0.0)) <= 0.0:
				continue
			var enemy_pos := Vector2(enemy.get("pos", Vector2.ZERO))
			if enemy_pos.distance_to(game.player_pos) <= 146.0:
				var away: Vector2 = (enemy_pos - Vector2(game.player_pos)).normalized()
				enemy["pos"] = (enemy_pos + away * 94.0).clamp(Vector2(40, 40), game.WORLD_SIZE - Vector2(40, 40))
	if bastion.is_empty():
		return
	bastion["life"] = float(bastion.get("life", 0.0)) - delta
	bastion["pos"] = game.player_pos
	if float(bastion["life"]) <= 0.0 or float(bastion.get("hp", 0.0)) <= 0.0:
		state["bastion"] = {}
	else:
		state["bastion"] = bastion


static func _update_fortress_heart(game: Node, state: Dictionary) -> void:
	if float(state.get("heart_tick", 0.0)) > 0.0:
		return
	var nodes := _active_anchor_positions(game, MAX_NETWORK_NODES)
	if nodes.size() < 2:
		state.erase("heart_center")
		state.erase("heart_flash")
		return
	state["heart_tick"] = 0.75
	var center := Vector2.ZERO
	for node_value in nodes:
		center += Vector2(node_value)
	center /= float(nodes.size())
	var repaired := 0
	for wall_value in Array(state.get("walls", [])):
		var wall := Dictionary(wall_value)
		var before := float(wall.get("hp", 0.0))
		wall["hp"] = minf(float(wall.get("max_hp", before)), before + 24.0)
		repaired += int(float(wall["hp"]) > before)
	for fortress_value in Array(state.get("fortresses", [])):
		var fortress := Dictionary(fortress_value)
		for pillar_value in Array(fortress.get("pillars", [])):
			var pillar := Dictionary(pillar_value)
			var before := float(pillar.get("hp", 0.0))
			pillar["hp"] = minf(float(pillar.get("max_hp", before)), before + 18.0)
			repaired += int(float(pillar["hp"]) > before)
	for bullet_value in game.enemy_bullets:
		var bullet := Dictionary(bullet_value)
		if Vector2(bullet.get("pos", Vector2.ZERO)).distance_to(center) <= 155.0 and not bool(bullet.get("ancorada_heart_guard", false)):
			bullet["ancorada_heart_guard"] = true
			bullet["speed_mult"] = minf(float(bullet.get("speed_mult", 1.0)), 0.68)
			bullet["damage"] = float(bullet.get("damage", 0.0)) * 0.78
	_metric(state, EV2_CORACAO_FORTALEZA, maxi(1, repaired))
	state["heart_center"] = center
	state["heart_flash"] = 0.5


static func _update_structure_collisions(game: Node, state: Dictionary, ids: Dictionary) -> void:
	for wall_value in Array(state.get("walls", [])):
		var wall := Dictionary(wall_value)
		_resolve_wall_collisions(game, state, wall, ids)
	for fortress_value in Array(state.get("fortresses", [])):
		var fortress := Dictionary(fortress_value)
		for pillar_value in Array(fortress.get("pillars", [])):
			var pillar := Dictionary(pillar_value)
			if float(pillar.get("hp", 0.0)) > 0.0:
				_resolve_round_structure(game, state, pillar, 30.0, ids)
	for monument_value in Array(state.get("monuments", [])):
		var monument := Dictionary(monument_value)
		if bool(monument.get("landed", false)):
			_resolve_round_structure(game, state, monument, 38.0, ids)
	if _has(ids, EV1_CONTRA_IMPACTO):
		for anchor_value in game.anchors:
			var anchor := Dictionary(anchor_value)
			if String(anchor.get("source", "")).begins_with("ancorada_") and float(anchor.get("life", 0.0)) > 0.0:
				_resolve_counter_anchor(game, state, anchor)


static func _resolve_wall_collisions(game: Node, state: Dictionary, wall: Dictionary, ids: Dictionary) -> void:
	var a := Vector2(wall.get("a", game.player_pos))
	var b := Vector2(wall.get("b", game.player_pos))
	var cooldowns: Dictionary = Dictionary(wall.get("contact_cooldowns", {}))
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var pos := Vector2(enemy.get("pos", Vector2.ZERO))
		if game._distance_to_segment(pos, a, b) > 25.0:
			continue
		var uid := str(enemy.get("uid", ""))
		var endpoint := a if pos.distance_squared_to(a) < pos.distance_squared_to(b) else b
		var wall_dir := (b - a).normalized()
		var normal := wall_dir.orthogonal()
		if (pos - a).dot(normal) < 0.0:
			normal = -normal
		enemy["pos"] = pos.move_toward((endpoint + normal * 34.0).clamp(Vector2(40, 40), game.WORLD_SIZE - Vector2(40, 40)), 58.0)
		enemy["velocity"] = Vector2.ZERO
		enemy["ancorada_wall_detour"] = endpoint
		if float(cooldowns.get(uid, 0.0)) <= 0.0:
			cooldowns[uid] = 0.55
			wall["hp"] = float(wall.get("hp", 0.0)) - (28.0 if game._is_uncommon_enemy(enemy) else 16.0)
			_metric(state, "wall_blocks")
			if _has(ids, EV1_CONTRA_IMPACTO):
				_apply_counter_impact(game, state, enemy, (pos - (a + b) * 0.5).normalized())
	wall["contact_cooldowns"] = cooldowns
	if game.boss_active and float(game.boss_hp) > 0.0 and game._distance_to_segment(game.boss_pos, a, b) <= 62.0:
		game.boss_tp_stun_timer = maxf(float(game.boss_tp_stun_timer), 0.06)


static func _resolve_round_structure(game: Node, state: Dictionary, structure: Dictionary, radius: float, ids: Dictionary) -> void:
	var center := Vector2(structure.get("pos", game.player_pos))
	var cooldowns: Dictionary = Dictionary(structure.get("contact_cooldowns", {}))
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var pos := Vector2(enemy.get("pos", Vector2.ZERO))
		if pos.distance_to(center) > radius + 24.0:
			continue
		var away := (pos - center).normalized()
		if away.length_squared() <= 0.001:
			away = Vector2.RIGHT
		enemy["pos"] = (center + away * (radius + 27.0)).clamp(Vector2(40, 40), game.WORLD_SIZE - Vector2(40, 40))
		var uid := str(enemy.get("uid", ""))
		if float(cooldowns.get(uid, 0.0)) <= 0.0:
			cooldowns[uid] = 0.60
			structure["hp"] = float(structure.get("hp", 0.0)) - (24.0 if game._is_uncommon_enemy(enemy) else 14.0)
			if _has(ids, EV1_CONTRA_IMPACTO):
				_apply_counter_impact(game, state, enemy, away)
	structure["contact_cooldowns"] = cooldowns


static func _resolve_counter_anchor(game: Node, state: Dictionary, anchor: Dictionary) -> void:
	var center := Vector2(anchor.get("pos", game.player_pos))
	var cooldowns: Dictionary = Dictionary(state.get("counter_cooldowns", {}))
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var pos := Vector2(enemy.get("pos", Vector2.ZERO))
		if pos.distance_to(center) > 68.0:
			continue
		var uid := str(enemy.get("uid", ""))
		if float(cooldowns.get(uid, 0.0)) > 0.0:
			continue
		cooldowns[uid] = 0.82
		anchor["structure_hp"] = float(anchor.get("structure_hp", 140.0)) - (22.0 if game._is_uncommon_enemy(enemy) else 12.0)
		if float(anchor["structure_hp"]) <= 0.0:
			anchor["life"] = 0.0
		_apply_counter_impact(game, state, enemy, (pos - center).normalized())
	state["counter_cooldowns"] = cooldowns


static func _apply_counter_impact(game: Node, state: Dictionary, enemy: Dictionary, away: Vector2) -> void:
	if away.length_squared() <= 0.001:
		away = Vector2.RIGHT
	game._damage_enemy(enemy, float(game.player_damage) * 0.24, "ancorada_contra_impacto", false)
	enemy["pos"] = (Vector2(enemy.get("pos", Vector2.ZERO)) + away.normalized() * 92.0).clamp(Vector2(40, 40), game.WORLD_SIZE - Vector2(40, 40))
	enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), 0.45)
	_metric(state, EV1_CONTRA_IMPACTO)
	game._spawn_radial_particles(Vector2(enemy.get("pos", game.player_pos)), COLOR_DANGER, 8)
	game._play_sfx("boss_impact", 0.012, 0.42, 1.24)


static func _update_autonomous_fortress(game: Node, state: Dictionary) -> void:
	for fortress_value in Array(state.get("fortresses", [])):
		var fortress := Dictionary(fortress_value)
		var has_living_pillar := false
		for pillar_value in Array(fortress.get("pillars", [])):
			if float(Dictionary(pillar_value).get("hp", 0.0)) > 0.0:
				has_living_pillar = true
				break
		if not has_living_pillar:
			continue
		fortress["tick"] = float(fortress.get("tick", 0.0)) - STRUCTURE_SCAN_INTERVAL
		if float(fortress["tick"]) > 0.0:
			continue
		fortress["tick"] = 0.65
		var center := Vector2(fortress.get("center", game.player_pos))
		var target := _nearest_enemy_descriptor(game, center, 235.0, {})
		if target.is_empty():
			continue
		var target_pos := _target_pos(game, target)
		_damage_target(game, target, float(game.player_damage) * 0.26, "ancorada_fortaleza_autoportante")
		if String(target.get("kind", "enemy")) == "enemy":
			var enemy = game._enemy_by_uid(int(target.get("uid", -1)))
			if enemy != null:
				var away := (target_pos - center).normalized()
				enemy["pos"] = (target_pos + away * 46.0).clamp(Vector2(40, 40), game.WORLD_SIZE - Vector2(40, 40))
		var arcs: Array = Array(state.get("network_arcs", []))
		arcs.append({"a": center, "b": target_pos, "life": 0.30, "max": 0.30})
		while arcs.size() > MAX_VISUAL_ARCS:
			arcs.pop_front()
		state["network_arcs"] = arcs
		_metric(state, "fortress_shots")


static func _update_continent_boundaries(game: Node, state: Dictionary) -> void:
	var continent := Dictionary(state.get("continent", {}))
	if continent.is_empty():
		return
	var nodes: Array = Array(continent.get("nodes", []))
	if nodes.size() < 3:
		return
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var pos := Vector2(enemy.get("pos", Vector2.ZERO))
		for index in range(nodes.size()):
			var a := Vector2(nodes[index])
			var b := Vector2(nodes[(index + 1) % nodes.size()])
			if game._distance_to_segment(pos, a, b) > 24.0:
				continue
			var endpoint := a if pos.distance_squared_to(a) < pos.distance_squared_to(b) else b
			enemy["pos"] = pos.move_toward(endpoint, 64.0).clamp(Vector2(40, 40), game.WORLD_SIZE - Vector2(40, 40))
			enemy["velocity"] = Vector2.ZERO
			enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), 0.22)
			_metric(state, "continent_blocks")
			break
	if game.boss_active and float(game.boss_hp) > 0.0:
		for index in range(nodes.size()):
			if game._distance_to_segment(game.boss_pos, Vector2(nodes[index]), Vector2(nodes[(index + 1) % nodes.size()])) <= 58.0:
				game.boss_tp_stun_timer = maxf(float(game.boss_tp_stun_timer), 0.05)
				break


static func _update_domains(game: Node, state: Dictionary) -> void:
	for domain_value in Array(state.get("domains", [])):
		var domain := Dictionary(domain_value)
		var center := Vector2(domain.get("pos", game.player_pos))
		var radius := float(domain.get("radius", 178.0))
		var entered: Dictionary = Dictionary(domain.get("entered", {}))
		var scanned := 0
		for enemy in game.enemies:
			if scanned >= 8 or float(enemy.get("hp", 0.0)) <= 0.0:
				continue
			var pos := Vector2(enemy.get("pos", Vector2.ZERO))
			if pos.distance_to(center) > radius:
				continue
			scanned += 1
			var uid := str(enemy.get("uid", ""))
			enemy["evolution_slow"] = maxf(float(enemy.get("evolution_slow", 0.0)), 0.22)
			enemy["evolution_slow_mult"] = minf(float(enemy.get("evolution_slow_mult", 1.0)), 0.62)
			if not entered.has(uid):
				if entered.size() >= 32:
					entered.erase(entered.keys()[0])
				entered[uid] = true
				game._damage_enemy(enemy, float(game.player_damage) * 0.18, "ancorada_territorio_jurado", false)
				_metric(state, "territory_entries")
		domain["entered"] = entered
		var protected := 0
		for bullet_value in game.enemy_bullets:
			if protected >= 6:
				break
			var bullet := Dictionary(bullet_value)
			if Vector2(bullet.get("pos", Vector2.ZERO)).distance_to(center) > radius or bool(bullet.get("ancorada_oath", false)):
				continue
			bullet["ancorada_oath"] = true
			bullet["speed_mult"] = minf(float(bullet.get("speed_mult", 1.0)), 0.58)
			bullet["damage"] = float(bullet.get("damage", 0.0)) * 0.65
			protected += 1


static func _update_foundation_lines(game: Node, state: Dictionary) -> void:
	for line_value in Array(state.get("foundation_lines", [])):
		var line := Dictionary(line_value)
		if int(line.get("charges", 0)) <= 0:
			continue
		var a := Vector2(line.get("a", game.player_pos))
		var b := Vector2(line.get("b", game.player_pos))
		for bullet_value in game.enemy_bullets:
			if int(line.get("charges", 0)) <= 0:
				break
			var bullet := Dictionary(bullet_value)
			if float(bullet.get("life", 0.0)) <= 0.0 or game._distance_to_segment(Vector2(bullet.get("pos", Vector2.ZERO)), a, b) > 16.0:
				continue
			bullet["life"] = 0.0
			line["charges"] = int(line.get("charges", 0)) - 1
			_metric(state, "line_intercepts")


static func _update_bastion_projectiles(game: Node, state: Dictionary) -> void:
	var bastion := Dictionary(state.get("bastion", {}))
	if bastion.is_empty():
		return
	var center := Vector2(bastion.get("pos", game.player_pos))
	var radius := float(bastion.get("radius", 126.0))
	var absorbed := 0
	for bullet_value in game.enemy_bullets:
		if absorbed >= 8:
			break
		var bullet := Dictionary(bullet_value)
		if float(bullet.get("life", 0.0)) <= 0.0 or Vector2(bullet.get("pos", Vector2.ZERO)).distance_to(center) > radius:
			continue
		var incoming := maxf(1.0, float(bullet.get("damage", 1.0)))
		bullet["life"] = 0.0
		bastion["hp"] = float(bastion.get("hp", 0.0)) - incoming
		absorbed += 1
		_metric(state, "bastion_absorbed")
	state["bastion"] = bastion if float(bastion.get("hp", 0.0)) > 0.0 else {}


static func _update_cooldowns(state: Dictionary, delta: float) -> void:
	var global_cooldowns: Dictionary = Dictionary(state.get("counter_cooldowns", {}))
	_tick_cooldown_dictionary(global_cooldowns, delta)
	state["counter_cooldowns"] = global_cooldowns
	for key in ["walls", "fortresses", "monuments"]:
		for value in Array(state.get(key, [])):
			var item := Dictionary(value)
			var cooldowns: Dictionary = Dictionary(item.get("contact_cooldowns", {}))
			_tick_cooldown_dictionary(cooldowns, delta)
			item["contact_cooldowns"] = cooldowns
			if key == "fortresses":
				for pillar_value in Array(item.get("pillars", [])):
					var pillar := Dictionary(pillar_value)
					var pillar_cooldowns: Dictionary = Dictionary(pillar.get("contact_cooldowns", {}))
					_tick_cooldown_dictionary(pillar_cooldowns, delta)
					pillar["contact_cooldowns"] = pillar_cooldowns


static func _tick_cooldown_dictionary(cooldowns: Dictionary, delta: float) -> void:
	for key in cooldowns.keys():
		var left := float(cooldowns.get(key, 0.0)) - delta
		if left <= 0.0:
			cooldowns.erase(key)
		else:
			cooldowns[key] = left


static func _active_anchor_positions(game: Node, limit: int) -> Array:
	var positions: Array = []
	for anchor_value in game.anchors:
		var anchor := Dictionary(anchor_value)
		if not String(anchor.get("source", "")).begins_with("ancorada_") or float(anchor.get("life", 0.0)) <= 0.0:
			continue
		positions.append(Vector2(anchor.get("pos", game.player_pos)))
		if positions.size() >= limit:
			break
	return positions


static func _nearest_enemy_descriptor(game: Node, center: Vector2, radius: float, excluded: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := radius
	for enemy in game.enemies:
		if float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		var descriptor := {"kind": "enemy", "uid": int(enemy.get("uid", -1))}
		if excluded.has(_target_key(descriptor)):
			continue
		var distance := center.distance_to(Vector2(enemy.get("pos", Vector2.ZERO)))
		if distance < best_distance:
			best_distance = distance
			best = descriptor
	if game._arauto_active() and not excluded.has("arauto"):
		var distance := center.distance_to(Vector2(game.arauto.get("pos", Vector2.ZERO)))
		if distance < best_distance:
			best_distance = distance
			best = {"kind": "arauto", "uid": -1}
	if game.boss_active and float(game.boss_hp) > 0.0 and not excluded.has("boss"):
		var distance := center.distance_to(game.boss_pos)
		if distance < best_distance:
			best = {"kind": "boss", "uid": -1}
	return best


static func _damage_target(game: Node, target: Dictionary, amount: float, source: String) -> void:
	match String(target.get("kind", "enemy")):
		"boss": game._damage_boss(amount * 0.42, source)
		"arauto": game._damage_arauto(amount * 0.62, source, false)
		_:
			var enemy = game._enemy_by_uid(int(target.get("uid", -1)))
			if enemy != null:
				var killed: bool = bool(game._damage_enemy(enemy, amount, source, false))
				if killed:
					game._kill_enemy(enemy)


static func _target_descriptor(target: Dictionary) -> Dictionary:
	return {"kind": String(target.get("kind", "enemy")), "uid": int(target.get("uid", -1))}


static func _target_key(target: Dictionary) -> String:
	var kind := String(target.get("kind", "enemy"))
	return kind if kind != "enemy" else "enemy:%s" % str(target.get("uid", -1))


static func _target_pos(game: Node, target: Dictionary) -> Vector2:
	match String(target.get("kind", "enemy")):
		"boss": return game.boss_pos
		"arauto": return Vector2(game.arauto.get("pos", game.player_pos))
		_:
			var enemy = game._enemy_by_uid(int(target.get("uid", -1)))
			return Vector2(enemy.get("pos", game.player_pos)) if enemy != null else game.player_pos


static func _fade(item: Dictionary) -> float:
	return clampf(float(item.get("life", 0.0)) / minf(0.8, maxf(0.01, float(item.get("max", 1.0)))), 0.0, 1.0)


static func _draw_health_bar(game: Node2D, center: Vector2, hp: float, maximum: float, alpha: float) -> void:
	var ratio := clampf(hp / maxf(1.0, maximum), 0.0, 1.0)
	game.draw_rect(Rect2(center + Vector2(-28, -4), Vector2(56, 8)), Color(0.02, 0.03, 0.02, 0.78 * alpha), true)
	game.draw_rect(Rect2(center + Vector2(-26, -2), Vector2(52.0 * ratio, 4)), Color(COLOR_FOUNDATION, 0.88 * alpha), true)
