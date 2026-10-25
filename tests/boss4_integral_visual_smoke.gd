extends SceneTree

const OUT_DIR := "res://.codex/boss4_rework_after"
const DESKTOP := Vector2i(1280, 720)
const MOBILE := Vector2i(960, 540)

var game: Node
var captures: Array[String] = []


func _initialize() -> void:
	root.size = DESKTOP
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("BOSS4_INTEGRAL_VISUAL_FAIL " + message)
	quit(1)


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_prepare_game()
	for key in ["idle", "walk", "hit", "slam", "tongue", "jump", "land", "comet", "gravity", "ultimate", "transition_2", "transition_3", "transition_4", "death"]:
		var texture_key: String = "boss4_rework_" + String(key)
		game._ensure_runtime_texture(texture_key)
		var frames: Array = game.textures.get(texture_key, [])
		_check(not frames.is_empty() and frames.all(func(frame): return frame is Texture2D), "missing frames for " + texture_key)
		for frame in frames:
			_check(frame.get_width() == 384 and frame.get_height() == 384, "wrong canvas for " + texture_key)

	_prepare_stage(1, 0.88, "windup", "slam", 0.48)
	await _capture("boss4_stage1_slam_1280x720.png", DESKTOP)

	_prepare_stage(2, 0.68, "jump", "jump", 0.86)
	game.boss4_ai_state["jump_progress"] = 0.58
	game.boss4_ai_state["jump_to"] = game.player_pos + Vector2(120.0, 0.0)
	await _capture("boss4_stage2_jump_1280x720.png", DESKTOP)

	_prepare_stage(3, 0.43, "active", "tongue", 0.78)
	game._start_boss4_orbital_prison()
	await _capture("boss4_stage3_tongue_1280x720.png", DESKTOP)

	_prepare_stage(4, 0.18, "walk", "", 0.0)
	game.boss4_ultimate_used = false
	game._start_boss4_ultimate()
	await _capture("boss4_stage4_ultimate_1280x720.png", DESKTOP)
	await _capture("boss4_stage4_ultimate_960x540.png", MOBILE)
	game._finish_boss4_ultimate(true)
	await _capture("boss4_ultimate_interrupted_1280x720.png", DESKTOP)

	_prepare_stage(4, 0.16, "walk", "", 0.0)
	game.boss4_ultimate_used = false
	game._start_boss4_ultimate()
	game._finish_boss4_ultimate(false)
	await _capture("boss4_ultimate_failure_1280x720.png", DESKTOP)

	_prepare_stage(4, 0.04, "idle", "", 0.0)
	game.boss4_death_timer = game.boss4_death_duration * 0.54
	game.boss4_death_pos = game.boss_pos
	game.boss_active = false
	game.boss_dead = true
	await _capture("boss4_death_1280x720.png", DESKTOP)

	_prepare_stage(1, 1.0, "land", "", 0.10)
	game.boss_entry_timer = game.BOSS4_ENTRY_TIME * 0.42
	game.boss_pos = game.boss4_entry_target + Vector2(0.0, -186.0)
	await _capture("boss4_entry_1280x720.png", DESKTOP)

	print("BOSS4_INTEGRAL_VISUAL_OK captures=", ", ".join(captures))
	_cleanup()
	for frame in range(4):
		await process_frame
	quit(0)


func _prepare_game() -> void:
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.qa_streaming_enabled = false
	game.gfx_screen_shake = false
	game.gfx_particles = true
	game.show_fps_counter = false
	game.ui_platform_override = "desktop"
	game.ui_platform_override_unlocked = true
	game._start_game(false)
	game.set_process(false)
	game._advance_to_phase(4)
	game.mode = "game"
	game.current_phase = 4
	game.player_pos = Vector2(800.0, 450.0)
	game.player_hp_max = 1000.0
	game.player_hp = 1000.0
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 8000.0
	game.boss_pos = Vector2(1010.0, 435.0)
	game.boss4_controller.reset()


func _prepare_stage(stage: int, hp_ratio: float, state: String, action: String, action_progress: float) -> void:
	root.size = DESKTOP
	game.ui_platform_override = "desktop"
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss4_stage = stage
	game.boss_hp = game.boss_hp_max * hp_ratio
	game.boss_pos = Vector2(1010.0, 435.0)
	game.boss4_ai_state["state"] = state
	game.boss4_ai_state["action"] = action
	game.boss4_ai_state["action_elapsed"] = action_progress
	game.boss4_ai_state["action_total_elapsed"] = action_progress
	game.boss4_ai_state["attack_dir"] = Vector2.LEFT
	game.boss4_ai_state["facing"] = -1.0
	game.boss4_visual_state_elapsed = action_progress
	game.boss4_hit_timer = 0.0
	game.boss4_death_timer = 0.0
	game.boss4_ultimate_active = false
	game.boss4_ultimate_outcome = ""
	game.boss4_ultimate_outcome_timer = 0.0
	game.boss4_rupture_anchors.clear()
	game.boss4_prison.clear()
	game.boss4_clone.clear()
	game.phase4_enemy_hazards.clear()
	game.phase4_planets.clear()
	game.phase4_null_zones.clear()
	game.effects.clear()
	game.enemy_bullets.clear()
	game.buttons.clear()
	game.screen_shake_timer = 0.0
	game.screen_shake_strength = 0.0


func _capture(file_name: String, size: Vector2i) -> void:
	root.size = size
	game.ui_platform_override = "mobile" if size == MOBILE else "desktop"
	game.buttons.clear()
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == size.x and image.get_height() == size.y, "invalid capture " + file_name)
	_check(image.get_used_rect().size.x > int(size.x * 0.75) and image.get_used_rect().size.y > int(size.y * 0.75), "blank capture " + file_name)
	var output := OUT_DIR.path_join(file_name)
	_check(image.save_png(output) == OK, "could not save " + file_name)
	captures.append(ProjectSettings.globalize_path(output))


func _cleanup() -> void:
	game._cleanup_runtime_resources()
	if game.music_player != null:
		game.music_player.stop()
		game.music_player.stream = null
	if game.rain_audio_player != null:
		game.rain_audio_player.stop()
		game.rain_audio_player.stream = null
	for player in game.sfx_players:
		if player != null:
			player.stop()
			player.stream = null
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
