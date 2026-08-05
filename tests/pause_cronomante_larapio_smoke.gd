extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _expect(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("PAUSE_CRONOMANTE_LARAPIO_SMOKE_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()

	_expect(game.music_player != null, "music_player_missing")
	_expect(game.music_player.stream != null, "music_stream_missing")
	if not game.music_player.playing:
		game.music_player.play()
	game.music_player.seek(6.0)
	var paused_at: float = game.music_player.get_playback_position()
	game._begin_pause_music_fade_out()
	_expect(game.music_paused_by_pause, "music_not_marked_paused")
	_expect(game.music_player.stream_paused, "stream_not_paused")
	game._begin_pause_music_fade_in()
	_expect(game.music_pause_fade_mode == "in", "fade_in_not_started")
	_expect(not game.music_player.stream_paused, "stream_still_paused")
	_expect(game.music_player.get_playback_position() >= paused_at - 0.30, "music_resume_restarted_track")
	game._update_music_pause_fade(3.1)
	_expect(game.music_pause_fade_mode == "", "fade_in_not_finished")

	game.boss_active = true
	game.boss_hp = game.boss_hp_max * 0.25
	game.boss1_rewind_history.clear()
	game.boss1_rewind_history.append(game._capture_boss1_rewind_snapshot())
	game.time_alive += 0.2
	game.player_pos += Vector2(24, 0)
	game.boss1_rewind_history.append(game._capture_boss1_rewind_snapshot())
	game._start_boss1_rewind_sequence()
	_expect(not game.boss1_rewind_sequence.is_empty(), "rewind_not_started")
	game._update_boss1_rewind_sequence(game.BOSS1_CLOCK_TRAVEL_TIME + 0.18)
	_expect(game.boss1_rewind_clock_tick >= 0, "clock_tick_missing")
	_expect(game.boss1_rewind_vibration_timer > 0.0, "vibration_timer_missing")

	game.score = 1000
	game.score_total = 1000
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_LARAPIO, game.player_pos + Vector2(40, 0))
	var larapio: Dictionary = game.enemies[0]
	larapio["steal_cd"] = 0.0
	game._update_larapio(larapio, 0.1)
	_expect(game.score == 400, "larapio_score_not_stolen")
	_expect(int(larapio.get("stolen", 0)) == 600, "larapio_stolen_wrong")
	_expect(game.player_stun_timer >= game.LARAPIO_STUN_TIME, "larapio_stun_missing")
	_expect(game.larapio_coin_drops.size() > 0, "larapio_coin_trail_missing")
	larapio["hp"] = float(larapio["max_hp"]) * 0.55
	larapio["larapio_ult_cd"] = 0.0
	larapio["larapio_ult_timer"] = 0.0
	game._update_larapio(larapio, 0.25)
	_expect(float(larapio.get("larapio_ult_timer", 0.0)) > 0.0, "larapio_ultimate_not_started")
	_expect(Array(larapio.get("larapio_ult_portals", [])).size() == game.LARAPIO_ULTIMATE_PORTAL_COUNT, "larapio_ultimate_portal_count_wrong")
	var before_portal_pos: Vector2 = larapio["pos"]
	larapio["larapio_ult_jump_cd"] = 0.0
	game._update_larapio(larapio, 0.25)
	_expect(Vector2(larapio["pos"]).distance_to(before_portal_pos) > 32.0, "larapio_ultimate_did_not_reposition")
	_expect(game._larapio_throw_interval(larapio, game.LARAPIO_IRRITATED_RADIUS - 8.0, true, false, false) <= game.LARAPIO_IRRITATED_COIN_INTERVAL, "larapio_irritated_coin_interval_not_used")

	game.larapio_coin_drops.clear()
	game._spawn_larapio_loot(game.player_pos, 90)
	_expect(game.larapio_coin_drops.size() >= 4, "larapio_loot_not_split")
	var before_score = game.score
	game._update_larapio_coin_drops(0.02)
	_expect(game.score > before_score, "larapio_loot_not_collected")

	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_LARAPIO, Vector2(40, 40))
	var corner_larapio: Dictionary = game.enemies[0]
	corner_larapio["larapio_corner_time"] = game.LARAPIO_CORNER_TRAP_TIME - 0.05
	corner_larapio["direct_steal"] = false
	corner_larapio["stolen"] = 0
	game.player_pos = Vector2(500, 500)
	game._update_larapio(corner_larapio, 0.10)
	_expect(float(corner_larapio.get("larapio_escape_timer", 0.0)) > 0.0, "larapio_corner_escape_not_triggered")
	var old_corner_pos: Vector2 = corner_larapio["pos"]
	game._move_enemy(corner_larapio, 0.35)
	var new_corner_pos: Vector2 = corner_larapio["pos"]
	_expect(new_corner_pos.x > old_corner_pos.x and new_corner_pos.y > old_corner_pos.y, "larapio_did_not_leave_corner")

	print("PAUSE_CRONOMANTE_LARAPIO_SMOKE_OK fade=true rewind_feedback=true larapio_steal_loot=true")
	quit(0)
