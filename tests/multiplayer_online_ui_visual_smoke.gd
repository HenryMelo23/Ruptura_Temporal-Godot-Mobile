extends SceneTree

const OUT_DIR := "res://.codex"

var game: Node
var captures: Array[String] = []


func _fail(message: String) -> void:
	push_error("MULTIPLAYER_ONLINE_UI_VISUAL_FAIL " + message)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.player_nickname = "Geovana"
	game.ui_platform_override = "desktop"
	game.ui_platform_override_unlocked = true
	game.online_relay_request = null
	game.online_heartbeat_request = null

	game.mode = "menu"
	game.online_mode_unlocked = false
	await _capture("online_menu_locked_1280x720.png")
	_check(not game._menu_rects(Vector2(1280, 720)).has("multiplayer"), "locked menu should not expose online")
	game.gameplay_cheat_text = "ONLINE30"
	_check(game._try_unlock_retornante_cheat(), "ONLINE30 did not unlock online")
	await _capture("online_menu_unlocked_1280x720.png")
	_check(game._menu_rects(Vector2(1280, 720)).has("multiplayer"), "unlocked menu should expose online")

	game.mode = "multiplayer_menu"
	game.multiplayer_notice = "ONLINE DISPONIVEL"
	await _capture("online_hub_1280x720.png")

	game.mode = "online_create_room"
	game.online_room_name = "D37 Ruptura Limpa"
	game.online_room_password = "d37"
	if game.online_room_name_edit != null:
		game.online_room_name_edit.text = game.online_room_name
	if game.online_room_password_edit != null:
		game.online_room_password_edit.text = game.online_room_password
	await _capture("online_create_room_1280x720.png")

	game.mode = "online_find_room"
	game.online_status = "ESCOLHA UMA SALA"
	game.online_room_list = [
		{"code": "A1B2C3", "name": "D37 Ruptura Limpa", "players": 1, "maxPlayers": 3, "locked": true},
		{"code": "FACE05", "name": "Fase 5 Teste", "players": 2, "maxPlayers": 3, "locked": false}
	]
	game.lobby_client_selected = 0
	game.online_join_code = "A1B2C3"
	game.online_join_password = "d37"
	if game.online_search_code_edit != null:
		game.online_search_code_edit.text = game.online_join_code
	if game.online_join_password_edit != null:
		game.online_join_password_edit.text = game.online_join_password
	await _capture("online_find_room_1280x720.png")

	game.mode = "lobby_online_host"
	game.online_status = "SALA PRONTA"
	game.online_connected = true
	game.online_room_owner = true
	game.online_room_code = "A1B2C3"
	game.online_room_name = "D37 Ruptura Limpa"
	game.online_room_locked = true
	game.online_lobby_connected_count = 3
	game.online_lobby_active_player_count = 2
	game.online_lobby_spectator_count = 1
	game.online_lobby_ready_count = 1
	game.online_lobby_roster = [
		{"peer_id": 11, "name": "Geovana", "owner": true, "ready": true, "spectator": false},
		{"peer_id": 22, "name": "Apolo", "owner": false, "ready": true, "spectator": false},
		{"peer_id": 33, "name": "Observador", "owner": false, "ready": true, "spectator": true}
	]
	await _capture("online_lobby_host_1280x720.png")

	game.mode = "manifest_mp"
	game.is_multiplayer = true
	game.online_connected = true
	game.online_lobby_connected_count = 3
	game.online_lobby_active_player_count = 3
	game.manifest_select_stage = game.MANIFEST_STAGE_AURA
	game.selected_manifestation = 2
	game.selected_aura = 3
	game.aura_scroll_pos = 3.0
	game.mp_local_ready = false
	game.mp_ready_last_sent_ms = Time.get_ticks_msec() + 60000
	game.mp_manifest_state_by_peer = {
		22: {"stage": game.MANIFEST_STAGE_AURA, "manifestation": 1, "aura": 2, "scroll": 2.0, "ready": true, "name": "Apolo"},
		33: {"stage": game.MANIFEST_STAGE_MANIFESTATION, "manifestation": 4, "aura": 0, "scroll": 4.0, "ready": false, "name": "Umbra"}
	}
	await _capture("online_manifest_team_1280x720.png")
	_check_button_inside("mp_manifest_ready", Vector2i(1280, 720))
	_check_button_inside("mp_manifest_start", Vector2i(1280, 720))
	await _capture("online_manifest_team_960x540.png", Vector2i(960, 540))
	_check_button_inside("mp_manifest_ready", Vector2i(960, 540))
	_check_button_inside("mp_manifest_start", Vector2i(960, 540))

	game.online_room_owner = true
	game.mp_local_ready = true
	game.mp_ready_last_sent_ms = Time.get_ticks_msec() + 60000
	game.mp_manifest_state_by_peer = {
		22: {"stage": game.MANIFEST_STAGE_AURA, "manifestation": 1, "aura": 2, "scroll": 2.0, "ready": true, "name": "Apolo"},
		33: {"stage": game.MANIFEST_STAGE_AURA, "manifestation": 4, "aura": 5, "scroll": 5.0, "ready": true, "name": "Umbra"}
	}
	await _capture("online_manifest_ready_host_start_1280x720.png")
	_check(game._manifest_mp_start_available(), "host start button did not unlock after all choices")

	game.mode = "game"
	game.is_multiplayer = true
	game.is_host = true
	game.is_dead = true
	game.player_hp = 0.0
	game.score = 410
	game.card_cost = 500
	game._clear_team_revival_state()
	game._start_team_revival_for_dead(game._mp_unique_id(), game.player_pos, "Geovana", false)
	await _capture("online_revive_dead_1280x720.png")
	_check(game.revival_active and game.revival_fragments.size() > 0, "revival fragments did not render for dead player")
	game.is_dead = false
	game.player_hp = game.player_hp_max
	for i in range(game.revival_fragments.size()):
		var fragment_state: Dictionary = game.revival_fragments[i]
		fragment_state["collected"] = true
		game.revival_fragments[i] = fragment_state
	game._refresh_revival_collection_state()
	game._activate_team_revival_altars()
	game.player_pos = game.revival_altar_life_pos
	await _capture("online_revive_altars_1280x720.png")
	_check(game.revival_altars_active and game._local_revival_altar_method() == game.REVIVE_PAY_LIFE, "revival altar prompt did not become available")

	print("MULTIPLAYER_ONLINE_UI_VISUAL_OK captures=", ", ".join(captures))
	game.queue_free()
	await process_frame
	quit(0)


func _capture(file_name: String, capture_size := Vector2i(1280, 720)) -> void:
	root.size = capture_size
	game.buttons.clear()
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == capture_size.x and image.get_height() == capture_size.y, "invalid capture " + file_name)
	_check(image.get_used_rect().size.x > int(float(capture_size.x) * 0.78) and image.get_used_rect().size.y > int(float(capture_size.y) * 0.78), "blank capture " + file_name)
	var output := OUT_DIR + "/" + file_name
	_check(image.save_png(output) == OK, "could not save " + file_name)
	captures.append(ProjectSettings.globalize_path(output))


func _check_button_inside(button_name: String, capture_size: Vector2i) -> void:
	_check(game.buttons.has(button_name), "missing button rect " + button_name)
	var rect: Rect2 = game.buttons[button_name]
	var logical_size: Vector2 = game.get_viewport_rect().size
	if logical_size.x <= 0.0 or logical_size.y <= 0.0:
		logical_size = Vector2(capture_size)
	var viewport_rect := Rect2(Vector2.ZERO, logical_size)
	_check(viewport_rect.encloses(rect), "button outside viewport %s rect=%s viewport=%s" % [button_name, str(rect), str(viewport_rect)])
