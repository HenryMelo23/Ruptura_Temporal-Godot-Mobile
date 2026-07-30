extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _expect(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("CARDS_UNLIMITED_SMOKE_FAIL " + message)
	quit(1)


func _card(card_id: String) -> Dictionary:
	for card in game.CARDS:
		if game._card_id(card) == card_id:
			return card
	return {}


func _run() -> void:
	game._start_game()

	for card in game.CARDS:
		var card_id: String = game._card_id(card)
		game.cards_bought[card_id] = game.CARD_UNLIMITED_COUNT + 10
		_expect(not game._card_at_max(card), "card_should_never_max_%s" % card_id)
		_expect(game._card_max_count(card) >= game.CARD_UNLIMITED_COUNT, "card_max_count_should_be_symbolic_%s" % card_id)

	game.cards_bought.clear()
	var porcao := _card("Porcao")
	_expect(not porcao.is_empty(), "porcao_missing")
	game.player_hp_max = 1000
	game.player_hp = 1000
	for i in range(3):
		var old_max: int = game.player_hp_max
		var old_hp: int = game.player_hp
		game._apply_card(porcao)
		var expected_max := old_max + int(round(float(old_max) * game.PORCAO_MAX_HP_GAIN_RATIO))
		var expected_hp := mini(expected_max, old_hp + int(round(float(old_max) * game.PORCAO_HEAL_OLD_MAX_RATIO)))
		_expect(game.player_hp_max == expected_max, "porcao_repeat_max_hp_wrong_%d" % i)
		_expect(game.player_hp == expected_hp, "porcao_repeat_heal_wrong_%d" % i)

	print("CARDS_UNLIMITED_SMOKE_OK cards=%d porcao_repeat=true" % game.CARDS.size())
	quit(0)
