extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _assert_audio_registered(expected: Array[String]) -> void:
	for track in expected:
		assert(game._audio_key_available(track), "audio key missing: %s" % track)


func _shared_track_number(name: String) -> int:
	if not name.get_basename().begins_with("Fases"):
		return 999999
	var suffix := name.get_basename().substr(5)
	return int(suffix) if suffix.is_valid_int() else 999999


func _shared_track_less(a: String, b: String) -> bool:
	var left := _shared_track_number(a)
	var right := _shared_track_number(b)
	if left == right:
		return a.to_lower() < b.to_lower()
	return left < right


func _shared_tracks_on_disk() -> Array[String]:
	var tracks: Array[String] = []
	var dir := DirAccess.open("res://Sounds")
	assert(dir != null, "could not inspect res://Sounds")
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "mp3":
			tracks.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	tracks.sort_custom(_shared_track_less)
	return tracks


func _run() -> void:
	await process_frame
	var shared_tracks: Array[String] = _shared_tracks_on_disk()
	assert(shared_tracks.size() >= 12, "expected the Sounds playlist to contain the phase music set")
	assert(game._shared_phase_music_tracks() == shared_tracks, "shared phase playlist does not mirror Sounds/*.mp3")
	for phase in [1, 2, 3, 4, 6, 7]:
		assert(game._phase_music_tracks(phase) == shared_tracks, "phase %d leaked a non-Sounds playlist" % phase)
	for track in game._shared_phase_music_tracks():
		var path := String(game.audio_stream_paths.get(String(track), ""))
		assert(path.begins_with("res://Sounds/"), "normal phase track does not come from Sounds: %s path=%s" % [String(track), path])
	for leaked in ["Fase1.mp3", "Fase2.mp3", "Fase3-7.mp3", "Fase4-4.mp3", "Fase_boas.mp3", "fases.mp3", "Tema_Neve.mp3", "Tema_Praia.mp3", "Tema_Ratos.mp3"]:
		assert(leaked not in game._shared_phase_music_tracks(), "legacy root track leaked into normal phase playlist: " + leaked)
		for phase in [1, 2, 3, 4, 6, 7]:
			assert(leaked not in game._phase_music_tracks(phase), "legacy root track leaked into phase %d: %s" % [phase, leaked])
	_assert_audio_registered(shared_tracks)
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
	print("PHASE_MUSIC_PLAYLIST_SMOKE_OK sounds_tracks=%d legacy_phase_tracks_ignored=true" % shared_tracks.size())
	quit(0)
