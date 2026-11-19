extends SceneTree

## Close do pinguim na Nevasca com o movimento real: escondido na nevoa -> sai andando
## da nevasca e se remonta -> cospe -> volta para a neve e se desfaz.
## -- --frames=<dir>
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
	game.current_phase = 2
	game.boss_active = true
	game.boss_ready = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = 6000.0 * 0.39
	game.player_hp_max = 1000
	game.player_hp = 1000
	var center: Vector2 = game.experimental_phase_controller.boss_encounter_center()
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.boss_attacks.clear()
	game._reset_boss2_state()
	game.spawn_timer = 999.0
	game._start_boss2_ultimate()
	var c: Vector2 = game.boss2_ultimate_center
	game.boss2_ultimate_orbit_angle = 0.0
	game.boss_pos = c + Vector2(700, 0)
	var motion = game._boss2_motion()
	motion.reset()
	motion.radius = 700.0
	motion.radius_target = 700.0
	if frames_dir != "":
		DirAccess.make_dir_recursive_absolute(frames_dir)
	var t := 0.0
	var step := 0
	var reveals: Array = []
	while t < 8.6:
		t += DT
		game.time_alive += DT
		game.elapsed_unpaused += DT
		game.boss2_ultimate_wind_active = 0.0
		game.boss2_ultimate_wind_timer = 99.0
		game.boss2_ultimate_timer = 30.0
		# 0-1.2 escondido | 1.2-3.3 sai da neve | 3.3-6.2 volta para a neve | 6.2-8.3 sai de novo
		var cycle: float = t if t < 3.3 else t - 5.0
		if t >= 3.3 and t < 6.2:
			game.boss2_ultimate_spit_timer = 4.5
		elif cycle < 1.2:
			game.boss2_ultimate_spit_timer = 4.5
		else:
			game.boss2_ultimate_spit_timer = maxf(0.01, 2.1 - (cycle - 1.2))
		motion.dash_cd = 99.0
		motion.update_orbit(DT)
		game.player_pos = c + Vector2.from_angle(game.boss2_ultimate_orbit_angle) * 330.0 + Vector2(0, 40)
		game._update_effects(DT)
		step += 1
		if step % 2 == 0:
			game.queue_redraw()
			await process_frame
			reveals.append("%.2f:%d:%d" % [RTBoss2BlizzardPresentation._reveal, int(motion.radius), int(game.boss_pos.distance_to(c))])
			if frames_dir != "":
				var img := root.get_texture().get_image()
				img = img.get_region(Rect2i(240, 90, 960, 540))
				img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
				img.save_png("%s/f_%03d.png" % [frames_dir, seq])
			seq += 1
	print("CENTER ", c, " WORLD ", game.WORLD_SIZE)
	print("BOSS2_DISSOLVE_DEMO frames=%d reveal_samples=%s" % [seq, str(reveals.slice(0, reveals.size(), 12))])
	quit(0)
