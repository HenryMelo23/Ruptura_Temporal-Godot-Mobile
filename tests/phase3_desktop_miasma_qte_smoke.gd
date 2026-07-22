extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("PHASE3_DESKTOP_MIASMA_QTE_SMOKE_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game.current_phase = 3
	game.boss3_miasma_variant = 3
	game.boss3_miasma_timer = 5.0
	game.boss3_miasma_qte_required = 3
	game.boss3_miasma_qte_taps = 0
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	game._unhandled_input(event)
	_check(game.boss3_miasma_qte_taps == 1, "desktop space did not count as eye-open input")
	event.echo = true
	game._unhandled_input(event)
	_check(game.boss3_miasma_qte_taps == 1, "desktop repeated key echo counted as input")
	print("PHASE3_DESKTOP_MIASMA_QTE_SMOKE_OK space=true")
	quit(0)
