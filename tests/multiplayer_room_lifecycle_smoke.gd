extends SceneTree

const PREFIX := "res://tests/room_lifecycle_"
const ERROR_FILE := PREFIX + "error.txt"

var game: Node
var role := ""
var host := "127.0.0.1"
var port := 4591
var manager_room := false


func _initialize() -> void:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with("--role="):
			role = arg.substr("--role=".length())
		elif arg.begins_with("--host="):
			host = arg.substr("--host=".length())
		elif arg.begins_with("--port="):
			port = int(arg.substr("--port=".length()))
		elif arg == "--manager-room":
			manager_room = true
	if not role in ["server", "host", "client"]:
		_fail("invalid role")
		return
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_start")


func _start() -> void:
	if role == "server":
		game.dedicated_room_code = "LIFECYCLE"
		game._start_dedicated_room_server(port)
		_run_server()
	elif role == "host":
		game.player_nickname = "LifecycleHost"
		game.is_multiplayer = true
		game.online_room_owner = true
		game.mode = "lobby_online_host"
		game._connect_to_online_host(host, port)
		_run_host()
	else:
		game.player_nickname = "LifecycleClient"
		game.is_multiplayer = true
		game.online_room_owner = false
		game.mode = "lobby_online_client"
		game._connect_to_online_host(host, port)
		_run_client()


func _run_server() -> void:
	var deadline := Time.get_ticks_msec() + 15000
	var ready_written := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if not ready_written and game.dedicated_room_owner_peer_id != 0 and game._mp_peer_ids().size() == 2:
			_write("server_ready", "OK")
			ready_written = true
		if game.dedicated_room_shutdown_pending:
			_write("server_result", "OK")
			return
	_fail("server did not shut down after owner disconnect")


func _run_host() -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var server_ready := FileAccess.file_exists(PREFIX + "server_ready.txt")
		if manager_room:
			server_ready = game.online_lobby_connected_count == 2
		if game.online_connected and server_ready:
			_write("host_result", "OK")
			game._leave_multiplayer()
			await create_timer(0.3).timeout
			quit(0)
			return
	_fail("host never reached connected lifecycle state")


func _run_client() -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if game.mode == "multiplayer_menu" and game.multiplayer_notice == "O HOST SAIU. A SALA FOI ENCERRADA.":
			_write("client_result", "OK")
			quit(0)
			return
	_fail("client did not return to multiplayer menu with owner disconnect reason")


func _write(name: String, value: String) -> void:
	var file := FileAccess.open(PREFIX + name + ".txt", FileAccess.WRITE)
	if file:
		file.store_string(value)
		file.close()


func _fail(message: String) -> void:
	var error := "[%s] %s" % [role.to_upper(), message]
	push_error(error)
	_write("error", error)
	quit(1)
