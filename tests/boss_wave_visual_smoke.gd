extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.current_phase = 1
	assert(game.has_method("_draw_boss_siege_tide"))
	game.gfx_shadows = true
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = 6000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(410, 0)
	game.enemies.clear()
	game.effects.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.boss_pos + Vector2(-350, 170))
	game._spawn_enemy(game.ENEMY_ATIRADOR, game.boss_pos + Vector2(330, 210))
	game.enemies[0]["facing_dir"] = Vector2.RIGHT
	game.enemies[1]["facing_dir"] = Vector2.LEFT
	game.boss_stage_duration = 8.0
	game.boss_stage_timer = game.boss_stage_duration - game.BOSS_STAGE_SLAM_TIME * 0.5
	game.boss1_siege_tide_jump_event_id = "boss1-siege-tide-visual-opening"
	game.boss1_siege_tide_jump_duration = game.BOSS_STAGE_SLAM_TIME
	game.boss1_siege_tide_jump_timer = game.BOSS_STAGE_SLAM_TIME * 0.5
	game.boss_transition_waves.clear()
	game.queue_redraw()
	await process_frame
	await process_frame
	var jump_image = root.get_texture().get_image()
	assert(jump_image != null and jump_image.get_width() == 1280 and jump_image.get_height() == 720)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	assert(jump_image.save_png("res://.codex/boss_wave_jump_qa_1280x720.png") == OK)
	game.boss_stage_timer = 3.8
	game.boss1_siege_tide_jump_event_id = "boss1-siege-tide-visual-1"
	game.boss1_siege_tide_jump_duration = game.BOSS1_SIEGE_TIDE_WARNING
	game.boss1_siege_tide_jump_timer = game.BOSS1_SIEGE_TIDE_WARNING * 0.45
	game.boss_stage_safe_angle = 0.0
	game.boss_transition_waves = [{
		"idx": 0,
		"pos": game.boss_pos,
		"radius": 310.0,
		"speed": game.BOSS_STAGE_WAVE_SPEED,
		"width": 16.0,
		"kind": "dupla_abertura",
		"siege_tide": true,
		"event_id": "boss1-siege-tide-visual-0",
		"seed": 17,
		"open_angle": 0.0,
		"open_size": PI * 0.48,
		"age": game.BOSS_STAGE_WAVE_WARNING + 0.7,
		"warning": game.BOSS1_SIEGE_TIDE_WARNING,
		"hit": false
	}, {
		"idx": 1,
		"pos": game.boss_pos,
		"radius": 42.0,
		"speed": game.BOSS_STAGE_WAVE_SPEED,
		"width": 16.0,
		"kind": "dupla_abertura",
		"siege_tide": true,
		"event_id": "boss1-siege-tide-visual-1",
		"seed": 31,
		"open_angle": PI / 8.0,
		"open_size": PI * 0.48,
		"age": game.BOSS_STAGE_WAVE_WARNING * 0.55,
		"warning": game.BOSS1_SIEGE_TIDE_WARNING,
		"hit": false
	}]
	game.queue_redraw()
	await process_frame
	await process_frame
	var image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output = "res://.codex/boss_wave_qa_1280x720.png"
	assert(image.save_png(output) == OK)
	print("BOSS_WAVE_VISUAL_OK jump=" + ProjectSettings.globalize_path("res://.codex/boss_wave_jump_qa_1280x720.png") + " wave=" + ProjectSettings.globalize_path(output))
	quit(0)
