extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MULTIPLAYER_SPECTATOR_CONTRACT_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame

	game.is_multiplayer = true
	game.online_connected = true
	game.online_room_owner = true
	game.online_lobby_connected_count = 2
	game.online_lobby_active_player_count = 1
	game.online_lobby_spectator_count = 1
	game.online_lobby_ready_count = 0
	game.online_local_spectator = false
	game._start_game()
	_check(is_equal_approx(game.enemy_base_hp, game.ENEMY_BASE_HP), "solo host with spectator scaled enemy health")
	_check(game._online_client_ready(), "host could not start with a spectator-only client")

	game.online_lobby_active_player_count = 2
	game.online_lobby_spectator_count = 1
	game.online_lobby_ready_count = 0
	_check(not game._online_client_ready(), "active client was treated as ready without vote")
	game.online_lobby_ready_count = 1
	_check(game._online_client_ready(), "active client ready vote did not unlock start")

	game.dedicated_server_mode = true
	game.dedicated_room_owner_peer_id = 2
	game.dedicated_spectator_by_peer = {2: false, 3: true}
	game.dedicated_ready_by_peer = {2: true, 3: true}
	game.dedicated_preload_ready_by_peer = {2: true}
	game.dedicated_manifest_ready_by_peer = {2: true}
	_check(game._dedicated_active_peer_ids() == [2], "spectator leaked into dedicated active peer list")
	_check(game._dedicated_spectator_count() == 1, "dedicated spectator count is wrong")
	_check(game._dedicated_preload_all_ready(), "spectator blocked preload completion")
	_check(game._dedicated_manifest_all_ready(), "spectator blocked manifestation completion")
	_check(game._dedicated_all_peers_voted({2: true}), "spectator blocked active-only consensus")

	game.dedicated_server_mode = false
	game.online_room_owner = false
	game.online_connected = true
	game.mode = "lobby_online_client"
	game.online_local_spectator = true
	game.online_spectator_request_pending = true
	game._online_lobby_state_v3("ROOM", 2, 2, 0, 0, false, false, false)
	_check(game.online_local_spectator, "stale lobby snapshot overwrote pending spectator request")
	_check(game.online_spectator_request_pending, "stale lobby snapshot acknowledged spectator request")
	game._online_lobby_state_v3("ROOM", 2, 1, 1, 0, true, false, true)
	_check(game.online_local_spectator_confirmed and not game.online_spectator_request_pending, "spectator confirmation did not settle")

	game.online_local_spectator = false
	game.online_local_spectator_confirmed = false
	game.online_lobby_ready_pending = true
	game.local_player_ready = true
	game._online_lobby_state_v3("ROOM", 2, 2, 0, 0, false, false, false)
	_check(game.local_player_ready and game.online_lobby_ready_pending, "stale lobby snapshot cancelled pending ready request")
	game._online_lobby_state_v3("ROOM", 2, 2, 0, 1, true, true, false)
	_check(game.online_local_ready_confirmed and not game.online_lobby_ready_pending, "ready confirmation did not settle")

	game.online_local_spectator = true
	game.player_hp = game.player_hp_max
	game.is_dead = false
	_check(not game._local_player_targetable(), "spectator remained targetable")
	game.mp_local_ready = false
	game.mode = "manifest_mp"
	game._start_multiplayer_manifest()
	_check(game.mode != "manifest_mp", "spectator was forced into manifestation/spectrum selection")

	game.cards_bought = {"Porcao": 2}
	game._sync_deck_network()
	game.is_dead = true
	game.score = game._revive_cost()
	game._request_team_revive()
	_check(not game.revive_request_outgoing, "spectator could request revive as a player")

	print("MULTIPLAYER_SPECTATOR_CONTRACT_SMOKE_OK active_players_ignore_spectators=true solo_balance=true choices_skipped=true")
	game.queue_free()
	await process_frame
	quit(0)
