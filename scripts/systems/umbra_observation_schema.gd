extends RefCounted
class_name RTUmbraObservationSchema

# Observation-only contract.  It deliberately does not replace the active
# 24-input policy ABI until a separately trained/exported policy opts into it.
const SCHEMA_VERSION := 2
const MAX_PLAYER_SLOTS := 3
const POSITION_LIMIT := 2000.0
const DEFAULT_WORLD_SIZE := Vector2(1600.0, 900.0)
const VELOCITY_LIMIT := 800.0
const COOLDOWN_LIMIT := 24.0
const DAMAGE_LIMIT := 1000.0
const CARD_LIMIT := 30.0
const ACTIONS := ["FUGIR", "INTERCEPTAR", "ORBITAR", "CERCAR", "ATAQUE", "SIFON", "TELEPORTE", "TELEPORTE_JUKE", "TRANSMUTAR_VORTICE", "TRANSMUTAR_GRAVIDADE", "TRANSMUTAR_NECROSE", "TRANSMUTAR_RESSONANCIA", "TRANSMUTAR_HEMORRAGIA", "TRANSMUTAR_ATRITO", "TRANSMUTAR_RASTRO", "VORTICE", "PRISAO", "MIASMA", "DESCARGA_ELETRICA", "PRAGA_RATOS", "LASER_SOBRECARGA", "CAMINHO_ESPINHOS", "NENHUMA"]
const MANIFESTATIONS := ["eletrica", "lacerante", "prismatica", "retornante", "parasitica", "gravitante", "ancorada", "cartografica", "mnesica", "ressonante", "contratual", "acorrentada", "eclipsada", "bombastica", "necronada"]
const COOLDOWN_KEYS := ["VORTICE", "PRISAO", "MIASMA", "DESCARGA_ELETRICA", "CAMINHO_ESPINHOS", "PRAGA_RATOS", "LASER_SOBRECARGA"]


static func feature_schema() -> Array:
	var specs: Array = []
	_add(specs, "umbra.hp_ratio", "umbra", 0.0, 1.0)
	_add(specs, "umbra.position_x", "umbra", 0.0, POSITION_LIMIT)
	_add(specs, "umbra.position_y", "umbra", 0.0, POSITION_LIMIT)
	_add(specs, "umbra.velocity_x", "umbra", -VELOCITY_LIMIT, VELOCITY_LIMIT)
	_add(specs, "umbra.velocity_y", "umbra", -VELOCITY_LIMIT, VELOCITY_LIMIT)
	_add(specs, "umbra.current_action", "umbra", 0.0, float(maxi(1, ACTIONS.size() - 1)))
	_add(specs, "umbra.damage_recent", "umbra", 0.0, DAMAGE_LIMIT)
	for cooldown in COOLDOWN_KEYS:
		_add(specs, "umbra.cooldown." + cooldown.to_lower(), "umbra", 0.0, COOLDOWN_LIMIT)
	for slot in range(MAX_PLAYER_SLOTS):
		var prefix := "players.slot_%d." % slot
		_add(specs, prefix + "valid", "players", 0.0, 1.0, slot)
		_add(specs, prefix + "alive", "players", 0.0, 1.0, slot)
		_add(specs, prefix + "relative_x", "players", -POSITION_LIMIT, POSITION_LIMIT, slot)
		_add(specs, prefix + "relative_y", "players", -POSITION_LIMIT, POSITION_LIMIT, slot)
		_add(specs, prefix + "velocity_x", "players", -VELOCITY_LIMIT, VELOCITY_LIMIT, slot)
		_add(specs, prefix + "velocity_y", "players", -VELOCITY_LIMIT, VELOCITY_LIMIT, slot)
		_add(specs, prefix + "hp_ratio", "players", 0.0, 1.0, slot)
		_add(specs, prefix + "build_cards", "players", 0.0, CARD_LIMIT, slot)
		_add(specs, prefix + "build_damage", "players", 0.0, DAMAGE_LIMIT, slot)
		_add(specs, prefix + "manifestation", "players", 0.0, float(maxi(1, MANIFESTATIONS.size() - 1)), slot)
		_add(specs, prefix + "stunned", "players", 0.0, 1.0, slot)
		_add(specs, prefix + "silenced", "players", 0.0, 1.0, slot)
		_add(specs, prefix + "action_recent", "players", 0.0, 1.0, slot)
	_add(specs, "space.boss_edge_x", "space", 0.0, 1.0)
	_add(specs, "space.boss_edge_y", "space", 0.0, 1.0)
	_add(specs, "space.nearest_player_edge_x", "space", 0.0, 1.0)
	_add(specs, "space.nearest_player_edge_y", "space", 0.0, 1.0)
	_add(specs, "space.boss_center_distance", "space", 0.0, 1.0)
	for hazard in ["vortex", "prison", "thorns", "overload_laser", "discharge", "miasma", "rats"]:
		_add(specs, "space.hazard." + hazard, "space", 0.0, 1.0)
	_add(specs, "space.dimension", "space", 0.0, 1.0)
	_add(specs, "space.route_pressure", "space", 0.0, 1.0)
	_add(specs, "combat.projectile_pressure", "combat", 0.0, 1.0)
	_add(specs, "combat.hazard_pressure", "combat", 0.0, 1.0)
	_add(specs, "combat.recent_hits", "combat", 0.0, 20.0)
	_add(specs, "combat.recent_misses", "combat", 0.0, 20.0)
	_add(specs, "combat.player_damage_recent", "combat", 0.0, DAMAGE_LIMIT)
	_add(specs, "combat.umbra_damage_recent", "combat", 0.0, DAMAGE_LIMIT)
	_add(specs, "history.player_motion", "history", 0.0, 1.0)
	_add(specs, "history.player_direction_change", "history", 0.0, 1.0)
	_add(specs, "history.player_distance_delta", "history", -1.0, 1.0)
	_add(specs, "history.target_switches", "history", 0.0, 8.0)
	_add(specs, "history.player_downs", "history", 0.0, 3.0)
	_add(specs, "history.action_repeat", "history", 0.0, 1.0)
	_add(specs, "multiplayer.player_count", "multiplayer", 1.0, float(MAX_PLAYER_SLOTS))
	for slot in range(MAX_PLAYER_SLOTS):
		_add(specs, "multiplayer.slot_%d_valid" % slot, "multiplayer", 0.0, 1.0, slot)
	return specs


static func feature_names() -> Array:
	var names: Array = []
	for spec in feature_schema():
		names.append(String(Dictionary(spec).get("name", "")))
	return names


static func build_from_snapshot(snapshot: Dictionary) -> Dictionary:
	var specs := feature_schema()
	var players: Array = Array(snapshot.get("players", []))
	var values: Array = []
	var mask: Array = []
	for slot in range(MAX_PLAYER_SLOTS):
		var player: Dictionary = Dictionary(players[slot]) if slot < players.size() else {}
		# A slot stays present for deterministic feature ordering, but a downed or
		# eliminated player must never become a policy target.
		var targetable := slot < players.size() and bool(player.get("valid", true)) and bool(player.get("alive", true))
		mask.append(1.0 if targetable else 0.0)
	for spec_value in specs:
		var spec: Dictionary = Dictionary(spec_value)
		var raw: float = _raw_value(snapshot, players, spec)
		values.append(_normalize(raw, float(spec["min"]), float(spec["max"])))
	return {
		"schema_version": SCHEMA_VERSION,
		"feature_schema": feature_names(),
		"feature_specs": specs,
		"input_size": values.size(),
		"values": values,
		"valid_player_mask": mask
	}


static func build_from_runtime(runtime: Object) -> Dictionary:
	var world := DEFAULT_WORLD_SIZE
	var boss_pos: Vector2 = Vector2(runtime.get("boss_pos"))
	var player_pos: Vector2 = Vector2(runtime.get("player_pos"))
	# Slots are always local peer first, then peers sorted by stable peer id. A
	# downed/eliminated slot remains in place but is masked out for targeting.
	var players: Array = [_local_player_snapshot(runtime, boss_pos)]
	var remotes: Array = []
	for peer_value in Dictionary(runtime.get("net_players_by_peer")).keys():
		var peer_id := int(peer_value)
		var state: Dictionary = Dictionary(Dictionary(runtime.get("net_players_by_peer")).get(peer_id, {}))
		var alive := bool(state.get("alive", not bool(state.get("dead", false)))) and not bool(state.get("eliminated", false)) and float(state.get("hp", 0.0)) > 0.0
		remotes.append({"peer_id": peer_id, "valid": alive, "alive": alive, "pos": Vector2(state.get("pos", player_pos)), "velocity": Vector2(state.get("velocity", Vector2.ZERO)), "hp": float(state.get("hp", 0.0)), "hp_max": float(state.get("hp_max", 1.0)), "cards": float(state.get("cards_bought", 0.0)), "damage": float(state.get("damage", 0.0)), "manifestation": String(state.get("manifestation", "")), "stunned": bool(state.get("stunned", false)), "silenced": bool(state.get("silenced", false)), "action_recent": float(state.get("action_recent", 0.0))})
	remotes.sort_custom(func(a: Dictionary, b: Dictionary): return int(a["peer_id"]) < int(b["peer_id"]))
	for remote in remotes:
		if players.size() >= MAX_PLAYER_SLOTS:
			break
		players.append(remote)
	var cooldowns: Dictionary = Dictionary(runtime.get("boss5_ability_cooldowns"))
	var history: Array = Array(runtime.get("phase5_player_history"))
	var motion := _history_motion(history, world)
	var snapshot := {
		"umbra_hp_ratio": float(runtime.get("boss_hp")) / maxf(1.0, float(runtime.get("boss_hp_max"))),
		"umbra_position_x": boss_pos.x, "umbra_position_y": boss_pos.y,
		"umbra_velocity_x": Vector2(runtime.get("boss5_velocity")).x, "umbra_velocity_y": Vector2(runtime.get("boss5_velocity")).y,
		"umbra_current_action": float(ACTIONS.find(String(runtime.get("boss5_current_action")))),
		"umbra_damage_recent": 0.0,
		"cooldowns": cooldowns, "players": players,
		"space_boss_edge_x": _edge_ratio(boss_pos.x, world.x), "space_boss_edge_y": _edge_ratio(boss_pos.y, world.y),
		"space_nearest_player_edge_x": _edge_ratio(player_pos.x, world.x), "space_nearest_player_edge_y": _edge_ratio(player_pos.y, world.y),
		"space_boss_center_distance": boss_pos.distance_to(world * 0.5) / maxf(1.0, world.length() * 0.5),
		"space_dimension": _dimension_value(String(runtime.get("boss5_dimension"))),
		"space_route_pressure": clampf(float(history.size()) / 28.0, 0.0, 1.0),
		"combat_projectile_pressure": _projectile_pressure(Array(runtime.get("bullets")), boss_pos),
		"combat_hazard_pressure": clampf(float(Array(runtime.get("phase5_hazards")).size()) / 8.0, 0.0, 1.0),
		"history_player_motion": motion.get("motion", 0.0), "history_player_direction_change": motion.get("direction_change", 0.0), "history_player_distance_delta": motion.get("distance_delta", 0.0),
		"multiplayer_player_count": players.size()
	}
	for cooldown in COOLDOWN_KEYS:
		snapshot["umbra_cooldown_" + cooldown.to_lower()] = float(cooldowns.get(cooldown, 0.0))
	for hazard in ["vortex", "prison", "thorns", "overload_laser", "discharge", "miasma"]:
		snapshot["space_hazard_" + hazard] = 1.0 if _hazard_active(Array(runtime.get("phase5_hazards")), hazard) else 0.0
	snapshot["space_hazard_rats"] = 1.0 if not Array(runtime.get("phase5_rats")).is_empty() else 0.0
	return build_from_snapshot(snapshot)


static func validate_observation(observation: Dictionary) -> String:
	if int(observation.get("schema_version", -1)) != SCHEMA_VERSION:
		return "schema_version mismatch"
	var names: Array = Array(observation.get("feature_schema", []))
	var values: Array = Array(observation.get("values", []))
	if names.size() != feature_schema().size() or values.size() != names.size():
		return "feature count mismatch"
	var seen: Dictionary = {}
	for index in range(names.size()):
		var name := String(names[index])
		if name == "" or seen.has(name):
			return "duplicate or empty feature " + name
		seen[name] = true
		var value := float(values[index])
		if value < -1.0001 or value > 1.0001:
			return "out of range " + name
	return ""


static func _add(specs: Array, name: String, group: String, min_value: float, max_value: float, slot: int = -1) -> void:
	specs.append({"name": name, "group": group, "min": min_value, "max": max_value, "slot": slot})


static func _raw_value(snapshot: Dictionary, players: Array, spec: Dictionary) -> float:
	var name := String(spec["name"])
	var slot := int(spec.get("slot", -1))
	if slot >= 0 and name.begins_with("players.slot_"):
		if slot >= players.size():
			return 0.0
		return _player_value(Dictionary(players[slot]), name.get_slice(".", 2), snapshot)
	if name.begins_with("multiplayer.slot_"):
		var mask_slot := int(name.get_slice(".", 1).get_slice("_", 1))
		return 1.0 if mask_slot < players.size() and bool(Dictionary(players[mask_slot]).get("valid", true)) else 0.0
	var key := name.replace(".", "_")
	return float(snapshot.get(key, 0.0))


static func _player_value(player: Dictionary, field: String, snapshot: Dictionary) -> float:
	var boss_pos: Vector2 = Vector2(snapshot.get("umbra_position", Vector2.ZERO))
	if boss_pos == Vector2.ZERO:
		boss_pos = Vector2(float(snapshot.get("umbra_position_x", 0.0)), float(snapshot.get("umbra_position_y", 0.0)))
	var pos: Vector2 = Vector2(player.get("pos", Vector2.ZERO))
	var velocity: Vector2 = Vector2(player.get("velocity", Vector2.ZERO))
	match field:
		"valid": return 1.0 if bool(player.get("valid", true)) else 0.0
		"alive": return 1.0 if bool(player.get("alive", true)) else 0.0
		"relative_x": return pos.x - boss_pos.x
		"relative_y": return pos.y - boss_pos.y
		"velocity_x": return velocity.x
		"velocity_y": return velocity.y
		"hp_ratio": return float(player.get("hp", 0.0)) / maxf(1.0, float(player.get("hp_max", 1.0)))
		"build_cards": return float(player.get("cards", 0.0))
		"build_damage": return float(player.get("damage", 0.0))
		"manifestation": return float(maxi(0, MANIFESTATIONS.find(String(player.get("manifestation", "")))))
		"stunned": return 1.0 if bool(player.get("stunned", false)) else 0.0
		"silenced": return 1.0 if bool(player.get("silenced", false)) else 0.0
		"action_recent": return float(player.get("action_recent", 0.0))
	return 0.0


static func _normalize(value: float, min_value: float, max_value: float) -> float:
	if is_equal_approx(min_value, max_value):
		return 0.0
	return clampf((clampf(value, min_value, max_value) - min_value) / (max_value - min_value) * 2.0 - 1.0, -1.0, 1.0)


static func _local_player_snapshot(runtime: Object, boss_pos: Vector2) -> Dictionary:
	var alive := not bool(runtime.get("is_dead")) and _number(runtime.get("player_hp")) > 0.0
	return {"valid": alive, "alive": alive, "pos": Vector2(runtime.get("player_pos")), "velocity": Vector2.ZERO, "hp": _number(runtime.get("player_hp")), "hp_max": _number(runtime.get("player_hp_max")), "cards": _number(runtime.get("cards_bought")), "damage": _number(runtime.get("player_damage")), "manifestation": String(runtime.get("manifestation_key")), "stunned": _number(runtime.get("player_stun_timer")) > 0.0, "silenced": _number(runtime.get("player_silence_timer")) > 0.0, "action_recent": 0.0}


static func _number(value) -> float:
	return float(value) if value is float or value is int else 0.0


static func _edge_ratio(value: float, size: float) -> float:
	return clampf(minf(value, size - value) / maxf(1.0, size * 0.5), 0.0, 1.0)


static func _dimension_value(dimension: String) -> float:
	var known := ["vortice", "gravidade", "necrose", "ressonancia", "hemorragia", "atrito", "rastro"]
	return float(maxi(0, known.find(dimension))) / float(maxi(1, known.size() - 1))


static func _hazard_active(hazards: Array, kind: String) -> bool:
	for hazard_value in hazards:
		var hazard: Dictionary = Dictionary(hazard_value)
		if String(hazard.get("kind", "")) == kind or (kind == "overload_laser" and String(hazard.get("kind", "")) == "umbra_overload_laser"):
			return true
	return false


static func _projectile_pressure(bullets: Array, boss_pos: Vector2) -> float:
	var nearby := 0
	for bullet_value in bullets:
		if Vector2(Dictionary(bullet_value).get("pos", Vector2.ZERO)).distance_to(boss_pos) <= 420.0:
			nearby += 1
	return clampf(float(nearby) / 12.0, 0.0, 1.0)


static func _history_motion(history: Array, world: Vector2) -> Dictionary:
	if history.size() < 2:
		return {"motion": 0.0, "direction_change": 0.0, "distance_delta": 0.0}
	var older: Vector2 = Vector2(history[maxi(0, history.size() - 4)])
	var previous: Vector2 = Vector2(history[history.size() - 2])
	var newest: Vector2 = Vector2(history[history.size() - 1])
	var last_step := newest - previous
	var total_step := newest - older
	var changed := 1.0 if previous.distance_to(older) > 1.0 and last_step.length() > 1.0 and previous.direction_to(newest).dot(older.direction_to(previous)) < 0.2 else 0.0
	return {"motion": clampf(total_step.length() / maxf(1.0, world.length() * 0.25), 0.0, 1.0), "direction_change": changed, "distance_delta": clampf((newest.distance_to(world * 0.5) - older.distance_to(world * 0.5)) / maxf(1.0, world.length() * 0.5), -1.0, 1.0)}
