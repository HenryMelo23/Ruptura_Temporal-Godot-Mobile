extends SceneTree

## Suturador: Pele de Ambar, Remendo Vivo e Casulo de Ambar. --frames=<dir> grava.
const DT := 1.0 / 60.0
var game: Node
var frames_dir := ""
var seq := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="): frames_dir = a.substr(9)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.startup_thanks_done = true
	game.forced_initial_phase = 6
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
	var ctrl = game.amber_suturer_controller
	var sut: Dictionary = ctrl.spawn_now()
	sut["pos"] = game.player_pos + Vector2(300.0, -30.0)
	var threat: RTSuturerThreatController = ctrl.threat()
	game.amber_suturer_state["battle_elapsed"] = 36.0
	var common: String = game.ENEMY_COMMON
	for i in range(8):
		game._spawn_enemy(common, game.player_pos + Vector2.from_angle(float(i) * TAU / 8.0) * 210.0)
	var revived := 0
	var regen_seen := false
	var cocoon_seen := false
	var elite_seen := false
	var step := 0
	var t := 0.0
	while t < 16.0:
		t += DT
		game.time_alive += DT
		game.elapsed_unpaused += DT
		game.player_hp = 1.0e9
		# Mata alguns comuns no comeco para virar cadaver.
		if absf(t - 1.0) < DT * 0.5 or absf(t - 2.0) < DT * 0.5:
			var killed := 0
			for e in game.enemies:
				if String(e.get("type", "")) == common and not bool(e.get("amber_patched", false)) and killed < 2:
					e["hp"] = 0.0
					killed += 1
		var hp_before: float = float(sut.get("hp", 0.0))
		if not threat.tethers.is_empty():
			sut["hp"] = float(sut["max_hp"]) * 0.6
		ctrl.update(DT)
		game.enemy_manager.update_enemies(DT)
		game._update_enemy_bullets(DT)
		game._update_effects(DT)
		if not threat.tethers.is_empty() and float(sut.get("hp", 0.0)) > float(sut["max_hp"]) * 0.6:
			regen_seen = true
		if not threat.cocoon.is_empty():
			cocoon_seen = true
		for e in game.enemies:
			if bool(e.get("amber_patched", false)) and not e.has("_counted"):
				e["_counted"] = true
				revived += 1
			if bool(e.get("amber_elite", false)):
				elite_seen = true
		step += 1
		if frames_dir != "" and step % 3 == 0:
			game.queue_redraw()
			await process_frame
			var img := root.get_texture().get_image()
			img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
			img.save_png("%s/f_%03d.png" % [frames_dir, seq])
			seq += 1
	var ok := revived > 0 and cocoon_seen and elite_seen
	print("SUTURER_THREAT_%s revived=%d regen=%s cocoon=%s elite=%s frames=%d" % ["OK" if ok else "FAIL", revived, regen_seen, cocoon_seen, elite_seen, seq])
	quit(0 if ok else 1)
