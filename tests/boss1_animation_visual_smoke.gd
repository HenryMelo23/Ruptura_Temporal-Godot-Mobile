extends SceneTree

const Boss1AnimationPresentation = preload("res://scripts/presentation/boss1_animation_presentation.gd")

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare_boss() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.current_phase = 1
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = 6000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(340.0, 0.0)
	game.enemies.clear()
	game.effects.clear()


func _capture(path: String) -> bool:
	game.queue_redraw()
	await process_frame
	await process_frame
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("BOSS1_ANIMATION_VISUAL_FAIL renderer did not expose a viewport texture")
		return false
	var image := viewport_texture.get_image()
	if image == null or image.save_png(path) != OK:
		push_error("BOSS1_ANIMATION_VISUAL_FAIL could not save " + path)
		return false
	return true


func _run() -> void:
	_prepare_boss()
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	Boss1AnimationPresentation.update(game, 0.01)
	if not await _capture("res://.codex/boss1_idle_remake_qa_1280x720.png"):
		quit(1)
		return

	game.boss1_animation_velocity = Vector2(90.0, 0.0)
	game.boss1_animation_state = Boss1AnimationPresentation.STATE_WALK
	game.boss1_animation_elapsed = 0.22
	if not await _capture("res://.codex/boss1_walk_remake_qa_1280x720.png"):
		quit(1)
		return

	game.boss1_animation_velocity = Vector2.ZERO
	game.boss_attacks.clear()
	game._add_boss_bubble(game.player_pos)
	Boss1AnimationPresentation.update(game, 0.28)
	if not await _capture("res://.codex/boss1_bubble_remake_qa_1280x720.png"):
		quit(1)
		return

	game.boss_attacks.clear()
	game._add_boss_pincer_tenaz()
	game.boss_attacks[0]["state"] = "dash_first"
	game.boss_attacks[0]["state_age"] = 0.12
	Boss1AnimationPresentation.update(game, 0.01)
	if not await _capture("res://.codex/boss1_tenaz_remake_qa_1280x720.png"):
		quit(1)
		return

	game.boss_attacks.clear()
	game._add_boss_tide()
	Boss1AnimationPresentation.update(game, 0.42)
	if not await _capture("res://.codex/boss1_tide_remake_qa_1280x720.png"):
		quit(1)
		return

	game.boss_attacks.clear()
	game.boss1_time_wave = {"radius": 120.0, "direction": 1.0, "age": 0.2, "max_radius": 620.0, "variant": 0, "origin": game.boss_pos}
	Boss1AnimationPresentation.update(game, 0.20)
	if not await _capture("res://.codex/boss1_rewind_remake_qa_1280x720.png"):
		quit(1)
		return
	game.boss1_time_wave.clear()

	game.boss1_hit_animation_duration = 0.24
	game.boss1_hit_animation_timer = 0.14
	if not await _capture("res://.codex/boss1_hit_qa_1280x720.png"):
		quit(1)
		return

	game.boss1_hit_animation_timer = 0.0
	game.boss_stage_duration = game.BOSS_STAGE_JUMP_TIME
	game.boss_stage_timer = game.boss_stage_duration - game.BOSS_STAGE_SLAM_TIME * 0.55
	if not await _capture("res://.codex/boss1_jump_qa_1280x720.png"):
		quit(1)
		return

	game.boss_stage_timer = 0.0
	game.boss_active = false
	game.boss_dead = true
	game.boss1_death_animation_duration = 1.65
	game.boss1_death_animation_timer = 0.88
	game.boss1_death_animation_pos = game.boss_pos
	if not await _capture("res://.codex/boss1_death_qa_1280x720.png"):
		quit(1)
		return

	root.size = Vector2i(960, 540)
	game.gfx_low_resource = true
	game.boss1_death_animation_timer = 0.36
	if not await _capture("res://.codex/boss1_death_low_qa_960x540.png"):
		quit(1)
		return

	print("BOSS1_ANIMATION_VISUAL_OK idle_walk_bubble_tenaz_tide_rewind=1280x720 hit_jump_death=1280x720 low=960x540")
	game.queue_free()
	await process_frame
	quit(0)
