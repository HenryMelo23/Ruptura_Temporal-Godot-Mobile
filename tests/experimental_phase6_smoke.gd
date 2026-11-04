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
	game.forced_initial_phase = 6
	game._start_game()
	var normal_hp: float = game.enemy_base_hp
	var normal_speed: float = game.enemy_speed_base
	var normal_boss_hp: float = game.boss_hp_max
	assert(game.current_phase == 6 and not game.experimental_phase_active)
	assert(game.experimental_phase_controller.uses_definitive_world())
	assert(game.experimental_phase_controller.active_phase == 6)
	assert(game.WORLD_SIZE == game.experimental_phase_controller.EXPERIMENTAL_WORLD_SIZE)
	assert(game._current_map_texture().resource_path.ends_with("phase_ex6_terrain_atlas.png"))
	assert(game.save_controller._run_can_be_saved())

	# Public command, switching an armed variant, cancelling, and rearming.
	assert(game._try_apply_initial_phase_cheat("FaseEX"))
	assert(game.experimental_phase_controller.requested_phase == 1)
	assert(game._try_apply_initial_phase_cheat("FaseEX6"))
	assert(game.experimental_phase_requested)
	assert(game.experimental_phase_controller.requested_phase == 6)
	assert(game._try_apply_initial_phase_cheat("FaseEX6"))
	assert(not game.experimental_phase_requested)
	assert(not game._try_apply_initial_phase_cheat("FaseEX8"))
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	assert(is_equal_approx(game.enemy_base_hp, normal_hp))
	assert(is_equal_approx(game.enemy_speed_base, normal_speed))
	assert(is_equal_approx(game.boss_hp_max, normal_boss_hp))
	assert(game.boss_name == "MATRIARCA DA CHAGA")
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
	assert(game.boss_active and game.current_phase == 6)
	assert(is_equal_approx(game.boss_pos.x, altar.x))
	assert(game.boss_pos.is_equal_approx(altar))
	assert(game.boss6_stage_controller.arena_center().is_equal_approx(altar))
	game._update_boss_phase6(game.BOSS6_ENTRY_TIME * 0.5)
	assert(game.boss_pos.is_equal_approx(altar))
	game._update_boss_phase6(game.BOSS6_ENTRY_TIME * 0.5 + 0.01)
	assert(game.boss_pos.is_equal_approx(altar))
	assert(game.boss_entry_timer <= 0.0)
	assert(game._next_phase_after_boss(6) != 0)
	for particle in game.boss6_entry_particles:
		assert(Vector2(particle["target"]).distance_to(altar) <= 74.01)
	for ratio in [1.0, 0.66, 0.33]:
		game.boss_hp = game.boss_hp_max * ratio
		game.boss6_stage_controller.update(0.05)
		assert(game.boss_pos.is_equal_approx(altar))
	for special in ["ecdysis", "final_birth", "cracked_heart"]:
		game._boss6_start_special(special)
		assert(game.boss_pos.is_equal_approx(altar))
	game._spawn_boss6_final_organs()
	assert(not game.boss6_organs.is_empty())
	for organ in game.boss6_organs:
		assert(is_equal_approx(Vector2(organ["pos"]).distance_to(altar), 165.0))
	game._start_boss6_miasma_ultimate()
	game.boss6_miasma_ult_angle = 0.0
	var miasma_radius: float = game.BOSS6_MIASMA_ULT_INNER_RADIUS + 10.0
	assert(not game._boss6_point_in_miasma(altar))
	assert(game._boss6_point_in_miasma(altar + Vector2(miasma_radius, 0)))
	assert(not game._boss6_point_in_miasma(altar + Vector2(game._boss6_miasma_outer_radius() + 10, 0)))
	var encounter: Rect2 = game.experimental_phase_controller.boss_encounter_rect()
	assert(encounter.size.is_equal_approx(game.experimental_phase_controller.BASE_WORLD_SIZE))
	for enemy in game.enemies:
		if bool(enemy.get("boss6_ult_pustule", false)):
			_assert_inside_encounter(Vector2(enemy["pos"]), encounter, Vector2(70, 70))

	# Expanded EX6 keeps every boss hazard in a local 1600x900 encounter even
	# if the player tries to drag target-based attacks across the 5x world.
	game.player_pos = Vector2(2, 2)
	var incubation: Vector2 = game._boss6_pustule_incubation_spot(0, 1, [])
	_assert_inside_encounter(incubation, encounter, Vector2(85, 85))
	game.boss6_lodarian_pools.clear()
	for spot in game.boss6_stage_controller.build_acid_bloom_spots():
		_assert_inside_encounter(Vector2(spot["pos"]), encounter, Vector2(110, 110))
	for drop in game.boss6_stage_controller.build_carnage_drop_batch():
		_assert_inside_encounter(Vector2(drop["pos"]), encounter, Vector2(80, 80))
	_assert_inside_encounter(game._boss6_valid_leech_drop_pos(Vector2.ZERO, 260.0), encounter, Vector2(75, 75))
	_assert_inside_encounter(game._boss6_spread_leech_drop_pos(0, 1, []), encounter, Vector2(90, 90))
	game.enemies.clear()
	game._spawn_boss6_leech_at(Vector2.ZERO)
	_assert_inside_encounter(Vector2(game.enemies.back()["pos"]), encounter, Vector2(55, 55))
	game._spawn_boss6_pustule_at(game.WORLD_SIZE)
	_assert_inside_encounter(Vector2(game.enemies.back()["pos"]), encounter, Vector2(55, 55))
	game._add_boss6_acid_pool(Vector2.ZERO)
	_assert_inside_encounter(Vector2(game.boss6_lodarian_pools.back()["pos"]), encounter, Vector2(45, 45))
	game.boss_attacks.clear()
	game._start_boss6_chasing_crack()
	_assert_inside_encounter(Vector2(game.boss_attacks.back()["pos"]), encounter, Vector2(80, 80))
	var distant_bone := {"dir": Vector2.UP, "distance": 2000.0, "side": 0.0, "phase": 0.0}
	var scythe_pos: Vector2 = game._boss6_vertebral_scythe_pos(altar, distant_bone, 1.0, 2.0)
	_assert_inside_encounter(scythe_pos, encounter, Vector2(8, 8))
	assert(game._boss6_relocation_point().is_equal_approx(altar))
	game._start_boss6_relocation()
	game._update_boss6_relocation(0.1)
	assert(game.boss_pos.is_equal_approx(altar))

	game.gameplay_cheat_text = "FaseEX6"
	assert(game._try_unlock_retornante_cheat())
	game._start_game()
	assert(game.current_phase == 6 and game.experimental_phase_active)
	assert(game.WORLD_SIZE == game.DEFAULT_WORLD_SIZE)
	assert(not game._current_map_texture().resource_path.contains("experimental/"))
	assert(not game.save_controller._run_can_be_saved())
	assert(game.experimental_phase_controller.terrain_chunks(Vector2.ZERO, game.WORLD_SIZE).is_empty())
	game.boss_entry_timer = game.BOSS6_ENTRY_TIME
	game._update_boss_phase6(game.BOSS6_ENTRY_TIME + 0.01)
	assert(game.boss_pos.is_equal_approx(game.WORLD_SIZE * 0.5))
	assert(game.boss6_stage_controller.arena_center().is_equal_approx(game.WORLD_SIZE * 0.5))
	game.forced_initial_phase = 6
	game._start_game()
	assert(not game.experimental_phase_active and game.experimental_phase_controller.uses_definitive_world())
	print("DEFINITIVE_PHASE6_SMOKE_OK command=true expanded_default=true classic_ex=true phase6_rules=true atlas=true altar_entry=true stationary_stages=true specials=true organs=true miasma=true encounter_local=true switch_reset=true")
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)


func _assert_inside_encounter(position: Vector2, encounter: Rect2, margin: Vector2) -> void:
	assert(position.x >= encounter.position.x + margin.x - 0.01)
	assert(position.x <= encounter.end.x - margin.x + 0.01)
	assert(position.y >= encounter.position.y + margin.y - 0.01)
	assert(position.y <= encounter.end.y - margin.y + 0.01)
