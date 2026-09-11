class_name RTAudioLifecycle
extends RefCounted


static func is_shared_phase_music_name(name: String) -> bool:
	if name.get_extension().to_lower() != "mp3":
		return false
	var stem: = name.get_basename()
	if not stem.begins_with("Fases"):
		return false
	var suffix: = stem.substr(5)
	return suffix.is_valid_int()


static func shared_phase_music_index(name: String) -> int:
	var stem: = name.get_basename()
	if not stem.begins_with("Fases"):
		return 999999
	var suffix: = stem.substr(5)
	if not suffix.is_valid_int():
		return 999999
	return int(suffix)


static func shared_phase_music_less(a, b) -> bool:
	var left: = String(a)
	var right: = String(b)
	var left_index: = shared_phase_music_index(left)
	var right_index: = shared_phase_music_index(right)
	if left_index == right_index:
		return left.to_lower() < right.to_lower()
	return left_index < right_index


static func discover_shared_phase_music_tracks(phase_music_dir: String) -> Array:
	var tracks: Array = []
	var dir: = DirAccess.open(phase_music_dir)
	if dir == null:
		return tracks
	dir.list_dir_begin()
	var file_name: = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and is_shared_phase_music_name(file_name):
			tracks.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	tracks.sort_custom(Callable(RTAudioLifecycle, "shared_phase_music_less"))
	return tracks


static func register_shared_phase_music_tracks(game: Node) -> void:
	for name in discover_shared_phase_music_tracks(game.PHASE_MUSIC_DIR):
		game._register_audio_stream(String(name), game.PHASE_MUSIC_DIR + "/" + String(name), false, true, game._memory_saver_active())


static func start_nevasca_sfx(game: Node) -> void:
	if game.nevasca_audio_player == null:
		return
	if game._ensure_audio_loaded("Nevasca.mp3"):
		game.nevasca_audio_player.stream = game.audio_streams["Nevasca.mp3"]
		game.nevasca_audio_player.volume_db = linear_to_db(max(0.001, game.vol_master * game.vol_sfx * 0.75))
		if not game.nevasca_audio_player.playing:
			game.nevasca_audio_player.play()


static func stop_nevasca_sfx(game: Node) -> void:
	if game.nevasca_audio_player != null and game.nevasca_audio_player.playing:
		game.nevasca_audio_player.stop()


static func is_menu_music_name(name: String) -> bool:
	return name.begins_with("Menu")


static func stop_menu_music_for_gameplay(game: Node) -> void:
	if not is_menu_music_name(game.current_music):
		return
	game.music_pause_fade_mode = ""
	game.music_pause_fade_timer = 0.0
	game.music_paused_by_pause = false
	game._cancel_music_crossfade()
	if game.music_player != null:
		game.music_player.stream_paused = false
		game.music_player.stop()
		game.music_player.stream = null
	game.current_music = ""


static func music_target_volume(game: Node) -> float:
	return game.vol_master * game.vol_music * game._shop_countdown_audio_duck()


static func stop_battle_music_for_screen_transition(game: Node) -> void:
	if game.music_player == null:
		return
	game.music_pause_fade_mode = ""
	game.music_pause_fade_timer = 0.0
	game.music_paused_by_pause = false
	game._cancel_music_crossfade()
	game.boss1_stop_music_duck_active = false
	game.prismatica_music_duck_active = false
	if game.current_music != "" and not game.current_music.begins_with("Menu"):
		game.music_player.stream_paused = false
		game.music_player.stop()
		game.music_player.stream = null
		game.current_music = ""


static func play_phase_music(game: Node) -> void:
	play_phase_music_random(game, game.current_phase)


static func shared_phase_music_tracks(game: Node) -> Array:
	var tracks: Array = discover_shared_phase_music_tracks(game.PHASE_MUSIC_DIR)
	tracks.sort_custom(Callable(RTAudioLifecycle, "shared_phase_music_less"))
	return tracks


static func phase_music_tracks(game: Node, _phase: int) -> Array:
	return shared_phase_music_tracks(game)


static func phase_music_available_tracks(game: Node, phase: int) -> Array:
	var available: Array = []
	for track in phase_music_tracks(game, phase):
		if game._audio_key_available(String(track)):
			available.append(String(track))
	return available


static func phase_music_bag_matches_available(game: Node, available: Array) -> bool:
	for track in game.phase_music_bag:
		if not available.has(String(track)):
			return false
	return true


static func refill_phase_music_bag(game: Node, available: Array) -> void:
	game.phase_music_bag.clear()
	for track in available:
		game.phase_music_bag.append(String(track))
	for i in range(game.phase_music_bag.size() - 1, 0, -1):
		var j: int = game.rng.randi_range(0, i)
		var tmp: String = game.phase_music_bag[i]
		game.phase_music_bag[i] = game.phase_music_bag[j]
		game.phase_music_bag[j] = tmp
	if game.phase_music_bag.size() > 1 and game.phase_music_bag[game.phase_music_bag.size() - 1] == game.current_music:
		var swap_index: int = game.rng.randi_range(0, game.phase_music_bag.size() - 2)
		var tmp_first: String = game.phase_music_bag[game.phase_music_bag.size() - 1]
		game.phase_music_bag[game.phase_music_bag.size() - 1] = game.phase_music_bag[swap_index]
		game.phase_music_bag[swap_index] = tmp_first


static func next_phase_music_track(game: Node, phase: int) -> String:
	var available: Array = phase_music_available_tracks(game, phase)
	if available.is_empty():
		return ""
	if game.phase_music_bag.is_empty() or not phase_music_bag_matches_available(game, available):
		refill_phase_music_bag(game, available)
	return String(game.phase_music_bag.pop_back())


static func play_phase_music_random(game: Node, phase: int) -> void:
	stop_menu_music_for_gameplay(game)
	var chosen: String = next_phase_music_track(game, phase)
	if chosen == "":
		return
	if chosen == game.current_music and game.music_player != null:
		game._replay_current_music(chosen)
		return
	game._play_music(chosen)


static func boss_music_tracks(phase: int) -> Array:
	match phase:
		1:
			return ["Boss1-Music-3.mp3"]
		2:
			return ["Boss2-Music-2.mp3", "Boss2-Music-3.mp3", "Boss2-Music-4.mp3", "Boss2-Music-5.mp3"]
		3:
			return ["Fase3_Boss-1.mp3.mp3", "Fase3_Boss-2.mp3.mp3"]
		4:
			return ["Fase4_Boss-1.mp3", "Fase4_Boss-2.mp3"]
		5:
			return ["Fase5_Boss-1.mp3", "Fase5_Boss-2.mp3", "Fase5_Boss-3.mp3"]
		7:
			return ["Fase7_Boss-1.mp3", "Fase7_Boss-2.mp3"]
	return []


static func play_boss_music_random(game: Node) -> void:
	var available: Array = []
	for track in boss_music_tracks(game.current_phase):
		if game._audio_key_available(track):
			available.append(track)
	if available.is_empty():
		if not (game.current_music in phase_music_tracks(game, game.current_phase)):
			play_phase_music(game)
		return
	var chosen: = String(available[game.rng.randi_range(0, available.size() - 1)])
	if chosen == game.current_music and game.music_player != null:
		game._replay_current_music(chosen, true)
		return
	game._play_music(chosen)


static func is_boss_music(name: String) -> bool:
	for phase in range(1, 8):
		if name in boss_music_tracks(phase):
			return true
	return false


static func on_music_finished(game: Node) -> void:
	if game.music_crossfade_active:
		return
	if is_menu_music_name(game.current_music):
		if game.mode == "game" or game.mode == "phase_transition":
			play_phase_music(game)
		else:
			play_menu_music_random(game)
		return
	if game.current_music in phase_music_tracks(game, game.current_phase):
		play_phase_music_random(game, game.current_phase)
		return
	if is_boss_music(game.current_music):
		if game.boss_active and not game.boss_dead:
			play_boss_music_random(game)
		else:
			play_phase_music(game)
		return
	if game.current_music != "" and game.music_player != null and game.music_player.stream != null:
		game.music_player.play()


static func play_menu_music_random(game: Node) -> void:
	var available = []
	for track in ["Menu.mp3", "Menu1-2.mp3", "Menu1-3.MP3", "Menu1-4.mp3"]:
		if game._audio_key_available(track):
			available.append(track)
	if available.is_empty():
		return
	var chosen = String(available[game.rng.randi_range(0, available.size() - 1)])
	if chosen == game.current_music and game.music_player != null:
		game._replay_current_music(chosen, true)
		return
	game._play_music(chosen)


static func update_audio_volumes(game: Node) -> void:
	if game.music_pause_fade_mode != "" or game.music_paused_by_pause or game.music_crossfade_active:
		return
	if game.music_player != null and not game.prismatica_music_duck_active and not game.boss1_stop_music_duck_active:
		game.music_player.volume_db = linear_to_db(max(0.001, game._music_target_volume()))
	if game.rain_audio_player != null and game.rain_audio_fade_mode == "":
		game.rain_audio_player.volume_db = linear_to_db(max(0.001, game.rain_audio_current_volume))
	if game.boss1_walk_audio_player != null:
		game.boss1_walk_audio_player.volume_db = linear_to_db(max(0.001, game.vol_master * game.vol_sfx * game.BOSS1_WALK_AUDIO_VOLUME))
	if game.boss1_stop_audio_player != null and game.boss1_stop_audio_player.playing:
		game.boss1_stop_audio_player.volume_db = linear_to_db(max(0.001, game.vol_master * game.vol_sfx * game.BOSS1_STOP_AUDIO_VOLUME))
	if game.acorrentada_walk_audio_player != null and game.acorrentada_walk_audio_player.playing:
		game.acorrentada_walk_audio_player.volume_db = linear_to_db(max(0.001, game.vol_master * game.vol_sfx * game.ACORRENTADA_WALK_VOLUME * game.acorrentada_walk_current_volume))
	if game.prismatica_ultimate_audio_player != null and game.prismatica_ultimate_audio_player.playing:
		game.prismatica_ultimate_audio_player.volume_db = linear_to_db(max(0.001, game.vol_master * game.vol_music * 0.82))
	if game.nevasca_audio_player != null and game.nevasca_audio_player.playing:
		game.nevasca_audio_player.volume_db = linear_to_db(max(0.001, game.vol_master * game.vol_sfx * 0.75))


static func update_boss1_walk_audio(game: Node, delta: float) -> void:
	if game.boss1_walk_audio_player == null:
		return
	if game.boss1_walk_previous_pos == Vector2.ZERO:
		game.boss1_walk_previous_pos = game.boss_pos
		return
	var distance: float = game.boss1_walk_previous_pos.distance_to(game.boss_pos)
	game.boss1_walk_previous_pos = game.boss_pos
	var movement_speed: float = distance / maxf(0.001, delta)
	var walking: bool = game.mode == "game" and game.current_phase == 1 and game.boss_active and not game.boss_dead and movement_speed >= 18.0 and movement_speed <= 620.0
	if walking and game.audio_streams.has("boss1_walk"):
		if game.boss1_walk_audio_player.stream != game.audio_streams["boss1_walk"]:
			game.boss1_walk_audio_player.stream = game.audio_streams["boss1_walk"]
		game.boss1_walk_audio_player.volume_db = linear_to_db(max(0.001, game.vol_master * game.vol_sfx * game.BOSS1_WALK_AUDIO_VOLUME))
		if not game.boss1_walk_audio_player.playing:
			game.boss1_walk_audio_player.play()
	else:
		stop_boss1_walk_audio(game)


static func stop_boss1_walk_audio(game: Node) -> void:
	if game.boss1_walk_audio_player != null and game.boss1_walk_audio_player.playing:
		game.boss1_walk_audio_player.stop()


static func rain_audio_target_volume(game: Node) -> float:
	return game.vol_master * game.vol_music * game.WEATHER_RAIN_AUDIO_VOLUME


static func start_rain_audio(game: Node) -> void:
	if game.rain_audio_player == null or not game._ensure_audio_loaded("rain"):
		return
	game.rain_audio_player.stream = game.audio_streams["rain"]
	if not game.rain_audio_player.playing:
		game.rain_audio_player.play()
	game.rain_audio_player.stream_paused = false
	game.rain_audio_current_volume = 0.001
	game.rain_audio_player.volume_db = linear_to_db(0.001)
	game.rain_audio_fade_timer = 0.0
	game.rain_audio_fade_mode = "in"


static func stop_rain_audio(game: Node) -> void:
	if game.rain_audio_player == null or game.rain_audio_player.stream == null:
		return
	game.rain_audio_fade_timer = 0.0
	game.rain_audio_fade_mode = "out"


static func stop_rain_audio_immediate(game: Node) -> void:
	if game.rain_audio_player == null:
		return
	game.rain_audio_fade_mode = ""
	game.rain_audio_fade_timer = 0.0
	game.rain_audio_current_volume = 0.0
	game.rain_audio_player.stop()


static func update_rain_audio_fade(game: Node, delta: float) -> void:
	if game.rain_audio_player == null or game.rain_audio_fade_mode == "":
		return
	game.rain_audio_fade_timer += delta
	var progress = clamp(game.rain_audio_fade_timer / game.WEATHER_RAIN_FADE_TIME, 0.0, 1.0)
	if game.rain_audio_fade_mode == "in":
		game.rain_audio_current_volume = lerp(0.001, rain_audio_target_volume(game), progress)
		game.rain_audio_player.volume_db = linear_to_db(max(0.001, game.rain_audio_current_volume))
		if progress >= 1.0:
			game.rain_audio_fade_mode = ""
			game.rain_audio_current_volume = rain_audio_target_volume(game)
			game.rain_audio_player.volume_db = linear_to_db(max(0.001, game.rain_audio_current_volume))
	elif game.rain_audio_fade_mode == "out":
		game.rain_audio_current_volume = lerp(game.rain_audio_current_volume, 0.001, progress)
		game.rain_audio_player.volume_db = linear_to_db(max(0.001, game.rain_audio_current_volume))
		if progress >= 1.0:
			game.rain_audio_fade_mode = ""
			game.rain_audio_current_volume = 0.0
			game.rain_audio_player.stop()
