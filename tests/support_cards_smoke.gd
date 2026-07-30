extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("SUPPORT_CARDS_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _support_card(id: String) -> Dictionary:
	var card: Dictionary = game._find_card_by_id(id)
	_check(not card.is_empty(), id + " was not registered")
	_check(not game._is_rare_card(card), id + " should be common")
	_check(game._card_max_count(card) >= 999999, id + " should be unlimited")
	_check(game._card_texture(card) != null, id + " frame 1 did not load")
	return card


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.player_defense = 0
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.aura_state = {}
	game._reset_card_counts()
	game._reset_card_proc_state()

	var ids: Array[String] = [
		game.CARD_TREGUA_ID,
		game.CARD_CINZAS_ID,
		game.CARD_RESERVA_ID,
		game.CARD_CASULO_ID,
		game.CARD_PASSAGEM_ID,
		game.CARD_ANCORA_ID
	]
	for id in ids:
		var card: Dictionary = _support_card(id)
		game._apply_card(card)
		_check(game._card_count_by_id(id) == 1, id + " did not increment its counter")

	game.player_hp = 800
	game.tregua_regenerativa_timer = game._tregua_delay()
	game._update_tregua_regenerativa(1.0)
	_check(game.tregua_regenerativa_active, "Tregua did not activate after its delay")
	_check(game.player_hp > 800 and game.player_hp <= game.player_hp_max, "Tregua did not heal inside max HP")
	game._damage_player(20, "test_projectile")
	_check(game.tregua_regenerativa_timer == 0.0 and not game.tregua_regenerativa_active, "Tregua did not reset on real damage")

	var common_card: Dictionary = game._find_card_by_id(game.CARD_TREGUA_ID)
	var rare_card: Dictionary = game._find_card_by_id("devorador_destinos")
	game.shop_cards = [common_card.duplicate(true), rare_card.duplicate(true)]
	game.shop_selected = 0
	var cinzas_before: int = game._card_count_by_id(game.CARD_CINZAS_ID)
	_check(game._burn_shop_card(0), "Cinzas could not burn a valid common card")
	_check(game._is_empty_shop_slot(game.shop_cards[0]), "Cinzas did not leave an empty slot")
	_check(game._card_count_by_id(game.CARD_CINZAS_ID) == cinzas_before - 1, "Cinzas was not consumed when burning")
	_check(game.cinzas_burn_marks.size() == 1, "Cinzas did not create a mark")
	_check(not game._can_burn_shop_card(rare_card), "Cinzas should not burn rare cards")
	_check(is_equal_approx(game._cinzas_weight_multiplier(game.CARD_TREGUA_ID), 1.0), "Cinzas should not change future common weight")
	game._update_burned_card_marks_after_shop([])
	_check(game.cinzas_burn_marks.size() == 1, "Cinzas mark should persist through rerolls")
	var returned_cards := [common_card.duplicate(true)]
	game._update_burned_card_marks_after_shop(returned_cards)
	_check(game.cinzas_burn_marks.size() == 1, "Cinzas mark should not be consumed when card merely reappears")
	_check(bool(returned_cards[0].get("cinzas_return_buff", false)), "Cinzas return did not add a one-time buff")
	_check(int(returned_cards[0].get("cinzas_buff_stacks", 0)) == 1, "Cinzas first return stack should be one")
	game._apply_card(game._find_card_by_id(game.CARD_CINZAS_ID))
	game.shop_cards = [returned_cards[0].duplicate(true)]
	_check(game._burn_shop_card(0), "Cinzas could not burn an already-buffed common card")
	_check(game._cinzas_mark_stacks(game.CARD_TREGUA_ID) == 2, "Cinzas did not stack when burning a buffed return")
	var stacked_return := [common_card.duplicate(true)]
	game._update_burned_card_marks_after_shop(stacked_return)
	_check(int(stacked_return[0].get("cinzas_buff_stacks", 0)) == 2, "Cinzas stacked return did not expose its buff count")
	var hp_max_before_cinzas_return: int = game.player_hp_max
	game._apply_card(stacked_return[0])
	_check(game.cinzas_burn_marks.is_empty(), "Cinzas mark was not consumed when the buffed card was bought")
	_check(game.player_hp_max > hp_max_before_cinzas_return, "Cinzas stacked return did not apply its one-time buff")

	game.player_hp = 1000
	game.reserva_pulso_stored = 0.0
	game._heal_player(200.0, "porcao", true)
	_check(game.reserva_pulso_stored > 0.0, "Reserva did not store valid overheal")
	var stored_before: float = game.reserva_pulso_stored
	game.player_hp = 430
	game._update_reserva_pulso(1.0)
	_check(game.player_hp > 430, "Reserva did not release under 45 percent HP")
	_check(game.reserva_pulso_stored < stored_before, "Reserva did not spend stored pulse")

	game.casulo_hit_times.clear()
	game.casulo_reativo_timer = 0.0
	game.casulo_reativo_cooldown = 0.0
	game.time_alive = 50.0
	game._register_hit_for_casulo(10)
	game.time_alive += 0.6
	game._register_hit_for_casulo(10)
	game.time_alive += 0.6
	game._register_hit_for_casulo(10)
	_check(game.casulo_reativo_timer > 0.0, "Casulo did not activate after 3 hits in window")
	_check(game._apply_casulo_damage_reduction(100) < 100, "Casulo did not reduce later damage")
	var first_timer: float = game.casulo_reativo_timer
	game._register_hit_for_casulo(10)
	_check(game.casulo_reativo_timer == first_timer, "Casulo reactivated while already active")

	game.passagem_intangivel_timer = 0.0
	game._execute_teleport(game.player_pos + Vector2(120, 0))
	_check(game.passagem_intangivel_timer > 0.0, "Passagem did not activate on teleport")
	_check(game._passagem_blocks_contact_damage(game.ENEMY_COMMON), "Passagem did not block contact damage")
	_check(not game._passagem_blocks_contact_damage("frost_shard"), "Passagem blocked projectile/area damage")

	game.ancora_vital_state.clear()
	game._create_ancora_vital(100, game.player_pos)
	_check(not game.ancora_vital_state.is_empty(), "Ancora was not created after damage")
	game.player_hp = 600
	game._update_ancora_vital(1.0)
	_check(game.player_hp > 600, "Ancora did not heal inside its radius")
	var previous_remaining: float = float(game.ancora_vital_state.get("remaining", 0.0))
	game._create_ancora_vital(80, game.player_pos + Vector2(40, 0))
	_check(float(game.ancora_vital_state.get("remaining", 0.0)) != previous_remaining, "Ancora did not replace the previous anchor")

	game._reset_card_proc_state()
	_check(game.cinzas_burn_marks.is_empty(), "reset did not clear Cinzas marks")
	_check(game.reserva_pulso_stored == 0.0, "reset did not clear Reserva")
	_check(game.casulo_reativo_timer == 0.0 and game.casulo_hit_times.is_empty(), "reset did not clear Casulo")
	_check(game.passagem_intangivel_timer == 0.0, "reset did not clear Passagem")
	_check(game.ancora_vital_state.is_empty(), "reset did not clear Ancora")

	print("SUPPORT_CARDS_SMOKE_OK cards=6 common=true unlimited=true sprites=true tregua=true cinzas=true reserva=true casulo=true passagem=true ancora=true reset=true")
	quit(0)
