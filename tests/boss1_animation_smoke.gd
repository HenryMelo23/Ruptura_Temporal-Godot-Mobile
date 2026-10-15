extends SceneTree

const Boss1AnimationPresentation = preload("res://scripts/presentation/boss1_animation_presentation.gd")

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare_boss() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.current_phase = 1
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = 6000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(380.0, 0.0)
	game.boss_stage_timer = 0.0
	game.boss1_hit_animation_timer = 0.0
	game.boss1_death_animation_timer = 0.0


func _run() -> void:
	_prepare_boss()
	for key in ["boss1_idle", "boss1_walk", "boss1_bubble", "boss1_pincer", "boss1_absorb", "boss1_sand", "boss1_tide", "boss1_rain", "boss1_rewind"]:
		assert(game.textures.get(key, []).size() == 4, "%s must expose four final remake frames" % key)
	assert(game.textures.get("boss1_turn", []).size() == 3)
	assert(game.textures.get("boss1_hit", []).size() == 5)
	assert(game.textures.get("boss1_jump", []).size() == 5)
	assert(game.textures.get("boss1_death", []).size() == 6)
	game.time_alive = 0.0
	var idle_size_a: Vector2 = game._boss_draw_size()
	game.time_alive = PI / 6.4
	var idle_size_b: Vector2 = game._boss_draw_size()
	assert(idle_size_a.is_equal_approx(idle_size_b))
	assert(Boss1AnimationPresentation.active_texture(game) in game.textures["boss1_idle"])

	# Facing follows effective movement with a deadzone, without flipping hitboxes.
	game.boss1_animation_previous_pos = game.boss_pos
	game.boss_pos += Vector2(-24.0, 0.0)
	Boss1AnimationPresentation.update(game, 0.1)
	assert(game.boss1_animation_state == Boss1AnimationPresentation.STATE_TURN)
	assert(Boss1AnimationPresentation.should_flip_h(game))
	game.boss_pos += Vector2(-24.0, 0.0)
	Boss1AnimationPresentation.update(game, Boss1AnimationPresentation.TURN_DURATION + 0.01)
	assert(game.boss1_animation_state == Boss1AnimationPresentation.STATE_WALK)
	assert(Boss1AnimationPresentation.active_texture(game) in game.textures["boss1_walk"])
	Boss1AnimationPresentation.update(game, 0.08)
	assert(game.boss1_animation_state == Boss1AnimationPresentation.STATE_WALK)
	Boss1AnimationPresentation.update(game, 0.12)
	assert(game.boss1_animation_state == Boss1AnimationPresentation.STATE_IDLE)
	game.boss_pos += Vector2(-12.0, 0.0)
	Boss1AnimationPresentation.update(game, 0.05)
	assert(game.boss1_animation_state == Boss1AnimationPresentation.STATE_WALK)

	var hp_before: float = game.boss_hp
	game._damage_boss(180.0, "boss1_animation_smoke", false, false)
	assert(game.boss_hp < hp_before)
	assert(game.boss1_hit_animation_timer > 0.0)
	# Damage while walking keeps locomotion; stopped damage may use hit frames.
	assert(Boss1AnimationPresentation.active_texture(game) in game.textures["boss1_walk"])
	game.boss1_animation_velocity = Vector2.ZERO
	game.boss1_animation_motion_hold = 0.0
	game.boss1_animation_turn_timer = 0.0
	assert(Boss1AnimationPresentation.active_texture(game) != null)
	assert(Boss1AnimationPresentation.active_texture(game) in game.textures["boss1_hit"])
	var first_hit_duration: float = game.boss1_hit_animation_duration
	game._damage_boss(180.0, "boss1_animation_smoke", false, false)
	assert(game.boss1_hit_animation_timer <= game.boss1_hit_animation_duration)
	assert(game.boss1_hit_animation_duration >= first_hit_duration)

	# Every live phase-1 attack family resolves to a real animation contract.
	var attack_cases := [
		["bubble", Callable(game, "_add_boss_bubble").bind(game.player_pos), "boss1_bubble"],
		["pressure", Callable(game, "_add_boss_pressure_bubbles").bind(5), "boss1_bubble"],
		["rain", Callable(game, "_add_boss_rain").bind(7), "boss1_rain"],
		["tide", Callable(game, "_add_boss_tide"), "boss1_tide"],
		["sand", Callable(game, "_add_boss_sand").bind(1), "boss1_sand"],
		["rush", Callable(game, "_add_boss_rush"), "boss1_pincer"],
		["tenaz", Callable(game, "_add_boss_pincer_tenaz"), "boss1_pincer"],
	]
	for attack_case in attack_cases:
		game.boss_attacks.clear()
		attack_case[1].call()
		Boss1AnimationPresentation.update(game, 0.01)
		assert(Boss1AnimationPresentation.active_texture(game) in game.textures[String(attack_case[2])], "%s has no real animation" % String(attack_case[0]))

	game.boss_attacks.clear()
	game.boss1_absorb_timer = game.BOSS1_ABSORB_DURATION
	Boss1AnimationPresentation.update(game, 0.01)
	assert(Boss1AnimationPresentation.active_texture(game) in game.textures["boss1_absorb"])
	game.boss1_absorb_timer = 0.0
	game.boss1_time_wave = {"radius": 42.0, "direction": 1.0}
	Boss1AnimationPresentation.update(game, 0.01)
	assert(Boss1AnimationPresentation.active_texture(game) in game.textures["boss1_rewind"])
	game.boss1_time_wave.clear()

	game.boss1_hit_animation_timer = 0.0
	game.boss_stage_duration = game.BOSS_STAGE_JUMP_TIME
	game.boss_stage_timer = game.boss_stage_duration - game.BOSS_STAGE_SLAM_TIME * 0.55
	var jump_frames: Array = game.textures["boss1_jump"]
	assert(Boss1AnimationPresentation.active_texture(game) == jump_frames[2])
	game.boss_stage_timer = game.boss_stage_duration - game.BOSS_STAGE_SLAM_TIME - 0.1
	assert(Boss1AnimationPresentation.active_texture(game) == jump_frames[4])
	game.boss_stage_timer = game.boss_stage_duration - game.BOSS_STAGE_SLAM_TIME - 0.5
	assert(Boss1AnimationPresentation.active_texture(game) in game.textures["boss1_idle"])

	game.boss_stage_timer = 0.0
	game.boss_hp = 10.0
	game._damage_boss(999999.0, "boss1_animation_smoke", false, false)
	assert(game.boss_dead)
	assert(not game.boss_active)
	assert(game.boss1_death_animation_timer > 0.0)
	assert(Boss1AnimationPresentation.death_active(game))
	assert(game.boss1_death_animation_pos == game.boss_pos)
	game.boss1_death_animation_timer = 0.0
	assert(not Boss1AnimationPresentation.death_active(game))

	print("BOSS1_ANIMATION_SMOKE_OK idle_walk_turn=true attacks=7 absorb_rewind=true hit_priority=true jump_frames=5 death_frames=6")
	if game.has_method("_cleanup_runtime_resources"):
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
	game.audio_streams.clear()
	game.textures.clear()
	root.remove_child(game)
	game.free()
	game = null
	for _frame in range(8):
		await process_frame
	quit(0)
