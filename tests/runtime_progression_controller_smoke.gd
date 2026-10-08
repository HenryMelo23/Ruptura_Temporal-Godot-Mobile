extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("RUNTIME_PROGRESSION_CONTROLLER_SMOKE_FAIL " + message)
	_cleanup_runtime()
	quit(1)


func _card(card_id: String) -> Dictionary:
	for entry in game.CARDS:
		if game._card_id(entry) == card_id:
			return entry
	return {}


func _cleanup_runtime() -> void:
	if game == null:
		return
	game.mode = "menu"
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.visible = false
	game.set_process(false)
	game.set_physics_process(false)
	game._cleanup_runtime_resources()


func _free_game() -> void:
	if game == null:
		return
	root.remove_child(game)
	game.free()
	game = null


func _run() -> void:
	game._start_game()
	game.time_alive = 45.0 * 60.0
	var common_enemy := {"points": 20, "type": game.ENEMY_COMMON}
	var larapio_enemy := {"points": 20, "type": game.ENEMY_LARAPIO}
	_check(game._points_for_enemy(common_enemy) == 320, "common long-run reward changed")
	_check(game._elite_point_multiplier(larapio_enemy) > 1.0, "elite reward multiplier unavailable")

	game.score = 0
	game.score_total = 0
	game.run_points_earned = 0
	game.run_points_spent = 0
	game._apply_score_delta(100, false, "reward:1")
	game._apply_score_delta(100, false, "reward:1")
	game._apply_score_delta(-35, false, "spend:1")
	_check(game.score == 65, "score delta/dedup changed")
	_check(game.score_total == 65, "score total changed")
	_check(game.run_points_earned == 100, "earned points changed")
	_check(game.run_points_spent == 35, "spent points changed")

	var speed := _card("Speed Boost")
	var pacto := _card("pacto_possibilidades")
	_check(not speed.is_empty() and not pacto.is_empty(), "required cards missing")
	game.cards_bought.clear()
	game.cards_bought["pacto_possibilidades"] = 5
	game.card_cost = 500
	_check(game._card_count_by_id("pacto_possibilidades") == 5, "card count wrapper changed")
	_check(game._effective_card_price(speed) == 400, "common-card discount changed")
	game.cards_bought["moeda_estavel"] = 6
	_check(game._shop_price_increment_after_purchase() == 64, "shop price increment changed")
	_check(game._shop_endurance_discount_from_elapsed(50.0 * 60.0) >= 0.50, "long-run shop discount changed")

	print("RUNTIME_PROGRESSION_CONTROLLER_SMOKE_OK reward=%d score=%d price=%d" % [game._points_for_enemy(common_enemy), game.score, game._effective_card_price(speed)])
	_cleanup_runtime()
	for _i in range(4):
		await process_frame
	_free_game()
	await process_frame
	await process_frame
	quit(0)
