extends SceneTree

## Round-trip proof for gameplay added while multiplayer validation was frozen.
## The host owns simulation; the client receives only public visual/buff state.

var host: Node
var client: Node


func _initialize() -> void:
	host = load("res://scenes/Main.tscn").instantiate()
	client = load("res://scenes/Main.tscn").instantiate()
	root.add_child(host)
	root.add_child(client)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("MULTIPLAYER_NEW_FEATURE_VISUAL_SYNC_FAIL " + message)
	quit(1)


func _setup(game: Node, authority: bool) -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = true
	game.online_connected = false
	game.is_host = authority
	game.online_room_owner = authority


func _round_trip(phase: int) -> Dictionary:
	host.current_phase = phase
	client.current_phase = phase
	var packet: Dictionary = host._pack_net_boss_visuals()
	client._apply_remote_boss_visual_snapshot(packet)
	return packet


func _run() -> void:
	_setup(host, true)
	_setup(client, false)

	# Arauto warnings used to exist only in the host process.
	host._arauto_threat().ability = {"kind": "hush", "age": 0.7, "safes": [Vector2(300, 400)]}
	host._arauto_threat().inversion = {"pos": Vector2(520, 430), "age": 1.2, "pulled": false}
	host._arauto_threat().stings = [{"pos": Vector2(600, 440), "dir": Vector2.LEFT, "life": 1.4}]
	var p1: Dictionary = _round_trip(1)
	_check(p1.has("arauto_threat"), "packet omitted Arauto public state")
	_check(String(client._arauto_threat().ability.get("kind", "")) == "hush", "client missed Arauto warning")
	_check(client._arauto_threat().stings.size() == 1, "client missed Arauto sting")

	# Boss 2 movement warnings/trail are visual; boss position remains in boss_core.
	host._boss2_motion().dash = {"from": Vector2(300, 300), "to": Vector2(700, 440), "t": -0.2}
	host._boss2_motion().sliding = true
	host._boss2_motion().trail = [{"pos": Vector2(420, 410), "t": 10.0}]
	var p2: Dictionary = _round_trip(2)
	_check(p2.has("boss2_motion"), "packet omitted Boss 2 motion visuals")
	_check(client._boss2_motion().sliding, "client missed Boss 2 slide")
	_check(client._boss2_motion().trail.size() == 1, "client missed Boss 2 trail")

	# Suturador telegraphs and Matriarch burrow state now survive the wire.
	host.boss6_ai_state = {"mode": "burrow", "emerge_at": Vector2(880, 510), "facing": -1.0, "step": 0.42}
	host.amber_suturer_controller.threat().stitch = {"age": 0.4, "targets": [{"pos": Vector2(760, 450), "type": "common"}]}
	host.amber_suturer_controller.threat().cocoon = {"uid": 77, "pos": Vector2(810, 470), "age": 2.0}
	host.amber_suturer_controller.threat().tethers = [Vector2(700, 400), Vector2(900, 500)]
	var p6: Dictionary = _round_trip(6)
	_check(p6.has("boss6_ai_state") and p6.has("suturer_threat"), "phase 6 packet omitted new states")
	_check(String(client.boss6_ai_state.get("mode", "")) == "burrow", "client missed Boss 6 burrow")
	_check(client.amber_suturer_controller.threat().tethers.size() == 2, "client missed Suturer links")
	_check(not client.amber_suturer_controller.threat().cocoon.is_empty(), "client missed Suturer cocoon")

	# Phoenix altitude, shadow, trail and velocity drive the same animation on peers.
	host.boss7_state = RTBoss7MotionController.STATE_SWOOP_WARN
	host.boss7_velocity = Vector2(210, -35)
	host.boss7_attack_dir = Vector2.RIGHT
	host._boss7_motion().bank = 0.65
	host._boss7_motion().altitude = 0.8
	host._boss7_motion().shadow_pos = Vector2(960, 520)
	host._boss7_motion().trail.assign([Vector2(900, 500), Vector2(880, 490)])
	host._boss7_motion().swoop = {"from": Vector2(820, 450), "to": Vector2(1100, 520), "t": 0.1}
	var p7: Dictionary = _round_trip(7)
	_check(p7.has("boss7_motion"), "packet omitted Boss 7 motion visuals")
	_check(is_equal_approx(client._boss7_motion().altitude, 0.8), "client missed Boss 7 altitude")
	_check(client._boss7_motion().trail.size() == 2, "client missed Boss 7 trail")
	_check(client.boss7_velocity.distance_to(Vector2(210, -35)) < 0.01, "client missed Boss 7 velocity")

	# Field Fury is deliberately a team buff in multiplayer; Magnet keeps its
	# collector peer so only that player's drops are attracted.
	host._field_artifacts().activate(RTFieldArtifactController.TYPE_FURY, 2, Vector2.ZERO, true)
	host._field_artifacts().activate(RTFieldArtifactController.TYPE_MAGNET, 2, Vector2.ZERO, true)
	_round_trip(7)
	_check(is_equal_approx(client._field_artifacts().damage_multiplier(), RTFieldArtifactController.FURY_MULTIPLIER), "team Fury did not replicate")
	_check(client._field_artifacts().magnet_peer_id == 2, "Magnet collector ownership was lost")

	print("MULTIPLAYER_NEW_FEATURE_VISUAL_SYNC_OK arauto=true boss2=true suturer=true boss6=true boss7=true artifacts=team_fury_owned_magnet")
	_cleanup(client)
	_cleanup(host)
	client = null
	host = null
	for frame in range(4):
		await process_frame
	quit(0)


func _cleanup(game: Node) -> void:
	if game == null or not is_instance_valid(game):
		return
	root.remove_child(game)
	game._cleanup_runtime_resources()
	game.free()
