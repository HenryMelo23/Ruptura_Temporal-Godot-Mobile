extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("CINZAS_ATTRIBUTE_BURN_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _burn_slot(slot: int) -> bool:
	var ok: bool = game._burn_shop_card(slot)
	game.shop_presentation.update(10.0)
	return ok


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_defense = 0.0
	game.aura_state = {}
	game._reset_card_counts()
	game._reset_card_proc_state()

	# =========================================================================
	# TEST 1: Policy and Non-burnable Integrity
	# =========================================================================
	var rare_card: Dictionary = game._find_card_by_id("devorador_destinos")
	var trembo_card: Dictionary = game._find_card_by_id("Trembo")
	var petro_card: Dictionary = game._find_card_by_id("Petro")
	var zero_card: Dictionary = game._find_card_by_id("carta_zero")
	var reserva_causal: Dictionary = game._find_card_by_id("escolha_adiada")
	var cinzas_itself: Dictionary = game._find_card_by_id(game.CARD_CINZAS_ID)

	# Ensure player has Cinzas in deck to test eligibility
	game.cards_bought[game.CARD_CINZAS_ID] = 20

	_check(not game._can_burn_shop_card(rare_card), "Policy fail: Rare card devorador_destinos should not be burnable")
	_check(not game._can_burn_shop_card(trembo_card), "Policy fail: Rare card Trembo should not be burnable")
	_check(not game._can_burn_shop_card(petro_card), "Policy fail: Rare card Petro should not be burnable")
	_check(not game._can_burn_shop_card(zero_card), "Policy fail: Rare card Carta Zero should not be burnable")
	_check(not game._can_burn_shop_card(reserva_causal), "Policy fail: Consumable Escolha Adiada should not be burnable")
	_check(not game._can_burn_shop_card(cinzas_itself), "Policy fail: Consumable Cinzas da Escolha should not be burnable")

	_check(not CardCatalogDefinitions.is_burn_eligible("escolha_adiada"), "Catalog policy: escolha_adiada must not be burn eligible")
	_check(not CardCatalogDefinitions.is_burn_eligible("cinzas_escolha"), "Catalog policy: cinzas_escolha must not be burn eligible")
	_check(not CardCatalogDefinitions.is_burn_eligible("Trembo"), "Catalog policy: Trembo must not be burn eligible")
	_check(CardCatalogDefinitions.is_burn_eligible("Defesa"), "Catalog policy: Defesa must be burn eligible")
	_check(CardCatalogDefinitions.is_burn_eligible("Speed Boost"), "Catalog policy: Speed Boost must be burn eligible")
	_check(CardCatalogDefinitions.is_burn_eligible("Disparo crescente"), "Catalog policy: Disparo crescente must be burn eligible")
	_check(CardCatalogDefinitions.is_burn_eligible("Speed Atack"), "Catalog policy: Speed Atack must be burn eligible")

	# =========================================================================
	# TEST 2: Damage Cards (Disparo crescente & Tempestade)
	# =========================================================================
	# Test 2a: Disparo crescente (+15% base damage)
	var disparo_card: Dictionary = game._find_card_by_id("Disparo crescente")
	_check(game._can_burn_shop_card(disparo_card), "Disparo crescente should be burnable")

	# Burn Disparo crescente (1 stack)
	game.shop_cards = [disparo_card.duplicate(true)]
	game.shop_selected = 0
	_check(_burn_slot(0), "Failed to burn Disparo crescente")
	_check(game.cinzas_burn_marks.size() == 1, "Burn mark for Disparo crescente was not created")

	# Return card with 1 stack
	var returned_disparo := [disparo_card.duplicate(true)]
	game._update_burned_card_marks_after_shop(returned_disparo)
	_check(bool(returned_disparo[0].get("cinzas_return_buff", false)), "Disparo crescente missing return buff")
	_check(int(returned_disparo[0].get("cinzas_buff_stacks", 0)) == 1, "Disparo crescente return stack should be 1")

	# Verify summary text explains the damage bonus
	var disparo_summary: String = String(returned_disparo[0].get("cinzas_bonus_summary", ""))
	_check(disparo_summary.contains("dano base"), "Disparo crescente summary must mention dano base, got: " + disparo_summary)
	_check(not disparo_summary.contains("+5.0 de dano"), "Disparo crescente summary must not use hardcoded +5 damage")

	# Apply burned copy: 1 stack (factor 0.5) gives effective count 1.5 -> (pow(1.15, 1.5) - 1.0) * base_dmg
	var dmg_before_buy: float = game.player_damage
	game._apply_card(returned_disparo[0])
	var dmg_after_buy: float = game.player_damage
	var gain_burned: float = dmg_after_buy - dmg_before_buy
	var expected_normal_gain: float = game._manifestation_base_damage() * (1.15 - 1.0)
	_check(gain_burned > expected_normal_gain, "Burned Disparo crescente should grant more damage than normal copy (%f > %f)" % [gain_burned, expected_normal_gain])
	_check(game._cinzas_bonus_stacks("Disparo crescente") == 1, "Disparo crescente cinzas_card_bonuses stack should be 1")

	# Test 2b: Multi-attribute damage card Tempestade (+5 flat damage, +2% crit)
	var tempestade_card: Dictionary = game._find_card_by_id("Tempestade")
	_check(game._can_burn_shop_card(tempestade_card), "Tempestade should be burnable")

	game.shop_cards = [tempestade_card.duplicate(true)]
	game.shop_selected = 0
	_check(_burn_slot(0), "Failed to burn Tempestade")
	var returned_tempestade := [tempestade_card.duplicate(true)]
	game._update_burned_card_marks_after_shop(returned_tempestade)

	var temp_summary: String = String(returned_tempestade[0].get("cinzas_bonus_summary", ""))
	_check(temp_summary.contains("critico") and temp_summary.contains("dano"), "Tempestade summary must mention both damage and crit: " + temp_summary)

	var dmg_pre_temp: float = game.player_damage
	var crit_pre_temp: float = game.player_crit_chance
	game._apply_card(returned_tempestade[0])
	# Effective count is 1.5 -> damage +7.5, crit +3.0% (instead of +5.0 dmg, +2.0% crit)
	_check(is_equal_approx(game.player_damage - dmg_pre_temp, 7.5), "Tempestade burned damage gain should be 7.5, got: %f" % (game.player_damage - dmg_pre_temp))
	_check(is_equal_approx(game.player_crit_chance - crit_pre_temp, 0.03), "Tempestade burned crit gain should be +0.03, got: %f" % (game.player_crit_chance - crit_pre_temp))

	# =========================================================================
	# TEST 3: Non-Damage Category 1 - Defense (Defesa) & Caps
	# =========================================================================
	var def_card: Dictionary = game._find_card_by_id("Defesa")
	game.player_defense = 0.0
	game.cinzas_card_bonuses.erase("Defesa")
	game.cards_bought["Defesa"] = 0
	game._recalculate_common_card_stat_bonuses()

	# Normal Defesa gives +3.5
	# Burned Defesa (1 stack, factor 0.5) gives effective 1.5 -> +5.25 defense
	game.shop_cards = [def_card.duplicate(true)]
	game.shop_selected = 0
	_check(_burn_slot(0), "Failed to burn Defesa")
	var returned_def := [def_card.duplicate(true)]
	game._update_burned_card_marks_after_shop(returned_def)

	var def_summary: String = String(returned_def[0].get("cinzas_bonus_summary", ""))
	_check(def_summary.contains("resistencia") or def_summary.contains("defesa"), "Defesa summary must mention defense, got: " + def_summary)
	_check(not def_summary.contains("vida maxima") and not def_summary.contains("dano"), "Defesa must NOT grant Max HP or Damage, got: " + def_summary)

	var def_before: float = game.player_defense
	game._apply_card(returned_def[0])
	var def_after: float = game.player_defense
	_check(is_equal_approx(def_after - def_before, 5.25), "Burned Defesa should grant 5.25 defense (3.5 * 1.5), got: %f" % (def_after - def_before))

	# Multi-stack Test: Burn Defesa twice (2 stacks)
	# Stacking 2 burn stacks gives factor 0.5 * 2 = +1.0 -> effective 2.0 copies (+7.0 defense)
	game.cards_bought[game.CARD_CINZAS_ID] = 10
	game.shop_cards = [def_card.duplicate(true)]
	game.shop_selected = 0
	_burn_slot(0) # Stack 1
	var buffed_def_return := [def_card.duplicate(true)]
	game._update_burned_card_marks_after_shop(buffed_def_return)
	game.shop_cards = [buffed_def_return[0].duplicate(true)]
	game.shop_selected = 0
	_check(_burn_slot(0), "Failed to burn already-buffed Defesa")
	_check(game._cinzas_mark_stacks("Defesa") == 2, "Defesa burn stacks should be 2")

	var stacked_def_return := [def_card.duplicate(true)]
	game._update_burned_card_marks_after_shop(stacked_def_return)
	_check(int(stacked_def_return[0].get("cinzas_buff_stacks", 0)) == 2, "Defesa stacked return must have 2 stacks")

	var def_pre_stack: float = game.player_defense
	game._apply_card(stacked_def_return[0])
	# Total effective count = 2 cards bought + 3 burn stacks (1.5 bonus) = 3.5 -> 3.5 * 3.5 = 12.25 defense.
	# Gain is 12.25 - 5.25 = 7.0 defense!
	_check(is_equal_approx(game.player_defense, 12.25), "Defesa after 2nd burned purchase should be 12.25, got: %f" % game.player_defense)

	# Cap Test: Defense cap is 50.0. Give 20 copies of Defesa.
	game.cards_bought["Defesa"] = 20
	game._recalculate_common_card_stat_bonuses()
	_check(is_equal_approx(game.player_defense, 50.0), "Defense must be hard-capped at 50.0, got: %f" % game.player_defense)

	# =========================================================================
	# TEST 4: Non-Damage Category 2 - Movement Speed (Speed Boost)
	# =========================================================================
	game.cards_bought["Speed Boost"] = 0
	game.cinzas_card_bonuses.erase("Speed Boost")
	game._recalculate_common_card_stat_bonuses()
	var speed_base: float = game.player_speed

	var speed_card: Dictionary = game._find_card_by_id("Speed Boost")
	game.shop_cards = [speed_card.duplicate(true)]
	game.shop_selected = 0
	_burn_slot(0) # 1 stack
	var returned_speed := [speed_card.duplicate(true)]
	game._update_burned_card_marks_after_shop(returned_speed)

	var speed_summary: String = String(returned_speed[0].get("cinzas_bonus_summary", ""))
	_check(speed_summary.contains("velocidade"), "Speed Boost summary must mention velocidade, got: " + speed_summary)

	game._apply_card(returned_speed[0])
	# Normal speed gain for 1 copy: BASE * (pow(1.065, 1.0) - 1.0) = BASE * 0.065 (~18.2)
	# Burned speed gain for 1.5 copies: BASE * (pow(1.065, 1.5) - 1.0) = BASE * ~0.0991 (~27.75)
	var speed_gain: float = game.player_speed - speed_base
	var normal_speed_gain: float = game.PLAYER_BASE_SPEED * (pow(1.065, 1.0) - 1.0)
	_check(speed_gain > normal_speed_gain, "Burned Speed Boost gain must be higher than normal (%f > %f)" % [speed_gain, normal_speed_gain])
	_check(is_equal_approx(speed_gain, game.PLAYER_BASE_SPEED * (pow(1.065, 1.5) - 1.0)), "Speed gain did not match effective 1.5 formula")

	# =========================================================================
	# TEST 5: Non-Damage Category 3 - Attack Speed & Dash Cooldown (with Floors)
	# =========================================================================
	# Test 5a: Speed Atack
	game.cards_bought["Speed Atack"] = 0
	game.cinzas_card_bonuses.erase("Speed Atack")
	game._recalculate_common_card_stat_bonuses()
	var initial_interval: float = game.player_attack_interval

	var atack_card: Dictionary = game._find_card_by_id("Speed Atack")
	game.shop_cards = [atack_card.duplicate(true)]
	game.shop_selected = 0
	_burn_slot(0)
	var returned_atack := [atack_card.duplicate(true)]
	game._update_burned_card_marks_after_shop(returned_atack)

	var atack_summary: String = String(returned_atack[0].get("cinzas_bonus_summary", ""))
	_check(atack_summary.contains("intervalo") or atack_summary.contains("disparo"), "Speed Atack summary must mention intervalo, got: " + atack_summary)

	game._apply_card(returned_atack[0])
	# Normal reduction is 0.014s; burned reduction is 0.014 * 1.5 = 0.021s
	var interval_reduction: float = initial_interval - game.player_attack_interval
	_check(is_equal_approx(interval_reduction, 0.021), "Burned Speed Atack reduction should be 0.021s, got: %f" % interval_reduction)

	# Attack Interval Floor Test: floor is 0.28s
	game.cards_bought["Speed Atack"] = 50
	game._recalculate_common_card_stat_bonuses()
	_check(is_equal_approx(game.player_attack_interval, 0.28), "Attack interval must not drop below 0.28s floor, got: %f" % game.player_attack_interval)

	# Test 5b: Teleporte Cooldown Floor
	game.cards_bought["Teleporte"] = 0
	game.cinzas_card_bonuses.erase("Teleporte")
	game._recalculate_common_card_stat_bonuses()
	var initial_dash_cd: float = game.player_dash_cooldown

	var tp_card: Dictionary = game._find_card_by_id("Teleporte")
	game.shop_cards = [tp_card.duplicate(true)]
	game.shop_selected = 0
	_burn_slot(0)
	var returned_tp := [tp_card.duplicate(true)]
	game._update_burned_card_marks_after_shop(returned_tp)
	game._apply_card(returned_tp[0])
	# Burned reduction is 0.3 * 1.5 = 0.45s
	var dash_reduction: float = initial_dash_cd - game.player_dash_cooldown
	_check(is_equal_approx(dash_reduction, 0.45), "Burned Teleporte reduction should be 0.45s, got: %f" % dash_reduction)

	# Dash Cooldown Floor Test: floor is 0.5s
	game.cards_bought["Teleporte"] = 20
	game._recalculate_common_card_stat_bonuses()
	_check(is_equal_approx(game.player_dash_cooldown, 0.5), "Dash cooldown must not drop below 0.5s floor, got: %f" % game.player_dash_cooldown)

	# =========================================================================
	# TEST 6: Non-Damage Category 4 - Resistance & Area (Inercia Cronal & Orbita)
	# =========================================================================
	game.cards_bought["inercia_cronal"] = 0
	game.cinzas_card_bonuses.erase("inercia_cronal")
	var inercia_card: Dictionary = game._find_card_by_id("inercia_cronal")
	game.shop_cards = [inercia_card.duplicate(true)]
	game.shop_selected = 0
	_burn_slot(0)
	var returned_inercia := [inercia_card.duplicate(true)]
	game._update_burned_card_marks_after_shop(returned_inercia)
	game._apply_card(returned_inercia[0])

	# Effective count 1.5 -> control mult = 1.0 - (1.5 * 0.08) = 0.88, knockback mult = 1.0 - (1.5 * 0.18) = 0.73
	_check(is_equal_approx(game._inercia_control_multiplier(), 0.88), "Inercia control mult should be 0.88 with 1.5 effective stacks, got: %f" % game._inercia_control_multiplier())
	_check(is_equal_approx(game._inercia_knockback_multiplier(), 0.73), "Inercia knockback mult should be 0.73 with 1.5 effective stacks, got: %f" % game._inercia_knockback_multiplier())

	# Inercia Caps: max control resist 0.40 (mult 0.60), max knockback resist 0.72 (mult 0.28)
	game.cards_bought["inercia_cronal"] = 20
	_check(is_equal_approx(game._inercia_control_multiplier(), 0.60), "Inercia control reduction must cap at 0.40")
	_check(is_equal_approx(game._inercia_knockback_multiplier(), 0.28), "Inercia knockback reduction must cap at 0.72")

	# =========================================================================
	# TEST 7: Multiplayer Deck and Cinzas Bonuses Synchronization
	# =========================================================================
	game.is_multiplayer = true
	game.online_connected = true
	game.dedicated_server_mode = false
	game.net_decks_by_peer.clear()

	# Simulate remote peer 2 sending deck with burned bonuses
	var remote_payload: Dictionary = {
		"counts": {"Defesa": 2, "Speed Boost": 1},
		"cinzas_bonuses": {"Defesa": 1, "Speed Boost": 2}
	}
	game._rpc_remote_deck(2, remote_payload, "PLAYER_DOIS")

	_check(game.net_decks_by_peer.has(2), "Remote deck for peer 2 was not stored")
	var peer2_entry: Dictionary = Dictionary(game.net_decks_by_peer[2])
	_check(peer2_entry.get("name", "") == "PLAYER_DOIS", "Remote player name mismatched")
	_check(int(Dictionary(peer2_entry.get("counts", {})).get("Defesa", 0)) == 2, "Remote Defesa count mismatched")
	_check(int(Dictionary(peer2_entry.get("cinzas_bonuses", {})).get("Defesa", 0)) == 1, "Remote Defesa cinzas bonus mismatched")
	_check(int(Dictionary(peer2_entry.get("cinzas_bonuses", {})).get("Speed Boost", 0)) == 2, "Remote Speed Boost cinzas bonus mismatched")

	# Test backward compatibility: flat dictionary payload
	game._rpc_remote_deck(3, {"Porcao": 3}, "PLAYER_TRES")
	_check(game.net_decks_by_peer.has(3), "Remote deck for peer 3 was not stored")
	var peer3_entry: Dictionary = Dictionary(game.net_decks_by_peer[3])
	_check(int(Dictionary(peer3_entry.get("counts", {})).get("Porcao", 0)) == 3, "Backward-compatible counts failed")

	print("CINZAS_ATTRIBUTE_BURN_SYSTEM_SMOKE_OK policy=true damage=true defense=true speed=true attack_speed=true cooldown=true resistance=true caps=true multiplayer=true")
	root.remove_child(game)
	game.queue_free()
	quit(0)
