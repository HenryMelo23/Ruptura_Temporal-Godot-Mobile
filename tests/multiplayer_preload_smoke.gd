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
		game._cleanup_runtime_resources()
		game.textures.clear()
		game.audio_streams.clear()
		root.remove_child(game)
		game.free()
		game = null
	for i in range(4):
		await process_frame
	quit(0)


func _run() -> void:
	game.is_multiplayer = true
	game.online_connected = false
	game.online_room_owner = false
	game.local_player_ready = true
	game.online_lobby_ready_pending = true
	game._online_lobby_state_v2("ABC123", 2, 1, true)
	_check(game.local_player_ready, "lobby ack should keep the client ready")
	_check(not game.online_lobby_ready_pending, "lobby ack should clear the ready pending flag")
	_check(game.online_lobby_ready_count == 1, "host lobby should see one ready client")
	_check(game.net_player_ready, "one ready client should unlock the host start condition")

	game._start_multiplayer_preload()
	for i in range(8):
		await process_frame
	_check(game.mode == "multiplayer_preload", "preload should keep the preload mode while waiting for peers")
	_check(game.online_preload_local_ready, "local preload did not finish")
	_check(game.online_preload_progress >= 1.0, "preload progress did not reach 100 percent")

	game.online_connected = true
	game.online_room_owner = false
	game.dedicated_server_mode = false
	game._start_multiplayer_game()
	_check(game.mode == "multiplayer_syncing", "online replica should wait for the first world snapshot before gameplay")
	game._apply_remote_world_snapshot(PackedFloat32Array(), PackedFloat32Array([0.0, 0.0, 100.0, 0.0]), PackedFloat32Array())
	_check(game.mode == "game", "first world snapshot should release the client into gameplay")

	await _finish_ok("MULTIPLAYER_PRELOAD_SMOKE_OK")
