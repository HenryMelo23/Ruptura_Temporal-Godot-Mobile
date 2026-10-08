extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("BOSS2_HUNT_MARK_SMOKE_FAIL " + message)
	quit(1)


func _remote_state(pos: Vector2, name: String) -> Dictionary:
	return {
		"pos": pos,
		"render_pos": pos,
		"velocity": Vector2.ZERO,
		"hp": 480.0,
		"hp_max": 480.0,
		"dead": false,
		"eliminated": false,
		"stealthed": false,
		"has_snapshot": true,
		"name": name
	}


func _setup_boss2() -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.current_phase = 2
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = 6000.0
	game.boss_pos = game.WORLD_SIZE * 0.5
	game.player_hp_max = 500
	game.player_hp = 500
	game.player_pos = game.boss_pos + Vector2(-240, 0)
	game.boss_attacks.clear()
	game._reset_boss2_state()


func _start_hunt_and_peer() -> int:
	game.boss_attacks.clear()
	game._boss2_start_hunt_mark()
	_check(game.boss_attacks.size() == 1, "hunt attack was not created")
	var attack: Dictionary = game.boss_attacks[0]
	_check(String(attack.get("kind", "")) == "hunt_mark", "wrong attack kind")
	return int(attack.get("target_peer", 0))


func _run() -> void:
	_setup_boss2()

	var solo_peer: int = _start_hunt_and_peer()
	_check(solo_peer == game._mp_unique_id(), "solo hunt did not target the local player")
	_check(not game._boss2_hunt_can_start(), "solo grace allowed immediate repeated hunt")
	game._update_boss2_hunt_grace(game.BOSS2_HUNT_GRACE + 0.1)
	_check(game._boss2_hunt_can_start(), "solo grace did not expire")

	game.is_multiplayer = true
	game.is_host = true
	game.online_connected = false
	game.online_lobby_connected_count = 3
	game.net_players_by_peer = {
		42: _remote_state(game.boss_pos + Vector2(180, -80), "DOIS"),
		43: _remote_state(game.boss_pos + Vector2(260, 90), "TRES")
	}
	game.net_player_peer_id = 42
	game._sync_legacy_remote_player(42)
	game._reset_boss_party_scaling_context(2)
	game.boss2_hunt_target_grace.clear()
	game.boss2_hunt_last_target_peer_id = 0
	game.boss2_hunt_sequence = 0
	var first_peer: int = _start_hunt_and_peer()
	var first_attack: Dictionary = game.boss_attacks[0]
	_check(int(first_attack.get("party_size", 0)) == 3, "hunt did not snapshot fixed party size")
	_check(float(first_attack.get("damage_scale", 0.0)) == game.MULTIPLAYER_BOSS_DAMAGE_SCALE_3P, "hunt did not use party pressure coefficient")
	var second_peer: int = _start_hunt_and_peer()
	var third_peer: int = _start_hunt_and_peer()
	_check(first_peer != second_peer and second_peer != third_peer and first_peer != third_peer, "hunt did not rotate among three living targets")
	_check(not game._boss2_hunt_can_start(), "hunt ignored per-target grace after all players were marked")

	game._update_boss2_hunt_grace(float(first_attack.get("grace", game.BOSS2_HUNT_GRACE)) + 4.5)
	game.net_players_by_peer[42]["dead"] = true
	game.net_players_by_peer[42]["hp"] = 0.0
	_check(not game._boss2_pick_hunt_target_entry(false).is_empty(), "dead peer incorrectly blocked living targets")
	var chosen_after_death: Dictionary = game._boss2_pick_hunt_target_entry(false)
	_check(int(chosen_after_death.get("peer_id", 0)) != 42, "dead peer remained eligible for hunt")
	game.net_players_by_peer[42]["dead"] = false
	game.net_players_by_peer[42]["hp"] = 360.0
	_check(game._targetable_remote_peer_ids(true).has(42), "revived peer did not become targetable again")

	game.is_multiplayer = false
	game.net_players_by_peer.clear()
	game.boss2_hunt_target_grace.clear()
	game.player_hp = game.player_hp_max
	game.boss_pos = Vector2(760, 450)
	game.player_pos = Vector2(520, 450)
	game.boss_attacks.clear()
	game._boss2_start_hunt_mark()
	var attack_damage: Dictionary = game.boss_attacks[0]
	attack_damage["age"] = float(attack_damage.get("warn", game.BOSS2_HUNT_WARN)) - 0.01
	attack_damage["origin"] = game.boss_pos
	attack_damage["locked"] = true
	attack_damage["target_pos"] = game.player_pos
	attack_damage["locked_pos"] = game.player_pos
	var hp_before: int = game.player_hp
	game._update_boss2_attacks(0.02)
	var hp_after: int = game.player_hp
	_check(hp_after < hp_before, "hunt impact did not damage player on trajectory")
	game._update_boss2_attacks(0.08)
	_check(game.player_hp == hp_after, "hunt impact damaged the same peer twice")

	game.boss_attacks.clear()
	game.boss2_hunt_target_grace.clear()
	game._boss2_start_hunt_mark()
	var dodge_attack: Dictionary = game.boss_attacks[0]
	dodge_attack["age"] = float(dodge_attack.get("lock_at", 1.0)) + 0.02
	dodge_attack["origin"] = game.boss_pos
	dodge_attack["locked"] = true
	dodge_attack["locked_pos"] = game.player_pos
	game.player_pos += Vector2(0, 180)
	var dodge_hp: int = game.player_hp
	dodge_attack["age"] = float(dodge_attack.get("warn", game.BOSS2_HUNT_WARN)) - 0.01
	game._update_boss2_attacks(0.02)
	_check(game.player_hp == dodge_hp, "locked hunt trajectory was not dodgeable")

	print("BOSS2_HUNT_MARK_SMOKE_OK solo=true trio_rotation=true grace=true death_revive=true single_hit=true dodge=true party_scale=true")
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(4):
		await process_frame
	quit(0)
