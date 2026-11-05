extends SceneTree

## Luta real do Boss 2 (Sentinela Pinguim) para avaliar habilidades e a nevasca.
## -- --mode=normal|ultimate [--frames=<dir>] [--seconds=N]
## Imprime as habilidades vistas, dano recebido e o quanto o boss ficou visivel.
const DT := 1.0 / 60.0
var game: Node
var frames_dir := ""
var mode := "normal"
var seconds := 20.0
var seq := 0


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="): frames_dir = a.substr(9)
		elif a.begins_with("--mode="): mode = a.substr(7)
		elif a.begins_with("--seconds="): seconds = float(a.substr(10))
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
	game.boss_hp = 6000.0 * (0.39 if mode == "ultimate" else 0.85)
	game.player_hp_max = 1000
	game.player_hp = 1000
	var center: Vector2 = game.experimental_phase_controller.boss_encounter_center()
	game.player_pos = center + Vector2(-60, 40)
	game.boss_pos = center + Vector2(360, -40)
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.boss_attacks.clear()
	game._reset_boss2_state()
	game.spawn_timer = 999.0
	if mode == "ultimate":
		game._start_boss2_ultimate()
	if frames_dir != "":
		DirAccess.make_dir_recursive_absolute(frames_dir)
	var seen: Dictionary = {}
	var visible_frames := 0
	var frames := 0
	var hp_lost := 0.0
	var step := 0
	var t := 0.0
	var start: Vector2 = game.player_pos
	var boss_path: Array = []
	while t < seconds:
		t += DT
		game.time_alive += DT
		game.elapsed_unpaused += DT
		var before: float = float(game.player_hp)
		if game.player_hp < 250:
			game.player_hp = 1000
		game.player_pos = game._clamp_player_world(start + Vector2.from_angle(t * 0.55) * Vector2(230.0, 150.0))
		game.player_shove.update(game, DT)
		game._update_boss(DT)
		game._update_enemy_bullets(DT)
		game._update_effects(DT)
		hp_lost += maxf(0.0, before - float(game.player_hp))
		seen[String(game.boss2_state).replace("boss2_", "")] = true
		for atk in game.boss_attacks:
			seen["atk:" + String(atk.get("kind", ""))] = true
		frames += 1
		if game._boss2_ultimate_boss_visible():
			visible_frames += 1
		if step % 30 == 0:
			boss_path.append(game.boss_pos)
		step += 1
		if frames_dir != "" and step % 3 == 0:
			game.queue_redraw()
			await process_frame
			var img := root.get_texture().get_image()
			img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
			img.save_png("%s/f_%03d.png" % [frames_dir, seq])
			seq += 1
	# Quao "previsivel": variacao de direcao entre amostras de posicao do boss.
	var turns := 0.0
	for i in range(2, boss_path.size()):
		var a: Vector2 = Vector2(boss_path[i - 1]) - Vector2(boss_path[i - 2])
		var b: Vector2 = Vector2(boss_path[i]) - Vector2(boss_path[i - 1])
		if a.length() > 2.0 and b.length() > 2.0:
			turns += absf(a.angle_to(b))
	print("BOSS2_DEMO mode=%s seen=%s hp_lost=%d boss_visible=%.0f%% turn_sum=%.1f frames=%d" % [mode, str(seen.keys()), int(hp_lost), 100.0 * float(visible_frames) / float(maxi(1, frames)), turns, seq])
	quit(0)
