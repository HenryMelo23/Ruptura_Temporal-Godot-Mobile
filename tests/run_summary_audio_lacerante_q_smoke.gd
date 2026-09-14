extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _reset_sfx_players() -> void:
	for player in game.sfx_players:
		player.stop()
		player.stream = null


func _playing_sfx_count() -> int:
	var count := 0
	for player in game.sfx_players:
		if player.playing:
			count += 1
	return count


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i].get("key", "")) == "lacerante":
			game.selected_manifestation = i
			break
	game._start_game()
	game.manifestation_key = "lacerante"

	game.vol_sfx = 0.35
	game.vol_shots = 0.0
	_check(game._is_shot_audio("atk_lacerante_1"), "Lacerante attack was not routed as shot audio")
	_check(game._is_shot_audio("eletrica_travel"), "projectile travel was not routed as shot audio")
	_check(not game._is_shot_audio("ui_manifest_switch"), "interface sound was routed as shot audio")
	_check(is_zero_approx(game._sfx_channel_volume("atk_eletrica")), "shot mute does not reach attack audio")
	_check(is_equal_approx(game._sfx_channel_volume("ui_manifest_switch"), 0.35), "effects volume no longer controls interface audio")
	game.vol_master = 1.0
	game.vol_shots = 1.0
	_reset_sfx_players()
	for silent_key in ["player_shot", "prismatica_shot", "atk_lacerante_1", "atk_eletrica", "eletrica_travel", "Disparo.MP3"]:
		game._play_sfx(silent_key)
		_check(_playing_sfx_count() == 0, "manifestation shot SFX was not silent: " + silent_key)
	game.player_pos = Vector2(500.0, 500.0)
	game.player_hp = game.player_hp_max
	game.enemy_bullets = [{"pos": game.player_pos, "dir": Vector2.ZERO, "life": 1.0, "damage": 1, "phase": 0.0, "type": "test_enemy_bullet"}]
	_reset_sfx_players()
	game._update_enemy_bullets(0.016)
	_check(_playing_sfx_count() == 0, "enemy bullet hit SFX was not silent")

	game.run_points_earned = 0
	game.run_points_spent = 0
	game.score = 1000
	game.score_total = 1000
	game.card_cost = 500
	game.shop_purchase_pending_card = game.CARDS[0].duplicate(true)
	game.shop_purchase_pending_can_continue = false
	game.shop_purchase_anim_timer = 0.01
	game.mode = "shop"
	game._update_shop(0.02)
	_check(game._deck_total_cards() == 1, "run card total did not include purchased card")

	game.mode = "game"
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(900, 450))
	var enemy: Dictionary = game.enemies[0]
	var expected_gain = game._points_for_enemy(enemy)
	game._kill_enemy(enemy)
	_check(game.run_points_earned == expected_gain, "enemy reward was not counted as earned points")
	game.time_alive = 754.0
	game.current_phase = 2
	_check(game._run_time_text() == "12:34", "run time formatting is incorrect")

	print("RUN_SUMMARY_AUDIO_SMOKE_OK time=12:34 phase=2 earned=%d spent=%d cards=%d shots_muted=true enemy_bullet_hit_silent=true" % [game.run_points_earned, game.run_points_spent, game._deck_total_cards()])
	game.queue_free()
	await process_frame
	await process_frame
	quit(0)
