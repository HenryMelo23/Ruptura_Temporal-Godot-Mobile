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


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	print("CARD_PROC_EFFECTS_SMOKE_FAIL %s" % message)
	quit(1)


func _spawn_test_enemy(pos: Vector2, hp := 1000.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies[game.enemies.size() - 1]
	enemy["pos"] = pos
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	return enemy


func _reset_combat_fixture() -> void:
	game.enemies.clear()
	game.boss_active = false
	game.boss_hp = 0.0
	game.boss_hp_max = 1000.0
	game.boss_fragilidade_cronal_timer = 0.0
	game.boss_fragilidade_cronal_bonus = 0.0
	game.fratura_cronal_armed = false
	game.fratura_cronal_cooldown = 0.0
	game.pulso_desestabilizador_armed = false
	game.pulso_desestabilizador_cooldown = 0.0


func _run() -> void:
	game._start_game()
	var expected_ids := [
		"fratura_cronal",
		"pulso_desestabilizador",
		"pressao_cerco"
	]
	for card_id in expected_ids:
		var card := _find_card(card_id)
		_check(not card.is_empty(), "missing_card_%s" % card_id)
		_check(not game._is_rare_card(card), "card_should_be_common_%s" % card_id)
		_check(game._card_max_count(card) >= 999999, "card_should_be_unlimited_%s" % card_id)
		_check(game.textures["card_" + String(card["name"])] != null, "missing_texture_1_%s" % card_id)
		_check(game.textures["card_" + String(card["name"]) + "_2"] != null, "missing_texture_2_%s" % card_id)

	game.cards_bought["fratura_cronal"] = 5
	_check(is_equal_approx(game._fratura_cronal_bonus(), 0.12), "fratura_bonus_bad")
	var fratura := _find_card("fratura_cronal")
	for i in range(8):
		game._apply_card(fratura)
	_check(game.cards_bought["fratura_cronal"] == 13, "fratura_should_keep_stacking")
	_check(not game._card_at_max(fratura), "fratura_should_never_be_maxed")

	_reset_combat_fixture()
	game.cards_bought["fratura_cronal"] = 5
	game.fratura_cronal_armed = true
	var fragile_enemy := _spawn_test_enemy(Vector2(500, 500), 1000.0)
	game._damage_enemy(fragile_enemy, 100.0, "atk", false, false)
	_check(not game.fratura_cronal_armed, "fratura_not_consumed")
	_check(is_equal_approx(game.fratura_cronal_cooldown, game.FRATURA_CRONAL_COOLDOWN), "fratura_cooldown_bad")
	_check(is_equal_approx(float(fragile_enemy["fragilidade_cronal"]), game.FRATURA_CRONAL_DURATION), "fratura_duration_bad")
	_check(is_equal_approx(float(fragile_enemy["fragilidade_cronal_bonus"]), 0.12), "fratura_enemy_bonus_bad")
	_check(is_equal_approx(float(fragile_enemy["hp"]), 888.0), "fratura_damage_bad")
	game._damage_enemy(fragile_enemy, 100.0, "atk", false, false)
	_check(is_equal_approx(float(fragile_enemy["hp"]), 776.0), "fratura_second_damage_bad")

	_reset_combat_fixture()
	game.cards_bought["fratura_cronal"] = 5
	game.fratura_cronal_armed = true
	game.boss_active = true
	game.boss_hp = 1000.0
	game.boss_hp_max = 1000.0
	game.boss_pos = Vector2(700, 420)
	game._damage_boss(100.0, "atk", false, false)
	_check(is_equal_approx(game.boss_fragilidade_cronal_timer, game.FRATURA_CRONAL_DURATION), "fratura_boss_duration_bad")
	_check(is_equal_approx(game.boss_fragilidade_cronal_bonus, 0.06), "fratura_boss_bonus_bad")

	_reset_combat_fixture()
	game.cards_bought["pulso_desestabilizador"] = 5
	game.player_damage = 100.0
	game.pulso_desestabilizador_armed = true
	var pulse_target := _spawn_test_enemy(Vector2(500, 500), 1000.0)
	var pulse_neighbor := _spawn_test_enemy(Vector2(548, 500), 1000.0)
	game._damage_enemy(pulse_target, 10.0, "atk", false, false)
	_check(not game.pulso_desestabilizador_armed, "pulso_not_consumed")
	_check(is_equal_approx(game.pulso_desestabilizador_cooldown, game.PULSO_DESESTABILIZADOR_COOLDOWN), "pulso_cooldown_bad")
	_check(float(pulse_neighbor["hp"]) < 1000.0, "pulso_neighbor_not_damaged")
	_check(game.fratura_cronal_armed == false, "pulso_rearmed_fratura")

	_reset_combat_fixture()
	game.cards_bought["pressao_cerco"] = 3
	var siege_target := _spawn_test_enemy(Vector2(500, 500), 1000.0)
	_spawn_test_enemy(Vector2(590, 500), 1000.0)
	_spawn_test_enemy(Vector2(500, 590), 1000.0)
	_spawn_test_enemy(Vector2(430, 500), 1000.0)
	game._damage_enemy(siege_target, 100.0, "atk", false, false)
	_check(is_equal_approx(float(siege_target["hp"]), 885.0), "cerco_enemy_damage_bad")

	_reset_combat_fixture()
	game.cards_bought["pressao_cerco"] = 3
	game.boss_active = true
	game.boss_hp = 1000.0
	game.boss_hp_max = 1000.0
	game.boss_pos = Vector2(500, 500)
	_spawn_test_enemy(Vector2(590, 500), 1000.0)
	_spawn_test_enemy(Vector2(500, 590), 1000.0)
	_spawn_test_enemy(Vector2(430, 500), 1000.0)
	game._damage_boss(100.0, "atk", false, false)
	_check(game.boss_hp < 945.0, "cerco_boss_damage_bad")

	print("CARD_PROC_EFFECTS_SMOKE_OK fratura=true pulso=true cerco=true assets=true unlimited=true")
	quit(0)
