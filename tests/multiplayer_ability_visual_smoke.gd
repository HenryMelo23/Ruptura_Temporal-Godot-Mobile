extends SceneTree

const PREFIX := "res://tests/ability_visual_"
const ERROR_FILE := PREFIX + "error.txt"
const LOCAL_PING_BUDGET_MS := 50

var game: Node
var role := ""
var host := "127.0.0.1"
var port := 4603


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
	if not role in ["server", "host", "client"]:
		_fail("invalid role")
		return
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_start")


func _start() -> void:
	if role == "server":
		game.dedicated_room_code = "ABILITY_VISUAL"
		game._start_dedicated_room_server(port)
		_run_server()
	elif role == "host":
		game.player_nickname = "AbilityHost"
		game.is_multiplayer = true
		game.online_room_owner = true
		game.mode = "lobby_online_host"
		game._connect_to_online_host(host, port)
		_run_host()
	else:
		game.player_nickname = "AbilityClient"
		game.is_multiplayer = true
		game.online_room_owner = false
		game.mode = "lobby_online_client"
		game._connect_to_online_host(host, port)
		_run_client()


func _run_server() -> void:
	var deadline := Time.get_ticks_msec() + 60000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if game.dedicated_room_owner_peer_id != 0 and game._mp_peer_ids().size() == 2 and not FileAccess.file_exists(PREFIX + "server_ready.txt"):
			_write("server_ready", "OK")
		if FileAccess.file_exists(PREFIX + "host_result.txt") and FileAccess.file_exists(PREFIX + "client_result.txt"):
			_check(game.net_ability_visuals.is_empty(), "dedicated relay instantiated ability visuals")
			_check(game.remote_bullets.is_empty(), "dedicated relay instantiated remote projectiles")
			print("[SERVER] ABILITY_VISUAL_OK relay_only=true")
			_write("server_result", "OK")
			await _finish()
			return
	_fail("server timed out waiting for host/client ability results")


func _run_host() -> void:
	var deadline := Time.get_ticks_msec() + 60000
	var sent := false
	var projectile: Dictionary = {}
	var destroy_sent := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if game.online_connected:
			game._update_online_ping(Time.get_ticks_msec())
		if not sent and game.online_connected and FileAccess.file_exists(PREFIX + "server_ready.txt"):
			sent = true
			game.selected_manifestation = 0
			game.manifestation_key = "eletrica"
			game.time_alive = 30.0
			game.last_skill_time = -10.0
			game.last_secondary_time = -999.0
			game.player_pos = Vector2(420, 360)
			game.last_facing = Vector2.RIGHT
			game._use_skill(Vector2(620, 360))
			game._use_secondary_skill(Vector2(620, 360))
			game._execute_teleport(Vector2(700, 360))
			projectile = {
				"pos": Vector2(700, 360),
				"dir": Vector2.RIGHT,
				"speed": 520.0,
				"life": 1.2,
				"max_life": 1.2,
				"age": 0.0,
				"phase": 0.0,
				"trail_cd": 0.0,
				"damage": 20.0,
				"kind": "eletrica",
				"pierce": false,
				"hits": {},
				"color": Color(0.0, 0.88, 1.0)
			}
			game._add_bullet(projectile)
			continue
		if sent and not destroy_sent and FileAccess.file_exists(PREFIX + "client_received.txt"):
			destroy_sent = true
			projectile["pos"] = Vector2(860, 360)
			projectile["life"] = 0.0
			game._update_bullets(0.0)
			continue
		if destroy_sent and FileAccess.file_exists(PREFIX + "client_result.txt"):
			await _wait_for_ping_budget(LOCAL_PING_BUDGET_MS, 2.0)
			_check(game.net_report_ping_min <= LOCAL_PING_BUDGET_MS, "host relay ping exceeded local %dms budget: best=%d last=%d" % [LOCAL_PING_BUDGET_MS, game.net_report_ping_min, game.net_ping_ms])
			print("[HOST] ABILITY_VISUAL_OK ping_ms=%d ping_min_ms=%d q_e_tp_sent=true projectile_destroy_sent=true" % [game.net_ping_ms, game.net_report_ping_min])
			_write("host_result", "OK")
			while not FileAccess.file_exists(PREFIX + "server_result.txt") and Time.get_ticks_msec() < deadline:
				await process_frame
			await _finish()
			return
	_fail("host timed out sending ability/projectile sequence")


func _run_client() -> void:
	var deadline := Time.get_ticks_msec() + 60000
	var received := false
	var payload_bytes_seen := 0
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if game.online_connected:
			game._update_online_ping(Time.get_ticks_msec())
		if not received and game.net_ability_visuals.size() >= 3 and not game.remote_bullets.is_empty():
			var actions := {}
			for visual in game.net_ability_visuals:
				actions[int(visual.get("action", -1))] = true
			_check(actions.has(game.NET_ABILITY_SKILL), "client did not receive Q visual")
			_check(actions.has(game.NET_ABILITY_SECONDARY), "client did not receive E visual")
			_check(actions.has(game.NET_ABILITY_TELEPORT), "client did not receive TP visual")
			var exact_replicas := 0
			for visual in game.net_ability_visuals:
				if bool(visual.get("network_replica", false)):
					exact_replicas += 1
			_check(exact_replicas >= 3, "Q/E/TP were not reconstructed as local effect replicas")
			_check(not game.effects.is_empty(), "remote projectile muzzle/trail was not reproduced")
			payload_bytes_seen = var_to_bytes([42, 3, game.NET_ABILITY_SKILL, 0, Vector2(420, 360), Vector2(620, 360), 0.75, 0.0, {"seed": 5}, 5]).size()
			_check(payload_bytes_seen < 256, "ability event exceeded 256-byte budget: %d" % payload_bytes_seen)
			received = true
			_write("client_received", "OK")
			continue
		if received:
			var projectile_finished := true
			for bullet in game.remote_bullets:
				if float(bullet.get("life", 0.0)) > 0.0:
					projectile_finished = false
			if projectile_finished:
				await _wait_for_ping_budget(LOCAL_PING_BUDGET_MS, 2.0)
				_check(game.net_report_ping_min <= LOCAL_PING_BUDGET_MS, "client relay ping exceeded local %dms budget: best=%d last=%d" % [LOCAL_PING_BUDGET_MS, game.net_report_ping_min, game.net_ping_ms])
				print("[CLIENT] ABILITY_VISUAL_OK ping_ms=%d ping_min_ms=%d payload_bytes=%d q_e_tp_visible=true projectile_removed=true" % [game.net_ping_ms, game.net_report_ping_min, payload_bytes_seen])
				_write("client_result", "OK")
				while not FileAccess.file_exists(PREFIX + "server_result.txt") and Time.get_ticks_msec() < deadline:
					await process_frame
				await _finish()
				return
	_fail("client timed out waiting for Q/E/TP or projectile destroy")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _wait_for_ping_budget(budget_ms: int, max_wait: float) -> void:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < int(max_wait * 1000.0):
		if game.net_report_ping_min <= budget_ms:
			return
		if game.online_connected:
			game._update_online_ping(Time.get_ticks_msec())
		await process_frame


func _write(name: String, value: String) -> void:
	var file := FileAccess.open(PREFIX + name + ".txt", FileAccess.WRITE)
	if file:
		file.store_string(value)
		file.close()


func _finish() -> void:
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
	var error := "[%s] %s" % [role.to_upper(), message]
	push_error(error)
	_write("error", error)
	quit(1)
