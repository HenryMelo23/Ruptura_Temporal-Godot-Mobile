extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _expect(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("COMBAT_GAMEOVER_ADJUSTMENTS_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()

	game.manifestation_key = "prismatica"
	game.enemies.clear()
	game.bullets.clear()
	game.bullets.append({
		"pos": Vector2(game.WORLD_SIZE.x - 4.0, 420.0),
		"dir": Vector2.RIGHT,
		"life": 1.0,
		"max_life": 1.0,
		"age": 0.0,
		"phase": 0.0,
		"trail_cd": 1.0,
		"damage": 10.0,
		"speed": 120.0,
		"kind": "prismatica",
		"pierce": true,
		"hits": {},
		"ricochets": 3,
		"durability": 100.0,
		"color": Color.CYAN
	})
	game._update_bullets(0.05)
	_expect(game.bullets.size() == 1, "prism_bullet_vanished_early")
	_expect(is_equal_approx(float(game.bullets[0].get("durability", 0.0)), 90.0), "prism_durability_not_reduced")

	game.manifestation_key = "eletrica"
	game.auto_target_priority = "hp_low"
	game.player_pos = Vector2(100, 100)
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(220, 100))
	game.enemies[0]["hp"] = 80.0
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(1350, 100))
	game.enemies[1]["hp"] = 1.0
	var target: Dictionary = game._auto_target_enemy()
	_expect(int(target.get("uid", -1)) == int(game.enemies[0]["uid"]), "auto_target_ignored_range")

	game.boss1_rewind_history.clear()
	game.current_phase = 1
	game.boss_active = true
	game.boss_hp = game.boss_hp_max * 0.25
	game.player_pos = Vector2(700, 500)
	game.boss_pos = Vector2(900, 450)
	game.boss1_rewind_history.append(game._capture_boss1_rewind_snapshot())
	game.time_alive += 0.2
	game.elapsed_unpaused += 0.2
	game.player_pos = Vector2(320, 260)
	game.boss1_rewind_history.append(game._capture_boss1_rewind_snapshot())
	game.dash_touch_index = 12
	game.teleport_dragging = true
	game.teleport_drag_screen = Vector2(1100, 620)
	game.skill_touch_index = 13
	game.secondary_touch_index = 14
	game.attack_drag_touch_index = 15
	game.attack_dragging = true
	game.attack_holding = true
	game._start_boss1_rewind_sequence()
	_expect(not game.teleport_dragging and game.dash_touch_index == -1, "rewind_left_tp_aim_stuck")
	_expect(game.skill_touch_index == -1 and game.secondary_touch_index == -1, "rewind_left_ability_aim_stuck")
	_expect(not game.attack_dragging and not game.attack_holding, "rewind_left_attack_aim_stuck")
	game._update_boss1_rewind_sequence(game.BOSS1_CLOCK_TRAVEL_TIME + game.BOSS1_CLOCK_TURN_TIME * 0.5)
	_expect(game.player_pos.distance_to(Vector2(320, 260)) > 1.0, "rewind_not_moving_during_clock")
	_expect(not game.boss1_rewind_sequence.is_empty(), "rewind_finished_too_early")

	game.boss1_rewind_sequence.clear()
	game.boss_attacks.clear()
	game.boss_pos = Vector2(800, 420)
	game.player_pos = Vector2(520, 420)
	game._add_boss_rain(10)
	for i in range(5):
		game.player_pos += Vector2(42, 0)
		game._update_boss_attacks(0.39)
	_expect(game.boss_attacks.size() == 1, "boiling_bubble_attack_missing")
	var drops: Array = game.boss_attacks[0].get("drops", [])
	_expect(drops.size() >= 5, "boiling_bubbles_not_five")
	var first_target = Vector2(drops[0]["target"])
	var last_target = Vector2(drops[drops.size() - 1]["target"])
	_expect(first_target.distance_to(last_target) > 40.0, "boiling_bubbles_not_tracking_player")

	var viewport = Vector2(1280, 720)
	game.mode = "game_over"
	var end_buttons: Dictionary = game._game_over_button_layout(viewport)
	_expect(end_buttons.has("end_retry") and end_buttons.has("end_ranking") and end_buttons.has("end_menu") and end_buttons.has("end_exit"), "game_over_buttons_missing")
	_expect(String(game._leaderboard_url()).ends_with(game.RUN_LEADERBOARD_VIEW_PATH), "leaderboard_url_invalid")
	var fixed_run_url: String = game._sanitize_leaderboard_url("http://127.0.0.1:18191/leaderboard/run/5347688565db2d3df3")
	_expect(fixed_run_url == "http://72.61.217.238:8090/leaderboard/run/5347688565db2d3df3", "leaderboard_localhost_not_sanitized")
	game._on_run_leaderboard_request_completed(0, 201, PackedStringArray(), JSON.stringify({"run": {"id": "abc123"}, "runUrl": "http://127.0.0.1:18191/leaderboard/run/abc123"}).to_utf8_buffer())
	_expect(game._leaderboard_url() == "http://72.61.217.238:8090/leaderboard/run/abc123", "leaderboard_run_url_not_used")

	print("COMBAT_GAMEOVER_ADJUSTMENTS_OK prism_durability=true target_range=true rewind_clock=true rewind_clears_aim=true boiling_bubbles=true gameover_buttons=true ranking_button=true")
	quit(0)
