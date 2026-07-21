extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 1000.0
	game.boss_hp = 310.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(160.0, 0.0)
	game.boss1_rewind_cooldown = game.BOSS1_REWIND_COOLDOWN

	game._damage_boss(20.0, "eletrica")
	assert(game.boss1_rain_active)
	assert(game.weather_kind == "rain")
	assert(game.rain_audio_player == null or game.rain_audio_player.playing)
	assert(game.puddles.size() > 0)
	for puddle in game.puddles:
		assert(float(puddle["r"]) >= game.WEATHER_PUDDLE_MIN_SIZE)
		assert(float(puddle["r"]) <= game.WEATHER_PUDDLE_MAX_SIZE)

	var puddle = game.puddles[0]
	game.player_pos = Vector2(puddle["pos"])
	assert(is_equal_approx(game._environment_player_slow_mult(), game.WEATHER_PUDDLE_SLOW_MULT))

	game._update_environment_weather(0.25)
	assert(game.raindrops.size() > 0 or game.rain_splashes.size() > 0)

	game.time_alive = 624.0
	game.elapsed_unpaused = 624.0
	game._advance_to_phase(2)
	assert(is_equal_approx(game.time_alive, 624.0))
	assert(is_equal_approx(game.elapsed_unpaused, 624.0))
	assert(game.boss1_rain_active)
	assert(game.weather_kind == "snow")
	assert(game.puddles.is_empty())
	assert(game.snowflakes.size() > 0)
	assert(game.rain_audio_player == null or not game.rain_audio_player.playing)
	assert(game.rain_audio_fade_mode == "")

	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp = 280.0
	game._start_boss1_rain()
	assert(game.rain_audio_player == null or game.rain_audio_player.playing)
	game._go_to_menu()
	assert(not game.boss1_rain_active)
	assert(game.weather_kind == "")
	assert(game.rain_audio_player == null or not game.rain_audio_player.playing)
	assert(game.rain_audio_fade_mode == "")

	print("BOSS1_WEATHER_SMOKE_OK rain_threshold=30%% puddles=%d slow=10%% snowflakes=%d" % [game.WEATHER_MAX_PUDDLES, game.snowflakes.size()])
	quit(0)
