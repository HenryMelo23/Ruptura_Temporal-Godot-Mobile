extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	_check(game._net_player_sync_interval_ms() == game.NET_PLAYER_SYNC_INTERVAL_MS, "healthy transport changed player cadence")
	_check(game._net_world_sync_interval_ms() == game.NET_WORLD_SYNC_INTERVAL_MS, "healthy transport changed world cadence")
	game.net_ping_ms = 240
	_check(game._net_player_sync_interval_ms() == game.NET_PLAYER_SYNC_INTERVAL_MS, "stable distant connection was penalized with extra input delay")
	var timing := Vector2.ZERO
	for _sample in range(60):
		timing = game.RTTransportStateScript.arrival_timing(67.0, timing.x, timing.y)
	_check(is_zero_approx(timing.y), "steady bandwidth-paced snapshots were mistaken for jitter")
	timing = game.RTTransportStateScript.arrival_timing(140.0, timing.x, timing.y)
	_check(timing.y > 0.0, "variable packet arrival was not detected")
	game.net_ping_ms = 120
	game.net_world_jitter_ms = 40.0
	_check(game._net_player_sync_interval_ms() > game.NET_PLAYER_SYNC_INTERVAL_MS, "high RTT did not reduce player packet pressure")
	_check(game._net_world_sync_interval_ms() > game.NET_WORLD_SYNC_INTERVAL_MS, "high RTT did not reduce world packet pressure")
	_check(game._net_world_payload_bytes() < 200, "empty world snapshot should stay compact")
	_check(game.RTTransportStateScript.budget_interval_ms(19864, game.NET_WORLD_BUDGET_BYTES_PER_SEC, game.NET_WORLD_SYNC_INTERVAL_MS) >= 66, "large snapshots were not paced by payload budget")
	for _index in range(120):
		game.enemies.append({})
	for _index in range(80):
		game.enemy_bullets.append({})
	_check(game._net_world_payload_bytes() >= 19800, "large world payload estimate was unexpectedly small")
	_check(game._net_world_sync_interval_ms() >= 66, "large world payload was still scheduled at the base cadence")
	var packed_enemies: PackedFloat32Array = game._pack_net_enemies()
	var packed_boss: PackedFloat32Array = game._pack_net_boss()
	var packed_bullets: PackedFloat32Array = game._pack_net_enemy_bullets()
	var encoded_world: PackedByteArray = game.RTWorldSnapshotChunkerScript.encode(packed_enemies, packed_boss, packed_bullets)
	var world_chunks: Array = game.RTWorldSnapshotChunkerScript.split(encoded_world, game.NET_WORLD_CHUNK_PAYLOAD_BYTES)
	_check(world_chunks.size() > 1, "oversized world snapshot was not fragmented")
	for chunk_index in range(world_chunks.size()):
		var chunk: PackedByteArray = world_chunks[chunk_index]
		_check(chunk.size() <= game.NET_WORLD_CHUNK_PAYLOAD_BYTES, "world chunk exceeded the safe payload limit")
		_check(var_to_bytes([1, chunk_index, world_chunks.size(), chunk]).size() < 1392, "serialized world chunk exceeded ENet MTU")
	var chunks_by_index: Dictionary = {}
	for chunk_index in range(world_chunks.size() - 1, -1, -1):
		chunks_by_index[chunk_index] = world_chunks[chunk_index]
	var rebuilt_world: PackedByteArray = game.RTWorldSnapshotChunkerScript.join(chunks_by_index, world_chunks.size(), game.NET_WORLD_CHUNK_MAX_COUNT)
	_check(rebuilt_world == encoded_world, "world chunks did not reassemble losslessly")
	var decoded_world: Array = game.RTWorldSnapshotChunkerScript.decode(rebuilt_world)
	_check(decoded_world.size() == 3, "reassembled world snapshot did not decode")
	_check(decoded_world[0] == packed_enemies and decoded_world[1] == packed_boss and decoded_world[2] == packed_bullets, "fragmentation changed world snapshot data")
	chunks_by_index.erase(0)
	_check(game.RTWorldSnapshotChunkerScript.join(chunks_by_index, world_chunks.size(), game.NET_WORLD_CHUNK_MAX_COUNT).is_empty(), "incomplete world snapshot was accepted")
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.is_multiplayer = true
	game.online_connected = true
	game.is_host = false
	game.online_room_owner = false
	game.net_world_last_sequence = -1
	for chunk_index in range(1, world_chunks.size()):
		game._update_remote_entities_chunk(77, chunk_index, world_chunks.size(), world_chunks[chunk_index])
	_check(game.net_world_last_sequence == -1 and game.enemies.is_empty(), "partial world snapshot was applied to the replica")
	game._update_remote_entities_chunk(77, 1, world_chunks.size(), world_chunks[1])
	_check(game.net_world_pending_chunks.size() == world_chunks.size() - 1, "duplicate chunk changed pending snapshot cardinality")
	game._update_remote_entities_chunk(77, 0, world_chunks.size(), world_chunks[0])
	_check(game.net_world_last_sequence == 77, "complete world snapshot was not committed atomically")
	_check(game.enemies.size() == 120 and game.enemy_bullets.size() == 80, "replica did not restore every fragmented entity")
	var now_ms: int = Time.get_ticks_msec()
	game.mode = "game"
	game.net_transport_last_activity_ms = now_ms
	game._update_network_transport_health(now_ms)
	_check(game.net_transport_health == "ok", "active transport was not healthy")
	game._update_network_transport_health(now_ms + game.NET_TRANSPORT_DEGRADED_AFTER_MS)
	_check(game.net_transport_health == "degraded", "transport degradation was not detected")
	game._update_network_transport_health(now_ms + game.NET_TRANSPORT_STALLED_AFTER_MS)
	_check(game.net_transport_health == "stalled", "transport stall was not detected")
	print("MULTIPLAYER_TRANSPORT_SMOKE_OK adaptive=true mtu_chunks=%d lossless=true health=ok,degraded,stalled" % world_chunks.size())
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	for _frame in range(4):
		await process_frame
	quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
