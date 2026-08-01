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


func _shared_track_number(name: String) -> int:
	return int(name.get_basename().substr(5))


func _shared_track_less(a: String, b: String) -> bool:
	var left := _shared_track_number(a)
	var right := _shared_track_number(b)
	if left == right:
		return a < b
	return left < right


func _shared_tracks_on_disk() -> Array[String]:
	var tracks: Array[String] = []
	var dir := DirAccess.open("res://")
	assert(dir != null, "could not inspect project root for FasesN tracks")
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var stem := file_name.get_basename()
		var suffix := stem.substr(5)
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "mp3" and stem.begins_with("Fases") and suffix.is_valid_int():
			tracks.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	tracks.sort_custom(_shared_track_less)
	return tracks


func _run() -> void:
	var shared_tracks: Array[String] = _shared_tracks_on_disk()
	assert(shared_tracks.size() >= 12, "expected at least the current Fases1-Fases12 playlist")
	assert(game._shared_phase_music_tracks() == shared_tracks, "shared phase playlist does not mirror all FasesN.mp3 files")
	var phase1_only: Array[String] = ["Fase1.mp3", "Fase1-2.mp3", "Fase1-4.mp3"]
	var phase2_only: Array[String] = ["Fase2.mp3", "Fase2-3.mp3", "Fase2-4.mp3"]
	var phase3_only: Array[String] = ["Fase3-2.mp3", "Fase3-7.mp3"]
	var phase4_only: Array[String] = ["Fase4-4.mp3"]
	_assert_has_all(game._shared_phase_music_tracks(), shared_tracks, "shared")
	_assert_has_all(game._phase_music_tracks(1), shared_tracks + phase1_only, "phase1")
	_assert_has_all(game._phase_music_tracks(2), shared_tracks + phase2_only, "phase2")
	_assert_has_all(game._phase_music_tracks(3), shared_tracks + phase3_only, "phase3")
	_assert_has_all(game._phase_music_tracks(4), shared_tracks + phase4_only, "phase4")
	for track in game._shared_phase_music_tracks():
		assert(String(track).begins_with("Fases"), "shared playlist leaked non-global track: %s" % String(track))
	for leaked in ["Fase1.mp3", "Fase2.mp3", "Fase3-7.mp3", "Fase4-4.mp3", "Fase_boas.mp3", "fases.mp3", "Tema_Neve.mp3", "Tema_Praia.mp3", "Tema_Ratos.mp3"]:
		assert(leaked not in game._shared_phase_music_tracks(), "non-global track leaked into shared playlist: " + leaked)
	assert("Fase3-7.mp3" not in game._phase_music_tracks(1))
	assert("Fase3-7.mp3" not in game._phase_music_tracks(2))
	assert("Fase3-7.mp3" not in game._phase_music_tracks(4))
	assert("Fase1.mp3" not in game._phase_music_tracks(2))
	assert("Fase2.mp3" not in game._phase_music_tracks(1))
	assert("Fase4-4.mp3" not in game._phase_music_tracks(3))
	_assert_audio_registered(shared_tracks + phase1_only + phase2_only + phase3_only + phase4_only)
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
