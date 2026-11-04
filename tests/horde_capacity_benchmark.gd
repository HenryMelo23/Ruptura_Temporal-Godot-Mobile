extends SceneTree

## Mede o custo de CPU (logica + chamadas de desenho) por quantidade de inimigos vivos.
## Uso: godot --headless --path . --script res://tests/horde_capacity_benchmark.gd -- --phase=1 --counts=10,40,80
## Saida: HORDE_BENCH phase=N count=C update_p50_us draw_p50_us total_p95_us

var game: Node2D
var phase := 1
var no_shadows := false
var counts: Array = [10, 30, 60, 100, 160]
const FRAMES := 180
const DT := 1.0 / 60.0


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--phase="):
			phase = int(argument.trim_prefix("--phase="))
		elif argument.begins_with("--counts="):
			counts = []
			for part in argument.trim_prefix("--counts=").split(","):
				counts.append(int(part))
		elif argument == "--no-shadows":
			no_shadows = true
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.set_script(load("res://tests/runtime_render_profile_probe.gd"))
	root.add_child(game)
	call_deferred("_run")


func _fixture() -> void:
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game._start_game()
	game.set_process(false)
	game.set_physics_process(false)
	if game.current_phase != phase:
		game._advance_to_phase(phase)
	print("HORDE_PHASE current=", game.current_phase)
	game.mode = "game"
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.is_multiplayer = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.spawn_timer = 999999.0
	game.player_hp_max = 1000000.0
	game.player_hp = game.player_hp_max
	game.run_retry_invulnerability_timer = 999999.0
	game.shop_auto_enabled = false
	game.shop_rift_controller.allow_rift = false
	game.enemies.clear()
	if no_shadows:
		game.gfx_shadows = false
		game._apply_graphics_settings()


func _fill(count: int) -> void:
	var guard := 0
	while game.enemies.size() < count and guard < count * 4:
		guard += 1
		var kind: String = game._choose_enemy_type()
		var angle := randf() * TAU
		game._spawn_enemy(kind, game.player_pos + Vector2.from_angle(angle) * randf_range(260.0, 620.0))
	for enemy in game.enemies:
		enemy["hp"] = 1.0e9
		enemy["max_hp"] = 1.0e9


func _percentile(values: Array, p: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(floor(p * float(sorted.size() - 1))), 0, sorted.size() - 1)])


func _run() -> void:
	_fixture()
	for count in counts:
		game.enemies.clear()
		game.bullets.clear()
		game.enemy_bullets.clear()
		_fill(int(count))
		var updates: Array = []
		var totals: Array = []
		var draws: Array = []
		var enemy_draws: Array = []
		var parts: Dictionary = {}
		game.profile_runtime = true
		for frame in range(FRAMES):
			_fill(int(count))
			game.player_hp = game.player_hp_max
			var t0 := Time.get_ticks_usec()
			game._process(DT)
			var t1 := Time.get_ticks_usec()
			game.queue_redraw()
			await process_frame
			var t2 := Time.get_ticks_usec()
			if frame >= 30:
				updates.append(t1 - t0)
				totals.append(t2 - t0)
				draws.append(int(game.render_profile_us.get("draw_total", 0)))
				enemy_draws.append(int(game.render_profile_us.get("enemies", 0)))
				for key in game.runtime_profile_us.keys():
					if not parts.has(key):
						parts[key] = []
					parts[key].append(int(game.runtime_profile_us[key]))
		var kinds: Dictionary = {}
		for e in game.enemies:
			kinds[String(e.get("type", ""))] = int(kinds.get(String(e.get("type", "")), 0)) + 1
		print("HORDE_KINDS ", kinds)
		var part_line := ""
		for key in parts.keys():
			part_line += "%s=%d " % [key, int(_percentile(parts[key], 0.5))]
		print("HORDE_PARTS ", part_line)
		print("HORDE_BENCH phase=%d count=%d live=%d update_p50_us=%d update_p95_us=%d draw_p50_us=%d draw_p95_us=%d enemy_draw_p50_us=%d" % [phase, int(count), game.enemies.size(), int(_percentile(updates, 0.5)), int(_percentile(updates, 0.95)), int(_percentile(draws, 0.5)), int(_percentile(draws, 0.95)), int(_percentile(enemy_draws, 0.5))])
	game._cleanup_runtime_resources()
	game.free()
	quit(0)
