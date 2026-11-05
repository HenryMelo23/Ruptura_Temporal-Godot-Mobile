extends SceneTree

## Demonstracao/checagem do Sineiro Boreal (fase 2). --frames=<dir> grava a ~20 fps.
## --seconds=N duracao da luta. Imprime estados e ataques vistos.
const DT := 1.0 / 60.0
var game: Node
var frames_dir := ""
var seconds := 14.0
var seq := 0
var ring_only := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="): frames_dir = a.substr(9)
		elif a.begins_with("--seconds="): seconds = float(a.substr(10))
		elif a == "--ring": ring_only = true
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.startup_thanks_done = true
	game.forced_initial_phase = 2
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_hp_max = 1.0e9
	game.player_hp = 1.0e9
	game.run_retry_invulnerability_timer = 999.0
	game.enemies.clear()
	game.spawn_timer = 999.0
	if frames_dir != "":
		DirAccess.make_dir_recursive_absolute(frames_dir)
	var ctrl = game.sineiro_boreal_controller
	var enemy: Dictionary = ctrl.spawn_now()
	if not enemy.is_empty() and float(enemy["pos"].distance_to(game.player_pos)) > 700.0:
		enemy["pos"] = game.player_pos + Vector2(520.0, -40.0)
	var seen: Dictionary = {}
	var step := 0
	if ring_only and not enemy.is_empty():
		enemy["pos"] = game.player_pos + Vector2(-160.0, 20.0)
		enemy["sineiro_state"] = "position"
		enemy["sineiro_echo_cd"] = 99.0
		enemy["sineiro_call_cd"] = 99.0
		enemy["sineiro_ring_cd"] = 0.0
		enemy["sineiro_action_cd"] = 0.0
		seconds = 2.4
	var t := 0.0
	var center: Vector2 = game.player_pos
	while t < seconds:
		t += DT
		game.time_alive += DT
		game.elapsed_unpaused += DT
		if not ring_only:
			game.player_pos = game._clamp_player_world(center + Vector2.from_angle(t * 0.7) * Vector2(220.0, 140.0))
		ctrl.update(DT)
		game.enemy_manager.update_enemies(DT)
		game._update_enemy_bullets(DT)
		game._update_effects(DT)
		var e: Dictionary = ctrl.active_enemy()
		if not e.is_empty():
			seen[String(e.get("sineiro_state", ""))] = true
			if String(e.get("sineiro_attack_kind", "")) != "":
				seen["atk:" + String(e.get("sineiro_attack_kind", ""))] = true
		step += 1
		if frames_dir != "" and step % 3 == 0:
			game.queue_redraw()
			await process_frame
			var img := root.get_texture().get_image()
			img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
			img.save_png("%s/f_%03d.png" % [frames_dir, seq])
			seq += 1
	if ring_only:
		print("SINEIRO_RING_DEMO seen=%s frames=%d" % [str(seen.keys()), seq])
		quit(0)
		return
	# Fuga: o jogador dispara para longe e o Dobre de Chamada tem que traze-lo de volta.
	var e2: Dictionary = ctrl.active_enemy()
	if not e2.is_empty():
		e2["sineiro_call_cd"] = 0.0
		var fled := false
		for k in range(int(4.0 / DT)):
			game.time_alive += DT
			game.player_pos = game._clamp_player_world(game.player_pos + Vector2(1, 0.3).normalized() * 520.0 * DT)
			ctrl.update(DT)
			game.enemy_manager.update_enemies(DT)
			game._update_enemy_bullets(DT)
			var st := String(e2.get("sineiro_attack_kind", ""))
			if st != "":
				seen["atk:" + st] = true
			step += 1
			if frames_dir != "" and step % 3 == 0:
				game.queue_redraw()
				await process_frame
				var img2 := root.get_texture().get_image()
				img2.resize(640, 360, Image.INTERPOLATE_BILINEAR)
				img2.save_png("%s/f_%03d.png" % [frames_dir, seq])
				seq += 1
		seen["final_distance_%d" % int(Vector2(e2["pos"]).distance_to(game.player_pos))] = true
	var ok: bool = seen.has("atk:dobre_glacial") and seen.has("atk:dobre_de_chamada") and seen.has("atk:badalada_passado") and seen.has("atk:estilhacos_ressonantes")
	print("SINEIRO_DEMO_%s seen=%s frames=%d" % ["OK" if ok else "FAIL", str(seen.keys()), seq])
	quit(0)
