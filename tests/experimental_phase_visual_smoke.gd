extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	var phase_id := 1
	var reference := false
	for candidate in [2, 3, 4, 5, 6, 7]:
		if "--ex%d" % candidate in OS.get_cmdline_user_args() or "--phase%d-reference" % candidate in OS.get_cmdline_user_args():
			phase_id = candidate
			reference = "--phase%d-reference" % candidate in OS.get_cmdline_user_args()
	game.experimental_phase_controller.requested_phase = phase_id
	game.experimental_phase_requested = reference
	game.forced_initial_phase = phase_id
	game.active_character_key = game.CHARACTER_GEOVANA
	game._start_game()
	assert(game.active_character_key == game.CHARACTER_GEOVANA)
	game.set_process(false)
	game.set_physics_process(false)
	game.enemies.clear()
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.gfx_low_resource = "--low" in OS.get_cmdline_user_args()
	game.mode = "game"
	game.queue_redraw()
	await process_frame
	await process_frame
	var output_dir := "res://.agent_logs/experimental_phase%s" % (str(phase_id) if phase_id > 1 else "")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	if reference:
		await _capture(output_dir + "/before_1280x720.png", Vector2i(1280, 720))
		game._cleanup_runtime_resources()
		game.free()
		quit(0)
		return
	var suffix := "_low" if game.gfx_low_resource else ""
	await _capture(output_dir + "/start_desktop_1280x720%s.png" % suffix, Vector2i(1280, 720))
	game.player_pos = Vector2(1600.0, 900.0)
	game.queue_redraw()
	await process_frame
	await _capture(output_dir + "/sector_seam_1280x720%s.png" % suffix, Vector2i(1280, 720))

	game.player_pos = game.experimental_boss_altar_pos + Vector2(-72.0, 0.0)
	game.experimental_phase_controller.update(0.58)
	assert(game.experimental_boss_altar_discovered)
	game.queue_redraw()
	await process_frame
	await _capture(output_dir + "/altar_mobile_960x540%s.png" % suffix, Vector2i(960, 540))

	var guidance_pos: Vector2 = game.experimental_boss_altar_pos + Vector2(900.0, 0.0)
	if guidance_pos.x > game.WORLD_SIZE.x - 80.0:
		guidance_pos = game.experimental_boss_altar_pos - Vector2(900.0, 0.0)
	game.player_pos = guidance_pos.clamp(Vector2(80.0, 80.0), game.WORLD_SIZE - Vector2(80.0, 80.0))
	game.queue_redraw()
	await process_frame
	await _capture(output_dir + "/altar_guidance_1280x720%s.png" % suffix, Vector2i(1280, 720))

	var original_altar: Vector2 = game.experimental_boss_altar_pos
	game.experimental_boss_altar_used = true
	game.player_pos = original_altar + Vector2(-72, 0)
	await _capture(output_dir + "/altar_used_1280x720%s.png" % suffix, Vector2i(1280, 720))
	game.experimental_boss_altar_used = false
	game.experimental_boss_altar_pos = Vector2(4.5, 3.5) * game.experimental_phase_controller.CHUNK_SIZE
	game.player_pos = game.experimental_boss_altar_pos + Vector2(-72, 0)
	await _capture(output_dir + "/altar_moved_960x540%s.png" % suffix, Vector2i(960, 540))
	game.experimental_boss_altar_pos = original_altar

	if phase_id > 1:
		game.player_pos = game.experimental_boss_altar_pos + Vector2(-72, 0)
		game.experimental_phase_controller.update(game.experimental_phase_controller.ALTAR_HOLD_TIME + 0.02)
		assert(game.mode == "boss_call")
		game._update_boss_call(game.BOSS_CALL_COUNTDOWN + 0.05)
		if phase_id == 7:
			game._update_boss_phase7(game.BOSS7_ENTRY_TIME + 0.01)
		elif phase_id == 6:
			game._update_boss_phase6(game.BOSS6_ENTRY_TIME + 0.01)
		elif phase_id == 5:
			game._update_boss_phase5(game.BOSS5_ENTRY_TIME + 0.01)
		elif phase_id == 4:
			game._update_boss_phase4(game.BOSS4_ENTRY_TIME + 0.01)
		elif phase_id == 3:
			game._update_boss_phase3(game.BOSS3_ENTRY_TIME + 0.01)
		else:
			game._update_boss_phase2(game.BOSS2_ENTRY_TIME + 0.01)
		assert(game.boss_pos.is_equal_approx(game.experimental_boss_altar_pos))
		await _capture(output_dir + "/boss_entry_1280x720%s.png" % suffix, Vector2i(1280, 720))
		game.player_pos = game.experimental_boss_altar_pos
		game.boss_attacks.clear()
		game.effects.clear()
		if phase_id == 7:
			game.boss_hp = game.boss_hp_max * 0.29
			game._check_boss7_ultimate(0.0)
			game.boss7_ultimate_timer = game.PhoenixFire.DURATION - 7.2
			game._update_boss7_ultimate(0.0)
		elif phase_id == 6:
			game._start_boss6_miasma_ultimate()
		elif phase_id == 5:
			game._transmute_umbra_dimension("TRANSMUTAR_VORTICE")
			game._spawn_umbra_action("VORTICE")
		elif phase_id == 4:
			game._start_boss4_ultimate()
		elif phase_id == 3:
			game._start_boss3_sector_ritual()
			game.boss_attacks[0]["age"] = game.BOSS3_SECTOR_RITUAL_WARNING + 0.08
		else:
			game._add_boss2_blizzard(true)
			game._update_boss2_attacks(game.BOSS2_WARNING_TIME + 0.9)
		game.queue_redraw()
		await process_frame
		await _capture(output_dir + "/boss_mechanic_1280x720%s.png" % suffix, Vector2i(1280, 720))
		await _capture(output_dir + "/boss_mechanic_mobile_960x540%s.png" % suffix, Vector2i(960, 540))
	else:
		game.boss_active = true
		game.boss_dead = false
		game.boss_hp_max = 10000.0
		game.boss_hp = game.boss_hp_max
		game.boss_pos = game.WORLD_SIZE * 0.5
		game.boss_attacks.clear()
		game.early_boss_controller.start_boss1_whirlpool()
		var whirlpool: Dictionary = game.boss_attacks[0]
		whirlpool["state"] = "active"
		whirlpool["state_age"] = 2.0
		game.player_pos = Vector2(260.0, 260.0)
		game.queue_redraw()
		await process_frame
		await _capture(output_dir + "/whirlpool_world_edge_1280x720%s.png" % suffix, Vector2i(1280, 720))
	game.experimental_phase_controller.requested_phase = phase_id
	game.experimental_phase_requested = true
	game._start_game()
	game.queue_redraw()
	await process_frame
	await process_frame
	assert(game.experimental_phase_active)
	assert(game.WORLD_SIZE == game.DEFAULT_WORLD_SIZE)
	assert(game.phase_map_layer.map_chunks.is_empty())
	assert(game.phase_map_layer.material != game.phase_map_layer.chunk_material)

	print("DEFINITIVE_PHASE_VISUAL_OK phase=%d captures=%d area=5x altar=true hidden_until_discovered=true guidance=true relocated=true used=true boss_mechanic=true classic_ex_material=true" % [phase_id, 9 if phase_id > 1 else 7])
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)


func _capture(path: String, size: Vector2i) -> void:
	root.size = size
	game.queue_redraw()
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	assert(image != null)
	assert(image.get_width() == size.x and image.get_height() == size.y)
	assert(image.save_png(path) == OK)
