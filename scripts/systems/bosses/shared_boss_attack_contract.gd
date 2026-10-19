class_name RTSharedBossAttackContract
extends RefCounted

## Small, data-only contract shared by authoritative boss attacks.
##
## The runtime remains responsible for hit tests and damage.  This helper only
## owns deterministic target rotation, immutable event metadata and the local
## visual-event ledger used when snapshots are replayed.

const MAX_VISUAL_EVENT_STAGES := 96

var _seen_visual_event_stages: Dictionary = {}


func tick_target_grace(grace_by_peer: Dictionary, delta: float) -> Dictionary:
	var next: Dictionary = grace_by_peer.duplicate()
	for peer_key in grace_by_peer.keys():
		var remaining := maxf(0.0, float(grace_by_peer.get(peer_key, 0.0)) - maxf(0.0, delta))
		if remaining <= 0.0:
			next.erase(peer_key)
		else:
			next[peer_key] = remaining
	return next


func select_target(targets: Array, grace_by_peer: Dictionary, last_target_peer_id: int, sequence: int) -> Dictionary:
	var open_targets: Array = []
	for value in targets:
		var target := Dictionary(value)
		var peer_id := int(target.get("peer_id", 0))
		if peer_id <= 0 or not bool(target.get("eligible", true)):
			continue
		if float(grace_by_peer.get(peer_id, 0.0)) > 0.0:
			continue
		open_targets.append(target)
	if open_targets.is_empty():
		return {}
	var preferred: Array = []
	if open_targets.size() > 1:
		for value in open_targets:
			var target := Dictionary(value)
			if int(target.get("peer_id", 0)) != last_target_peer_id:
				preferred.append(target)
	else:
		preferred = open_targets
	var pool: Array = preferred if not preferred.is_empty() else open_targets
	pool.sort_custom(func(a, b): return int(Dictionary(a).get("peer_id", 0)) < int(Dictionary(b).get("peer_id", 0)))
	return Dictionary(pool[posmod(sequence, pool.size())])


func claim_target_grace(grace_by_peer: Dictionary, peer_id: int, duration: float) -> void:
	if peer_id > 0 and duration > 0.0:
		grace_by_peer[peer_id] = duration


func make_authoritative_event(prefix: String, sequence: int, seed: int, target_peer_id: int, started_ms: int) -> Dictionary:
	return {
		"event_id": "%s_%d_%d" % [prefix, sequence, started_ms],
		"seed": seed,
		"target_peer": target_peer_id
	}


func build_telegraphed_attack(kind: String, event: Dictionary, fields: Dictionary) -> Dictionary:
	var attack := fields.duplicate(true)
	attack["kind"] = kind
	attack["event_id"] = String(event.get("event_id", ""))
	attack["seed"] = int(event.get("seed", 0))
	attack["target_peer"] = int(event.get("target_peer", 0))
	attack["impact"] = bool(attack.get("impact", false))
	attack["hit"] = Dictionary(attack.get("hit", {}))
	return attack


func claim_impact(attack: Dictionary) -> bool:
	if bool(attack.get("impact", false)):
		return false
	attack["impact"] = true
	return true


func claim_peer_hit(attack: Dictionary, peer_id: int) -> bool:
	if peer_id <= 0:
		return false
	var hits := Dictionary(attack.get("hit", {}))
	var key := "peer_%d" % peer_id
	if bool(hits.get(key, false)):
		return false
	hits[key] = true
	attack["hit"] = hits
	return true


func consume_visual_events(attacks: Array) -> Array:
	var events: Array = []
	for value in attacks:
		var attack := Dictionary(value)
		var event_id := String(attack.get("event_id", ""))
		if event_id.is_empty():
			continue
		var stage := "impact" if bool(attack.get("impact", false)) else "telegraph"
		var key := "%s:%s" % [event_id, stage]
		if _seen_visual_event_stages.has(key):
			continue
		_seen_visual_event_stages[key] = true
		events.append({
			"event_id": event_id,
			"stage": stage,
			"kind": String(attack.get("kind", "")),
			"seed": int(attack.get("seed", 0)),
			"target_peer": int(attack.get("target_peer", 0))
		})
	_trim_visual_event_ledger()
	return events


func has_seen_visual_event(event_id: String, stage: String) -> bool:
	return _seen_visual_event_stages.has("%s:%s" % [event_id, stage])


func forget_visual_events_with_prefix(prefix: String) -> void:
	for key in _seen_visual_event_stages.keys():
		if String(key).begins_with(prefix):
			_seen_visual_event_stages.erase(key)


func reset_visual_events() -> void:
	_seen_visual_event_stages.clear()


func _trim_visual_event_ledger() -> void:
	if _seen_visual_event_stages.size() <= MAX_VISUAL_EVENT_STAGES:
		return
	var keys: Array = _seen_visual_event_stages.keys()
	while _seen_visual_event_stages.size() > MAX_VISUAL_EVENT_STAGES / 2 and not keys.is_empty():
		_seen_visual_event_stages.erase(keys.pop_front())
