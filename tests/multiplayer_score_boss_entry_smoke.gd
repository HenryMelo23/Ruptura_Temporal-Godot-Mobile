extends SceneTree

var failures: Array[String] = []
var capture_tag := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_tag = arg.trim_prefix("--capture=")
	root.size = Vector2i(1280, 720)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var host = load("res://scenes/Main.tscn").instantiate()
	var client = load("res://scenes/Main.tscn").instantiate()
	root.add_child(host)
	root.add_child(client)
	host.set_process(false)
	client.set_process(false)
	host.hide()
	host.is_multiplayer = true
	host.is_host = true
	client.is_multiplayer = true
	client.is_host = false
	client.online_room_owner = false
	client.score = 0
	client.score_total = 0
	client.run_points_earned = 0
	client.run_points_spent = 0
	client._apply_score_delta(40, true, "client-request")
	_check(client.score == 0, "client credited an unconfirmed local reward")
	client._rpc_add_score(40, "client-request")
	client._rpc_add_score(60, "host-kill")
	client._rpc_add_score(60, "host-kill")
	_check(client.score == 100 and client.score_total == 100 and client.run_points_earned == 100, "client did not credit confirmed rewards exactly once")
	client.score -= 20
	client.run_points_spent += 20
	client._rpc_add_score(30, "next-kill")
	_check(client.score == 110 and client.run_points_earned == 130 and client.run_points_spent == 20, "next reward overwrote the individual balance")
	var expected_names := {
		1: "CARANGUEJO COSMICO GIGANTE",
		2: "SENTINELA GLACIAL",
		3: "PAI-RATO",
		4: "NEXO DA RUPTURA",
		5: "UMBRA",
		6: "MATRIARCA DA CHAGA",
		7: "FENIX"
	}
	for phase in range(1, 8):
		for game in [host, client]:
			game._prepare_phase_texture_assets(phase)
		host.current_phase = phase
		host.mode = "game"
		host.boss_ready = true
		host.boss_active = false
		host.boss_dead = false
		host.boss_call_timer = -1.0
		host._start_boss_call_local()
		host._update_boss_call(host.BOSS_CALL_COUNTDOWN + 0.01)
		client.current_phase = maxi(1, phase - 1)
		client.mode = "game"
		client.boss_active = false
		client.boss_dead = false
		client.boss_pos = Vector2(-500, -500)
		var entry_time: float = host.boss_entry_timer
		client.boss_name = "STALE CLIENT BOSS"
		for remaining in [entry_time, entry_time * 0.5, 0.0]:
			host.boss_entry_timer = remaining
			host.boss_pos = host.WORLD_SIZE * 0.5
			client._apply_remote_boss_snapshot(host._pack_net_boss(), Time.get_ticks_msec())
			client._apply_remote_boss_visual_snapshot(host._pack_net_boss_visuals())
			_check(is_equal_approx(client.boss_entry_timer, remaining), "phase %d entry timer stuck: expected %.2f got %.2f" % [phase, remaining, client.boss_entry_timer])
			_check(client.current_phase == phase and client.boss_active, "phase %d boss identity was not restored on the replica" % phase)
			_check(String(client.boss_name) == String(expected_names[phase]), "phase %d boss name diverged on the replica" % phase)
		if phase == 6:
			_check(host.boss6_entry_particles.size() == host.BOSS6_ENTRY_PARTICLES, "phase 6 authority did not build the complete entry VFX")
			_check(client.boss6_entry_particles.size() == host.BOSS6_ENTRY_PARTICLES, "phase 6 replica did not rebuild the complete seeded entry VFX")
			_check(client.boss6_entry_particle_seed == host.boss6_entry_particle_seed, "phase 6 entry VFX seed diverged")
			_check(Dictionary(client.boss6_entry_particles[0]).get("start") == Dictionary(host.boss6_entry_particles[0]).get("start"), "phase 6 seeded entry trajectory diverged")
		if capture_tag != "":
			_check(client._boss_texture() != null, "phase %d replica boss texture was not resident" % phase)
			client.player_pos = client.WORLD_SIZE * 0.5 + Vector2(280, 150)
			client.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var screenshot := root.get_texture().get_image()
			_check(screenshot.save_png("res://.agent_logs/multiplayer_boss_phase_%d_%s.png" % [phase, capture_tag]) == OK, "phase %d screenshot failed" % phase)
		# Older visual packets must not preserve an entry overlay forever.
		client.boss_entry_timer = entry_time
		var legacy: Dictionary = host._pack_net_boss_visuals()
		legacy.erase("boss_entry_timer")
		client._apply_remote_boss_visual_snapshot(legacy)
		_check(client.boss_entry_timer == 0.0, "legacy packet left the boss entry overlay active")
	for game in [host, client]:
		game._cleanup_runtime_resources()
		game.free()
	for _frame in range(4):
		await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("MULTIPLAYER_SCORE_BOSS_ENTRY_OK confirmed_credit=true dedup=true individual_balance=true boss_entry_phases=7 names=true seeded_boss6_vfx=true legacy=true")
	quit(0 if failures.is_empty() else 1)
