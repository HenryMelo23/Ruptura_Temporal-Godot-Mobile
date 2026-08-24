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
	_check(game._shared_phase_music_tracks().size() >= 12, "missing Sounds/FasesN phase playlist tracks")
	for track in game._shared_phase_music_tracks():
		_check(game.audio_stream_paths.has(track), "missing shared phase music path: " + String(track))
		_check(String(game.audio_stream_paths[track]).begins_with("res://Sounds/"), "shared phase track not loaded from Sounds: " + String(track))
	_check(game.audio_streams.has("Boss1-Music-3.mp3"), "missing boss1 playlist alternate")
	_check(game.audio_streams.has("Boss2-Music-4.mp3"), "missing converted boss2 playlist track")
	for new_boss_track in ["Fase3_Boss-1.mp3.mp3", "Fase3_Boss-2.mp3.mp3", "Fase4_Boss-1.mp3", "Fase4_Boss-2.mp3", "Fase5_Boss-1.mp3", "Fase5_Boss-2.mp3", "Fase5_Boss-3.mp3", "Fase7_Boss-1.mp3", "Fase7_Boss-2.mp3"]:
		_check(game.audio_streams.has(new_boss_track), "missing new boss playlist track: " + new_boss_track)
	for track in game._shared_phase_music_tracks() + ["Menu.mp3", "Nevasca.mp3", "Congelando.mp3", "Descongelando.mp3", "Retrocede.mp3"]:
		_check(game.audio_streams.has(track), "missing extra phase track: " + track)
	for shared_track in game._shared_phase_music_tracks():
		_check(String(shared_track).begins_with("Fases"), "shared playlist contains a non-global phase track: " + String(shared_track))
	for leaked in ["Fase1.mp3", "Fase2.mp3", "Fase3-7.mp3", "Fase4-4.mp3", "Fase_boas.mp3", "fases.mp3", "Tema_Neve.mp3", "Tema_Praia.mp3", "Tema_Ratos.mp3", "Boss1-1.mp3", "Boss2.mp3", "Boss3.mp3", "Fase2_Boss.mp3", "Fase3_Boss.mp3"]:
		_check(not (leaked in game._shared_phase_music_tracks()), "legacy or phase-specific track leaked into shared playlist: " + leaked)
		_check(not game.audio_stream_paths.has(leaked), "legacy boss music registered: " + leaked)
	for phase in [1, 2, 3, 4, 5, 7]:
		for track in game._boss_music_tracks(phase):
			_check(game.audio_streams.has(track), "missing boss playlist stream: " + String(track))
	for phase in [1, 2, 3, 4, 5, 6, 7]:
		for track in game._shared_phase_music_tracks():
			_check(track in game._phase_music_tracks(phase), "shared phase track not available in phase %d: %s" % [phase, track])
	_check(not ("Fase1.mp3" in game._phase_music_tracks(2)), "Fase1 leaked into phase 2")
	_check(not ("Fase2.mp3" in game._phase_music_tracks(1)), "Fase2 leaked into phase 1")
	_check(not ("Fase_boas.mp3" in game._phase_music_tracks(5)), "legacy Fase_boas leaked into phase 5")
	_check(not ("fases.mp3" in game._phase_music_tracks(6)), "legacy fases.mp3 leaked into phase 6")
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
	_check(game.audio_streams["Fases1.mp3"] is AudioStreamMP3, "Fases1 is not MP3")
	_check(game.audio_streams["Boss1-Music-3.mp3"] is AudioStreamMP3, "Boss1 is not MP3")
	_check(not game.audio_streams["Fases1.mp3"].loop, "Fases1 should rotate")
	_check(not game.audio_streams["Boss1-Music-3.mp3"].loop, "Boss1 should rotate instead of looping")

	game.current_phase = 1
	game.rng.seed = 7319
	var heard = {}
	for iteration in range(12):
		game._play_phase_music_random(1)
		_check(game.current_music in game._phase_music_tracks(1), "unexpected phase1 track")
		heard[game.current_music] = true
		game._on_music_finished()
		_check(game.music_player.playing, "music did not restart after finished")
	_check(heard.size() >= 2, "phase1 rotation did not vary with the expanded playlist")

	game._play_music("Fases1.mp3")
	if game.music_crossfade_active:
		game._finish_music_crossfade()
	game.music_pause_fade_mode = ""
	game.music_player.stop()
	game._update_music_pause_fade(0.1)
	_check(game.music_player.playing, "stopped music did not recover")
	_check(game.music_pause_fade_mode != "auto_out", "auto fade mode returned")

	game.boss_active = true
	game.boss_dead = false
	game._play_boss_music_random()
	_check(game.current_music in game._boss_music_tracks(1), "boss1 playlist did not select an exclusive track")
	var boss_stream_ok: bool = game.music_player.stream == game.audio_streams[game.current_music]
	if not boss_stream_ok and game.music_crossfade_active and game.music_crossfade_player != null:
		boss_stream_ok = game.music_crossfade_player.stream == game.audio_streams[game.current_music]
	_check(boss_stream_ok, "boss1 stream mismatch")
	_check(game.music_player.playing or (game.music_crossfade_player != null and game.music_crossfade_player.playing), "boss1 music not playing")
	game._on_music_finished()
	_check(game.current_music in game._boss_music_tracks(1), "boss playlist did not rotate")

	print("MUSIC_ROTATION_SMOKE_OK phase_tracks=true boss_playlists=true root_sfx=true no_silent_stop=true")
	quit(0)
