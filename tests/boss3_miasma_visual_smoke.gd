extends SceneTree

var game: Node
var capture_count := 0
var measurements: Array = []
var output_dir := "res://.codex/miasma_" + (OS.get_environment("MIASMA_CAPTURE_LABEL") if not OS.get_environment("MIASMA_CAPTURE_LABEL").is_empty() else "after")


func _fail(message: String) -> void:
	push_error("BOSS3_MIASMA_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _save(name: String) -> void:
	var gameplay_before := _gameplay_snapshot()
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null or image.get_size() != root.size:
		_fail("capture image is empty")
		return
	var output := output_dir + "/" + name + ".png"
	var err := image.save_png(output)
	if err != OK:
		_fail("could not save capture %s err=%d" % [output, err])
		return
	print("BOSS3_MIASMA_VISUAL_OK " + ProjectSettings.globalize_path(output))
	capture_count += 1
	if gameplay_before != _gameplay_snapshot():
		_fail("render changed miasma state/RNG: " + name)
	if "middle" in name:
		var samples: Array[float] = []
		var calls := 0.0
		for frame in range(28):
			var started := Time.get_ticks_usec()
			game.queue_redraw()
			await RenderingServer.frame_post_draw
			if frame >= 4:
				samples.append((Time.get_ticks_usec() - started) / 1000.0)
				calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			await process_frame
		var total := 0.0
		for sample in samples:
			total += sample
		samples.sort()
		measurements.append({"capture": name, "submission_to_draw_ms": total / samples.size(), "p95_ms": samples[int(samples.size() * 0.95)], "draw_calls": calls / samples.size()})


func _gameplay_snapshot() -> Dictionary:
	var snapshot := {"rng": game.rng.state, "hp": game.player_hp, "boss_hp": game.boss_hp, "pos": game.boss_pos, "attacks": game.boss_attacks.duplicate(true)}
	for property in game.get_property_list():
		var key := String(property.name)
		if key.begins_with("boss3_miasma_"):
			var value: Variant = game.get(key)
			snapshot[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	return snapshot


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game._start_game()
	game._advance_to_phase(3)
	game.set_process(false)
	game.set_physics_process(false)
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.effects.clear()
	game.rng.seed = 31415
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	Engine.max_fps = 0
	game.mode = "game"
	game.startup_thanks_done = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 8000.0
	game.boss_hp = 6200.0
	game.boss_pos = Vector2(900, 420)
	game.player_pos = Vector2(690, 470)
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(530, 350))
	game._spawn_enemy(game.ENEMY_GUARDIAO, Vector2(1070, 520))

	for mobile in [false, true]:
		root.size = Vector2i(960, 540) if mobile else Vector2i(1280, 720)
		root.content_scale_size = root.size
		game.ui_platform_override = game.UI_PLATFORM_ANDROID if mobile else game.UI_PLATFORM_DESKTOP
		game.gfx_low_resource = mobile
		var suffix := "960x540_mobile_low" if mobile else "1280x720_desktop"
		for variant in [1, 2, 4]:
			game._end_boss3_miasma(true)
			game._start_boss3_miasma(variant)
			game.effects.clear()
			if variant == 1:
				game.boss3_miasma_clone_positions = [Vector2(430, 430), Vector2(550, 650), Vector2(1050, 650), Vector2(680, 280)]
			if variant == 2:
				game.boss3_miasma_spit_timer = 0.0
				game._update_boss3_miasma(0.01)
				game.boss_attacks[0]["age"] = 0.58
			var stages := ["entry", "middle", "exit"] if variant != 4 else ["entry", "middle", "near_complete", "contact", "overtime"]
			for stage in stages:
				game.time_alive = 120.5
				game.boss3_miasma_timer = 14.92 if stage == "entry" else (0.12 if stage == "exit" else 8.0)
				game.boss3_miasma_clone_timer = 1.45 if stage == "entry" else 0.72
				game.boss3_miasma_qte_taps = 0 if stage == "entry" else (17 if stage == "near_complete" else 9)
				game.boss3_miasma_qte_elapsed = 0.3 if stage == "entry" else (8.0 if stage == "overtime" else 2.7)
				game.boss3_miasma_qte_time_left = maxf(0.0, 7.0 - game.boss3_miasma_qte_elapsed)
				game.boss3_miasma_qte_lids_touching = stage == "contact"
				await _save("v%d_%s_%s" % [variant, stage, suffix])
			game._end_boss3_miasma(true)
			game.effects.clear()
			await _save("v%d_cleared_%s" % [variant, suffix])

	game._end_boss3_miasma(true)
	game.boss_attacks.clear()
	game._start_boss3_sector_ritual()
	if game.boss_attacks.is_empty():
		_fail("sector ritual did not start")
		return
	game.boss_attacks[0]["age"] = game.BOSS3_SECTOR_RITUAL_WARNING * 0.72
	await _save("boss3_sector_ritual_warning")
	game.boss_attacks[0]["age"] = game.BOSS3_SECTOR_RITUAL_WARNING + 0.24
	await _save("boss3_sector_ritual_active")
	var report := FileAccess.open(output_dir + "/performance.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"device": RenderingServer.get_video_adapter_name(), "metric": "CPU submission to frame_post_draw, static scene; not gameplay FPS", "results": measurements}, "\t"))
	report.close()
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	game.queue_free()
	await process_frame
	await process_frame
	# Let AudioServer process the stopped boot/music playbacks before shutdown.
	await create_timer(0.2).timeout
	print("BOSS3_MIASMA_VISUAL_MATRIX_OK captures=%d desktop=true mobile_low=true" % capture_count)
	quit(0)
