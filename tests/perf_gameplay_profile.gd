extends SceneTree

## Benchmark de jogo real: partida em andamento com horda grande, auto-ataque e
## habilidades, medindo tempo por secao (RTFrameProfiler) e monitores do Godot.
## Uso: xvfb-run ... --script res://tests/perf_gameplay_profile.gd -- --manif=eletrica --enemies=150 --seconds=20 --phase=1

var game: Node
var manif := "eletrica"
var enemy_target := 150
var seconds := 20.0
var phase := 1
var frame_ms: Array = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--manif="): manif = a.substr(8)
		elif a.begins_with("--enemies="): enemy_target = int(a.substr(10))
		elif a.begins_with("--seconds="): seconds = float(a.substr(10))
		elif a.begins_with("--phase="): phase = int(a.substr(8))
		elif a.begins_with("--skip="):
			for k in a.substr(7).split(","):
				RTFrameProfiler.skip[k] = true
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	Engine.max_fps = 0
	game.startup_thanks_done = true
	game.unlocked_manifestation_ids[manif] = true
	game._apply_character_identity(game.CHARACTER_GEOVANA)
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i]["key"]) == manif:
			game.selected_manifestation = i
	game.selected_aura = 0
	game.forced_initial_phase = phase
	game.run_tutorial_enabled = false
	game._start_game()
	game.mode = "game"
	game.vol_master = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_hp_max = 1.0e9
	game.player_hp = 1.0e9
	for _w in range(30):
		await process_frame
	RTFrameProfiler.reset()
	RTFrameProfiler.enabled = true
	var elapsed := 0.0
	var last_us := Time.get_ticks_usec()
	var t := 0.0
	var skill_clock := 0.0
	while elapsed < seconds:
		game.run_retry_invulnerability_timer = 99.0
		if game.mode != "game":
			game.mode = "game"
		# Mantem a horda no alvo (inimigos variados da fase).
		var tries := 0
		while game.enemies.size() < enemy_target and tries < 12:
			tries += 1
			game.spawn_timer = 0.0
			game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(randf() * TAU) * randf_range(260.0, 620.0))
		# Movimento em circulo + ataques + habilidades.
		t += 1.0 / 60.0
		game.player_pos = game._clamp_player_world(game.player_pos + Vector2.from_angle(t * 0.8) * 2.4)
		game._try_attack()
		skill_clock += 1.0 / 60.0
		if skill_clock > 2.5:
			skill_clock = 0.0
			game.last_skill_time = -999.0
			game._use_skill(game._nearest_ability_target())
			game.last_secondary_time = -999.0
			if randf() < 0.3:
				game._use_secondary_skill(game._nearest_ability_target())
		await process_frame
		var now_us := Time.get_ticks_usec()
		var dt := float(now_us - last_us) / 1000.0
		last_us = now_us
		frame_ms.append(dt)
		elapsed += dt / 1000.0
	RTFrameProfiler.enabled = false
	frame_ms.sort()
	var n := frame_ms.size()
	var avg := 0.0
	for v in frame_ms:
		avg += float(v)
	avg /= float(maxi(1, n))
	print("PERF_RESULT manif=%s phase=%d enemies=%d frames=%d avg_frame=%.2fms p50=%.2f p95=%.2f p99=%.2f bullets=%d effects=%d particles=%d stage=%d" % [manif, phase, game.enemies.size(), n, avg, frame_ms[n / 2], frame_ms[int(n * 0.95)], frame_ms[int(n * 0.99)], game.bullets.size(), game.effects.size(), (game.particles.size() if "particles" in game else -1), int(game.runtime_performance_controller.stage)])
	print("PERF_MONITORS process=%.2fms objects=%d nodes=%d draw_calls=%d static_mem=%.1fMB" % [Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0])
	for row in RTFrameProfiler.report():
		print("PERF_SECTION %-30s avg=%.3fms peak=%.2fms" % [row["name"], row["avg_ms"], row["peak_ms"]])
	quit(0)
