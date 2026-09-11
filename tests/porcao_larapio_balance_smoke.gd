extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _expect(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("PORCAO_LARAPIO_BALANCE_SMOKE_FAIL " + message)
	quit(1)


func _card(name: String) -> Dictionary:
	for card in game.CARDS:
		if String(card.get("name", "")) == name:
			return card
	return {}


func _run() -> void:
	game._start_game()

	var porcao := _card("Porcao")
	_expect(not porcao.is_empty(), "porcao_card_missing")
	game.player_hp_max = 1000
	game.player_hp = 400
	game.cards_bought.clear()
	game._apply_card(porcao)
	_expect(game.player_hp_max == 1450, "porcao_max_hp_gain_wrong")
	_expect(game.player_hp == 450, "porcao_heal_should_use_old_max_hp")

	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_LARAPIO, game.player_pos + Vector2(120, 0))
	var larapio: Dictionary = game.enemies[0]
	larapio["hp"] = float(larapio["max_hp"]) * 0.55
	larapio["larapio_ult_cd"] = 0.0
	larapio["larapio_ult_timer"] = 0.0
	game._update_larapio(larapio, 0.25)
	_expect(float(larapio.get("larapio_ult_timer", 0.0)) > 0.0, "larapio_ultimate_not_started")
	_expect(is_equal_approx(float(larapio.get("larapio_ult_cd", 0.0)), game.LARAPIO_ULTIMATE_DURATION + game.LARAPIO_ULTIMATE_COOLDOWN), "larapio_ultimate_cooldown_should_be_60s_after_duration")

	print("PORCAO_LARAPIO_BALANCE_SMOKE_OK porcao_hp=1450 heal=50 larapio_portal_cd=60s")
	quit(0)
