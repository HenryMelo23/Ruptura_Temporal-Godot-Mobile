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
	_check(game.audio_streams.has("Boss1-Music-3.mp3"), "missing boss1 playlist alternate")
	_check(game.audio_streams.has("Boss2-Music-4.mp3"), "missing converted boss2 playlist track")
	_check(game.audio_streams.has("Boss3-Music-1.mp3"), "missing boss3 playlist track")
	for track in ["Fases1.mp3", "Fases2.mp3", "Fases3.mp3", "Fases4.mp3", "Fases5.mp3", "Fase4-4.mp3"]:
		_check(game.audio_streams.has(track), "missing extra phase track: " + track)
	for phase in range(1, 4):
		for track in game._boss_music_tracks(phase):
			_check(game.audio_streams.has(track), "missing boss playlist stream: " + String(track))
	for phase in range(1, 6):
		for track in game._shared_phase_music_tracks():
			_check(track in game._phase_music_tracks(phase), "shared phase track not available in phase %d: %s" % [phase, track])
	_check("Fase4-4.mp3" in game._phase_music_tracks(4), "Fase4-4 is not exclusive to phase 4 playlist")
	_check(not ("Fase4-4.mp3" in game._phase_music_tracks(1)), "Fase4-4 leaked into phase 1")
	_check(not ("Fase4-4.mp3" in game._phase_music_tracks(5)), "Fase4-4 leaked into phase 5")
	_check(game.audio_streams.has("player_shot"), "missing player shot recording")
	_check(game.audio_streams.has("atk_lacerante_1") and game.audio_streams.has("lacerante_kill"), "missing Lacerante recordings")
	_check(game.audio_streams["player_shot"] is AudioStreamMP3, "player shot is not the root MP3 recording")
	_check(game.audio_streams["atk_lacerante_1"] is AudioStreamMP3, "Lacerante attack is not the root MP3 recording")
	for old_key in ["atk_eletrica", "atk_eletrica_charged", "atk_prismatica", "atk_retornante", "atk_parasitica", "atk_gravitante", "atk_ancorada", "ult_eletrica", "ult_gravitante", "Disparo_Geo.wav", "Disparo.MP3"]:
		_check(not game.audio_streams.has(old_key), "legacy weapon sfx was loaded: " + old_key)
	game.vol_master = 1.0
	game.vol_shots = 1.0
	for player in game.sfx_players:
		player.stop()
		player.stream = null
	game._play_sfx("atk_eletrica")
	_check(game.sfx_players[0].stream == game.audio_streams["player_shot"], "legacy attack did not redirect to player shot")
	for player in game.sfx_players:
		player.stop()
		player.stream = null
	game._play_sfx("ult_lacerante")
	_check(game.sfx_players[0].stream == game.audio_streams["atk_lacerante_3"], "Lacerante ultimate did not redirect to cut 3")
	_check(game.audio_streams["Fase1.mp3"] is AudioStreamMP3, "Fase1 is not MP3")
	_check(game.audio_streams["Fase1-2.mp3"] is AudioStreamMP3, "Fase1-2 is not MP3")
	_check(game.audio_streams["Boss1-1.mp3"] is AudioStreamMP3, "Boss1 is not MP3")
	_check(not game.audio_streams["Fase1.mp3"].loop, "Fase1 should rotate")
	_check(not game.audio_streams["Fase1-2.mp3"].loop, "Fase1-2 should rotate")
	_check(not game.audio_streams["Boss1-1.mp3"].loop, "Boss1 should rotate instead of looping")

	game.current_phase = 1
	game.rng.seed = 7319
	var heard = {}
	for iteration in range(12):
		game._play_phase1_music_random()
		_check(game.current_music in game._phase_music_tracks(1), "unexpected phase1 track")
		heard[game.current_music] = true
		game._on_music_finished()
		_check(game.music_player.playing, "music did not restart after finished")
	_check(heard.size() >= 2, "phase1 rotation did not vary with the expanded playlist")

	game._play_music("Fase1.mp3")
	game.music_pause_fade_mode = ""
	game.music_player.stop()
	game._update_music_pause_fade(0.1)
	_check(game.music_player.playing, "stopped music did not recover")
	_check(game.music_pause_fade_mode != "auto_out", "auto fade mode returned")

	game.boss_active = true
	game.boss_dead = false
	game._play_boss_music_random()
	_check(game.current_music in game._boss_music_tracks(1), "boss1 playlist did not select an exclusive track")
	_check(game.music_player.stream == game.audio_streams[game.current_music], "boss1 stream mismatch")
	_check(game.music_player.playing, "boss1 music not playing")
	game._on_music_finished()
	_check(game.current_music in game._boss_music_tracks(1), "boss playlist did not rotate")

	print("MUSIC_ROTATION_SMOKE_OK phase_tracks=true boss_playlists=true root_sfx=true no_silent_stop=true")
	quit(0)
