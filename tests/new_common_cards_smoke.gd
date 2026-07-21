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


func _approx(value: float, expected: float, tolerance := 0.001) -> bool:
	return abs(value - expected) <= tolerance


func _run() -> void:
	game._start_game()

	var expected := {
		"escolha_adiada": 1,
		"inercia_cronal": 5,
		"leitura_instante": 4,
		"margem_segura": 4,
		"moeda_estavel": 6,
		"orbita_coletora": 5,
		"pacto_possibilidades": 5,
		"solo_consolidado": 4
	}
	for card_id in expected.keys():
		var card := _find_card(card_id)
		assert(not card.is_empty())
		assert(not game._is_rare_card(card))
		assert(game._card_max_count(card) == int(expected[card_id]))
		assert(game.cards_bought.has(card_id))
		assert(game.textures.has("card_" + String(card["name"])))
		assert(game.textures["card_" + String(card["name"])] != null)
		assert(game.textures.has("card_" + String(card["name"]) + "_2"))
		assert(game.textures["card_" + String(card["name"]) + "_2"] != null)

	var margem := _find_card("margem_segura")
	for i in range(8):
		game._apply_card(margem)
	assert(game.cards_bought["margem_segura"] == 4)
	for roll in range(12):
		assert(not _has_card(game._roll_shop_cards(), "margem_segura"))

	game.cards_bought["escolha_adiada"] = 1
	var speed := _find_card("Speed Boost")
	game.shop_cards = [speed.duplicate(true)]
	game.card_cost = 500
	game._reserve_shop_card(0)
	assert(game._card_count_by_id("escolha_adiada") == 0)
	assert(game._shop_slot_locked(0))
	assert(game._effective_card_price(game.shop_cards[0]) == 500)
	game.card_cost = 900
	game.shop_cards = game._roll_shop_cards()
	assert(game._shop_slot_locked(0))
	assert(game._card_id(game.shop_cards[0]) == "Speed Boost")
	assert(game._effective_card_price(game.shop_cards[0]) == 500)
	game._reserve_shop_card(0)
	assert(not game._shop_slot_locked(0))

	game.card_cost = 500
	game.cards_bought["pacto_possibilidades"] = 5
	assert(game._effective_card_price(speed) == 400)
	assert(game._effective_card_price(_find_card("Trembo")) == 500)
	game.cards_bought["moeda_estavel"] = 6
	assert(game._shop_price_increment_after_purchase() == 64)

	game.cards_bought["inercia_cronal"] = 5
	assert(_approx(game._hostile_control_duration(1.0), 0.60))
	assert(_approx(game._hostile_knockback(Vector2(100, 0)).length(), 28.0))
	game.cards_bought["leitura_instante"] = 4
	assert(_approx(game._telegraph_window(1.0), 1.28))
	game.cards_bought["orbita_coletora"] = 5
	assert(_approx(game._neutral_pickup_radius(50.0), 105.0))
	game.cards_bought["solo_consolidado"] = 4
	assert(_approx(game._hostile_ground_hazard_duration(10.0), 6.8))
	game.cards_bought["margem_segura"] = 4
	assert(_approx(game._safe_spawn_distance_bonus(), 140.0))

	var attack: Dictionary = game._with_card_telegraph({"warn": 1.0, "duration": 2.0})
	assert(_approx(float(attack["warn"]), 1.28))
	assert(_approx(float(attack["duration"]), 2.28))

	print("NEW_COMMON_CARDS_SMOKE_OK cards=8 max=true reserve=true prices=true effects=true assets=true")
	quit(0)
