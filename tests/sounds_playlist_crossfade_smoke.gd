extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("SOUNDS_PLAYLIST_CROSSFADE_FAIL " + message)
	quit(1)


func _sounds_dir_track_count() -> int:
	var count := 0
	var dir := DirAccess.open("res://Sounds")
	_check(dir != null, "res://Sounds not found")
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "mp3":
			count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	return count


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.vol_master = 1.0
	game.vol_music = 1.0
	game.current_phase = 1
	var tracks: Array = game._shared_phase_music_tracks()
	var expected_count := _sounds_dir_track_count()
	_check(expected_count >= 2, "expected at least two mp3 tracks in Sounds")
	_check(tracks.size() == expected_count, "registered track count does not match Sounds directory")
	for track in tracks:
		var path := String(game.audio_stream_paths.get(String(track), ""))
		_check(path.begins_with("res://Sounds/"), "track does not come from Sounds: " + String(track) + " path=" + path)

	game.phase_music_bag.clear()
	var seen := {}
	for i in range(tracks.size()):
		var chosen := String(game._next_phase_music_track(1))
		_check(chosen != "", "bag returned empty before all tracks played")
		_check(not seen.has(chosen), "bag repeated before exhausting playlist: " + chosen)
		seen[chosen] = true
	_check(seen.size() == tracks.size(), "bag did not expose every track once")
	var after_reset := String(game._next_phase_music_track(1))
	_check(after_reset != "", "playlist did not reset after exhausting all tracks")

	var first := String(tracks[0])
	var second := String(tracks[1])
	game._play_music(first)
	await process_frame
	_check(game.music_player != null and game.music_player.playing, "first track did not start")
	game._play_music(second)
	_check(game.music_crossfade_active, "crossfade did not activate when changing music")
	_check(game.music_crossfade_target_track == second, "crossfade target mismatch")
	game._update_music_crossfade(2.5)
	_check(db_to_linear(game.music_player.volume_db) < 1.0, "old track did not fade out")
	_check(db_to_linear(game.music_crossfade_player.volume_db) > 0.001, "new track did not fade in")
	game._update_music_crossfade(3.0)
	_check(not game.music_crossfade_active, "crossfade did not finish")
	_check(game.current_music == second, "current music not preserved after crossfade")
	print("SOUNDS_PLAYLIST_CROSSFADE_PASS tracks=%d crossfade=%.1fs reset_ok=true" % [tracks.size(), game.MUSIC_CROSSFADE_TIME])
	quit(0)
