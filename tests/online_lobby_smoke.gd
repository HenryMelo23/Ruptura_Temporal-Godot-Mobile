extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _finish_ok(message: String) -> void:
	print(message)
	if is_instance_valid(game):
		_cleanup_audio_resources()
		root.remove_child(game)
		game.free()
		game = null
	await process_frame
	quit(0)


func _cleanup_audio_resources() -> void:
	if game.music_player != null:
		game.music_player.stop()
		game.music_player.stream = null
	if game.rain_audio_player != null:
		game.rain_audio_player.stop()
		game.rain_audio_player.stream = null
	for player in game.sfx_players:
		if player != null:
			player.stop()
			player.stream = null
	game.audio_streams.clear()
	game.textures.clear()


func _run() -> void:
	_check(game.MULTIPLAYER_MENU_ENABLED, "Multiplayer option should be enabled")
	_check(game._menu_rects(Vector2(1280, 720)).has("multiplayer"), "Hub should expose the multiplayer button")
	game._activate_menu_option("multiplayer")
	_check(game.mode == "multiplayer_menu", "Multiplayer button should open online hub")

	game.online_relay_request = null
	game._host_multiplayer_game()
	_check(game.mode == "online_create_room", "Host flow should open create-room screen")
	game._join_multiplayer_game()
	_check(game.mode == "online_find_room", "Client flow should open find-room screen")

	game._online_lobby_roster([
		{"peer_id": 21, "name": "HostQA", "owner": true, "ready": true, "spectator": false},
		{"peer_id": 22, "name": "ClientQA", "owner": false, "ready": false, "spectator": false}
	])
	_check(game.online_lobby_roster.size() == 2, "Lobby roster should be stored")
	game.player_nickname = "ClientQA"
	game.online_room_owner = false
	game.local_player_ready = true
	game.online_lobby_ready_pending = true
	game.online_ready_pending_started_ms = Time.get_ticks_msec()
	game._online_lobby_roster([
		{"peer_id": 21, "name": "HostQA", "owner": true, "ready": true, "spectator": false},
		{"peer_id": 22, "name": "ClientQA", "owner": false, "ready": true, "spectator": false}
	])
	_check(game.online_local_ready_confirmed and not game.online_lobby_ready_pending, "Local roster ready should clear confirming state")
	game.online_local_ready_confirmed = false
	game.local_player_ready = true
	game.online_lobby_ready_pending = true
	game.mode = "lobby_online_client"
	game.online_connected = true
	game.online_ready_pending_started_ms = Time.get_ticks_msec() - game.ONLINE_READY_PENDING_TIMEOUT_MS - 1
	game.online_ready_last_sent_ms = Time.get_ticks_msec() - game.ONLINE_READY_RESEND_INTERVAL_MS - 1
	game._update_lobby_ready_resend()
	_check(game.online_lobby_ready_pending and game.local_player_ready, "Ready soft timeout should resend without cancelling the pending request")
	_check(game.online_status == "REENVIANDO CONFIRMACAO AO HOST...", "Ready soft timeout should show resend status")
	game.local_player_ready = true
	game.online_local_ready_confirmed = false
	game.online_lobby_ready_pending = true
	game.online_ready_pending_started_ms = Time.get_ticks_msec() - game.ONLINE_READY_MAX_PENDING_MS - 1
	game._update_lobby_ready_resend()
	_check(not game.online_lobby_ready_pending and not game.local_player_ready, "Ready hard timeout should release the confirming button")

	game.online_connected = true
	game.online_room_owner = false
	game.local_player_ready = true
	game.online_lobby_ready_pending = true
	game.online_ready_request_seq = 2
	game.online_ready_confirmed_seq = 0
	game._online_lobby_ready_ack(1, true, true, "STALE1")
	_check(game.online_lobby_ready_pending, "Stale ready ack should not clear current confirmation")
	game._online_lobby_ready_ack(2, true, true, "ABCDEF")
	_check(game.online_local_ready_confirmed and not game.online_lobby_ready_pending, "Sequenced ready ack should confirm the latest request")
	game.online_room_owner = true
	game.online_lobby_connected_count = 2
	game.online_lobby_active_player_count = 2
	game.online_lobby_ready_count = 1
	game.online_start_request_seq = 4
	game.online_start_confirmed_seq = 0
	game.online_status = ""
	game._online_start_ack(3, true, "stale")
	_check(game.online_start_confirmed_seq == 0 and game.online_status == "", "Stale start ack should be ignored")
	game._online_start_ack(4, true, "preload")
	_check(game.online_start_confirmed_seq == 4 and game.online_status == "INICIO CONFIRMADO", "Latest start ack should confirm the match start")
	game.online_room_owner = false

	game.online_relay_action = "list"
	game._on_online_relay_request_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), JSON.stringify({
		"rooms": [{"code": "ABCDEF", "name": "Sala QA", "players": 1, "maxPlayers": 3, "locked": true}]
	}).to_utf8_buffer())
	_check(game.online_room_list.size() == 1, "Room list should parse public room metadata")
	_check(String(Dictionary(game.online_room_list[0]).get("name", "")) == "Sala QA", "Room name should be preserved")
	_check(bool(Dictionary(game.online_room_list[0]).get("locked", false)), "Locked room flag should be preserved")

	game._online_lobby_state("ABCDEF", 2, 1)
	_check(game.online_room_code == "ABCDEF", "Codigo da sala deve ser atualizado")
	_check(game.online_lobby_connected_count == 2, "Contagem de conexoes deve ser 2")
	_check(game.online_lobby_ready_count == 1, "Contagem de prontos deve ser 1")
	_check(game._online_client_ready(), "Fallback do lobby deve reconhecer client pronto pelo contador")
	_check(game.online_room_owner == false, "O recebimento de online_lobby_state nao deve resetar online_room_owner")

	game.local_player_ready = true
	game.online_local_ready_confirmed = false
	game._online_lobby_state_v2("ABCDEF", 2, 1, false, true)
	_check(game.online_lobby_client_ready == true, "Estado v2 deve marcar client pronto explicitamente")
	_check(game.online_local_ready_confirmed == true, "Client deve receber confirmacao autoritativa do pronto")
	game.online_room_owner = true
	game.online_lobby_client_ready = false
	game._online_lobby_state_v2("ABCDEF", 2, 1, false, true)
	_check(game._online_client_ready(), "Host deve reconhecer client pronto pelo estado v2")

	await _finish_ok("ONLINE_LOBBY_SMOKE_OK - online entry enabled, room metadata, roster, and lobby state parsing preserved")
