extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _seed_history() -> void:
	game.boss1_rewind_history.clear()
	for sample_index in range(126):
		var t = sample_index * game.BOSS1_REWIND_SAMPLE_INTERVAL
		var ratio = float(sample_index) / 125.0
		game.time_alive = t
		game.elapsed_unpaused = t
		game.player_pos = Vector2(180.0, 220.0).lerp(Vector2(820.0, 520.0), ratio)
		game.boss_pos = Vector2(1080.0, 620.0).lerp(Vector2(760.0, 390.0), ratio)
		game.player_hp = int(round(390.0 - ratio * 210.0))
		game.last_facing = Vector2.RIGHT if sample_index % 2 == 0 else Vector2.UP
		game.last_attack_time = t - 0.25
		game.last_dash_time = t - 1.0
		game.last_skill_time = t - 2.0
		game.last_secondary_time = t - 5.0
		game.last_damage_time = t - 0.4
		game.boss_phase = t * 6.0
		game.boss_attack_timer = 2.6 - ratio
		game.bullets = [{
			"pos": game.player_pos + Vector2.RIGHT * (44.0 + ratio * 240.0),
			"dir": Vector2.RIGHT,
			"kind": "eletrica",
			"life": 1.0,
			"speed": 600.0
		}]
		game.boss1_rewind_history.append(game._capture_boss1_rewind_snapshot())
	game.bullets.clear()


func _run() -> void:
	assert(is_equal_approx(game.BOSS1_REWIND_COOLDOWN, 45.0))
	assert(is_equal_approx(game.BOSS1_CLOCK_TURN_TIME, 2.0))
	assert(is_equal_approx(game.BOSS1_REWIND_PLAYBACK_TIME, 2.0))
	assert(game.audio_streams.has("Retrocede.mp3"))
	game._start_game()
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 1000.0
	game.boss_hp = 305.0
	game.player_hp_max = 450.0
	_seed_history()
	for player in game.sfx_players:
		player.stop()
		player.stream = null

	game._damage_boss(120.0, "eletrica")
	assert(is_equal_approx(game.boss1_rewind_cooldown, game.BOSS1_REWIND_COOLDOWN))
	assert(not game.boss1_time_wave.is_empty())
	assert(game.sfx_players.any(func(player): return player.stream == game.audio_streams["Retrocede.mp3"]))
	assert(game.boss_hp > 0.0 and game.boss_hp <= game.boss_hp_max * game.BOSS1_REWIND_THRESHOLD)
	var warning_radius = float(game.boss1_time_wave["radius"])
	game._update_boss1_time_wave(game.BOSS1_TIME_WAVE_WARNING * 0.50)
	assert(is_equal_approx(float(game.boss1_time_wave["radius"]), warning_radius))
	game.time_alive += game.BOSS1_REWIND_SAMPLE_INTERVAL
	game.player_pos += Vector2(45.0, -20.0)
	game._record_boss1_rewind_history(game.BOSS1_REWIND_SAMPLE_INTERVAL)
	assert(abs(float(game.boss1_rewind_history[-1]["time"]) - game.time_alive) < 0.01)
	assert(Vector2(game.boss1_rewind_history[-1]["player_pos"]).distance_to(game.player_pos) < 0.01)
	var rewind_target: Dictionary = game.boss1_rewind_history[0].duplicate(true)

	var origin = Vector2(game.boss1_time_wave["origin"])
	var max_radius = float(game.boss1_time_wave["max_radius"])
	game.player_pos = origin
	game.boss1_time_wave["radius"] = max_radius - 5.0
	game.boss1_time_wave["age"] = game.BOSS1_TIME_WAVE_WARNING
	game._update_boss1_time_wave(0.10)
	assert(float(game.boss1_time_wave["direction"]) < 0.0)
	assert(game.boss1_rewind_sequence.is_empty())

	game.player_pos = origin + Vector2.RIGHT * (max_radius - 42.0)
	game._update_boss1_time_wave(0.10)
	assert(game.boss1_time_wave.is_empty())
	assert(not game.boss1_rewind_sequence.is_empty())
	var hp_before_heal = game.boss_hp
	var expected_heal = (game.boss_hp_max - hp_before_heal) * game.BOSS1_REWIND_BOSS_HEAL
	var player_hp_at_impact = game.player_hp
	var expected_player_hp = int(round(player_hp_at_impact + (game.player_hp_max - player_hp_at_impact) * game.BOSS1_REWIND_PLAYER_HEAL))

	var total = game.BOSS1_CLOCK_TRAVEL_TIME + game.BOSS1_CLOCK_TURN_TIME + game.BOSS1_REWIND_PLAYBACK_TIME
	var simulated = 0.0
	while simulated < total + 0.20:
		game._update_boss1_rewind_sequence(0.05)
		simulated += 0.05

	assert(game.boss1_rewind_sequence.is_empty())
	assert(game.boss1_rewind_cooldown > 0.0)
	assert(game.player_pos.distance_to(Vector2(rewind_target["player_pos"])) < 0.1)
	assert(game.boss_pos.distance_to(Vector2(rewind_target["boss_pos"])) < 0.1)
	assert(game.player_hp == expected_player_hp)
	assert(abs(game.time_alive - float(rewind_target["time"])) < 0.01)
	assert(abs(game.last_skill_time - float(rewind_target["last_skill"])) < 0.01)
	assert(abs(game.boss_hp - (hp_before_heal + expected_heal)) < 0.05)
	assert(game.bullets.is_empty() and game.return_bullets.is_empty() and game.enemy_bullets.is_empty())

	game._start_boss1_time_wave()
	assert(game.boss1_time_wave.is_empty())

	game.boss_hp = game.boss_hp_max * 0.25
	game.boss1_rewind_cooldown = 0.05
	game._update_boss(0.06)
	assert(not game.boss1_time_wave.is_empty())
	assert(is_equal_approx(game.boss1_rewind_cooldown, game.BOSS1_REWIND_COOLDOWN))

	game.boss1_rewind_history = [game._capture_boss1_rewind_snapshot()]
	game.boss1_time_wave["radius"] = 100.0
	game.boss1_time_wave["direction"] = 1.0
	game.boss1_time_wave["max_radius"] = 600.0
	game.boss1_time_wave["age"] = game.BOSS1_TIME_WAVE_WARNING
	game.player_pos = game.boss_pos + Vector2.RIGHT * 155.0
	game._update_boss1_time_wave(0.20)
	assert(not game.boss1_rewind_sequence.is_empty())

	print("BOSS1_REWIND_SMOKE_OK recurring=true cooldown=45s rewind=8s anim=2s return_hit=true boss_heal=%.2f player_hp=%d" % [expected_heal, expected_player_hp])
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(4):
		await process_frame
	quit(0)
