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
	host_game.current_phase = 2
	host_game.boss_active = true
	host_game.boss_hp = 1000.0
	host_game.boss_hp_max = 1400.0
	host_game.boss_phase = 1.0
	host_game.boss_attacks = [{"kind": "bubble", "age": 0.20, "duration": 1.0, "target": Vector2(340, 280)}]
	host_game.boss2_state = host_game.BOSS2_STATE_FLASH_FREEZE
	host_game.boss2_anim_frame = 2
	host_game.boss2_ice_shards = [{"pos": Vector2(310, 280), "vel": Vector2(40, -20), "life": 0.6, "max": 0.8, "size": 8.0, "phase": 0.2}]
	host_game.boss2_snow_zones = [{"pos": Vector2(330, 300), "radius": 120.0, "life": 1.4, "max": 1.8, "phase": 0.4}]
	host_game.boss2_ultimate_timer = 12.0
	host_game.boss2_ultimate_center = Vector2(340, 300)
	host_game.boss3_miasma_variant = 3
	host_game.boss3_miasma_timer = 7.5
	host_game.boss3_miasma_clouds = [{"pos": Vector2(370, 310), "dir": Vector2.LEFT, "life": 3.0, "max": 8.0, "radius": 42.0, "phase": 0.8, "hit": {}}]
	host_game.boss3_faith_link_timer = 2.0
	host_game.phase4_enemy_hazards = [{"kind": "boss4_pulse", "pos": Vector2(360, 320), "age": 0.10, "life": 1.0, "max": 1.0, "radius": 180.0}]
	client_game._apply_remote_world_snapshot(
		host_game._pack_net_enemies(),
		host_game._pack_net_boss(),
		host_game._pack_net_enemy_bullets()
	)
	client_game._apply_remote_boss_visual_snapshot(host_game._pack_net_boss_visuals())
	_check(Vector2(client_game.enemies[0]["pos"]).is_equal_approx(Vector2(100, 200)), "initial enemy snapshot did not snap into place")
	_check(client_game.boss_active, "boss active state was not synchronized to replica")
	_check(client_game.current_phase == 2, "boss phase index was not synchronized to replica")
	_check(is_equal_approx(client_game.boss_hp_max, 1400.0), "boss max HP was not synchronized to replica")
	_check(client_game.boss_attacks.size() == 1 and String(client_game.boss_attacks[0].get("kind", "")) == "bubble", "boss attack visuals were not synchronized to replica")
	_check(client_game.boss2_state == host_game.BOSS2_STATE_FLASH_FREEZE and client_game.boss2_anim_frame == 2, "boss2 animation state was not synchronized to replica")
	_check(client_game.boss2_ice_shards.size() == 1 and client_game.boss2_snow_zones.size() == 1, "boss2 ice visuals were not synchronized to replica")
	_check(is_equal_approx(client_game.boss2_ultimate_timer, 12.0) and client_game.boss2_ultimate_center == Vector2(340, 300), "boss2 ultimate visual state was not synchronized")
	host_game.current_phase = 3
	client_game._apply_remote_boss_visual_snapshot(host_game._pack_net_boss_visuals())
	_check(client_game.boss3_miasma_variant == 3 and client_game.boss3_miasma_clouds.size() == 1, "boss3 miasma visuals were not synchronized to replica")
	_check(is_equal_approx(client_game.boss3_faith_link_timer, 2.0), "boss3 faith link visual timer was not synchronized")
	host_game.current_phase = 4
	client_game._apply_remote_boss_visual_snapshot(host_game._pack_net_boss_visuals())
	_check(client_game.phase4_enemy_hazards.size() == 1, "boss/environment hazards were not synchronized to replica")
	host_game.current_phase = 2

	await create_timer(0.06).timeout
	host_game.enemies[0]["pos"] = Vector2(220, 200)
	host_game.enemy_bullets[0]["pos"] = Vector2(310, 240)
	host_game.boss_pos = Vector2(420, 280)
	client_game._apply_remote_world_snapshot(
		host_game._pack_net_enemies(),
		host_game._pack_net_boss(),
		host_game._pack_net_enemy_bullets()
	)
	client_game._apply_remote_boss_visual_snapshot(host_game._pack_net_boss_visuals())

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
	client_game._rpc_remote_player_state_light(42, Vector2(560, 300), 90, 100, false, 1, 2, client_game.NET_ANIM_FIRE, 1, true, 12)
	_check(client_game.net_player_anim_state == client_game.NET_ANIM_FIRE, "remote animation state was not preserved")
	_check(client_game.net_player_frame_idx == 1 and client_game.net_player_flip_h, "remote animation frame/facing was not preserved")
	_check(is_equal_approx(client_game.net_player_hp, 90.0) and is_equal_approx(client_game.net_player_hp_max, 100.0), "remote player health was not preserved for ally HUD")
	_check(is_equal_approx(client_game._remote_player_health_ratio(client_game.net_players_by_peer[42]), 0.9), "ally health bar ratio did not match remote HP")
	client_game._rpc_remote_player_state_light(42, Vector2(560, 300), 0, 100, true, 1, 2, client_game.NET_ANIM_DAMAGE, 0, false, 12)
	_check(is_equal_approx(client_game._remote_player_health_ratio(client_game.net_players_by_peer[42]), 0.0), "dead ally health bar should be empty")
	client_game._rpc_remote_player_state_light(42, Vector2(560, 300), 90, 100, false, 1, 2, client_game.NET_ANIM_FIRE, 1, true, 12)

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
	client_game.remote_bullets = [{
		"source": 42, "uid": "42:return", "pos": Vector2(560, 360), "dir": Vector2.RIGHT,
		"speed": 300.0, "life": 6.0, "max_life": 6.0, "age": 0.0, "phase": 0.0,
		"trail_cd": 0.0, "kind": "retornante", "motion_mode": "returning", "state": "ida",
		"pierce": true, "hits": {}, "color": Color.MAGENTA
	}]
	client_game.net_player_render_pos = Vector2(560, 360)
	client_game._update_remote_bullets(0.60)
	_check(not client_game.remote_bullets.is_empty() and String(client_game.remote_bullets[0].get("state", "")) == "volta", "returning projectile did not reproduce ida/volta trajectory")
	_check(not client_game.effects.is_empty(), "remote projectile did not emit its local visual trail")

	client_game.net_player_peer_id = 42
	client_game.net_player_render_pos = Vector2(560, 300)
	client_game._rpc_ability_visual(42, 1, client_game.NET_ABILITY_SKILL, 1, Vector2(560, 300), Vector2(700, 300), 0.8, 0.0, {"seed": 11, "rotations": 3.0}, 4)
	client_game._rpc_ability_visual(42, 2, client_game.NET_ABILITY_SECONDARY, 0, Vector2(560, 300), Vector2(560, 300), 2.0, 0.0, {"seed": 12, "center": Vector2(560, 300)}, 4)
	client_game._rpc_ability_visual(42, 3, client_game.NET_ABILITY_TELEPORT, 2, Vector2(560, 300), Vector2(760, 300), 0.55, 0.0, {"seed": 13}, 4)
	client_game.mode = "game"
	client_game.queue_redraw()
	await process_frame
	await process_frame
	_check(client_game.net_ability_visuals.size() == 3, "Q/E/TP remote visuals failed during rendered frames")
	_check(bool(client_game.net_ability_visuals[1].get("network_replica", false)), "secondary visual did not use a local effect replica")

	var core_payload_bytes := var_to_bytes([
		host_game._pack_net_enemies(),
		host_game._pack_net_boss(),
		host_game._pack_net_enemy_bullets()
	]).size()
	var visual_payload_bytes := var_to_bytes(host_game._pack_net_boss_visuals()).size()
	_check(core_payload_bytes < 1200, "compact one-entity core snapshot exceeded expected budget")
	_check(visual_payload_bytes < 1392, "boss visual snapshot exceeded ENet MTU budget")
	print("MULTIPLAYER_NETWORK_SMOOTHING_SMOKE_OK core_bytes=%d visual_bytes=%d enemy_step=%.2f" % [core_payload_bytes, visual_payload_bytes, enemy_after_one_frame - 100.0])

	for game in [host_game, client_game]:
		game._cleanup_runtime_resources()
		game.textures.clear()
		game.audio_streams.clear()
		root.remove_child(game)
		game.free()
	for i in range(4):
		await process_frame
	quit(0)
