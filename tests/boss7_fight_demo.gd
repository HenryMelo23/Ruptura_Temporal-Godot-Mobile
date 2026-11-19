extends SceneTree

## Luta real da Fenix (Boss 7) para avaliar animacao, mecanica e VFX.
## -- [--frames=<dir>] [--seconds=N] [--hp=0.85] [--force=<ataque>]
const DT := 1.0 / 60.0
var game: Node
var frames_dir := ""
var seconds := 20.0
var hp_ratio := 0.85
var force := ""
var seq := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="): frames_dir = a.substr(9)
		elif a.begins_with("--seconds="): seconds = float(a.substr(10))
		elif a.begins_with("--hp="): hp_ratio = float(a.substr(5))
		elif a.begins_with("--force="): force = a.substr(8)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game.forced_initial_phase = 7
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.current_phase = 7
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.boss_attacks.clear()
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.time_alive = game.BOSS_READY_TIME + 0.01
	game.player_pos = game.experimental_phase_controller.boss_encounter_center() + Vector2(0, 120)
	game.boss_ready = true
	game._start_boss_call_local()
	game.boss_call_timer = 0.01
	game._update_boss_call(0.02)
	game.boss_hp = game.boss_hp_max * hp_ratio
	print("ARENA ", game.experimental_phase_controller.boss_encounter_rect(), " boss=", game.boss_pos, " player=", game.player_pos)
	game.spawn_timer = 999.0
	if frames_dir != "":
		DirAccess.make_dir_recursive_absolute(frames_dir)
	var seen: Dictionary = {}
	var hp_lost := 0.0
	var t := 0.0
	var step := 0
	var start: Vector2 = game.player_pos
	while t < seconds:
		t += DT
		game.time_alive += DT
		game.elapsed_unpaused += DT
		var before: float = float(game.player_hp)
		if game.player_hp < 250:
			game.player_hp = 1000
		game.player_pos = game._clamp_player_world(start + Vector2.from_angle(t * 0.6) * Vector2(220.0, 140.0))
		game.player_shove.update(game, DT)
		if force != "" and String(game.boss7_state) == game.BOSS7_STATE_FLY and game.boss_attack_timer > 0.3:
			game.boss_attack_timer = 0.2
		game._update_boss(DT)
		game._update_enemy_bullets(DT)
		game._update_effects(DT)
		hp_lost += maxf(0.0, before - float(game.player_hp))
		seen[String(game.boss7_state)] = true
		for atk in game.boss_attacks:
			seen["atk:" + String(atk.get("kind", "")).replace("boss7_", "")] = true
		step += 1
		if frames_dir != "" and step % 3 == 0:
			game.queue_redraw()
			await process_frame
			var img := root.get_texture().get_image()
			img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
			img.save_png("%s/f_%03d.png" % [frames_dir, seq])
			seq += 1
	print("BOSS7_DEMO seen=%s hp_lost=%d frames=%d" % [str(seen.keys()), int(hp_lost), seq])
	quit(0)
