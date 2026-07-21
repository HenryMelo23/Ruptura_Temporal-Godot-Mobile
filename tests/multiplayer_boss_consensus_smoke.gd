extends SceneTree


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host_game = load("res://scenes/Main.tscn").instantiate()
	var client_game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(host_game)
	root.add_child(client_game)

	host_game.is_multiplayer = true
	host_game.online_room_owner = true
	host_game.is_host = true
	host_game.mode = "game"
	host_game.current_phase = 2
	host_game.boss_ready = true
	host_game.boss_active = false
	host_game.boss_dead = false
	host_game.boss_call_timer = -1.0

	host_game._start_boss_call()
	_check(host_game.mode == "game", "multiplayer boss call started without remote agreement")
	_check(host_game.boss_mp_request_outgoing, "host did not show outgoing boss call request")
	_check(host_game.boss_call_timer < 0.0, "boss countdown started before remote agreement")

	host_game._begin_boss_call_for_all()
	_check(host_game.mode == "boss_call", "host did not start boss call after agreement")
	_check(not host_game.boss_mp_request_outgoing, "boss call request overlay was not cleared on start")
	_check(host_game.boss_call_timer > 0.0, "boss call countdown was not scheduled after agreement")

	client_game.is_multiplayer = true
	client_game.online_room_owner = false
	client_game.mode = "game"
	client_game.current_phase = 1
	client_game.boss_ready = true
	client_game.boss_active = false
	client_game.boss_dead = false
	client_game.boss_call_timer = -1.0
	client_game._rpc_start_boss_call(2)
	_check(client_game.mode == "boss_call", "client did not mirror approved boss call")
	_check(client_game.current_phase == 2, "client did not mirror approved boss phase")
	_check(client_game.boss_call_timer > 0.0, "client did not schedule boss countdown")

	host_game.boss_pos = Vector2(440, 320)
	host_game.boss_active = true
	host_game.boss_hp = 900.0
	host_game.boss_hp_max = 1400.0
	host_game.boss_phase = 3.0
	client_game._apply_remote_boss_snapshot(host_game._pack_net_boss(), Time.get_ticks_msec())
	_check(client_game.boss_active, "client boss replica stayed inactive after host snapshot")
	_check(client_game.current_phase == 2, "client boss replica phase drifted after host snapshot")
	_check(is_equal_approx(client_game.boss_hp, 900.0), "client boss HP did not mirror host snapshot")
	_check(is_equal_approx(client_game.boss_hp_max, 1400.0), "client boss HP max did not mirror host snapshot")

	for game in [host_game, client_game]:
		game._cleanup_runtime_resources()
		game.textures.clear()
		game.audio_streams.clear()
		root.remove_child(game)
		game.free()
	for i in range(4):
		await process_frame
	print("MULTIPLAYER_BOSS_CONSENSUS_SMOKE_OK agreement=true replica=true")
	quit(0)
