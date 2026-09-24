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
	game.hud_shop_pos = Vector2(-1, -1)
	game._open_edit_layout(viewport)
	game._update_button_layout(viewport)
	_check(game.buttons.has("shop_manual"), "shop button must be editable even when automatic shop is enabled")

	var start_pos: Vector2 = game._manual_shop_pos(viewport)
	var drag_to := start_pos + Vector2(-130, 70)
	game._handle_edit_layout_press(-2, start_pos + Vector2(52, 21), viewport)
	_check(game.edit_layout_selected == "shop_manual", "shop button did not become the selected layout item")
	game._handle_edit_layout_drag(-2, drag_to + Vector2(52, 21), viewport)
	game._handle_edit_layout_release(-2, drag_to + Vector2(52, 21), viewport)
	_check(game.hud_shop_pos.distance_to(drag_to) < 0.1, "shop button did not persist dragged position")
	_check(game._manual_shop_pos(viewport).distance_to(drag_to) < 0.1, "manual shop position did not use saved HUD position")

	print("SHOP_BUTTON_LAYOUT_SMOKE_OK editable_when_auto=true moved=true")
	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	quit(0)
