extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	assert(game.audio_streams.has("Fase1.mp3"))
	assert(game.audio_streams.has("Fase1-2.mp3"))
	assert(game.audio_streams.has("Boss1-1.mp3"))
	assert(game.audio_streams["Fase1.mp3"] is AudioStreamMP3)
	assert(game.audio_streams["Fase1-2.mp3"] is AudioStreamMP3)
	assert(game.audio_streams["Boss1-1.mp3"] is AudioStreamMP3)
	assert(not game.audio_streams["Fase1.mp3"].loop)
	assert(not game.audio_streams["Fase1-2.mp3"].loop)
	assert(game.audio_streams["Boss1-1.mp3"].loop)

	game.current_phase = 1
	game.rng.seed = 7319
	var heard = {}
	for iteration in range(32):
		game._play_phase1_music_random()
		assert(game.current_music == "Fase1.mp3" or game.current_music == "Fase1-2.mp3")
		heard[game.current_music] = true
		game._on_music_finished()
		assert(game.music_player.playing)
	assert(heard.has("Fase1.mp3") and heard.has("Fase1-2.mp3"))

	game._play_music("Boss1-1.mp3")
	assert(game.current_music == "Boss1-1.mp3")
	assert(game.music_player.stream == game.audio_streams["Boss1-1.mp3"])
	assert(game.music_player.playing)

	print("MUSIC_ROTATION_SMOKE_OK phase1_tracks=2 reroll=true repeat=true boss1_loop=true")
	quit(0)
