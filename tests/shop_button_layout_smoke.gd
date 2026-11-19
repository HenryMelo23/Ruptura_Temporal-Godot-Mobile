extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("SHOP_BUTTON_LAYOUT_FAIL " + message)
	quit(1)


func _run() -> void:
	var viewport := Vector2(1280, 720)
	game._start_game()
	game.shop_auto_enabled = true
	game.qa_data_unlocked = true
	game.forced_initial_phase = 3
	game.hud_shop_pos = Vector2(-1, -1)
	game._open_edit_layout(viewport)
	game._update_button_layout(viewport)
	_check(not game.buttons.has("shop_manual"), "QA shop shortcut returned to the layout editor")
	_check(game.edit_layout_selected != "shop_manual", "removed shop button remained selected")

	game.mode = "game"
	game._update_button_layout(viewport)
	_check(not game.buttons.has("shop_manual"), "QA shop shortcut returned to the combat HUD")

	print("SHOP_BUTTON_LAYOUT_SMOKE_OK qa_hidden=true hud_hidden=true")
	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	quit(0)
