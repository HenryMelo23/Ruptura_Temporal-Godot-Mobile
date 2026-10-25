extends SceneTree

const VisualSyncContract = preload("res://scripts/systems/online/runtime_visual_sync_contract.gd")

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
	var client_visuals_received := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if game.online_connected:
			game._update_online_ping(Time.get_ticks_msec())
			game._sync_active_ability_visual_state(Time.get_ticks_msec())
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
			_send_manifestation_transport_matrix()
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
		if sent and not client_visuals_received and FileAccess.file_exists(PREFIX + "client_sent.txt"):
			var remote_actions := {}
			var canonical_patch_received := false
			for visual in game.net_ability_visuals:
				if int(visual.get("source", 0)) == game._mp_unique_id():
					continue
				_check(int(visual.get("schema", 0)) == VisualSyncContract.ABILITY_VISUAL_SCHEMA, "host received legacy/simplified ability visual")
				_check(visual.get("canonical_state", null) is Dictionary and not Dictionary(visual.get("canonical_state", {})).is_empty(), "host received ability visual without canonical local state")
				remote_actions[int(visual.get("action", -1))] = true
				canonical_patch_received = canonical_patch_received or int(visual.get("canonical_patch_count", 0)) > 0
			var visual_state_received := false
			for state_value in game.net_players_by_peer.values():
				if not state_value is Dictionary:
					continue
				var state: Dictionary = state_value
				if int(state.get("visual_action_sequence", -1)) == 321:
					_check(Vector2(state.get("input_move", Vector2.ZERO)).is_equal_approx(Vector2(-0.8, 0.2)), "host lost client movement intent")
					_check(Vector2(state.get("aim_dir", Vector2.ZERO)).is_equal_approx(Vector2(-1.0, 0.25).normalized()), "host lost client aim intent")
					visual_state_received = true
			if visual_state_received and canonical_patch_received and remote_actions.has(game.NET_ABILITY_SKILL) and remote_actions.has(game.NET_ABILITY_SECONDARY) and remote_actions.has(game.NET_ABILITY_TELEPORT):
				client_visuals_received = true
				_write("host_received_client", "OK")
				continue
		if destroy_sent and FileAccess.file_exists(PREFIX + "client_result.txt"):
			_check(client_visuals_received, "host did not receive client Q/E/TP visuals")
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
	var response_sent := false
	var payload_bytes_seen := 0
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if game.online_connected:
			game._update_online_ping(Time.get_ticks_msec())
			game._sync_active_ability_visual_state(Time.get_ticks_msec())
		if not received and game.net_ability_visuals.size() >= 3 and not game.remote_bullets.is_empty():
			var actions := {}
			var canonical_patch_received := false
			var manifestation_actions := {}
			for visual in game.net_ability_visuals:
				actions[int(visual.get("action", -1))] = true
				_check(int(visual.get("schema", 0)) == VisualSyncContract.ABILITY_VISUAL_SCHEMA, "client received legacy/simplified ability visual")
				_check(visual.get("canonical_state", null) is Dictionary and not Dictionary(visual.get("canonical_state", {})).is_empty(), "client received ability visual without canonical local state")
				canonical_patch_received = canonical_patch_received or int(visual.get("canonical_patch_count", 0)) > 0
				var manifest_key := String(visual.get("manifestation_key", ""))
				if manifest_key != "":
					if not manifestation_actions.has(manifest_key):
						manifestation_actions[manifest_key] = {}
					manifestation_actions[manifest_key][int(visual.get("action", -1))] = true
			if not canonical_patch_received or not _manifestation_transport_matrix_complete(manifestation_actions):
				continue
			_check(actions.has(game.NET_ABILITY_SKILL), "client did not receive Q visual")
			_check(actions.has(game.NET_ABILITY_SECONDARY), "client did not receive E visual")
			_check(actions.has(game.NET_ABILITY_TELEPORT), "client did not receive TP visual")
			var exact_replicas := 0
			for visual in game.net_ability_visuals:
				if bool(visual.get("network_replica", false)):
					exact_replicas += 1
			_check(exact_replicas >= 3, "Q/E/TP were not reconstructed as local effect replicas")
			_check(not game.effects.is_empty(), "remote projectile muzzle/trail was not reproduced")
			var first_visual: Dictionary = game.net_ability_visuals[0]
			var sanitized_payload := VisualSyncContract.sanitize_ability_payload(first_visual)
			payload_bytes_seen = VisualSyncContract.ability_event_bytes([
				int(first_visual.get("source", 42)), int(first_visual.get("sequence", 1)), int(first_visual.get("action", game.NET_ABILITY_SKILL)),
				int(first_visual.get("manifestation", 0)), Vector2(first_visual.get("origin", Vector2.ZERO)), Vector2(first_visual.get("target", Vector2.ZERO)),
				float(first_visual.get("max", 0.75)), float(first_visual.get("extra", 0.0)), sanitized_payload, 5
			])
			_check(payload_bytes_seen <= VisualSyncContract.ABILITY_VISUAL_MAX_BYTES, "ability event exceeded compact budget: %d" % payload_bytes_seen)
			received = true
			_write("client_received", "OK")
			continue
		if received and not response_sent:
			# This transport matrix exercises Geovana manifestations, not Henry mutations.
			# The lobby now correctly assigns Henry to the second player by default.
			game.active_character_key = game.CHARACTER_GEOVANA
			var ressonante_index := -1
			for manifest_index in range(game.MANIFESTATIONS.size()):
				if String(game.MANIFESTATIONS[manifest_index].get("key", "")) == "ressonante":
					ressonante_index = manifest_index
					break
			_check(ressonante_index >= 0, "ressonante manifestation missing")
			game.selected_manifestation = ressonante_index
			game.manifestation_key = "ressonante"
			game.time_alive = 45.0
			game.last_skill_time = -999.0
			game.last_secondary_time = -999.0
			game.player_pos = Vector2(920, 400)
			game.last_facing = Vector2.LEFT
			game._use_skill(Vector2(720, 400))
			game._use_secondary_skill(Vector2(920, 400))
			game._execute_teleport(Vector2(780, 440))
			var visual_snapshot := VisualSyncContract.pack_player_visual(Vector2(-0.8, 0.2), Vector2(-1.0, 0.25), game.NET_ABILITY_SKILL, 0.14, 0.82, 321, 2)
			game.rpc_id(1, "_rpc_client_player_state_light", game.player_pos, int(game.player_hp), int(game.player_hp_max), false, ressonante_index, 0, game.NET_ANIM_FIRE, 1, true, game.net_ping_ms, false, "ressonante", visual_snapshot)
			response_sent = true
			_write("client_sent", "OK")
			continue
		if received and response_sent:
			var projectile_finished := true
			for bullet in game.remote_bullets:
				if float(bullet.get("life", 0.0)) > 0.0:
					projectile_finished = false
			if projectile_finished and FileAccess.file_exists(PREFIX + "host_received_client.txt"):
				await _wait_for_ping_budget(LOCAL_PING_BUDGET_MS, 2.0)
				_check(game.net_report_ping_min <= LOCAL_PING_BUDGET_MS, "client relay ping exceeded local %dms budget: best=%d last=%d" % [LOCAL_PING_BUDGET_MS, game.net_report_ping_min, game.net_ping_ms])
				print("[CLIENT] ABILITY_VISUAL_OK ping_ms=%d ping_min_ms=%d payload_bytes=%d q_e_tp_visible=true manifestations=15 projectile_removed=true" % [game.net_ping_ms, game.net_report_ping_min, payload_bytes_seen])
				_write("client_result", "OK")
				while not FileAccess.file_exists(PREFIX + "server_result.txt") and Time.get_ticks_msec() < deadline:
					await process_frame
				await _finish()
				return
	_fail("client timed out waiting for Q/E/TP or projectile destroy")


func _send_manifestation_transport_matrix() -> void:
	var sequence := 100
	for manifest_index in range(game.MANIFESTATIONS.size()):
		var manifest_key := String(game.MANIFESTATIONS[manifest_index].get("key", ""))
		for action in [game.NET_ABILITY_SKILL, game.NET_ABILITY_SECONDARY, game.NET_ABILITY_TELEPORT]:
			var state := {"manifestation_key": manifest_key, "evolution_ids": [], "source_time": game.time_alive}
			if action == game.NET_ABILITY_SECONDARY:
				state["secondary"] = {"kind": "eclipsada_sol" if manifest_key == "eclipsada" else manifest_key, "life": 4.0, "max": 4.0, "active_time": 0.0, "center": game.player_pos}
			elif action == game.NET_ABILITY_TELEPORT:
				state["tp_effects"] = [{"kind": manifest_key, "life": 0.8, "max": 0.8, "a": game.player_pos, "b": game.player_pos + Vector2(80, 0)}]
			var payload := {
				"schema": VisualSyncContract.ABILITY_VISUAL_SCHEMA,
				"event_id": "%d:%d" % [game._mp_unique_id(), sequence],
				"manifestation_key": manifest_key,
				"seed": sequence,
				"canonical_state": state
			}
			game.rpc_id(1, "_rpc_ability_visual", game._mp_unique_id(), sequence, action, manifest_index, game.player_pos, game.player_pos + Vector2(80, 0), 5.0, 0.0, payload, game.net_ping_ms)
			sequence += 1


func _manifestation_transport_matrix_complete(manifestation_actions: Dictionary) -> bool:
	if manifestation_actions.size() < game.MANIFESTATIONS.size():
		return false
	for manifestation in game.MANIFESTATIONS:
		var key := String(manifestation.get("key", ""))
		var actions: Dictionary = manifestation_actions.get(key, {})
		if not actions.has(game.NET_ABILITY_SKILL) or not actions.has(game.NET_ABILITY_SECONDARY) or not actions.has(game.NET_ABILITY_TELEPORT):
			return false
	return true


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
