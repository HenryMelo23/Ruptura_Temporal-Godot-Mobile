extends SceneTree

## A loja manual foi aposentada: sem opcao nas configuracoes, sem botao no HUD e
## sem caminho para desligar a loja automatica/Fenda do Mercador.

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("MANUAL_SHOP_REMOVED_FAIL " + message)
	quit(1)


func _run() -> void:
	var viewport := Vector2(1280, 720)
	game.qa_data_unlocked = false
	game.forced_initial_phase = 0
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.qa_data_unlocked = false
	game.forced_initial_phase = 0
	var keys: Array = game._gameplay_preference_keys()
	_check(not keys.has("shop_mode") and not keys.has("shop_interval"), "shop options still in settings")
	game._update_button_layout(viewport)
	_check(not game.buttons.has("shop_manual"), "manual shop button visible in normal run")
	game._try_open_manual_shop()
	_check(game.mode == "game", "manual shop opened without QA access")
	game._open_edit_layout(viewport)
	game._update_button_layout(viewport)
	_check(not game.buttons.has("shop_manual"), "manual shop button editable in layout editor")
	game.mode = "game"
	_check(game.shop_auto_enabled, "automatic shop was disabled")
	_check(game.shop_rift_controller.enabled(), "merchant rift disabled in solo run")
	print("MANUAL_SHOP_REMOVED_OK settings=false hud=false edit_layout=false rift=true")
	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	quit(0)
