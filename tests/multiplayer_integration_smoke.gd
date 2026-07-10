extends SceneTree

var game: Node
var role: String = ""
var host: String = "127.0.0.1"
var port: int = 4590
var timer: float = 0.0
var step: int = 0
var manifest_reveal_requested: bool = false
var spectrum_ready_sent: bool = false


func _check(condition: bool, message: String) -> void:
	if not condition:
		var err_msg = "[%s] ERROR: %s" % [role.to_upper(), message]
		push_error(err_msg)
		var file = FileAccess.open("res://tests/integration_error.txt", FileAccess.WRITE)
		if file:
			file.store_string(err_msg)
			file.close()
		quit(1)


func _initialize() -> void:
	# Ler argumentos de linha de comando
	var args = OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with("--role="):
			role = arg.substr("--role=".length())
		elif arg.begins_with("--host="):
			host = arg.substr("--host=".length())
		elif arg.begins_with("--port="):
			port = int(arg.substr("--port=".length()))

	if role == "":
		push_error("Missing --role argument (server/host/client)")
		quit(1)
		return

	# Instanciar o jogo
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)

	# Chamar lógica conforme papel
	call_deferred("_start_role")


func _start_role() -> void:
	print("[%s] Starting role at port %d..." % [role.to_upper(), port])
	
	if role == "server":
		# Inicializar como servidor dedicado
		game.dedicated_room_code = "INTEGRATION_TEST"
		game._start_dedicated_room_server(port)
		# Monitorar status
		set_auto_accept_quit(false)
		_check(game.dedicated_server_mode == true, "Server mode should be dedicated")
		_check(game.mode == "dedicated_server", "Server mode should be dedicated_server")
		_run_server_loop()
	elif role == "host":
		# Inicializar como host online
		game.player_nickname = "HostPlayer"
		game.online_room_owner = true
		game.mode = "lobby_online_host"
		game._connect_to_online_host(host, port)
		_run_host_loop()
	elif role == "client":
		# Inicializar como client online
		game.player_nickname = "ClientPlayer"
		game.online_room_owner = false
		game.mode = "lobby_online_client"
		game._connect_to_online_host(host, port)
		_run_client_loop()


func _finish_ok(message: String) -> void:
	print("[%s] SUCCESS: %s" % [role.to_upper(), message])
	
	var file = FileAccess.open("res://tests/" + role + "_result.txt", FileAccess.WRITE)
	if file:
		file.store_string("OK")
		file.close()

	if is_instance_valid(game):
		_cleanup_audio_resources()
		root.remove_child(game)
		game.free()
		game = null
	# Pequeno tempo para fechar sockets de rede limpamente
	await create_timer(0.2).timeout
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


# Loop para o Dedicated Server
func _run_server_loop() -> void:
	var total_time = 0.0
	while true:
		await process_frame
		total_time += 0.016
		if total_time > 15.0:
			_check(false, "Timeout waiting for integration test steps")
			return
		
		# Validar que a partida foi iniciada pelo host
		if game.mode == "game":
			_finish_ok("Dedicated server successfully transitioned to game state")
			return


# Loop para o Host Online (Owner)
func _run_host_loop() -> void:
	var total_time = 0.0
	var requested_start = false
	while true:
		await process_frame
		total_time += 0.016
		if total_time > 15.0:
			_check(false, "Timeout waiting for game start")
			return

		# Simular clique do Host para iniciar quando o client estiver pronto
		if not requested_start and game.online_lobby_connected_count == 2 and game.online_lobby_ready_count >= 1:
			print("[HOST] Client is ready. Requesting start game...")
			requested_start = true
			game.rpc_id(1, "_host_request_start_game")

		# Manifestacao primeiro, espectro depois. So o espectro conta como pronto final.
		if game.mode == "manifest_mp" and game.manifest_select_stage == game.MANIFEST_STAGE_MANIFESTATION and not manifest_reveal_requested:
			print("[HOST] Manifest stage reached. Revealing spectrum...")
			manifest_reveal_requested = true
			game._set_selected_manifestation(1, false)
			game._confirm_manifest_mp_selection()
		elif game.mode == "manifest_mp" and game.manifest_select_stage == game.MANIFEST_STAGE_AURA and not spectrum_ready_sent:
			print("[HOST] Spectrum stage reached. Marking ready...")
			spectrum_ready_sent = true
			game._set_selected_aura(1, false)
			game._confirm_manifest_mp_selection()

		if game.mode == "game":
			_finish_ok("Host transitioned to game state successfully")
			return


# Loop para o Client Online
func _run_client_loop() -> void:
	var total_time = 0.0
	var marked_ready = false
	while true:
		await process_frame
		total_time += 0.016
		if total_time > 15.0:
			_check(false, "Timeout waiting for game start")
			return

		# Conectado e no lobby: marcar pronto
		if not marked_ready and game.online_connected and game.mode == "lobby_online_client":
			print("[CLIENT] Connected. Marking ready...")
			marked_ready = true
			game.local_player_ready = true
			game.rpc_id(1, "_toggle_ready", true)

		# Manifestacao primeiro, espectro depois. So o espectro conta como pronto final.
		if game.mode == "manifest_mp" and game.manifest_select_stage == game.MANIFEST_STAGE_MANIFESTATION and not manifest_reveal_requested:
			print("[CLIENT] Manifest stage reached. Revealing spectrum...")
			manifest_reveal_requested = true
			game._set_selected_manifestation(1, false)
			game._confirm_manifest_mp_selection()
		elif game.mode == "manifest_mp" and game.manifest_select_stage == game.MANIFEST_STAGE_AURA and not spectrum_ready_sent:
			print("[CLIENT] Spectrum stage reached. Marking ready...")
			spectrum_ready_sent = true
			game._set_selected_aura(1, false)
			game._confirm_manifest_mp_selection()

		if game.mode == "game":
			_finish_ok("Client transitioned to game state successfully")
			return
