extends "res://tests/multiplayer_lobby_integration_smoke.gd"

var initialized := false
var request_sent := false
var target_uid := -1
var last_ms := 0
var coagula_before := 0


func _result_path(result_role: String) -> String:
	if result_dir != "":
		return result_dir.path_join("%s_result.txt" % result_role)
	return "res://.agent_logs/lacerante_execution_wire_%d_%s.txt" % [port, result_role]


func _lacerante_index() -> int:
	for index in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[index].get("key", "")) == "lacerante":
			return index
	return 0


func _configure_runner() -> void:
	game.set_process(false)
	game.mode = "game"
	game.run_tutorial_enabled = false
	game.active_character_key = game.CHARACTER_GEOVANA
	game.selected_manifestation = _lacerante_index()
	game.manifestation_key = "lacerante"
	game.player_damage = 40.0
	game.player_hp = 100
	game.player_hp_max = 100
	game.is_dead = false
	game.player_pos = Vector2(520.0, 420.0) if role == "host" else Vector2(700.0, 420.0)
	game.enemies.clear()
	game._lacerante_exec().reset()
	last_ms = Time.get_ticks_msec()
	coagula_before = int(game.lacerante_coagula)


func _run() -> void:
	while Time.get_ticks_msec() - started_ms < TIMEOUT_MS:
		await process_frame
		if role == "server":
			if _result_exists("host") and _result_exists("client"):
				_write_result("server")
				print("MULTIPLAYER_LACERANTE_EXECUTION_WIRE_OK role=server request=relayed authority=true")
				await _finish()
				return
			continue
		if _result_exists(role) and _result_exists("server"):
			print("MULTIPLAYER_LACERANTE_EXECUTION_WIRE_OK role=%s request=wire authority_kill=true owner_reward=once" % role)
			await _finish()
			return
		if not game.online_connected or game.online_lobby_connected_count != 2:
			continue
		if not initialized:
			initialized = true
			_configure_runner()
			if role == "host":
				game._spawn_enemy(game.ENEMY_COMMON, Vector2(790.0, 420.0))
				var target: Dictionary = game.enemies[-1]
				target["pos"] = Vector2(790.0, 420.0)
				target["hp"] = 18.0
				target["max_hp"] = 100.0
				target["speed"] = 0.0
				target_uid = int(target.get("uid", -1))
				_write_result("host_ready")
		var now := Time.get_ticks_msec()
		var delta := clampf(float(now - last_ms) / 1000.0, 0.0, 0.05)
		last_ms = now
		game._sync_multiplayer_state()
		game._lacerante_exec().update(delta)
		if role == "host":
			for peer_id in game.net_players_by_peer:
				var remote_state: Dictionary = game.net_players_by_peer[peer_id]
				if game._damage_source_manifestation_key(int(peer_id)) == "lacerante":
					_write_result("host_manifest")
			game._update_remote_lacerante_executions(delta)
			if game.net_seen_lacerante_execution_request_ids.size() > 0:
				_write_result("host_seen")
			if game.net_remote_lacerante_execution_jobs.size() > 0:
				_write_result("host_scheduled")
			var tracked = game._enemy_by_uid(target_uid) if target_uid > 0 else null
			if tracked != null and float(tracked.get("hp", 1.0)) <= 0.0:
				_write_result("host_killed")
			if target_uid > 0 and game.net_seen_lacerante_execution_request_ids.size() == 1 and game.net_remote_lacerante_execution_jobs.is_empty() and game._enemy_by_uid(target_uid) == null:
				_write_result("host")
		elif not request_sent and _result_exists("host_ready") and not game.enemies.is_empty() and not game.net_players_by_peer.is_empty():
			var target: Dictionary = game.enemies[0]
			# The legacy lobby fixture reassigns the second slot to Henry on each
			# snapshot. This scenario exercises the newer manifestation path.
			game.active_character_key = game.CHARACTER_GEOVANA
			game.selected_manifestation = _lacerante_index()
			game.manifestation_key = "lacerante"
			game._sync_multiplayer_state()
			if not _result_exists("host_manifest"):
				continue
			game.player_pos = Vector2(target.get("pos", Vector2(790.0, 420.0))) - Vector2(90.0, 0.0)
			var points: Array = [game.player_pos, game.player_pos + Vector2(180.0, 0.0)]
			if not game._lacerante_exec().try_start_on_slash(points, 52.0):
				_fail("client could not request executable replica hp=%.2f threshold=%.2f key=%s character=%s enabled=%s executable=%s dist=%.2f line=%.2f authority=%s uid=%s" % [float(target.get("hp", -1.0)), game._lacerante_exec().threshold(target), game.manifestation_key, game.active_character_key, game._lacerante_exec()._enabled(), game._lacerante_exec().can_be_executed(target), game.player_pos.distance_to(Vector2(target.get("pos", game.player_pos))), game._distance_to_polyline(target.get("pos", game.player_pos), points), game._is_world_authority(), str(target.get("uid", ""))])
				return
			request_sent = true
			_write_result("client_requested")
		elif request_sent and int(game.lacerante_coagula) == coagula_before + 1 and game._lacerante_exec().confirmed_remote_finish_ids.size() == 1:
			_write_result("client")
	_fail("lacerante wire timeout role=%s requested=%s pending=%s jobs=%d coagula=%d" % [role, request_sent, game._lacerante_exec().pending_remote_event_id, game.net_remote_lacerante_execution_jobs.size(), int(game.lacerante_coagula)])
