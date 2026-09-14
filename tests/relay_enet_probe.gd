extends SceneTree

var peer := ENetMultiplayerPeer.new()
var started_ms := 0
var compression := "none"


func _initialize() -> void:
	var host := "127.0.0.1"
	var port := 4591
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--host="):
			host = arg.trim_prefix("--host=")
		elif arg.begins_with("--port="):
			port = int(arg.trim_prefix("--port="))
		elif arg.begins_with("--compression="):
			compression = arg.trim_prefix("--compression=")
	if compression not in ["fastlz", "none"]:
		quit(2)
		return
	var error := peer.create_client(host, port, 4)
	if error != OK:
		print("RELAY_ENET_PROBE_FAIL create_client=", error)
		quit(1)
		return
	peer.host.compress(ENetConnection.COMPRESS_FASTLZ if compression == "fastlz" else ENetConnection.COMPRESS_NONE)
	started_ms = Time.get_ticks_msec()
	print("RELAY_ENET_PROBE_START host=%s port=%d compression=%s" % [host, port, compression])


func _process(_delta: float) -> bool:
	peer.poll()
	var elapsed := Time.get_ticks_msec() - started_ms
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		print("RELAY_ENET_PROBE_OK handshake_ms=%d compression=%s" % [elapsed, compression])
		peer.close()
		quit(0)
	elif elapsed >= 12000 or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		print("RELAY_ENET_PROBE_FAIL elapsed_ms=%d compression=%s status=%d" % [elapsed, compression, peer.get_connection_status()])
		peer.close()
		quit(1)
	return false
