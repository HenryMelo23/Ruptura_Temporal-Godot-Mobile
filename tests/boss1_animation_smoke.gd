extends SceneTree

const Boss1AnimationPresentation = preload("res://scripts/presentation/boss1_animation_presentation.gd")
const AssetController = preload("res://scripts/systems/assets/runtime_asset_controller.gd")


func _opaque_area(texture: Texture2D) -> int:
	var image := texture.get_image()
	var area := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.02:
				area += 1
	return area

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
	for key in ["boss1_idle", "boss1_walk", "boss1_turn", "boss1_bubble", "boss1_pincer", "boss1_pincer_up", "boss1_pincer_down", "boss1_absorb", "boss1_sand", "boss1_tide", "boss1_rain", "boss1_rewind", "boss1_hit", "boss1_jump", "boss1_death"]:
		for frame in game.textures[key]:
			var image: Image = frame.get_image()
			assert(image != null and image.get_size() == Vector2i(256, 256), key)
			var visible := image.get_used_rect()
			assert(visible.position.x >= 10 and visible.position.y >= 10 and visible.end.x <= 246 and visible.end.y <= 246, "%s needs transparent safety margin" % key)
			if key != "boss1_death":
				assert(maxi(visible.size.x, visible.size.y) >= 230, "%s silhouette must retain the canonical visual extent" % key)
				assert(visible.end.y >= 243 and visible.end.y <= 245, "%s feet must share the canonical ground anchor" % key)
	assert(Boss1AnimationPresentation.DRAW_SIZE.is_equal_approx(Vector2(184.0, 170.0) * 1.8), "Cronoguejo base scale must remain 80 percent above the previous size")
	var draw_scale := minf(Boss1AnimationPresentation.DRAW_SIZE.x / Boss1AnimationPresentation.FRAME_SIZE, Boss1AnimationPresentation.DRAW_SIZE.y / Boss1AnimationPresentation.FRAME_SIZE)
	var expected_visible_foot := -Boss1AnimationPresentation.DRAW_SIZE.y * 0.5 + 244.0 * draw_scale
	var shadow_foot := Boss1AnimationPresentation.SHADOW_CENTER_Y_OFFSET + Boss1AnimationPresentation.DRAW_SIZE.y * 0.5
	assert(absf(expected_visible_foot - shadow_foot) <= 1.0, "boss shadow must meet the visible feet")
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
		# Advance scheduled attacks to their actual emission, not a negative delay.
		for attack in game.boss_attacks:
			attack["age"] = 0.0
		Boss1AnimationPresentation.update(game, 0.01)
		assert(Boss1AnimationPresentation.active_texture(game) in game.textures[String(attack_case[2])], "%s has no real animation" % String(attack_case[0]))

	game.boss_attacks.clear()
	# A lingering projectile cannot drag an attack pose through locomotion.
	game.boss1_animation_motion_hold = 0.18
	game.boss1_animation_turn_timer = 0.0
	game.boss_attacks.append({"kind": "bubble", "age": 0.1, "duration": 2.0})
	assert(Boss1AnimationPresentation.active_texture(game) in game.textures["boss1_walk"])
	game.boss1_animation_motion_hold = 0.0
	game.boss_attacks[0]["age"] = -0.2
	game.boss1_hit_animation_timer = 0.0
	assert(Boss1AnimationPresentation.active_texture(game) in game.textures["boss1_idle"])
	var idle_texture: Texture2D = game.textures["boss1_idle"][0]
	var idle_rendered_area := float(_opaque_area(idle_texture)) * pow(Boss1AnimationPresentation.DRAW_SIZE.y / Boss1AnimationPresentation.FRAME_SIZE, 2.0)
	# Each leg follows its locked direction, independent of movement snapshots.
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		game.boss_attacks.clear()
		game.boss_attacks.append({"kind": "pincer_tenaz", "state": "dash_second", "age": 1.0, "state_age": 0.1, "first_dir": -direction, "second_dir": direction})
		var key := "boss1_pincer"
		if direction.y != 0.0:
			key += "_up" if direction.y < 0.0 else "_down"
		var directional_texture := Boss1AnimationPresentation.active_texture(game)
		assert(directional_texture in game.textures[key])
		var directional_size := Boss1AnimationPresentation.draw_size(game)
		var directional_rendered_area := float(_opaque_area(directional_texture)) * pow(directional_size.y / Boss1AnimationPresentation.FRAME_SIZE, 2.0)
		var perceived_area_ratio := directional_rendered_area / idle_rendered_area
		assert(perceived_area_ratio >= 0.85 and perceived_area_ratio <= 1.15, "dash %s changed perceived boss size: %.3f" % [direction, perceived_area_ratio])
		var directional_draw_scale := directional_size.y / Boss1AnimationPresentation.FRAME_SIZE
		var directional_visible_foot := -directional_size.y * 0.5 + 244.0 * directional_draw_scale
		var directional_shadow_foot := Boss1AnimationPresentation.shadow_center(Vector2.ZERO, directional_size).y + directional_size.y * 0.5
		assert(absf(directional_visible_foot - directional_shadow_foot) <= 1.0, "dash %s shadow lost its ground anchor" % direction)
		assert(Boss1AnimationPresentation.should_flip_h(game) == (direction == Vector2.LEFT))
		var wire: Dictionary = bytes_to_var(var_to_bytes(game._pack_net_boss_visuals()))
		game.boss_attacks = Array(wire["boss_attacks"])
		assert(Boss1AnimationPresentation.active_texture(game) in game.textures[key], "replicated direction must select the same sprite")
		game.boss_attacks[0] = {"kind": "rush", "state": "dash", "age": 0.7, "dir": direction}
		assert(Boss1AnimationPresentation.active_texture(game) in game.textures[key])
		var full_frames: Array = game.textures[key]
		game.textures[key] = AssetController._compact_boss1_animation_spec(key, full_frames)
		assert(game.textures[key].size() == 3)
		assert(Boss1AnimationPresentation.active_texture(game) == full_frames[2], "LOW must retain the strike frame")
		game.textures[key] = full_frames
	game.boss_attacks[0]["state"] = "recovery"
	game.boss1_animation_motion_hold = 0.18
	assert(Boss1AnimationPresentation.active_texture(game) in game.textures["boss1_walk"])
	game.boss1_animation_motion_hold = 0.0
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

	print("BOSS1_ANIMATION_SMOKE_OK idle_walk_turn=true attacks=7 absorb_rewind=true hit_priority=true jump_frames=5 death_frames=6 directions=4 wire=true low_dash=true safe_margins=true canonical_extent=true perceived_scale=true shadow_anchor=true")
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
