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
	var fresh_phase5_hp := float(game._boss_hp_for_phase(5))
	var fresh_phase6_hp := float(game._boss_hp_for_phase(6))
	_check(is_equal_approx(fresh_phase1_hp, float(game.BOSS_BASE_HP) * game._boss_phase_durability_multiplier(1)), "fresh phase 1 durability mismatch")
	_check(is_equal_approx(fresh_phase6_hp, float(game.BOSS_BASE_HP) * float(game.BOSS6_HP_SCALE) * game._boss_phase_durability_multiplier(6)), "fresh phase 6 durability mismatch")
	_check(fresh_phase6_hp > fresh_phase1_hp * 5.0, "phase 6 boss is not substantially tougher than phase 1")
	_check(is_equal_approx(float(game._boss_time_hp_multiplier()), 1.0), "fresh boss time scaling should start neutral")
	_check(is_equal_approx(float(game._boss_farm_pressure_multiplier()), 1.0), "fresh boss pressure should start neutral")

	game.time_alive = 1500.0
	var twenty_five_min_multiplier: float = game._boss_time_hp_multiplier()
	var twenty_five_min_phase5_hp: float = game._boss_hp_for_phase(5)
	_check(twenty_five_min_multiplier >= 1.9, "25-minute run did not materially raise boss endurance")
	_check(twenty_five_min_phase5_hp > fresh_phase5_hp * 1.9, "late boss did not keep pace with time played")
	game.score_total = 999999
	game.enemies_killed = 999999
	_check(is_equal_approx(game._boss_hp_for_phase(5), twenty_five_min_phase5_hp), "score or kills still change boss hp")

	game.time_alive = 3600.0
	var one_hour_multiplier: float = game._boss_time_hp_multiplier()
	var one_hour_phase1_hp := float(game._boss_hp_for_phase(1))
	game.time_alive = 7200.0
	var two_hour_multiplier: float = game._boss_time_hp_multiplier()
	game.time_alive = 10800.0
	var three_hour_multiplier: float = game._boss_time_hp_multiplier()
	game.time_alive = 36000.0
	var ten_hour_multiplier: float = game._boss_time_hp_multiplier()
	_check(one_hour_multiplier > twenty_five_min_multiplier, "one-hour run stopped increasing boss hp")
	_check(two_hour_multiplier > one_hour_multiplier, "two-hour run stopped increasing boss hp")
	_check(three_hour_multiplier > two_hour_multiplier, "three-hour run stopped increasing boss hp")
	_check(ten_hour_multiplier > three_hour_multiplier, "ten-hour run stopped increasing boss hp")
	_check(one_hour_phase1_hp > fresh_phase1_hp * twenty_five_min_multiplier, "one-hour boss durability did not grow")
	game.time_alive = 3600.0
	_check(is_equal_approx(float(game._boss_farm_pressure_multiplier()), float(game.BOSS_FARM_DAMAGE_MAX_MULT)), "long farm should reach pressure cap")
	_check(game._damage_source_is_boss("boss"), "plain boss source not detected")
	_check(game._damage_source_is_boss("frost_shard"), "boss2 frost shard source not detected")
	_check(not game._damage_source_is_boss(game.ENEMY_COMMON), "normal enemy should not use boss pressure")

	game.manifestation_key = "eletrica"
	game.current_phase = 1
	game.boss_active = true
	game.boss_hp = 1000.0
	game.boss_hp_max = one_hour_phase1_hp
	game.is_dead = false
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_defense = 0.0
	game._damage_player(100, "boss")
	_check(game.player_hp == 815, "boss farm pressure did not scale damage at cap")

	game.player_hp = 1000
	game._damage_player(100, game.ENEMY_COMMON)
	_check(game.player_hp == 900, "normal enemy damage should not receive boss farm pressure")

	print("BOSS_FARM_BALANCE_SMOKE_OK fresh_hp=%.1f hp_25m=%.1f time_25m=%.2f time_1h=%.2f time_2h=%.2f time_3h=%.2f time_10h=%.2f kills_points_ignored=true" % [
		fresh_phase1_hp,
		twenty_five_min_phase5_hp,
		twenty_five_min_multiplier,
		one_hour_multiplier,
		two_hour_multiplier,
		three_hour_multiplier,
		ten_hour_multiplier
	])
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	for i in range(4):
		await process_frame
	quit(0)
