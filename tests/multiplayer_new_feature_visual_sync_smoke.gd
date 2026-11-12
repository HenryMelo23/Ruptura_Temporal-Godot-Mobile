extends SceneTree

## Round-trip proof for gameplay added while multiplayer validation was frozen.
## The host owns simulation; the client receives only public visual/buff state.

var host: Node
var client: Node
var client_two: Node


func _initialize() -> void:
	host = load("res://scenes/Main.tscn").instantiate()
	client = load("res://scenes/Main.tscn").instantiate()
	client_two = load("res://scenes/Main.tscn").instantiate()
	root.add_child(host)
	root.add_child(client)
	root.add_child(client_two)
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
	_setup(client_two, false)

	# Arauto warnings used to exist only in the host process.
	host._arauto_threat().ability = {"kind": "hush", "age": 0.7, "safes": [Vector2(300, 400)]}
	host._arauto_threat().inversion = {"pos": Vector2(520, 430), "age": 1.2, "pulled": false}
	host._arauto_threat().stings = [{"pos": Vector2(600, 440), "dir": Vector2.LEFT, "life": 1.4}]
	var p1: Dictionary = _round_trip(1)
	_check(p1.has("arauto_threat"), "packet omitted Arauto public state")
	_check(String(client._arauto_threat().ability.get("kind", "")) == "hush", "client missed Arauto warning")
	_check(client._arauto_threat().stings.size() == 1, "client missed Arauto sting")
	var hostile_peer: int = client._mp_unique_id()
	_check(client._arauto_threat().apply_remote_hostile_event(hostile_peer, "hush:1", 1, 0, "silence", 2.4, 0, Vector2.ZERO), "client rejected authoritative Arauto silence")
	_check(client.player_silence_timer > 0.0, "client did not apply Arauto silence")
	_check(not client._arauto_threat().apply_remote_hostile_event(hostile_peer, "hush:1", 1, 0, "silence", 2.4, 0, Vector2.ZERO), "client replayed duplicate Arauto status")
	client.player_pos = Vector2(480, 360)
	_check(client._arauto_threat().apply_remote_hostile_event(hostile_peer, "invert:2", 1, 0, "inversion", 1.0, 0, Vector2(620, 360)), "client rejected authoritative Arauto inversion")
	_check(client.player_shove.remaining.length() > 0.0, "client missed Arauto inversion pull")
	_check(client._arauto_threat().apply_remote_hostile_event(hostile_peer, "venom:3", 1, 0, "venom", 4.0, 2, Vector2.ZERO), "client rejected authoritative Arauto venom")
	_check(client._arauto_threat().venom_stacks.size() == 2, "client missed Arauto venom stacks")

	# Boss 2 movement warnings/trail are visual; boss position remains in boss_core.
	host._boss2_motion().dash = {"from": Vector2(300, 300), "to": Vector2(700, 440), "t": -0.2}
	host._boss2_motion().sliding = true
	host._boss2_motion().trail = [{"pos": Vector2(420, 410), "t": 10.0}]
	var p2: Dictionary = _round_trip(2)
	_check(p2.has("boss2_motion"), "packet omitted Boss 2 motion visuals")
	_check(client._boss2_motion().sliding, "client missed Boss 2 slide")
	_check(client._boss2_motion().trail.size() == 1, "client missed Boss 2 trail")
	client.player_frost_stacks = 1 # The replicated hit itself already added the first stack.
	client.player_ice_slip_timer = 0.0
	client._rpc_apply_hostile_status("frost_slip_1", 2.6)
	_check(client.player_frost_stacks == 2, "client missed the remaining Sineiro frost stack")
	_check(is_equal_approx(client.player_ice_slip_timer, 2.6), "client missed the Sineiro ice floor")
	client._rpc_apply_hostile_status("ice_slip", 3.2)
	_check(is_equal_approx(client.player_ice_slip_timer, 3.2), "client did not extend the Sineiro ring slip")

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
	client.player_hp = client.player_hp_max
	client.boss6_heal_cut_timer = 0.0
	client._damage_player(10, "boss6_chasing_crack", true)
	_check(client.boss6_heal_cut_timer > 0.0, "replicated Boss 6 damage did not apply local heal cut")

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

	# Henry Incendiario transports compact public state; both clients derive VFX.
	host.active_character_key = host.CHARACTER_HENRY
	host.selected_manifestation = host.HENRY_SELECTION_INDEX
	host.mutation_key = "incendiario"
	host.manifestation_key = "incendiario"
	host.player_pos = Vector2(640.0, 420.0)
	host.last_facing = Vector2.RIGHT
	var source_peer := 77
	var sequence := 1
	_check(host.henry_incendiary_ability_controller.begin_spin_dash(host.player_pos + Vector2(280.0, 0.0)), "host dash did not begin")
	var dash_payload: Dictionary = host._network_ability_payload(host.NET_ABILITY_TELEPORT, host.player_pos, host.henry_spin_dash_target)
	var dash_bytes: int = host.RTVisualSyncContractScript.ability_event_bytes([source_peer, sequence, host.NET_ABILITY_TELEPORT, host.HENRY_SELECTION_INDEX, host.player_pos, host.henry_spin_dash_target, host.HENRY_SPIN_DURATION + host.henry_incendiary_ability_controller.TRAIL_LIFE, host.HENRY_SPIN_DURATION, dash_payload, 0])
	_check(dash_bytes <= 1392, "Incendiario public event exceeded ENet MTU budget: %d" % dash_bytes)
	for replica in [client, client_two]:
		replica._rpc_ability_visual(source_peer, sequence, host.NET_ABILITY_TELEPORT, host.HENRY_SELECTION_INDEX, host.player_pos, host.henry_spin_dash_target, host.HENRY_SPIN_DURATION + host.henry_incendiary_ability_controller.TRAIL_LIFE, host.HENRY_SPIN_DURATION, dash_payload, 0)
		_check(replica.net_ability_visuals.size() == 1, "trio replica missed Incendiario dash event")
		var remote_state: Dictionary = Dictionary(replica.net_ability_visuals[0].get("canonical_state", {})).get("incendiary", {})
		_check(bool(Dictionary(remote_state.get("spin", {})).get("active", false)), "remote dash omitted current state")
		_check(Array(remote_state.get("trail", [])).size() == 1, "remote dash omitted ember trail")
	host.henry_incendiary_ability_controller.update(0.32)
	var dash_patch: Dictionary = host.RTVisualSyncContractScript.sanitize_ability_payload({
		"schema": host.RTVisualSyncContractScript.ABILITY_VISUAL_SCHEMA,
		"manifestation_key": "incendiario",
		"canonical_state": host.RTManifestationVisualSnapshotScript.capture(host, host.NET_ABILITY_TELEPORT, "incendiario")
	})
	for replica in [client, client_two]:
		replica._rpc_ability_visual_patch(source_peer, sequence, 0.32, dash_patch)
		var patched: Dictionary = Dictionary(replica.net_ability_visuals[0].get("canonical_state", {})).get("incendiary", {})
		_check(Array(patched.get("trail", [])).size() > 1, "remote dash progress did not extend ember trail")

	sequence += 1
	host.henry_incendiary_ability_controller.update(host.HENRY_SPIN_DURATION)
	host.henry_incendiary_ability_controller.reset()
	host.henry_entry_timer = 0.0
	host.player_start_down_fall_timer = 0.0
	host.player_start_down_landing_timer = 0.0
	_check(host.henry_incendiary_ability_controller.begin_skill(host.player_pos + Vector2.RIGHT * 300.0), "host channel did not begin")
	var skill_payload: Dictionary = host._network_ability_payload(host.NET_ABILITY_SKILL, host.player_pos, host.player_pos + Vector2.RIGHT * 300.0)
	for replica in [client, client_two]:
		replica._rpc_ability_visual(source_peer, sequence, host.NET_ABILITY_SKILL, host.HENRY_SELECTION_INDEX, host.player_pos, host.player_pos + Vector2.RIGHT * 300.0, host.HENRY_SKILL_CAST_DURATION, 0.0, skill_payload, 0)
	host.henry_incendiary_ability_controller.cancel_channel()
	var end_payload: Dictionary = host._network_ability_payload(host.NET_ABILITY_SECONDARY_END, host.player_pos, host.player_pos)
	sequence += 1
	for replica in [client, client_two]:
		replica._rpc_ability_visual(source_peer, sequence, host.NET_ABILITY_SECONDARY_END, host.HENRY_SELECTION_INDEX, host.player_pos, host.player_pos, 0.08, float(host.NET_ABILITY_SKILL), end_payload, 0)
		_check(float(replica.net_ability_visuals[-1].get("life", 1.0)) <= 0.0, "remote cancel did not stop the skill immediately")
	# Duplicate cancellation and a fresh peer state are both harmless.
	sequence += 1
	client._rpc_ability_visual(source_peer, sequence, host.NET_ABILITY_SECONDARY_END, host.HENRY_SELECTION_INDEX, host.player_pos, host.player_pos, 0.08, float(host.NET_ABILITY_SKILL), end_payload, 0)
	client_two.net_ability_seen.clear()
	client_two.net_ability_visuals.clear()
	client_two._rpc_ability_visual(source_peer, sequence, host.NET_ABILITY_SECONDARY_END, host.HENRY_SELECTION_INDEX, host.player_pos, host.player_pos, 0.08, float(host.NET_ABILITY_SKILL), end_payload, 0)
	_check(client_two.net_ability_visuals.is_empty(), "reconnected replica revived a cancelled channel")

	print("MULTIPLAYER_NEW_FEATURE_VISUAL_SYNC_OK arauto=visual_silence_venom_inversion boss2=motion_frost_slip suturer=true boss6=visual_heal_cut boss7=true artifacts=team_fury_owned_magnet henry_incendiario=duo_trio_progress_cancel reconnect_clean=true dash_packet_bytes=%d" % dash_bytes)
	_cleanup(client_two)
	_cleanup(client)
	_cleanup(host)
	client_two = null
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
