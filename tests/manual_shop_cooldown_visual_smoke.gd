extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless":
		return
	var path := "res://.codex/manual_shop_%s_%dx%d.png" % [label, root.size.x, root.size.y]
	var texture := root.get_texture()
	if texture == null:
		return
	var image := texture.get_image()
	if image == null:
		return
	assert(image.save_png(ProjectSettings.globalize_path(path)) == OK)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.codex"))
	game._start_game()
	game.set_process(false)
	game.run_tutorial_enabled = false
	game.shop_tutorial_seen = true
	game.shop_auto_enabled = false
	game.mode = "game"
	game.score = 2000
	game.card_cost = 500
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0

	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game.time_alive = 100.0
	game.shop_manual_cooldown_until = game.time_alive + 24.0
	game.shop_manual_grace_until = -999.0
	game.shop_manual_grace_reopen_available = false
	game._update_button_layout(Vector2(root.size))
	await _capture("cooldown")

	root.size = Vector2i(960, 540)
	root.content_scale_size = root.size
	game.time_alive = 200.0
	game.shop_manual_cooldown_until = game.time_alive + game.SHOP_MANUAL_REOPEN_COOLDOWN
	game.shop_manual_grace_until = game.time_alive + 4.0
	game.shop_manual_grace_reopen_available = true
	game.shop_manual_reopen_warning_text = "Fechou sem querer? Reabra em ate 5s sem perder pontos."
	game._update_button_layout(Vector2(root.size))
	await _capture("grace")

	assert(game._manual_shop_status_text() != "", "manual shop status text missing")
	print("MANUAL_SHOP_COOLDOWN_VISUAL_SMOKE_OK cooldown=true grace=true")
	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	quit(0)
