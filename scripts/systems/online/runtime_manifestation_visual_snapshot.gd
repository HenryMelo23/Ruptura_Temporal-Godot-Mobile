class_name RTManifestationVisualSnapshot
extends RefCounted

# Presentation-only mirror. It captures the same state dictionaries consumed by
# the local renderers; it never contains damage, cooldown authority or hit data.
const MAX_SHORT_EVENTS := 8
const MAX_PERSISTENT_ITEMS := 12


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
		"parasitica":
			snapshot["parasite_spit_zones"] = _tail(game.parasite_spit_zones, 1)
		"gravitante":
			snapshot["gravitante_vfx_events"] = _tail_matching(game.gravitante_vfx_events, "kind", "gravity_q", 1)
			snapshot["orbitals"] = _tail(game.orbitals, MAX_PERSISTENT_ITEMS)
		_:
			pass


static func _capture_secondary(game: Node, key: String, snapshot: Dictionary) -> void:
	var secondary := _last_matching(game.manifestation_secondaries, "kind", key)
	if not secondary.is_empty():
		snapshot["secondary"] = secondary
	match key:
		"barometrico":
			snapshot["barometric"] = game.henry_barometric_ability_controller.visual_snapshot()
		"gravitante":
			snapshot["orbitals"] = _tail(game.orbitals, MAX_PERSISTENT_ITEMS)
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
		_:
			pass


static func _evolution_ids(game: Node) -> Array:
	var result: Array = []
	if not game.MANIFEST_EVOLUTIONS_ENABLED:
		return result
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


static func _last_matching(values: Array, field: String, expected: String) -> Dictionary:
	for index in range(values.size() - 1, -1, -1):
		if values[index] is Dictionary and String(values[index].get(field, "")) == expected:
			return Dictionary(values[index]).duplicate(true)
	return {}


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
