extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.selected_manifestation = 0
	game.selected_aura = 0
	game._start_game()
	game.mode = "game"
	game.manifestation_key = "eletrica"
	game.player_nickname = "EletricaQA"
	game.player_profile_id = "qa-eletrica"
	game.player_pos = Vector2(640, 360)
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.enemies.clear()
	game.enemies.append({
		"type": game.ENEMY_COMMON,
		"uid": 999,
		"pos": game.player_pos + Vector2(40, 0),
		"hp": 100.0,
		"max_hp": 100.0,
		"speed": game.enemy_speed_base,
		"stun": 0.0,
		"phase": 0.0
	})
	var secondary := {
		"kind": "eletrica",
		"life": 10.0,
		"max": 10.0,
		"tick": 999.0,
		"active_time": game.SECONDARY_ELETRICA_DRAIN_DELAY - 0.1,
		"empty_time": 0.0,
		"health_drain_timer": 0.0,
		"health_drain_carry": 0.0
	}
	var cold_color: Color = game._eletrica_tension_color(0.0)
	var hot_color: Color = game._eletrica_tension_color(1.0)
	assert(cold_color.b > cold_color.r)
	assert(hot_color.r > cold_color.r and hot_color.b >= 0.95)
	assert(game._eletrica_tension_ratio(secondary) > 0.90 and game._eletrica_tension_ratio(secondary) < 1.0)
	game._update_secondary_eletrica(secondary, 0.2)
	assert(game.player_hp == 1000)
	assert(is_equal_approx(game._eletrica_tension_ratio(secondary), 1.0))
	game._update_secondary_eletrica(secondary, 1.0)
	assert(is_equal_approx(game._eletrica_tension_ratio(secondary), 1.0))
	assert(game.player_hp <= 990 and game.player_hp >= 989)
	secondary["active_time"] = game.SECONDARY_ELETRICA_DRAIN_DELAY + game.SECONDARY_ELETRICA_DRAIN_TIER_SECONDS + 0.2
	secondary["health_drain_timer"] = 0.0
	var before_hp := int(game.player_hp)
	game._update_secondary_eletrica(secondary, 1.0)
	assert(before_hp - int(game.player_hp) >= 18)
	game.cards_bought["Petro"] = 1
	game.enemies_killed = 3
	var payload: Dictionary = game._build_run_report_payload("Smoke")
	assert(payload.has("cards_detail"))
	assert(payload.has("leaderboard_score"))
	assert(String(payload["profile_id"]) != "")
	print("ELETRICA_DRAIN_AND_REPORT_SMOKE_OK drain_after=18s report=true")
	game._cleanup_runtime_resources()
	if game.music_player != null:
		game.music_player.stop()
		game.music_player.stream = null
	if game.rain_audio_player != null:
		game.rain_audio_player.stop()
		game.rain_audio_player.stream = null
	for player in game.sfx_players:
		if player != null:
			player.stop()
			player.stream = null
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(4):
		await process_frame
	quit(0)
