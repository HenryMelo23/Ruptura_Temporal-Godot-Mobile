extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _card(name: String) -> Dictionary:
	for card in game.CARDS:
		if card["name"] == name:
			return card
	return {}


func _spawn_static_enemy(hp := 100.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(800, 450))
	var enemy = game.enemies.back()
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["speed"] = 0.0
	return enemy


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game._apply_card(_card("Mercenaria"))
	for i in range(5):
		game._kill_enemy(_spawn_static_enemy())
	_check(game.combo_kills == 5, "Mercenaria did not preserve the five-kill contract")
	_check(game.mercenary_bonus_points == 65, "first contract should add base 25 plus 40 per card")
	var score_before = game.score
	var expected_base = game._points_for_enemy(_spawn_static_enemy())
	var sixth = game.enemies.back()
	game._kill_enemy(sixth)
	_check(game.score - score_before == expected_base + 65, "current Mercenaria bonus was not paid on the next kill")
	game.enemies.clear()
	game.spawn_timer = 999.0
	game.boss_dead = true
	game._update_game(5.0)
	_check(game.combo_kills == 6, "Mercenaria combo incorrectly expired with time")
	game._damage_player(10, "test")
	_check(game.combo_kills == 0 and game.mercenary_bonus_points == 0, "taking damage did not break Mercenaria contract")

	game._apply_card(_card("Coletora"))
	_check(is_equal_approx(game.execute_threshold, 0.058), "first Coletora card should activate 5.8 percent execution")
	var target = _spawn_static_enemy(1000.0)
	target["hp"] = 59.0
	game._damage_enemy(target, 2.0, "eletrica")
	_check(float(target["hp"]) <= 0.0, "Coletora did not execute a common enemy below threshold")
	_check(is_equal_approx(game._boss_execute_threshold(), 0.0116), "boss execution should use 20 percent of common threshold")
	game.current_phase = 2
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 10000.0
	game.boss_hp = 115.0
	game._damage_boss(1.0, "eletrica")
	_check(game.boss_dead, "Coletora did not execute boss inside its reduced threshold")

	print("MERCENARIA_COLETORA_SMOKE_OK persistent_contract=true reset_on_damage=true common=5.8 boss=1.16")
	quit(0)
