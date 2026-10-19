extends SceneTree

const Boss1AnimationPresentation = preload("res://scripts/presentation/boss1_animation_presentation.gd")
const AssetController = preload("res://scripts/systems/assets/runtime_asset_controller.gd")

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
	var capture_size := Vector2i(960, 540) if path.contains("960x540") else Vector2i(1280, 720)
	root.mode = Window.MODE_WINDOWED
	root.borderless = true
	root.min_size = Vector2i.ZERO
	root.content_scale_size = capture_size
	root.size = capture_size
	for _frame in range(4):
		await process_frame
	game.queue_redraw()
	# Waiting on frame_post_draw can stall indefinitely under the headless
	# renderer. Two processed frames after queue_redraw are sufficient for the
	# viewport texture and keep this visual smoke bounded.
	await process_frame
	await process_frame
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("BOSS1_ANIMATION_VISUAL_FAIL renderer did not expose a viewport texture")
		return false
	var image := viewport_texture.get_image()
	if image == null or image.get_size() != capture_size or image.save_png(path) != OK:
		push_error("BOSS1_ANIMATION_VISUAL_FAIL expected=%s actual=%s path=%s" % [capture_size, image.get_size() if image != null else Vector2i.ZERO, path])
		return false
	return true


func _run() -> void:
	_prepare_boss()
	game.set_process(false)
	game.set_physics_process(false)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	Boss1AnimationPresentation.update(game, 0.01)
	if not await _capture("res://.codex/boss1_idle_remake_qa_1280x720.png"):
		quit(1)
		return

	game.boss1_animation_velocity = Vector2(90.0, 0.0)
	game.boss1_animation_motion_hold = 0.18
	game.boss1_animation_turn_timer = 0.0
	game.boss1_animation_state = Boss1AnimationPresentation.STATE_WALK
	game.boss1_animation_elapsed = 0.22
	assert(Boss1AnimationPresentation.active_texture(game) in game.textures["boss1_walk"])
	if not await _capture("res://.codex/boss1_walk_remake_qa_1280x720.png"):
		quit(1)
		return

	game.boss1_animation_velocity = Vector2.ZERO
	game.boss1_animation_motion_hold = 0.0
	game.boss_attacks.clear()
	game._add_boss_bubble(game.player_pos)
	game.boss_attacks[0]["age"] = 0.28
	Boss1AnimationPresentation.update(game, 0.28)
	if not await _capture("res://.codex/boss1_bubble_remake_qa_1280x720.png"):
		quit(1)
		return
	var windup_captures := [
		["bubble", "boss1_bubble"],
		["rain", "boss1_rain"],
		["sand", "boss1_sand"],
		["tide", "boss1_tide"],
	]
	game.boss1_absorb_cooldown = 999.0
	game.boss1_rewind_cooldown = 999.0
	for windup_capture in windup_captures:
		game.boss_attacks.clear()
		game.boss1_attack_windup.clear()
		game.boss_attack_timer = 99.0
		game.boss1_animation_velocity = Vector2(90.0, 0.0)
		game.boss1_animation_motion_hold = 0.18
		game.boss1_animation_turn_timer = 0.0
		game._start_boss1_attack_windup(String(windup_capture[0]), game.player_pos)
		var frozen_position: Vector2 = game.boss_pos
		game._update_boss(0.10)
		Boss1AnimationPresentation.update(game, 0.10)
		assert(game.boss_pos.is_equal_approx(frozen_position), "%s moved during visual pre-cast" % String(windup_capture[0]))
		assert(Boss1AnimationPresentation.active_texture(game) in game.textures[String(windup_capture[1])], "%s rendered locomotion instead of its pre-cast" % String(windup_capture[0]))
		if not await _capture("res://.codex/boss1_precast_%s_qa_1280x720.png" % String(windup_capture[0])):
			quit(1)
			return
	game.boss1_attack_windup.clear()

	game.boss_attacks.clear()
	game._add_boss_pincer_tenaz()
	game.boss_attacks[0]["state"] = "dash_first"
	game.boss_attacks[0]["state_age"] = 0.12
	Boss1AnimationPresentation.update(game, 0.01)
	if not await _capture("res://.codex/boss1_tenaz_remake_qa_1280x720.png"):
		quit(1)
		return
	var dash_directions := {
		"right": Vector2.RIGHT,
		"left": Vector2.LEFT,
		"up": Vector2.UP,
		"down": Vector2.DOWN,
	}
	for facing: String in dash_directions:
		game.boss_attacks[0]["first_dir"] = dash_directions[facing]
		if not await _capture("res://.codex/boss1_dash_%s_qa_1280x720.png" % facing):
			quit(1)
			return
		root.size = Vector2i(960, 540)
		game.gfx_low_resource = true
		if not await _capture("res://.codex/boss1_dash_%s_low_qa_960x540.png" % facing):
			quit(1)
			return
		root.size = Vector2i(1280, 720)
		game.gfx_low_resource = false
	game.boss_attacks[0]["state"] = "recovery"
	game.boss1_animation_motion_hold = 0.0
	Boss1AnimationPresentation.update(game, 0.01)
	if not await _capture("res://.codex/boss1_dash_recovery_qa_1280x720.png"):
		quit(1)
		return

	var cast_captures := [
		["rain", Callable(game, "_add_boss_rain").bind(7), "boss1_rain", 3, 0.38],
		["sand", Callable(game, "_add_boss_sand").bind(1), "boss1_sand", 5, 0.70],
		["tide", Callable(game, "_add_boss_tide"), "boss1_tide", 3, 0.38],
	]
	for cast_capture in cast_captures:
		game.boss_attacks.clear()
		cast_capture[1].call()
		game.boss_attacks[-1]["age"] = float(cast_capture[4])
		Boss1AnimationPresentation.update(game, 0.01)
		assert(Boss1AnimationPresentation.active_texture(game) == game.textures[String(cast_capture[2])][int(cast_capture[3])])
		if not await _capture("res://.codex/boss1_%s_release_qa_1280x720.png" % String(cast_capture[0])):
			quit(1)
			return
		root.size = Vector2i(960, 540)
		game.gfx_low_resource = true
		var texture_key := String(cast_capture[2])
		var full_frames: Array = game.textures[texture_key]
		game.textures[texture_key] = AssetController._compact_boss1_animation_spec(texture_key, full_frames)
		if not await _capture("res://.codex/boss1_%s_release_low_qa_960x540.png" % String(cast_capture[0])):
			quit(1)
			return
		game.textures[texture_key] = full_frames
		root.size = Vector2i(1280, 720)
		game.gfx_low_resource = false

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

	print("BOSS1_ANIMATION_VISUAL_OK idle_walk_bubble_precast_tenaz_dash_recovery_rain_sand_tide_rewind=1280x720 hit_jump_death=1280x720 low=960x540")
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	game = null
	await process_frame
	quit(0)
