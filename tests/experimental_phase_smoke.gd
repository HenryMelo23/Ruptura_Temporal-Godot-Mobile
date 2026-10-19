extends SceneTree

var game: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame

	assert(game.WORLD_SIZE == game.DEFAULT_WORLD_SIZE)
	game.gameplay_cheat_text = "FaseEX"
	assert(game._try_unlock_retornante_cheat())
	assert(game.experimental_phase_requested)
	game._start_game()

	assert(game.experimental_phase_active)
	assert(game.current_phase == 1)
	assert(is_equal_approx((game.WORLD_SIZE.x * game.WORLD_SIZE.y) / (game.DEFAULT_WORLD_SIZE.x * game.DEFAULT_WORLD_SIZE.y), 5.0))
	assert(game.boss_ready)
	assert(not game.experimental_phase_controller.should_show_boss_button())
	assert(not game._boss_call_can_start(false))
	assert(not game.save_controller._run_can_be_saved())
	assert(not game.experimental_boss_altar_discovered)
	assert(game.experimental_boss_altar_pos.distance_to(game.PLAYER_START) >= game.experimental_phase_controller.ALTAR_MIN_START_DISTANCE)
	assert(game.experimental_boss_altar_pos.x >= game.experimental_phase_controller.ALTAR_WORLD_MARGIN.x)
	assert(game.experimental_boss_altar_pos.y >= game.experimental_phase_controller.ALTAR_WORLD_MARGIN.y)
	assert(game.experimental_boss_altar_pos.x <= game.WORLD_SIZE.x - game.experimental_phase_controller.ALTAR_WORLD_MARGIN.x)
	assert(game.experimental_boss_altar_pos.y <= game.WORLD_SIZE.y - game.experimental_phase_controller.ALTAR_WORLD_MARGIN.y)
	assert(game.experimental_phase_controller.map_tile_rects(Vector2.ZERO).size() == 1)
	assert(ResourceLoader.exists("res://assets/sprites/experimental/phase_ex_ground_tile.png"))
	assert(ResourceLoader.exists("res://assets/sprites/experimental/phase_ex_boss_altar_v2.png"))
	assert(game._current_map_texture() != null)
	_assert_experimental_art_contract()
	assert(game.experimental_phase_controller.landmarks.size() >= 36)
	for _spawn in range(12):
		var spawn_pos: Vector2 = game._spawn_point_on_edge()
		var spawn_distance: float = spawn_pos.distance_to(game.player_pos)
		assert(spawn_distance >= 500.0 and spawn_distance <= 900.0)

	game.player_pos = game.experimental_boss_altar_pos
	game.experimental_phase_controller.update(game.experimental_phase_controller.ALTAR_HOLD_TIME + 0.02)
	assert(game.experimental_boss_altar_discovered)
	assert(game.experimental_boss_altar_used)
	assert(game.mode == "boss_call")
	assert(game.boss_call_timer > 0.0)
	game._update_boss_call(game.BOSS_CALL_COUNTDOWN + 0.05)
	assert(game.boss_active)
	assert(is_equal_approx(game.boss_pos.x, game.experimental_boss_altar_pos.x))
	assert(game.boss_pos.y < game.experimental_boss_altar_pos.y)

	var first_altar_position: Vector2 = game.experimental_boss_altar_pos
	game.experimental_phase_requested = false
	game.is_multiplayer = false
	game.experimental_phase_controller.prepare_new_run(true)
	assert(not game.experimental_phase_active)
	assert(game.WORLD_SIZE == game.DEFAULT_WORLD_SIZE)
	assert(not game.experimental_boss_altar_discovered)

	game.experimental_phase_requested = true
	game.experimental_phase_controller.prepare_new_run(true)
	assert(game.experimental_phase_active)
	assert(not game.experimental_boss_altar_pos.is_equal_approx(first_altar_position))

	game.experimental_phase_requested = true
	game.is_multiplayer = true
	game.experimental_phase_controller.prepare_new_run(true)
	assert(not game.experimental_phase_active)
	assert(game.experimental_phase_rejected_online)
	assert(game.WORLD_SIZE == game.DEFAULT_WORLD_SIZE)
	game.is_multiplayer = false

	print("EXPERIMENTAL_PHASE_SMOKE_OK cheat=true area=5x altar=true normal_reset=true online_isolated=true")
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(3):
		await process_frame
	quit(0)


func _assert_experimental_art_contract() -> void:
	var ground_texture: Texture2D = load("res://assets/sprites/experimental/phase_ex_ground_tile.png")
	var altar_texture: Texture2D = load("res://assets/sprites/experimental/phase_ex_boss_altar_v2.png")
	assert(ground_texture != null and altar_texture != null)
	var ground: Image = ground_texture.get_image()
	var altar: Image = altar_texture.get_image()
	assert(ground.get_width() >= 1024 and ground.get_width() == ground.get_height())
	for sample in range(0, ground.get_height(), 16):
		assert(_color_delta(ground.get_pixel(0, sample), ground.get_pixel(ground.get_width() - 1, sample)) <= 0.04)
	for sample in range(0, ground.get_width(), 16):
		assert(_color_delta(ground.get_pixel(sample, 0), ground.get_pixel(sample, ground.get_height() - 1)) <= 0.04)
	assert(altar.get_pixel(0, 0).a <= 0.01)
	assert(altar.get_pixel(altar.get_width() / 2, altar.get_height() / 2).a >= 0.9)


func _color_delta(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a)
