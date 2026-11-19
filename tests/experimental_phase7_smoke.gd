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
	game.forced_initial_phase = 7
	game._start_game()
	var normal_hp: float = game.enemy_base_hp
	var normal_speed: float = game.enemy_speed_base
	var normal_boss_hp: float = game.boss_hp_max
	assert(game.current_phase == 7 and not game.experimental_phase_active)
	assert(game.experimental_phase_controller.uses_definitive_world())
	assert(game.experimental_phase_controller.active_phase == 7)
	assert(game.WORLD_SIZE == game.experimental_phase_controller.EXPERIMENTAL_WORLD_SIZE)
	assert(game._current_map_texture().resource_path.ends_with("phase_ex7_terrain_atlas.png"))
	assert(game.save_controller._run_can_be_saved())

	# Public command, switching an armed variant, cancelling, and rearming.
	assert(game._try_apply_initial_phase_cheat("FaseEX"))
	assert(game.experimental_phase_controller.requested_phase == 1)
	assert(game._try_apply_initial_phase_cheat("FaseEX7"))
	assert(game.experimental_phase_requested)
	assert(game.experimental_phase_controller.requested_phase == 7)
	assert(game._try_apply_initial_phase_cheat("FaseEX7"))
	assert(not game.experimental_phase_requested)
	assert(not game._try_apply_initial_phase_cheat("FaseEX8"))
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	assert(is_equal_approx(game.enemy_base_hp, normal_hp))
	assert(is_equal_approx(game.enemy_speed_base, normal_speed))
	assert(is_equal_approx(game.boss_hp_max, normal_boss_hp))
	assert(game.boss_name == "FENIX")
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
	assert(game.boss_active and game.current_phase == 7)
	assert(game.boss_pos.is_equal_approx(altar + Vector2(0, -188)))
	assert(game.boss7_target_pos.is_equal_approx(altar))
	game._update_boss_phase7(game.BOSS7_ENTRY_TIME + 0.01)
	assert(game.boss_pos.is_equal_approx(altar))
	assert(game.boss7_state == game.BOSS7_STATE_FLY)
	assert(game._next_phase_after_boss(7) != 0)
	var arena: Rect2 = game.experimental_phase_controller.boss_encounter_rect()
	assert(arena.size == game.experimental_phase_controller.BASE_WORLD_SIZE)
	game.player_pos = altar + Vector2(160, 0)
	game._update_boss7_flight(0.25)
	assert(arena.has_point(game.boss_pos))
	assert(not game.boss_pos.is_equal_approx(altar))
	game._start_boss7_dive()
	game._update_boss7_state(2.0)
	assert(is_equal_approx(game.boss_pos.y, arena.position.y - 180.0))
	game._update_boss7_state(0.9)
	assert(arena.grow(-89.0).has_point(game.boss7_target_pos))
	game._spawn_boss7_dive_fireball(altar)
	var fireball: Dictionary = game.enemy_bullets[-1]
	assert(is_equal_approx(Vector2(fireball["pos"]).y, arena.position.y - 124.0))
	assert(Vector2(fireball["impact_pos"]).is_equal_approx(altar))
	game.boss_hp = game.boss_hp_max * 0.29
	game._check_boss7_ultimate(0.0)
	assert(game.boss7_ultimate_active)
	var outside_corner: Vector2 = arena.position + Vector2(80, 45)
	var inside_corner: Vector2 = arena.position + Vector2(760, 420)
	assert(not game.modern_boss_controller.boss7_fire_dangerous(outside_corner, 2.9))
	assert(game.modern_boss_controller.boss7_fire_dangerous(outside_corner, 5.5))
	assert(not game.modern_boss_controller.boss7_fire_dangerous(inside_corner, 5.5))
	assert(not game.modern_boss_controller.boss7_fire_dangerous(arena.position - Vector2.ONE, 8.0))
	for elapsed in [3.0, 5.5, 8.0, 18.0, 28.0]:
		for local_pos in [Vector2(80, 45), Vector2(760, 420), Vector2(1520, 855)]:
			assert(game.modern_boss_controller.boss7_fire_dangerous(arena.position + local_pos, elapsed) == game.PhoenixFire.dangerous(local_pos, arena.size, elapsed))
	game.boss_pos = altar
	game._damage_boss(game.boss_hp + 99999.0, "ex7_test", false, false, "", altar)
	assert(game.boss7_core_active and not game.boss_dead)
	assert(game.boss7_core_pos.is_equal_approx(altar))
	game.boss7_core_timer = 0.0
	game._update_boss7_core(0.02)
	assert(game.boss7_reborn and not game.boss7_core_active)
	game.gameplay_cheat_text = "FaseEX7"
	assert(game._try_apply_gameplay_cheat())
	game._start_game()
	assert(game.current_phase == 7 and game.experimental_phase_active)
	assert(game.WORLD_SIZE == game.DEFAULT_WORLD_SIZE)
	assert(not game._current_map_texture().resource_path.contains("experimental/"))
	assert(not game.save_controller._run_can_be_saved())
	assert(game.experimental_phase_controller.terrain_chunks(Vector2.ZERO, game.WORLD_SIZE).is_empty())
	game.boss7_target_pos = game.experimental_phase_controller.boss7_entry_target()
	game.boss_entry_timer = game.BOSS7_ENTRY_TIME
	game._update_boss_phase7(game.BOSS7_ENTRY_TIME + 0.01)
	assert(game.boss_pos.is_equal_approx(game.WORLD_SIZE * 0.5 + Vector2(0, -72)))
	assert(game.experimental_phase_controller.boss_encounter_rect() == Rect2(Vector2.ZERO, game.WORLD_SIZE))
	game.forced_initial_phase = 7
	game._start_game()
	assert(not game.experimental_phase_active and game.experimental_phase_controller.uses_definitive_world())
	print("DEFINITIVE_PHASE7_SMOKE_OK command=true expanded_default=true classic_ex=true phase7_rules=true atlas=true altar_entry=true flight=true dive=true fire_local=true rebirth=true switch_reset=true")
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)
