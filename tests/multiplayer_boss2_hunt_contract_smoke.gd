extends SceneTree

var host: Node
var client: Node


func _initialize() -> void:
	host = load("res://scenes/Main.tscn").instantiate()
	client = load("res://scenes/Main.tscn").instantiate()
	root.add_child(host)
	root.add_child(client)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("MULTIPLAYER_BOSS2_HUNT_CONTRACT_FAIL " + message)
	quit(1)


func _remote_state(pos: Vector2) -> Dictionary:
	return {"pos": pos, "render_pos": pos, "hp": 500.0, "hp_max": 500.0, "dead": false, "eliminated": false, "stealthed": false, "has_snapshot": true}


func _setup(game: Node, host_mode: bool) -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = true
	game.is_host = host_mode
	game.online_room_owner = host_mode
	game.online_connected = false
	game.online_lobby_connected_count = 3
	game.current_phase = 2
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = 6000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_hp_max = 500
	game.player_hp = 500
	game.player_pos = game.boss_pos + Vector2(-220, 0)
	game._reset_boss2_state()


func _cleanup(game: Node) -> void:
	if not is_instance_valid(game):
		return
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()


func _run() -> void:
	_setup(host, true)
	_setup(client, false)
	host.net_players_by_peer = {
		42: _remote_state(host.boss_pos + Vector2(190, -80)),
		43: _remote_state(host.boss_pos + Vector2(240, 90))
	}
	host.net_player_peer_id = 42
	host._sync_legacy_remote_player(42)
	host._reset_boss_party_scaling_context(2)
	host.online_lobby_connected_count = 2
	host._reset_boss_party_scaling_context(2)
	_check(int(host._boss2_hunt_params().get("party_size", 0)) == 2, "duo party size was not fixed")
	host.online_lobby_connected_count = 3
	host._reset_boss_party_scaling_context(2)

	host._boss2_start_hunt_mark()
	_check(host.boss_attacks.size() == 1, "authority did not create hunt")
	var authority_attack: Dictionary = host.boss_attacks[0]
	_check(String(authority_attack.get("event_id", "")) != "" and int(authority_attack.get("seed", 0)) != 0, "authority event metadata missing")
	_check(int(authority_attack.get("party_size", 0)) == 3, "fixed party size missing")
	var tracked_peer := int(authority_attack.get("target_peer", 0))
	if tracked_peer == host._mp_unique_id():
		host.player_pos += Vector2(48, 36)
	else:
		host.net_players_by_peer[tracked_peer]["pos"] = Vector2(host.net_players_by_peer[tracked_peer]["pos"]) + Vector2(48, 36)
	host._update_boss2_attacks(0.1)
	authority_attack = host.boss_attacks[0]
	var expected_target: Vector2 = host._boss2_hunt_target_pos(tracked_peer, Vector2.ZERO).clamp(Vector2(90, 90), host.WORLD_SIZE - Vector2(90, 90))
	_check(Vector2(authority_attack.get("target_pos", Vector2.ZERO)).is_equal_approx(expected_target), "authority did not update moving target before lock")

	var packet: Dictionary = host._pack_net_boss_visuals()
	client._apply_remote_boss_visual_snapshot(packet)
	_check(client.boss_attacks.size() == 1, "client did not receive telegraph")
	var client_attack: Dictionary = client.boss_attacks[0]
	_check(String(client_attack.get("event_id", "")) == String(authority_attack.get("event_id", "")), "client event id diverged")
	_check(int(client_attack.get("seed", 0)) == int(authority_attack.get("seed", 0)), "client seed diverged")
	client_attack["age"] = float(client_attack.get("warn", client.BOSS2_HUNT_WARN)) - 0.01
	client_attack["locked"] = true
	client_attack["origin"] = client.boss_pos
	client_attack["target_pos"] = client.player_pos
	client_attack["locked_pos"] = client.player_pos
	var client_hp_before: int = client.player_hp
	client._update_boss2_attacks(0.02)
	_check(client.player_hp == client_hp_before, "replica simulated authoritative hunt damage")
	client._apply_remote_boss_visual_snapshot(packet)
	_check(client.shared_boss_attack_contract.has_seen_visual_event(String(authority_attack.get("event_id", "")), "telegraph"), "telegraph ledger did not record event")

	authority_attack["impact"] = true
	packet = host._pack_net_boss_visuals()
	client._apply_remote_boss_visual_snapshot(packet)
	client._apply_remote_boss_visual_snapshot(packet)
	_check(client.shared_boss_attack_contract.has_seen_visual_event(String(authority_attack.get("event_id", "")), "impact"), "impact ledger did not dedupe event")

	host.net_players_by_peer[42]["dead"] = true
	host.net_players_by_peer[42]["hp"] = 0.0
	host.boss2_hunt_target_grace.clear()
	var post_death: Dictionary = host._boss2_pick_hunt_target_entry(false)
	_check(int(post_death.get("peer_id", 0)) != 42, "eliminated target remained eligible")
	host.net_players_by_peer[42]["dead"] = false
	host.net_players_by_peer[42]["hp"] = 350.0
	_check(host._targetable_remote_peer_ids(true).has(42), "revived target did not return")
	host.net_players_by_peer.erase(43)
	_check(not host._boss2_pick_hunt_target_entry(false).is_empty(), "disconnect blocked remaining targets")

	host._clear_boss_runtime_hazards()
	client._apply_remote_boss_visual_snapshot(host._pack_net_boss_visuals())
	_check(client.boss_attacks.is_empty(), "phase cleanup left ghost telegraph")
	# Preserve the ledger across cleanup: a delayed, stale snapshot cannot replay
	# feedback after the real attack has already been removed.
	client._apply_remote_boss_visual_snapshot(packet)
	_check(client.shared_boss_attack_contract.has_seen_visual_event(String(authority_attack.get("event_id", "")), "telegraph"), "stale snapshot bypassed event dedupe")

	print("MULTIPLAYER_BOSS2_HUNT_CONTRACT_OK host=true client=true party=3 death_revive=true disconnect=true idempotent=true cleanup=true")
	_cleanup(client)
	_cleanup(host)
	client = null
	host = null
	for i in range(4):
		await process_frame
	quit(0)
