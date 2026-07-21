extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("APP_UPDATE_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.mode = "menu"
	var update_url: String = game.ONLINE_RELAY_BASE_URL + game._app_update_download_prefix() + ("Ruptura_Temporal_9.9.99.exe" if game._app_update_platform() == "windows" else "ruptura_temporal_mobile_9.9.99.apk")
	var payload := {
		"available": true,
		"version": "9.9.99",
		"version_code": int(game.GAME_VERSION_CODE) + 1,
		"size": 594065183,
		"sha256": "a".repeat(64),
		"notes": [
			"Novas mecanicas e balanceamento.",
			"Correcoes multiplayer e melhorias de estabilidade.",
			"Ranking e fichas de partida atualizados."
		],
		"mandatory": false,
		"filename": update_url.get_file()
	}
	payload[game._app_update_download_url_field()] = update_url
	game._apply_app_update_manifest(payload)
	var viewport := Vector2(1280, 720)
	var panel: Rect2 = game._app_update_panel_rect(viewport)
	var actions: Array[Rect2] = game._app_update_button_rects(viewport)
	_check(Rect2(Vector2.ZERO, viewport).encloses(panel), "panel escaped viewport")
	_check(actions.size() == 2 and panel.encloses(actions[0]) and panel.encloses(actions[1]), "actions escaped panel")
	game.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless":
		print("APP_UPDATE_VISUAL_OK headless_layout_only")
		quit(0)
		return
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == 1280 and image.get_height() == 720, "invalid capture")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output := "res://.codex/app_update_popup_1280x720.png"
	_check(image.save_png(output) == OK, "save failed")
	print("APP_UPDATE_VISUAL_OK " + ProjectSettings.globalize_path(output))
	quit(0)
