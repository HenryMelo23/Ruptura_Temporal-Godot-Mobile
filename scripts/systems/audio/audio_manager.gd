class_name RTAudioManager
extends Node

var _game: Node


func bind_game(game: Node) -> void:
	_game = game


func unbind_game(game: Node) -> void:
	if _game == game:
		_game = null


func play_sfx(name: String, pitch_variance: float = 0.0, volume_scale: float = 1.0, pitch_center: float = 1.0) -> void:
	var game: Node = _game
	if game == null or not is_instance_valid(game):
		return
	if game._is_silent_manifestation_shot_sfx(name):
		return
	if name in ["Disparo_Geo.wav", "Disparo.MP3"]:
		name = "player_shot"
	elif name in ["skill_acorrentada", "ult_acorrentada", "atk_acorrentada_light", "atk_acorrentada_heavy"]:
		return
	elif name.begins_with("skill_") or name.begins_with("ult_") or (name.begins_with("atk_") and not name.begins_with("atk_lacerante_")):
		if name.contains("lacerante"):
			name = "atk_lacerante_3" if name.begins_with("ult_") else "atk_lacerante_2"
		else:
			name = "player_shot"
	if not game._ensure_audio_loaded(name):
		return
	var stream: AudioStream = game.audio_streams[name]
	var duck: float = 1.0 if name == "shop_countdown_tick" else game._shop_countdown_audio_duck()
	var channel_volume: float = game._sfx_channel_volume(name)
	if game.vol_master <= 0.001 or channel_volume <= 0.001:
		return
	var db: float = linear_to_db(max(0.001, game.vol_master * channel_volume * volume_scale * duck))
	var pitch: float = clamp(pitch_center + (game.rng.randf_range(-pitch_variance, pitch_variance) if pitch_variance > 0.0 else 0.0), 0.55, 1.65)
	for player in game.sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = db
			player.pitch_scale = pitch
			player.play()
			return
	if game.sfx_players.size() > 0:
		game.sfx_players[0].stream = stream
		game.sfx_players[0].volume_db = db
		game.sfx_players[0].pitch_scale = pitch
		game.sfx_players[0].play()


func play_music(name: String) -> void:
	var game: Node = _game
	if game == null or not is_instance_valid(game) or game.music_player == null:
		return
	if game.current_music == name and not game.music_crossfade_active and game.music_player.playing:
		return
	if game.music_crossfade_active:
		game._finish_music_crossfade()
	var had_active_music: bool = game.music_player.stream != null and game.music_player.playing and game.current_music != ""
	game.music_pause_fade_mode = ""
	game.music_paused_by_pause = false
	if game._ensure_audio_loaded(name):
		game.current_music = name
		if had_active_music and game.music_crossfade_player != null:
			game.music_crossfade_player.stop()
			game.music_crossfade_player.stream = game.audio_streams[name]
			game.music_crossfade_player.stream_paused = false
			game.music_crossfade_player.volume_db = linear_to_db(0.001)
			game.music_crossfade_player.play()
			game.music_crossfade_active = true
			game.music_crossfade_target_track = name
			game.music_crossfade_timer = 0.0
			game.music_crossfade_duration = game.MUSIC_CROSSFADE_TIME
			game.music_crossfade_from_volume = game._current_music_linear_volume()
			game.music_crossfade_to_volume = max(0.001, game._music_target_volume())
			game.music_pause_fade_mode = ""
		else:
			game.music_player.stream = game.audio_streams[name]
			game.music_player.stream_paused = false
			game.music_player.volume_db = linear_to_db(max(0.001, game._music_target_volume()))
			game.music_player.play()
			game.music_pause_fade_mode = "in"
			game.music_pause_fade_timer = 0.0
			game.music_pause_resume_volume = max(0.001, game._music_target_volume())
			game._set_music_linear_volume(0.001)
		game._release_unused_music_streams(name)
	else:
		game.music_player.stop()
		game.music_player.stream = null
		game.current_music = ""
