extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	print("LEGENDARY_CARD_SMOKE_FAIL %s" % message)
	quit(1)


func _has_effect(kind: String) -> bool:
	for effect in game.rare_card_effects:
		if String(effect.get("kind", "")) == kind:
			return true
	return false


func _pool_has_card(pool: Array, card_id: String) -> bool:
	for card in pool:
		if game._card_id(card) == card_id:
			return true
	return false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	var card: Dictionary = game._find_card_by_id(game.CARD_PARADOX_ID)
	_check(not card.is_empty(), "card_missing")
	_check(game._is_legendary_card(card), "rarity_not_legendary")
	_check(not game._is_common_card(card) and not game._is_uncommon_card(card) and not game._is_rare_card(card), "rarity_overlap")
	_check(game._card_rarity_label(card) == "LENDARIA", "label_incorrect")
	_check(game._card_rarity_color(card).is_equal_approx(game.CARD_RARITY_LEGENDARY_COLOR), "color_incorrect")
	_check(not game._can_burn_shop_card(card), "legendary_burnable")
	_check(game._card_max_count(card) >= game.CARD_UNLIMITED_COUNT, "unlimited_contract_missing")
	_check(game._get_texture("card_" + String(card["name"])) != null, "frame_1_missing")
	_check(game._get_texture("card_" + String(card["name"]) + "_2") != null, "frame_2_missing")

	game.cards_bought["Sorte"] = 1
	game.current_phase = 1
	_check(is_equal_approx(game._chance_carta_lendaria(), 0.0), "unlocked_too_early")
	game.current_phase = 2
	var legendary_chance: float = game._chance_carta_lendaria()
	_check(legendary_chance > 0.0 and legendary_chance <= 0.03, "chance_out_of_bounds")
	_check(legendary_chance < game._chance_carta_rara(), "legendary_not_rarer_than_rare")
	var legendary_pool: Array = game._shop_rarity_pool(game.CARD_RARITY_LEGENDARY, {})
	_check(legendary_pool.size() == 2, "shop_pool_size_incorrect")
	_check(_pool_has_card(legendary_pool, game.CARD_PARADOX_ID), "paradox_missing_from_pool")
	_check(_pool_has_card(legendary_pool, game.CARD_IMPOSSIBLE_ARCHIVE_ID), "archive_missing_from_pool")

	game._apply_card(card)
	_check(game._card_count_by_id(game.CARD_PARADOX_ID) == 1, "purchase_not_applied")
	_check(not game._card_at_max(card), "legendary_wrongly_capped")
	var duration_one: float = game._paradox_active_duration()
	var ratio_one: float = game._paradox_echo_ratio()
	game._apply_card(card)
	_check(game._card_count_by_id(game.CARD_PARADOX_ID) == 2, "second_copy_not_applied")
	_check(game._paradox_active_duration() > duration_one, "duration_did_not_scale")
	_check(game._paradox_echo_ratio() > ratio_one, "echo_did_not_scale")
	_check(_pool_has_card(game._shop_rarity_pool(game.CARD_RARITY_LEGENDARY, {}), game.CARD_PARADOX_ID), "owned_card_missing_from_pool")
	_check(_has_effect("paradox_acquired"), "purchase_vfx_missing")
	game.cards_bought[game.CARD_PARADOX_ID] = 1
	game._reset_card_proc_state()

	for i in range(game.PARADOX_HITS_REQUIRED - 1):
		game._register_paradox_confirmed_damage(20.0, "test_basic", "basic_attack", "enemy", 900, game.player_pos)
	_check(game.paradox_charge_hits == game.PARADOX_HITS_REQUIRED - 1, "charge_count_incorrect")
	_check(not game.paradox_ready, "readied_before_18_hits")
	game._register_paradox_confirmed_damage(20.0, "test_basic", "basic_attack", "enemy", 900, game.player_pos)
	_check(game.paradox_ready, "not_ready_after_18_hits")
	_check(_has_effect("paradox_ready"), "ready_vfx_missing")

	game._register_paradox_confirmed_damage(30.0, "test_basic", "basic_attack", "enemy", 900, game.player_pos)
	_check(game.paradox_ready and is_equal_approx(game.paradox_active_timer, 0.0), "basic_attack_consumed_ready_state")
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(120, 0))
	var enemy: Dictionary = game.enemies[0]
	enemy["hp"] = 1000.0
	enemy["max_hp"] = 1000.0
	var hp_before: float = float(enemy["hp"])
	game._register_paradox_confirmed_damage(100.0, "test_q", "skill_q", "enemy", int(enemy["uid"]), Vector2(enemy["pos"]))
	_check(not game.paradox_ready, "skill_did_not_consume_ready_state")
	_check(is_equal_approx(game.paradox_active_timer, game.PARADOX_ACTIVE_DURATION), "active_duration_incorrect")
	_check(game.paradox_echo_queue.size() == 1, "trigger_hit_not_queued")
	_check(_has_effect("paradox_open"), "open_vfx_missing")
	game._update_paradox(game.PARADOX_ECHO_DELAY + 0.01)
	_check(float(enemy["hp"]) < hp_before, "echo_damage_missing")
	_check(game.paradox_echo_queue.is_empty(), "echo_queue_not_drained")
	_check(_has_effect("paradox_echo"), "echo_vfx_missing")
	_check(game._paradox_direct_category(game.LEGENDARY_SOURCE_PARADOX, "legendary_card") == "", "echo_can_recurse")

	game._reset_card_proc_state()
	_check(game.paradox_charge_hits == 0 and not game.paradox_ready and is_equal_approx(game.paradox_active_timer, 0.0), "reset_incomplete")
	_check(game.paradox_echo_queue.is_empty(), "reset_queue_incomplete")

	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	print("LEGENDARY_CARD_SMOKE_OK unlimited=true pool=2 phase2_luck=true hits=18 trigger=q_e_tp active=5 echo=35pct scaling=true delay=0.55 authority_safe=true")
	quit(0)
