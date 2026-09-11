extends SceneTree

const SelfplayCore = preload("res://tools/umbra_selfplay_core.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var core := SelfplayCore.new()
	var result: Dictionary = core.run_training({
		"episodes": 8,
		"max_steps": 180,
		"seed": 20260826
	})
	if not bool(result.get("ok", false)):
		_fail("result did not finish with ok=true")
		return
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	if int(summary.get("episodes", 0)) != 8:
		_fail("unexpected episode count: %s" % str(summary.get("episodes", null)))
		return
	var winners: Dictionary = Dictionary(summary.get("winners", {}))
	var total_winners: int = int(winners.get("UMBRA", 0)) + int(winners.get("APOLO", 0)) + int(winners.get("DRAW", 0))
	if total_winners != 8:
		_fail("winner accounting mismatch: %s" % str(winners))
		return
	var memory: Dictionary = Dictionary(result.get("memory", {}))
	var actions: Dictionary = Dictionary(memory.get("actions", {}))
	for action in ["ATAQUE", "SIFON", "LASER_SOBRECARGA", "PRAGA_RATOS"]:
		if not actions.has(action):
			_fail("missing UMBRA action memory: %s" % action)
			return
	if Dictionary(memory.get("scenarios", {})).is_empty():
		_fail("scenario memory was not populated")
		return
	var features: Array = Array(summary.get("anti_aliasing_features", []))
	for feature in ["incoming_projectiles", "telegraphed_hazards", "cards", "known_enemy_actions", "recent_motion"]:
		if not features.has(feature):
			_fail("missing anti-aliasing feature: %s" % feature)
			return
	var episodes: Array = Array(result.get("episodes", []))
	if episodes.size() != 8:
		_fail("unexpected episode report size: %d" % episodes.size())
		return
	print("UMBRA_SELFPLAY_SMOKE_OK episodes=8 umbra_wins=%d apolo_wins=%d draws=%d" % [
		int(winners.get("UMBRA", 0)),
		int(winners.get("APOLO", 0)),
		int(winners.get("DRAW", 0))
	])
	quit(0)


func _fail(message: String) -> void:
	push_error("UMBRA_SELFPLAY_SMOKE_FAIL: %s" % message)
	quit(1)
