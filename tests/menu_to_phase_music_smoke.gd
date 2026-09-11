extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MENU_TO_PHASE_MUSIC_SMOKE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.vol_master = 1.0
	game.vol_music = 1.0
	game.rng.seed = 9031
	game._play_music("Menu.mp3")
	if game.music_crossfade_active:
		game._finish_music_crossfade()
	_check(String(game.current_music).begins_with("Menu"), "menu music did not start before gameplay")
	_check(game.music_player != null and game.music_player.playing, "menu stream was not playing before gameplay")

	game.forced_initial_phase = 1
	game.phase_music_bag.clear()
	game._start_game()
	await process_frame

	var active_track: String = String(game.current_music)
	_check(active_track in game._phase_music_tracks(game.current_phase), "gameplay did not switch to phase playlist: " + active_track)
	_check(String(game.audio_stream_paths.get(active_track, "")).begins_with("res://Sounds/"), "gameplay music did not come from Sounds: " + active_track)
	_check(not active_track.begins_with("Menu"), "menu music remained current during gameplay")
	_check(not game.music_crossfade_active, "menu-to-game transition should not leave a menu crossfade active")
	_check(game.music_player != null and game.music_player.stream == game.audio_streams[active_track], "active stream does not match selected Sounds track")

	if game.has_method("_cleanup_runtime_resources"):
		game.call("_cleanup_runtime_resources")
	root.remove_child(game)
	game.free()
	game = null
	for _i in range(4):
		await process_frame
	print("MENU_TO_PHASE_MUSIC_SMOKE_OK track=%s source=Sounds menu_stopped=true" % active_track)
	quit(0)
