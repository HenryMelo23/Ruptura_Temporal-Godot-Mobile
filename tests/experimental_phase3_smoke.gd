extends SceneTree

var game: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.forced_initial_phase = 3
	game._start_game()
	var normal_hp: float = game.enemy_base_hp
	var normal_speed: float = game.enemy_speed_base
	var normal_boss_hp: float = game.boss_hp_max
	assert(game.current_phase == 3 and not game.experimental_phase_active)
	assert(game.experimental_phase_controller.uses_definitive_world())
	assert(game.experimental_phase_controller.active_phase == 3)
	assert(game.WORLD_SIZE == game.experimental_phase_controller.EXPERIMENTAL_WORLD_SIZE)
	assert(game._current_map_texture().resource_path.ends_with("phase_ex3_terrain_atlas.png"))
	assert(game.save_controller._run_can_be_saved())

	# Public command, switching an armed variant, cancelling, and rearming.
	assert(game._try_apply_initial_phase_cheat("FaseEX"))
	assert(game.experimental_phase_controller.requested_phase == 1)
	assert(game._try_apply_initial_phase_cheat("FaseEX3"))
	assert(game.experimental_phase_requested)
	assert(game.experimental_phase_controller.requested_phase == 3)
	assert(game._try_apply_initial_phase_cheat("FaseEX3"))
	assert(not game.experimental_phase_requested)
	assert(not game._try_apply_initial_phase_cheat("FaseEX8"))
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	assert(is_equal_approx(game.enemy_base_hp, normal_hp))
	assert(is_equal_approx(game.enemy_speed_base, normal_speed))
	assert(is_equal_approx(game.boss_hp_max, normal_boss_hp))
	assert(game.boss_name == "PAI-RATO")
	assert(not game._boss_call_can_start(false))
	assert(not game.experimental_boss_altar_discovered)
	var altar: Vector2 = game.experimental_boss_altar_pos
	assert(altar.distance_to(game.PLAYER_START) >= game.experimental_phase_controller.ALTAR_MIN_START_DISTANCE)
	var altar_count := 0
	var variants := {}
	for chunk in game.experimental_phase_controller.terrain_chunks(Vector2.ZERO, game.WORLD_SIZE):
		variants[chunk.tile] = true
		if chunk.tile == game.experimental_phase_controller.ALTAR_TILE:
			altar_count += 1
			assert(chunk.rect.get_center().is_equal_approx(altar))
	assert(altar_count == 1 and variants.size() == 16)

	game.player_pos = altar
	game.experimental_phase_controller.update(game.experimental_phase_controller.ALTAR_HOLD_TIME + 0.02)
	assert(game.experimental_boss_altar_used and game.mode == "boss_call")
	game._update_boss_call(game.BOSS_CALL_COUNTDOWN + 0.05)
	assert(game.boss_active and game.current_phase == 3)
	assert(is_equal_approx(game.boss_pos.x, altar.x))
	assert(game.boss_pos.y < altar.y)
	game._update_boss_phase3(game.BOSS3_ENTRY_TIME + 0.01)
	assert(game.boss_pos.is_equal_approx(altar))
	assert(game.boss_entry_timer <= 0.0)
	assert(game._next_phase_after_boss(3) != 0)
	var encounter: Rect2 = game.experimental_phase_controller.boss_encounter_rect()
	assert(encounter.size.is_equal_approx(game.experimental_phase_controller.BASE_WORLD_SIZE))
	game.boss_attacks.clear()
	game._start_boss3_sector_ritual()
	assert(game.boss_attacks.size() == 1)
	assert(Vector2(game.boss_attacks[0]["center"]).is_equal_approx(altar))
	game.boss_attacks.clear()
	game._start_boss3_miasma(1)
	assert(game.boss3_miasma_clone_positions.size() == 4)
	for clone_data in game.boss3_miasma_clone_positions:
		var clone_pos := Vector2(clone_data)
		assert(clone_pos.x >= encounter.position.x + 120.0 and clone_pos.x <= encounter.end.x - 120.0)
		assert(clone_pos.y >= encounter.position.y + 120.0 and clone_pos.y <= encounter.end.y - 120.0)
		assert(clone_pos.distance_to(altar) <= 430.01)
	game._end_boss3_miasma(false)
	game._start_boss3_ritual()
	assert(game.phase3_cheeses.size() == 3)
	for cheese in game.phase3_cheeses:
		assert(encounter.has_point(Vector2(cheese["pos"])))
	game.phase3_cheeses.clear()
	game.enemy_bullets.clear()
	game.boss_attacks.clear()
	game._start_boss3_rain()
	game._update_boss3_attacks(0.66)
	var rain_count := 0
	for bullet in game.enemy_bullets:
		if String(bullet.get("type", "")) != "rat_flask":
			continue
		rain_count += 1
		var rain_pos := Vector2(bullet["pos"])
		assert(is_equal_approx(rain_pos.x, encounter.end.x + 30.0))
		assert(rain_pos.y >= encounter.position.y and rain_pos.y <= encounter.end.y)
	assert(rain_count == 3)

	game.gameplay_cheat_text = "FaseEX3"
	assert(game._try_apply_gameplay_cheat())
	game._start_game()
	assert(game.current_phase == 3 and game.experimental_phase_active)
	assert(game.WORLD_SIZE == game.DEFAULT_WORLD_SIZE)
	assert(not game._current_map_texture().resource_path.contains("experimental/"))
	assert(not game.save_controller._run_can_be_saved())
	assert(game.experimental_phase_controller.terrain_chunks(Vector2.ZERO, game.WORLD_SIZE).is_empty())
	game.boss_entry_timer = game.BOSS3_ENTRY_TIME
	game._update_boss_phase3(game.BOSS3_ENTRY_TIME + 0.01)
	assert(game.boss_pos.is_equal_approx(game.WORLD_SIZE * 0.5))
	game.forced_initial_phase = 3
	game._start_game()
	assert(not game.experimental_phase_active and game.experimental_phase_controller.uses_definitive_world())
	print("DEFINITIVE_PHASE3_SMOKE_OK command=true expanded_default=true classic_ex=true phase3_rules=true atlas=true altar_entry=true encounter_local=true sector=true miasma=true ritual=true rain=true switch_reset=true")
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)
