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
	var now_ms: int = Time.get_ticks_msec()
	game.is_multiplayer = true
	game.online_connected = true
	game.mode = "game"
	game.net_transport_last_activity_ms = now_ms
	game._update_network_transport_health(now_ms)
	_check(game.net_transport_health == "ok", "active transport was not healthy")
	game._update_network_transport_health(now_ms + game.NET_TRANSPORT_DEGRADED_AFTER_MS)
	_check(game.net_transport_health == "degraded", "transport degradation was not detected")
	game._update_network_transport_health(now_ms + game.NET_TRANSPORT_STALLED_AFTER_MS)
	_check(game.net_transport_health == "stalled", "transport stall was not detected")
	print("MULTIPLAYER_TRANSPORT_SMOKE_OK adaptive=true health=ok,degraded,stalled")
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
