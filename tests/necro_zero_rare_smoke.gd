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
	print("NECRO_ZERO_RARE_SMOKE_FAIL %s" % message)


func _find_card(card_id: String) -> Dictionary:
	for card in game.CARDS:
		if game._card_id(card) == card_id:
			return card
	return {}


func _spawn_test_enemy(pos: Vector2, hp := 100.0, enemy_type := "") -> Dictionary:
	var type_id: String = enemy_type if enemy_type != "" else game.ENEMY_COMMON
	game._spawn_enemy(type_id, pos)
	var enemy: Dictionary = game.enemies[-1]
	enemy["pos"] = pos
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["killed_by_source"] = "atk"
	enemy["killed_by_category"] = "basic_attack"
	return enemy


func _reset_fixture() -> void:
	game._reset_card_counts()
	game._reset_card_proc_state()
	game.enemies.clear()
	game.active_necro_specters.clear()
	game.player_pos = Vector2(500, 500)
	game.player_speed = game.PLAYER_BASE_SPEED
	game.player_damage = game._manifestation_base_damage()
	game.player_attack_interval = game._manifestation_attack_interval()
	game.player_dash_cooldown = game.PLAYER_BASE_DASH_COOLDOWN
	game.player_defense = 0.0
	game.player_crit_chance = 0.0
	game.player_lifesteal = 0.0
	game.luck = 0.0
	game.poison_damage = 0.0
	game.execute_threshold = 0.0
	game.time_alive = 30.0
	game.boss_active = false
	game.boss_hp = 0.0


func _run() -> void:
	game._start_game()
	_reset_fixture()

	var zero := _find_card("carta_zero")
	var necro := _find_card("necrocronismo")
	_check(not zero.is_empty(), "missing_carta_zero")
	_check(not necro.is_empty(), "missing_necrocronismo")
	for card in [zero, necro]:
		_check(game._is_rare_card(card), "card_not_rare_%s" % game._card_id(card))
		_check(game._card_max_count(card) >= 999999, "card_not_infinite_%s" % game._card_id(card))
		_check(game.textures.get("card_" + String(card["name"])) != null, "missing_frame_1_%s" % game._card_id(card))
		_check(game.textures.get("card_" + String(card["name"]) + "_2") != null, "missing_frame_2_%s" % game._card_id(card))

	for i in range(12):
		game._apply_card(zero)
		game._apply_card(necro)
	_check(game._rare_card_count("carta_zero") == 12, "carta_zero_count_not_unlimited")
	_check(game._rare_card_count("necrocronismo") == 12, "necrocronismo_count_not_unlimited")
	_check(not game._card_at_max(zero), "carta_zero_left_pool_by_count")
	_check(not game._card_at_max(necro), "necrocronismo_left_pool_by_count")
	_check(game._carta_zero_multiplier() > 1.0 + 0.06 * sqrt(1.0), "carta_zero_sqrt_scaling_missing")
	_check(game._necro_kills_required() >= 4, "necro_requirement_below_floor")

	_reset_fixture()
	var speed := _find_card("Speed Boost")
	var dash := _find_card("Teleporte")
	var poison := _find_card("Poison")
	game._apply_card(speed)
	var speed_without_zero: float = game.player_speed
	game._apply_card(zero)
	var speed_with_zero: float = game.player_speed
	_check(speed_with_zero > speed_without_zero, "zero_did_not_improve_existing_common")
	var stable_speed: float = game.player_speed
	game._recalculate_common_card_stat_bonuses()
	game._recalculate_common_card_stat_bonuses()
	_check(is_equal_approx(game.player_speed, stable_speed), "zero_recalculation_accumulated_speed")
	var dash_before: float = game.player_dash_cooldown
	game._apply_card(dash)
	_check(game.player_dash_cooldown < dash_before - 0.30, "zero_did_not_amplify_cooldown_reduction")
	game._apply_card(poison)
	var poison_before_zero: float = game.poison_damage
	game._apply_card(zero)
	_check(is_equal_approx(game.poison_damage, poison_before_zero), "zero_affected_rare_poison")
	_check(game._rare_card_count("Poison") == 1 or game._card_count(poison) == 1, "rare_counter_changed_unexpectedly")

	_reset_fixture()
	var one_enemy := _spawn_test_enemy(Vector2(540, 500), 80.0)
	game._register_valid_necro_kill(one_enemy)
	_check(game.necro_kill_counter == 0 and game.active_necro_specters.is_empty(), "necro_counted_before_purchase")
	game._apply_card(necro)
	var required: int = game._necro_kills_required()
	for i in range(required):
		var enemy := _spawn_test_enemy(Vector2(550 + i * 4, 500), 80.0)
		game._register_valid_necro_kill(enemy)
	_check(game.active_necro_specters.size() == 1, "necro_did_not_spawn_specter")
	var specter: Dictionary = game.active_necro_specters[0]
	_check(bool(specter.get("is_necro_specter", false)), "necro_specter_not_safe_copy")
	_check(float(specter.get("life", 0.0)) > 0.0 and float(specter.get("power", 0.0)) > 0.0, "necro_specter_missing_life_or_power")
	var loop_enemy := _spawn_test_enemy(Vector2(570, 500), 50.0)
	loop_enemy["killed_by_source"] = game.RARE_SOURCE_NECRO
	loop_enemy["killed_by_category"] = "necro_specter"
	game._register_valid_necro_kill(loop_enemy)
	_check(game.active_necro_specters.size() == 1, "necro_specter_created_loop")
	game.boss_active = true
	game.boss_hp = 0.0
	game._register_valid_necro_kill({"type": "boss", "killed_by_source": "atk", "killed_by_category": "basic_attack"})
	_check(game.active_necro_specters.size() == 1, "necro_spawned_from_boss_like_data")
	game._reset_card_proc_state()
	game._reset_card_counts()
	_check(game.active_necro_specters.is_empty(), "reset_left_necro_specters")
	_check(game._rare_card_count("carta_zero") == 0 and game._rare_card_count("necrocronismo") == 0, "reset_left_rare_counts")

	if failed:
		quit(1)
		return
	print("NECRO_ZERO_RARE_SMOKE_OK rare=true frames=true infinite=true zero=true necro=true reset=true")
	quit(0)
