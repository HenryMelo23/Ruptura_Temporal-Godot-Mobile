extends SceneTree

const SAMPLE_FRAMES := 180
const WARMUP_FRAMES := 90

var game: Node
var preset := "high"
# Mirrors the largest supported late-run crowd/projectile envelope. Larger
# values remain available through command-line overrides as a torture profile.
var enemy_fixture_count := 16
var bullet_fixture_count := 56
var hide_hud := false


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--preset="):
			preset = argument.trim_prefix("--preset=")
		elif argument.begins_with("--enemy-count="):
			enemy_fixture_count = maxi(0, int(argument.trim_prefix("--enemy-count=")))
		elif argument.begins_with("--bullet-count="):
			bullet_fixture_count = maxi(0, int(argument.trim_prefix("--bullet-count=")))
		elif argument == "--no-hud":
			hide_hud = true
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _cleanup(code := 0) -> void:
	if game != null:
		game.mode = "menu"
		game.visible = false
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)


func _static_bullet(index: int) -> Dictionary:
	var angle := float(index) * TAU / 72.0
	return {
		"uid": "render:%d" % index,
		"pos": game.player_pos + Vector2.from_angle(angle) * (90.0 + float(index % 5) * 12.0),
		"origin": game.player_pos,
		"dir": Vector2.ZERO,
		"speed": 0.0,
		"life": 30.0,
		"max_life": 30.0,
		"age": 0.0,
		"phase": angle,
		"trail_cd": 100.0,
		"damage": 1.0,
		"player_damage": 1.0,
		"kind": "eletrica",
		"source_category": "basic_attack",
		"pierce": true,
		"hits": {},
		"ricochets": 0,
		"durability": 0.0,
		"fly_sfx_cd": 100.0,
		"color": Color(0.22, 0.82, 1.0)
	}


func _percentile(sorted_values: Array[float], ratio: float) -> float:
	return sorted_values[clampi(int(round(float(sorted_values.size() - 1) * ratio)), 0, sorted_values.size() - 1)]


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.is_multiplayer = false
	game.online_connected = false
	game.dedicated_server_mode = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.henry_entry_timer = 0.0
	game.spawn_timer = 9999.0
	game.player_hp_max = 1000000.0
	game.player_hp = game.player_hp_max
	game.gfx_fps_limit = 50
	game.gfx_memory_saver = false
	game.gfx_low_resource = preset == "low"
	game.gfx_particles = true
	game.gfx_shadows = preset != "low"
	game._apply_graphics_settings()
	game.preview_capture_mode = hide_hud

	game.enemies.clear()
	for index in enemy_fixture_count:
		var col := index % 16
		var row := index / 16
		var position := Vector2(280.0 + float(col) * 88.0, 180.0 + float(row) * 92.0)
		game._spawn_enemy(game.ENEMY_COMMON, position)
		game.enemies[-1]["speed"] = 0.0
		game.enemies[-1]["damage"] = 0.0
	for index in bullet_fixture_count:
		game.bullets.append(_static_bullet(index))

	for _frame in WARMUP_FRAMES:
		await process_frame
	game.interrupted_run_autosave_timer = 0.5
	var samples: Array[float] = []
	var spikes := 0
	for _frame in SAMPLE_FRAMES:
		var started := Time.get_ticks_usec()
		await process_frame
		var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
		samples.append(elapsed_ms)
		if elapsed_ms >= 35.0:
			spikes += 1
	samples.sort()
	var p50 := _percentile(samples, 0.50)
	var p95 := _percentile(samples, 0.95)
	var worst := samples[-1]
	var enemy_count: int = game.enemies.size()
	var bullet_count: int = game.bullets.size()
	var failed := p95 >= 35.0 or spikes > 4
	if failed:
		printerr("SINGLEPLAYER_RENDERED_FRAME_PACING_FAIL preset=%s p50_ms=%.2f p95_ms=%.2f max_ms=%.2f stalls_35ms=%d enemies=%d bullets=%d draw_calls=%d" % [preset, p50, p95, worst, spikes, enemy_count, bullet_count, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))])
	else:
		print("SINGLEPLAYER_RENDERED_FRAME_PACING_OK preset=%s p50_ms=%.2f p95_ms=%.2f max_ms=%.2f stalls_35ms=%d enemies=%d bullets=%d draw_calls=%d" % [preset, p50, p95, worst, spikes, enemy_count, bullet_count, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))])
	_cleanup(1 if failed else 0)
