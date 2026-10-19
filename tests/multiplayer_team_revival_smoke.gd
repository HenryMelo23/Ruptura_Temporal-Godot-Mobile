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
	_check(game.revive_controller != null, "runtime revive controller was not composed")
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
	_check(is_equal_approx(game._revival_life_sacrifice_rate_for_dead_count(1), 0.1296), "first life altar sacrifice should be 13 percent")
	_check(is_equal_approx(game._revival_life_sacrifice_rate(), 0.2016), "two fallen players should raise the life sacrifice to 20 percent")
	game._try_interact_revival_altar(game.REVIVE_PAY_LIFE)
	_check(is_equal_approx(game.player_hp, 319.36), "life altar should apply the 20 percent two-player sacrifice")
	_check(is_equal_approx(float(Dictionary(game.net_players_by_peer[42]).get("hp", 0.0)), 40.32), "life altar did not split the canonical life payment to first dead peer")
	_check(is_equal_approx(float(Dictionary(game.net_players_by_peer[43]).get("hp", 0.0)), 40.32), "life altar did not split the canonical life payment to second dead peer")

	# Request flow: an unavailable spectator cannot open a request, and an
	# insufficient payer does not spend points or accept it accidentally.
	game.is_dead = true
	game.online_local_spectator = true
	game._request_team_revive()
	_check(not game.revive_request_outgoing, "spectator opened an unavailable revive request")
	game.online_local_spectator = false
	game.is_dead = false
	game.revive_request_incoming = true
	game.revive_request_target_peer = 42
	game.revive_request_cost = 999
	game.score = 0
	game._accept_team_revive_request(game.REVIVE_PAY_POINTS)
	_check(game.revive_request_incoming and game.revive_request_target_peer == 42, "insufficient score accepted the revive request")
	game._reject_team_revive_request()
	_check(not game.revive_request_incoming, "rejected request remained active")

	# Solo must not retain a team-revival state, while a fully dead room still
	# reports defeat through the unchanged public facade.
	game.revival_active = true
	game.is_multiplayer = false
	game._update_team_revival(0.1)
	_check(not game.revival_active, "solo retained multiplayer revival state")
	game.is_multiplayer = true
	game.is_dead = true
	for peer_id in game.net_players_by_peer.keys():
		game.net_players_by_peer[peer_id]["dead"] = true
		game.net_players_by_peer[peer_id]["eliminated"] = true
		game.net_players_by_peer[peer_id]["alive"] = false
		game.net_players_by_peer[peer_id]["hp"] = 0.0
	_check(game._all_multiplayer_players_dead(), "fully dead multiplayer room did not report game over")

	print("MULTIPLAYER_TEAM_REVIVAL_SMOKE_OK owner=true unavailable=true failure=true solo=true game_over=true score_dedup=true fragments=true altars=true life_split=true")
	game.queue_free()
	await process_frame
	quit(0)
