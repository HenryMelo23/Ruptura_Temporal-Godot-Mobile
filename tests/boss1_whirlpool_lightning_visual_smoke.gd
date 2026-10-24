extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.current_phase = 1
	game.mode = "game"
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 10000.0
	game.boss_hp = game.boss_hp_max
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(330.0, 0.0)
	game.enemies.clear()
	game.effects.clear()
	game.boss_attacks.clear()
	game.set_process(false)
	game.set_physics_process(false)


func _capture(path: String, capture_size: Vector2i) -> bool:
	root.mode = Window.MODE_WINDOWED
	root.borderless = true
	root.min_size = Vector2i.ZERO
	root.content_scale_size = capture_size
	root.size = capture_size
	for _frame in range(4):
		await process_frame
	game.queue_redraw()
	await process_frame
	await process_frame
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("BOSS1_WHIRLPOOL_LIGHTNING_VISUAL_FAIL no viewport")
		return false
	var image := viewport_texture.get_image()
	if image == null or image.get_size() != capture_size or image.save_png(path) != OK:
		push_error("BOSS1_WHIRLPOOL_LIGHTNING_VISUAL_FAIL expected=%s actual=%s path=%s" % [capture_size, image.get_size() if image != null else Vector2i.ZERO, path])
		return false
	return true


func _whirlpool_snapshot() -> void:
	game.boss_attacks.clear()
	game.boss1_whirlpool_sequence = 3
	game.early_boss_controller.start_boss1_whirlpool()
	var attack: Dictionary = game.boss_attacks[0]
	attack["state"] = "active"
	attack["state_age"] = game.BOSS1_WHIRLPOOL_LASER_WARNING + game.BOSS1_WHIRLPOOL_LASER_ROTATION_DURATION * 0.38
	attack["age"] = attack["state_age"]
	game.boss_pos = game.WORLD_SIZE * 0.5
	# Center the gameplay camera on the boss so the capture proves the beams
	# originate at the sprite instead of merely crossing the middle of the view.
	game.player_pos = game.boss_pos
	game.online_local_spectator = true


func _lightning_snapshot() -> void:
	game.boss_attacks.clear()
	game.online_local_spectator = false
	game.player_pos = game.boss_pos + Vector2(330.0, 0.0)
	game.early_boss_controller.spawn_boss1_lightning_strike()
	game.early_boss_controller.spawn_boss1_lightning_strike()
	var warning: Dictionary = game.boss_attacks[0]
	warning["target"] = game.player_pos + Vector2(-150.0, 45.0)
	warning["age"] = 0.84
	var impact: Dictionary = game.boss_attacks[1]
	impact["target"] = game.player_pos + Vector2(155.0, -20.0)
	impact["age"] = game.BOSS1_LIGHTNING_WARNING + 0.12
	impact["impact"] = true


func _run() -> void:
	_prepare()
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	_whirlpool_snapshot()
	if not await _capture("res://.codex/boss1_whirlpool_qa_1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	game.gfx_low_resource = true
	if not await _capture("res://.codex/boss1_whirlpool_low_qa_960x540.png", Vector2i(960, 540)):
		quit(1)
		return

	game.gfx_low_resource = false
	_lightning_snapshot()
	if not await _capture("res://.codex/boss1_lightning_qa_1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	game.gfx_low_resource = true
	if not await _capture("res://.codex/boss1_lightning_low_qa_960x540.png", Vector2i(960, 540)):
		quit(1)
		return

	print("BOSS1_WHIRLPOOL_LIGHTNING_VISUAL_OK whirlpool_lasers=4 whirlpool=1280x720,960x540 lightning=1280x720,960x540")
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	game = null
	await process_frame
	quit(0)
