extends SceneTree

const OUTPUT_DIR := "res://.codex/drop_journey_mode"

var game: Node


func _initialize() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("DROP_JOURNEY_MODE_VISUAL_FAIL " + message)
	quit(1)


func _capture(filename: String) -> void:
	game.buttons.clear()
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_size() == Vector2i(1280, 720), "invalid capture " + filename)
	var path := ProjectSettings.globalize_path(OUTPUT_DIR.path_join(filename))
	_check(image.save_png(path) == OK, "could not save " + filename)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	game._finish_startup_thanks()
	game.vol_master = 0.0
	game.ui_platform_override = "desktop"
	game.ui_platform_override_unlocked = true
	game.player_nickname = "GEOVANA"
	game.henry_cheat_unlocked = true
	game.mode = "character_select"
	game.character_select_index = 0
	game._set_run_mode_local(game.RUN_MODE_DROP)
	await _capture("solo_character_and_mode_1280x720.png")
	_check(game.buttons.has("journey_mode_shop") and game.buttons.has("journey_mode_drop"), "solo mode buttons missing")

	game.mode = "lobby_online_host"
	game.online_connected = true
	game.online_room_owner = true
	game.online_room_code = "DROP35"
	game.online_room_name = "Ruptura sem Loja"
	game.online_lobby_connected_count = 3
	game.online_lobby_active_player_count = 3
	game.online_lobby_ready_count = 2
	game.online_lobby_roster = [
		{"peer_id": 1, "name": "GEOVANA", "owner": true, "slot": 1, "ready": true, "spectator": false},
		{"peer_id": 42, "name": "HENRY", "owner": false, "slot": 2, "ready": true, "spectator": false},
		{"peer_id": 43, "name": "NORA", "owner": false, "slot": 3, "ready": true, "spectator": false},
	]
	game.run_mode_popup_selection = 1
	game.run_mode_popup_open = true
	await _capture("multiplayer_host_mode_popup_1280x720.png")
	_check(game.buttons.has("lobby_mode_shop") and game.buttons.has("lobby_mode_drop"), "host popup choices missing")

	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = true
	game.online_lobby_active_player_count = 3
	game._set_run_mode_local(game.RUN_MODE_DROP)
	game.player_pos = Vector2(640.0, 360.0)
	game.arauto_card_drops.clear()
	game.online_lobby_roster = [
		{"peer_id": 1, "name": "GEOVANA", "slot": 1},
		{"peer_id": 42, "name": "HENRY", "slot": 2},
		{"peer_id": 43, "name": "NORA", "slot": 3},
	]
	var cards := [game.CARDS[0], game.CARDS[1], game.CARDS[2]]
	var owners := [1, 42, 43]
	var positions := [Vector2(520.0, 330.0), Vector2(690.0, 285.0), Vector2(790.0, 430.0)]
	var lives := [5.0, 1.25, 0.42]
	for index in range(3):
		var identity: Dictionary = game._drop_mode().owner_identity(owners[index])
		game._append_owned_card_drop(cards[index], positions[index], 0.0, owners[index], lives[index], 0.0, 0.0, 0.0, 0.0, {
			"drop_mode": true,
			"owner_name": identity["name"],
			"owner_color": identity["color"],
			"max_life": 5.0,
		})
		game.arauto_card_drops.back()["age"] = 1.7 + index * 0.2
	await _capture("gameplay_owned_cards_and_expiry_1280x720.png")

	print("DROP_JOURNEY_MODE_VISUAL_OK solo_selector=true host_popup=true owner_names=true arrows=true expiry_states=true output=%s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	await process_frame
	quit(0)
