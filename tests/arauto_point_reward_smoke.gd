extends SceneTree

var game: Node
var failed := false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("ARAUTO_POINT_REWARD_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	game.current_phase = 1
	game.mode = "game"
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game.enemies.clear()
	game._spawn_arauto()
	_check(game._arauto_active(), "Arauto fixture did not spawn")

	var expected_points: int = RTSupremeEnemyRewards.points_for("arauto", int(game.card_cost))
	var score_before: int = int(game.score)
	game.arauto["entry_timer"] = 0.0
	game.arauto["hp"] = 1.0
	game._damage_arauto(99999.0, "reward_smoke", false)

	_check(not game._arauto_active(), "Arauto did not finish")
	_check(game.score - score_before == expected_points, "Arauto did not credit its supreme point reward")
	_check(game.arauto_card_drops.is_empty(), "Arauto still drops cards")

	if failed:
		_cleanup()
		quit(1)
		return
	print("ARAUTO_POINT_REWARD_SMOKE_OK points=%d cards=%d" % [expected_points, game.arauto_card_drops.size()])
	_cleanup()
	quit(0)


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	if game.get_parent() == root:
		root.remove_child(game)
	game.free()
