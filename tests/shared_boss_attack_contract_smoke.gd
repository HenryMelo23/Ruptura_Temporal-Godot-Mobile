extends SceneTree

const SharedBossAttackContract = preload("res://scripts/systems/bosses/shared_boss_attack_contract.gd")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("SHARED_BOSS_ATTACK_CONTRACT_SMOKE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	var contract = SharedBossAttackContract.new()
	var targets: Array = [
		{"peer_id": 3, "eligible": true},
		{"peer_id": 1, "eligible": true},
		{"peer_id": 2, "eligible": false}
	]
	var first: Dictionary = contract.select_target(targets, {}, 0, 0)
	_check(int(first.get("peer_id", 0)) == 1, "target order is not deterministic")
	var grace := {}
	contract.claim_target_grace(grace, 1, 4.0)
	var second: Dictionary = contract.select_target(targets, grace, 1, 1)
	_check(int(second.get("peer_id", 0)) == 3, "grace did not avoid repeated living target")
	grace = contract.tick_target_grace(grace, 4.1)
	_check(grace.is_empty(), "expired grace remained")

	var event: Dictionary = contract.make_authoritative_event("test_hunt", 7, 9381, 3, 12345)
	_check(String(event.get("event_id", "")) == "test_hunt_7_12345", "event id is not stable")
	_check(int(event.get("seed", 0)) == 9381 and int(event.get("target_peer", 0)) == 3, "event metadata changed")
	var attack: Dictionary = contract.build_telegraphed_attack("hunt_mark", event, {"age": 0.0, "hit": {}})
	_check(contract.claim_impact(attack), "first impact was rejected")
	_check(not contract.claim_impact(attack), "impact was accepted twice")
	_check(contract.claim_peer_hit(attack, 3), "first target hit was rejected")
	_check(not contract.claim_peer_hit(attack, 3), "same target was charged twice")
	_check(contract.claim_peer_hit(attack, 1), "second target hit was rejected")

	attack["impact"] = false
	var first_visual: Array = contract.consume_visual_events([attack])
	_check(first_visual.size() == 1 and String(Dictionary(first_visual[0]).get("stage", "")) == "telegraph", "telegraph was not emitted once")
	_check(contract.consume_visual_events([attack]).is_empty(), "repeated snapshot replayed telegraph")
	attack["impact"] = true
	var impact_visual: Array = contract.consume_visual_events([attack])
	_check(impact_visual.size() == 1 and String(Dictionary(impact_visual[0]).get("stage", "")) == "impact", "impact was not emitted once")
	_check(contract.consume_visual_events([attack]).is_empty(), "repeated snapshot replayed impact")

	print("SHARED_BOSS_ATTACK_CONTRACT_SMOKE_OK target_rotation=true authority_metadata=true single_hit=true idempotent_visual=true")
	quit(0)
