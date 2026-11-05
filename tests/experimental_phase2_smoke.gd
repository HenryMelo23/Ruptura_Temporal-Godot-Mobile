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
	game.forced_initial_phase = 2
	game._start_game()
	var normal_hp: float = game.enemy_base_hp
	var normal_speed: float = game.enemy_speed_base
	var normal_boss_hp: float = game.boss_hp_max
	assert(game.current_phase == 2 and not game.experimental_phase_active)
	assert(game.experimental_phase_controller.uses_definitive_world())
	assert(game.experimental_phase_controller.active_phase == 2)
	assert(game.WORLD_SIZE == game.experimental_phase_controller.EXPERIMENTAL_WORLD_SIZE)
	assert(game._current_map_texture().resource_path.ends_with("phase_ex2_terrain_atlas.png"))
	assert(game.save_controller._run_can_be_saved())

	# Public command, switching an armed variant, cancelling, and rearming.
	assert(game._try_apply_initial_phase_cheat("FaseEX"))
	assert(game.experimental_phase_controller.requested_phase == 1)
	assert(game._try_apply_initial_phase_cheat("FaseEX2"))
	assert(game.experimental_phase_requested)
	assert(game.experimental_phase_controller.requested_phase == 2)
	assert(game._try_apply_initial_phase_cheat("FaseEX2"))
	assert(not game.experimental_phase_requested)
	assert(not game._try_apply_initial_phase_cheat("FaseEX8"))
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	assert(is_equal_approx(game.enemy_base_hp, normal_hp))
	assert(is_equal_approx(game.enemy_speed_base, normal_speed))
	assert(is_equal_approx(game.boss_hp_max, normal_boss_hp))
	assert(game.boss_name == "SENTINELA GLACIAL")
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
	assert(game.boss_active and game.current_phase == 2)
	assert(is_equal_approx(game.boss_pos.x, altar.x))
	assert(game.boss_pos.y < altar.y)
	game._update_boss_phase2(game.BOSS2_ENTRY_TIME + 0.01)
	assert(game.boss_pos.is_equal_approx(altar))
	assert(game.boss_entry_timer == 0.0)
	assert(game._next_phase_after_boss(2) != 0)
	var encounter: Rect2 = game.experimental_phase_controller.boss_encounter_rect()
	assert(encounter.size.is_equal_approx(game.experimental_phase_controller.BASE_WORLD_SIZE))
	assert(encounter.has_point(altar))
	assert(game.experimental_phase_controller.boss2_wind_center().is_equal_approx(altar))
	game.player_pos = altar + Vector2(120.0, 60.0)
	game._start_boss2_ultimate()
	assert(game.experimental_phase_controller.boss2_wind_center().is_equal_approx(game.boss2_ultimate_center))
	game._end_boss2_ultimate()
	game.player_pos = altar + Vector2(300.0, 0.0)
	var wind_distance_before: float = game.player_pos.distance_to(altar)
	game._apply_boss2_wind_force(0.5)
	assert(game.player_pos.distance_to(altar) < wind_distance_before)
	for _sample in range(12):
		var reposition: Vector2 = game._boss2_pick_reposition_target()
		assert(Rect2(encounter.position + Vector2(150.0, 130.0), encounter.size - Vector2(300.0, 260.0)).has_point(reposition))
	for vertical in [false, true]:
		for _sample in range(8):
			game.boss_attacks.clear()
			game._add_boss2_blizzard(vertical)
			var blizzard: Dictionary = game.boss_attacks[0]
			for wave_data in blizzard["waves"]:
				var wave: Dictionary = wave_data
				if String(wave.get("direction", "")) == "left":
					assert(float(wave["x"]) >= encounter.end.x)
					assert(float(wave["x"]) <= encounter.end.x + 470.0)
				else:
					assert(float(wave["y"]) <= encounter.position.y)
					assert(float(wave["y"]) >= encounter.position.y - 430.0)

	# The public EX command now opens the classic map, while the default stays expanded.
	game.gameplay_cheat_text = "FaseEX2"
	assert(game._try_apply_gameplay_cheat())
	game._start_game()
	assert(game.current_phase == 2 and game.experimental_phase_active)
	assert(game.WORLD_SIZE == game.DEFAULT_WORLD_SIZE)
	assert(not game._current_map_texture().resource_path.contains("experimental/"))
	assert(not game.save_controller._run_can_be_saved())
	assert(game.experimental_phase_controller.terrain_chunks(Vector2.ZERO, game.WORLD_SIZE).is_empty())
	game.boss_entry_timer = game.BOSS2_ENTRY_TIME
	game._update_boss_phase2(game.BOSS2_ENTRY_TIME + 0.01)
	assert(game.boss_pos.is_equal_approx(game.WORLD_SIZE * 0.5))
	assert(game.experimental_phase_controller.boss2_wind_center().is_equal_approx(game.WORLD_SIZE * 0.5))
	game.forced_initial_phase = 2
	game._start_game()
	assert(not game.experimental_phase_active and game.experimental_phase_controller.uses_definitive_world())
	assert(game.WORLD_SIZE == game.experimental_phase_controller.EXPERIMENTAL_WORLD_SIZE)
	print("DEFINITIVE_PHASE2_SMOKE_OK command=true expanded_default=true classic_ex=true phase2_rules=true atlas=true altar_entry=true encounter_local=true wind=true blizzard=true reposition=true switch_reset=true")
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)
