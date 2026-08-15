extends SceneTree

var game: Node


func _expect(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("BOSS2_FREEZE_WIND_AUDIO_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _cleanup_game() -> void:
	if not is_instance_valid(game):
		return
	game._cleanup_runtime_resources()
	for player in [game.music_player, game.rain_audio_player, game.boss1_walk_audio_player, game.nevasca_audio_player]:
		if player != null:
			player.stop()
			player.stream = null
	for player in game.sfx_players:
		if player != null:
			player.stop()
			player.stream = null
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null


func _run() -> void:
	game._start_game()
	game.vol_master = 1.0
	game.vol_sfx = 1.0
	_expect(game.audio_streams.has("boss1_walk"), "boss1_walk_audio_missing")
	_expect(game.audio_streams.has("Nevasca.mp3"), "nevasca_audio_missing")
	_expect(game.audio_streams.has("Congelando.mp3"), "freeze_audio_missing")
	_expect(game.audio_streams.has("Descongelando.mp3"), "unfreeze_audio_missing")
	_expect(game.audio_streams["boss1_walk"] is AudioStreamMP3 and game.audio_streams["boss1_walk"].loop, "boss1_walk_not_looped")
	_expect(game.audio_streams["Nevasca.mp3"] is AudioStreamMP3 and game.audio_streams["Nevasca.mp3"].loop, "nevasca_audio_not_looped")
	game.mode = "game"
	game.current_phase = 1
	game.boss_active = true
	game.boss_dead = false
	game.boss_pos = Vector2(900, 420)
	game.boss1_walk_previous_pos = game.boss_pos - Vector2(18, 0)
	game._update_boss1_walk_audio(0.10)
	_expect(game.boss1_walk_audio_player.playing, "boss1_steps_did_not_start_while_walking")
	game._update_boss1_walk_audio(0.10)
	_expect(not game.boss1_walk_audio_player.playing, "boss1_steps_did_not_stop")

	game.current_phase = 2
	game.boss_hp_max = 6000.0
	game.boss_hp = 5000.0
	game.boss_pos = Vector2(900, 400)
	game.player_pos = Vector2(1040, 400)
	game.player_hp_max = 450
	game.player_hp = 450
	game.boss_attacks.clear()
	for player in game.sfx_players:
		player.stop()
		player.stream = null
	game._boss2_start_flash_freeze()
	game._update_boss2_attacks(game.BOSS2_FLASH_FREEZE_WARNING + 0.01)
	_expect(game.player_stun_timer >= game.BOSS2_FLASH_FREEZE_STUN - 0.01, "flash_freeze_did_not_stun")
	_expect(game.sfx_players.any(func(player): return player.stream == game.audio_streams["Congelando.mp3"]), "freeze_audio_did_not_play")
	for player in game.sfx_players:
		player.stop()
		player.stream = null
	game.player_freeze_visual_timer = 0.01
	game._update_game(0.02)
	_expect(game.sfx_players.any(func(player): return player.stream == game.audio_streams["Descongelando.mp3"]), "unfreeze_audio_did_not_play")
	_expect(game.textures.get("player_frozen", []).size() == 2, "Geo_Cool_frames_missing")
	_expect(game.PLAYER_DRAW_FROZEN_SIZE == Vector2(58.8, 84.0), "frozen_sprite_not_increased_five_percent")
	var frozen_frames: Array = game.textures["player_frozen"]
	for sample in [[0.69, 0], [0.72, 1], [1.02, 0], [1.32, 1], [1.62, 0], [2.25, 0]]:
		game.player_freeze_visual_timer = game.player_freeze_visual_duration - float(sample[0])
		_expect(game._frozen_player_frame_index() == int(sample[1]), "freeze_sequence_wrong_at_%.2f" % float(sample[0]))
		_expect(game._player_texture() == frozen_frames[int(sample[1])], "freeze_texture_wrong_at_%.2f" % float(sample[0]))

	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(360, 0)
	game.touch_move = Vector2.ZERO
	game.move_touch_index = -1
	game.boss2_ultimate_wind_active = 1.0
	var before: Vector2 = game.player_pos
	game._update_boss2_ultimate_wind(0.20)
	_expect(game.player_pos.x < before.x, "wind_did_not_blow_to_map_center")
	_expect(game.player_pos.distance_to(game.WORLD_SIZE * 0.5) < before.distance_to(game.WORLD_SIZE * 0.5), "wind_increased_center_distance")

	game._reset_boss2_state()
	game._start_boss2_ultimate()
	_expect(game.nevasca_audio_player.playing, "nevasca_audio_did_not_start")
	_expect(is_zero_approx(game.boss2_ultimate_wind_timer), "ultimate_wind_did_not_start_immediately")
	game._update_boss2_ultimate_wind(0.01)
	_expect(game.boss2_ultimate_wind_active > 0.0, "immediate_wind_not_activated")
	game._end_boss2_ultimate()
	_expect(not game.nevasca_audio_player.playing, "nevasca_audio_did_not_stop")

	print("BOSS2_FREEZE_WIND_AUDIO_OK center_wind=true freeze_frames=1-2-1-2-1 steps_loop=true nevasca_loop=true freeze_sfx=true")
	_cleanup_game()
	for i in range(4):
		await process_frame
	quit(0)
