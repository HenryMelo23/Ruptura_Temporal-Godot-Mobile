extends SceneTree

const Probe = preload("res://tests/runtime_render_profile_probe.gd")
const OUT := "res://.codex/runtime_performance/"
const SAMPLE_FRAMES := 30

var game: Node2D
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("RUNTIME_PERFORMANCE_VISUAL requires a renderer")
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
	game.set_process(false)
	game.set_physics_process(false)
	game.mode = "game"
	game.current_phase = 1
	game.player_pos = Vector2(800, 450)
	game.player_hp = game.player_hp_max
	game.is_dead = false
	game.show_fps_counter = false
	game.gfx_low_resource = false
	game.gfx_memory_saver = false
	game.gfx_shadows = true
	game.mobile_adaptive_visual_budget = false
	game.enemies.clear()
	for index in range(96):
		var col := index % 16
		var row := index / 16
		game._spawn_enemy(game.ENEMY_COMMON, Vector2(150.0 + float(col) * 92.0, 140.0 + float(row) * 82.0))
		game.enemies[-1]["speed"] = 0.0
		game.enemies[-1]["damage"] = 0.0
	game.bullets.clear()
	for index in range(72):
		var angle := float(index) * TAU / 72.0
		game.bullets.append(_static_bullet(index, angle))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	var full := await _measure_stage(0, "full")
	var emergency := await _measure_stage(2, "emergency")
	_check(game.runtime_projectile_batch_renderer.active_stage == 0, "Ultra changed projectile texture fidelity during measured emergency")
	_check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS, "Ultra changed native canvas rendering during measured emergency")
	print("RUNTIME_PERFORMANCE_VISUAL_%s full_world_p50_us=%.1f emergency_world_p50_us=%.1f full_projectiles_p50_us=%.1f emergency_projectiles_p50_us=%.1f captures=2" % [
		"FAIL" if failed else "OK",
		full.world_p50_us,
		emergency.world_p50_us,
		full.projectiles_p50_us,
		emergency.projectiles_p50_us,
	])
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _static_bullet(index: int, angle: float) -> Dictionary:
	return {
		"uid": "visual:%d" % index,
		"pos": game.player_pos + Vector2.from_angle(angle) * (90.0 + float(index % 8) * 22.0),
		"origin": game.player_pos,
		"dir": Vector2.from_angle(angle),
		"speed": 0.0,
		"life": 30.0,
		"max_life": 30.0,
		"age": 1.0,
		"phase": angle,
		"damage": 1.0,
		"kind": "eletrica",
		"source_category": "basic_attack",
		"color": Color(0.22, 0.82, 1.0),
	}


func _measure_stage(stage: int, label: String) -> Dictionary:
	game.runtime_performance_controller.force_stage_for_test(stage)
	var world_samples: Array[float] = []
	var projectile_samples: Array[float] = []
	for frame in range(SAMPLE_FRAMES + 5):
		game.queue_redraw()
		await RenderingServer.frame_post_draw
		if frame >= 5:
			world_samples.append(float(game.render_profile_us.get("world", 0)))
			projectile_samples.append(float(game.render_profile_us.get("projectiles", 0)))
		await process_frame
	var image := root.get_texture().get_image()
	var path := OUT + label + ".png"
	_check(image.get_size() == root.size and image.save_png(path) == OK, "invalid %s capture" % label)
	world_samples.sort()
	projectile_samples.sort()
	return {
		"world_p50_us": world_samples[world_samples.size() / 2],
		"projectiles_p50_us": projectile_samples[projectile_samples.size() / 2],
	}


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("RUNTIME_PERFORMANCE_VISUAL_FAIL " + message)
