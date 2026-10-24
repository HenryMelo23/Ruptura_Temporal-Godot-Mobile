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
	var score_before: int = game.score
	var hp_before: float = game.player_hp
	game._start_team_revival_for_dead(42, Vector2(900, 430), "DOIS", false)
	_check(not game.revive_controller.fragment_altar_revive_enabled(game), "fragment/altar revive unexpectedly enabled")
	_check(not game.revival_active and game.revival_fragments.is_empty() and not game.revival_altars_active, "dead peer spawned removed fragment/altar flow")
	game._activate_team_revival_altars()
	game._collect_revival_fragment(1, game._mp_unique_id())
	game._try_interact_revival_altar(game.REVIVE_PAY_POINTS)
	_check(game.score == score_before and is_equal_approx(game.player_hp, hp_before), "removed altar flow still charged points or life")
	_check(bool(Dictionary(game.net_players_by_peer[42]).get("dead", false)), "removed altar flow still revived a dead peer")
	game._apply_team_revival_state([42], {42: "DOIS"}, {42: Vector2(900, 430)}, [{"id": 1, "pos": Vector2(700, 400)}], 20.0, true, "LEGACY")
	_check(not game.revival_active and game.revival_fragments.is_empty() and not game.revival_altars_active, "legacy network state re-enabled fragments or altars")
	game._rpc_team_revival_complete([42], 225.0, game.REVIVE_PAY_POINTS, game._mp_unique_id(), {42: Vector2(700, 400)})
	_check(bool(Dictionary(game.net_players_by_peer[42]).get("dead", false)), "legacy altar completion packet revived a dead peer")

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

	print("MULTIPLAYER_TEAM_REVIVAL_SMOKE_OK owner=true requests=preserved solo=true game_over=true score_dedup=true fragments=false altars=false legacy_state=ignored")
	game.queue_free()
	await process_frame
	quit(0)
