extends SceneTree

var game: Node
var failed := false


func _init() -> void:
	call_deferred("_run")


func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error("TEST_ATRITO FAIL: " + message)
	quit(1)


func _assert_ok(condition: bool, message: String) -> void:
	if failed:
		return
	if not condition:
		_fail(message)


func _assert_approx(value: float, expected: float, tolerance: float, message: String) -> void:
	if failed:
		return
	if absf(value - expected) > tolerance:
		_fail("%s | expected %.4f got %.4f" % [message, expected, value])


func _run() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	_assert_ok(main_scene != null, "Failed to load Main scene")

	game = main_scene.instantiate()
	root.add_child(game)
	current_scene = game

	for _f in range(5):
		await process_frame

	_assert_ok("current_phase" in game, "Could not find main game node with current_phase")
	print("--- STARTING TRANSMUTAR_ATRITO & LASER_SOBRECARGA SMOKE TEST ---")

	game.set("current_phase", 5)
	game.set("boss_active", true)
	game.set("boss_pos", game.WORLD_SIZE * 0.5)
	game.set("player_pos", game.WORLD_SIZE * 0.5 + Vector2(240.0, 0.0))

	game.call("_transmute_umbra_dimension", "TRANSMUTAR_ATRITO")
	var current_dim: String = String(game.get("boss5_dimension"))
	var map_key: String = String(game.call("_boss5_dimension_map_key", current_dim))
	print("[TEST LOG] Transmuted to dimension: %s | Map Key: %s" % [current_dim, map_key])
	_assert_ok(current_dim == "atrito", "Expected dimension atrito, got " + current_dim)
	_assert_ok(map_key == "map_phase_7", "Expected map_key map_phase_7, got " + map_key)

	game.call("_spawn_umbra_action", "LASER_SOBRECARGA")
	var hazards: Array = game.get("phase5_hazards")
	_assert_ok(not hazards.is_empty(), "Laser hazard was not created")

	var h: Dictionary = hazards[hazards.size() - 1]
	_assert_ok(String(h.get("kind", "")) == "umbra_overload_laser", "Expected umbra_overload_laser")
	_assert_ok(String(h.get("fase", "")) == "caminhando", "Expected initial fase caminhando")

	game.call("_update_phase5_hazards", 0.02)
	await process_frame
	_assert_ok(String(h.get("fase", "")) == "esfera_carga_1", "Expected fase esfera_carga_1")

	game.call("_update_phase5_hazards", 1.21)
	await process_frame
	_assert_ok(String(h.get("fase", "")) == "laser_2", "Expected fase laser_2")

	game.set("player_hp", 500)
	game.set("invulnerable_timer", 0.0)
	game.set("dodge_timer", 0.0)
	game.set("player_burn_stacks", 0)
	game.set("player_burn_timer", 0.0)
	game.set("player_burn_tick_timer", 1.0)

	_measure_rotation(h, "laser_2", float(game.BOSS5_OVERLOAD_LASER_ROTATION_FAST), 2)

	var angle_for_hit: float = float(h.get("angle", 0.0))
	game.set("player_pos", game.WORLD_SIZE * 0.5 + Vector2.from_angle(angle_for_hit) * 220.0)
	game.call("_update_phase5_hazards", 0.02)
	await process_frame
	_assert_ok(int(game.get("player_hp")) < 500, "Laser should still damage when player is on the beam")
	_assert_ok(int(game.get("player_burn_stacks")) > 0, "Laser hit should still apply burn stacks")
	print("[TEST LOG] hit dist %.2f | hp %d | burn stacks %d" % [
		float(h.get("last_laser_dist", -1.0)),
		int(game.get("player_hp")),
		int(game.get("player_burn_stacks"))
	])

	game.set("player_pos", Vector2(3000.0, 3000.0))
	game.set("player_burn_tick_timer", 0.0)
	var hp_before_burn: int = int(game.get("player_hp"))
	game.call("_update_phase5_hazards", 0.10)
	await process_frame
	_assert_ok(int(game.get("player_hp")) < hp_before_burn, "Burn tick failed to deal damage")

	await _advance_until_fase(h, "laser_4", 6.0)
	_measure_rotation(h, "laser_4", -float(game.BOSS5_OVERLOAD_LASER_ROTATION_SLOW), 4)

	await _advance_until_fase(h, "laser_6_ccw", 7.0)
	_measure_rotation(h, "laser_6_ccw", -float(game.BOSS5_OVERLOAD_LASER_ROTATION_SLOW), 6)

	await _advance_until_fase(h, "laser_6_cw", 4.0)
	_measure_rotation(h, "laser_6_cw", float(game.BOSS5_OVERLOAD_LASER_ROTATION_SLOW), 6)

	game.call("_reset_phase5_state")
	_assert_ok(Array(game.get("phase5_hazards")).is_empty(), "Hazards should be cleaned on reset")
	_assert_ok(int(game.get("player_burn_stacks")) == 0, "Burn stacks should be cleaned on reset")
	if failed:
		return

	print("--- ALL TRANSMUTAR_ATRITO & LASER_SOBRECARGA SMOKE TESTS PASSED CLEANLY ---")
	quit(0)


func _measure_rotation(hazard: Dictionary, expected_fase: String, expected_delta: float, expected_beams: int) -> void:
	_assert_ok(String(hazard.get("fase", "")) == expected_fase, "Expected fase " + expected_fase)
	_assert_ok(int(hazard.get("num_beams", 0)) == expected_beams, "Unexpected beam count for " + expected_fase)
	var before: float = float(hazard.get("angle", 0.0))
	game.call("_update_phase5_hazards", 1.0)
	var after: float = float(hazard.get("angle", 0.0))
	var delta_angle: float = wrapf(after - before, -PI, PI)
	_assert_approx(delta_angle, expected_delta, 0.015, expected_fase + " rotation speed")
	print("[TEST LOG] %s beams=%d angle_delta=%.4f rad/s" % [expected_fase, expected_beams, delta_angle])


func _advance_until_fase(hazard: Dictionary, expected_fase: String, max_seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < max_seconds and String(hazard.get("fase", "")) != expected_fase:
		game.call("_update_phase5_hazards", 0.10)
		await process_frame
		elapsed += 0.10
	_assert_ok(String(hazard.get("fase", "")) == expected_fase, "Could not reach fase " + expected_fase)
