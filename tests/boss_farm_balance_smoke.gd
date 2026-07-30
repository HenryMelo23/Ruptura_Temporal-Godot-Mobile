extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS_FARM_BALANCE_SMOKE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.score_total = 0
	game.enemies_killed = 0
	game.time_alive = 0.0
	var fresh_phase1_hp := float(game._boss_hp_for_phase(1))
	var fresh_phase6_hp := float(game._boss_hp_for_phase(6))
	_check(is_equal_approx(fresh_phase1_hp, float(game.BOSS_BASE_HP)), "fresh phase 1 boss hp changed")
	_check(is_equal_approx(fresh_phase6_hp, fresh_phase1_hp), "phase 6 should mirror phase 1 boss hp")
	_check(is_equal_approx(float(game._boss_farm_pressure_multiplier()), 1.0), "fresh boss pressure should start neutral")

	game.score_total = 250000
	game.enemies_killed = 3600
	game.time_alive = 3600.0
	var farm_phase1_hp := float(game._boss_hp_for_phase(1))
	var old_linear_hp := float(game.BOSS_BASE_HP) + float(game.score_total) * 0.12 + float(game.enemies_killed) * 9.0
	_check(farm_phase1_hp > fresh_phase1_hp, "farm should still add some boss hp")
	_check(farm_phase1_hp < old_linear_hp * 0.25, "farm hp scaling is still too punishing")
	_check(is_equal_approx(float(game._boss_farm_pressure_multiplier()), float(game.BOSS_FARM_DAMAGE_MAX_MULT)), "long farm should reach pressure cap")
	_check(game._damage_source_is_boss("boss"), "plain boss source not detected")
	_check(game._damage_source_is_boss("frost_shard"), "boss2 frost shard source not detected")
	_check(not game._damage_source_is_boss(game.ENEMY_COMMON), "normal enemy should not use boss pressure")

	game.manifestation_key = "eletrica"
	game.contractual_order.clear()
	game.contractual_order_penalties.clear()
	game.current_phase = 1
	game.is_dead = false
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_defense = 0.0
	game._damage_player(100, "boss")
	_check(game.player_hp == 815, "boss farm pressure did not scale damage at cap")

	game.player_hp = 1000
	game._damage_player(100, game.ENEMY_COMMON)
	_check(game.player_hp == 900, "normal enemy damage should not receive boss farm pressure")

	print("BOSS_FARM_BALANCE_SMOKE_OK fresh_hp=%.1f farm_hp=%.1f old_linear=%.1f boss_pressure=%.2f" % [
		fresh_phase1_hp,
		farm_phase1_hp,
		old_linear_hp,
		float(game._boss_farm_pressure_multiplier())
	])
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	for i in range(4):
		await process_frame
	quit(0)
