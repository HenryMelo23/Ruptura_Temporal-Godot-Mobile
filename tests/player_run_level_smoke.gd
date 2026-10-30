extends SceneTree

const BASE_RANGE := 300.0

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("PLAYER_RUN_LEVEL_SMOKE_FAIL " + message)
	_cleanup(1)


func _cleanup(code: int) -> void:
	if game != null:
		game.mode = "menu"
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.set_process(false)
	game.set_physics_process(false)
	var level = game._player_run_level_controller()
	_check(game.player_run_level == 1 and game.player_run_xp == 0, "new_run_did_not_reset_level")
	_check(level.classify_enemy({"type": game.ENEMY_COMMON}) == 10, "common_xp_wrong")
	_check(level.classify_enemy({"type": "atirador"}) == 25, "elite_xp_wrong")
	_check(level.classify_enemy({"type": game.ENEMY_LARAPIO}) == 90, "larapio_miniboss_xp_wrong")
	_check(level.classify_enemy({"type": "ignored", "skip_rewards": true}) == 0, "reward_skip_received_xp")
	_check(level.classify_enemy({"type": "node", "aguilhao_nodule": true}) == 0, "node_received_xp")
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(100.0, 0.0))
	var confirmed_common: Dictionary = game.enemies.back()
	confirmed_common["hp"] = 0.0
	confirmed_common["max_hp"] = 1.0
	game._kill_enemy(confirmed_common)
	_check(game.player_run_xp == 10, "confirmed_common_kill_did_not_award_xp")
	game._kill_enemy(confirmed_common)
	_check(game.player_run_xp == 10, "confirmed_common_kill_awarded_twice")
	level.reset()
	game.active_character_key = game.CHARACTER_GEOVANA
	_check(level.XP_THRESHOLDS == [500, 800, 1200, 1750, 2500, 3500, 4800, 6500, 8500], "long_run_xp_curve_wrong")
	level.grant_xp(1200)
	_check(game.player_run_level == 2 and game.player_run_xp == 700, "opening_burst_reached_levels_too_quickly")
	level.reset()

	for _i in range(49):
		level.grant_xp(10)
	_check(game.player_run_level == 1 and game.player_run_xp == 490, "first_level_unlocked_before_500_xp")
	level.grant_xp(10)
	_check(game.player_run_level == 2 and game.player_run_xp == 0, "first_threshold_or_overflow_wrong")
	var level_up_effect_found := false
	for effect_value in game.effects:
		var effect: Dictionary = effect_value
		if String(effect.get("kind", "")) == "geovana_level_up" and int(effect.get("level", 0)) == 2:
			level_up_effect_found = true
			break
	_check(level_up_effect_found, "geovana_level_up_effect_missing")
	level.grant_xp(850)
	_check(game.player_run_level == 3 and game.player_run_xp == 50, "second_threshold_overflow_wrong")
	level.grant_confirmed_boss()
	_check(game.player_run_level == 3 and game.player_run_xp == 230, "boss_skipped_long_horizon_threshold")
	level.grant_xp(1100)
	_check(game.player_run_level == 4 and game.player_run_xp == 130, "third_threshold_overflow_wrong")
	level.grant_xp(100000)
	_check(game.player_run_level == 10 and game.player_run_xp == 0, "max_level_cap_wrong")
	_check(is_equal_approx(level.damage_multiplier(), 1.09), "damage_bonus_wrong")
	_check(is_equal_approx(level.auto_attack_range_bonus(), 45.0), "range_bonus_wrong")
	_check(is_equal_approx(level.received_damage_multiplier(), 0.964), "mitigation_bonus_wrong")
	_check(is_equal_approx(game._apply_player_run_level_damage(100.0, "eletrica", "basic_attack"), 109.0), "direct_damage_not_scaled")
	_check(is_equal_approx(game._apply_player_run_level_damage(100.0, "veneno", "common_card"), 100.0), "proc_damage_scaled_twice")
	_check(game._apply_player_run_level_mitigation(100) == 96, "received_damage_mitigation_wrong")

	game.active_character_key = game.CHARACTER_GEOVANA
	game.manifestation_key = "eletrica"
	game.cards_bought.clear()
	_check(is_equal_approx(game._auto_attack_range(), BASE_RANGE + 45.0), "ranged_target_range_missing_level_bonus")
	var bullet := {"source_category": "basic_attack", "kind": "eletrica", "origin": game.player_pos, "pos": game.player_pos, "speed": 600.0, "life": 2.0, "damage": 20.0}
	game.RangedAttackRange.configure_bullet(game, bullet)
	_check(is_equal_approx(float(bullet.get("max_range", 0.0)), BASE_RANGE + 45.0), "projectile_range_missing_level_bonus")
	game.manifestation_key = "prismatica"
	_check(is_equal_approx(game._auto_attack_range(), BASE_RANGE + 45.0), "prismatica_target_range_missing_level_bonus")
	var prism := {"source_category": "basic_attack", "kind": "prismatica", "origin": game.player_pos, "pos": game.player_pos, "speed": 600.0, "life": 2.0, "damage": 20.0}
	game.RangedAttackRange.configure_bullet(game, prism)
	_check(not prism.has("max_range"), "prismatica_lifetime_was_replaced")
	game.manifestation_key = "lacerante"
	_check(game._auto_attack_range() < BASE_RANGE, "melee_received_ranged_level_bonus")

	var save_fields: Array = game.save_controller._interrupted_run_field_names()
	_check(save_fields.has("player_run_level") and save_fields.has("player_run_xp"), "save_fields_missing_level")
	game._apply_remote_player_run_level(3, 1325)
	_check(game.player_run_level == 4 and game.player_run_xp == 125, "replica_snapshot_overflow_wrong")
	var before_duplicate: int = game.player_run_xp
	game._apply_shared_kill_progress(game.enemies_killed)
	_check(game.player_run_xp == before_duplicate, "kill_counter_duplicate_changed_xp")

	print("PLAYER_RUN_LEVEL_SMOKE_OK level=%d xp=%d range=%.0f mitigation=%.3f save=true replica=true" % [game.player_run_level, game.player_run_xp, game._player_run_level_range_bonus(), level.received_damage_multiplier()])
	_cleanup(0)
