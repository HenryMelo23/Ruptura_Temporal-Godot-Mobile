extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("AUDIO_LIFECYCLE_SMOKE_FAIL " + message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.mode = "game"
	game.current_music = "Fase2.mp3"
	var test_stream := AudioStreamWAV.new()
	test_stream.mix_rate = 44100
	test_stream.format = AudioStreamWAV.FORMAT_16_BITS
	test_stream.stereo = false
	var silence := PackedByteArray()
	silence.resize(44100 * 2 * 3)
	test_stream.data = silence
	game.music_player.stream = test_stream
	game.music_player.volume_db = linear_to_db(0.5)
	game.music_player.play()
	await process_frame
	_check(game.music_player.playing, "test music did not start")
	
	game._apply_pause_state(true)
	_check(game.mode == "paused", "pause state was not entered")
	_check(game.music_player.stream_paused, "pause did not pause music stream")
	_check(game.current_music == "Fase2.mp3", "pause changed current music")
	
	game._apply_pause_state(false)
	_check(not game.music_player.stream_paused, "resume did not unpause music stream")
	_check(game.music_player.playing, "resume did not keep music playing")
	_check(game.current_music == "Fase2.mp3", "resume restarted or swapped music")
	
	game.current_music = "Fase2.mp3"
	game.music_player.stream = test_stream
	game.music_player.stream_paused = false
	game.music_player.play()
	game._stop_battle_music_for_screen_transition()
	_check(game.current_music == "", "battle music key was not cleared on screen transition")
	_check(game.music_player.stream == null, "battle music stream was not released on screen transition")
	_check(not game.music_player.playing, "battle music kept playing after screen transition")
	
	print("AUDIO_LIFECYCLE_SMOKE_PASS pause_resume_and_transition_stop")
	quit(0)
