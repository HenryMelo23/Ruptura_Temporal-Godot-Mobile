extends SceneTree

## Cripta de Seda (9) em multiplayer: autoridade enxerga pelos cones de TODOS os
## jogadores; a replica recebe o mundo (pilastras, lamparinas, ecos, fios, teias,
## estados das aranhas e da Matriarca) e calcula a propria vista.

var failed := false
var host: Node
var replica: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("MULTIPLAYER_PHASE9_PARITY_FAIL " + message)


func _initialize() -> void:
	host = load("res://scenes/Main.tscn").instantiate()
	replica = load("res://scenes/Main.tscn").instantiate()
	root.add_child(host)
	root.add_child(replica)
	call_deferred("_run")


func _sync() -> void:
	var packet: Dictionary = bytes_to_var(var_to_bytes(host._pack_net_boss_visuals()))
	replica._apply_remote_boss_visual_snapshot(packet)


func _run() -> void:
	await process_frame
	for game in [host, replica]:
		game._start_game()
		game._story().queue.clear()
		game._advance_to_phase(9)
		game._story().queue.clear()
		game.mode = "game"
		game.is_multiplayer = true
	host.is_host = true
	host.online_room_owner = true
	replica.is_host = false
	replica.online_room_owner = false
	var hc: RTCriptaController = host.cripta_controller
	var rc: RTCriptaController = replica.cripta_controller
	_check(host._is_world_authority() and replica._is_world_replica(), "papeis de rede")

	# ---------------- identidade das aranhas na rede
	var roster: Array = []
	for i in range(RTCriptaController.KINDS.size()):
		roster.append({"uid": 9100 + i, "type": RTCriptaController.KINDS[i], "pos": Vector2(200 + i * 40, 320), "hp": 50.0, "max_hp": 50.0})
	var enemy_packet: PackedFloat32Array = host.RTNetContractScript.pack_enemies(roster, host.NET_ENEMY_TYPES, host.ENEMY_COMMON, host.NET_LEECH_STATES, host.SANGUESSUGA_STATE_DORMANT)
	var decoded: Array = host.RTNetContractScript.unpack_enemy_snapshot(enemy_packet, {}, host.NET_ENEMY_TYPES, host.ENEMY_COMMON, host.NET_LEECH_STATES, host.ENEMY_CHRONAL_LEECH, Time.get_ticks_msec())
	_check(decoded.size() == roster.size(), "roster da fase 9 cortado")
	for i in range(mini(decoded.size(), roster.size())):
		_check(String(decoded[i].get("type", "")) == String(roster[i].get("type", "")), "aranha virou outra coisa na rede: %s" % roster[i]["type"])

	# ---------------- mesmo mapa nas duas pontas
	rc._layout_seed = hc._layout_seed + 1
	rc._build_layout()
	_sync()
	_check(rc._layout_seed == hc._layout_seed, "semente do mapa nao chegou")
	_check(rc.pillars.size() == hc.pillars.size(), "numero de pilastras diferente")
	for i in range(mini(rc.pillars.size(), hc.pillars.size())):
		_check(Vector2(rc.pillars[i]["pos"]).is_equal_approx(Vector2(hc.pillars[i]["pos"])), "pilastra %d em outro lugar" % i)
	for i in range(hc.lamps.size()):
		hc.lamps[i]["on"] = i == 2
		hc.lamps[i]["t"] = 1.5
		hc.lamps[i]["life"] = 9.0
	hc.echoes = [{"pos": Vector2(900, 700), "t": 0.4, "uid": 5}]
	hc.threads = [{"a": Vector2(500, 500), "b": Vector2(800, 520), "t": 1.0, "life": 9.0, "hp": 3}]
	hc.webs = [{"p": Vector2(600, 600), "v": Vector2(210, 0), "r": 12.0, "life": 2.0, "kind": "teia", "dmg": 0.05}]
	_sync()
	_check(bool(rc.lamps[2]["on"]) and not bool(rc.lamps[1]["on"]), "lamparinas nao sincronizaram")
	_check(rc.echoes.size() == 1 and Vector2(rc.echoes[0]["pos"]).is_equal_approx(Vector2(900, 700)), "ecos nao sincronizaram")
	_check(rc.threads.size() == 1 and int(rc.threads[0]["hp"]) == 3, "fios nao sincronizaram")
	_check(rc.webs.size() == 1 and String(rc.webs[0]["kind"]) == "teia", "teias nao sincronizaram")

	# ---------------- autoridade usa o cone de cada jogador
	var host_pos := Vector2(1500, 1000)
	var remote_pos := Vector2(1900, 1000)
	host.player_pos = host_pos
	hc.facing = Vector2.LEFT
	host.net_players_by_peer = {2: {
		"pos": remote_pos, "hp": 100.0, "hp_max": 100.0, "has_snapshot": true, "alive": true,
		"aim_dir": Vector2.RIGHT, "input_move": Vector2.RIGHT, "input_moving": true, "velocity": Vector2.ZERO,
	}}
	for i in range(30):
		hc._update_peer_facings(1.0 / 30.0)
	var vs: Array = hc.viewers()
	_check(vs.size() == 2, "autoridade deveria ver 2 jogadores: %d" % vs.size())
	var spot := remote_pos + Vector2(380, 0)
	for p in hc.pillars:
		p["pos"] = Vector2(-5000, -5000)
	for l in hc.lamps:
		l["on"] = false
	_check(not hc.sees_from(host_pos, hc.facing, spot), "host olha para o outro lado")
	_check(hc.seen_by_any(spot), "cone do jogador remoto nao conta para a IA")
	_check(hc.looked_at_by_any(spot), "viuva deveria congelar quando o remoto encara")
	host.net_players_by_peer[2]["input_move"] = Vector2.LEFT
	host.net_players_by_peer[2]["aim_dir"] = Vector2.LEFT
	for i in range(60):
		hc._update_peer_facings(1.0 / 30.0)
	_check(not hc.looked_at_by_any(spot), "remoto virou as costas e a viuva continuou parada")

	# ---------------- estados das aranhas chegam na replica
	host.enemies.clear()
	host._spawn_enemy(RTCriptaController.ALCAPAO, Vector2(1000, 800))
	var alc: Dictionary = host.enemies.back()
	alc["pos"] = Vector2(1000, 800)
	# A replica recebe os inimigos pelo mesmo caminho da rede (pack -> unpack).
	var world_packet: PackedFloat32Array = host._pack_net_enemies()
	replica.enemies = host.RTNetContractScript.unpack_enemy_snapshot(world_packet, {}, host.NET_ENEMY_TYPES, host.ENEMY_COMMON, host.NET_LEECH_STATES, host.ENEMY_CHRONAL_LEECH, Time.get_ticks_msec())
	_check(replica.enemies.size() == 1 and replica.enemies[0].has("phase"), "inimigo da replica sem campos da rede")
	_sync()
	_check(String(replica.enemies[0].get("cr_state", "")) == "buried", "estado enterrada nao chegou")
	replica.player_pos = Vector2(1000, 860)
	rc.facing = Vector2.UP
	rc.update_replica(1.0 / 30.0)
	_check(bool(replica.enemies[0].get("untargetable", false)), "enterrada deveria ser invisivel ao tiro da replica")
	alc["cr_state"] = "emerge"
	alc["cr_t"] = 0.0
	rc.scare_cd = 0.0
	_sync()
	rc.update_replica(1.0 / 30.0)
	_check(not rc.scare.is_empty(), "replica perto nao levou susto quando a alcapao saiu")
	# ondulacao local: inimigo mexendo atras da replica
	replica.enemies[0]["pos"] = Vector2(1000, 1100)
	alc["cr_state"] = "hunt"
	_sync()
	rc.ripples.clear()
	rc.facing = Vector2.UP
	rc.update_replica(1.0 / 30.0)
	replica.enemies[0]["pos"] = Vector2(1020, 1110)
	rc.update_replica(1.0 / 30.0)
	_check(not rc.ripples.is_empty(), "replica nao viu ondulacao do bicho atras dela")

	# ---------------- laco/casulo: quem esta preso chega na replica; efeitos sao locais
	host.enemies.clear()
	host._spawn_enemy(RTCriptaGrapple.BOLEADEIRA, Vector2(1200, 900))
	var bol: Dictionary = host.enemies.back()
	bol["cr_state"] = "drag"
	bol["gp"] = 2
	var bol_packet: PackedFloat32Array = host._pack_net_enemies()
	replica.enemies = host.RTNetContractScript.unpack_enemy_snapshot(bol_packet, {}, host.NET_ENEMY_TYPES, host.ENEMY_COMMON, host.NET_LEECH_STATES, host.ENEMY_CHRONAL_LEECH, Time.get_ticks_msec())
	_check(replica.enemies.size() == 1 and String(replica.enemies[0].get("type", "")) == RTCriptaGrapple.BOLEADEIRA, "boleadeira virou outra coisa na rede")
	_sync()
	_check(String(replica.enemies[0].get("cr_state", "")) == "drag" and int(replica.enemies[0].get("gp", 0)) == 2, "quem esta lacado nao chegou na replica")
	hc.webs = [{"p": Vector2(700, 700), "v": Vector2(380, 0), "r": 14.0, "life": 1.0, "kind": "bola", "dmg": 0.0, "owner": int(bol["uid"])}]
	_sync()
	_check(rc.webs.size() == 1 and String(rc.webs[0]["kind"]) == "bola" and int(rc.webs[0]["owner"]) == int(bol["uid"]), "bola de seda nao chegou com a dona")
	var rg: RTCriptaGrapple = rc.grapple
	rg.reset()
	rc.apply_local_event("grab", float(bol["uid"]), Vector2(1200, 900))
	_check(rg.held() and String(rg.grab["kind"]) == "drag", "evento de laco nao prendeu a replica")
	rc.apply_local_event("release", float(bol["uid"]), Vector2.ZERO)
	_check(not rg.held(), "evento de soltar nao soltou a replica")
	rc.apply_local_event("poison", 2.0, Vector2.ZERO)
	_check(rg.poison_stacks == 2, "veneno nao chegou na replica")
	_check(hc.grapple.poison_stacks == 0, "veneno da replica vazou para o host")
	hc.grapple.on_escape(2, int(bol["uid"]))
	_check(String(bol.get("cr_state", "")) == "recover" and not hc.grapple.can_hold(2), "fuga do remoto nao soltou a aranha no host")
	rg.reset()
	hc.webs.clear()

	# ---------------- Matriarca
	var hb: RTBoss9Controller = host.boss9_controller
	hb.mode = "olhar"
	hb.anim = "gaze"
	hb.beam_angle = 1.2
	hb.stage = 2
	hb.blackout = 5.0
	hb.eggs = [{"pos": Vector2(700, 700), "t": 0.3, "fall": 1.0}]
	hb.height = 140.0
	_sync()
	var rb: RTBoss9Controller = replica.boss9_controller
	_check(rb.mode == "olhar" and rb.anim == "gaze" and rb.stage == 2, "modo do chefe nao chegou")
	_check(is_equal_approx(rb.beam_angle, 1.2) and rb.eggs.size() == 1 and is_equal_approx(rb.height, 140.0), "feixes/ovos/altura nao chegaram")
	rc._replica_blackout = false
	rc.scare_cd = 0.0
	replica.boss_active = true
	rc.update_replica(1.0 / 30.0)
	_check(rc._replica_blackout and String(rc.scare.get("kind", "")) == "matriarca", "replica nao sentiu o apagao")
	_check(rb.beam_angle > 1.2, "feixe nao gira entre pacotes")
	# espreita: o aviso chega com o alvo certo
	hb.mode = "ambush_warn"
	hb.t = 0.1
	hb.ambush_peer = 2
	_sync()
	_check(rb.mode == "ambush_warn" and rb.ambush_peer == 2, "aviso da espreita nao chegou com o alvo")
	# feixe acerta o jogador remoto (autoridade decide)
	host.boss_pos = Vector2(1500, 600)
	hb.beam_angle = (remote_pos - hb.eye_pos()).angle()
	_check(not hb._viewer_in_beam().is_empty() and int(hb._viewer_in_beam()["peer_id"]) == 2, "feixe nao enxerga o jogador remoto")

	# ---------------- rota do ciclo igual para todos
	var action: String = host._phase_flow()._farm_action_with_route()
	host.dimension_route_queue.clear()
	replica.dimension_route_queue.clear()
	host._phase_flow()._commit_phase_mp_transfer(0, action)
	replica._phase_flow()._commit_phase_mp_transfer(0, action)
	_check(Array(host.dimension_route_queue) == Array(replica.dimension_route_queue) and host.dimension_route_queue.size() == 3, "host e replica com rotas diferentes")
	_check(int(host.pending_phase) == 7 and int(replica.pending_phase) == 7, "ciclo nao comecou pela 7 nos dois")

	host.queue_free()
	replica.queue_free()
	host = null
	replica = null
	hc = null
	rc = null
	rg = null
	hb = null
	rb = null
	await process_frame
	await process_frame
	await process_frame
	if failed:
		quit(1)
	else:
		print("MULTIPLAYER_PHASE9_PARITY_OK layout=sync world=sync vision=per_player boss=sync route=shared")
		quit(0)
