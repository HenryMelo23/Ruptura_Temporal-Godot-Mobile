extends SceneTree

const Probe = preload("res://tests/runtime_render_profile_probe.gd")
const DEFAULT_DURATION_SECONDS := 300.0
const DEFAULT_ENEMY_COUNT := 12
const BULLET_COUNT := 56
const KILL_INTERVAL := 0.75
const PROFILE_KEYS := [
	"update_total", "enemies", "separation", "bullets", "enemy_bullets", "effects", "weather",
	"draw_total", "world", "enemies_render", "projectiles", "hud",
]

var game: Node2D
var duration_seconds := DEFAULT_DURATION_SECONDS
var enemy_count := DEFAULT_ENEMY_COUNT
var disable_enemy_render := false
var disable_projectile_render := false
var enforce_target := false
var frame_samples: Array[Array] = []
var profile_samples: Array[Dictionary] = []
var draw_counts: Array[int] = []
var stalled_25ms: Array[int] = []


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--duration="):
			duration_seconds = maxf(5.0, float(argument.trim_prefix("--duration=")))
		elif argument.begins_with("--enemy-count="):
			enemy_count = maxi(1, int(argument.trim_prefix("--enemy-count=")))
		elif argument == "--disable-enemy-render":
			disable_enemy_render = true
		elif argument == "--disable-projectile-render":
			disable_projectile_render = true
		elif argument == "--enforce-target":
			enforce_target = true
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


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("SINGLEPLAYER_SUSTAINED_PERFORMANCE requires a renderer")
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	game = Probe.new()
	game.name = "Main"
	var players := Node2D.new()
	players.name = "PlayersContainer"
	game.add_child(players)
	var spawner := MultiplayerSpawner.new()
	spawner.name = "MultiplayerSpawner"
	spawner.spawn_path = NodePath("../PlayersContainer")
	spawner.add_spawnable_scene("res://scenes/Player.tscn")
	game.add_child(spawner)
	root.add_child(game)
	await process_frame
	await process_frame
	_fixture()
	for _frame in range(120):
		await process_frame
	game.profile_runtime = true
	game.skip_enemy_render = disable_enemy_render
	game.skip_projectile_render = disable_projectile_render
	var minute_count := maxi(1, int(ceil(duration_seconds / 60.0)))
	for _minute in range(minute_count):
		frame_samples.append([])
		profile_samples.append({})
		draw_counts.append(0)
		stalled_25ms.append(0)
	var started_usec := Time.get_ticks_usec()
	var previous_frame_usec := started_usec
	var next_kill := KILL_INTERVAL
	var last_draw_serial: int = game.draw_serial
	while float(Time.get_ticks_usec() - started_usec) / 1000000.0 < duration_seconds:
		game.heal_orbs.clear()
		_maintain_load()
		await process_frame
		var now_usec := Time.get_ticks_usec()
		var elapsed := float(now_usec - started_usec) / 1000000.0
		while elapsed >= next_kill and not game.enemies.is_empty():
			var victim: Dictionary = game.enemies[0]
			victim["hp"] = 0.0
			game._kill_enemy(victim)
			next_kill += KILL_INTERVAL
		var minute_index := clampi(int(floor(elapsed / 60.0)), 0, minute_count - 1)
		var frame_ms := float(now_usec - previous_frame_usec) / 1000.0
		previous_frame_usec = now_usec
		frame_samples[minute_index].append(frame_ms)
		if frame_ms >= 25.0:
			stalled_25ms[minute_index] += 1
		_collect_profile(minute_index, game.runtime_profile_us)
		if game.draw_serial != last_draw_serial:
			draw_counts[minute_index] += game.draw_serial - last_draw_serial
			last_draw_serial = game.draw_serial
			var render_values: Dictionary = game.render_profile_us.duplicate()
			if render_values.has("enemies"):
				render_values["enemies_render"] = render_values["enemies"]
			_collect_profile(minute_index, render_values)
	var summaries: Array = []
	var failed := false
	var first_p50 := 0.0
	for minute_index in range(minute_count):
		var samples: Array = frame_samples[minute_index]
		var p50 := _percentile(samples, 0.50)
		var p95 := _percentile(samples, 0.95)
		var average_ms := _average(samples)
		var average_fps := 1000.0 / maxf(average_ms, 0.001)
		var seconds_in_minute := minf(60.0, maxf(0.001, duration_seconds - float(minute_index) * 60.0))
		var draw_hz := float(draw_counts[minute_index]) / seconds_in_minute
		if minute_index == 0:
			first_p50 = p50
		failed = failed or average_fps < 55.0 or draw_hz < 55.0 or p50 > 18.2
		var profile_summary := _profile_summary(profile_samples[minute_index])
		summaries.append({
			"minute": minute_index + 1,
			"frames": samples.size(),
			"avg_fps": snappedf(average_fps, 0.01),
			"draw_hz": snappedf(draw_hz, 0.01),
			"p50_ms": snappedf(p50, 0.01),
			"p95_ms": snappedf(p95, 0.01),
			"max_ms": snappedf(_percentile(samples, 1.0), 0.01),
			"stalls_25ms": stalled_25ms[minute_index],
			"profile_p50_us": profile_summary,
		})
	var last_samples: Array = frame_samples[-1]
	var progressive_drift := _percentile(last_samples, 0.50) - first_p50
	failed = failed or progressive_drift > 1.5
	print("SINGLEPLAYER_SUSTAINED_PERFORMANCE_%s duration=%.1f variant=%s mode=performance enemies=%d bullets=%d kills=%d drift_p50_ms=%.2f minutes=%s" % [
		"TARGET_MISSED" if failed else "OK",
		duration_seconds,
		_variant_name(),
		enemy_count,
		BULLET_COUNT,
		int(game.enemies_killed),
		progressive_drift,
		JSON.stringify(summaries),
	])
	_cleanup(1 if failed and enforce_target else 0)


func _variant_name() -> String:
	if disable_enemy_render:
		return "no_enemy_render"
	if disable_projectile_render:
		return "no_projectile_render"
	return "full_render"


func _fixture() -> void:
	game._start_game()
	game.mode = "game"
	game.is_multiplayer = false
	game.online_connected = false
	game.dedicated_server_mode = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.henry_entry_timer = 0.0
	game.spawn_timer = 999999.0
	game.player_hp_max = 1000000.0
	game.player_hp = game.player_hp_max
	game.run_retry_invulnerability_timer = 999999.0
	game.shop_auto_enabled = false
	game.gfx_fps_limit = 60
	game.gfx_memory_saver = true
	game.gfx_low_resource = true
	game.gfx_particles = false
	game.gfx_shadows = false
	game.gfx_screen_shake = false
	game._apply_graphics_settings()
	game.enemies.clear()
	game.bullets.clear()
	_maintain_load()


func _maintain_load() -> void:
	while game.enemies.size() < enemy_count:
		var index: int = game.enemies.size()
		var angle := float(index) * TAU / float(enemy_count) + float(game.enemies_killed % 13) * 0.09
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(angle) * (220.0 + float(index % 3) * 34.0))
		var enemy: Dictionary = game.enemies[-1]
		enemy["hp"] = 42.0
		enemy["max_hp"] = 42.0
		enemy["speed"] = 46.0
		enemy["damage"] = 0.0
	while game.bullets.size() < BULLET_COUNT:
		game.bullets.append(_bullet(game.bullets.size()))
	if game.bullets.size() > BULLET_COUNT:
		game.bullets.resize(BULLET_COUNT)


func _bullet(index: int) -> Dictionary:
	var angle := float(index) * TAU / float(BULLET_COUNT)
	return {
		"uid": "sustained:%d:%d" % [game.enemies_killed, index],
		"pos": game.player_pos + Vector2.from_angle(angle) * (92.0 + float(index % 6) * 18.0),
		"origin": game.player_pos,
		"dir": Vector2.from_angle(angle + PI * 0.5),
		"speed": 38.0,
		"life": 8.0,
		"max_life": 8.0,
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
		"color": Color(0.22, 0.82, 1.0),
	}


func _collect_profile(minute_index: int, values: Dictionary) -> void:
	var minute: Dictionary = profile_samples[minute_index]
	for key in PROFILE_KEYS:
		if not values.has(key):
			continue
		var samples: Array = minute.get(key, [])
		samples.append(float(values[key]))
		minute[key] = samples
	profile_samples[minute_index] = minute


func _profile_summary(values: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in PROFILE_KEYS:
		var samples: Array = values.get(key, [])
		if samples.is_empty():
			continue
		result[key] = snappedf(_percentile(samples, 0.50), 1.0)
	return result


func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())


func _percentile(values: Array, ratio: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(round(float(sorted.size() - 1) * ratio)), 0, sorted.size() - 1)])
