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


func _approx(value: float, expected: float, tolerance := 0.001) -> bool:
	return abs(value - expected) <= tolerance


func _run() -> void:
	game._start_game()

	var expected_ids := [
		"inercia_cronal",
		"moeda_estavel",
		"orbita_coletora",
		"pacto_possibilidades",
		"rastro_de_retorno",
		"municao_de_rebate",
		"impulso_de_sobras",
		"eco_de_impacto",
		"zona_de_descompressao",
		"folego_de_perseguicao",
		"margem_de_erro",
		"ressonancia_de_alternancia"
	]
	var uncommon_ids := [
		"moeda_estavel",
		"pacto_possibilidades",
		"rastro_de_retorno",
		"municao_de_rebate",
		"impulso_de_sobras",
		"eco_de_impacto",
		"zona_de_descompressao",
		"margem_de_erro",
		"ressonancia_de_alternancia",
		"ferrolho_ruptura",
	]
	for card_id in expected_ids:
		var card := _find_card(card_id)
		assert(not card.is_empty())
		if card_id in uncommon_ids:
			assert(game._is_uncommon_card(card))
			assert(not game._is_common_card(card))
		else:
			assert(game._is_common_card(card))
		assert(game._card_max_count(card) >= 999999)
		assert(game.cards_bought.has(card_id))
		assert(game._get_texture("card_" + String(card["name"])) != null)
		assert(game.textures.has("card_" + String(card["name"])))
		assert(game._get_texture("card_" + String(card["name"]) + "_2") != null)
		assert(game.textures.has("card_" + String(card["name"]) + "_2"))

	var speed := _find_card("Speed Boost")
	game.card_cost = 500
	game.cards_bought["pacto_possibilidades"] = 5
	assert(game._effective_card_price(speed) == 350)
	assert(game._effective_card_price(_find_card("Trembo")) == 500)
	game.cards_bought["moeda_estavel"] = 6
	assert(game._shop_price_increment_after_purchase() == 64)

	game.cards_bought["inercia_cronal"] = 5
	assert(_approx(game._hostile_control_duration(1.0), 0.60))
	assert(_approx(game._hostile_knockback(Vector2(100, 0)).length(), 28.0))
	game.cards_bought["orbita_coletora"] = 5
	assert(_approx(game._neutral_pickup_radius(50.0), 105.0))
	for retired_id in game.RETIRED_CARD_IDS:
		assert(_find_card(retired_id).is_empty())
		game.cards_bought[retired_id] = 8
		assert(game._card_count_by_id(retired_id) == 0)
	assert(_approx(game._telegraph_window(1.0), 1.0))
	assert(_approx(game._hostile_ground_hazard_duration(10.0), 10.0))
	assert(_approx(game._safe_spawn_distance_bonus(), 0.0))

	var attack: Dictionary = game._with_card_telegraph({"warn": 1.0, "duration": 2.0})
	assert(_approx(float(attack["warn"]), 1.0))
	assert(_approx(float(attack["duration"]), 2.0))

	game.cards_bought["rastro_de_retorno"] = 3
	assert(game._rastro_interval() < 12.0)
	assert(game._rastro_duration() > 6.0)
	game.cards_bought["municao_de_rebate"] = 5
	assert(game._rebate_chance() > 0.0)
	assert(game._rebate_search_radius() > 120.0)
	game.cards_bought["margem_de_erro"] = 4
	game.margem_window_timer = 1.0
	var mitigated: float = game._apply_margem_de_erro_damage(100.0, "smoke")
	assert(mitigated < 100.0)
	assert(game.margem_debt > 0.0)
	game.cards_bought["ressonancia_de_alternancia"] = 4
	game._record_ressonancia_action("ATTACK")
	game._record_ressonancia_action("Q", 8.0)
	game._record_ressonancia_action("E", 40.0)
	game._record_ressonancia_action("TELEPORT", 4.0)
	assert(game.ressonancia_ready_timer > 0.0)

	root.remove_child(game)
	game.queue_free()
	await process_frame
	await process_frame
	print("NEW_COMMON_CARDS_SMOKE_OK cards=16 uncommon=9 migrated=true unlimited=true retired=true prices=true effects=true assets=true")
	quit(0)
