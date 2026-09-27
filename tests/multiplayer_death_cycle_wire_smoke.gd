extends "res://tests/multiplayer_lobby_integration_smoke.gd"

const STAGE_PATH := "res://.codex/death_cycle_stage.txt"
var local_stage := 0
var server_stage := 1


func _result_path(result_role: String) -> String:
	return "res://.codex/death_cycle_%s.txt" % result_role


func _run() -> void:
	game.set_process(false)
	game.startup_thanks_done = true
	game.run_tutorial_enabled = false
	while Time.get_ticks_msec() - started_ms < TIMEOUT_MS:
		await process_frame
		if role == "server":
			if game._dedicated_active_peer_ids().size() != 2:
				continue
			var stage_file := FileAccess.open(STAGE_PATH, FileAccess.WRITE)
			stage_file.store_string(str(server_stage))
			stage_file.close()
			var received := true
			for peer_id in game._dedicated_active_peer_ids():
				var state: Dictionary = game.dedicated_player_state_by_peer.get(peer_id, {})
				if int(Vector2(state.get("pos", Vector2.ZERO)).x) != server_stage:
					received = false
			if not received:
				continue
			var cycle_step: int = (server_stage - 1) % 4
			var expected_living: int = [2, 1, 2, 0][cycle_step]
			if game._dedicated_living_peer_ids().size() != expected_living:
				_fail("relay lost death/revive state at stage %d" % server_stage)
				return
			if cycle_step == 1 and not game._dedicated_all_peers_voted({game.dedicated_room_owner_peer_id: true}):
				_fail("dead client still required for consensus")
				return
			if not _result_exists("host_%d" % server_stage) or not _result_exists("client_%d" % server_stage):
				continue
			server_stage += 1
			if server_stage > 28:
				# Stop relay callbacks before the test clients tear down their peers.
				multiplayer_poll = false
				_write_result("server")
				print("DEATH_CYCLE_WIRE_OK phases=7 death_revive_death=true living_consensus=true all_dead_ends_run=true")
				await create_timer(0.5).timeout
				await _finish()
				return
			continue
		if not game.online_connected or game.online_lobby_connected_count != 2 or not FileAccess.file_exists(STAGE_PATH):
			continue
		if _result_exists("server"):
			await _finish()
			return
		var stage := int(FileAccess.get_file_as_string(STAGE_PATH))
		var cycle_step: int = (stage - 1) % 4
		var dead: bool = cycle_step == 3 or (cycle_step == 1 and role == "client")
		if stage != local_stage:
			local_stage = stage
			game.is_multiplayer = true
			game.current_phase = 1 + (stage - 1) / 4
			game.mode = "game"
			game.is_dead = dead
			game.player_hp = 0.0 if dead else 450.0
			game.player_hp_max = 450.0
			if dead:
				game.rpc_id(1, "_rpc_player_died")
		var pos := Vector2(stage, game.current_phase)
		if stage % 2 == 0:
			game.rpc_id(1, "_rpc_client_player_state", {"pos": pos, "hp": game.player_hp, "hp_max": 450.0, "dead": dead}, [], [], [], [], [])
		else:
			game.rpc_id(1, "_rpc_client_player_state_light", pos, int(game.player_hp), 450, dead, 0, 1, 0, 0, false, 0, false)
		if cycle_step == 3:
			game._finish_multiplayer_defeat_if_all_dead()
			if game.mode != "game_over":
				continue
		_write_result("%s_%d" % [role, stage])
	_fail("death/revive wire timeout at stage %d role=%s" % [local_stage, role])
