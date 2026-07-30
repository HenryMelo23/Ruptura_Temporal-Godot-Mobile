extends SceneTree

const ITERATIONS := 100000

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("SHOP_FAIRNESS_V2_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _card_ids(cards: Array) -> Array:
	var ids := []
	for card in cards:
		if game._is_empty_shop_slot(card):
			continue
		ids.append(game._card_id(card))
	return ids


func _has_duplicate(ids: Array) -> bool:
	var seen := {}
	for card_id in ids:
		if seen.has(card_id):
			return true
		seen[card_id] = true
	return false


func _rare_count(cards: Array) -> int:
	var count := 0
	for card in cards:
		if not game._is_empty_shop_slot(card) and game._is_rare_card(card):
			count += 1
	return count


func _owned_common_count(cards: Array) -> int:
	var count := 0
	for card in cards:
		if not game._is_empty_shop_slot(card) and game._is_common_card(card) and game._card_count(card) > 0:
			count += 1
	return count


func _new_common_count(cards: Array) -> int:
	var count := 0
	for card in cards:
		if not game._is_empty_shop_slot(card) and game._is_common_card(card) and game._card_count(card) <= 0:
			count += 1
	return count


func _prepare_build_started() -> void:
	game._reset_card_counts()
	game._reset_card_proc_state()
	game.shop_locked_slots.clear()
	game.shop_recent_common_ids.clear()
	game.shop_recent_generation_ids.clear()
	game.shop_slot_intents.clear()
	game.cinzas_burn_marks.clear()
	for card_id in ["Speed Boost", "Disparo crescente", "Defesa", "Teleporte", "Roubo de Vida", "Tempestade"]:
		game.cards_bought[card_id] = 1


func _simulate(use_v2: bool, iterations: int) -> Dictionary:
	var three_new := 0
	var at_least_owned := 0
	var two_owned := 0
	var rare_total := 0
	var duplicates := 0
	var structured := 0
	var free_profile := 0
	for i in range(iterations):
		var cards: Array
		if use_v2:
			cards = game._roll_shop_cards_v2("open")
			if game.shop_generation_profile == "structured":
				structured += 1
			elif game.shop_generation_profile == "free":
				free_profile += 1
		else:
			cards = game._roll_shop_cards_legacy()
		var ids := _card_ids(cards)
		if _has_duplicate(ids):
			duplicates += 1
		var owned := _owned_common_count(cards)
		var fresh := _new_common_count(cards)
		if fresh >= 3:
			three_new += 1
		if owned >= 1:
			at_least_owned += 1
		if owned >= 2:
			two_owned += 1
		rare_total += _rare_count(cards)
	return {
		"three_new": float(three_new) / float(iterations),
		"at_least_owned": float(at_least_owned) / float(iterations),
		"two_owned": float(two_owned) / float(iterations),
		"rare_rate": float(rare_total) / float(iterations),
		"duplicates": duplicates,
		"structured": float(structured) / float(max(1, iterations)),
		"free_profile": float(free_profile) / float(max(1, iterations))
	}


func _run() -> void:
	game._start_game()
	game.shop_telemetry_enabled = false
	game.score = 99999999
	game.card_cost = 500
	game._set_shop_rng_seed(32029)
	game.rng.seed = 32029

	game._reset_card_counts()
	game._reset_card_proc_state()
	game.shop_locked_slots.clear()
	game.shop_recent_generation_ids.clear()
	for i in range(2000):
		var no_luck_cards: Array = game._roll_shop_cards_v2("open")
		_check(_rare_count(no_luck_cards) == 0, "rare appeared without Sorte")

	_prepare_build_started()
	var speed: Dictionary = game._find_card_by_id("Speed Boost")
	var first_copy: Dictionary = game._shop_common_weight_breakdown(speed, game.SHOP_INTENT_CONSOLIDATION)
	game.cards_bought["Speed Boost"] = 2
	var second_copy: Dictionary = game._shop_common_weight_breakdown(speed, game.SHOP_INTENT_CONSOLIDATION)
	_check(is_equal_approx(float(first_copy["copy_multiplier"]), 1.0), "first copy was penalized")
	_check(float(second_copy["copy_multiplier"]) < 1.0, "second copy was not softly penalized")

	game.cards_bought[game.CARD_CINZAS_ID] = 1
	var tregua: Dictionary = game._find_card_by_id(game.CARD_TREGUA_ID)
	game.shop_cards = [tregua.duplicate(true)]
	_check(game._burn_shop_card(0), "Cinzas could not mark a common card")
	_check(game._cinzas_weight_multiplier(game.CARD_TREGUA_ID) > 2.5, "Cinzas did not add real weight")
	game.cinzas_burn_marks[0]["eligible_misses"] = game.SHOP_ASHES_GUARANTEE_VISITS
	game.shop_locked_slots.clear()
	game.shop_slot_intents = [game.SHOP_INTENT_CONSOLIDATION, game.SHOP_INTENT_FREE, game.SHOP_INTENT_DISCOVERY]
	var guaranteed: Array = game._roll_shop_cards_v2("reroll")
	_check(_card_ids(guaranteed).has(game.CARD_TREGUA_ID), "Cinzas guarantee did not force return")

	_prepare_build_started()
	game.cards_bought["Sorte"] = 1
	game.cards_bought[game.CARD_ESCOLHA_ADIADA_ID] = 1
	var rare: Dictionary = game._find_card_by_id("devorador_destinos")
	game.shop_cards = [rare.duplicate(true)]
	_check(game._can_reserve_shop_card(rare), "rare card could not be reserved")
	game._reserve_shop_card(0)
	_check(game._shop_slot_locked(0), "rare reservation did not lock slot")
	for i in range(2000):
		var cards_with_locked_rare: Array = game._roll_shop_cards_v2("reroll")
		_check(_rare_count(cards_with_locked_rare) <= 1, "locked rare allowed a second rare")
		_check(game._card_id(cards_with_locked_rare[0]) == "devorador_destinos", "reserved rare moved from its slot")

	_prepare_build_started()
	game._set_shop_rng_seed(777)
	game.rng.seed = 777
	var old_metrics := _simulate(false, ITERATIONS)
	_prepare_build_started()
	game._set_shop_rng_seed(777)
	game.rng.seed = 777
	var new_metrics := _simulate(true, ITERATIONS)

	_check(int(new_metrics["duplicates"]) == 0, "new shop created duplicate offers")
	_check(float(new_metrics["at_least_owned"]) > float(old_metrics["at_least_owned"]), "new shop did not improve consolidation")
	_check(float(new_metrics["three_new"]) < float(old_metrics["three_new"]), "new shop did not reduce triple-new shops")
	_check(float(new_metrics["structured"]) > 0.64 and float(new_metrics["structured"]) < 0.76, "structured profile rate outside target")

	print("SHOP_FAIRNESS_V2_SMOKE_OK iterations=%d old_three_new=%.3f new_three_new=%.3f old_owned=%.3f new_owned=%.3f structured=%.3f duplicates=%d" % [
		ITERATIONS,
		float(old_metrics["three_new"]),
		float(new_metrics["three_new"]),
		float(old_metrics["at_least_owned"]),
		float(new_metrics["at_least_owned"]),
		float(new_metrics["structured"]),
		int(new_metrics["duplicates"])
	])
	root.remove_child(game)
	game.queue_free()
	await process_frame
	quit(0)
