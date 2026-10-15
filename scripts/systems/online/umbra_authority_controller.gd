extends RefCounted
class_name RTUmbraAuthorityController

# Keeps UMBRA 2.0 decision ownership off replicas. This owner only transports
# compact, replay-safe decisions; weights and recurrent memory stay on host.
const ObservationSchema = preload("res://scripts/systems/umbra_observation_schema.gd")
const PROTOCOL_VERSION := 1

var next_sequence := 0
var last_applied_sequence := -1
var latest_event: Dictionary = {}


func reset() -> void:
	next_sequence = 0
	last_applied_sequence = -1
	latest_event.clear()


func build_authoritative_decision(runtime: Object, policy: Object, available_actions: Array, fallback_action: String) -> Dictionary:
	var observation := ObservationSchema.build_from_runtime(runtime)
	var target_mask: Array = Array(observation.get("valid_player_mask", []))
	var action_mask := _action_mask(available_actions)
	var action := fallback_action
	var target_slot := _first_valid_slot(target_mask)
	var space := _fallback_space(runtime, target_slot)
	var source := "heuristic_fallback"
	if policy != null and policy.has_method("step"):
		var prediction: Dictionary = policy.call("step", observation, action_mask, target_mask)
		if not prediction.has("error"):
			var action_index := clampi(int(prediction.get("action_index", -1)), 0, ObservationSchema.ACTIONS.size() - 1)
			var predicted_action := String(ObservationSchema.ACTIONS[action_index])
			if available_actions.has(predicted_action):
				action = predicted_action
			target_slot = clampi(int(prediction.get("target_slot", target_slot)), 0, target_mask.size() - 1) if not target_mask.is_empty() else -1
			if target_slot < 0 or target_slot >= target_mask.size() or float(target_mask[target_slot]) <= 0.0:
				target_slot = _first_valid_slot(target_mask)
			space = Dictionary(prediction.get("spatial", space)).duplicate(true)
			source = "multihead_policy"
	# An encounter with no valid living target cannot begin a hostile action.
	# This is deliberately decided on the host rather than trusting a stale
	# replica mask during a death/revive transition.
	if target_slot < 0:
		action = "NENHUMA"
	next_sequence += 1
	var target_peer_id := _peer_id_for_slot(runtime, target_slot)
	var random: RandomNumberGenerator = runtime.get("rng")
	var event := {
		"protocol_version": PROTOCOL_VERSION,
		"sequence": next_sequence,
		"event_id": "umbra:%d" % next_sequence,
		"action": action,
		"target_slot": target_slot,
		"target_peer_id": target_peer_id,
		"space": _normalized_space(space),
		"seed": random.randi() if random != null else next_sequence,
		"issued_at_ms": Time.get_ticks_msec(),
		"source": source
	}
	latest_event = event.duplicate(true)
	return event


func revalidate_before_execution(runtime: Object, event: Dictionary) -> Dictionary:
	var result := event.duplicate(true)
	var target_peer_id := int(result.get("target_peer_id", 0))
	if target_peer_id != 0 and _peer_is_eligible(runtime, target_peer_id):
		latest_event = result.duplicate(true)
		return result
	var fallback_slot := _first_valid_slot(Array(ObservationSchema.build_from_runtime(runtime).get("valid_player_mask", [])))
	result["target_slot"] = fallback_slot
	result["target_peer_id"] = _peer_id_for_slot(runtime, fallback_slot)
	if fallback_slot < 0:
		result["action"] = "NENHUMA"
	result["target_revalidated"] = true
	latest_event = result.duplicate(true)
	return result


func accept_replica_event(event_value) -> bool:
	if not event_value is Dictionary:
		return false
	var event: Dictionary = event_value
	if int(event.get("protocol_version", -1)) != PROTOCOL_VERSION:
		return false
	var sequence := int(event.get("sequence", -1))
	if sequence <= last_applied_sequence:
		return false
	last_applied_sequence = sequence
	latest_event = event.duplicate(true)
	return true


func public_event() -> Dictionary:
	return latest_event.duplicate(true)


func _action_mask(available_actions: Array) -> Array:
	var mask: Array = []
	for action in ObservationSchema.ACTIONS:
		mask.append(1.0 if available_actions.has(action) else 0.0)
	return mask


func _first_valid_slot(mask: Array) -> int:
	for index in range(mask.size()):
		if float(mask[index]) > 0.0:
			return index
	return -1


func _peer_id_for_slot(runtime: Object, slot: int) -> int:
	if slot < 0:
		return 0
	if slot == 0:
		return int(runtime.call("_mp_unique_id"))
	var peers: Array = Dictionary(runtime.get("net_players_by_peer")).keys()
	peers.sort()
	var index := slot - 1
	return int(peers[index]) if index >= 0 and index < peers.size() else 0


func _peer_is_eligible(runtime: Object, peer_id: int) -> bool:
	if peer_id == int(runtime.call("_mp_unique_id")):
		return not bool(runtime.get("is_dead")) and float(runtime.get("player_hp")) > 0.0
	var state: Dictionary = Dictionary(Dictionary(runtime.get("net_players_by_peer")).get(peer_id, {}))
	return not state.is_empty() and bool(state.get("alive", not bool(state.get("dead", false)))) and not bool(state.get("eliminated", false)) and float(state.get("hp", 0.0)) > 0.0


func _fallback_space(runtime: Object, target_slot: int) -> Dictionary:
	var peer_id := _peer_id_for_slot(runtime, target_slot)
	var target_pos: Vector2 = Vector2(runtime.get("player_pos"))
	if peer_id != int(runtime.call("_mp_unique_id")):
		var state: Dictionary = Dictionary(Dictionary(runtime.get("net_players_by_peer")).get(peer_id, {}))
		target_pos = Vector2(state.get("pos", target_pos))
	var world: Vector2 = ObservationSchema.DEFAULT_WORLD_SIZE
	var direction := (target_pos - Vector2(runtime.get("boss_pos"))).normalized()
	return {"x": clampf(target_pos.x / maxf(1.0, world.x), 0.0, 1.0), "y": clampf(target_pos.y / maxf(1.0, world.y), 0.0, 1.0), "direction_x": direction.x, "direction_y": direction.y}


func _normalized_space(raw: Dictionary) -> Dictionary:
	return {"x": clampf(float(raw.get("x", 0.5)), 0.0, 1.0), "y": clampf(float(raw.get("y", 0.5)), 0.0, 1.0), "direction_x": clampf(float(raw.get("direction_x", 0.0)), -1.0, 1.0), "direction_y": clampf(float(raw.get("direction_y", 0.0)), -1.0, 1.0)}
