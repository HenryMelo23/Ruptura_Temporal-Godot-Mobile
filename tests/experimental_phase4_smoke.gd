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
	game.forced_initial_phase = 4
	game._start_game()
	var normal_hp: float = game.enemy_base_hp
	var normal_speed: float = game.enemy_speed_base
	var normal_boss_hp: float = game.boss_hp_max
	assert(game.current_phase == 4 and not game.experimental_phase_active)
	assert(game.experimental_phase_controller.uses_definitive_world())
	assert(game.experimental_phase_controller.active_phase == 4)
	assert(game.WORLD_SIZE == game.experimental_phase_controller.EXPERIMENTAL_WORLD_SIZE)
	assert(game._current_map_texture().resource_path.ends_with("phase_ex4_terrain_atlas.png"))
	assert(game.save_controller._run_can_be_saved())

	# Public command, switching an armed variant, cancelling, and rearming.
	assert(game._try_apply_initial_phase_cheat("FaseEX"))
	assert(game.experimental_phase_controller.requested_phase == 1)
	assert(game._try_apply_initial_phase_cheat("FaseEX4"))
	assert(game.experimental_phase_requested)
	assert(game.experimental_phase_controller.requested_phase == 4)
	assert(game._try_apply_initial_phase_cheat("FaseEX4"))
	assert(not game.experimental_phase_requested)
	assert(not game._try_apply_initial_phase_cheat("FaseEX8"))
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	assert(is_equal_approx(game.enemy_base_hp, normal_hp))
	assert(is_equal_approx(game.enemy_speed_base, normal_speed))
	assert(is_equal_approx(game.boss_hp_max, normal_boss_hp))
	assert(game.boss_name == "NEXO ANFIBIO")
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
	assert(game.boss_active and game.current_phase == 4)
	assert(is_equal_approx(game.boss_pos.x, altar.x))
	assert(game.boss_pos.y < altar.y)
	assert(game.boss4_entry_target.is_equal_approx(altar))
	game._update_boss_phase4(game.BOSS4_ENTRY_TIME * 0.5)
	assert(game.boss_pos.is_equal_approx(altar + Vector2(0, -280)))
	game._update_boss_phase4(game.BOSS4_ENTRY_TIME * 0.5 + 0.01)
	assert(game.boss_pos.is_equal_approx(altar))
	assert(game.boss_entry_timer <= 0.0)
	assert(game._next_phase_after_boss(4) != 0)
	var encounter: Rect2 = game.experimental_phase_controller.boss_encounter_rect()
	assert(encounter.size.is_equal_approx(game.experimental_phase_controller.BASE_WORLD_SIZE))
	game._start_boss4_ultimate()
	assert(game.boss4_rupture_anchors.size() == game.BOSS4_ULTIMATE_REQUIRED_ANCHORS)
	for anchor in game.boss4_rupture_anchors:
		var anchor_pos := Vector2(anchor["pos"])
		assert(anchor_pos.x >= encounter.position.x + 96.0 and anchor_pos.x <= encounter.end.x - 96.0)
		assert(anchor_pos.y >= encounter.position.y + 96.0 and anchor_pos.y <= encounter.end.y - 96.0)
		assert(anchor_pos.distance_to(altar) <= minf(encounter.size.x, encounter.size.y) * 0.23 + 0.01)
	game._finish_boss4_ultimate(true)
	game.phase4_enemy_hazards.clear()
	game._start_boss4_secondary()
	for hazard in game.phase4_enemy_hazards:
		assert(String(hazard["kind"]) == "boss4_bubble")
		var start := Vector2(hazard["start"])
		var end := Vector2(hazard["end"])
		assert(start.x >= encounter.position.x and start.x <= encounter.end.x)
		assert(end.x >= encounter.position.x - 70.0 and end.x <= encounter.end.x + 70.0)
		assert(is_equal_approx(start.y, encounter.position.y - 62.0) or is_equal_approx(start.y, encounter.end.y + 62.0))
	game._start_boss4_meteor_event()
	for meteor in game.boss4_meteorites:
		var meteor_target := Vector2(meteor["target"])
		assert(meteor_target.x >= encounter.position.x + 100.0 and meteor_target.x <= encounter.end.x - 100.0)
		assert(meteor_target.y >= encounter.position.y + 110.0 and meteor_target.y <= encounter.end.y - 110.0)
		assert(is_equal_approx(Vector2(meteor["start"]).y, encounter.position.y - 170.0))
	game.phase4_enemy_hazards.clear()
	game._spawn_boss4_column_barrage()
	var column: Dictionary = game.phase4_enemy_hazards[-1]
	assert(float(column["start_x"]) >= encounter.position.x and float(column["start_x"]) <= encounter.end.x)
	assert(is_equal_approx(float(column["arena_y"]), encounter.position.y))
	assert(is_equal_approx(float(column["arena_height"]), encounter.size.y))
	game._spawn_boss4_drag_wave()
	var drag: Dictionary = game.phase4_enemy_hazards[-1]
	assert(is_equal_approx(float(drag["start_x"]), encounter.end.x + 80.0))
	game._spawn_boss4_sonic_wave()
	var sonic: Dictionary = game.phase4_enemy_hazards[-1]
	assert(is_equal_approx(float(sonic["arena_top"]), encounter.position.y + 82.0))
	assert(is_equal_approx(float(sonic["arena_bottom"]), encounter.end.y - 82.0))
	game._spawn_boss4_ultimate_ray(false)
	var ray: Dictionary = game.phase4_enemy_hazards[-1]
	var ray_pos := Vector2(ray["pos"])
	assert(ray_pos.x >= encounter.position.x + 74.0 and ray_pos.x <= encounter.end.x - 74.0)
	assert(ray_pos.y >= encounter.position.y + 74.0 and ray_pos.y <= encounter.end.y - 74.0)

	game.gameplay_cheat_text = "FaseEX4"
	assert(game._try_unlock_retornante_cheat())
	game._start_game()
	assert(game.current_phase == 4 and game.experimental_phase_active)
	assert(game.WORLD_SIZE == game.DEFAULT_WORLD_SIZE)
	assert(not game._current_map_texture().resource_path.contains("experimental/"))
	assert(not game.save_controller._run_can_be_saved())
	assert(game.experimental_phase_controller.terrain_chunks(Vector2.ZERO, game.WORLD_SIZE).is_empty())
	game.boss_entry_timer = game.BOSS4_ENTRY_TIME
	game._update_boss_phase4(game.BOSS4_ENTRY_TIME + 0.01)
	assert(game.boss_pos.is_equal_approx(Vector2(game.WORLD_SIZE.x * 0.68, game.WORLD_SIZE.y * 0.5)))
	game.forced_initial_phase = 4
	game._start_game()
	assert(not game.experimental_phase_active and game.experimental_phase_controller.uses_definitive_world())
	print("DEFINITIVE_PHASE4_SMOKE_OK command=true expanded_default=true classic_ex=true phase4_rules=true atlas=true altar_entry=true encounter_local=true ultimate=true bubbles=true meteors=true columns=true drag=true sonic=true rays=true switch_reset=true")
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)
