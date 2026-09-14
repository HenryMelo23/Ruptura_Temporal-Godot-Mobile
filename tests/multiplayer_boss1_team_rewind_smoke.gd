extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


static func seed_rewind(game: Node, offset: Vector2) -> void:
	game.mode = "game"
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 1000.0
	game.boss_hp = 200.0
	game.player_hp_max = 500.0
	game.player_hp = 100
	game.is_dead = false
	game.boss1_rewind_sequence.clear()
	game.boss1_rewind_history.clear()
	for i in range(11):
		game.time_alive = 20.0 + i * 0.8
		game.elapsed_unpaused = game.time_alive
		game.player_pos = offset + Vector2(i * 20.0, i * 10.0)
		game.boss_pos = Vector2(700, 400) + Vector2(i * 4.0, 0)
		game.boss1_rewind_history.append(game._capture_boss1_rewind_snapshot())


func _run() -> void:
	var host = load("res://scenes/Main.tscn").instantiate()
	var client = load("res://scenes/Main.tscn").instantiate()
	for game in [host, client]:
		root.add_child(game)
		game.set_process(false)
		game.is_multiplayer = true
	host.is_host = true
	client.is_host = false
	client.online_room_owner = false
	for hit_remote in [false, true]:
		seed_rewind(host, Vector2(240, 300))
		seed_rewind(client, Vector2(880, 500))
		client.player_hp = 300
		host.net_players_by_peer[42] = {"pos": client.player_pos, "hp": 300.0, "hp_max": 500.0, "dead": false}
		var target: Vector2 = client.player_pos if hit_remote else host.player_pos
		host.boss1_time_wave = {"origin": host.boss_pos, "radius": host.boss_pos.distance_to(target) - 20.0, "direction": 1.0, "age": host.BOSS1_TIME_WAVE_WARNING, "max_radius": 5000.0, "variant": 2, "target_peer": 42 if hit_remote else host._mp_unique_id()}
		host._update_boss1_time_wave(0.05)
		_check(not host.boss1_rewind_sequence.is_empty(), "wave hit did not start host rewind")
		var packet: Dictionary = host._pack_net_boss_visuals()
		var sequence: Dictionary = packet.get("boss1_rewind_sequence", {})
		_check(not sequence.has("player_final_hp") and not packet.has("boss1_rewind_visual_projectiles"), "host private history/HP leaked into visual packet")
		client._apply_remote_boss_visual_snapshot(packet)
		var event_id: String = String(sequence.get("event_id", ""))
		_check(not event_id.is_empty() and not client.boss1_rewind_sequence.is_empty(), "snapshot did not recover missed start event")
		client._rpc_boss1_team_rewind(event_id, 2)
		_check(int(client.boss1_rewind_sequence.get("player_final_hp", 0)) == 350, "client used host HP instead of its own")
		for step in range(80):
			host._update_boss1_rewind_sequence(0.05)
			client._apply_remote_boss_snapshot(host._pack_net_boss(), Time.get_ticks_msec())
			if step % 3 == 0:
				client._apply_remote_boss_visual_snapshot(host._pack_net_boss_visuals())
			client._update_boss1_rewind_sequence(0.05)
		_check(host.boss1_rewind_sequence.is_empty() and client.boss1_rewind_sequence.is_empty(), "team rewind did not finish")
		_check(host.player_pos.distance_to(Vector2(240, 300)) < 0.1 and client.player_pos.distance_to(Vector2(880, 500)) < 0.1, "players did not return along their own histories")
		_check(host.player_hp == 200 and client.player_hp == 350, "rewind healing changed")
		_check(is_equal_approx(host.boss_hp, 520.0) and is_equal_approx(client.boss_hp, 520.0), "boss heal was applied more than once")
		client._apply_remote_boss_visual_snapshot(packet)
		client._rpc_boss1_team_rewind(event_id, 2)
		_check(client.boss1_rewind_sequence.is_empty() and client.player_hp == 350, "late duplicate replayed the rewind")
	host.boss_stage_timer = 0.4
	client._apply_remote_boss_visual_snapshot(host._pack_net_boss_visuals())
	_check(is_equal_approx(client.boss_stage_timer, 0.4), "client did not receive the slam animation clock")
	seed_rewind(client, Vector2(880, 500))
	client.is_dead = true
	client.player_hp = 0
	client._rpc_boss1_team_rewind("dead-viewer", 0)
	client._update_boss1_rewind_sequence(4.0)
	_check(client.player_hp == 0 and client.is_dead, "shared visual resurrected a dead player")
	for game in [host, client]:
		game._cleanup_runtime_resources()
		game.free()
	for _frame in range(4):
		await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("BOSS1_TEAM_REWIND_OK host_hit=true client_hit=true private_history=true shared_clock=true single_heal=true duplicate=true dead_viewer=true")
	quit(0 if failures.is_empty() else 1)
