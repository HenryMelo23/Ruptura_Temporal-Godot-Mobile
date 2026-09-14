extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("LONG_RUN_ECONOMY_SMOKE_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()
	game.time_alive = 50.0 * 60.0
	game.shop_auto_elapsed = game.time_alive
	var enemy := {"points": 20, "elite": false}
	var points: int = game._points_for_enemy(enemy)
	_check(game._long_run_point_multiplier() >= 12.0, "50 minute point multiplier too low")
	_check(points >= 240, "50 minute enemy reward too low")
	var discount: float = game._shop_endurance_discount_from_elapsed(game.time_alive)
	_check(discount >= 0.50, "50 minute shop endurance discount too low")
	print("LONG_RUN_ECONOMY_SMOKE_OK points=%d mult=%.2f discount=%.2f" % [points, game._long_run_point_multiplier(), discount])
	quit(0)
