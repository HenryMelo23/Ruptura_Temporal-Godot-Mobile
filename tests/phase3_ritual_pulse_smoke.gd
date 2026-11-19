extends SceneTree

## Ritual da Catedral (jogavel): selo, profanacao no compasso, pulsos, TP,
## fieis, sacrificio, consumacao, resultado por circulo, limpeza e rede.

var game: Node
var ctl
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("PHASE3_RITUAL_FAIL " + message)


func _prepare_phase3() -> void:
	game._advance_to_phase(3)
	game.mode = "game"
	game.is_multiplayer = false
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game.player_hp_max = 1000.0
	game.player_hp = 1000.0
	game.is_dead = false
	game.player_pos = game.WORLD_SIZE * 0.5
	game.time_alive = 300.0
	game.last_dash_time = -100.0
	game.enemies.clear()
	game.phase3_miasma_zones.clear()
	game.net_players_by_peer.clear()
	ctl = game.phase3_ritual_pulse_controller
	ctl.reset()


func _marked(role: String) -> Array:
	return game.enemies.filter(func(e): return String(Dictionary(e).get("phase3_ritual_role", "")) == role)


func _circle(id: int) -> Dictionary:
	for value in Array(ctl.active_snapshot().get("circles", [])):
		if int(Dictionary(value).get("id", -1)) == id:
			return value
	return {}


func _live_circle(id: int) -> Dictionary:
	for value in Array(ctl._active.get("circles", [])):
		if int(Dictionary(value).get("id", -1)) == id:
			return value
	return {}


func _step(dt: float, steps: int, enemies_too: bool = true) -> void:
	for i in range(steps):
		game.time_alive += dt
		if enemies_too:
			for e in game.enemies.duplicate():
				if bool(Dictionary(e).get("phase3_ritual_marked", false)):
					game._update_phase3_enemy(e, dt)
		ctl.update(dt, true)


func _safe_spot(circle: Dictionary) -> Vector2:
	var w: int = int(circle.get("safe_wedge", 0))
	return Vector2(circle["pos"]) + Vector2.from_angle((float(w) + 0.5) * TAU / float(ctl.WEDGES)) * float(circle["radius"]) * 0.5


func _danger_spot(circle: Dictionary) -> Vector2:
	var w: int = (int(circle.get("safe_wedge", 0)) + 2) % ctl.WEDGES
	return Vector2(circle["pos"]) + Vector2.from_angle((float(w) + 0.5) * TAU / float(ctl.WEDGES)) * float(circle["radius"]) * 0.5


func _settle_officiant(officiant: Dictionary) -> Dictionary:
	var circle: Dictionary = _circle(int(officiant["phase3_ritual_circle_id"]))
	officiant["pos"] = Vector2(circle["pos"])
	game._update_phase3_enemy(officiant, 0.02)
	return _live_circle(int(officiant["phase3_ritual_circle_id"]))


func _test_start_seal_and_procession() -> void:
	_prepare_phase3()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(420.0, 330.0))
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(1080.0, 570.0))
	for i in range(5):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(float(i)) * 300.0)
	_check(ctl.force_start_for_test(), "ritual did not start")
	_check(_marked("officiant").size() == 2, "officiants not marked")
	_check(_marked("fiel").size() >= 2 and _marked("fiel").size() <= 4, "fieis not recruited (%d)" % _marked("fiel").size())
	var officiant: Dictionary = _marked("officiant")[0]
	var circle: Dictionary = _circle(int(officiant["phase3_ritual_circle_id"]))
	officiant["pos"] = Vector2(circle["pos"]) + Vector2(200, 0)
	var d0: float = Vector2(officiant["pos"]).distance_to(Vector2(circle["pos"]))
	game._update_phase3_enemy(officiant, 0.2)
	_check(Vector2(officiant["pos"]).distance_to(Vector2(circle["pos"])) < d0, "officiant did not walk to circle")
	_check(String(officiant.get("phase3_ritual_pose", "")) == "procession", "walking pose is not procession")
	var hp0: float = float(officiant["hp"])
	game._damage_enemy(officiant, 5.0, "eletrica", false, true, game.player_pos, "basic_attack")
	_check(float(officiant["hp"]) < hp0, "walking officiant should be vulnerable")
	var live: Dictionary = _settle_officiant(officiant)
	_check(bool(live.get("sealed", false)), "officiant in circle is not sealed")
	_check(String(officiant.get("phase3_ritual_pose", "")) == "dance", "channel pose is not dance")
	hp0 = float(officiant["hp"])
	game._damage_enemy(officiant, 50.0, "eletrica", false, true, game.player_pos, "basic_attack")
	_check(is_equal_approx(float(officiant["hp"]), hp0), "sealed officiant took damage")
	# Pose muda com o compasso.
	var p1: Dictionary = RTPhase3RitualPresentation.pose(game, officiant, game.time_alive)
	_step(ctl.BEAT * 0.5, 1, false)
	var p2: Dictionary = RTPhase3RitualPresentation.pose(game, officiant, game.time_alive)
	_check(not p1.is_empty() and Vector2(p1["offset"]) != Vector2(p2["offset"]), "dance pose does not animate with the beat")


func _test_profane_dance_and_pulse() -> void:
	_prepare_phase3()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(420.0, 330.0))
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(1080.0, 570.0))
	_check(ctl.force_start_for_test(), "ritual did not start")
	var officiant: Dictionary = _marked("officiant")[0]
	var cid: int = int(officiant["phase3_ritual_circle_id"])
	_settle_officiant(officiant)
	# Pulso fora da runa: dano, empurrao, perda de profanacao.
	var live: Dictionary = _live_circle(cid)
	live["profane"] = 0.5
	game.player_pos = _danger_spot(live)
	var hp0: float = game.player_hp
	var beat0: int = ctl.beat_index()
	while ctl.beat_index() == beat0:
		game.player_pos = _danger_spot(_live_circle(cid))
		_live_circle(cid)["profane"] = 0.5
		_step(0.02, 1)
	live = _live_circle(cid)
	_check(game.player_hp < hp0, "pulse outside the rune did no damage")
	_check(int(live.get("hits_taken", 0)) == 1 and float(live.get("profane", 1.0)) < 0.45, "pulse did not cost profanation")
	# TP atravessa o pulso.
	game.player_pos = _danger_spot(live)
	hp0 = game.player_hp
	var to_next: float = ctl.BEAT - fposmod(ctl.elapsed(), ctl.BEAT) + 0.01
	game.time_alive += to_next - 0.05
	game.last_dash_time = game.time_alive
	game.time_alive -= to_next - 0.05
	_step(to_next, 1)
	_check(is_equal_approx(game.player_hp, hp0), "TP did not cross the pulse without damage")
	# Dança certa: seguir a runa acesa ate quebrar o selo.
	live = _live_circle(cid)
	live["profane"] = 0.0
	live["hits_taken"] = 0
	var guard := 0
	while not bool(_live_circle(cid).get("profaned", false)) and guard < 400:
		guard += 1
		game.player_pos = _safe_spot(_live_circle(cid))
		game.last_dash_time = -100.0
		_step(0.05, 1)
	live = _live_circle(cid)
	_check(bool(live.get("profaned", false)), "following the lit rune did not profane the circle")
	_check(bool(live.get("perfect", false)), "clean profanation was not perfect")
	_check(float(officiant.get("stun", 0.0)) > 0.0 and not bool(live.get("sealed", true)), "broken seal did not stun/unseal")
	_check(is_equal_approx(ctl.damage_taken_multiplier(officiant), ctl.BROKEN_DAMAGE_MULT), "profaned officiant has no damage bonus")
	var hp_o: float = float(officiant["hp"])
	game._damage_enemy(officiant, 10.0, "eletrica", false, true, game.player_pos, "basic_attack")
	_check(float(officiant["hp"]) < hp_o, "profaned officiant still immune")
	# Matar o oficiante dissolve o circulo; o outro se consuma -> parcial.
	game._kill_enemy(officiant)
	_check(String(_live_circle(cid).get("outcome", "")) == "disrupted", "officiant kill did not dissolve circle")
	var other: Dictionary = _marked("officiant")[0]
	var other_cid: int = int(other["phase3_ritual_circle_id"])
	_settle_officiant(other)
	_live_circle(other_cid)["progress"] = 0.995
	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(900, 0)
	var nearby: int = game.enemies.size()
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(_live_circle(other_cid)["pos"]) + Vector2(300, 0))
	var witness: Dictionary = game.enemies[-1]
	var score0: int = game.score_total
	_step(0.2, 3)
	var snap: Dictionary = ctl.active_snapshot()
	_check(String(snap.get("result", "")) == "partial", "mixed outcome is not partial (%s)" % snap.get("result", ""))
	_check(int(snap.get("reward", 0)) == ctl.REWARD_POINTS_PER_CIRCLE + ctl.PERFECT_PROFANE_BONUS, "partial reward mismatch %d" % int(snap.get("reward", 0)))
	_check(game.score_total >= score0 + int(snap.get("reward", 0)), "reward not applied")
	_check(game.phase3_miasma_zones.size() >= 1, "consummated circle did not leave miasma")
	_check(float(witness.get("phase3_fervor_timer", 0.0)) > 0.0, "consummation did not spread fervor")
	_check(nearby >= 0, "")


func _test_fieis_and_sacrifice() -> void:
	_prepare_phase3()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(420.0, 330.0))
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(1080.0, 570.0))
	for i in range(4):
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(float(i) * 1.6) * 260.0)
	_check(ctl.force_start_for_test(), "ritual did not start")
	var officiant: Dictionary = _marked("officiant")[0]
	var cid: int = int(officiant["phase3_ritual_circle_id"])
	_settle_officiant(officiant)
	var fieis: Array = _marked("fiel").filter(func(e): return int(Dictionary(e)["phase3_ritual_circle_id"]) == cid)
	# Sem fieis dançando.
	for f in fieis:
		Dictionary(f)["phase3_ritual_dancing"] = false
	var c: Dictionary = _live_circle(cid)
	c["progress"] = 0.0
	game._update_phase3_enemy(officiant, 1.0)
	var solo_rate: float = float(_live_circle(cid)["progress"])
	if not fieis.is_empty():
		for f in fieis:
			var fe: Dictionary = f
			fe["pos"] = Vector2(c["pos"]) + Vector2(c["radius"] * 0.7, 0)
			for k in range(40):
				game._update_phase3_enemy(fe, 0.05)
		_check(bool(Dictionary(fieis[0]).get("phase3_ritual_dancing", false)) and String(Dictionary(fieis[0]).get("phase3_ritual_pose", "")) == "worship", "fiel did not reach worship pose")
		_live_circle(cid)["progress"] = 0.0
		game._update_phase3_enemy(officiant, 1.0)
		_check(float(_live_circle(cid)["progress"]) > solo_rate * 1.15, "dancing fieis do not speed the ritual")
	# Sacrificio: morte dentro do circulo alimenta o ritual.
	_live_circle(cid)["progress"] = 0.2
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(_live_circle(cid)["pos"]) + Vector2(20, 10))
	var victim: Dictionary = game.enemies[-1]
	game._kill_enemy(victim)
	_check(absf(float(_live_circle(cid)["progress"]) - (0.2 + ctl.SACRIFICE_PROGRESS)) < 0.001, "kill inside circle did not feed the ritual")


func _test_timeout_and_cleanup() -> void:
	_prepare_phase3()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(180.0, 180.0))
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(1420.0, 720.0))
	_check(ctl.force_start_for_test(), "ritual did not start")
	for value in _marked("officiant"):
		Dictionary(value)["stun"] = ctl.RITUAL_DURATION + 1.0
	var score0: int = game.score_total
	ctl.update(ctl.RITUAL_DURATION + 0.01, true)
	var snap: Dictionary = ctl.active_snapshot()
	_check(String(snap.get("result", "")) == "success" and String(snap.get("result_reason", "")) == "ritual_timeout", "timeout did not hold the ritual")
	_check(game.score_total >= score0 + int(snap.get("reward", 0)) and int(snap.get("reward", 0)) > 0, "timeout reward")
	ctl.update(ctl.RESULT_DISPLAY_TIME + 0.1, true)
	_check(not ctl.is_active() and _marked("officiant").is_empty(), "result end left marks")

	_prepare_phase3()
	_check(ctl.force_start_for_test(), "ritual did not start")
	game._despawn_enemies_for_boss_call()
	_check(not ctl.is_active() and _marked("officiant").is_empty() and _marked("fiel").is_empty(), "boss call cleanup")
	_prepare_phase3()
	_check(ctl.force_start_for_test(), "ritual did not start")
	game._advance_to_phase(4)
	_check(not ctl.is_active(), "phase change cleanup")


func _test_multiplayer_snapshot() -> void:
	_prepare_phase3()
	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = true
	game.online_lobby_connected_count = 3
	game.net_players_by_peer[2] = {"has_snapshot": true, "pos": Vector2(620.0, 410.0), "velocity": Vector2.ZERO, "hp": 450.0, "hp_max": 450.0, "dead": false, "eliminated": false, "alive": true}
	game.net_players_by_peer[3] = {"has_snapshot": true, "pos": Vector2(980.0, 490.0), "velocity": Vector2.ZERO, "hp": 450.0, "hp_max": 450.0, "dead": false, "eliminated": false, "alive": true}
	_check(ctl.force_start_for_test(), "mp ritual did not start")
	var host_snapshot: Dictionary = ctl.active_snapshot()
	_check(Array(host_snapshot.get("circles", [])).size() == 3, "mp circle count")
	var packet: Dictionary = game._pack_net_boss_visuals()
	var round_trip: Variant = bytes_to_var(var_to_bytes(packet))
	ctl.reset()
	game.is_host = false
	game.online_room_owner = false
	game._apply_remote_boss_visual_snapshot(round_trip)
	var replica: Dictionary = ctl.active_snapshot()
	_check(String(replica.get("event_id", "")) == String(host_snapshot.get("event_id", "")), "replica event id")
	_check(Array(replica.get("devotees", [])).size() == 3, "replica devotees")
	game.is_multiplayer = false
	game.net_players_by_peer.clear()


func _test_normal_phase3_unchanged_outside_pulse() -> void:
	_prepare_phase3()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(500.0, 400.0))
	var devotee: Dictionary = game.enemies[-1]
	var miasma_before: int = game.phase3_miasma_zones.size()
	devotee["miasma_cd"] = 0.0
	game._update_phase3_enemy(devotee, 0.02)
	_check(game.phase3_miasma_zones.size() == miasma_before + 1, "devoto lost its normal miasma")
	_check(not bool(devotee.get("phase3_ritual_marked", false)), "devoto marked outside ritual")


func _run() -> void:
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	_test_start_seal_and_procession()
	_test_profane_dance_and_pulse()
	_test_fieis_and_sacrifice()
	_test_timeout_and_cleanup()
	_test_multiplayer_snapshot()
	_test_normal_phase3_unchanged_outside_pulse()
	ctl.reset()
	if failed:
		print("PHASE3_RITUAL_PULSE_SMOKE_FAILED")
	else:
		print("PHASE3_RITUAL_PULSE_SMOKE_OK seal=true profane_on_beat=true pulse=true tp_dodge=true perfect=true fieis=true sacrifice=true consummation=true partial=true timeout=true cleanup=true snapshot=true")
	game._cleanup_runtime_resources()
	game.free()
	for _frame in range(4):
		await process_frame
	quit(1 if failed else 0)
