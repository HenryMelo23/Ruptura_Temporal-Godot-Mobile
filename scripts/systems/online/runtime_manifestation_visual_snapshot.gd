class_name RTManifestationVisualSnapshot
extends RefCounted

# Presentation-only mirror. It captures the same state dictionaries consumed by
# the local renderers; it never contains damage, cooldown authority or hit data.
const MAX_SHORT_EVENTS := 8
const MAX_PERSISTENT_ITEMS := 12
const MAX_MARKED_ENEMIES := 12


static func capture(game: Node, action: int, manifestation_key: String) -> Dictionary:
	var snapshot := {
		"manifestation_key": manifestation_key,
		"evolution_ids": _evolution_ids(game),
		"source_time": float(game.time_alive)
	}
	if action == game.NET_ABILITY_ATTACK:
		_capture_attack(game, manifestation_key, snapshot)
	elif action == game.NET_ABILITY_SKILL:
		_capture_skill(game, manifestation_key, snapshot)
	elif action == game.NET_ABILITY_SECONDARY:
		_capture_secondary(game, manifestation_key, snapshot)
	elif action == game.NET_ABILITY_TELEPORT:
		_capture_teleport(game, manifestation_key, snapshot)
	return snapshot


static func _capture_attack(game: Node, key: String, snapshot: Dictionary) -> void:
	match key:
		"lacerante":
			snapshot["slashes"] = _tail(game.slashes, 1)
		"acorrentada":
			# The attack is the pair of physical chains themselves.  Preserve the
			# exact local geometry/motion dictionaries so the receiver can call the
			# same world renderer instead of inventing a lightweight substitute.
			snapshot["acorrentada_worn_chains"] = _compact_acorrentada_worn_chains(game.acorrentada_worn_chains)
			snapshot["acorrentada_visuals"] = _tail(game.acorrentada_visuals, MAX_SHORT_EVENTS)
			snapshot["acorrentada_tension"] = float(game.acorrentada_tension)
		"eclipsada":
			snapshot["eclipsada_vfx"] = _tail(game.eclipsada_vfx, 2)
		_:
			pass # Projectile visuals already use the canonical remote projectile renderer.


static func _capture_skill(game: Node, key: String, snapshot: Dictionary) -> void:
	match key:
		"barometrico":
			snapshot["barometric"] = game.henry_barometric_ability_controller.visual_snapshot()
		"eletrica":
			snapshot["eletrica_waves"] = _tail(game.eletrica_waves, 1)
		"lacerante":
			snapshot["slashes"] = _tail(game.slashes, 1)
		"prismatica":
			snapshot["prisms"] = _tail(game.prisms, 1)
		"retornante":
			snapshot["return_bullets"] = _tail(game.return_bullets, 8)
		"parasitica":
			snapshot["parasite_spit_zones"] = _tail(game.parasite_spit_zones, 1)
		"gravitante":
			snapshot["gravitante_vfx_events"] = _tail_matching(game.gravitante_vfx_events, "kind", "gravity_q", 1)
			snapshot["orbitals"] = _tail(game.orbitals, MAX_PERSISTENT_ITEMS)
		"ancorada":
			snapshot["anchors"] = _tail_matching_prefix(game.anchors, "source", "ancorada_", MAX_PERSISTENT_ITEMS)
		"cartografica":
			_capture_cartographic(game, snapshot)
		"mnesica":
			snapshot["slashes"] = _tail(game.slashes, MAX_SHORT_EVENTS)
			snapshot["shockwaves"] = _tail(game.shockwaves, MAX_SHORT_EVENTS)
			snapshot["enemy_markers"] = _enemy_markers(game.enemies, key)
		"ressonante":
			snapshot["shockwaves"] = _tail(game.shockwaves, MAX_SHORT_EVENTS)
			snapshot["enemy_markers"] = _enemy_markers(game.enemies, key)
		"contratual":
			snapshot["contractual_notifications"] = _tail(game.contractual_notifications, MAX_SHORT_EVENTS)
			snapshot["enemy_markers"] = _enemy_markers(game.enemies, key)
		"acorrentada":
			snapshot["acorrentada_links"] = _tail(game.acorrentada_links, MAX_PERSISTENT_ITEMS)
		"eclipsada":
			snapshot["eclipsada_vfx"] = _tail(game.eclipsada_vfx, 4)
		"bombastica":
			snapshot["bombastica_bombs"] = _tail(game.bombastica_bombs, 1)
			snapshot["bombastica_vfx"] = _tail(game.bombastica_vfx, 2)
		"necronada":
			_capture_necronada(game, snapshot)
		_:
			pass


static func _capture_secondary(game: Node, key: String, snapshot: Dictionary) -> void:
	# Eclipsada keeps the concrete form in the kind (sol/lua_eclipse).  The
	# stable manifestation key still owns both forms, so the visual snapshot
	# must preserve the concrete local dictionary instead of falling back to an
	# approximate network replica.
	var secondary := _last_matching_prefix(game.manifestation_secondaries, "kind", "eclipsada_") if key == "eclipsada" else _last_matching(game.manifestation_secondaries, "kind", key)
	if not secondary.is_empty():
		snapshot["secondary"] = secondary
	match key:
		"barometrico":
			snapshot["barometric"] = game.henry_barometric_ability_controller.visual_snapshot()
		"gravitante":
			snapshot["orbitals"] = _tail(game.orbitals, MAX_PERSISTENT_ITEMS)
		"ancorada":
			snapshot["anchors"] = _tail_matching_prefix(game.anchors, "source", "ancorada_", MAX_PERSISTENT_ITEMS)
		"cartografica":
			_capture_cartographic(game, snapshot)
		"mnesica", "ressonante":
			snapshot["enemy_markers"] = _enemy_markers(game.enemies, key)
			snapshot["shockwaves"] = _tail(game.shockwaves, MAX_SHORT_EVENTS)
		"contratual":
			snapshot["contractual_notifications"] = _tail(game.contractual_notifications, MAX_SHORT_EVENTS)
			snapshot["enemy_markers"] = _enemy_markers(game.enemies, key)
		"acorrentada":
			snapshot["acorrentada_links"] = _tail(game.acorrentada_links, MAX_PERSISTENT_ITEMS)
		"eclipsada":
			snapshot["eclipsada_vfx"] = _tail(game.eclipsada_vfx, MAX_SHORT_EVENTS)
		"bombastica":
			snapshot["bombastica_bombs"] = _tail(game.bombastica_bombs, 2)
			snapshot["bombastica_vfx"] = _tail(game.bombastica_vfx, MAX_SHORT_EVENTS)
		"necronada":
			_capture_necronada(game, snapshot)
		_:
			pass


static func _capture_teleport(game: Node, key: String, snapshot: Dictionary) -> void:
	snapshot["tp_effects"] = _tail(game.tp_effects, 2)
	match key:
		"lacerante":
			snapshot["slashes"] = _tail(game.slashes, 3)
		"prismatica":
			snapshot["prisms"] = _tail(game.prisms, 2)
		"parasitica":
			snapshot["tp_effects"] = _tail(game.tp_effects, 8)
		"gravitante":
			snapshot["gravitante_vfx_events"] = _tail(game.gravitante_vfx_events, 3)
		"ancorada":
			snapshot["anchors"] = _tail_matching_prefix(game.anchors, "source", "ancorada_", 4)
		"cartografica":
			_capture_cartographic(game, snapshot)
		"contratual":
			snapshot["contractual_notifications"] = _tail(game.contractual_notifications, 2)
		"acorrentada":
			snapshot["acorrentada_links"] = _tail(game.acorrentada_links, 4)
		"eclipsada":
			snapshot["eclipsada_vfx"] = _tail(game.eclipsada_vfx, 3)
		"necronada":
			snapshot["necronada_vfx"] = _tail(game.necronada_vfx, 3)
		_:
			pass


static func _capture_cartographic(game: Node, snapshot: Dictionary) -> void:
	snapshot["cartographic_coords"] = _tail(game.cartographic_coords, 3)
	snapshot["cartographic_route_timer"] = float(game.cartographic_route_timer)
	snapshot["cartographic_trace_flash"] = float(game.cartographic_trace_flash)
	snapshot["cartographic_complete_map_timer"] = float(game.cartographic_complete_map_timer)


static func _capture_necronada(game: Node, snapshot: Dictionary) -> void:
	snapshot["necronada_vestiges"] = _tail(game.necronada_vestiges, MAX_PERSISTENT_ITEMS)
	snapshot["necronada_remnants"] = _tail(game.necronada_remnants, MAX_PERSISTENT_ITEMS)
	snapshot["necronada_vfx"] = _tail(game.necronada_vfx, MAX_SHORT_EVENTS)
	snapshot["necronada_requiem"] = Dictionary(game.necronada_requiem).duplicate(true)


static func _evolution_ids(game: Node) -> Array:
	var result: Array = []
	for choice_value in game.manifest_evolution_state.get("choices", []):
		if not choice_value is Dictionary:
			continue
		var choice: Dictionary = choice_value
		var evolution_id := String(choice.get("evolution", choice.get("id", "")))
		if evolution_id != "" and not result.has(evolution_id):
			result.append(evolution_id)
		if result.size() >= 12:
			break
	return result


static func _enemy_markers(enemies: Array, key: String) -> Array:
	var result: Array = []
	for enemy_value in enemies:
		if not enemy_value is Dictionary:
			continue
		var enemy: Dictionary = enemy_value
		var include := false
		match key:
			"mnesica": include = not Array(enemy.get("mnesic_memories", [])).is_empty() or float(enemy.get("mnesic_dejavu", 0.0)) > 0.0 or float(enemy.get("mnesic_tricked", 0.0)) > 0.0
			"ressonante": include = not Array(enemy.get("resonant_notes", [])).is_empty() or float(enemy.get("resonant_flash", 0.0)) > 0.0
			"contratual": include = enemy.has("contract_clause")
		if not include:
			continue
		result.append(Dictionary(enemy).duplicate(true))
		if result.size() >= MAX_MARKED_ENEMIES:
			break
	return result


static func _last_matching(values: Array, field: String, expected: String) -> Dictionary:
	for index in range(values.size() - 1, -1, -1):
		if values[index] is Dictionary and String(values[index].get(field, "")) == expected:
			return Dictionary(values[index]).duplicate(true)
	return {}


static func _compact_acorrentada_worn_chains(values: Array) -> Array:
	var result: Array = []
	for value in values:
		if not value is Dictionary:
			continue
		var entry: Dictionary = value
		var physics: Dictionary = entry.get("physics", {})
		var points: Array = []
		for point_value in physics.get("points", []):
			if point_value is Dictionary:
				points.append(Vector2(Dictionary(point_value).get("pos", Vector2.ZERO)))
			elif point_value is Vector2:
				points.append(point_value)
		var compact := {
			"index": int(entry.get("index", result.size())),
			"physics": {
				"a": Vector2(physics.get("a", Vector2.ZERO)),
				"b": Vector2(physics.get("b", Vector2.ZERO)),
				"points": points
			}
		}
		if entry.has("attack_motion"):
			var motion: Dictionary = entry.get("attack_motion", {})
			compact["attack_motion"] = {"stage": int(motion.get("stage", 1)), "elapsed": float(motion.get("elapsed", 0.0))}
		result.append(compact)
		if result.size() >= 2:
			break
	return result


static func _last_matching_prefix(values: Array, field: String, prefix: String) -> Dictionary:
	for index in range(values.size() - 1, -1, -1):
		if values[index] is Dictionary and String(values[index].get(field, "")).begins_with(prefix):
			return Dictionary(values[index]).duplicate(true)
	return {}


static func _tail_matching(values: Array, field: String, expected: String, limit: int) -> Array:
	var result: Array = []
	for index in range(values.size() - 1, -1, -1):
		if values[index] is Dictionary and String(values[index].get(field, "")) == expected:
			result.push_front(Dictionary(values[index]).duplicate(true))
			if result.size() >= limit:
				break
	return result


static func _tail_matching_prefix(values: Array, field: String, prefix: String, limit: int) -> Array:
	var result: Array = []
	for index in range(values.size() - 1, -1, -1):
		if values[index] is Dictionary and String(values[index].get(field, "")).begins_with(prefix):
			result.push_front(Dictionary(values[index]).duplicate(true))
			if result.size() >= limit:
				break
	return result


static func _tail(values: Array, limit: int) -> Array:
	var result: Array = []
	for index in range(maxi(0, values.size() - limit), values.size()):
		if values[index] is Dictionary:
			result.append(Dictionary(values[index]).duplicate(true))
	return result
