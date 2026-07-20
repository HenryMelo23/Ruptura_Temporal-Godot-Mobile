extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("CONTRACTUAL_ORDER_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"
	game.manifestation_key = "contratual"
	game.player_pos = Vector2(640, 360)
	game.player_hp_max = 500
	game.player_hp = 500
	game.enemies = [
		{"uid": 1, "type": game.ENEMY_COMMON, "pos": game.player_pos + Vector2(80, 0), "hp": 120.0, "max_hp": 120.0, "speed": 80.0, "shoot_cd": 9.0}
	]
	_check(game._start_contractual_order(), "could not start judicial order")
	_check(not game.contractual_order.is_empty(), "order state was not created")
	_check(is_equal_approx(float(game.contractual_order.get("time_left", 0.0)), game.CONTRACT_ORDER_DURATION), "order did not start with the full execution time")
	_check(not bool(game.contractual_order.get("active", false)), "order execution started before reading phase")
	_check(game._contractual_order_world_time_scale() <= 1.0 and game._contractual_order_world_time_scale() > 0.0, "order did not start in slowdown phase")
	var found_visual := false
	for secondary in game.manifestation_secondaries:
		if String(secondary.get("kind", "")) == "contratual":
			found_visual = true
			break
	_check(found_visual, "opening secondary visual was not spawned")
	game._contractual_order_progress("break", 10, "aproximacao")
	_check(int(game.contractual_order.get("progress", 0)) == 0, "order counted progress before execution phase")
	game._update_contractual_order(game.CONTRACT_ORDER_SLOW_IN_TIME + game.CONTRACT_ORDER_REVEAL_TIME * 0.5)
	_check(not bool(game.contractual_order.get("active", false)), "order activated during reading phase")
	_check(is_equal_approx(float(game.contractual_order.get("time_left", 0.0)), game.CONTRACT_ORDER_DURATION), "reading phase consumed execution time")
	game._update_contractual_order(game.CONTRACT_ORDER_REVEAL_TIME * 0.5 + game.CONTRACT_ORDER_SLOW_OUT_TIME)
	_check(bool(game.contractual_order.get("active", false)), "order did not activate after the reading and return phases")
	_check(is_equal_approx(float(game.contractual_order.get("time_left", 0.0)), game.CONTRACT_ORDER_DURATION), "execution timer was consumed before the order became active")

	game.contractual_order = {"kind": "break", "goal": 2, "progress": 0, "time_left": 30.0, "age": 12.0, "real_age": 12.0, "active": true, "failed": false, "label": "Teste", "desc": "Teste"}
	game._contractual_order_progress("break", 2, "aproximacao")
	_check(game.contractual_order.is_empty(), "completed order did not clear state")
	_check(not game.contractual_order_rewards.is_empty(), "completed order did not grant a reward")

	game.contractual_order_rewards.clear()
	game.contractual_order_rewards["immortal"] = 5.0
	game.player_hp = 300
	game._damage_player(90, "test")
	_check(game.player_hp == 300, "immortality reward did not block damage")

	game.contractual_order_rewards.clear()
	game.contractual_order = {"kind": "survive", "goal": 10, "progress": 0, "time_left": 30.0, "age": 12.0, "real_age": 12.0, "active": true, "failed": false, "label": "Teste", "desc": "Teste"}
	game._damage_player(10, "test")
	game._update_contractual_order(0.1)
	_check(game.contractual_order.is_empty(), "failed no-damage order did not clear state")
	_check(not game.contractual_order_penalties.is_empty(), "failed order did not apply confiscation")

	print("CONTRACTUAL_ORDER_SMOKE_OK start=true reward=true immortal=true penalty=true")
	quit(0)
