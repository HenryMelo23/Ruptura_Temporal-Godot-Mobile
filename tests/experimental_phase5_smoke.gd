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
	game.forced_initial_phase = 5
	game._start_game()
	var normal_hp: float = game.enemy_base_hp
	var normal_speed: float = game.enemy_speed_base
	var normal_boss_hp: float = game.boss_hp_max
	assert(game.current_phase == 5 and not game.experimental_phase_active)
	assert(game.experimental_phase_controller.uses_definitive_world())
	assert(game.experimental_phase_controller.active_phase == 5)
	assert(game.WORLD_SIZE == game.experimental_phase_controller.EXPERIMENTAL_WORLD_SIZE)
	assert(game._current_map_texture().resource_path.ends_with("phase_ex5_terrain_atlas.png"))
	assert(game.save_controller._run_can_be_saved())

	# Public command, switching an armed variant, cancelling, and rearming.
	assert(game._try_apply_initial_phase_cheat("FaseEX"))
	assert(game.experimental_phase_controller.requested_phase == 1)
	assert(game._try_apply_initial_phase_cheat("FaseEX5"))
	assert(game.experimental_phase_requested)
	assert(game.experimental_phase_controller.requested_phase == 5)
	assert(game._try_apply_initial_phase_cheat("FaseEX5"))
	assert(not game.experimental_phase_requested)
	assert(not game._try_apply_initial_phase_cheat("FaseEX8"))
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	assert(is_equal_approx(game.enemy_base_hp, normal_hp))
	assert(is_equal_approx(game.enemy_speed_base, normal_speed))
	assert(is_equal_approx(game.boss_hp_max, normal_boss_hp))
	assert(game.boss_name == "UMBRA")
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
	assert(game.boss_active and game.current_phase == 5)
	game._update_boss_phase5(game.BOSS5_ENTRY_TIME + 0.01)
	assert(game.boss_pos.is_equal_approx(altar))
	assert(game._next_phase_after_boss(5) == 0)
	for dimension in ["base", "vortice", "gravidade", "necrose", "ressonancia", "hemorragia", "atrito", "rastro"]:
		game.boss5_dimension = dimension
		assert(game._current_map_texture() != null)
		assert(game._current_map_texture().resource_path.contains("experimental/"))
		assert(game.experimental_phase_controller.altar_label() == "SELO DA UMBRA")
	game.boss5_dimension = "base"
	game.phase5_hazards.clear()
	game._spawn_umbra_action("VORTICE")
	assert(Vector2(game.phase5_hazards[0]["pos"]).is_equal_approx(altar))
	game.phase5_hazards.clear()
	game._spawn_umbra_action("LASER_SOBRECARGA")
	game.boss_pos = altar
	game._update_phase5_hazards(0.01)
	assert(game.boss_pos.is_equal_approx(altar))

	game.gameplay_cheat_text = "FaseEX5"
	assert(game._try_apply_gameplay_cheat())
	game._start_game()
	assert(game.current_phase == 5 and game.experimental_phase_active)
	assert(game.WORLD_SIZE == game.DEFAULT_WORLD_SIZE)
	assert(not game._current_map_texture().resource_path.contains("experimental/"))
	assert(not game.save_controller._run_can_be_saved())
	assert(game.experimental_phase_controller.terrain_chunks(Vector2.ZERO, game.WORLD_SIZE).is_empty())
	game.forced_initial_phase = 5
	game._start_game()
	assert(not game.experimental_phase_active and game.experimental_phase_controller.uses_definitive_world())
	print("DEFINITIVE_PHASE5_SMOKE_OK command=true expanded_default=true classic_ex=true phase5_rules=true atlas=true altar_entry=true dimensions=true vortex=true laser=true switch_reset=true")
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)
