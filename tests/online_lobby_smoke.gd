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
	_check(not game.MULTIPLAYER_MENU_ENABLED, "Multiplayer option should be disabled")
	_check(not game._menu_rects(Vector2(1280, 720)).has("multiplayer"), "Hub should not expose the multiplayer button")

	# 1. Garantir que atalhos/metodos online nao reativam multiplayer
	game._create_online_room()
	_check(game.is_multiplayer == false, "Host online removido nao deve marcar is_multiplayer")
	_check(game.online_room_owner == false, "Host online removido nao deve marcar dono da sala")
	_check(game.mode == "menu", "Host online removido deve voltar para o menu")

	# 2. Simular Client Online com multiplayer removido
	game._join_online_room()
	_check(game.is_multiplayer == false, "Client online removido nao deve marcar is_multiplayer")
	_check(game.is_host == false, "Client online removido deve manter is_host false")
	_check(game.online_room_owner == false, "Client online removido nao deve marcar dono da sala")
	_check(game.mode == "menu", "Client online removido deve voltar para o menu")

	# 3. Estado de lobby recebido isoladamente continua parseavel para compatibilidade interna
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

	await _finish_ok("ONLINE_LOBBY_SMOKE_OK - online entry disabled and lobby state parsing preserved")
