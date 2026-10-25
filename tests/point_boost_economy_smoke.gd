extends SceneTree

const ControllerScript = preload("res://scripts/systems/progression/point_boost_pickup_controller.gd")

class EconomyCore extends RefCounted:
	var heal_orbs: Array = []
	var player_pos := Vector2.ZERO
	var spawned := 0

	func _spawn_gameplay_orb(kind: String, pos: Vector2, data: Dictionary, _owner_peer: int, life: float) -> Dictionary:
		spawned += 1
		var orb := {"uid": "%s_%d" % [kind, spawned], "kind": kind, "pos": pos, "life": life, "max_life": life}
		orb.merge(data, true)
		heal_orbs.append(orb)
		return orb

	func _on_point_boost_spawned(_orb: Dictionary) -> void:
		pass

	func _on_point_boost_activated(_collector: int, _authority: bool) -> void:
		pass

	func _on_point_boost_final_warning() -> void:
		pass

	func _on_point_boost_expired(_authority: bool) -> void:
		pass


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("POINT_BOOST_ECONOMY_FAIL " + message)
	quit(1)


func _affordable_cards(points: int, seconds: int) -> Dictionary:
	var score := points
	var cost := 500
	var cards := 0
	var shops := seconds / 180
	for _shop in range(shops):
		for _slot in range(3):
			if score < cost:
				break
			score -= cost
			cost += 100
			cards += 1
	return {"cards": cards, "shops": shops, "remaining": score}


func _simulate(seconds: int, luck: float, enabled: bool) -> Dictionary:
	var core := EconomyCore.new()
	var controller = ControllerScript.new()
	controller.configure(core)
	var points := 0
	var drops := 0
	var snapshots := {}
	for second in range(1, seconds + 1):
		controller.update(1.0, true)
		var multiplier: float = controller.effective_point_multiplier(1.0) if enabled else 1.0
		points += int(round(20.0 * multiplier))
		if enabled:
			var orb: Dictionary = controller.on_enemy_defeated({"type": "common", "pos": Vector2.ZERO}, float(second), 1, luck, false, true)
			if not orb.is_empty():
				drops += 1
				controller.activate(1, true)
				core.heal_orbs.clear()
		if second in [300, 600, 900]:
			snapshots[second] = {"points": points, "drops": drops, "economy": _affordable_cards(points, second)}
	return {"points": points, "drops": drops, "snapshots": snapshots}


func _initialize() -> void:
	var baseline := _simulate(900, 0.0, false)
	var low_luck := _simulate(900, 0.0, true)
	var high_luck := _simulate(900, 999.0, true)
	for minute_mark in [300, 600, 900]:
		var base_row: Dictionary = baseline.snapshots[minute_mark]
		var boost_row: Dictionary = low_luck.snapshots[minute_mark]
		var uplift: float = float(boost_row.points - base_row.points) / float(maxi(1, base_row.points))
		_check(uplift <= 0.06, "cumulative point uplift exceeded 6 percent at %d seconds" % minute_mark)
		var base_cards: int = int(Dictionary(base_row.economy).cards)
		var boost_cards: int = int(Dictionary(boost_row.economy).cards)
		_check(boost_cards - base_cards <= 1, "pickup added more than one early card at %d seconds" % minute_mark)
		_check(int(Dictionary(base_row.economy).shops) == int(Dictionary(boost_row.economy).shops), "pickup changed shop cadence")
	_check(int(Dictionary(low_luck.snapshots[300]).drops) == 0, "pickup affected economy at five minutes")
	_check(int(low_luck.drops) <= 3, "low-luck run exceeded controlled drop budget")
	_check(int(high_luck.drops) <= int(low_luck.drops) + 1, "high luck bypassed cooldown/window budget")
	_check(int(high_luck.drops) <= 4, "high-luck run produced too many drops")
	var points_per_minute: float = float(low_luck.points) / 15.0
	print("POINT_BOOST_ECONOMY_SMOKE_OK baseline=%d boosted=%d ppm=%.1f drops_low=%d drops_high=%d cards_5_10_15=%d/%d/%d" % [
		int(baseline.points), int(low_luck.points), points_per_minute, int(low_luck.drops), int(high_luck.drops),
		int(Dictionary(Dictionary(low_luck.snapshots[300]).economy).cards),
		int(Dictionary(Dictionary(low_luck.snapshots[600]).economy).cards),
		int(Dictionary(Dictionary(low_luck.snapshots[900]).economy).cards),
	])
	quit(0)
