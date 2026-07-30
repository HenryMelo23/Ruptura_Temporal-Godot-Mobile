extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _assert_has_all(list: Array, expected: Array[String], context: String) -> void:
	for track in expected:
		assert(track in list, "%s missing %s" % [context, track])


func _assert_audio_registered(expected: Array[String]) -> void:
	for track in expected:
		assert(game._audio_key_available(track), "audio key missing: %s" % track)


func _run() -> void:
	var shared_tracks: Array[String] = [
		"Fases1.mp3",
		"Fases2.mp3",
		"Fases3.mp3",
		"Fases4.mp3",
		"Fases5.mp3",
		"Fases6.mp3",
		"Fases7.mp3",
		"Fases8.mp3",
		"Fases9.mp3",
		"Fases10.mp3",
	]
	var phase3_only: Array[String] = ["Fase3-7.mp3"]
	_assert_has_all(game._shared_phase_music_tracks(), shared_tracks, "shared")
	_assert_has_all(game._phase_music_tracks(1), shared_tracks, "phase1")
	_assert_has_all(game._phase_music_tracks(2), shared_tracks, "phase2")
	_assert_has_all(game._phase_music_tracks(3), shared_tracks + phase3_only, "phase3")
	_assert_has_all(game._phase_music_tracks(4), shared_tracks, "phase4")
	assert("Fase3-7.mp3" not in game._phase_music_tracks(1))
	assert("Fase3-7.mp3" not in game._phase_music_tracks(2))
	assert("Fase3-7.mp3" not in game._phase_music_tracks(4))
	_assert_audio_registered(shared_tracks + phase3_only)
	if game.has_method("_cleanup_runtime_resources"):
		game.call("_cleanup_runtime_resources")
	if "textures" in game:
		game.textures.clear()
	if "audio_streams" in game:
		game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for _i in range(4):
		await process_frame
	print("PHASE_MUSIC_PLAYLIST_SMOKE_OK shared=%d phase3_extra=true" % shared_tracks.size())
	quit(0)
