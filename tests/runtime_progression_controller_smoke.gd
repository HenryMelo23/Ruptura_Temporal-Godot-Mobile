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
	game.cards_bought.clear()
	game.luck = 0.0
	var temporal_samples := {}
	for minutes in [0, 30, 60, 90, 120]:
		game.time_alive = float(minutes) * 60.0
		temporal_samples[minutes] = game._temporal_luck()
	_check(is_zero_approx(float(temporal_samples[0])), "temporal luck did not start at zero")
	_check(absf(float(temporal_samples[60]) - 0.35) < 0.0001, "temporal luck did not reach 35 percent at 60 minutes")
	var gain_30_60 := float(temporal_samples[60]) - float(temporal_samples[30])
	var gain_60_90 := float(temporal_samples[90]) - float(temporal_samples[60])
	var gain_90_120 := float(temporal_samples[120]) - float(temporal_samples[90])
	_check(gain_30_60 > gain_60_90 and gain_60_90 > gain_90_120, "temporal luck did not diminish over equal time windows")
	game.time_alive = 24.0 * 60.0 * 60.0
	_check(game._temporal_luck() < 0.600001 and game._temporal_luck() > 0.59, "temporal luck did not approach its 60 percent ceiling")
	game.time_alive = 0.0
	var uncommon_at_start: float = game._chance_carta_incomum()
	game.time_alive = 60.0 * 60.0
	_check(game._chance_carta_incomum() > uncommon_at_start, "temporal luck did not improve uncommon items")
	_check(is_zero_approx(game._chance_carta_rara()), "temporal luck bypassed the Sorte rare gate")
	game.cards_bought["Sorte"] = 1
	game.luck = 0.003
	var rare_at_hour: float = game._chance_carta_rara()
	_check(absf(rare_at_hour - 0.07116) < 0.00001, "unlocked rare chance did not match the 60-minute contract")
	game.time_alive = 0.0
	_check(rare_at_hour > game._chance_carta_rara(), "temporal luck did not improve unlocked rare items")
	game.time_alive = 60.0 * 60.0
	_check(absf(game._effective_luck() - 0.353) < 0.0001, "card and temporal luck did not combine")
	game.current_phase = 2
	_check(absf(game._chance_carta_lendaria() - 0.01286) < 0.00001, "legendary chance did not match the 60-minute contract")
	var drop_weights: Array = game._progression().temporal_luck_controller.drop_mode_rarity_weights()
	_check(absf(float(drop_weights[1][1]) - 27.766) < 0.0001, "Drop journey uncommon weight did not match the temporal contract")
	_check(absf(float(drop_weights[2][1]) - 9.03) < 0.0001, "Drop journey rare weight did not match the temporal contract")
	_check(absf(float(drop_weights[3][1]) - 1.206) < 0.0001, "Drop journey legendary weight did not match the temporal contract")

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
	_check(game._effective_card_price(speed) == 350, "Pacto discount did not keep up with the shop curve")
	game.cards_bought["moeda_estavel"] = 6
	_check(game._shop_price_increment_after_purchase() == 64, "shop price increment changed")
	_check(game._shop_endurance_discount_from_elapsed(50.0 * 60.0) >= 0.50, "long-run shop discount changed")

	print("RUNTIME_PROGRESSION_CONTROLLER_SMOKE_OK reward=%d score=%d price=%d temporal_luck_60=%.2f diminishing=true rare_gate=true" % [game._points_for_enemy(common_enemy), game.score, game._effective_card_price(speed), float(temporal_samples[60])])
	_cleanup_runtime()
	for _i in range(4):
		await process_frame
	_free_game()
	await process_frame
	await process_frame
	quit(0)
