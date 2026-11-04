extends SceneTree

## Caminhada da pressao: para varios minutos de run, roda o jogo de verdade (spawn, IA, desenho)
## ate a horda encher e mede vivos, desejado, orcamento e custo de CPU por quadro.

var game: Node2D
const DT := 1.0 / 60.0
var MINUTES: Array = [5.0, 15.0, 30.0, 45.0, 60.0, 90.0]


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--minutes="):
			MINUTES = []
			for part in argument.trim_prefix("--minutes=").split(","):
				MINUTES.append(float(part))
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.set_script(load("res://tests/runtime_render_profile_probe.gd"))
	root.add_child(game)
	call_deferred("_run")


func _p(values: Array, q: float) -> int:
	if values.is_empty():
		return 0
	var s := values.duplicate()
	s.sort()
	return int(s[clampi(int(q * float(s.size() - 1)), 0, s.size() - 1)])


func _run() -> void:
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game._start_game()
	game.set_process(false)
	game.set_physics_process(false)
	if game.current_phase != 1:
		game._advance_to_phase(1)
	game.mode = "game"
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.is_multiplayer = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_hp_max = 1.0e9
	game.player_hp = 1.0e9
	game.run_retry_invulnerability_timer = 1.0e9
	game.shop_auto_enabled = false
	game.shop_rift_controller.allow_rift = false
	var horde = game.enemy_manager.horde
	for minutes in MINUTES:
		game.time_alive = minutes * 60.0
		game.phase_started_at = game.time_alive - 300.0
		game.boss_active = false
		var cpu: Array = []
		for frame in range(560):
			game.player_hp = 1.0e9
			game.boss_call_timer = -1.0
			var t0 := Time.get_ticks_usec()
			game._process(DT)
			var t1 := Time.get_ticks_usec()
			game.queue_redraw()
			await process_frame
			if frame >= 400:
				cpu.append(t1 - t0 + int(game.render_profile_us.get("draw_total", 0)))
		var desired: int = game.enemy_manager.get_desired_enemy_limit()
		print("HORDE_WALK min=%d phase=%d live=%d limit=%d desired=%d budget=%d condensed=%.2f cpu_p50_us=%d cpu_p95_us=%d mode=%s stage=%d fps=%.1f enemy_ms=%.2f" % [int(minutes), game.current_phase, game.enemies.size(), game.enemy_manager.get_enemy_limit(), desired, horde.live_budget(), horde.overflow_ratio(desired), _p(cpu, 0.5), _p(cpu, 0.95), game.mode, int(game.runtime_performance_controller.stage), float(game.runtime_performance_controller.smoothed_fps), horde.enemy_cost_ms()])
	game._cleanup_runtime_resources()
	game.free()
	quit(0)
