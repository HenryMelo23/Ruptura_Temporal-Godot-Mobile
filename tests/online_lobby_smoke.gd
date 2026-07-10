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
	# 1. Simular Host Online Criando Sala
	game._create_online_room()
	_check(game.is_multiplayer == true, "Host online deve marcar is_multiplayer como true")
	_check(game.is_host == false, "Host online usa P2P emulado, entao is_host deve ser false")
	_check(game.online_room_owner == true, "Dono da sala online deve ter online_room_owner = true")
	_check(game.mode == "lobby_online_host", "Dono da sala online deve ir para o modo lobby_online_host")

	# 2. Simular Client Online Entrando na Sala
	game._join_online_room()
	_check(game.is_multiplayer == true, "Client online deve marcar is_multiplayer como true")
	_check(game.is_host == false, "Client online deve ter is_host como false")
	_check(game.online_room_owner == false, "Client online nao e dono da sala, online_room_owner deve ser false")
	_check(game.mode == "lobby_online_client", "Client online deve ir para o modo lobby_online_client")

	# 3. Simular recebimento do estado do lobby online
	game._online_lobby_state("ABCDEF", 2, 1)
	_check(game.online_room_code == "ABCDEF", "Codigo da sala deve ser atualizado")
	_check(game.online_lobby_connected_count == 2, "Contagem de conexoes deve ser 2")
	_check(game.online_lobby_ready_count == 1, "Contagem de prontos deve ser 1")
	_check(game.online_room_owner == false, "O recebimento de online_lobby_state nao deve resetar online_room_owner")

	await _finish_ok("ONLINE_LOBBY_SMOKE_OK - Host/Client states validated successfully")
