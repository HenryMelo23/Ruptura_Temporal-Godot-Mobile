extends SceneTree

const Catalog = preload("res://scripts/systems/events/runtime_event_catalog.gd")
const ControllerScript = preload("res://scripts/systems/progression/point_boost_pickup_controller.gd")

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("POINT_BOOST_PICKUP_FAIL " + message)
	failed = true


func _enemy(uid: int, enemy_type: String = "common") -> Dictionary:
	return {
		"uid": uid,
		"type": enemy_type,
		"pos": game.player_pos + Vector2(110.0, 0.0),
		"hp": 1.0,
		"max_hp": 20.0,
		"points": 20,
		"speed": 0.0,
		"damage": 1.0,
	}


func _feed_controller(count: int, event_points_active: bool = false, enemy_type: String = "common") -> void:
	for index in range(count):
		game.point_boost_pickup_controller.on_enemy_defeated(
			_enemy(7000 + index, enemy_type), game.time_alive, game.current_phase, game.luck,
			event_points_active, game._is_world_authority()
		)


func _points_event_snapshot() -> Dictionary:
	return {
		"active": true,
		"schema": Catalog.SCHEMA,
		"schema_version": Catalog.SCHEMA_VERSION,
		"sequence": 991,
		"type": "double_points",
		"label": "PONTOS EM DOBRO",
		"stat": "points",
		"duration": 20.0,
		"remaining": 20.0,
		"multiplier": 2.0,
	}


func _run() -> void:
	await process_frame
	game._start_game()
	game.run_tutorial_enabled = false
	game.mode = "game"
	game.current_phase = 1
	game.player_pos = Vector2(640, 360)
	game.heal_orbs.clear()
	game.point_boost_pickup_controller.reset()

	game.time_alive = float(ControllerScript.CONFIG["min_run_time"]) - 0.1
	_feed_controller(180)
	_check(game.heal_orbs.is_empty(), "pickup spawned before minimum run time")

	game.time_alive = float(ControllerScript.CONFIG["min_run_time"])
	var threshold := int(ControllerScript.CONFIG["charge_threshold"])
	_feed_controller(threshold - 1)
	_check(game.heal_orbs.is_empty(), "pickup spawned before deterministic threshold")
	_feed_controller(1)
	var boost_orbs: Array = game.heal_orbs.filter(func(orb): return String(orb.get("kind", "")) == game.POINT_BOOST_PICKUP_KIND)
	_check(boost_orbs.size() == 1, "threshold did not spawn exactly one point artifact")
	_check(absf(float(boost_orbs[0].get("life", 0.0)) - float(ControllerScript.CONFIG["ground_lifetime"])) < 0.01, "ground lifetime is not data-driven")

	_feed_controller(threshold * 2)
	boost_orbs = game.heal_orbs.filter(func(orb): return String(orb.get("kind", "")) == game.POINT_BOOST_PICKUP_KIND)
	_check(boost_orbs.size() == 1, "cooldown or active-pickup cap allowed duplicates")

	game.heal_orbs[0]["pos"] = game.player_pos
	game._update_heal_orbs(0.016)
	_check(game.point_boost_pickup_controller.is_active(), "collection did not activate team x2")
	_check(game.heal_orbs.filter(func(orb): return String(orb.get("kind", "")) == game.POINT_BOOST_PICKUP_KIND).is_empty(), "collected artifact did not despawn")
	var remaining_before: float = game.point_boost_pickup_controller.remaining()
	_check(not game.point_boost_pickup_controller.activate(game._mp_unique_id(), true), "active buff stacked or refreshed")
	_check(is_equal_approx(remaining_before, game.point_boost_pickup_controller.remaining()), "rejected refresh changed remaining time")

	game.runtime_event_director.apply_remote_snapshot(_points_event_snapshot())
	_check(is_equal_approx(game.point_boost_pickup_controller.effective_point_multiplier(game.runtime_event_director.point_multiplier()), 2.0), "pickup x2 and Event Director x2 multiplied into x4")
	game.runtime_event_director.reset()

	var base_gain: int = game._points_for_enemy(_enemy(8801))
	_check(int(round(float(base_gain) * game.point_boost_pickup_controller.effective_point_multiplier(1.0))) == base_gain * 2, "score calculation did not double exactly")
	game.point_boost_pickup_controller.update(float(ControllerScript.CONFIG["duration"]) - 2.5, true)
	_check(game.point_boost_pickup_controller.final_warning_active(), "final HUD warning window did not activate")
	game.point_boost_pickup_controller.update(3.0, true)
	_check(not game.point_boost_pickup_controller.is_active(), "buff did not expire")
	_check(is_equal_approx(game.point_boost_pickup_controller.effective_point_multiplier(1.0), 1.0), "expired buff still changes score")

	game.point_boost_pickup_controller.reset()
	game.heal_orbs.clear()
	_feed_controller(threshold, true)
	_check(game.heal_orbs.is_empty(), "point Event Director overlap did not block pickup spawn")
	_feed_controller(1, false)
	_check(game.heal_orbs.size() == 1, "stored pity did not resume after Event Director ended")
	game.heal_orbs[0]["life"] = 0.01
	game.heal_orbs[0]["pos"] = Vector2(1200, 900)
	game._update_heal_orbs(0.02)
	_check(game.heal_orbs.is_empty(), "uncollected artifact did not despawn")

	var low_luck_threshold: float = game.point_boost_pickup_controller.effective_threshold(0.0)
	var high_luck_threshold: float = game.point_boost_pickup_controller.effective_threshold(999.0)
	_check(is_equal_approx(low_luck_threshold, 90.0), "base threshold drifted")
	_check(is_equal_approx(high_luck_threshold, 76.5), "luck reduction was not capped at 15 percent")

	game.point_boost_pickup_controller.reset()
	game.is_multiplayer = true
	game.is_host = false
	game.online_room_owner = false
	_feed_controller(threshold + 10)
	_check(game.heal_orbs.is_empty(), "replica spawned an authority-owned pickup")
	var remote_snapshot := {
		"active": true, "sequence": 12, "remaining": 9.4, "duration": 12.0, "multiplier": 2.0,
		"cooldown": 200.0, "charge": 0.0, "window_drops": 1, "window_elapsed": 350.0,
	}
	game.point_boost_pickup_controller.apply_remote_snapshot(remote_snapshot)
	_check(game.point_boost_pickup_controller.is_active(), "client did not apply authority buff snapshot")
	_check(absf(game.point_boost_pickup_controller.remaining() - 9.4) < 0.01, "client HUD timer did not receive authority remaining time")

	game.set_process(false)
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	if not failed:
		print("POINT_BOOST_PICKUP_SMOKE_OK eligible threshold cooldown collect x2 expire no_stack event_cap multiplayer despawn hud_timer luck_cap")
	quit(1 if failed else 0)
