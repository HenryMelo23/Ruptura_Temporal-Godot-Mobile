extends SceneTree

const Boss2AnimationPresentation = preload("res://scripts/presentation/boss2_animation_presentation.gd")

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
	game.current_phase = 2
	game._prepare_phase_texture_assets(2)
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = game.boss_hp_max
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(330.0, 0.0)
	game.enemies.clear()
	game.effects.clear()
	game._reset_boss2_state()
	game.set_process(false)
	game.set_physics_process(false)


func _cleanup_game() -> void:
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
	var texture := root.get_texture()
	if texture == null:
		return false
	var image := texture.get_image()
	return image != null and image.get_size() == capture_size and image.save_png(path) == OK


func _run() -> void:
	_prepare_boss()
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var captures := [
		[game.BOSS2_STATE_IDLE, 0, "res://.codex/boss2_remaster_idle_qa_1280x720.png", Vector2i(1280, 720)],
		[game.BOSS2_STATE_GLACIAL_STOMP, 1, "res://.codex/boss2_remaster_stomp_qa_1280x720.png", Vector2i(1280, 720)],
		[game.BOSS2_STATE_ICE_PRISON, 1, "res://.codex/boss2_remaster_prison_qa_1280x720.png", Vector2i(1280, 720)],
		[game.BOSS2_STATE_HUNT_MARK, 0, "res://.codex/boss2_remaster_hunt_qa_1280x720.png", Vector2i(1280, 720)],
	]
	for capture_value in captures:
		game.boss2_state = String(capture_value[0])
		game.boss2_anim_frame = int(capture_value[1])
		assert(Boss2AnimationPresentation.active_texture(game) != null)
		if not await _capture(String(capture_value[2]), capture_value[3]):
			push_error("BOSS2_ANIMATION_VISUAL_FAIL " + String(capture_value[2]))
			quit(1)
			return

	game.gfx_low_resource = true
	game.boss2_state = game.BOSS2_STATE_DOUBLE_BLIZZARD
	game.boss2_anim_frame = 1
	if not await _capture("res://.codex/boss2_remaster_blizzard_low_qa_960x540.png", Vector2i(960, 540)):
		push_error("BOSS2_ANIMATION_VISUAL_FAIL low")
		quit(1)
		return

	game.boss_active = false
	game.boss_dead = true
	game.boss2_death_animation_duration = Boss2AnimationPresentation.DEATH_DURATION
	game.boss2_death_animation_timer = 0.72
	game.boss2_death_animation_pos = game.boss_pos
	if not await _capture("res://.codex/boss2_remaster_death_qa_1280x720.png", Vector2i(1280, 720)):
		push_error("BOSS2_ANIMATION_VISUAL_FAIL death")
		quit(1)
		return

	print("BOSS2_ANIMATION_VISUAL_OK idle_stomp_prison_hunt_death=1280x720 blizzard_low=960x540")
	_cleanup_game()
	await process_frame
	await process_frame
	quit(0)
