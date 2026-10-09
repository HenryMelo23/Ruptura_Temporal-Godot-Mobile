extends SceneTree

const Visual = preload("res://scripts/presentation/boss3_miasma_presentation.gd")
var failed := false


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("MIASMA_PRESENTATION_CONTRACT_FAIL " + message)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host = load("res://scenes/Main.tscn").instantiate()
	var client = load("res://scenes/Main.tscn").instantiate()
	root.add_child(host)
	root.add_child(client)
	for game in [host, client]:
		game.set_process(false)
		game.set_physics_process(false)
		game.current_phase = 3
		game.boss_active = true
		game.boss_hp = 8000.0
		game.boss_hp_max = 8000.0
		game.player_hp = 450
		game.is_multiplayer = true
	host.online_room_owner = true
	client.online_room_owner = false
	host.is_host = true
	client.is_host = false
	_check(host.BOSS3_MIASMA_VALID_VARIANTS == [1, 2, 4], "variant contract changed")
	for variant in [1, 2, 4]:
		host._end_boss3_miasma(true)
		host._start_boss3_miasma(variant)
		client._apply_remote_boss_visual_snapshot(host._pack_net_boss_visuals())
		_check(client.boss3_miasma_variant == variant, "replica variant mismatch")
		_check(client.boss3_miasma_clone_positions == host.boss3_miasma_clone_positions, "clone positions mismatch")
	# Compare the real runtime's contact decision against rendering from the
	# existing wire fields, including exact boundaries, progress and overtime.
	for taps in [0, 9, 17]:
		for elapsed in [0.01, 0.179, 0.18, 0.22, 1.5, 1.69, 2.7, 7.1, 8.0]:
			host.boss3_miasma_qte_taps = taps
			host.boss3_miasma_qte_elapsed = elapsed
			host.boss3_miasma_qte_lids_touching = false
			host._update_boss3_miasma_qte(0.0)
			client._apply_remote_boss_visual_snapshot(host._pack_net_boss_visuals())
			var rng_before: int = client.rng.state
			var hp_before: int = client.player_hp
			var openness := Visual.qte_openness(client)
			_check(is_equal_approx(openness, Visual.qte_openness(host)), "host/replica lid disagreement at %.3f/%d" % [elapsed, taps])
			_check(not host.boss3_miasma_qte_lids_touching or openness == 0, "contact shown open")
			_check(is_equal_approx(openness, Visual.qte_openness(client)), "frozen snapshot animated its own clock")
			_check(client.rng.state == rng_before and client.player_hp == hp_before, "presentation mutated gameplay")
	# Every boundary point and chord must stay inside the functional vision disk.
	for t in [0.0, 0.1, 1.5, 15.0, 200.0]:
		for i in range(720):
			var boundary := Visual.darkness_boundary(i * TAU / 720, 250, t)
			_check(boundary.length() <= 250.0, "darkness leaked outside functional radius")
	host._end_boss3_miasma(true)
	client._apply_remote_boss_visual_snapshot(host._pack_net_boss_visuals())
	_check(not client._boss3_miasma_active(), "replica did not clear miasma")
	for reason in ["phase", "boss_dead", "player_dead", "spectator", "elapsed"]:
		client.current_phase = 4 if reason == "phase" else 3
		client.boss_hp = 0 if reason == "boss_dead" else 8000
		client.player_hp = 0 if reason == "player_dead" else 450
		client.online_local_spectator = reason == "spectator"
		client.set_meta(Visual.RESIDUE_META, client.time_alive - (1.0 if reason == "elapsed" else 0.0))
		Visual.overlay(client, Vector2(1280, 720), Vector2.ZERO)
		_check(not client.has_meta(Visual.RESIDUE_META), reason + " retained visual residue")
	for game in [host, client]:
		game._cleanup_runtime_resources()
		game.textures.clear()
		game.audio_streams.clear()
		game.free()
	await process_frame
	await create_timer(0.2).timeout
	if not failed:
		print("MIASMA_PRESENTATION_CONTRACT_OK snapshots=1,2,4 blink_cases=27 radius_samples=3600 rng_unchanged=true cleanup=true")
	quit(1 if failed else 0)
