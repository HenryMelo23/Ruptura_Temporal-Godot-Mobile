extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("AUDIO_SPATIAL_MIX_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.vol_master = 1.0
	game.vol_sfx = 1.0
	game.vol_shots = 1.0
	game.player_pos = Vector2(640, 360)
	var test_stream := AudioStreamWAV.new()
	test_stream.mix_rate = 44100
	test_stream.format = AudioStreamWAV.FORMAT_16_BITS
	test_stream.stereo = true
	var silence := PackedByteArray()
	silence.resize(44100 * 2 * 2)
	test_stream.data = silence
	game.audio_streams["player_shot"] = test_stream
	game.audio_output_mode = game.AUDIO_OUTPUT_STEREO
	game._apply_audio_output_mode_to_players()
	game._play_sfx("player_shot", 0.0, 1.0, 1.0, Vector2(940, 360))
	var stereo_player := game.sfx_players[0] as AudioStreamPlayer2D
	_check(stereo_player != null, "SFX pool is not spatial AudioStreamPlayer2D")
	_check(Vector2(stereo_player.global_position).distance_to(Vector2(940, 360)) <= 0.5, "stereo SFX did not keep source position")
	_check(float(stereo_player.get("panning_strength")) > 0.5, "stereo SFX panning is not enabled")
	stereo_player.stop()

	game.audio_output_mode = game.AUDIO_OUTPUT_MONO
	game._apply_audio_output_mode_to_players()
	game._play_sfx("player_shot", 0.0, 1.0, 1.0, Vector2(300, 360))
	var mono_player := game.sfx_players[0] as AudioStreamPlayer2D
	_check(mono_player != null, "mono SFX player is not spatial")
	_check(Vector2(mono_player.global_position).distance_to(Vector2(300, 360)) <= 0.5, "mono SFX did not keep source position for distance volume")
	_check(is_equal_approx(float(mono_player.get("panning_strength")), 0.0), "mono SFX did not center panning")
	_check(game._sanitize_audio_output_mode("invalid") == game.AUDIO_OUTPUT_STEREO, "invalid audio output mode should fall back to stereo")
	for player in game.sfx_players:
		player.stop()
		player.stream = null
	game.audio_output_mode = game.AUDIO_OUTPUT_STEREO
	game.vol_sfx = 1.0
	game.current_phase = 6
	game.mode = "game"
	game.enemies.clear()
	game.player_pos = Vector2(640, 360)
	game._spawn_enemy(game.ENEMY_LODARIO, game.player_pos + Vector2(game.LODARIO_SFX_CLOSE_DISTANCE, 0))
	var lodario: Dictionary = game.enemies.back()
	var close_scale: float = game._lodario_landing_sfx_volume(lodario)
	lodario["pos"] = game.player_pos + Vector2(game.LODARIO_SFX_FAR_DISTANCE + 90.0, 0)
	var far_scale: float = game._lodario_landing_sfx_volume(lodario)
	_check(close_scale >= game.LODARIO_SFX_VOLUME_MAX - 0.002, "Lodario close landing SFX does not reach 20 percent")
	_check(far_scale <= game.LODARIO_SFX_VOLUME_MIN + 0.002, "Lodario far landing SFX does not fade to zero")
	lodario["pos"] = game.player_pos + Vector2(180, 0)
	lodario["lodario_jump_from"] = lodario["pos"]
	lodario["lodario_jump_to"] = game.player_pos + Vector2(90, 0)
	lodario["lodario_jump_progress"] = 0.01
	lodario["lodario_jump_duration"] = 0.22
	game._update_lodario(lodario, 0.01)
	_check(not game.sfx_players.any(func(player): return player.stream == game.audio_streams["Lodario-mov.mp3"]), "Lodario landing SFX played before ground contact")
	game._update_lodario(lodario, 0.25)
	var lodario_players: Array = game.sfx_players.filter(func(player): return player.stream == game.audio_streams["Lodario-mov.mp3"])
	_check(not lodario_players.is_empty(), "Lodario landing SFX did not play on ground contact")
	var lodario_volume := db_to_linear(lodario_players[0].volume_db)
	var expected_lodario_volume: float = game.vol_master * game.vol_sfx * game._lodario_landing_sfx_volume(lodario)
	_check(abs(lodario_volume - expected_lodario_volume) <= 0.002, "Lodario landing SFX did not use distance-scaled volume")
	print("AUDIO_SPATIAL_MIX_PASS stereo_mono_and_lodario_landing")
	quit(0)
