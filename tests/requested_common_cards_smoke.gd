extends SceneTree

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("REQUESTED_COMMON_CARDS_FAIL " + message)
	print("REQUESTED_COMMON_CARDS_FAIL %s" % message)
	quit(1)


func _reset_fixture() -> void:
	game._reset_card_counts()
	game._reset_card_proc_state()
	game.common_card_effects.clear()
	game.rare_card_effects.clear()
	game.enemies.clear()
	game.player_pos = Vector2(640, 360)
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_defense = 0.0
	game.player_damage = 100.0
	game.mode = "game"
	game.time_alive = 60.0
	game.is_dead = false
	game.is_multiplayer = false
	game.boss_active = false
	game.boss_dead = false
	game.boss_pos = Vector2(760, 360)
	game.boss_hp_max = 10000.0
	game.boss_hp = 10000.0
	game.current_phase = 1
	game.aura_state = {}
	game.contractual_order = {}
	game.contractual_order_penalties.clear()


func _run() -> void:
	await process_frame
	game._start_game()
	_reset_fixture()

	var ids: Array[String] = [
		game.CARD_ESTASE_ID,
		game.CARD_MANTO_IMPULSO_ID,
		game.CARD_RECUSA_DANO_ID,
		game.CARD_CARRASCO_COLOSSOS_ID,
		game.CARD_SUTURA_GRADUAL_ID
	]
	for card_id in ids:
		var card: Dictionary = game._find_card_by_id(card_id)
		_check(not card.is_empty(), "missing_%s" % card_id)
		if failed: return
		_check(game._is_common_card(card), "not_common_%s" % card_id)
		if failed: return
		_check(game._card_max_count(card) >= 999999, "not_unlimited_%s" % card_id)
		if failed: return
		_check(game._card_texture(card) != null, "missing_frame_1_%s" % card_id)
		if failed: return
		_check(game._get_texture("card_" + String(card["name"]) + "_2") != null, "missing_frame_2_%s" % card_id)
		if failed: return

	var estase: Dictionary = game._find_card_by_id(game.CARD_ESTASE_ID)
	game._apply_card(estase)
	var estase_rate_one: float = game._estase_heal_rate()
	var estase_radius_one: float = game._estase_radius()
	for i in range(5):
		game._apply_card(estase)
	_check(game._estase_heal_rate() > estase_rate_one, "estase_heal_does_not_scale")
	_check(game._estase_radius() > estase_radius_one, "estase_radius_does_not_scale")
	var deck_one := {"counts": {game.CARD_ESTASE_ID: 1}, "cinzas_bonuses": {}}
	var deck_six := {"counts": {game.CARD_ESTASE_ID: 6}, "cinzas_bonuses": {}}
	var net_one: Dictionary = game._estase_network_values_from_deck(deck_one)
	var net_six: Dictionary = game._estase_network_values_from_deck(deck_six)
	_check(float(net_six["rate"]) > float(net_one["rate"]), "estase_network_heal_does_not_scale")
	_check(float(net_six["radius"]) > float(net_one["radius"]), "estase_network_radius_does_not_scale")
	_reset_fixture()

	game._apply_card(game._find_card_by_id(game.CARD_MANTO_IMPULSO_ID))
	game._register_manual_skill_use("skill_q", 8.0)
	_check(game.manto_impulso_shield > 0.0 and game.manto_impulso_timer > 0.0, "manto_not_granted_on_skill")
	var shield_before: float = game.manto_impulso_shield
	var damage_after_shield: int = game._absorb_manto_impulso_shield(20)
	_check(damage_after_shield < 20 and game.manto_impulso_shield < shield_before, "manto_did_not_absorb")
	game._update_new_common_card_effects(game._manto_impulso_duration() + 0.1)
	_check(game.manto_impulso_shield == 0.0, "manto_did_not_expire")
	_reset_fixture()

	game._apply_card(game._find_card_by_id(game.CARD_RECUSA_DANO_ID))
	var chance_one: float = game._recusa_dano_chance()
	_check(chance_one > 0.0 and chance_one < 0.1, "recusa_initial_chance_not_low")
	_check(game._recusa_blocks_damage(0.0), "recusa_did_not_block_low_roll")
	_check(not game._recusa_blocks_damage(0.99), "recusa_blocked_high_roll")
	for i in range(24):
		game._apply_card(game._find_card_by_id(game.CARD_RECUSA_DANO_ID))
	_check(game._recusa_dano_chance() > chance_one, "recusa_does_not_scale")
	_reset_fixture()

	var baseline_multiplier: float = game._carrasco_boss_damage_multiplier("atk", "basic_attack")
	game._apply_card(game._find_card_by_id(game.CARD_CARRASCO_COLOSSOS_ID))
	var boss_multiplier: float = game._carrasco_boss_damage_multiplier("atk", "basic_attack")
	var indirect_multiplier: float = game._carrasco_boss_damage_multiplier("card_proc", "common_card")
	_check(is_equal_approx(baseline_multiplier, 1.0), "carrasco_baseline_changed")
	_check(boss_multiplier >= 1.18, "carrasco_direct_bonus_too_low")
	_check(is_equal_approx(indirect_multiplier, 1.0), "carrasco_buffed_indirect_damage")
	_reset_fixture()

	game._apply_card(game._find_card_by_id(game.CARD_SUTURA_GRADUAL_ID))
	game.player_hp = 500
	game._damage_player(100, "boss", true)
	var queued: float = game.sutura_gradual_pending
	_check(game.player_hp == 400 and queued > 0.0, "sutura_not_queued_from_real_damage")
	game._update_sutura_gradual(0.1)
	_check(game.player_hp > 400 and game.player_hp < 400 + queued, "sutura_not_paid_in_small_slice")
	for i in range(36):
		game._update_sutura_gradual(0.1)
	_check(game.sutura_gradual_pending <= 0.01, "sutura_did_not_finish")
	_reset_fixture()

	for card_id in ids:
		var card: Dictionary = game._find_card_by_id(card_id)
		for i in range(32):
			game._apply_card(card)
		_check(game._card_count_by_id(card_id) == 32, "infinite_stack_failed_%s" % card_id)
		if failed: return

	print("REQUESTED_COMMON_CARDS_SMOKE_OK common=5 unlimited=true estase_allies=true shield=true damage_block=true boss_bonus=true sliced_heal=true")
	quit(0)
