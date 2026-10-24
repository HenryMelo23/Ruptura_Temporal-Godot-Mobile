extends SceneTree
## Paired old/new render workload, same process/snapshot/device. Requires a display.
const Probe = preload("res://tests/runtime_render_profile_probe.gd")
const Reference = preload("res://tests/fixtures/enemy_render_before_optimization.gd")
const EntitiesPresentation = preload("res://scripts/presentation/entities_presentation.gd")
const OUT := "res://.codex/render_optimization/"
var game: Node2D
var rows: Array = []
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("ENEMY_RENDER_EQUIVALENCE requires a real renderer")
		quit(1)
		return
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
	game.set_process(false)
	game.set_physics_process(false)
	game.render_enemies_only = true
	game.mode = "game"
	game.time_alive = 17.25
	game.player_pos = Vector2(640, 660)
	game.gfx_particles = true
	game.gfx_shadows = true
	game.gfx_low_resource = false
	game.gfx_memory_saver = false
	game.mobile_adaptive_visual_budget = false
	_check(not EntitiesPresentation._enemy_health_bar_visible(game, {}, 1.0, false), "untargeted full-health bar was not culled")
	_check(EntitiesPresentation._enemy_health_bar_visible(game, {}, 0.99, false), "damaged enemy lost its health bar")
	_check(EntitiesPresentation._enemy_health_bar_visible(game, {}, 1.0, true), "targeted enemy lost its health bar")
	_check(EntitiesPresentation._enemy_health_bar_visible(game, {"sanguinaria_hunt": true}, 1.0, false), "status-marked enemy lost its health bar")
	Engine.max_fps = 0
	root.mode = Window.MODE_WINDOWED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var galleries := {
		1: [game.ENEMY_COMMON, game.ENEMY_ATIRADOR, game.ENEMY_KAMIKAZE, game.ENEMY_AGGLOMERATOR, game.ENEMY_STALKER, game.ENEMY_PROJECTOR, game.ENEMY_CRYSTAL, game.ENEMY_CURATER, game.ENEMY_LARAPIO],
		2: [game.ENEMY_COMMON, game.ENEMY_KAMIKAZE, game.ENEMY_PYRO_PENGUIN, game.ENEMY_COUT_ATTACK_SPEED, game.ENEMY_SHIELD_REFLECTOR],
		3: [game.ENEMY_DEVOTO, game.ENEMY_INCENSARIO, game.ENEMY_GUARDIAO, game.ENEMY_FLAGELANTE, game.ENEMY_SALMODIANTE, game.ENEMY_RELICARIO],
		4: [game.ENEMY_NEXUS_CARTOGRAPHER, game.ENEMY_NEXUS_CHRONOPHAGE, game.ENEMY_NEXUS_REFRACTOR, game.ENEMY_NEXUS_WEAVER, game.ENEMY_NEXUS_ECHO],
		6: [game.ENEMY_MIASMA_EEL, game.ENEMY_LODARIO, game.ENEMY_FOSSIL_PUSTULE, game.ENEMY_CHRONAL_LEECH],
		7: [game.ENEMY_CINERIDO, game.ENEMY_PANGOLIRO, game.ENEMY_CORVOL],
	}
	for size in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = size
		root.content_scale_size = size
		for phase in galleries:
			_setup(phase, galleries[phase], galleries[phase].size() * 3, size)
			await _compare("gallery_f%d_%dx%d" % [phase, size.x, size.y], 2)
	# Timings contain only CPU submission of enemies, never claimed as gameplay FPS.
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	for phase in [1, 2]:
		for count in [20, 120]:
			_setup(phase, [game.ENEMY_COMMON], count, root.size)
			await _compare("crowd_f%d_%d" % [phase, count], 40)
	var report := FileAccess.open(OUT + "results.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"device": RenderingServer.get_video_adapter_name(), "renderer": RenderingServer.get_current_rendering_method(), "metric": "CPU enemy renderer submission only; identical frozen snapshots", "results": rows}, "\t"))
	report.close()
	game.enemy_render_reference = null
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	game.queue_free()
	game = null
	for frame in range(4):
		await process_frame
	print("ENEMY_RENDER_EQUIVALENCE_%s scenarios=%d" % ["FAIL" if failed else "OK", rows.size()])
	quit(1 if failed else 0)

func _setup(phase: int, kinds: Array, count: int, size: Vector2i) -> void:
	game.current_phase = phase
	game.rng.seed = 14703
	game.enemies.clear()
	game.manifestation_secondaries.clear()
	var columns := 12 if count > 30 else 6
	for index in range(count):
		var pos := Vector2(60 + (index % columns) * (size.x - 120.0) / columns, 80 + (index / columns) * 48)
		game._spawn_enemy(kinds[index % kinds.size()], pos)
		var enemy: Dictionary = game.enemies.back()
		enemy["phase"] = index % 2
		# Keep every gallery entry damaged so the paired pixel oracle still
		# verifies that visible bars and enemy art are unchanged.
		enemy["hp"] = 99.0 - (index % 3) * 30.0
		enemy["max_hp"] = 100.0
		enemy["alpha"] = 0.6 if index % 3 == 0 else 1.0
		enemy["sanguinaria_hunt"] = index % 7 == 2
		enemy["crepuscular_ocaso_mark"] = 0.5 if index % 7 == 3 else 0.0
		enemy["phase7_vulnerable"] = 0.4 if index % 2 == 0 else 0.0
		enemy["facing_dir"] = Vector2.LEFT if index % 2 == 0 else Vector2.RIGHT

func _check(ok: bool, message: String) -> void:
	if ok:
		return
	failed = true
	push_error("ENEMY_RENDER_EQUIVALENCE " + message)

func _compare(label: String, samples: int) -> void:
	var captures: Array[Image] = []
	var timings: Array = []
	for reference in [true, false]:
		game.enemy_render_reference = Reference if reference else null
		var times: Array[float] = []
		for frame in range(samples + 4):
			game.queue_redraw()
			await RenderingServer.frame_post_draw
			if frame >= 4:
				times.append(float(game.render_profile_us.get("enemies", 0)))
			await process_frame
		var capture := root.get_texture().get_image()
		captures.append(capture)
		capture.save_png(OUT + label + ("_before.png" if reference else "_after.png"))
		var sum := 0.0
		for value in times:
			sum += value
		times.sort()
		timings.append({"mean_us": sum / times.size(), "p95_us": times[mini(times.size() - 1, int(times.size() * 0.95))]})
	var equal_pixels := captures[0].get_size() == captures[1].get_size() and captures[0].get_data() == captures[1].get_data()
	if not equal_pixels:
		failed = true
		push_error("ENEMY_RENDER_PIXEL_MISMATCH " + label)
	rows.append({"scenario": label, "pixel_equal": equal_pixels, "before": timings[0], "after": timings[1]})
	print("ENEMY_RENDER_COMPARE %s pixel_equal=%s before_us=%.1f after_us=%.1f" % [label, equal_pixels, timings[0].mean_us, timings[1].mean_us])
