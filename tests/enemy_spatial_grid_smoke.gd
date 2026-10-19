extends SceneTree

const EnemyManagerScript = preload("res://scripts/systems/enemy_manager.gd")

var failed := false


class FakeGame extends Node:
	var enemies: Array = []
	var necronada_remnants: Array = []
	var boss_active := false
	var boss_hp := 0.0
	var boss_pos := Vector2.ZERO
	var player_pos := Vector2(1500.0, 800.0)
	var WORLD_SIZE := Vector2(1600.0, 900.0)

	func _entity_physical_radius(entity: Dictionary) -> float:
		return float(entity.get("radius", 22.0))

	func _local_player_targetable() -> bool:
		return true


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("ENEMY_SPATIAL_GRID_FAIL " + message)


func _entity(uid: int, pos: Vector2, radius: float = 22.0) -> Dictionary:
	return {"uid": uid, "pos": pos, "hp": 100.0, "radius": radius}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := FakeGame.new()
	root.add_child(game)
	var manager := EnemyManagerScript.new()
	game.add_child(manager)
	manager.bind_game(game)

	for index in range(400):
		var column: int = index % 20
		var row: int = index / 20
		game.enemies.append(_entity(index, Vector2(55.0 + column * 76.0, 55.0 + row * 40.0)))
	manager.rebuild_spatial_index()
	var candidate_checks := 0
	for enemy in game.enemies:
		candidate_checks += manager.avoidance_neighbors(Vector2(enemy["pos"]), 22.0).size()
	var brute_checks: int = game.enemies.size() * game.enemies.size()
	_check(candidate_checks < brute_checks / 4, "spatial lookup did not reduce the quadratic candidate set")

	game.enemies = [
		_entity(1, Vector2(200.0, 200.0)),
		_entity(2, Vector2(214.0, 200.0)),
		_entity(3, Vector2(700.0, 500.0))
	]
	game.necronada_remnants = [
		_entity(101, Vector2(420.0, 300.0), 8.0),
		_entity(102, Vector2(440.0, 300.0), 8.0)
	]
	var distant_before: Vector2 = game.enemies[2]["pos"]
	manager.apply_entity_separation(1.0 / 60.0)
	_check(Vector2(game.enemies[0]["pos"]).distance_to(Vector2(game.enemies[1]["pos"])) >= 43.9, "overlapping enemies were not separated with the existing radii")
	_check(Vector2(game.necronada_remnants[0]["pos"]).distance_to(Vector2(game.necronada_remnants[1]["pos"])) >= 49.9, "remnant-specific 50px separation was lost")
	_check(Vector2(game.enemies[2]["pos"]).is_equal_approx(distant_before), "distant entity moved without a nearby collision")
	for entity in game.enemies + game.necronada_remnants:
		var pos := Vector2(entity["pos"])
		_check(pos.x >= 40.0 and pos.y >= 40.0 and pos.x <= 1560.0 and pos.y <= 860.0, "separation escaped world bounds")

	manager.rebuild_spatial_index()
	var ordered := manager.nearby_entity_indices(Vector2(210.0, 200.0), 100.0, false)
	_check(ordered == [0, 1], "nearby enemy order changed and could alter avoidance determinism")

	print("ENEMY_SPATIAL_GRID_OK entities=400 brute_candidates=%d spatial_candidates=%d reduction=%.1fx" % [
		brute_checks,
		candidate_checks,
		float(brute_checks) / maxf(1.0, float(candidate_checks))
	])
	game.free()
	quit(1 if failed else 0)
