extends SceneTree

const Transport = preload("res://scripts/systems/online/transport_state.gd")

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for i in range(120):
		game.enemies.append({"uid": 1000 + i, "type": game.ENEMY_COMMON, "pos": Vector2(i * 8, i * 3), "hp": 180.0, "max_hp": 180.0})
	for i in range(80):
		game.enemy_bullets.append({"pos": Vector2(i * 6, 350), "dir": Vector2.RIGHT, "life": 3.0, "damage": 20.0})
	var packet: PackedByteArray = var_to_bytes([game._pack_net_enemies(), game._pack_net_boss(), game._pack_net_enemy_bullets()])
	var plain: int = await _measure(packet, false)
	var compressed: int = await _measure(packet, true)
	assert(plain > 0 and compressed > 0 and compressed < plain, "compression did not reduce actual ENet traffic")
	print("MULTIPLAYER_TRANSPORT_WIRE_OK snapshots=20 payload_bytes=%d plain_udp_bytes=%d fastlz_udp_bytes=%d reduction_pct=%.1f" % [packet.size(), plain, compressed, 100.0 * (1.0 - float(compressed) / plain)])
	game._cleanup_runtime_resources()
	game.free()
	quit(0)


func _measure(packet: PackedByteArray, compressed: bool) -> int:
	var receiver := ENetConnection.new()
	var sender := ENetConnection.new()
	assert(receiver.create_host_bound("127.0.0.1", 0, 1, 5) == OK)
	assert(sender.create_host(1, 5) == OK)
	if compressed:
		Transport.configure_connection(receiver)
		Transport.configure_connection(sender)
	else:
		receiver.compress(ENetConnection.COMPRESS_NONE)
		sender.compress(ENetConnection.COMPRESS_NONE)
	var peer := sender.connect_to_host("127.0.0.1", receiver.get_local_port(), 5)
	var connected := false
	var deadline := Time.get_ticks_msec() + 4000
	while not connected and Time.get_ticks_msec() < deadline:
		var event := sender.service(0)
		connected = event[0] == ENetConnection.EVENT_CONNECT
		receiver.service(0)
		await process_frame
	assert(connected, "ENet wire benchmark could not connect")
	sender.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA)
	for sample in range(20):
		assert(peer.send(2, packet, ENetPacketPeer.FLAG_RELIABLE) == OK)
		sender.flush()
		var received := false
		deadline = Time.get_ticks_msec() + 4000
		while not received and Time.get_ticks_msec() < deadline:
			sender.service(0)
			var event := receiver.service(0)
			if event[0] == ENetConnection.EVENT_RECEIVE:
				var remote: ENetPacketPeer = event[1]
				assert(remote.get_packet() == packet, "compressed snapshot changed bytes in transit")
				received = true
			await process_frame
		assert(received, "ENet wire benchmark lost snapshot %d" % sample)
	var bytes: int = int(sender.pop_statistic(ENetConnection.HOST_TOTAL_SENT_DATA))
	sender.destroy()
	receiver.destroy()
	return bytes
