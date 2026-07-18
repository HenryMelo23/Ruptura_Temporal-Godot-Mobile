extends SceneTree

const TIMEOUT_MS := 30000

var game: Node
var role := ""
var scenario := "ready"
var relay_host := "127.0.0.1"
var port := 4591
var external_server := false
var started_ms := 0
var action_sent := false
var server_state_valid := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):
			role = arg.trim_prefix("--role=")
		elif arg.begins_with("--scenario="):
			scenario = arg.trim_prefix("--scenario=")
		elif arg.begins_with("--port="):
			port = int(arg.trim_prefix("--port="))
		elif arg.begins_with("--host="):
			relay_host = arg.trim_prefix("--host=")
		elif arg == "--external-server":
			external_server = true
	if role not in ["server", "host", "client"] or scenario not in ["ready", "spectator"]:
		_fail("invalid arguments")
		return
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	started_ms = Time.get_ticks_msec()
	call_deferred("_start_role")


func _start_role() -> void:
	if role == "server":
		game.dedicated_room_code = "LOBBY_TEST"
		game._start_dedicated_room_server(port)
	else:
		game.player_nickname = role.to_upper() + "_" + scenario.to_upper()
		game.online_room_owner = role == "host"
		game.mode = "lobby_online_host" if role == "host" else "lobby_online_client"
		game._connect_to_online_host(relay_host, port)
	call_deferred("_run")


func _run() -> void:
	while Time.get_ticks_msec() - started_ms < TIMEOUT_MS:
		await process_frame
		if role == "client":
			_run_client_step()
		elif role == "host":
			_run_host_step()
		else:
			_run_server_step()
		var external_results_ready := external_server and _result_exists("host") and _result_exists("client")
		if _result_exists(role) and (external_results_ready or role == "server" or _result_exists("server")):
			await _finish()
			return
	_fail("timeout scenario=%s role=%s state=%s" % [scenario, role, _state_summary()])


func _run_client_step() -> void:
	if not game.online_connected:
		return
	if not action_sent:
		action_sent = true
		if scenario == "spectator":
			game._toggle_online_spectator_mode()
		else:
			game._set_lobby_ready(true)
	if scenario == "ready":
		if game.local_player_ready and game.online_local_ready_confirmed and not game.online_lobby_ready_pending:
			_write_result(role)
	else:
		if game.online_local_spectator and game.online_local_spectator_confirmed and not game.online_spectator_request_pending and game.online_lobby_active_player_count == 1 and game.online_lobby_spectator_count == 1:
			_write_result(role)


func _run_host_step() -> void:
	if not game.online_connected or game.online_lobby_connected_count != 2:
		return
	if scenario == "ready":
		if game.online_lobby_active_player_count == 2 and game.online_lobby_ready_count == 1 and game.online_lobby_client_ready and game._online_client_ready():
			_write_result(role)
	else:
		if game.online_lobby_active_player_count == 1 and game.online_lobby_spectator_count == 1 and game._online_client_ready():
			_write_result(role)


func _run_server_step() -> void:
	if scenario == "ready":
		server_state_valid = game.dedicated_room_owner_peer_id != 0 and game._dedicated_active_peer_ids().size() == 2 and game._dedicated_clients_ready()
	else:
		server_state_valid = game.dedicated_room_owner_peer_id != 0 and game._dedicated_active_peer_ids().size() == 1 and game._dedicated_spectator_count() == 1
	if server_state_valid and _result_exists("host") and _result_exists("client"):
		_write_result(role)


func _result_path(result_role: String) -> String:
	return "res://tests/lobby_%s_%s_result.txt" % [scenario, result_role]


func _result_exists(result_role: String) -> bool:
	return FileAccess.file_exists(_result_path(result_role))


func _write_result(result_role: String) -> void:
	var file := FileAccess.open(_result_path(result_role), FileAccess.WRITE)
	if file == null:
		_fail("could not write result for " + result_role)
		return
	file.store_string("OK " + _state_summary())
	file.close()


func _state_summary() -> String:
	return "connected=%d active=%d spectators=%d ready=%d local_ready=%s spectator=%s" % [
		game.online_lobby_connected_count,
		game.online_lobby_active_player_count,
		game.online_lobby_spectator_count,
		game.online_lobby_ready_count,
		str(game.local_player_ready),
		str(game.online_local_spectator)
	]


func _finish() -> void:
	print("MULTIPLAYER_LOBBY_INTEGRATION_OK scenario=%s role=%s %s" % [scenario, role, _state_summary()])
	if is_instance_valid(game):
		game._cleanup_runtime_resources()
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
		root.remove_child(game)
		game.free()
		game = null
	for _frame in range(8):
		await process_frame
	quit(0)


func _fail(message: String) -> void:
	push_error("MULTIPLAYER_LOBBY_INTEGRATION_FAIL " + message)
	quit(1)
