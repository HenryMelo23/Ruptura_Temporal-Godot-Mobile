extends SceneTree

const RESULT_PREFIX := "res://tests/gameplay_authority_"
const ERROR_FILE := "res://tests/gameplay_authority_error.txt"
const CLIENT_TEST_POS := Vector2(760, 500)
const HIGH_ENEMY_UID := 4026531841
const DAMAGE_PER_HIT := 7.0
const DAMAGE_SOURCES := [
	"eletrica", "lacerante", "prismatica", "retornante", "parasitica", "gravitante",
	"ancorada", "cartografica", "mnesica", "ressonante", "contratual",
	"eletrica_charged", "lacerante_empowered", "gravitante_orbital", "veneno",
	"aura_vanguarda", "aura_insana", "aura_voraz", "aura_abissal"
]
const SPECTRUM_PROBE_DAMAGE := 10.0
const SPECTRUM_PROBE_MULTIPLIER := 1.69
const EXPECTED_DAMAGE_REQUESTS := 22
const EXPECTED_TOTAL_DAMAGE := DAMAGE_PER_HIT * 21.0 + SPECTRUM_PROBE_DAMAGE * SPECTRUM_PROBE_MULTIPLIER

var game: Node
var role: String = ""
var host: String = "127.0.0.1"
var port: int = 4591
var ping_budget_ms: int = 30

var manifest_reveal_requested := false
var spectrum_ready_sent := false
var manifest_start_requested := false
var requested_start := false
var client_marked_ready := false
var client_hit_sent := false
var spawned_test_enemy := false
var remote_damage_sent := false
var host_game_initialized := false
var client_game_initialized := false
var client_damage_seen_at := -1.0
var enemy_uid := ""
var enemy_initial_hp := 0.0
var host_hp_before_remote_damage := 0
var remote_hp_before_damage := 0
var server_game_seen_at := -1.0


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	var err_msg := "[%s] %s" % [role.to_upper(), message]
	push_error(err_msg)
	var file := FileAccess.open(ERROR_FILE, FileAccess.WRITE)
	if file:
		file.store_string(err_msg)
		file.close()
	quit(1)


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
		elif arg.begins_with("--ping-budget="):
			ping_budget_ms = maxi(1, int(arg.substr("--ping-budget=".length())))

	_check(role in ["server", "host", "client"], "missing or invalid --role")
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_start_role")


func _start_role() -> void:
	if role == "server":
		game.dedicated_room_code = "GAMEPLAY_AUTHORITY"
		game._start_dedicated_room_server(port)
		_run_server_loop()
	elif role == "host":
		game.player_nickname = "SmokeHost"
		game.is_multiplayer = true
		game.is_host = false
		game.online_room_owner = true
		game.mode = "lobby_online_host"
		game._connect_to_online_host(host, port)
		_run_host_loop()
	else:
		game.player_nickname = "SmokeClient"
		game.is_multiplayer = true
		game.is_host = false
		game.online_room_owner = false
		game.mode = "lobby_online_client"
		game._connect_to_online_host(host, port)
		_run_client_loop()


func _run_server_loop() -> void:
	var total_time := 0.0
	var results_seen := false
	while true:
		await process_frame
		total_time += 0.016
		if game.mode == "game" and server_game_seen_at < 0.0:
			server_game_seen_at = total_time
		if server_game_seen_at >= 0.0 and total_time - server_game_seen_at > 1.0:
			_check(game.enemies.is_empty(), "dedicated server simulated enemies; server must relay only")
			_check(game.enemy_bullets.is_empty(), "dedicated server simulated enemy bullets; server must relay only")
		if not results_seen and _result_exists("host") and _result_exists("client"):
			results_seen = true
			print("[SERVER] GAMEPLAY_AUTHORITY_OK server relay stayed clean")
		if results_seen and game.dedicated_room_shutdown_pending:
			return
		if total_time > 15.0:
			_check(false, "timeout waiting for host/client gameplay authority result")
			return


func _run_host_loop() -> void:
	var total_time := 0.0
	while true:
		await process_frame
		total_time += 0.016
		if total_time > 15.0:
			var timeout_enemy := _host_enemy_by_uid(enemy_uid)
			print("[HOST] TIMEOUT enemy_hp=%.2f expected=%.2f remote_hp=%d peer=%d" % [float(timeout_enemy.get("hp", -1.0)), enemy_initial_hp - EXPECTED_TOTAL_DAMAGE, int(game.net_player_hp), game.net_player_peer_id])
			_check(false, "timeout waiting for host gameplay authority checks")
			return

		_host_lobby_and_manifest_flow()

		if game.mode != "game":
			continue

		_check(game._is_world_authority(), "online host owner must be world authority")
		_check(not game.dedicated_server_mode, "host process cannot be dedicated server")
		if not host_game_initialized:
			host_game_initialized = true
			game.spawn_timer = 9999.0
			game.boss_active = false
			game.boss_dead = true
			game.enemies.clear()
			game.enemy_bullets.clear()
			print("[HOST] game reached; waiting remote player sync")
		if game.net_player_peer_id == 0 or game.net_player_pos.distance_to(CLIENT_TEST_POS) > 90.0:
			continue

		if not spawned_test_enemy:
			spawned_test_enemy = true
			game.enemies.clear()
			game._spawn_enemy("comum", CLIENT_TEST_POS + Vector2(150, 0))
			_check(game.enemies.size() == 1, "world authority host failed to spawn test enemy")
			var enemy: Dictionary = game.enemies[0]
			enemy["uid"] = HIGH_ENEMY_UID
			enemy["hp"] = 5000.0
			enemy["max_hp"] = 5000.0
			enemy["speed"] = 0.0
			enemy["hit_cd"] = 99.0
			game.enemies[0] = enemy
			enemy_uid = str(enemy["uid"])
			enemy_initial_hp = float(enemy["hp"])
			game.net_world_sync_last_ms = 0
			print("[HOST] spawned test enemy uid=%s hp=%.1f" % [enemy_uid, enemy_initial_hp])
			continue

		var enemy := _host_enemy_by_uid(enemy_uid)
		if enemy.is_empty():
			_check(false, "test enemy disappeared before client hit could be verified")
			return

		var expected_hp: float = enemy_initial_hp - EXPECTED_TOTAL_DAMAGE
		if not remote_damage_sent and float(enemy.get("hp", 0.0)) <= expected_hp + 0.01:
			_check(absf(float(enemy.get("hp", 0.0)) - expected_hp) <= 0.05, "damage matrix total differs from manifestations/spectrum contract")
			remote_damage_sent = true
			host_hp_before_remote_damage = int(game.player_hp)
			remote_hp_before_damage = int(game.net_player_hp)
			enemy["pos"] = game.net_player_pos
			enemy["speed"] = 0.0
			enemy["hit_cd"] = 0.0
			game._update_enemies(0.20)
			print("[HOST] routed enemy damage to remote peer; host_hp=%d remote_hp_before=%d" % [host_hp_before_remote_damage, remote_hp_before_damage])
			continue

		if remote_damage_sent:
			_check(int(game.player_hp) == host_hp_before_remote_damage, "enemy damage aimed at client also changed host hp")
			if int(game.net_player_hp) < remote_hp_before_damage:
				await _wait_for_ping_budget(ping_budget_ms, 2.0)
				_check(game.net_report_ping_min <= ping_budget_ms, "host relay ping exceeded local %dms budget: best=%d last=%d" % [ping_budget_ms, game.net_report_ping_min, game.net_ping_ms])
				if not _result_exists("client"):
					continue
				await _finish_ok("host authority applied client hit and routed enemy damage to client only")
				return


func _run_client_loop() -> void:
	var total_time := 0.0
	var hp_before := 0
	while true:
		await process_frame
		total_time += 0.016
		if total_time > 15.0:
			_check(false, "timeout waiting for client gameplay authority checks")
			return

		_client_lobby_and_manifest_flow()

		if game.mode != "game":
			continue

		game.player_pos = CLIENT_TEST_POS
		_check(game._is_world_replica(), "online client must be a world replica")
		if not client_game_initialized:
			client_game_initialized = true
			print("[CLIENT] game reached; waiting authoritative enemy")

		if not client_hit_sent:
			var enemy := _client_enemy_by_uid(str(HIGH_ENEMY_UID))
			if enemy.is_empty():
				continue
			var local_hp_before := float(enemy.get("hp", 0.0))
			client_hit_sent = true
			hp_before = int(game.player_hp)
			for source in DAMAGE_SOURCES:
				game._damage_enemy(enemy, DAMAGE_PER_HIT, source, false)
			game.player_crit_chance = 0.0
			game._apply_bullet_effect({
				"damage": DAMAGE_PER_HIT,
				"kind": "eletrica",
				"pos": Vector2(enemy.get("pos", CLIENT_TEST_POS)),
				"dir": Vector2.RIGHT
			}, enemy)
			game._apply_aura_events([{
				"type": "enemy_damage",
				"uid": HIGH_ENEMY_UID,
				"amount": DAMAGE_PER_HIT,
				"source": "aura_vanguarda"
			}])
			var selected_aura_name := String(game.aura_state.get("name", ""))
			game.aura_state["name"] = "Impulsiva"
			game.aura_state["impulsive_active"] = 5.0
			game.aura_state["impulsive_rank"] = 2
			game._damage_enemy(enemy, SPECTRUM_PROBE_DAMAGE, "spectrum_multiplier_probe", false)
			game.aura_state["impulsive_active"] = 0.0
			game.aura_state["name"] = selected_aura_name
			_check(float(enemy.get("hp", 0.0)) == local_hp_before, "client replica mutated enemy locally instead of sending hit to host")
			print("[CLIENT] sent %d damage routes against authoritative high uid=%s" % [EXPECTED_DAMAGE_REQUESTS, HIGH_ENEMY_UID])
			continue

		if client_hit_sent and int(game.player_hp) < hp_before:
			if client_damage_seen_at < 0.0:
				client_damage_seen_at = total_time
				continue
			if total_time - client_damage_seen_at < 0.60:
				continue
			await _wait_for_ping_budget(ping_budget_ms, 2.0)
			_check(game.net_report_ping_min <= ping_budget_ms, "client relay ping exceeded local %dms budget: best=%d last=%d" % [ping_budget_ms, game.net_report_ping_min, game.net_ping_ms])
			await _finish_ok("client skill hit was relayed and client-only damage arrived")
			return


func _host_lobby_and_manifest_flow() -> void:
	if not requested_start and game.online_lobby_connected_count == 2 and game.online_lobby_ready_count >= 1:
		requested_start = true
		game._send_host_start_request()
		return
	_manifest_selection_flow(1, 1)
	if spectrum_ready_sent and not manifest_start_requested and game._manifest_all_players_ready():
		manifest_start_requested = true
		game._request_manifest_mp_start()


func _client_lobby_and_manifest_flow() -> void:
	if not client_marked_ready and game.online_connected and game.mode == "lobby_online_client":
		client_marked_ready = true
		game._set_lobby_ready(true)
		return
	_manifest_selection_flow(2, 3)


func _manifest_selection_flow(manifestation: int, aura: int) -> void:
	if game.mode == "manifest_mp" and game.manifest_select_stage == game.MANIFEST_STAGE_MANIFESTATION and not manifest_reveal_requested:
		manifest_reveal_requested = true
		game._set_selected_manifestation(manifestation, false)
		game._confirm_manifest_mp_selection()
	elif game.mode == "manifest_mp" and game.manifest_select_stage == game.MANIFEST_STAGE_AURA and not spectrum_ready_sent:
		spectrum_ready_sent = true
		game._set_selected_aura(aura, false)
		game._confirm_manifest_mp_selection()


func _host_enemy_by_uid(uid: String) -> Dictionary:
	for enemy in game.enemies:
		if str(enemy.get("uid", "")) == uid:
			return enemy
	return {}


func _client_enemy_by_uid(uid: String) -> Dictionary:
	for enemy in game.enemies:
		if str(enemy.get("uid", "")) == uid:
			return enemy
	return {}


func _result_exists(result_role: String) -> bool:
	return FileAccess.file_exists(RESULT_PREFIX + result_role + "_result.txt")


func _wait_for_ping_budget(budget_ms: int, max_wait: float) -> void:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < int(max_wait * 1000.0):
		if game.net_report_ping_min <= budget_ms:
			return
		if game.online_connected:
			game._update_online_ping(Time.get_ticks_msec())
		await process_frame


func _finish_ok(message: String) -> void:
	var best_ping: int = int(game.net_report_ping_min) if game.net_report_ping_count > 0 else -1
	print("[%s] GAMEPLAY_AUTHORITY_OK ping_ms=%d ping_min_ms=%d remote_ping_ms=%d %s" % [role.to_upper(), int(game.net_ping_ms), int(best_ping), int(game.net_remote_ping_ms), message])
	var file := FileAccess.open(RESULT_PREFIX + role + "_result.txt", FileAccess.WRITE)
	if file:
		file.store_string("OK")
		file.close()
		file = null
	# Let the owner close first so the test exercises the production room-shutdown
	# path instead of destroying both ENet peers during the same relay frame.
	if role == "client":
		while not _result_exists("host"):
			await process_frame
		await create_timer(0.6).timeout
	if is_instance_valid(game):
		game._leave_multiplayer()
		for _frame in range(4):
			await process_frame
		game._cleanup_runtime_resources()
		_cleanup_audio_resources()
		for i in range(4):
			await process_frame
		root.remove_child(game)
		game.free()
		game = null
	for i in range(4):
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
