extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	print("DEVORADOR_DESTINOS_SMOKE_FAIL %s" % message)
	quit(1)


func _find_card(card_id: String) -> Dictionary:
	for card in game.CARDS:
		if game._card_id(card) == card_id:
			return card
	return {}


func _spawn_test_enemy(enemy_type: String, pos: Vector2, hp: float) -> Dictionary:
	game._spawn_enemy(enemy_type, pos)
	var enemy: Dictionary = game.enemies[game.enemies.size() - 1]
	enemy["type"] = enemy_type
	enemy["pos"] = pos
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["speed"] = 90.0
	enemy["reconstitute_time"] = 0.0
	return enemy


func _reset_fixture() -> void:
	game.enemies.clear()
	game.boss_active = false
	game.boss_dead = false
	game.boss_hp = 0.0
	game.boss_hp_max = 1000.0
	game.player_pos = Vector2(600, 420)
	game.player_hp_max = 500
	game.player_hp = 500
	game.player_defense = 0.0
	game.player_damage = 120.0
	game._reset_card_proc_state()
	game._reset_card_counts()


func _run() -> void:
	game._start_game()
	var card: Dictionary = _find_card("devorador_destinos")
	_check(not card.is_empty(), "missing_devorador_card")
	_check(game._is_rare_card(card), "devorador_not_rare")
	_check(String(card.get("icon", "")) == "Deck/carta-Devorador_de_Destinos1.png", "bad_frame_1_path")
	_check(String(card.get("frame_2", "")) == "Deck/carta-Devorador_de_Destinos2.png", "bad_frame_2_path")
	_check(game.textures["card_" + String(card["name"])] != null, "missing_frame_1_texture")
	_check(game.textures["card_" + String(card["name"]) + "_2"] != null, "missing_frame_2_texture")
	game.cards_bought["devorador_destinos"] = 500
	_check(not game._card_at_max(card), "devorador_should_be_infinite")
	_check(not game._card_damage_can_trigger(game.DEVORADOR_SOURCE), "devorador_should_not_trigger_cards")
	_check(not game._card_damage_can_receive_bonus(game.DEVORADOR_SOURCE), "devorador_should_not_receive_card_bonus")

	_reset_fixture()
	game._apply_card(card)
	_check(game.cards_bought["devorador_destinos"] == 1, "first_copy_not_counted")
	_check(game.devorador_mark_timer <= game.DEVORADOR_FIRST_MARK_DELAY, "first_mark_not_armed_fast")
	var common: Dictionary = _spawn_test_enemy(game.ENEMY_COMMON, Vector2(720, 420), 900.0)
	var elite: Dictionary = _spawn_test_enemy(game.ENEMY_GUARDIAO, Vector2(760, 420), 600.0)
	var bulky: Dictionary = _spawn_test_enemy(game.ENEMY_COMMON, Vector2(740, 440), 1500.0)
	var selected: Dictionary = game._select_devorador_enemy_target()
	_check(int(selected.get("uid", 0)) == int(elite.get("uid", 0)), "elite_priority_failed")
	game._apply_devorador_enemy_mark(bulky)
	var neighbor: Dictionary = _spawn_test_enemy(game.ENEMY_COMMON, Vector2(776, 440), 1000.0)
	game._handle_devorador_enemy_death(bulky)
	_check(game.devorador_mark_kind == "", "enemy_mark_not_cleared")
	_check(float(neighbor["hp"]) < 1000.0, "neighbor_not_damaged")
	_check(float(neighbor.get("devorador_fear", 0.0)) > 0.0, "neighbor_not_feared")
	_check(game.devorador_destiny_shield > 0.0 and game.devorador_shield_timer > 0.0, "shield_not_granted")
	var hp_before: int = game.player_hp
	var shield_before: float = game.devorador_destiny_shield
	game._damage_player(30, "test")
	_check(game.player_hp == hp_before, "shield_did_not_absorb_before_hp")
	_check(game.devorador_destiny_shield < shield_before, "shield_not_consumed")

	_reset_fixture()
	game._apply_card(card)
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 2000.0
	game.boss_hp = 2000.0
	game.boss_pos = Vector2(820, 420)
	game._apply_devorador_boss_mark()
	var boss_hp_before: float = game.boss_hp
	game._damage_boss(game.boss_hp_max * 0.25, "eletrica", false, false)
	_check(game.devorador_mark_kind == "", "boss_mark_not_cleared")
	_check(game.boss_hp < boss_hp_before - game.boss_hp_max * 0.09, "boss_rupture_damage_missing")
	_check(game.devorador_destiny_shield > 0.0, "boss_rupture_shield_missing")

	game._reset_card_proc_state()
	game._reset_card_counts()
	_check(game.cards_bought["devorador_destinos"] == 0, "card_count_not_reset")
	_check(game.devorador_mark_kind == "" and game.devorador_destiny_shield == 0.0 and game.devorador_effects.is_empty(), "devorador_state_not_reset")

	print("DEVORADOR_DESTINOS_SMOKE_OK rare=true infinite=true enemy_mark=true boss_mark=true shield=true no_recursion=true")
	quit(0)
