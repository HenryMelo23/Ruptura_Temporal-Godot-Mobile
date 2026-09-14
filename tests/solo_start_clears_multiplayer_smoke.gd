extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("SOLO_START_CLEARS_MULTIPLAYER_SMOKE_FAIL " + message)
	quit(1)


func _run() -> void:
	game.mode = "menu"
	game.is_multiplayer = true
	game.is_host = true
	game.online_connected = true
	game.online_room_owner = true
	game.local_player_ready = true
	game.net_player_ready = true
	game.shop_mp_request_timer = 1.0
	game.shop_mp_request_incoming = true
	game.boss_mp_request_timer = 1.0
	game.boss_mp_request_outgoing = true
	game.phase_mp_request_timer = 1.0
	game.phase_mp_request_incoming = true
	game._activate_menu_option("start")
	_check(not game.is_multiplayer, "solo start kept multiplayer flag")
	_check(not game.is_host, "solo start kept host flag")
	_check(not game.online_connected, "solo start kept online connection flag")
	_check(not game.online_room_owner, "solo start kept online owner flag")
	_check(not game.local_player_ready and not game.net_player_ready, "solo start kept lobby ready flags")
	_check(game.shop_mp_request_timer <= 0.0 and not game.shop_mp_request_incoming and not game.shop_mp_request_outgoing, "solo start kept shop vote state")
	_check(game.boss_mp_request_timer <= 0.0 and not game.boss_mp_request_incoming and not game.boss_mp_request_outgoing, "solo start kept boss vote state")
	_check(game.phase_mp_request_timer <= 0.0 and not game.phase_mp_request_incoming and not game.phase_mp_request_outgoing, "solo start kept phase vote state")
	print("SOLO_START_CLEARS_MULTIPLAYER_SMOKE_OK")
	quit(0)
