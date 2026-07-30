extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("END_SCREEN_NO_EXIT_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	var viewport := Vector2(1280, 720)

	game.mode = "game_over"
	game.gameover_selected = 2
	game.queue_redraw()
	await process_frame
	var game_over_buttons: Dictionary = game._game_over_button_layout(viewport)
	_check(game_over_buttons.has("end_retry"), "game over retry button missing")
	_check(game_over_buttons.has("end_ranking"), "game over ranking button missing")
	_check(game_over_buttons.has("end_menu"), "game over menu button missing")
	_check(not game_over_buttons.has("end_exit"), "game over exit button should not exist")
	_check(not game.buttons.has("end_exit"), "game over exit hitbox should not remain")

	game.gameover_selected = 2
	var key_down := InputEventKey.new()
	key_down.pressed = true
	key_down.keycode = KEY_DOWN
	game._handle_key(key_down)
	_check(game.gameover_selected == 0, "game over keyboard selection should wrap across three buttons")

	game.mode = "victory"
	game.queue_redraw()
	await process_frame
	_check(game.buttons.has("end_ranking"), "victory ranking button missing")
	_check(game.buttons.has("end_menu"), "victory menu button missing")
	_check(not game.buttons.has("end_exit"), "victory exit hitbox should not remain")

	root.remove_child(game)
	game.queue_free()
	for i in range(4):
		await process_frame
	print("END_SCREEN_NO_EXIT_SMOKE_OK game_over=true victory=true no_exit=true")
	quit(0)
