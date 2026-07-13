extends SceneTree


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate()
	var replica = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	root.add_child(replica)

	game._start_game()
	game.is_multiplayer = true
	game.online_room_owner = true
	game.net_player_peer_id = 42
	game.net_player_has_snapshot = true
	game.net_player_dead = false
	game.net_player_hp = 420
	game.net_player_pos = Vector2(900, 500)
	game.player_pos = Vector2(120, 500)
	game.player_hp = 0
	game.is_dead = true

	var enemy_dead_host := {
		"uid": 101,
		"type": game.ENEMY_COMMON,
		"pos": Vector2(180, 500),
		"speed": 100.0,
		"target_remote": false,
		"last_move_dir": Vector2.ZERO,
		"facing_dir": Vector2.RIGHT
	}
	var before_remote := Vector2(enemy_dead_host["pos"]).distance_to(game.net_player_pos)
	game._move_enemy(enemy_dead_host, 0.5)
	_check(Vector2(enemy_dead_host["pos"]).distance_to(game.net_player_pos) < before_remote, "enemy kept chasing dead local player instead of living remote player")

	game.player_hp = 450
	game.is_dead = false
	game.player_pos = Vector2(100, 500)
	game.net_player_pos = Vector2(900, 500)
	game.net_player_dead = false
	game.net_player_hp = 450
	var enemy_local := {"uid": 102, "type": game.ENEMY_COMMON, "pos": Vector2(500, 500), "speed": 100.0, "target_remote": false}
	var enemy_remote := {"uid": 103, "type": game.ENEMY_COMMON, "pos": Vector2(500, 500), "speed": 100.0, "target_remote": true}
	game._move_enemy(enemy_local, 0.5)
	game._move_enemy(enemy_remote, 0.5)
	_check(Vector2(enemy_local["pos"]).x < 500.0, "local-target enemy did not move toward local player")
	_check(Vector2(enemy_remote["pos"]).x > 500.0, "remote-target enemy did not move toward remote player")

	game.net_player_dead = true
	game.net_player_hp = 0
	var enemy_dead_remote := {"uid": 104, "type": game.ENEMY_COMMON, "pos": Vector2(500, 500), "speed": 100.0, "target_remote": true}
	game._move_enemy(enemy_dead_remote, 0.5)
	_check(Vector2(enemy_dead_remote["pos"]).x < 500.0, "enemy kept chasing dead remote player instead of living local player")

	replica._start_game()
	replica.is_multiplayer = true
	replica.online_room_owner = false
	game.current_phase = 4
	game.boss_active = true
	game.boss_pos = Vector2(420, 360)
	game.boss_attacks = [{"kind": "bubble", "age": 0.25, "duration": 1.0, "target": Vector2(480, 360)}]
	game.phase4_enemy_hazards = [{"kind": "boss4_pulse", "pos": Vector2(450, 360), "age": 0.15, "life": 1.2, "max": 1.2, "radius": 180.0}]
	replica._apply_remote_world_snapshot(game._pack_net_enemies(), game._pack_net_boss(), game._pack_net_enemy_bullets(), game._pack_net_boss_visuals())
	_check(replica.boss_active and replica.current_phase == 4, "replica did not accept boss authoritative state")
	_check(replica.boss_attacks.size() == 1, "replica did not receive boss attack visual state")
	_check(replica.phase4_enemy_hazards.size() == 1, "replica did not receive boss hazard visual state")

	game.mode = "shop"
	game.previous_mode = "game"
	game.shop_mp_ready_to_leave = false
	game.shop_mp_partner_ready = false
	game.score = 0
	game.card_cost = 120
	game._request_shop_exit_or_finish()
	_check(game.mode == "shop_mp_waiting", "multiplayer shop without money did not move to waiting screen")
	game.shop_mp_partner_ready = true
	_check(game._check_shop_mp_exit(), "shop exit did not finish when both players were ready")
	_check(game.mode == "shop_return" and game.shop_return_timer > 0.0, "shop did not start the 3s return transition")
	game._update_shop_return(game.SHOP_RETURN_TIME + 0.1)
	_check(game.mode == "game", "shop return transition did not end in game mode")

	print("MULTIPLAYER_TARGETING_BOSS_SHOP_SMOKE_OK")
	root.remove_child(game)
	root.remove_child(replica)
	game.free()
	replica.free()
	quit(0)
