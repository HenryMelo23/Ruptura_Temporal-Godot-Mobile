extends SceneTree

## Arautos com as mecanicas novas. -- --variant=condutor|aguilhao [--frames=<dir>] [--seconds=N]
## Checa se todas as habilidades novas aconteceram e se tiram vida do jogador.
const DT := 1.0 / 60.0
var game: Node
var frames_dir := ""
var variant := "condutor"
var seconds := 24.0
var seq := 0
var baseline := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="): frames_dir = a.substr(9)
		elif a.begins_with("--variant="): variant = a.substr(10)
		elif a.begins_with("--seconds="): seconds = float(a.substr(10))
		elif a == "--baseline": baseline = true
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.startup_thanks_done = true
	game.forced_initial_phase = 6 if variant == "aguilhao" else 1
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.enemies.clear()
	game.spawn_timer = 999.0
	if frames_dir != "":
		DirAccess.make_dir_recursive_absolute(frames_dir)
	game._spawn_arauto()
	game.arauto["entry_timer"] = 0.0
	game.arauto["hp"] = float(game.arauto["max_hp"]) * 0.45
	var ctrl: RTArautoThreatController = game._arauto_threat()
	var seen: Dictionary = {}
	var hp_lost := 0.0
	var by_bucket: Dictionary = {}
	var step := 0
	var t := 0.0
	var center: Vector2 = game.player_pos
	while t < seconds:
		t += DT
		game.time_alive += DT
		game.elapsed_unpaused += DT
		var before_hp: float = float(game.player_hp)
		if game.player_hp < 200:
			game.player_hp = 1000
		var move := Vector2.from_angle(t * 0.6) * Vector2(240.0, 150.0)
		game.player_pos = game._clamp_player_world(center + move)
		game.player_shove.update(game, DT)
		if baseline:
			for key in ctrl._cds.keys():
				ctrl._cds[key] = 999.0
		game.player_silence_timer = maxf(0.0, float(game.player_silence_timer) - DT)
		game.boss_wave_slow_timer = maxf(0.0, float(game.boss_wave_slow_timer) - DT)
		game._update_arauto(DT)
		game.enemy_manager.update_enemies(DT)
		game._update_enemy_bullets(DT)
		game._update_effects(DT)
		var lost: float = maxf(0.0, before_hp - float(game.player_hp))
		hp_lost += lost
		var bucket: String = String(ctrl.ability.get("kind", "base"))
		if bucket == "base" and not ctrl.inversion.is_empty():
			bucket = "inversion"
		if lost > 0.0:
			by_bucket[bucket] = int(by_bucket.get(bucket, 0)) + int(lost)
		var k: String = String(ctrl.ability.get("kind", ""))
		if k != "":
			seen[k] = true
		if not ctrl.inversion.is_empty():
			seen["inversion"] = true
		if not ctrl.stings.is_empty():
			seen["sting"] = true
		if not ctrl.venom_stacks.is_empty():
			seen["venom"] = true
		if int(game.arauto.get("ricochet_left", 3)) < 3 and String(game.arauto.get("state", "")) in ["charge", "charge_windup"]:
			seen["ricochet"] = true
		if false and step % 120 == 0:
			print("DBG t=%.1f cds=%s dist=%.0f gaze=%s sil=%s ab=%s" % [t, str(ctrl._cds), Vector2(game.arauto["pos"]).distance_to(game.player_pos), game.arauto.get("gaze_active"), game.arauto.get("silence_active"), k])
		if not game._arauto_active():
			break
		step += 1
		if frames_dir != "" and step % 3 == 0:
			game.queue_redraw()
			await process_frame
			var img := root.get_texture().get_image()
			img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
			img.save_png("%s/f_%03d.png" % [frames_dir, seq])
			seq += 1
	var need: Array = ["choir", "prism", "hush", "inversion"] if variant != "aguilhao" else ["shell", "sting", "venom", "ricochet"]
	var ok := true
	for n in need:
		if not seen.has(n):
			ok = false
	print("ARAUTO_BUCKETS ", by_bucket)
	print("ARAUTO_THREAT_%s variant=%s seen=%s hp_lost=%d frames=%d" % ["OK" if ok else "FAIL", variant, str(seen.keys()), int(hp_lost), seq])
	quit(0 if ok else 1)
