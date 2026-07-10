extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MUSIC_ROTATION_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	_check(game.audio_streams.has("Fase1.mp3"), "missing Fase1.mp3")
	_check(game.audio_streams.has("Fase1-2.mp3"), "missing Fase1-2.mp3")
	_check(game.audio_streams.has("Fase1-4.mp3"), "missing Fase1-4.mp3")
	_check(game.audio_streams.has("Boss1-1.mp3"), "missing Boss1-1.mp3")
	_check(game.audio_streams["Fase1.mp3"] is AudioStreamMP3, "Fase1 is not MP3")
	_check(game.audio_streams["Fase1-2.mp3"] is AudioStreamMP3, "Fase1-2 is not MP3")
	_check(game.audio_streams["Boss1-1.mp3"] is AudioStreamMP3, "Boss1 is not MP3")
	_check(not game.audio_streams["Fase1.mp3"].loop, "Fase1 should rotate")
	_check(not game.audio_streams["Fase1-2.mp3"].loop, "Fase1-2 should rotate")
	_check(game.audio_streams["Boss1-1.mp3"].loop, "Boss1 should loop")

	game.current_phase = 1
	game.rng.seed = 7319
	var heard = {}
	for iteration in range(12):
		game._play_phase1_music_random()
		_check(game.current_music in ["Fase1.mp3", "Fase1-2.mp3", "Fase1-4.mp3"], "unexpected phase1 track")
		heard[game.current_music] = true
		game._on_music_finished()
		_check(game.music_player.playing, "music did not restart after finished")
	_check(heard.has("Fase1.mp3") and heard.has("Fase1-2.mp3"), "phase1 rotation did not use the main alternates")

	game._play_music("Fase1.mp3")
	game.music_pause_fade_mode = ""
	game.music_player.stop()
	game._update_music_pause_fade(0.1)
	_check(game.music_player.playing, "stopped music did not recover")
	_check(game.music_pause_fade_mode != "auto_out", "auto fade mode returned")

	game._play_music("Boss1-1.mp3")
	_check(game.current_music == "Boss1-1.mp3", "boss1 track not selected")
	_check(game.music_player.stream == game.audio_streams["Boss1-1.mp3"], "boss1 stream mismatch")
	_check(game.music_player.playing, "boss1 music not playing")

	print("MUSIC_ROTATION_SMOKE_OK phase1_tracks=2 reroll=true repeat=true no_silent_stop=true boss1_loop=true")
	quit(0)
