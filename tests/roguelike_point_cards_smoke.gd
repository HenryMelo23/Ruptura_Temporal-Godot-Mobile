extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("ROGUELIKE_POINT_CARDS_SMOKE_FAIL " + message)
	_cleanup_runtime()
	quit(1)


func _card(card_id: String) -> Dictionary:
	for card in game.CARDS:
		if game._card_id(card) == card_id:
			return card
	return {}


func _cleanup_runtime() -> void:
	if game == null:
		return
	game.mode = "menu"
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.heal_orbs.clear()
	game.visible = false
	game.set_process(false)
	game.set_physics_process(false)
	game._cleanup_runtime_resources()


func _run() -> void:
	game._start_game()
	var ids := [
		game.CARD_PAIN_TRIBUTE_ID,
		game.CARD_PRISM_SHARD_ID,
		game.CARD_ABSOLUTE_CRIT_ID,
		game.CARD_IMPOSSIBLE_ARCHIVE_ID,
	]
	var expected_rarities := [
		game.CARD_RARITY_COMMON,
		game.CARD_RARITY_UNCOMMON,
		game.CARD_RARITY_RARE,
		game.CARD_RARITY_LEGENDARY,
	]
	for index in range(ids.size()):
		var card := _card(ids[index])
		_check(not card.is_empty(), "missing_card_%s" % ids[index])
		_check(game._card_rarity_key(card) == expected_rarities[index], "wrong_rarity_%s" % ids[index])
		_check(card.has("frame_2"), "missing_second_frame_%s" % ids[index])
		_check(game._get_texture("card_" + String(card["name"])) != null, "missing_first_texture_%s" % ids[index])
		_check(game._get_texture("card_" + String(card["name"]) + "_2") != null, "missing_second_texture_%s" % ids[index])

	for card in game.CARDS:
		var card_id: String = game._card_id(card)
		game.cards_bought[card_id] = game.CARD_UNLIMITED_COUNT + 100
		_check(not game._card_at_max(card), "finite_acquisition_%s" % card_id)
	game.cards_bought.clear()

	var card_logic = game.roguelike_point_card_controller
	_check(card_logic.prism_shard_chance(5) > card_logic.prism_shard_chance(1), "prism_chance_not_scaling")
	_check(card_logic.prism_shard_chance(50) > card_logic.prism_shard_chance(20), "prism_chance_late_not_scaling")
	_check(card_logic.prism_shard_value(20) > card_logic.prism_shard_value(5), "prism_value_not_scaling")
	_check(card_logic.pain_reward(20.0) > card_logic.pain_reward(5.0), "pain_reward_not_scaling")
	_check(card_logic.pain_reward(50.0) > card_logic.pain_reward(20.0), "pain_reward_late_not_scaling")
	_check(card_logic.critical_damage_multiplier(50) > card_logic.critical_damage_multiplier(20), "critical_late_not_scaling")

	# Actual kill hook: a very high copy count makes the chance deterministically 100%.
	game.cards_bought[game.CARD_PRISM_SHARD_ID] = 1000
	game.heal_orbs.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(220.0, 0.0))
	_check(not game.enemies.is_empty(), "enemy_spawn_failed")
	var killed_enemy: Dictionary = game.enemies.back()
	game._kill_enemy(killed_enemy)
	var large_orb: Dictionary = {}
	for orb in game.heal_orbs:
		if bool(orb.get("large_prism_shard", false)):
			large_orb = orb
			break
	_check(not large_orb.is_empty(), "kill_did_not_spawn_large_prism")
	_check(int(large_orb.get("large_prism_value", 0)) == card_logic.prism_shard_value(1000), "large_prism_value_wrong")
	_check(int(large_orb.get("score_value", 0)) >= int(large_orb.get("large_prism_value", 0)), "normal_drop_did_not_merge")

	# Actual damage hook: only HP damage pays, and later copies pay more.
	game.cards_bought.clear()
	game.cards_bought[game.CARD_PAIN_TRIBUTE_ID] = 1
	game.score = 0
	game.score_total = 0
	game.player_defense = 0.0
	game.player_hp_max = 1000
	game.player_hp = 1000
	var reward_one: int = card_logic.pain_reward()
	game._damage_player(10, "roguelike_card_test", true)
	_check(game.score == reward_one, "damage_hook_reward_wrong")
	var zero_damage_score: int = game.score
	_check(card_logic.on_player_damaged(0.0) == 0, "zero_hp_damage_paid_reward")
	_check(game.score == zero_damage_score, "zero_hp_damage_changed_score")
	game.cards_bought[game.CARD_PAIN_TRIBUTE_ID] = 20
	var score_before: int = game.score
	var reward_twenty: int = card_logic.pain_reward()
	game._damage_player(10, "roguelike_card_test", true)
	_check(game.score == score_before + reward_twenty, "damage_hook_late_reward_wrong")
	_check(reward_twenty > reward_one, "damage_hook_copy_scaling_wrong")

	# Critical multiplier is applied after the existing 3x critical contract.
	game.cards_bought.erase(game.CARD_ABSOLUTE_CRIT_ID)
	_check(is_equal_approx(float(game._critical_damage(100.0, true)["amount"]), 300.0), "base_critical_changed")
	game.cards_bought[game.CARD_ABSOLUTE_CRIT_ID] = 1
	_check(is_equal_approx(float(game._critical_damage(100.0, true)["amount"]), 600.0), "single_critical_copy_not_100_percent")
	game.cards_bought[game.CARD_ABSOLUTE_CRIT_ID] = 5
	_check(is_equal_approx(float(game._critical_damage(100.0, true)["amount"]), 1800.0), "critical_did_not_scale_per_copy")

	# Archive duplicates each non-legendary acquisition, never itself and never recursively.
	game.cards_bought.clear()
	game.cards_bought[game.CARD_IMPOSSIBLE_ARCHIVE_ID] = 2
	var speed_card := _card("Speed Boost")
	game._apply_card(speed_card)
	_check(game._card_count_by_id("Speed Boost") == 3, "archive_did_not_grant_two_free_copies")
	var archive_card := _card(game.CARD_IMPOSSIBLE_ARCHIVE_ID)
	game._apply_card(archive_card)
	_check(game._card_count_by_id(game.CARD_IMPOSSIBLE_ARCHIVE_ID) == 3, "archive_duplicated_itself")

	# Explicit 70/90 minute evidence: time and copies keep increasing point power.
	game.time_alive = 70.0 * 60.0
	var prism_70: int = card_logic.prism_shard_value(20)
	game.time_alive = 90.0 * 60.0
	var prism_90: int = card_logic.prism_shard_value(20)
	_check(prism_70 > card_logic.PRISM_BASE_POINTS, "70_minute_prism_not_powerful")
	_check(prism_90 >= prism_70, "90_minute_prism_regressed")
	_check(card_logic.pain_reward(50.0) >= 150, "late_pain_reward_not_broken")
	_check(card_logic.critical_damage_multiplier(50) == 51.0, "late_critical_multiplier_wrong")
	_check(card_logic.extra_card_copies(speed_card, 50) == 50, "late_archive_duplication_wrong")

	print("ROGUELIKE_POINT_CARDS_SMOKE_OK cards=%d prism70=%d prism90=%d pain50=%d crit50=%.1f archive50=%d" % [game.CARDS.size(), prism_70, prism_90, card_logic.pain_reward(50.0), card_logic.critical_damage_multiplier(50), card_logic.extra_card_copies(speed_card, 50)])
	_cleanup_runtime()
	for _i in range(4):
		await process_frame
	root.remove_child(game)
	game.free()
	game = null
	await process_frame
	await process_frame
	quit(0)
