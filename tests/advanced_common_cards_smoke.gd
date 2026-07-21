extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _find_card(card_id: String) -> Dictionary:
	for card in game.CARDS:
		if game._card_id(card) == card_id:
			return card
	return {}


func _has_card(cards: Array, card_id: String) -> bool:
	for card in cards:
		if game._card_id(card) == card_id:
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	print("ADVANCED_COMMON_CARDS_SMOKE_FAIL %s" % message)
	quit(1)


func _spawn_test_enemy(pos: Vector2, hp := 1000.0, enemy_type := "") -> Dictionary:
	var type_id: String = enemy_type if enemy_type != "" else game.ENEMY_COMMON
	game._spawn_enemy(type_id, pos)
	var enemy: Dictionary = game.enemies[game.enemies.size() - 1]
	enemy["pos"] = pos
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["facing_dir"] = Vector2.RIGHT
	enemy["last_move_dir"] = Vector2.RIGHT
	return enemy


func _reset_fixture() -> void:
	game._reset_card_counts()
	game._reset_card_proc_state()
	game.enemies.clear()
	game.player_pos = Vector2(500, 500)
	game.player_damage = 100.0
	game.time_alive = 30.0
	game.boss_active = false
	game.boss_hp = 0.0
	game.boss_hp_max = 1000.0
	game.boss_pos = Vector2(720, 500)
	game.current_phase = 1


func _run() -> void:
	game._start_game()

	var expected_ids := [
		"choque_fontes",
		"ferrolho_ruptura",
		"limiar_colapso",
		"desvio_probabilidade",
		"ponto_cego"
	]
	for card_id in expected_ids:
		var card := _find_card(card_id)
		_check(not card.is_empty(), "missing_card_%s" % card_id)
		_check(not game._is_rare_card(card), "card_should_be_common_%s" % card_id)
		_check(game._card_max_count(card) >= 999999, "card_should_be_infinite_%s" % card_id)
		_check(game.cards_bought.has(card_id), "missing_card_counter_%s" % card_id)
		_check(game.textures["card_" + String(card["name"])] != null, "missing_frame_1_%s" % card_id)
		_check(game.textures["card_" + String(card["name"]) + "_2"] != null, "missing_frame_2_%s" % card_id)
		for i in range(24):
			game._apply_card(card)
		_check(game.cards_bought[card_id] == 24, "card_was_clamped_%s" % card_id)
	_reset_fixture()

	_check(game._damage_source_category("atk", "basic_attack") == "basic_attack", "basic_category_bad")
	_check(game._damage_source_category("tp_lacerante", "teleport") == "teleport", "teleport_category_bad")
	_check(game._damage_source_category("aura_fome") == "aura", "aura_category_bad")
	_check(game._damage_source_category(game.CARD_SOURCE_CHOQUE, "common_card") == "common_card", "common_card_category_bad")
	_check(not game._source_can_trigger_secondary_cards(game.CARD_SOURCE_CHOQUE), "card_source_can_loop")

	game.cards_bought["choque_fontes"] = 1
	var choque_enemy := _spawn_test_enemy(Vector2(540, 500), 1000.0)
	game._damage_enemy(choque_enemy, 50.0, "atk", false, false, game.player_pos, "basic_attack")
	var after_basic: float = float(choque_enemy["hp"])
	game.time_alive += 0.25
	game._damage_enemy(choque_enemy, 50.0, "electric_q", false, false, game.player_pos, "skill_q")
	_check(float(choque_enemy["hp"]) < after_basic - 50.0, "choque_no_interference")
	var after_choque: float = float(choque_enemy["hp"])
	game._damage_enemy(choque_enemy, 10.0, game.CARD_SOURCE_CHOQUE, false, false, game.player_pos, "common_card")
	_check(is_equal_approx(float(choque_enemy["hp"]), after_choque - 10.0), "choque_card_source_looped")
	var second_choque_enemy := _spawn_test_enemy(Vector2(640, 500), 1000.0)
	game._damage_enemy(second_choque_enemy, 50.0, "atk", false, false, game.player_pos, "basic_attack")
	game.time_alive += 0.25
	game._damage_enemy(second_choque_enemy, 50.0, "aura_fome", false, false, game.player_pos, "aura")
	_check(float(second_choque_enemy["hp"]) < 900.0, "choque_not_per_target")

	_reset_fixture()
	game.cards_bought["ferrolho_ruptura"] = 1
	game._update_card_proc_state(game.FERROLHO_RUPTURA_COOLDOWN)
	_check(game.ferrolho_ruptura_armed, "ferrolho_not_armed")
	var ferrolho_enemy := _spawn_test_enemy(Vector2(540, 500), 1000.0)
	game._damage_enemy(ferrolho_enemy, 50.0, "atk", false, false, game.player_pos, "basic_attack")
	_check(not game.ferrolho_ruptura_armed, "ferrolho_not_consumed")
	_check(is_equal_approx(game.ferrolho_ruptura_cooldown, game.FERROLHO_RUPTURA_COOLDOWN), "ferrolho_cooldown_bad")
	_check(float(ferrolho_enemy["ferrolho_root"]) > 0.0, "ferrolho_root_missing")
	var target_before: Vector2 = game._get_enemy_target_pos(ferrolho_enemy)
	game._update_enemies(0.1)
	_check(Vector2(ferrolho_enemy["pos"]).distance_to(Vector2(540, 500)) < 0.01, "ferrolho_enemy_moved")
	_check(target_before.distance_to(game.player_pos) < 0.01, "ferrolho_changed_target")
	game.ferrolho_ruptura_armed = true
	game.boss_active = true
	game.boss_hp = 1000.0
	game._damage_boss(25.0, "atk", false, false, "basic_attack", game.player_pos)
	_check(game.boss_ferrolho_slow_timer > 0.0, "ferrolho_boss_slow_missing")
	_check(game._boss_card_move_multiplier() < 1.0, "ferrolho_boss_multiplier_bad")

	_reset_fixture()
	game.cards_bought["limiar_colapso"] = 1
	var limiar_enemy := _spawn_test_enemy(Vector2(540, 500), 1000.0)
	game._damage_enemy(limiar_enemy, 650.0, "atk", false, false, game.player_pos, "basic_attack")
	_check((int(limiar_enemy["limiar_mask"]) & 1) != 0, "limiar_70_missing")
	_check((int(limiar_enemy["limiar_mask"]) & 2) != 0, "limiar_40_missing")
	_check(float(limiar_enemy["hp"]) < 350.0, "limiar_damage_missing")
	var limiar_after: float = float(limiar_enemy["hp"])
	game._damage_enemy(limiar_enemy, 1.0, game.CARD_SOURCE_LIMIAR, false, false, game.player_pos, "common_card")
	_check(is_equal_approx(float(limiar_enemy["hp"]), limiar_after - 1.0), "limiar_card_source_looped")

	_reset_fixture()
	game.cards_bought["desvio_probabilidade"] = 1
	var bullet := {"pos": Vector2(560, 520), "from_enemy": true}
	game._track_probability_near_miss(bullet, Vector2(440, 520), 12.0)
	_check(game.desvio_probabilidade_charges == 1, "desvio_charge_missing")
	game._track_probability_near_miss(bullet, Vector2(440, 520), 12.0)
	_check(game.desvio_probabilidade_charges == 1, "desvio_double_charged")
	var desvio_enemy := _spawn_test_enemy(Vector2(540, 500), 1000.0)
	game._damage_enemy(desvio_enemy, 50.0, "atk", false, false, game.player_pos, "basic_attack")
	_check(game.desvio_probabilidade_charges == 0, "desvio_not_consumed")
	_check(float(desvio_enemy["hp"]) < 950.0, "desvio_bonus_missing")

	_reset_fixture()
	game.cards_bought["ponto_cego"] = 1
	var ponto_enemy := _spawn_test_enemy(Vector2(540, 500), 1000.0)
	game._damage_enemy(ponto_enemy, 50.0, "atk", false, false, Vector2(480, 500), "basic_attack")
	_check(float(ponto_enemy["hp"]) < 950.0, "ponto_cego_damage_missing")
	_check(float(ponto_enemy["blind_confusion"]) > 0.0, "ponto_cego_confusion_missing")
	var blind_target: Vector2 = game._get_enemy_target_pos(ponto_enemy)
	_check(blind_target.distance_to(game.player_pos) < 0.01, "ponto_cego_decoy_bad")
	var front_enemy := _spawn_test_enemy(Vector2(540, 620), 1000.0)
	game._damage_enemy(front_enemy, 50.0, "atk", false, false, Vector2(600, 620), "basic_attack")
	_check(is_equal_approx(float(front_enemy["hp"]), 950.0), "ponto_cego_front_triggered")

	game._reset_card_proc_state()
	game._reset_card_counts()
	for card_id in expected_ids:
		_check(game.cards_bought[card_id] == 0, "reset_count_bad_%s" % card_id)
	_check(game.desvio_probabilidade_charges == 0, "reset_desvio_bad")
	_check(not game.ferrolho_ruptura_armed, "reset_ferrolho_bad")
	_check(game.common_card_effects.is_empty(), "reset_effects_bad")

	print("ADVANCED_COMMON_CARDS_SMOKE_OK cards=5 infinite=true assets=true choque=true ferrolho=true limiar=true desvio=true ponto_cego=true no_loop=true")
	quit(0)
