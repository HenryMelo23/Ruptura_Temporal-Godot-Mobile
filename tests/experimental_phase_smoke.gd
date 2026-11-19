extends SceneTree

var game: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame

	# Definitive journey: expanded atlas, exploration altar and normal save/route.
	game.forced_initial_phase = 1
	game._start_game()
	game.set_process(false)
	game.set_physics_process(false)

	assert(not game.experimental_phase_active)
	assert(game.experimental_phase_controller.uses_definitive_world())
	assert(game.current_phase == 1)
	assert(is_equal_approx((game.WORLD_SIZE.x * game.WORLD_SIZE.y) / (game.DEFAULT_WORLD_SIZE.x * game.DEFAULT_WORLD_SIZE.y), 5.0))
	assert(game.boss_ready)
	assert(not game.experimental_phase_controller.should_show_boss_button())
	assert(not game._boss_call_can_start(false))
	assert(game.save_controller._run_can_be_saved())
	assert(not game.experimental_boss_altar_discovered)
	assert(game.experimental_boss_altar_pos.distance_to(game.PLAYER_START) >= game.experimental_phase_controller.ALTAR_MIN_START_DISTANCE)
	assert(game.experimental_boss_altar_pos.x >= game.experimental_phase_controller.ALTAR_WORLD_MARGIN.x)
	assert(game.experimental_boss_altar_pos.y >= game.experimental_phase_controller.ALTAR_WORLD_MARGIN.y)
	assert(game.experimental_boss_altar_pos.x <= game.WORLD_SIZE.x - game.experimental_phase_controller.ALTAR_WORLD_MARGIN.x)
	assert(game.experimental_boss_altar_pos.y <= game.WORLD_SIZE.y - game.experimental_phase_controller.ALTAR_WORLD_MARGIN.y)
	_assert_chunks()
	assert(game._current_map_texture() != null)
	_assert_expanded_art_contract()
	assert(game.experimental_phase_controller.landmarks.size() >= 36)
	for _spawn in range(12):
		var spawn_pos: Vector2 = game._spawn_point_on_edge()
		var spawn_distance: float = spawn_pos.distance_to(game.player_pos)
		assert(spawn_distance >= 500.0 and spawn_distance <= 900.0)
	var interrupted_fields: Array = game.save_controller._interrupted_run_field_names()
	assert("experimental_boss_altar_pos" in interrupted_fields)
	assert("experimental_boss_altar_discovered" in interrupted_fields)
	assert("experimental_boss_altar_used" in interrupted_fields)
	var interrupted_snapshot: Dictionary = game.save_controller._build_interrupted_run_snapshot()
	var interrupted_state: Dictionary = interrupted_snapshot["fields"]
	assert(Vector2(interrupted_state["experimental_boss_altar_pos"]).is_equal_approx(game.experimental_boss_altar_pos))
	assert(not bool(interrupted_state["experimental_boss_altar_discovered"]))
	assert(not bool(interrupted_state["experimental_boss_altar_used"]))

	game.player_pos = game.experimental_boss_altar_pos
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.experimental_phase_controller.update(game.experimental_phase_controller.ALTAR_HOLD_TIME + 0.02)
	assert(game.experimental_boss_altar_discovered)
	assert(game.experimental_boss_altar_used)
	assert(game.mode == "boss_call")
	assert(game.boss_call_timer > 0.0)
	game._update_boss_call(game.BOSS_CALL_COUNTDOWN + 0.05)
	assert(game.boss_active)
	assert(is_equal_approx(game.boss_pos.x, game.experimental_boss_altar_pos.x))
	assert(game.boss_pos.y < game.experimental_boss_altar_pos.y)

	# FaseEX now preserves the former definitive/classic map and world size.
	game.gameplay_cheat_text = "FaseEX"
	assert(game._try_apply_gameplay_cheat())
	assert(game.experimental_phase_requested)
	game._start_game()
	assert(game.experimental_phase_active)
	assert(not game.experimental_phase_controller.uses_definitive_world())
	assert(game.current_phase == 1)
	assert(game.WORLD_SIZE == game.DEFAULT_WORLD_SIZE)
	assert(game.experimental_boss_altar_pos == Vector2.ZERO)
	assert(game.experimental_phase_controller.terrain_chunks(Vector2.ZERO, game.WORLD_SIZE).is_empty())
	assert(not game._current_map_texture().resource_path.contains("experimental/"))
	assert(game.experimental_phase_controller.should_show_boss_button())
	assert(not game.save_controller._run_can_be_saved())
	game.boss_ready = true
	assert(game._boss_call_can_start(false))

	# Classic EX remains solo-only; rejected online selection falls back to the
	# definitive expanded campaign instead of the old map.
	game.experimental_phase_requested = true
	game.is_multiplayer = true
	game.experimental_phase_controller.prepare_new_run(true)
	assert(not game.experimental_phase_active)
	assert(game.experimental_phase_rejected_online)
	assert(game.WORLD_SIZE == game.experimental_phase_controller.EXPERIMENTAL_WORLD_SIZE)
	game.current_phase = 3
	game.experimental_phase_controller.begin_definitive_phase(3)
	var deterministic_altar: Vector2 = game.experimental_boss_altar_pos
	game.experimental_phase_controller.begin_definitive_phase(3)
	assert(game.experimental_boss_altar_pos.is_equal_approx(deterministic_altar))
	game.experimental_boss_altar_authorized = false
	assert(not game._boss_call_can_start(false))
	game.is_multiplayer = false

	print("DEFINITIVE_EXPANDED_PHASE_SMOKE_OK definitive_area=5x altar=true save=true resume_fields=true classic_ex=true classic_area=1x classic_map=true online_fallback=true deterministic_online_altar=true")
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)


func _assert_expanded_art_contract() -> void:
	var ground: Image = game._current_map_texture().get_image()
	assert(ground.get_width() >= 1024 and ground.get_width() == ground.get_height())
	for y in range(0, ground.get_height(), 32):
		for x in range(0, ground.get_width(), 32):
			assert(ground.get_pixel(x, y).a >= 0.99)


func _assert_chunks() -> void:
	var controller = game.experimental_phase_controller
	var altar: Vector2 = game.experimental_boss_altar_pos
	var size: float = controller.CHUNK_SIZE
	assert((altar / size - Vector2.ONE * 0.5).is_equal_approx((altar / size).floor()))
	var whole: Array[Dictionary] = controller.terrain_chunks(Vector2.ZERO, game.WORLD_SIZE)
	var altars := 0
	var variants := {}
	for chunk in whole:
		variants[chunk.tile] = true
		if chunk.tile == controller.ALTAR_TILE:
			altars += 1
			assert(chunk.rect.get_center().is_equal_approx(altar))
	assert(altars == 1 and variants.size() == 16)
	var camera := altar - Vector2(400, 300)
	var visible: Array[Dictionary] = controller.terrain_chunks(camera, Vector2(960, 540))
	assert(visible.size() <= 16)
	var shifted: Array[Dictionary] = controller.terrain_chunks(camera + Vector2(1, 1), Vector2(960, 540))
	assert(visible.size() == shifted.size())
	for i in range(visible.size()):
		assert(visible[i].tile == shifted[i].tile)
		assert(visible[i].rect.position.is_equal_approx(shifted[i].rect.position + Vector2.ONE))
	# Move the reserved cell: old location returns to terrain, exactly one altar remains.
	game.experimental_boss_altar_pos = altar + Vector2(size, 0)
	var moved: Array[Dictionary] = controller.terrain_chunks(altar - Vector2.ONE * size, Vector2.ONE * size * 4)
	altars = 0
	for chunk in moved:
		if chunk.tile == controller.ALTAR_TILE:
			altars += 1
			assert((chunk.rect.get_center() + altar - Vector2.ONE * size).is_equal_approx(game.experimental_boss_altar_pos))
	assert(altars == 1)
	game.experimental_boss_altar_pos = altar
	assert(ResourceLoader.exists(controller.TERRAIN_ATLAS_PATH))
