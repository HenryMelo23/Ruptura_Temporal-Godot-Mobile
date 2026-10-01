extends SceneTree

# Same deterministic render workload before/after. No gameplay simulation is timed.
# Run with Mobile/Vulkan, --disable-vsync, and -- --label=before (or after).
var game: Node2D
var label := "after"
var only: PackedStringArray = []
var results: Array = []
const OUT := "res://.codex/gravitante_vfx/"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):
			label = arg.trim_prefix("--label=")
		elif arg.begins_with("--only="):
			only = arg.trim_prefix("--only=").split(",")
	call_deferred("_run")

func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.current_phase = 1 # _start_game can randomize the starting phase from local progression.
	game.set_process(false)
	game.set_physics_process(false)
	game.manifestation_key = "gravitante"
	game.player_pos = Vector2(800, 600)
	game.mode = "game"
	game.boss_active = false
	game.boss_dead = true
	game.gfx_screen_shake = false
	Engine.max_fps = 0
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for quality in ["HIGH", "MEDIUM", "LOW", "MEMORY"]:
		game.gfx_low_resource = quality == "LOW"
		game.gfx_memory_saver = quality == "MEMORY"
		game.mobile_adaptive_visual_budget = quality == "MEDIUM"
		game.gfx_particles = quality == "HIGH"
		for scenario in range(6):
			if not only.is_empty() and not ("%s:%d" % [quality, scenario]) in only:
				continue
			_setup(scenario)
			var times: Array[float] = []
			var calls: Array[float] = []
			for frame in range(100):
				game.time_alive = 15.0 + frame / 60.0
				for i in range(game.orbitals.size()):
					game.orbitals[i]["angle"] = frame / 60.0 * 5.5 + i * 2.399
				var start := Time.get_ticks_usec()
				game.queue_redraw()
				await RenderingServer.frame_post_draw
				if frame >= 20:
					times.append((Time.get_ticks_usec() - start) / 1000.0)
					calls.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
				await process_frame
			times.sort()
			var mean := _mean(times)
			results.append({"quality": quality, "scenario": scenario, "mean_ms": mean,
				"p95_ms": times[int(times.size() * 0.95)], "fps_equivalent": 1000.0 / mean,
				"draw_calls": _mean(calls), "enemies": game.enemies.size(),
				"orbitals": game.orbitals.size(), "effects": game.effects.size(),
				"secondaries": game.manifestation_secondaries.size(), "bullets": game.bullets.size(),
				"phase": game.current_phase})
			if scenario == 3 or scenario == 5:
				var capture := root.get_texture().get_image()
				if capture == null or capture.get_size() != Vector2i(1280, 720):
					push_error("Invalid rendered benchmark capture")
					quit(1)
					return
				capture.save_png(OUT + "%s_%s_%d.png" % [label, quality, scenario])
	var file := FileAccess.open(OUT + label + "_performance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"label": label, "renderer": RenderingServer.get_current_rendering_method(),
		"device": RenderingServer.get_video_adapter_name(), "metric": "CPU submission + frame_post_draw wall time; not GPU time or gameplay FPS", "results": results}, "\t"))
	file.close()
	print("GRAVITANTE_PERFORMANCE_OK label=%s scenarios=%d" % [label, results.size()])
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	game.free()
	await process_frame
	quit()

func _mean(values: Array[float]) -> float:
	var sum := 0.0
	for value in values:
		sum += value
	return sum / max(1, values.size())

func _setup(scenario: int) -> void:
	game.rng.seed = 75031
	game.enemies.clear()
	game.orbitals.clear()
	game.effects.clear()
	game.slashes.clear()
	game.shockwaves.clear()
	game.tp_effects.clear()
	if "gravitante_vfx_events" in game:
		game.gravitante_vfx_events.clear()
	game.bullets.clear()
	game.manifestation_secondaries.clear()
	game._reset_manifest_evolution_state()
	if game.vfx_director:
		for property in ["hit_flashes", "squash_stretch", "impact_sparks", "impact_rings", "floor_cracks", "card_burns", "ground_scorches", "sky_lightning_bolts"]:
			game.vfx_director.get(property).clear()
	game.boss_active = scenario == 4
	game.boss_dead = not game.boss_active
	game.boss_hp = 10000.0
	game.boss_hp_max = 10000.0
	game.boss_pos = Vector2(1040, 410)
	var count: int = [20, 60, 120, 120, 20, 100][scenario]
	var orbital_count: int = [5, 20, 60, 60, 20, 60][scenario]
	for i in range(count):
		var point := Vector2(800, 450) + Vector2.from_angle(i * 2.399) * (80.0 + (i % 9) * 30.0)
		game._spawn_enemy(game.ENEMY_COMMON, point)
		var enemy: Dictionary = game.enemies.back()
		enemy["hp"] = 100000.0
		enemy["max_hp"] = 100000.0
		if i < orbital_count:
			game.orbitals.append({"target_kind": "enemy", "enemy_uid": enemy["uid"], "origin_pos": point,
				"angle": i * 2.399, "life": 3.0, "tick": 0.60, "damage": 0.0})
	for i in range(16):
		game.bullets.append({"kind": "gravitante", "pos": Vector2(400 + i * 40, 640),
			"dir": Vector2.RIGHT, "age": i * 0.1, "life": 1.0, "damage": 0.0})
	if scenario == 2:
		game._trigger_gravitante_mark_collision()
	if scenario >= 3:
		game.manifestation_secondaries.append({"kind": "gravitante", "life": 4.0, "max": 8.0,
			"center": Vector2(800, 450), "captured": count, "orbital_bonus": orbital_count,
			"capture_power": 1.0, "spin_speed": 420.0, "pulse_tick": 0.28, "boss_captured": scenario == 4})
	if scenario == 5:
		game.manifest_evolution_state = {"choices": [
			{"id": "gravitante_ev1_roche", "stage": "ev1"},
			{"id": "gravitante_ev2_chaotic_orbit", "stage": "ev2"}]}
