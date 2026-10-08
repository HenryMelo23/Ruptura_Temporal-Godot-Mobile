extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
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
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game.current_phase = 3
	game.boss3_miasma_variant = 4
	game.boss3_miasma_timer = 5.0
	game.boss3_miasma_qte_required = 3
	game.boss3_miasma_qte_taps = 0
	var viewport := Vector2(1280, 720)
	_check(game._boss3_miasma_qte_active(), "eye-open QTE is not active on variant 4")
	game._handle_boss3_miasma_qte_tap(viewport * 0.5, viewport)
	_check(game.boss3_miasma_qte_taps == 1, "center QTE tap did not count as eye-open input")
	game._handle_boss3_miasma_qte_tap(Vector2(24, 24), viewport)
	_check(game.boss3_miasma_qte_taps == 1, "out-of-center QTE tap counted as input")
	print("PHASE3_DESKTOP_MIASMA_QTE_SMOKE_OK variant=4 center_tap=true")
	quit(0)
