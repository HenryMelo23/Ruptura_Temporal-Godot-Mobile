extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MULTIPLAYER_THREE_PLAYER_CONTRACT_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


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


func _run() -> void:
	await process_frame
	game.is_multiplayer = true
	game.online_connected = false
	game.online_lobby_connected_count = 3
	game._start_game()
	game.mode = "game"
	game.net_players_by_peer = {
		42: _remote_state(Vector2(900, 430), "DOIS"),
		43: _remote_state(Vector2(1180, 560), "TRES")
	}
	game.net_player_peer_id = 42
	game._sync_legacy_remote_player(42)

	_check(game.ONLINE_MIN_PLAYERS == 2 and game.ONLINE_MAX_PLAYERS == 3, "room limits are not 2 to 3")
	_check(game._combat_targets().size() == 3, "combat target registry did not expose all three players")
	_check(is_equal_approx(game.boss_hp_max, game.BOSS_BASE_HP), "multiplayer still inflated boss health")

	var local_peer: int = game._mp_unique_id()
	var rotated_boss_targets: Dictionary = {}
	var rotated_arauto_targets: Dictionary = {}
	for index in range(3):
		rotated_boss_targets[int(game._boss_target_entry(true).get("peer_id", 0))] = true
		rotated_arauto_targets[int(game._arauto_target_entry(true).get("peer_id", 0))] = true
	_check(rotated_boss_targets.size() == 3, "boss did not rotate between three living players")
	_check(rotated_arauto_targets.size() == 3, "Arauto did not rotate between three living players")

	var eclipsada_index := -1
	for index in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[index].get("key", "")) == "eclipsada":
			eclipsada_index = index
			break
	_check(eclipsada_index >= 0, "Eclipsada is not registered")
	game.selected_manifestation = eclipsada_index
	game.manifestation_key = "eclipsada"
	game.eclipsada_stealth_timer = 5.0
	var stealth_enemy := {"uid": 701, "pos": game.player_pos, "target_peer_id": local_peer}
	var stealth_target: Vector2 = game._get_enemy_target_pos(stealth_enemy)
	_check(int(stealth_enemy.get("target_peer_id", 0)) != local_peer, "enemy retained stealthed local player as target")
	_check(stealth_target != game.player_pos, "enemy kept following Eclipsada during invisibility")
	game.net_players_by_peer[42]["stealthed"] = true
	_check(game._targetable_remote_peer_ids() == [43], "remote stealth fallback restored an invisible peer")
	game.eclipsada_stealth_timer = 0.0
	game.net_players_by_peer[42]["stealthed"] = false

	game.arauto_card_drops.clear()
	game._spawn_random_card_drops(Vector2(800, 430), 2, 0)
	var drop_owners: Dictionary = {}
	for drop_value in game.arauto_card_drops:
		var drop: Dictionary = drop_value
		drop_owners[int(drop.get("owner_peer", -1))] = true
	_check(drop_owners.size() == 3 and drop_owners.has(local_peer) and drop_owners.has(42) and drop_owners.has(43), "Larapio drops were not allocated to every player")
	game._spawn_arauto_evolution_fragment(Vector2(820, 450))
	var fragment_owners: Dictionary = {}
	for fragment_value in game.arauto_evolution_fragments:
		var fragment: Dictionary = fragment_value
		fragment_owners[int(fragment.get("owner_peer", -1))] = true
	_check(fragment_owners.size() == 3, "Arauto evolution fragment was not created for every player")

	game.mp_manifest_state_by_peer = {
		42: {"stage": game.MANIFEST_STAGE_AURA, "manifestation": 1, "aura": 2, "ready": true},
		43: {"stage": game.MANIFEST_STAGE_AURA, "manifestation": 3, "aura": 4, "ready": true}
	}
	game.mp_local_ready = true
	_check(game._manifest_choice_taken(1, false), "remote manifestation was not reserved")
	_check(game._manifest_choice_taken(4, true), "remote spectrum was not reserved")
	_check(game._manifest_all_players_ready(), "three-player manifestation readiness did not complete")
	game.mp_manifest_state_by_peer.erase(43)
	_check(not game._manifest_all_players_ready(), "selection started without every connected player")

	game.net_decks_by_peer = {
		42: {"counts": {"Porcao": 2}, "name": "DOIS"},
		43: {"counts": {"Defesa": 1}, "name": "TRES"}
	}
	_check(game._deck_view_peer_ids().size() == 3, "deck viewer did not include the whole team")
	game.deck_view_peer_id = 43
	_check(game._deck_view_name() == "TRES" and int(game._deck_view_counts().get("Defesa", 0)) == 1, "remote deck details are not readable")

	game.is_dead = true
	game.player_hp = 0
	game.net_players_by_peer[42]["dead"] = true
	game.net_players_by_peer[42]["hp"] = 0.0
	_check(not game._all_multiplayer_players_dead(), "run ended while the third player was alive")
	game.net_players_by_peer[43]["dead"] = true
	game.net_players_by_peer[43]["hp"] = 0.0
	_check(game._all_multiplayer_players_dead(), "run did not end after the whole team died")

	game.is_dead = false
	game.player_hp = game.player_hp_max
	game.previous_mode = "game"
	game.mode = "shop"
	game._finish_shop()
	_check(game.mode == "shop_return" and is_equal_approx(game.shop_return_timer, 3.0), "shop return did not freeze the world for three seconds")

	game._start_pause_mp_request(true, true, 1, 3)
	_check(game.pause_mp_expected_count == 3 and game.pause_mp_vote_count == 1, "pause consensus did not wait for all three votes")
	_check(game.NET_PLAYER_SYNC_INTERVAL_MS <= 16 and game.NET_WORLD_SYNC_INTERVAL_MS <= 25 and game.NET_WORLD_VISUAL_SYNC_INTERVAL_MS <= 33, "network cadence exceeds the low-latency budget")

	game.online_room_owner = false
	game.score = 100
	game.score_total = 100
	game._apply_score_delta(50)
	_check(game.score == 100 and game.score_total == 100, "world replica mutated score locally instead of waiting for host authority")
	game.online_room_owner = true
	game._apply_score_delta(50, false)
	_check(game.score == 150 and game.score_total == 150, "world authority did not apply score delta locally")

	game.mode = "game"
	game.is_dead = true
	game.player_hp = 0
	game.card_cost = 100
	game.score = 0
	game.revive_request_cooldown = 0.0
	game._request_team_revive()
	_check(game.revive_request_outgoing and game.revive_request_timer > 0.0, "dead player could not request team revive without points")
	game._rpc_reject_team_revive(game._mp_unique_id())
	_check(game.revive_request_cooldown >= game.REVIVE_REQUEST_COOLDOWN - 0.01, "rejected revive request did not start cooldown")
	game.is_dead = false
	game.player_hp = game.player_hp_max
	game.revive_request_incoming = true
	game.revive_request_target_peer = 42
	game.revive_request_cost = 120
	game.score = 500
	game._accept_team_revive_request(game.REVIVE_PAY_POINTS)
	_check(game.score == 380 and not game.revive_request_incoming, "accepting revive did not deduct team cost and clear request")
	game.revive_request_incoming = true
	game.revive_request_target_peer = 43
	game.revive_request_cost = 240
	game.score = 0
	game.player_hp_max = 500
	game.player_hp = 400
	game._accept_team_revive_request(game.REVIVE_PAY_LIFE)
	_check(game.score == 0 and is_equal_approx(game.player_hp, 200.0) and game.revive_heal_penalty_timer >= game.REVIVE_HEAL_PENALTY_DURATION - 0.01 and not game.revive_request_incoming, "life revive did not sacrifice hp, apply heal penalty and clear request")
	var healed: float = game._heal_player(100.0, "revive_smoke", false)
	_check(is_equal_approx(healed, 50.0) and is_equal_approx(game.player_hp, 250.0), "revive sacrifice did not reduce incoming healing by 50 percent")
	game.is_dead = true
	game.player_hp = 0
	game._handle_revive(true)
	_check(not game.is_dead and is_equal_approx(game.player_hp, game.player_hp_max * 0.5), "revive did not return player with half hp")

	print("MULTIPLAYER_THREE_PLAYER_CONTRACT_SMOKE_OK players=3 stealth=true rewards=per_peer choices=exclusive decks=shared shop_return=3s")
	game.queue_free()
	await process_frame
	quit(0)
