extends SceneTree

const Boss3AnimationPresentation = preload("res://scripts/presentation/boss3_animation_presentation.gd")

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _prepare_boss() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.current_phase = 3
	game._prepare_phase_texture_assets(3)
	game.boss_ready = true
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 9000.0
	game.boss_hp = 9000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(360.0, 0.0)
	game.boss_attacks.clear()
	game._reset_phase3_state()


func _expect_state(expected: String) -> void:
	Boss3AnimationPresentation.update(game, 0.016)
	assert(Boss3AnimationPresentation.visual_state(game) == expected)
	assert(Boss3AnimationPresentation.active_texture(game) != null)
	assert(game.boss3_visual_state == expected)


func _move_boss(delta_pos: Vector2, delta: float = 0.1) -> void:
	game.boss3_is_moving = delta_pos.length() > 0.0
	game.boss_pos += delta_pos
	Boss3AnimationPresentation.update(game, delta)


func _assert_frame_integrity(animation_name: String, frame_count: int) -> void:
	for frame_index in range(1, frame_count + 1):
		var path := "res://assets/sprites/boss3/remake/%s/%s_%02d.png" % [animation_name, animation_name, frame_index]
		var image := Image.new()
		var load_error := image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
		assert(load_error == OK and not image.is_empty(), "Boss 3 frame could not be loaded: " + path)
		assert(image.get_size() == Vector2i(256, 256), "Boss 3 frame canvas drifted: " + path)
		var used_rect := image.get_used_rect()
		assert(used_rect.size.x > 0 and used_rect.size.y > 0, "Boss 3 frame is empty: " + path)
		var used_end := used_rect.position + used_rect.size
		assert(used_rect.position.x >= 1 and used_rect.position.y >= 1, "Boss 3 frame touches the top/left crop edge: " + path)
		assert(used_end.x <= 255 and used_end.y <= 255, "Boss 3 frame touches the bottom/right crop edge: " + path)
		assert(used_end.y >= 252, "Boss 3 ground anchor drifted upward: " + path)
		var alpha_center_x: float = float(used_rect.position.x) + float(used_rect.size.x) * 0.5
		assert(alpha_center_x >= 118.0 and alpha_center_x <= 138.0, "Boss 3 horizontal anchor drifted: " + path)
		if animation_name in ["idle", "walk", "hit"]:
			assert(used_rect.size.x >= 219 and used_rect.size.y >= 207, "Boss 3 core silhouette changed scale: " + path)


func _run() -> void:
	_prepare_boss()
	var expected_counts := {
		"idle": 6, "walk": 8, "entry": 8, "rat_spit": 6,
		"rat_tail": 6, "rat_rain": 6, "cheese_ritual": 8,
		"consume": 6, "faith": 7, "sector_ritual": 8,
		"miasma": 7, "hit": 3, "stun": 5, "death": 10
	}
	for animation_name in expected_counts:
		var frames: Array = game.textures.get("boss3_anim_" + animation_name, [])
		assert(frames.size() == int(expected_counts[animation_name]))
		assert(frames.all(func(frame): return frame != null))
		_assert_frame_integrity(animation_name, int(expected_counts[animation_name]))

	_expect_state("idle")
	_move_boss(Vector2(-12.0, 0.0))
	assert(Boss3AnimationPresentation.visual_state(game) == "walk")
	assert(not Boss3AnimationPresentation.should_flip_h(game), "Original left-facing walk must not be mirrored")
	_move_boss(Vector2(24.0, 0.0))
	assert(Boss3AnimationPresentation.visual_state(game) == "walk")
	assert(Boss3AnimationPresentation.should_flip_h(game), "Right-facing walk must mirror only the visual")
	var facing_after_right: float = game.boss3_facing_dir
	_move_boss(Vector2.ZERO)
	assert(Boss3AnimationPresentation.visual_state(game) == "idle")
	assert(game.boss3_facing_dir == facing_after_right, "Idle must preserve the last valid facing")

	# Movement damage lowers HP and emits overlay feedback without replacing walk.
	_move_boss(Vector2(14.0, 0.0))
	var moving_hp_before: float = game.boss_hp
	for hit_index in range(3):
		game._damage_boss(22.0, "boss3_walk_hit_%d" % hit_index, false, false)
	assert(game.boss_hp < moving_hp_before)
	assert(game.boss3_hit_animation_timer == 0.0, "Rapid walk hits must not create a static hit pose")
	assert(game.boss3_hit_feedback_timer > 0.0)
	assert(Boss3AnimationPresentation.visual_state(game) == "walk")
	_move_boss(Vector2.ZERO)
	game.boss3_hit_animation_timer = 0.0

	game.boss_entry_timer = game.BOSS3_ENTRY_TIME * 0.5
	_expect_state("entry")
	game.boss_entry_timer = 0.0
	game.boss3_stun_timer = 1.0
	_expect_state("stun")
	game.boss3_stun_timer = 0.0
	game.boss3_consume_uid = 77
	game.boss3_consume_timer = 0.5
	_expect_state("consume")
	game.boss3_consume_uid = -1
	game.boss3_consume_timer = 0.0
	game.boss3_ritual_timer = 1.0
	_expect_state("cheese_ritual")
	game.boss3_ritual_timer = 0.0
	game.boss_attacks = [{"kind": "boss3_sector_ritual", "age": 0.4, "duration": 3.0}]
	_expect_state("sector_ritual")
	game.boss_attacks.clear()
	game.boss3_miasma_variant = 2
	game.boss3_miasma_timer = 2.0
	_expect_state("miasma")
	game.boss3_miasma_variant = 0
	game.boss3_miasma_timer = 0.0
	game.boss3_faith_test_active = true
	_expect_state("faith")
	game.boss3_faith_test_active = false
	for attack_case in [
		["rat_tail", "rat_tail"],
		["rat_spit", "rat_spit"],
		["rat_rain", "rat_rain"]
	]:
		game.boss_attacks = [{"kind": attack_case[0], "age": 0.2, "duration": 0.65}]
		_expect_state(attack_case[1])
	game.boss_attacks.clear()

	# A stationary eligible hit gets a short pose and returns to idle.
	var idle_hp_before: float = game.boss_hp
	game._damage_boss(45.0, "boss3_idle_hit", false, false)
	assert(game.boss_hp < idle_hp_before)
	assert(game.boss3_hit_animation_timer > 0.0)
	_expect_state("hit")
	Boss3AnimationPresentation.update(game, game.boss3_hit_animation_duration + 0.02)
	_expect_state("idle")

	# Blocking casts retain their telegraph under damage and release into walk
	# immediately when their finite gameplay window ends.
	game.boss_attacks = [{"kind": "rat_spit", "age": 0.1, "duration": 0.36, "dir": Vector2.LEFT, "fired": false}]
	_expect_state("rat_spit")
	game._damage_boss(38.0, "boss3_cast_hit", false, false)
	assert(game.boss3_hit_animation_timer == 0.0)
	assert(Boss3AnimationPresentation.visual_state(game) == "rat_spit")
	game.boss_attacks.clear()
	_move_boss(Vector2(-13.0, 0.0))
	assert(Boss3AnimationPresentation.visual_state(game) == "walk")

	game.boss3_ritual_timer = 0.4
	_move_boss(Vector2(10.0, 0.0))
	assert(Boss3AnimationPresentation.visual_state(game) == "cheese_ritual")
	game.boss3_ritual_timer = 0.0
	_move_boss(Vector2(10.0, 0.0))
	assert(Boss3AnimationPresentation.visual_state(game) == "walk")
	_move_boss(Vector2.ZERO)

	# Optional action sets may be released on low-memory devices and must load
	# on first use without falling back to a missing sprite.
	game.textures.erase("boss3_anim_hit")
	var hp_before: float = game.boss_hp
	game._damage_boss(220.0, "boss3_animation_smoke", false, false)
	assert(game.boss_hp < hp_before)
	_expect_state("hit")
	assert(game.textures.get("boss3_anim_hit", []).size() == 3)
	var first_hit_timer: float = game.boss3_hit_animation_timer
	game._damage_boss(25.0, "veneno", false, false)
	assert(is_equal_approx(game.boss3_hit_animation_timer, first_hit_timer))

	game.boss3_hit_animation_timer = 0.0
	game.boss3_consume_uid = 99
	game.boss3_consume_timer = 0.3
	game.boss3_facing_dir = 1.0
	var packet: Dictionary = game._pack_net_boss_visuals()
	assert(int(packet.get("boss3_consume_uid", -1)) == 99)
	assert(is_equal_approx(float(packet.get("boss3_consume_timer", 0.0)), 0.3))
	assert(is_equal_approx(float(packet.get("boss3_facing_dir", 0.0)), 1.0))
	game.boss3_consume_uid = -1
	game.boss3_consume_timer = 0.0
	game.boss3_facing_dir = -1.0
	game._apply_remote_boss_visual_snapshot(packet)
	assert(game.boss3_consume_uid == 99)
	assert(is_equal_approx(game.boss3_consume_timer, 0.3))
	assert(is_equal_approx(game.boss3_facing_dir, 1.0))

	game.boss3_consume_uid = -1
	game.boss3_consume_timer = 0.0
	game.boss_hp = 10.0
	game._damage_boss(999999.0, "boss3_animation_smoke", false, false)
	assert(game.boss_dead and not game.boss_active)
	assert(Boss3AnimationPresentation.death_active(game))
	assert(Boss3AnimationPresentation.visual_state(game) == "death")
	assert(game.boss3_death_animation_pos == game.boss_pos)

	# A retry/phase reset clears transient presentation state and a phase change
	# cannot leave the previous animation latched.
	game.boss_dead = false
	game.boss_active = true
	game.boss_hp = game.boss_hp_max
	game._reset_phase3_state()
	assert(not Boss3AnimationPresentation.death_active(game))
	assert(Boss3AnimationPresentation.visual_state(game) == "idle")
	assert(is_equal_approx(game.boss3_facing_dir, -1.0))
	game.current_phase = 4
	Boss3AnimationPresentation.update(game, 0.016)
	assert(Boss3AnimationPresentation.visual_state(game).is_empty())
	game.current_phase = 3

	print("BOSS3_ANIMATION_SMOKE_OK states=14 frames=94 facing=left,right,idle walk_hit_nonblocking=true cast_hit_preserved=true cast_release=true lethal=true retry_reset=true transition_clear=true ground_anchor=true network_facing=true")
	if game.has_method("_cleanup_runtime_resources"):
		game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	await process_frame
	quit(0)
