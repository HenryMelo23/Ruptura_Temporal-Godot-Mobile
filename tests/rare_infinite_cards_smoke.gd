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
	push_error(message)
	print("RARE_INFINITE_CARDS_SMOKE_FAIL %s" % message)


func _find_card(card_id: String) -> Dictionary:
	for card in game.CARDS:
		if game._card_id(card) == card_id:
			return card
	return {}


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
	game.active_necro_specters.clear()
	game.player_pos = Vector2(500, 500)
	game.player_hp = 450
	game.player_hp_max = 450
	game.player_speed = game.PLAYER_BASE_SPEED
	game.player_damage = 100.0
	game.player_attack_interval = game.PLAYER_BASE_ATTACK_INTERVAL
	game.player_dash_cooldown = game.PLAYER_BASE_DASH_COOLDOWN
	game.player_defense = 0.0
	game.player_crit_chance = 0.05
	game.player_lifesteal = 0.0
	game.poison_damage = 0.0
	game.execute_threshold = 0.0
	game.luck = 0.0
	game.time_alive = 30.0
	game.boss_active = false
	game.boss_hp = 0.0
	game.boss_hp_max = 1000.0
	game.boss_pos = Vector2(720, 500)
	game.current_phase = 1


func _run() -> void:
	game._start_game()
	_reset_fixture()

	var rare_ids := [
		"mandamento_ruptura",
		"carta_zero",
		"necrocronismo",
		"coracao_antimateria",
		"cofre_excesso"
	]
	for card_id in rare_ids:
		var card := _find_card(card_id)
		_check(not card.is_empty(), "missing_card_%s" % card_id)
		_check(game._is_rare_card(card), "card_should_be_rare_%s" % card_id)
		_check(game._card_max_count(card) >= 999999, "card_should_be_infinite_%s" % card_id)
		_check(game.cards_bought.has(card_id), "missing_card_counter_%s" % card_id)
		_check(game.textures["card_" + String(card["name"])] != null, "missing_frame_1_%s" % card_id)
		_check(game.textures["card_" + String(card["name"]) + "_2"] != null, "missing_frame_2_%s" % card_id)

	var zero := _find_card("carta_zero")
	var speed := _find_card("Speed Boost".to_snake_case())
	if speed.is_empty():
		speed = _find_card("Speed Boost")
	_check(not zero.is_empty(), "missing_zero_card")
	_check(not speed.is_empty(), "missing_speed_card")
	game._apply_card(speed)
	var speed_after_first: float = game.player_speed
	game._apply_card(zero)
	_check(game._carta_zero_multiplier() > 1.0, "zero_multiplier_missing")
	_check(game.player_speed > speed_after_first, "zero_retroactive_speed_missing")
	var speed_before_second: float = game.player_speed
	game._apply_card(speed)
	_check(game.player_speed > speed_before_second * 1.065, "zero_future_common_scale_missing")

	_reset_fixture()
	var mandamento := _find_card("mandamento_ruptura")
	game._apply_card(mandamento)
	var skill_time_before: float = game.last_skill_time
	var first_scale: float = game._register_manual_skill_use("skill_q", game._skill_cooldown())
	var second_scale: float = game._register_manual_skill_use("skill_q", game._skill_cooldown())
	var third_scale: float = game._register_manual_skill_use("skill_q", game._skill_cooldown())
	_check(is_equal_approx(first_scale, 1.0) and is_equal_approx(second_scale, 1.0), "mandamento_early_triggered")
	_check(third_scale > 1.0, "mandamento_third_skill_missing")
	_check(game.mandamento_invulnerability > 0.0, "mandamento_invulnerability_missing")
	_check(game.last_skill_time < skill_time_before, "mandamento_cooldown_recovery_missing")

	_reset_fixture()
	var necro := _find_card("necrocronismo")
	game._apply_card(necro)
	for i in range(game._necro_kills_required()):
		var enemy := _spawn_test_enemy(Vector2(540 + i * 3, 500), 20.0)
		enemy["killed_by_source"] = "atk"
		enemy["killed_by_category"] = "basic_attack"
		game._register_valid_necro_kill(enemy)
	_check(game.active_necro_specters.size() == 1, "necro_specter_not_spawned")
	var necro_enemy := _spawn_test_enemy(Vector2(580, 500), 100.0)
	necro_enemy["killed_by_source"] = game.RARE_SOURCE_NECRO
	necro_enemy["killed_by_category"] = "necro_specter"
	game._register_valid_necro_kill(necro_enemy)
	_check(game.active_necro_specters.size() == 1, "necro_rare_source_looped")

	_reset_fixture()
	var antimatter := _find_card("coracao_antimateria")
	game._apply_card(antimatter)
	game._register_antimatter_damage(game._antimatter_required_charge() / max(0.001, game._antimatter_charge_rate()) * 1.5, "atk", "basic_attack")
	_check(game.antimatter_armed, "antimatter_not_armed")
	var target := _spawn_test_enemy(Vector2(560, 500), 500.0)
	game._damage_enemy(target, 50.0, "atk", false, false, game.player_pos, "basic_attack")
	_check(not game.antimatter_armed, "antimatter_not_consumed")
	_check(float(target["hp"]) < 450.0, "antimatter_damage_missing")
	game._register_antimatter_damage(999999.0, game.RARE_SOURCE_ANTIMATTER, "rare_card")
	_check(not game.antimatter_armed, "antimatter_rare_source_rearmed")

	_reset_fixture()
	var cofre := _find_card("cofre_excesso")
	game._apply_card(cofre)
	var fragile := _spawn_test_enemy(Vector2(540, 500), 50.0)
	game._damage_enemy(fragile, 160.0, "atk", false, false, game.player_pos, "basic_attack")
	_check(game.stored_excess > 0.0, "cofre_did_not_store_overkill")
	var brute := _spawn_test_enemy(Vector2(580, 500), 1000.0, game.ENEMY_AGGLOMERATOR)
	game._damage_enemy(brute, 10.0, "atk", false, false, game.player_pos, "basic_attack")
	_check(game.excess_discharge_kind == "enemy", "cofre_target_not_selected")
	var stored_before: float = game.stored_excess
	game._update_excess_discharge(0.5)
	_check(game.stored_excess < stored_before, "cofre_not_released")
	game._store_excess_damage(999999.0, game.RARE_SOURCE_COFRE, "rare_card")
	_check(game.stored_excess < stored_before, "cofre_rare_source_looped")

	game._reset_card_proc_state()
	game._reset_card_counts()
	for card_id in rare_ids:
		_check(game.cards_bought[card_id] == 0, "reset_count_bad_%s" % card_id)
	_check(game.active_necro_specters.is_empty(), "reset_necro_bad")
	_check(game.rare_card_effects.is_empty(), "reset_rare_effects_bad")
	_check(not game.antimatter_armed and is_equal_approx(game.antimatter_charge, 0.0), "reset_antimatter_bad")
	_check(is_equal_approx(game.stored_excess, 0.0), "reset_cofre_bad")

	if failed:
		quit(1)
		return
	print("RARE_INFINITE_CARDS_SMOKE_OK cards=5 rare=true infinite=true zero=true mandamento=true necro=true antimatter=true cofre=true no_loop=true")
	quit(0)
