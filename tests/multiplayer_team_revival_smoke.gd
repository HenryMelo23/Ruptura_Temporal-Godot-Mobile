extends SceneTree

var game: Node


func _fail(message: String) -> void:
	push_error("MULTIPLAYER_TEAM_REVIVAL_FAIL " + message)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _remote_state(pos: Vector2, name: String) -> Dictionary:
	return {
		"pos": pos,
		"render_pos": pos,
		"velocity": Vector2.ZERO,
		"hp": 450.0,
		"hp_max": 450.0,
		"dead": false,
		"stealthed": false,
		"has_snapshot": true,
		"name": name
	}


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _collect_all_fragments() -> void:
	for fragment in game.revival_fragments.duplicate(true):
		var data: Dictionary = fragment
		game.player_pos = Vector2(data.get("pos", game.player_pos))
		game._collect_revival_fragment(int(data.get("id", 0)), game._mp_unique_id())


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.is_multiplayer = true
	game.is_host = true
	game.online_connected = false
	game.online_lobby_connected_count = 3
	game.online_lobby_active_player_count = 3
	game._start_game()
	game.mode = "game"
	game.player_hp_max = 500.0
	game.player_hp = 500.0
	game.card_cost = 100
	game.score = 100
	game.score_total = 100
	game._apply_score_delta(50, true, "kill:42")
	game._apply_score_delta(50, true, "kill:42")
	_check(game.score == 150 and game.score_total == 150, "score event applied more than once")
	game._apply_score_delta(-40, true, "spend:local")
	_check(game.score == 110 and game.run_points_spent >= 40, "local spend did not remain local")

	game.net_players_by_peer = {
		42: _remote_state(Vector2(900, 430), "DOIS"),
		43: _remote_state(Vector2(1180, 560), "TRES")
	}
	game.net_players_by_peer[42]["dead"] = true
	game._start_team_revival_for_dead(42, Vector2(900, 430), "DOIS", false)
	_check(game.revival_fragments.size() == game.REVIVAL_FRAGMENTS_PER_DEAD, "single player fragments missing")
	_check(is_equal_approx(game.revival_total_time, game.REVIVAL_SINGLE_TIME), "single player timer should be 30s")
	var fragment_before: Vector2 = Vector2(Dictionary(game.revival_fragments[0]).get("pos", Vector2.ZERO))
	game._update_team_revival(1.0)
	var fragment_after: Vector2 = Vector2(Dictionary(game.revival_fragments[0]).get("pos", Vector2.ZERO))
	_check(fragment_before.distance_to(fragment_after) > 0.5, "revival fragment did not drift")
	game.revival_timer = 0.01
	game._update_team_revival(0.02)
	_check(game.revival_fragments_suspended and game.revival_fragments.is_empty(), "expired fragments should suspend before respawn")
	game.revival_fragment_respawn_timer = 0.01
	game._update_team_revival(0.02)
	_check(not game.revival_fragments_suspended and game.revival_fragments.size() == game.REVIVAL_FRAGMENTS_PER_DEAD, "revival fragments did not respawn after the cooldown")
	_collect_all_fragments()
	_check(game.revival_altars_active, "single player altar did not activate")
	game.score = game._revival_points_cost()
	game.player_pos = game.revival_altar_points_pos
	game._try_interact_revival_altar(game.REVIVE_PAY_POINTS)
	_check(not game.revival_active and game.score == 0, "points altar did not spend exact four-card cost")
	_check(not bool(Dictionary(game.net_players_by_peer[42]).get("dead", true)), "points altar did not revive dead peer")

	game._clear_team_revival_state()
	game.player_hp = 400.0
	game.net_players_by_peer[42] = _remote_state(Vector2(900, 430), "DOIS")
	game.net_players_by_peer[43] = _remote_state(Vector2(1180, 560), "TRES")
	game.net_players_by_peer[42]["dead"] = true
	game.net_players_by_peer[43]["dead"] = true
	game._start_team_revival_for_dead(42, Vector2(900, 430), "DOIS", false)
	game._start_team_revival_for_dead(43, Vector2(1180, 560), "TRES", false)
	_check(game.revival_fragments.size() == game.REVIVAL_FRAGMENTS_PER_DEAD * 2, "multi player fragments missing")
	_check(is_equal_approx(game.revival_total_time, game.REVIVAL_MULTI_TIME), "multi player timer should be 50s")
	_collect_all_fragments()
	game.player_pos = game.revival_altar_life_pos
	game._try_interact_revival_altar(game.REVIVE_PAY_LIFE)
	_check(is_equal_approx(game.player_hp, 100.0), "life altar should sacrifice 75 percent with two dead")
	_check(is_equal_approx(float(Dictionary(game.net_players_by_peer[42]).get("hp", 0.0)), 150.0), "life altar did not split hp to first dead peer")
	_check(is_equal_approx(float(Dictionary(game.net_players_by_peer[43]).get("hp", 0.0)), 150.0), "life altar did not split hp to second dead peer")

	print("MULTIPLAYER_TEAM_REVIVAL_SMOKE_OK score_dedup=true fragments=true altars=true life_split=true")
	game.queue_free()
	await process_frame
	quit(0)
