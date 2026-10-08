extends SceneTree

const AuraSystem = preload("res://scripts/aura_system.gd")

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MULTIPLAYER_GAMEPLAY_ORBS_FAIL " + message)
	failed = true


func _aura_index(name: String) -> int:
	for index in range(game.AURAS.size()):
		if String(game.AURAS[index].get("name", "")) == name:
			return index
	return -1


func _remote_state(pos: Vector2, aura_name: String = "Racional") -> Dictionary:
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
		"aura": _aura_index(aura_name),
		"name": aura_name
	}


func _setup_authority(host_aura: String = "Racional", remote_aura: String = "Racional") -> void:
	game._start_game()
	game.mode = "game"
	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = true
	game.online_local_spectator = false
	game.player_pos = Vector2(640, 360)
	game.player_hp_max = 500.0
	game.player_hp = 250.0
	game.is_dead = false
	game.selected_aura = _aura_index(host_aura)
	game.aura_state = AuraSystem.create(host_aura, 1)
	game.net_players_by_peer = {42: _remote_state(Vector2(700, 360), remote_aura)}
	game.heal_orbs.clear()
	game.net_collected_gameplay_orb_ids.clear()


func _enemy(uid: int = 1001) -> Dictionary:
	return {
		"uid": uid,
		"type": game.ENEMY_COMMON,
		"pos": Vector2(720, 360),
		"hp": 1.0,
		"max_hp": 20.0,
		"points": 20
	}


func _kill_with_peer(peer_id: int, source: String = "eletrica", category: String = "basic_attack") -> void:
	var enemy := _enemy(1000 + game.heal_orbs.size())
	game.enemies = [enemy]
	var killed: bool = game._damage_enemy(enemy, 999.0, source, false, false, Vector2(640, 360), category, peer_id)
	_check(killed, "enemy was not killed by test damage")
	game._kill_enemy(enemy)


func _run_voraz_host_kill() -> void:
	_setup_authority("Voraz", "Racional")
	_kill_with_peer(game._mp_unique_id())
	_check_hunger_owner(game._mp_unique_id(), 1)


func _check_hunger_owner(peer_id: int, expected_count: int) -> void:
	# A kill may also roll a normal heal drop; it is not a Voraz reward.
	var hunger: Array = game.heal_orbs.filter(func(orb): return String(orb.get("kind", "")) == "voraz_hunger")
	_check(hunger.size() == expected_count, "wrong number of hunger orbs")
	for orb in hunger:
		_check(int(orb.get("owner_peer", 0)) == peer_id, "Voraz orb ownership changed")


func _run_voraz_client_kill() -> void:
	_setup_authority("Racional", "Voraz")
	_kill_with_peer(42, "skill_q", "skill_q")
	_check_hunger_owner(42, 1)


func _run_no_voraz_no_drop() -> void:
	_setup_authority("Racional", "Voraz")
	_kill_with_peer(game._mp_unique_id(), "veneno", "damage_over_time")
	_check_hunger_owner(game._mp_unique_id(), 0)


func _run_voraz_sources_keep_owner() -> void:
	_setup_authority("Racional", "Voraz")
	var kills := 0
	for source_data in [
		{"source": "eletrica", "category": "basic_attack"},
		{"source": "skill_q", "category": "skill_q"},
		{"source": "veneno", "category": "damage_over_time"},
		{"source": "petro", "category": "summon"}
	]:
		_kill_with_peer(42, String(source_data["source"]), String(source_data["category"]))
		kills += 1
		_check_hunger_owner(42, kills)


func _run_host_heal_collect() -> void:
	_setup_authority("Racional", "Racional")
	game._spawn_heal_orb(game.player_pos, 0.5)
	var uid: String = String(game.heal_orbs[0].get("uid", ""))
	game._update_heal_orbs(0.016)
	_check(game.heal_orbs.is_empty(), "host did not despawn collected heal orb")
	_check(game.player_hp > 250.0, "host did not receive heal orb healing")
	game._rpc_gameplay_orb_removed(uid, "collected", game._mp_unique_id(), {"uid": uid, "kind": "heal", "fraction": 0.5, "pos": game.player_pos})
	_check(game.player_hp <= game.player_hp_max, "duplicate heal collect over-applied")


func _run_client_heal_collect() -> void:
	_setup_authority("Racional", "Racional")
	game._spawn_heal_orb(Vector2(700, 360), 0.5)
	var uid: String = String(game.heal_orbs[0].get("uid", ""))
	game._rpc_request_gameplay_orb_collect(uid, 42)
	_check(game.heal_orbs.is_empty(), "client collect did not despawn heal orb on authority")
	_check(game.net_collected_gameplay_orb_ids.has(uid), "client collect was not deduped by uid")


func _run_simultaneous_collect() -> void:
	_setup_authority("Racional", "Racional")
	game._spawn_heal_orb(Vector2(670, 360), 0.5)
	var uid: String = String(game.heal_orbs[0].get("uid", ""))
	game._rpc_request_gameplay_orb_collect(uid, 42)
	var collected_count: int = game.net_collected_gameplay_orb_ids.size()
	game._rpc_request_gameplay_orb_collect(uid, game._mp_unique_id())
	_check(game.net_collected_gameplay_orb_ids.size() == collected_count, "simultaneous duplicate collect changed accepted count")
	_check(game.heal_orbs.is_empty(), "simultaneous collect left orb alive")


func _run_expire_and_reorder() -> void:
	_setup_authority("Racional", "Racional")
	game._spawn_heal_orb(Vector2(1200, 900), 0.25)
	var uid: String = String(game.heal_orbs[0].get("uid", ""))
	game.heal_orbs[0]["life"] = 0.01
	game._update_heal_orbs(0.05)
	_check(game.heal_orbs.is_empty(), "expired orb did not despawn")
	_check(game.net_collected_gameplay_orb_ids.has(uid), "expired orb was not marked removed")
	game._rpc_gameplay_orb_spawned({"uid": uid, "kind": "heal", "pos": Vector2(1200, 900), "fraction": 0.25, "life": 12.0})
	_check(game.heal_orbs.is_empty(), "stale spawn restored removed orb")


func _run_inelegible_collectors() -> void:
	_setup_authority("Racional", "Racional")
	game.online_local_spectator = true
	game._spawn_heal_orb(game.player_pos, 0.5)
	game._update_heal_orbs(0.016)
	_check(game.heal_orbs.size() == 1, "spectator collected heal orb")
	game.online_local_spectator = false
	game.net_players_by_peer[42]["dead"] = true
	game.net_players_by_peer[42]["eliminated"] = true
	game.net_players_by_peer[42]["hp"] = 0.0
	var uid: String = String(game.heal_orbs[0].get("uid", ""))
	game._rpc_request_gameplay_orb_collect(uid, 42)
	_check(game.heal_orbs.size() == 1, "dead or eliminated client collected heal orb")


func _run_solo_unchanged() -> void:
	game._start_game()
	game.mode = "game"
	game.is_multiplayer = false
	game.player_pos = Vector2(640, 360)
	game.player_hp_max = 500.0
	game.player_hp = 250.0
	game.heal_orbs.clear()
	game._spawn_heal_orb(game.player_pos, 0.5)
	game._update_heal_orbs(0.016)
	_check(game.heal_orbs.is_empty(), "solo heal orb did not collect")
	_check(game.player_hp > 250.0, "solo heal orb did not heal")


func _run() -> void:
	await process_frame
	_check(_aura_index("Voraz") >= 0, "Voraz aura is missing")
	_run_voraz_host_kill()
	_run_voraz_client_kill()
	_run_no_voraz_no_drop()
	_run_voraz_sources_keep_owner()
	_run_host_heal_collect()
	_run_client_heal_collect()
	_run_simultaneous_collect()
	_run_expire_and_reorder()
	_run_inelegible_collectors()
	_run_solo_unchanged()
	game.set_process(false)
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	if not failed:
		print("MULTIPLAYER_GAMEPLAY_ORBS_SMOKE_OK voraz_host voraz_client ownership heal_host heal_client duplicate expire reorder ineligible solo")
	quit(1 if failed else 0)
