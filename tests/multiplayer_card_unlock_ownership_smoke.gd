extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MULTIPLAYER_CARD_UNLOCK_OWNERSHIP_FAIL " + message)
	quit(1)


func _progress(metric: String) -> float:
	return float(game.card_unlock_progress.get(metric, 0.0))


func _remote_state(pos: Vector2) -> Dictionary:
	return {
		"pos": pos,
		"render_pos": pos,
		"velocity": Vector2.ZERO,
		"hp": 450.0,
		"hp_max": 500.0,
		"alive": true,
		"dead": false,
		"eliminated": false,
		"has_snapshot": true,
		"name": "Cliente"
	}


func _setup_authority() -> void:
	game._start_game()
	game.mode = "game"
	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = true
	game.online_local_spectator = false
	game.is_dead = false
	game.player_hp = game.player_hp_max
	game.player_pos = Vector2(640, 360)
	game.net_players_by_peer = {42: _remote_state(Vector2(720, 360))}
	game.card_unlock_progress.clear()
	game.unlock_notifications.clear()
	game.unlocked_card_ids.clear()
	game._ensure_card_unlock_defaults()
	game.net_seen_card_unlock_request_ids.clear()
	game.net_confirmed_card_unlock_event_ids.clear()


func _enemy(uid: int) -> Dictionary:
	return {
		"uid": uid,
		"type": game.ENEMY_COMMON,
		"pos": Vector2(720, 360),
		"hp": 1.0,
		"max_hp": 20.0,
		"points": 20
	}


func _kill_with_peer(peer_id: int, uid: int) -> void:
	var enemy := _enemy(uid)
	game.enemies = [enemy]
	var killed: bool = game._damage_enemy(enemy, 999.0, "eletrica", false, false, game.player_pos, "basic_attack", peer_id)
	_check(killed, "enemy was not killed")
	game._kill_enemy(enemy)


func _run_remote_kill_does_not_credit_host() -> void:
	_setup_authority()
	_kill_with_peer(42, 1001)
	_check(_progress("enemy_kills") == 0.0, "remote enemy kill credited host")


func _run_host_kill_credits_host_once() -> void:
	_setup_authority()
	_kill_with_peer(game._mp_unique_id(), 1002)
	_check(_progress("enemy_kills") == 1.0, "host enemy kill did not credit host")
	game._add_card_unlock_progress("enemy_kills", 1.0, game._mp_unique_id(), "host_kill_duplicate")
	game._add_card_unlock_progress("enemy_kills", 1.0, game._mp_unique_id(), "host_kill_duplicate")
	_check(_progress("enemy_kills") == 2.0, "duplicate event id was not deduped for host")


func _run_client_request_validation() -> void:
	_setup_authority()
	game._rpc_request_card_unlock_progress("client_shot_1", "shots_fired", 1.0, false, 42)
	_check(game.net_seen_card_unlock_request_ids.has("client_shot_1"), "valid client event was not accepted")
	_check(_progress("shots_fired") == 0.0, "client shot credited host")
	var seen_count: int = game.net_seen_card_unlock_request_ids.size()
	game._rpc_request_card_unlock_progress("client_shot_1", "shots_fired", 1.0, false, 42)
	_check(game.net_seen_card_unlock_request_ids.size() == seen_count, "duplicate client request changed seen count")
	game._rpc_request_card_unlock_progress("client_fake_kill", "enemy_kills", 1.0, false, 42)
	_check(not game.net_seen_card_unlock_request_ids.has("client_fake_kill"), "client was allowed to self-credit enemy kills")
	game.net_players_by_peer[42]["dead"] = true
	game.net_players_by_peer[42]["eliminated"] = true
	game.net_players_by_peer[42]["hp"] = 0.0
	game._rpc_request_card_unlock_progress("dead_damage", "damage_taken_events", 1.0, false, 42)
	_check(not game.net_seen_card_unlock_request_ids.has("dead_damage"), "dead or eliminated client generated progress")


func _run_collective_boss_and_phase() -> void:
	_setup_authority()
	game._confirm_card_unlock_progress_for_active_players("boss_kills", 1.0, false)
	_check(_progress("boss_kills") == 1.0, "collective boss kill did not credit living host")
	game._confirm_card_unlock_progress_for_active_players("phase_reached", 3.0, true)
	_check(_progress("phase_reached") == 3.0, "collective phase progress did not update host")


func _run_client_confirm_updates_ui_after_authority() -> void:
	_setup_authority()
	game.is_host = false
	game.online_room_owner = false
	game.card_unlock_progress.clear()
	game.unlock_notifications.clear()
	game.unlocked_card_ids.clear()
	game._ensure_card_unlock_defaults()
	game._rpc_confirm_card_unlock_progress("confirm_poison", game._mp_unique_id(), "enemy_kills", 180.0, false)
	_check(_progress("enemy_kills") == 180.0, "confirmed client progress was not applied")
	_check(bool(game.unlocked_card_ids.get("Poison", false)), "confirmed client progress did not unlock card")
	_check(game.unlock_notifications.size() == 1, "confirmed client progress did not update unlock UI")
	game._rpc_confirm_card_unlock_progress("confirm_poison", game._mp_unique_id(), "enemy_kills", 180.0, false)
	_check(_progress("enemy_kills") == 180.0, "replayed confirmation duplicated progress")
	game.net_players_by_peer.clear()
	game._rpc_confirm_card_unlock_progress("confirm_poison", game._mp_unique_id(), "enemy_kills", 180.0, false)
	_check(_progress("enemy_kills") == 180.0, "reconnect replay duplicated progress")


func _run_simultaneous_confirmations() -> void:
	_setup_authority()
	game.is_host = false
	game.online_room_owner = false
	game.card_unlock_progress.clear()
	game.net_confirmed_card_unlock_event_ids.clear()
	game._rpc_confirm_card_unlock_progress("heal_a", game._mp_unique_id(), "healing_events", 1.0, false)
	game._rpc_confirm_card_unlock_progress("heal_b", game._mp_unique_id(), "healing_events", 1.0, false)
	_check(_progress("healing_events") == 2.0, "simultaneous confirmations collapsed incorrectly")


func _run_solo_unchanged() -> void:
	game._start_game()
	game.is_multiplayer = false
	game.card_unlock_progress.clear()
	game._add_card_unlock_progress("enemy_kills", 2.0)
	game._set_card_unlock_progress_max("phase_reached", 4.0)
	_check(_progress("enemy_kills") == 2.0, "solo add progress changed")
	_check(_progress("phase_reached") == 4.0, "solo max progress changed")


func _run() -> void:
	await process_frame
	_run_remote_kill_does_not_credit_host()
	_run_host_kill_credits_host_once()
	_run_client_request_validation()
	_run_collective_boss_and_phase()
	_run_client_confirm_updates_ui_after_authority()
	_run_simultaneous_confirmations()
	_run_solo_unchanged()
	print("MULTIPLAYER_CARD_UNLOCK_OWNERSHIP_SMOKE_OK host client validation duplicate simultaneous reconnect solo")
	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	quit(0)
