extends SceneTree


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host_game = load("res://scenes/Main.tscn").instantiate()
	var client_game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(host_game)
	root.add_child(client_game)
	host_game.is_multiplayer = true
	host_game.online_room_owner = true
	client_game.is_multiplayer = true
	client_game.online_room_owner = false

	host_game.enemies = [{
		"uid": 7001,
		"type": host_game.ENEMY_COMMON,
		"pos": Vector2(100, 200),
		"hp": 100.0,
		"max_hp": 100.0,
		"phase": 0.0,
		"last_move_dir": Vector2.RIGHT
	}]
	host_game.enemy_bullets = [{
		"pos": Vector2(160, 240),
		"dir": Vector2.RIGHT,
		"life": 4.0,
		"damage": 20.0,
		"type": "atirador",
		"radius": 24.0,
		"phase": 0.0,
		"speed_mult": 1.0
	}]
	host_game.boss_pos = Vector2(300, 280)
	client_game._apply_remote_world_snapshot(
		host_game._pack_net_enemies(),
		PackedFloat32Array([host_game.boss_pos.x, host_game.boss_pos.y, 1000.0, 0.0]),
		host_game._pack_net_enemy_bullets()
	)
	_check(Vector2(client_game.enemies[0]["pos"]).is_equal_approx(Vector2(100, 200)), "initial enemy snapshot did not snap into place")

	await create_timer(0.06).timeout
	host_game.enemies[0]["pos"] = Vector2(220, 200)
	host_game.enemy_bullets[0]["pos"] = Vector2(310, 240)
	host_game.boss_pos = Vector2(420, 280)
	client_game._apply_remote_world_snapshot(
		host_game._pack_net_enemies(),
		PackedFloat32Array([host_game.boss_pos.x, host_game.boss_pos.y, 1000.0, 0.0]),
		host_game._pack_net_enemy_bullets()
	)

	_check(Vector2(client_game.enemies[0]["pos"]).x < 120.0, "enemy position jumped directly to the newest packet")
	_check(Vector2(client_game.enemy_bullets[0]["pos"]).x < 180.0, "bullet position jumped directly to the newest packet")
	_check(client_game.boss_pos.x < 320.0, "boss position jumped directly to the newest packet")
	client_game._update_network_interpolation(1.0 / 60.0)
	var enemy_after_one_frame := Vector2(client_game.enemies[0]["pos"]).x
	_check(enemy_after_one_frame > 100.0 and enemy_after_one_frame < 220.0, "enemy was not smoothly advanced between snapshots")

	client_game._accept_remote_player_position(42, Vector2(500, 300))
	await create_timer(0.04).timeout
	client_game._accept_remote_player_position(42, Vector2(560, 300))
	_check(client_game.net_player_render_pos.x < 520.0, "remote player jumped directly to snapshot")
	client_game._update_network_interpolation(1.0 / 60.0)
	_check(client_game.net_player_render_pos.x > 500.0 and client_game.net_player_render_pos.x < 560.0, "remote player interpolation did not advance smoothly")

	client_game.enemies = [{"uid": 9901, "type": client_game.ENEMY_COMMON, "pos": Vector2(820, 360), "hp": 100.0, "max_hp": 100.0, "phase": 0.0, "bit": 0, "last_move_dir": Vector2.ZERO}]
	client_game.remote_bullets = [{
		"source": 42,
		"uid": "42:1",
		"pos": Vector2(780, 360),
		"dir": Vector2.RIGHT,
		"speed": 200.0,
		"life": 1.0,
		"max_life": 1.0,
		"age": 0.0,
		"phase": 0.0,
		"kind": "eletrica",
		"pierce": false,
		"hits": {},
		"color": Color.CYAN
	}]
	client_game._update_remote_bullets(0.20)
	_check(client_game.remote_bullets.is_empty(), "non-piercing remote projectile crossed an enemy instead of ending on impact")
	client_game.remote_bullets = [{
		"source": 42,
		"uid": "42:2",
		"pos": Vector2(820, 360),
		"dir": Vector2.RIGHT,
		"speed": 0.0,
		"life": 1.0,
		"max_life": 1.0,
		"age": 0.0,
		"phase": 0.0,
		"kind": "prismatica",
		"pierce": true,
		"hits": {},
		"color": Color.CYAN
	}]
	client_game._update_remote_bullets(0.01)
	_check(not client_game.remote_bullets.is_empty() and int(client_game.remote_bullets[0].get("enemy_hits_count", 0)) == 1, "piercing remote projectile did not register its impact/ricochet")

	client_game.net_player_peer_id = 42
	client_game.net_player_render_pos = Vector2(560, 300)
	client_game._rpc_ability_visual(42, 1, client_game.NET_ABILITY_SKILL, 1, Vector2(560, 300), Vector2(700, 300), 0.8, 0.0, 4)
	client_game._rpc_ability_visual(42, 2, client_game.NET_ABILITY_SECONDARY, 0, Vector2(560, 300), Vector2(560, 300), 2.0, 0.0, 4)
	client_game._rpc_ability_visual(42, 3, client_game.NET_ABILITY_TELEPORT, 2, Vector2(560, 300), Vector2(760, 300), 0.55, 0.0, 4)
	client_game.mode = "game"
	client_game.queue_redraw()
	await process_frame
	await process_frame
	_check(client_game.net_ability_visuals.size() == 3, "Q/E/TP remote visuals failed during rendered frames")

	var payload_bytes := var_to_bytes([
		host_game._pack_net_enemies(),
		host_game._pack_net_enemy_bullets()
	]).size()
	_check(payload_bytes < 512, "compact one-entity snapshot exceeded expected budget")
	print("MULTIPLAYER_NETWORK_SMOOTHING_SMOKE_OK payload_bytes=%d enemy_step=%.2f" % [payload_bytes, enemy_after_one_frame - 100.0])

	root.remove_child(host_game)
	root.remove_child(client_game)
	host_game.free()
	client_game.free()
	quit(0)
