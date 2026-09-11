extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _expect(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("BOSS2_ULTIMATE_SMOKE_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()
	game.current_phase = 2
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = 6000.0
	game.player_hp_max = 450
	game.player_hp = 450
	game.player_pos = game.WORLD_SIZE * 0.5
	game.boss_pos = game.player_pos + Vector2(360, 0)
	game.boss_attacks.clear()
	game._reset_boss2_state()

	game.boss_hp = game.boss_hp_max * 0.60
	game._update_boss_phase2(0.16)
	_expect(game.boss2_ultimate_timer <= 0.0, "ultimate_started_above_40_percent")
	game.boss_hp = game.boss_hp_max * game.BOSS2_ULTIMATE_HP_THRESHOLD
	game._update_boss_phase2(0.16)
	_expect(game.boss2_ultimate_timer > 0.0, "ultimate_did_not_start_at_40_percent")
	_expect(game.boss2_ultimate_used, "ultimate_not_marked_used")
	game.boss2_ultimate_timer = 0.0
	game.boss2_ultimate_used = false
	game._start_boss2_ultimate()
	_expect(game.boss2_ultimate_timer == game.BOSS2_ULTIMATE_DURATION, "duration_not_started")
	_expect(game.BOSS2_ULTIMATE_DURATION == 40.0, "duration_not_40_seconds")
	_expect(game.boss2_ultimate_cooldown == 0.0, "ultimate_should_have_no_initial_cooldown")
	_expect(game.BOSS2_ULTIMATE_SAFE_RADIUS == 485.0, "safe_radius_not_485")
	_expect(game.boss_attacks.is_empty(), "old_attacks_not_cleared")
	game.boss2_ultimate_spit_timer = 2.0
	game.boss2_ultimate_wind_active = 0.0
	_expect(not game._boss2_ultimate_boss_visible(), "boss_should_hide_inside_blizzard")
	game.boss2_ultimate_spit_timer = 0.8
	_expect(game._boss2_ultimate_boss_visible(), "boss_should_reveal_before_ice_spit")
	game.boss2_ultimate_spit_timer = 2.0
	game.boss2_ultimate_wind_active = 1.0
	_expect(game._boss2_ultimate_boss_visible(), "boss_should_reveal_during_wind")
	game.boss2_ultimate_wind_active = 0.0
	game.boss_attacks.clear()
	game.boss2_ultimate_hail_timer = 0.0
	game._update_boss2_ultimate_hail(0.01)
	_expect(game.boss_attacks.any(func(a): return a.get("kind") == "ice_pillar"), "blizzard_hail_not_spawned")
	var bullets_before: int = game.enemy_bullets.size()
	game.boss2_ultimate_fan_timer = 0.0
	game._update_boss2_ultimate_fan(0.01)
	_expect(game.enemy_bullets.size() >= bullets_before + 5, "blizzard_fan_not_spawned")

	var timer_after_start: float = game.boss2_ultimate_timer
	game._boss2_ultimate_player_hit_boss("eletrica")
	_expect(is_equal_approx(game.boss2_ultimate_timer, timer_after_start), "player_hit_changed_fixed_timer")
	game._boss2_ultimate_boss_hit_player("frost_shard")
	_expect(is_equal_approx(game.boss2_ultimate_timer, timer_after_start), "boss_hit_changed_fixed_timer")

	var old_pos: Vector2 = game.boss_pos
	game._update_boss2_ultimate_orbit(0.35)
	_expect(game.boss_pos != old_pos, "boss_did_not_orbit")

	game.player_pos = game.boss2_ultimate_center + Vector2(game.BOSS2_ULTIMATE_SAFE_RADIUS + 80.0, 0)
	game.boss2_ultimate_blizzard_tick = 0.01
	var hp_before: int = game.player_hp
	game._update_boss2_ultimate_blizzard_damage(0.04)
	_expect(game.player_hp < hp_before, "blizzard_did_not_damage_outside_safe_zone")

	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(360, 0)
	game.boss2_ultimate_wind_dir = Vector2.LEFT
	game.boss2_ultimate_wind_active = 1.0
	var wind_before: Vector2 = game.player_pos
	game._update_boss2_ultimate_wind(0.20)
	_expect(game.player_pos.x < wind_before.x, "wind_did_not_push_player_to_center")
	game.player_pos = wind_before
	game.touch_move = Vector2.RIGHT
	game.move_touch_index = 7
	game.boss2_ultimate_wind_active = 1.0
	game._update_boss2_ultimate_wind(0.20)
	var resisted_push: float = wind_before.x - game.player_pos.x
	_expect(resisted_push < 16.0, "opposite_analog_did_not_resist_center_wind")

	print("BOSS2_ULTIMATE_SMOKE_OK timer=true orbit=true blizzard=true wind=true")
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
	for i in range(4):
		await process_frame
	quit(0)
