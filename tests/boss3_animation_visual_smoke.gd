extends SceneTree

const Boss3AnimationPresentation = preload("res://scripts/presentation/boss3_animation_presentation.gd")

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
	game.current_phase = 3
	game._prepare_phase_texture_assets(3)
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 9000.0
	game.boss_hp = 9000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(340.0, 0.0)
	game.enemies.clear()
	game.effects.clear()
	game.boss_attacks.clear()
	game._reset_phase3_state()


func _capture(path: String) -> bool:
	game.queue_redraw()
	await process_frame
	await process_frame
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("BOSS3_ANIMATION_VISUAL_FAIL renderer did not expose a viewport texture")
		return false
	var image := viewport_texture.get_image()
	if image == null or image.save_png(path) != OK:
		push_error("BOSS3_ANIMATION_VISUAL_FAIL could not save " + path)
		return false
	return true


func _run() -> void:
	_prepare_boss()
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var remake_frames: Dictionary = {}
	for key_value in game.textures.keys():
		var key := String(key_value)
		if key.begins_with("boss3_anim_"):
			remake_frames[key] = game.textures[key]
			game.textures.erase(key)
	if not await _capture("res://.codex/boss3_before_active_map_qa_1280x720.png"):
		quit(1)
		return
	for key in remake_frames:
		game.textures[key] = remake_frames[key]

	if not await _capture("res://.codex/boss3_idle_new_map_qa_1280x720.png"):
		quit(1)
		return

	game.boss_pos += Vector2(-18.0, 0.0)
	game.boss3_is_moving = true
	Boss3AnimationPresentation.update(game, 0.1)
	assert(Boss3AnimationPresentation.visual_state(game) == "walk")
	assert(not Boss3AnimationPresentation.should_flip_h(game))
	if not await _capture("res://.codex/boss3_walk_left_new_map_qa_1280x720.png"):
		quit(1)
		return

	game.boss_pos += Vector2(36.0, 0.0)
	Boss3AnimationPresentation.update(game, 0.1)
	assert(Boss3AnimationPresentation.should_flip_h(game))
	if not await _capture("res://.codex/boss3_walk_right_new_map_qa_1280x720.png"):
		quit(1)
		return

	game._damage_boss(45.0, "boss3_visual_walk_hit", false, false)
	assert(Boss3AnimationPresentation.visual_state(game) == "walk")
	if not await _capture("res://.codex/boss3_walk_hit_overlay_qa_1280x720.png"):
		quit(1)
		return

	game.boss3_is_moving = false
	Boss3AnimationPresentation.update(game, 0.1)
	game.boss_attacks = [{"kind": "rat_tail", "age": 0.32, "duration": 0.52, "hit": false}]
	Boss3AnimationPresentation.update(game, 0.016)
	if not await _capture("res://.codex/boss3_tail_new_map_qa_1280x720.png"):
		quit(1)
		return

	game.boss_attacks = [{"kind": "boss3_sector_ritual", "age": 0.72, "duration": 4.0, "center": game.WORLD_SIZE * 0.5, "radius": game.BOSS3_SECTOR_RITUAL_RADIUS, "lanes": game.BOSS3_SECTOR_RITUAL_LANES, "steps": 2, "warning": game.BOSS3_SECTOR_RITUAL_WARNING, "active": game.BOSS3_SECTOR_RITUAL_ACTIVE, "dissipate": game.BOSS3_SECTOR_RITUAL_DISSIPATE, "seed": 41, "hit": {}}]
	Boss3AnimationPresentation.update(game, 0.016)
	if not await _capture("res://.codex/boss3_sector_new_map_qa_1280x720.png"):
		quit(1)
		return

	game.boss_attacks.clear()
	game.boss_active = false
	game.boss_dead = true
	game.boss3_death_animation_duration = 1.72
	game.boss3_death_animation_timer = 0.82
	game.boss3_death_animation_pos = game.boss_pos
	if not await _capture("res://.codex/boss3_death_new_map_qa_1280x720.png"):
		quit(1)
		return

	root.size = Vector2i(960, 540)
	game.gfx_low_resource = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp = game.boss_hp_max
	Boss3AnimationPresentation.reset(game)
	game.boss_pos += Vector2(20.0, 0.0)
	game.boss3_is_moving = true
	Boss3AnimationPresentation.update(game, 0.1)
	assert(Boss3AnimationPresentation.should_flip_h(game))
	if not await _capture("res://.codex/boss3_walk_right_low_qa_960x540.png"):
		quit(1)
		return
	game.boss_active = false
	game.boss_dead = true
	game.boss3_death_animation_duration = 1.72
	game.boss3_death_animation_timer = 0.44
	game.boss3_death_animation_pos = game.boss_pos
	if not await _capture("res://.codex/boss3_death_new_map_low_qa_960x540.png"):
		quit(1)
		return

	print("BOSS3_ANIMATION_VISUAL_OK map=assets/maps/calm/phase_3.png desktop=idle,walk_left,walk_right,walk_hit,tail,sector,death low=walk_right,death facing_visual_only=true")
	if game.has_method("_cleanup_runtime_resources"):
		game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	quit(0)
