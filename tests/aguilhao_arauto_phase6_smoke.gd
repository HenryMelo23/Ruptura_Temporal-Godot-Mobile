extends SceneTree

var game: Node


func _remote_state(pos: Vector2) -> Dictionary:
	return {
		"has_snapshot": true,
		"dead": false,
		"eliminated": false,
		"alive": true,
		"hp": 800.0,
		"hp_max": 800.0,
		"pos": pos,
		"stealthed": false,
	}


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.current_phase = 6
	game.mode = "game"
	game.phase_started_at = 0.0
	game.time_alive = game._arauto_spawn_time() + 0.1
	game.player_pos = Vector2(760, 450)
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_damage = 44.0
	game.enemy_base_hp = 46.0
	game.boss_active = true
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game.enemies.clear()
	game._try_spawn_arauto()
	assert(not game._arauto_active())

	game.boss_active = false
	game._try_spawn_arauto()
	assert(game._arauto_active())
	assert(game.arauto_spawned)
	assert(String(game.arauto.get("variant", "")) == game.ARAUTO_VARIANT_AGUILHAO)
	assert(game._count_aguilhao_nodules() == game.AGUILHAO_NODE_COUNT)
	assert(game.enemies.all(func(enemy): return bool(enemy.get("aguilhao_nodule", false)) and bool(enemy.get("skip_rewards", false))))

	game.arauto["entry_timer"] = 0.0
	var hp_before: float = float(game.arauto["hp"])
	game._damage_arauto(100.0, "smoke", false, false)
	var reduced_damage: float = hp_before - float(game.arauto["hp"])
	assert(reduced_damage >= 59.0 and reduced_damage <= 61.0)

	var first_node: Dictionary = game.enemies[0]
	game._kill_enemy(first_node)
	assert(game._count_aguilhao_nodules() == 1)
	hp_before = float(game.arauto["hp"])
	game._damage_arauto(100.0, "smoke", false, false)
	reduced_damage = hp_before - float(game.arauto["hp"])
	assert(reduced_damage >= 79.0 and reduced_damage <= 81.0)

	game.arauto["pos"] = Vector2(360, 420)
	game.player_pos = Vector2(760, 420)
	var node: Dictionary = game.enemies[0]
	node["pos"] = Vector2(470, 420)
	game.arauto["charge_dir"] = Vector2.RIGHT
	game.arauto["state"] = "charge"
	game.arauto["state_timer"] = game.AGUILHAO_CHARGE_DURATION
	game.arauto["stun"] = 0.0
	game._update_aguilhao_charge(0.25, false)
	assert(game._count_aguilhao_nodules() == 0)
	assert(float(game.arauto.get("stun", 0.0)) > 0.0)
	assert(float(game.arauto.get("aguilhao_vulnerable", 0.0)) > 0.0)

	game.arauto["stun"] = 0.0
	game.arauto["aguilhao_vulnerable"] = 0.0
	game.arauto["seed_spots"] = [{"pos": Vector2(640, 430), "peer_id": game._mp_unique_id()}, {"pos": Vector2(700, 500), "peer_id": game._mp_unique_id()}]
	game._resolve_aguilhao_seed(false)
	assert(game._count_aguilhao_threats() == game.AGUILHAO_SEED_LIMIT)
	game.arauto["seed_spots"] = [{"pos": Vector2(740, 430), "peer_id": game._mp_unique_id()}, {"pos": Vector2(780, 500), "peer_id": game._mp_unique_id()}]
	game._resolve_aguilhao_seed(false)
	assert(game._count_aguilhao_threats() == game.AGUILHAO_SEED_LIMIT)

	var hp_player_before: int = game.player_hp
	game.player_pos = Vector2(game.arauto["pos"]) + Vector2(24, 0)
	game._resolve_aguilhao_pulse(false, 0)
	assert(game.player_hp < hp_player_before)

	# Multiplayer: each ability snapshots stable peer targets instead of using only the host.
	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = true
	game.net_players_by_peer = {
		42: _remote_state(Vector2(620, 330)),
		43: _remote_state(Vector2(910, 520)),
	}
	game.arauto_target_cursor = -1
	game.arauto["seed_spots"] = []
	for enemy in game.enemies:
		if bool(enemy.get("aguilhao_spawned", false)):
			enemy["hp"] = 0.0
	game._start_aguilhao_seed(false)
	var seed_peers: Array = Array(game.arauto.get("seed_spots", [])).map(func(value): return int(Dictionary(value).get("peer_id", -1)))
	assert(seed_peers.size() == 2)
	assert(seed_peers[0] != seed_peers[1])
	game._start_aguilhao_pulse()
	var pulse_targets: Array = Array(game.arauto.get("pulse_targets", []))
	assert(pulse_targets.size() == 3)
	var pulse_peers: Dictionary = {}
	for target_value in pulse_targets:
		pulse_peers[int(Dictionary(target_value).get("peer_id", -1))] = true
	assert(pulse_peers.size() == 3)
	var replica: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(replica)
	replica.set_process(false)
	replica.current_phase = 6
	replica.is_multiplayer = true
	replica.is_host = false
	replica.online_room_owner = false
	replica._apply_remote_boss_visual_snapshot(game._pack_net_boss_visuals())
	var replica_pulse_targets: Array = Array(replica.arauto.get("pulse_targets", []))
	assert(String(replica.arauto.get("state", "")) == "pulse")
	assert(replica_pulse_targets.size() == pulse_targets.size())
	assert(replica_pulse_targets == pulse_targets)
	replica._cleanup_runtime_resources()
	replica.textures.clear()
	replica.audio_streams.clear()
	root.remove_child(replica)
	replica.free()
	game.arauto["charge_hit_peers"] = {"peer_42": true}
	game._start_aguilhao_charge(true)
	var first_charge_peer: int = int(game.arauto.get("charge_target_peer", -1))
	assert(Dictionary(game.arauto.get("charge_hit_peers", {})).is_empty())
	game._finish_aguilhao_charge(true, 0.55)
	assert(int(game.arauto.get("charge_leg", 0)) == 2)
	assert(int(game.arauto.get("charge_target_peer", -1)) != first_charge_peer)
	assert(Dictionary(game.arauto.get("charge_hit_peers", {})).is_empty())
	game.is_multiplayer = false
	game.is_host = false
	game.online_room_owner = false
	game.net_players_by_peer.clear()

	game.arauto["state"] = "idle"
	game.arauto["stun"] = 0.0
	game.arauto["hp"] = float(game.arauto["max_hp"]) * 0.49
	game._update_aguilhao_arauto(0.05)
	assert(bool(game.arauto.get("phase2", false)))
	assert(String(game.arauto.get("state", "")) == "phase2_transition")

	game.arauto["hp"] = 1.0
	game._damage_arauto(99999.0, "smoke", false, false)
	assert(not game._arauto_active())
	assert(game.arauto_card_drops.size() == game.ARAUTO_CARD_REWARD_COUNT)
	assert(not game.arauto_evolution_fragment.is_empty())
	assert(game.enemies.all(func(enemy): return not bool(enemy.get("aguilhao_nodule", false)) and not bool(enemy.get("aguilhao_spawned", false))))

	print("AGUILHAO_ARAUTO_PHASE6_SMOKE_OK spawn=8min nodes=2 reduction=40 charge_chain=true seed_distribution=true pulse_targets=true replica_sync=true rewards=true")
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for i in range(4):
		await process_frame
	quit(0)
