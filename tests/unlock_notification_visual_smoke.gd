extends SceneTree

const OUTPUT := "res://.codex/unlock_notification_visual_1280x720.png"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("UNLOCK_NOTIFICATION_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	await process_frame
	game.startup_thanks_done = true
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	game.forced_initial_phase = 1
	game.force_phase6_start = false
	game._start_game()
	game.mode = "game"
	game.time_alive = 74.0
	game.score = 1680
	game.event_alert_timer = 0.0
	game.event_alert_text = ""
	game.effects.clear()

	var card: Dictionary = game._find_card_by_id("municao_de_rebate").duplicate(true)
	if card.is_empty():
		card = game.CARDS[2].duplicate(true)
	_check(not card.is_empty(), "sample card not found")

	game._queue_unlock_card_notification(card, "Eliminar 10/10 inimigos")
	_check(game.unlock_notifications.size() == 1, "notification was not queued")
	game.unlock_notifications[0]["age"] = 0.72
	game.unlock_notifications[0]["life"] = 5.28

	for i in range(8):
		game.queue_redraw()
		await process_frame

	_check(game.unlock_notifications.size() == 1, "notification expired too early")
	_check(String(game.unlock_notifications[0].get("challenge", "")) == "Eliminar 10/10 inimigos", "challenge text changed")

	if DisplayServer.get_name() != "headless":
		var viewport_texture: ViewportTexture = root.get_texture()
		var image: Image = viewport_texture.get_image()
		if image != null:
			if image.save_png(OUTPUT) != OK:
				push_error("UNLOCK_NOTIFICATION_VISUAL_FAIL could not save screenshot")
		image = null
		viewport_texture = null

	print("UNLOCK_NOTIFICATION_VISUAL_SMOKE_OK " + ProjectSettings.globalize_path(OUTPUT))
	root.remove_child(game)
	game.queue_free()
	for i in range(4):
		await process_frame
	quit(0)
