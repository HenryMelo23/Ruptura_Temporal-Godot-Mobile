extends "res://tests/multiplayer_lobby_integration_smoke.gd"

var initialized := false
var last_snapshot_ms := 0
var sequence := 0
var requested_reward := false


func _result_path(result_role: String) -> String:
	return "res://.agent_logs/score_boss_wire_%d_%s.txt" % [port, result_role]


func _run() -> void:
	while Time.get_ticks_msec() - started_ms < TIMEOUT_MS:
		await process_frame
		if role == "server":
			if _result_exists("host") and _result_exists("client"):
				_write_result("server")
				await _finish()
				return
			continue
		if _result_exists(role) and _result_exists("server"):
			print("MULTIPLAYER_SCORE_BOSS_WIRE_OK role=%s score=%d entry=%.2f" % [role, game.score, game.boss_entry_timer])
			await _finish()
			return
		if not game.online_connected or game.online_lobby_connected_count != 2:
			continue
		if not initialized:
			initialized = true
			game.set_process(false)
			game.run_tutorial_enabled = false
			game.score = 0
			game.score_total = 0
			game.run_points_earned = 0
			game.time_alive = 0.0
			game.mode = "game"
			game.current_phase = 1
			game.boss_ready = true
			game._start_boss_call_local()
			game._update_boss_call(game.BOSS_CALL_COUNTDOWN + 0.01)
			_write_result(role + "_ready")
		var kill_reward: int = game._points_for_enemy({"points": 20})
		if role == "host" and _result_exists("client_ready"):
			if not action_sent:
				action_sent = true
				game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(200, 0))
				var enemy: Dictionary = game.enemies.back()
				enemy["points"] = 20
				game._kill_enemy(enemy)
				game._apply_score_delta(50, true, "host-reward")
				game._apply_score_delta(50, true, "host-reward")
			game.boss_entry_timer = 0.0 if _result_exists("client_entry") else game.BOSS_ENTRY_TIME * 0.5
			if Time.get_ticks_msec() - last_snapshot_ms >= 50:
				last_snapshot_ms = Time.get_ticks_msec()
				sequence += 1
				game.rpc_id(1, "_update_remote_entities", sequence, game._pack_net_enemies(), game._pack_net_boss(), game._pack_net_enemy_bullets())
				game.rpc_id(1, "_update_remote_world_visuals", sequence, game._pack_net_boss_visuals())
			if game.score == kill_reward + 75 and game.boss_entry_timer == 0.0:
				_write_result(role)
		elif role == "client":
			if is_equal_approx(game.boss_entry_timer, game.BOSS_ENTRY_TIME * 0.5):
				_write_result("client_entry")
			if game.score == kill_reward + 50 and not requested_reward:
				requested_reward = true
				game._apply_score_delta(25, true, "client-reward")
				game._apply_score_delta(25, true, "client-reward")
				if game.score != kill_reward + 50:
					_fail("client credited its own request before host confirmation")
					return
			if requested_reward and game.score == kill_reward + 75 and game.run_points_earned == game.score and game.boss_entry_timer == 0.0:
				_write_result(role)
	_fail("score/boss wire timeout role=%s score=%d entry=%.2f" % [role, game.score, game.boss_entry_timer])
