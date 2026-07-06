extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.selected_manifestation = 1
	game._start_game()
	game.manifestation_key = "lacerante"

	game.vol_sfx = 0.35
	game.vol_shots = 0.0
	_check(game._is_shot_audio("atk_lacerante_1"), "Lacerante attack was not routed as shot audio")
	_check(game._is_shot_audio("eletrica_travel"), "projectile travel was not routed as shot audio")
	_check(not game._is_shot_audio("ui_manifest_switch"), "interface sound was routed as shot audio")
	_check(is_zero_approx(game._sfx_channel_volume("atk_eletrica")), "shot mute does not reach attack audio")
	_check(is_equal_approx(game._sfx_channel_volume("ui_manifest_switch"), 0.35), "effects volume no longer controls interface audio")

	game.last_skill_time = -999.0
	game._use_skill()
	var spin: Dictionary = {}
	for slash in game.slashes:
		if String(slash.get("kind", "")) == "lacerante_spin":
			spin = slash
			break
	_check(not spin.is_empty(), "Lacerante Q spin was not created")
	_check(is_equal_approx(float(spin["max"]), game.LACERANTE_Q_DURATION), "Lacerante Q does not last 1.5 seconds")
	_check(is_equal_approx(game.LACERANTE_Q_ROTATIONS, 5.0), "Lacerante Q does not perform five rotations")
	_check(String(game._manifestation_details("lacerante")["desc_hab"]).contains("5 voltas"), "manifestation screen does not explain the new Q")

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
	_check(game.run_points_spent == 500, "shop purchase was not counted as spent points")
	_check(game._deck_total_cards() == 1, "run card total did not include purchased card")

	game.mode = "game"
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(900, 450))
	var enemy: Dictionary = game.enemies[0]
	var expected_gain = game._points_for_enemy(enemy)
	game._kill_enemy(enemy)
	_check(game.run_points_earned == expected_gain, "enemy reward was not counted as earned points")
	_check(game.run_points_spent == 500, "enemy reward changed spent points")
	game.time_alive = 754.0
	game.current_phase = 2
	_check(game._run_time_text() == "12:34", "run time formatting is incorrect")

	print("RUN_SUMMARY_AUDIO_LACERANTE_Q_SMOKE_OK time=12:34 phase=2 earned=%d spent=%d cards=%d shots_muted=true q=5x360/1.5s" % [game.run_points_earned, game.run_points_spent, game._deck_total_cards()])
	quit(0)
