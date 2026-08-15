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
	game.current_phase = 6
	game.mode = "game"
	game.enemies.clear()
	game.player_pos = Vector2(640, 360)

	game._spawn_enemy(game.ENEMY_LODARIO, game.player_pos + Vector2(game.LODARIO_SFX_CLOSE_DISTANCE, 0))
	var lodario: Dictionary = game.enemies.back()
	var close_scale: float = game._lodario_landing_sfx_volume(lodario)
	lodario["pos"] = game.player_pos + Vector2(game.LODARIO_SFX_FAR_DISTANCE + 90.0, 0)
	var far_scale: float = game._lodario_landing_sfx_volume(lodario)
	lodario["pos"] = game.player_pos + Vector2(180, 0)
	var mid_scale: float = game._lodario_landing_sfx_volume(lodario)
	_check(close_scale >= game.LODARIO_SFX_VOLUME_MAX - 0.002, "Lodario close landing SFX does not reach 20 percent")
	_check(far_scale <= game.LODARIO_SFX_VOLUME_MIN + 0.002, "Lodario far landing SFX does not fade to zero past 280px")
	_check(mid_scale > far_scale and mid_scale < close_scale, "Lodario landing SFX does not scale by distance")

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
	print("AUDIO_SPATIAL_MIX_PASS lodario_distance_scaled_landing")
	quit(0)
