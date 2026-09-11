extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.is_multiplayer = true
	game.online_room_owner = false
	game._rpc_remote_player_state_light(42, Vector2(300, 300), 100, 100, false, 0, 0, 0, 0, false, 20)
	game.net_players_by_peer[42]["snapshot_ms"] = Time.get_ticks_msec() - 40
	game._rpc_remote_player_state_light(42, Vector2(312, 300), 100, 100, false, 0, 0, 0, 0, false, 20)
	assert(Vector2(game.net_players_by_peer[42]["velocity"]).x > 0.0, "real player RPC erased previous position before velocity calculation")
	game._rpc_remote_player_state_light(43, Vector2(800, 450), 100, 100, false, 2, 1, 0, 0, false, 20)
	game._sync_legacy_remote_player(42)
	game._rpc_ability_visual(43, 1, game.NET_ABILITY_SECONDARY, 2, Vector2(800, 450), Vector2(800, 450), 4.0, 0.0, {}, 20)
	game.net_players_by_peer[43]["render_pos"] = Vector2(820, 460)
	game._update_network_ability_visuals(0.01)
	assert(game.net_ability_visuals[0]["center"] == Vector2(820, 460), "third player's ultimate did not follow its owner")
	game._rpc_ability_visual(43, 1, game.NET_ABILITY_SECONDARY, 2, Vector2(800, 450), Vector2(800, 450), 4.0, 0.0, {}, 20)
	assert(game.net_ability_visuals.size() == 1, "retransmission duplicated an ability")
	game._rpc_ability_visual(43, 2, game.NET_ABILITY_TELEPORT, 2, Vector2(800, 450), Vector2(1040, 520), 0.4, 0.0, {}, 20)
	assert(game.net_players_by_peer[43]["render_pos"] == Vector2(1040, 520), "third player's teleport did not snap its own replica")
	assert(game.net_players_by_peer[42]["pos"] == Vector2(312, 300), "teleport moved the wrong ally")
	game.remote_bullets = [{"source": 43, "uid": "43:return", "pos": Vector2(700, 520), "dir": Vector2.LEFT, "speed": 100.0, "life": 3.0, "max_life": 3.0, "age": 1.0, "phase": 0.0, "trail_cd": 10.0, "kind": "retornante", "motion_mode": "returning", "state": "volta", "pierce": true, "hits": {}, "color": Color.CYAN}]
	game._update_remote_bullets(0.01)
	assert(Vector2(game.remote_bullets[0]["dir"]).x > 0.0, "third player's returning projectile homed toward the other ally")
	game._rpc_ability_visual(43, 3, game.NET_ABILITY_SECONDARY_END, 2, Vector2.ZERO, Vector2.ZERO, 0.1, 0.0, {}, 20)
	game._update_network_ability_visuals(0.01)
	assert(game.net_ability_visuals.all(func(v): return int(v["action"]) != game.NET_ABILITY_SECONDARY), "ultimate cancellation left a replica active")
	var entity: Dictionary = {}
	game.RTNetContractScript.apply_entity_motion(entity, Vector2(100, 100), 1000)
	game.RTNetContractScript.apply_entity_motion(entity, Vector2(105, 100), 1001)
	assert(Vector2(entity["_net_velocity"]).length() < 400.0, "bunched packets produced explosive extrapolation")
	game.RTNetContractScript.apply_entity_motion(entity, Vector2(900, 100), 1030)
	assert(entity["pos"] == Vector2(900, 100) and entity["_net_velocity"] == Vector2.ZERO, "teleport was extrapolated beyond its destination")
	game.dedicated_manifest_selection_by_peer = {42: {"stage": game.MANIFEST_STAGE_AURA, "manifestation": 2, "aura": 1}}
	assert(game._dedicated_manifest_duplicate_owner(43, game.MANIFEST_STAGE_AURA, 2, 3) == 42, "spectrum stage allowed duplicate manifestations")
	game.mp_manifest_start_pending = true
	game._rpc_manifest_start_rejected()
	assert(not game.mp_manifest_start_pending, "host remained stuck after a teammate cancelled ready")
	game.mode = "game"
	game.net_world_visual_last_sequence = -1
	game._update_remote_world_visuals(4, {"boss4_ultimate_timer": 9.0})
	game._update_remote_world_visuals(4, {"boss4_ultimate_timer": 18.0})
	game._update_remote_world_visuals(3, {"boss4_ultimate_timer": 19.0})
	assert(is_equal_approx(game.boss4_ultimate_timer, 9.0), "duplicate or old world visuals rewound an attack")
	print("MULTIPLAYER_COHESION_SMOKE_OK player_motion=true third_player_abilities=true dedup=true teleport=true manifest_conflict=true start_recovery=true")
	game._cleanup_runtime_resources()
	game.free()
	quit(0)
