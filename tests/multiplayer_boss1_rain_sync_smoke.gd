extends SceneTree

var host: Node
var client: Node


func _initialize() -> void:
	host = load("res://scenes/Main.tscn").instantiate()
	client = load("res://scenes/Main.tscn").instantiate()
	root.add_child(host)
	root.add_child(client)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("MULTIPLAYER_BOSS1_RAIN_SYNC_FAIL " + message)
	quit(1)


func _cleanup_game(game: Node) -> void:
	if not is_instance_valid(game):
		return
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
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()


func _setup_multiplayer_peer(game: Node, host_mode: bool) -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = true
	game.online_connected = false
	game.is_host = host_mode
	game.online_room_owner = host_mode
	game.online_lobby_connected_count = 2
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 1000.0
	game.boss_hp = 260.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(180, 0)


func _run() -> void:
	_setup_multiplayer_peer(host, true)
	_setup_multiplayer_peer(client, false)
	host._start_boss1_rain()
	host.weather_rain_intro_timer = host.WEATHER_RAIN_FADE_TIME
	for i in range(20):
		host._update_environment_weather(1.0 / 30.0)
	_check(host.boss1_rain_active and host.weather_kind == "rain", "host rain did not start")
	_check(host.puddles.size() > 0, "host rain did not create puddles")
	var packet: Dictionary = host._pack_net_boss_visuals()
	_check(packet.has("weather"), "host packet omitted weather")
	client._apply_remote_boss_visual_snapshot(packet)
	_check(client.boss1_rain_active, "client did not apply rain active state")
	_check(client.weather_kind == "rain", "client did not apply rain kind")
	_check(client.puddles.size() == host.puddles.size(), "client did not receive puddles")
	for i in range(20):
		client._update_environment_weather(1.0 / 30.0)
	_check(client.raindrops.size() > 0 or client.rain_splashes.size() > 0, "client did not spawn rain effects")
	_check(client.rain_audio_player == null or client.rain_audio_player.playing or client.rain_audio_fade_mode == "in", "client rain audio did not start or fade in")

	host._clear_environment_weather(true)
	var clear_packet: Dictionary = host._pack_net_boss_visuals()
	client._apply_remote_boss_visual_snapshot(clear_packet)
	_check(not client.boss1_rain_active, "client rain did not clear")
	_check(client.weather_kind == "", "client weather kind did not clear")
	_check(client.puddles.is_empty() and client.raindrops.is_empty() and client.rain_splashes.is_empty(), "client weather particles did not clear")

	print("MULTIPLAYER_BOSS1_RAIN_SYNC_OK host=true client=true puddles=true drops=true clear=true")
	_cleanup_game(client)
	_cleanup_game(host)
	client = null
	host = null
	for i in range(4):
		await process_frame
	quit(0)
