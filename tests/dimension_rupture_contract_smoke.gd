extends SceneTree
## Contrato multiplayer do Fragmento Instável sem rede: host autoritativo e
## réplicas (duo/trio) trocando apenas o snapshot compacto em processo único.
## Não substitui a validação real (ver .agents/MULTIPLAYER_DEFERRED_VALIDATION.md).
## godot4 --headless --path . --script tests/dimension_rupture_contract_smoke.gd

const R := preload("res://scripts/systems/phase/dimension_rupture_controller.gd")

var failures: Array[String] = []


class FakeMerchant:
	extends RefCounted
	var active := false


class FakeCore:
	extends Node
	const DIMENSION_FINAL_PHASE := 5
	const DIMENSION_FARM_ENTRY_PHASE := 7
	var authority := true
	var is_multiplayer := true
	var experimental_phase_active := false
	var current_phase := 3
	var mode := "game"
	var phase_fragment: Dictionary = {}
	var dimension_route_queue: Array = [6, 8]
	var boss_active := false
	var boss_entry_timer := 0.0
	var time_alive := 500.0
	var player_pos := Vector2(100, 100)
	var player_hp := 100.0
	var player_hp_max := 100.0
	var is_dead := false
	var event_alert_text := ""
	var event_alert_timer := 0.0
	var gfx_screen_shake := false
	var screen_shake_timer := 0.0
	var screen_shake_strength := 0.0
	var commits: Array = []
	var rupture: RTDimensionRuptureController
	var merchant := FakeMerchant.new()

	func _is_world_authority() -> bool:
		return authority or not is_multiplayer

	func _is_world_replica() -> bool:
		return is_multiplayer and not authority

	func _tutorial_active() -> bool:
		return false

	func _merchant_dimension() -> FakeMerchant:
		return merchant

	func _shop_rpc_available() -> bool:
		return false

	func _spawn_radial_particles(_pos: Vector2, _color: Color, _count: int) -> void:
		pass

	func _dimension_rupture() -> RTDimensionRuptureController:
		return rupture

	## Espelha `RTPhaseFlowController._commit_phase_mp_transfer`.
	func _commit_phase_mp_transfer(target: int, action: String) -> void:
		if not rupture.on_group_transfer_committed(target, action):
			return
		phase_fragment.clear()
		commits.append([target, action])
		rupture.on_transition_started(target)
		mode = "phase_transition"

	func arrive(phase: int) -> void:
		current_phase = phase
		phase_fragment.clear()
		rupture.on_phase_entered(phase)
		mode = "game"


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _make(is_host: bool) -> FakeCore:
	var core := FakeCore.new()
	core.authority = is_host
	core.rupture = RTDimensionRuptureController.new()
	core.rupture.configure(core)
	core.rupture.reset_for_new_run()
	root.add_child(core)
	return core


func _open_portal(core: FakeCore, next_phase: int = 4) -> void:
	core.phase_fragment = {"pos": Vector2(900, 700), "next_phase": next_phase}


func _sync(host: FakeCore, replicas: Array) -> Dictionary:
	var snap := host.rupture.public_snapshot()
	# Ida e volta pelo serializador do Godot, como o pacote de mundo.
	snap = bytes_to_var(var_to_bytes(snap))
	for replica in replicas:
		replica.rupture.apply_remote_snapshot(snap)
	return snap


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_authority_only_host()
	_test_duplicate_and_late_packets()
	_test_same_destination_duo_trio()
	_test_roster()
	_test_reconnect()
	_test_token_once_for_group()
	_test_snapshot_compact()
	_test_ejection_idempotent_on_replica()
	_test_new_run_and_epoch_drop()
	if failures.is_empty():
		print("DIMENSION_RUPTURE_CONTRACT_SMOKE_OK")
		quit(0)
	else:
		for f in failures:
			printerr("DIMENSION_RUPTURE_CONTRACT_SMOKE_FAIL " + f)
		quit(1)


func _test_authority_only_host() -> void:
	var host := _make(true)
	var client := _make(false)
	_open_portal(client)
	_check(not client.rupture.activate(R.SOURCE_OBJECTIVE, 3), "replica activated fragment")
	_open_portal(host)
	_check(host.rupture.activate(R.SOURCE_OBJECTIVE, 3), "host failed to activate")
	_sync(host, [client])
	client.rupture.advance_clock(100.0)
	_check(is_equal_approx(float(client.rupture.state["elapsed"]), 0.0), "replica advanced authoritative clock")
	_check(client.rupture.resolve_crossing() == R.BAND_NONE, "replica resolved crossing")
	_check(not client.rupture.eject(), "replica ejected")
	client.rupture.state["token"] = {"event_id": "t", "tier": "perfect", "attempts": 3}
	var card := {"id": "x"}
	_check(client.rupture.apply_quality_token(card, 2, {}) == card and not client.rupture.pending_token().is_empty(), "replica consumed token")
	# Menus individuais não pausam o relógio do host em multiplayer.
	host.mode = "manifest_mp"
	host.rupture.update(5.0)
	_check(is_equal_approx(float(host.rupture.state["elapsed"]), 5.0), "MP menu paused authoritative clock")
	host.mode = "phase_transition"
	host.rupture.update(5.0)
	_check(is_equal_approx(float(host.rupture.state["elapsed"]), 5.0), "transition advanced MP clock")
	host.queue_free()
	client.queue_free()


func _test_duplicate_and_late_packets() -> void:
	var host := _make(true)
	var client := _make(false)
	_open_portal(host)
	host.rupture.activate(R.SOURCE_OBJECTIVE, 3)
	var old := _sync(host, [client])
	host.rupture.advance_clock(70.0)
	var newer := _sync(host, [client])
	_check(not client.rupture.apply_remote_snapshot(newer), "duplicate packet re-applied")
	_check(not client.rupture.apply_remote_snapshot(old), "late packet (older rev) applied")
	_check(is_equal_approx(float(client.rupture.state["elapsed"]), 70.0), "late packet rewound clock")
	host.queue_free()
	client.queue_free()


func _test_same_destination_duo_trio() -> void:
	var host := _make(true)
	var a := _make(false)
	var b := _make(false)
	_open_portal(host)
	host.dimension_route_queue = [6, 8, 2, 9]
	host.rupture.activate(R.SOURCE_OBJECTIVE, 3)
	host.rupture.advance_clock(180.0)
	_check(host.rupture.current_state() == R.STATE_EMERGENCY, "host not in emergency")
	_sync(host, [a, b])
	var dst := int(host.rupture.state["eject_target"])
	_check(dst > 0 and dst != 3 and dst != 5, "invalid host destination %d" % dst)
	_check(int(a.rupture.state["eject_target"]) == dst and int(b.rupture.state["eject_target"]) == dst, "duo/trio disagree on destination")
	# Determinismo: mesmo event_id + run => mesmo destino em qualquer peer.
	var c := R.ejection_candidates(3, 4, [6, 8, 2, 9], 5)
	_check(not c.has(4), "normal next offered while alternatives exist")
	_check(R.ejection_candidates(3, 4, [3, 5], 5) == [4], "no-alternative fallback to normal next")
	_check(R.pick_deterministic(c, String(host.rupture.state["event_id"]), String(host.rupture.state["run_id"])) == dst, "destination not derived from event/run seed")
	host.queue_free()
	a.queue_free()
	b.queue_free()


func _test_roster() -> void:
	var roster := R.group_transfer_roster([
		{"peer_id": 1, "alive": true},
		{"peer_id": 2, "downed": true},
		{"peer_id": 3, "alive": false},
		{"peer_id": 4, "spectator": true},
		{"peer_id": 5, "connected": false},
	])
	_check(roster["moving"] == [1], "moving set")
	_check(roster["carried"] == [2, 3], "downed/dead should be carried, not block")
	_check(roster["spectators"] == [4], "spectator stays spectator")
	_check(roster["expected"] == [1], "disconnect/downed must leave expected set")


func _test_reconnect() -> void:
	var host := _make(true)
	_open_portal(host)
	host.rupture.activate(R.SOURCE_OBJECTIVE, 3)
	host.rupture.advance_clock(42.0)
	host.rupture.state["momentum"] = 2
	host.rupture.state["disorientation"] = 7.0
	var late := _make(false) # run_id aleatório diferente: peer reconectando
	_sync(host, [late])
	_check(is_equal_approx(late.rupture.remaining_seconds(), host.rupture.remaining_seconds()), "reconnect remaining time mismatch")
	_check(late.rupture.momentum() == 2 and is_equal_approx(late.rupture.disorientation_remaining(), 7.0), "reconnect lost momentum/disorientation")
	_check(String(late.rupture.state["event_id"]) == String(host.rupture.state["event_id"]), "reconnect event mismatch")
	_check(is_equal_approx(float(host.rupture.state["elapsed"]), 42.0), "reconnect restarted host clock")
	# Reconnect durante emergência recebe o destino já escolhido.
	host.rupture.advance_clock(200.0)
	var late2 := _make(false)
	_sync(host, [late2])
	_check(int(late2.rupture.state["eject_target"]) == int(host.rupture.state["eject_target"]) and late2.rupture.current_state() == R.STATE_EMERGENCY, "reconnect in emergency lost destination")
	host.queue_free()
	late.queue_free()
	late2.queue_free()


func _test_token_once_for_group() -> void:
	var host := _make(true)
	_open_portal(host)
	host.rupture.activate(R.SOURCE_OBJECTIVE, 3)
	host.rupture.advance_clock(30.0)
	_check(host.rupture.resolve_crossing() == R.BAND_PERFECT, "perfect band")
	_check(host.rupture.resolve_crossing() == R.BAND_NONE and host.rupture.momentum() == 1, "repeated resolve incremented momentum twice")
	host.rupture.state["state"] = R.STATE_UNSTABLE # pacote repetido reabrindo o mesmo evento
	host.rupture.resolve_crossing()
	_check(host.rupture.momentum() == 1, "granted ledger did not block duplicate resolution")
	# Consumo: as cartas de cada peer passam pelo host; só a primeira consome.
	# (core = null: caminho puro do ledger; a promoção real está no smoke solo.)
	host.rupture.core = null
	var card := {"id": "c"}
	host.rupture.apply_quality_token(card, 1, {})
	_check(host.rupture.pending_token().is_empty(), "token not consumed")
	host.rupture.state["token"] = {"event_id": String(host.rupture.state["event_id"]), "tier": "perfect", "attempts": 2}
	host.rupture.apply_quality_token(card, 2, {})
	_check(Dictionary(host.rupture.state["consumed_tokens"]).size() == 1, "token consumed twice for the group")
	host.queue_free()


func _test_snapshot_compact() -> void:
	var host := _make(true)
	_open_portal(host)
	host.rupture.activate(R.SOURCE_OBJECTIVE, 3)
	host.rupture.advance_clock(150.0)
	var snap := host.rupture.public_snapshot()
	for key in snap.keys():
		var k := String(key).to_lower()
		_check(not ("particle" in k or "crack" in k or "pulse" in k or "vfx" in k), "visual key in snapshot: " + k)
		var v = snap[key]
		_check(typeof(v) in [TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_DICTIONARY, TYPE_ARRAY], "non-scalar snapshot value " + k)
	_check(var_to_bytes(snap).size() < 1024, "snapshot not compact: %d bytes" % var_to_bytes(snap).size())
	for required in ["id", "ep", "o", "s", "t0", "rem", "mo", "band", "tok", "dst", "g", "sus", "dis"]:
		_check(snap.has(required), "snapshot missing " + required)
	host.queue_free()


func _test_ejection_idempotent_on_replica() -> void:
	var host := _make(true)
	var a := _make(false)
	var b := _make(false)
	for c in [host, a, b]:
		_open_portal(c)
		c.dimension_route_queue = [6, 8]
	host.rupture.activate(R.SOURCE_OBJECTIVE, 3)
	host.rupture.advance_clock(180.0)
	_sync(host, [a, b])
	a.player_hp = 10.0
	b.player_hp = 0.0
	b.is_dead = true # derrubado/morto não bloqueia nem é "curado"
	host.rupture.advance_clock(18.0)
	_check(host.commits.size() == 1, "host commits != 1")
	var target := int(host.commits[0][0])
	# Réplica 'a' recebe o RPC de commit e depois o snapshot (e o RPC repetido).
	a._commit_phase_mp_transfer(target, R.EJECT_ACTION)
	_sync(host, [a, b])
	a._commit_phase_mp_transfer(target, R.EJECT_ACTION)
	_check(a.commits.size() == 1, "replica committed ejection %d times" % a.commits.size())
	# Réplica 'b' (sala sem RPC) segue só o snapshot, uma vez.
	_check(b.commits.size() == 1 and int(b.commits[0][0]) == target, "snapshot fallback did not move replica b with the group")
	_check(a.dimension_route_queue == host.dimension_route_queue and b.dimension_route_queue == host.dimension_route_queue, "route diverged after ejection")
	host.arrive(target)
	a.arrive(target)
	b.arrive(target)
	_check(a.player_hp >= 50.0, "replica HP floor missing")
	_check(b.player_hp == 0.0, "HP floor touched dead replica")
	_sync(host, [a, b])
	_check(a.rupture.current_state() == R.STATE_INACTIVE and int(a.rupture.state["epoch"]) == int(host.rupture.state["epoch"]), "replica did not follow new epoch")
	_check(a.commits.size() == 1 and b.commits.size() == 1, "new-epoch snapshot re-triggered ejection")
	host.queue_free()
	a.queue_free()
	b.queue_free()


func _test_new_run_and_epoch_drop() -> void:
	var host := _make(true)
	var a := _make(false)
	_open_portal(host)
	host.rupture.activate(R.SOURCE_OBJECTIVE, 3)
	var epoch1 := _sync(host, [a])
	host.rupture.advance_clock(10.0)
	host.rupture.resolve_crossing()
	host.arrive(4)
	_sync(host, [a])
	_check(not a.rupture.apply_remote_snapshot(epoch1), "packet from previous epoch applied")
	_check(a.rupture.current_state() == R.STATE_INACTIVE, "old epoch reopened fragment")
	host.queue_free()
	a.queue_free()
