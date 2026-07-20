extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("RAIN_AUDIO_LIFECYCLE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _configure_raining_phase1() -> void:
	game._start_game()
	game.current_phase = 1
	game.mode = "game"
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 1000.0
	game.boss_hp = 250.0
	game.boss_entry_timer = 0.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_pos = game.boss_pos + Vector2(180.0, 0.0)
	game._start_boss1_rain()
	_check(game.boss1_rain_active, "rain did not activate in phase 1")
	_check(game.weather_kind == "rain", "weather kind did not become rain")
	_check(game.rain_audio_player != null and game.rain_audio_player.playing, "rain audio did not start")


func _run() -> void:
	_configure_raining_phase1()
	game._go_to_menu()
	_check(not game.boss1_rain_active, "rain state survived menu exit")
	_check(game.weather_kind == "", "weather kind survived menu exit")
	_check(game.rain_audio_fade_mode == "", "rain fade still active after menu exit")
	_check(game.rain_audio_player == null or not game.rain_audio_player.playing, "rain audio kept playing after menu exit")

	_configure_raining_phase1()
	game._advance_to_phase(2)
	_check(game.weather_kind != "rain", "rain weather survived phase transition")
	_check(game.rain_audio_fade_mode == "", "rain fade still active after phase transition")
	_check(game.rain_audio_player == null or not game.rain_audio_player.playing, "rain audio kept playing after phase transition")

	print("RAIN_AUDIO_LIFECYCLE_SMOKE_OK menu_stop=true phase_transition_stop=true")
	quit(0)
