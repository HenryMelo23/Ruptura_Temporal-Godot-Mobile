extends "res://tests/multiplayer_lobby_integration_smoke.gd"

const Fixture = preload("res://tests/multiplayer_boss1_team_rewind_smoke.gd")
var round_index := 0
var initialized := false
var saw_rewind := false
var last_ms := 0
var rewind_event := ""


func _result_path(result_role: String) -> String:
	return "res://.agent_logs/boss1_rewind_wire_%d_%s.txt" % [port, result_role]


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
			print("BOSS1_REWIND_WIRE_OK role=%s host_hit=true client_hit=true own_history=true animation=true" % role)
			await _finish()
			return
		if not game.online_connected or game.online_lobby_connected_count != 2 or round_index >= 2:
			continue
		var suffix := str(round_index)
		if not initialized:
			initialized = true
			game.set_process(false)
			Fixture.seed_rewind(game, Vector2(240, 300) if role == "host" else Vector2(880, 500))
			game.player_hp = 100 if role == "host" else 300
			game.run_tutorial_enabled = false
			last_ms = Time.get_ticks_msec()
			_write_result(role + "_ready" + suffix)
		var now := Time.get_ticks_msec()
		var delta := clampf(float(now - last_ms) / 1000.0, 0.0, 0.05)
		last_ms = now
		game._sync_multiplayer_state()
		if role == "host" and not action_sent and _result_exists("client_ready" + suffix) and not game.net_players_by_peer.is_empty():
			var target_peer: int = game._mp_unique_id()
			var target: Vector2 = game.player_pos
			if round_index == 1:
				for peer_id in game.net_players_by_peer:
					if int(peer_id) != game._mp_unique_id():
						target_peer = int(peer_id)
						target = Vector2(game.net_players_by_peer[peer_id].get("pos", target))
						break
			game.boss1_time_wave = {"origin": game.boss_pos, "radius": game.boss_pos.distance_to(target) - 20.0, "direction": 1.0, "age": game.BOSS1_TIME_WAVE_WARNING, "max_radius": 5000.0, "variant": 1, "target_peer": target_peer}
			game._update_boss1_time_wave(0.05)
			action_sent = true
		if not game.boss1_rewind_sequence.is_empty():
			saw_rewind = true
			rewind_event = String(game.boss1_rewind_sequence.get("event_id", ""))
			game._update_boss1_rewind_sequence(delta)
		if saw_rewind and game.boss1_rewind_sequence.is_empty() and is_equal_approx(game.boss_hp, 520.0):
			var expected_pos := Vector2(240, 300) if role == "host" else Vector2(880, 500)
			var expected_hp := 200 if role == "host" else 350
			if game.player_pos.distance_to(expected_pos) > 0.1 or game.player_hp != expected_hp:
				_fail("rewind result role=%s round=%d pos=%s hp=%d" % [role, round_index, game.player_pos, game.player_hp])
				return
			game._rpc_boss1_team_rewind(rewind_event, 1)
			if not game.boss1_rewind_sequence.is_empty():
				_fail("duplicate start replayed completed animation")
				return
			_write_result(role + "_done" + suffix)
		if _result_exists("host_done" + suffix) and _result_exists("client_done" + suffix):
			round_index += 1
			initialized = false
			action_sent = false
			saw_rewind = false
			if round_index == 2:
				_write_result(role)
	_fail("rewind wire timeout role=%s round=%d animation=%s hp=%d boss_hp=%.1f" % [role, round_index, saw_rewind, game.player_hp, game.boss_hp])
