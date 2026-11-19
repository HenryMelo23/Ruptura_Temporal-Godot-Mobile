extends SceneTree

## Soak do tunel publico: conecta pelo relay real, produz carga deterministica
## e mede o frescor do mundo no cliente contra o que o host produziu.
##
## Nao mede "conectou" nem "ping baixo": o criterio e a idade da geracao de
## mundo aplicada no cliente e o silencio maximo entre geracoes.
##
## uso:
##   godot --headless --path . --script res://tests/multiplayer_tunnel_soak_smoke.gd -- \
##     --role=host --host=127.0.0.1 --port=24522 --duration=120 \
##     --scenario=world --seed=7 --result-dir=.agent_logs/tunnel_soak/run1
##
## Papeis: host (dono do mundo), client, client2.
## Cenarios: lobby, world, boss, transition, shop, full_flow, saturation, recovery.

const SCENARIOS: Array[String] = [
	"lobby", "world", "boss", "transition", "shop", "full_flow", "saturation", "recovery",
]
const ROLES: Array[String] = ["host", "client", "client2"]
## Janela de telemetria.
const WINDOW_MS := 5000
## Acima disso a geracao aplicada esta velha demais para o jogo parecer vivo.
const WORLD_FRESH_BUDGET_MS := 250
## Reta final: o peer que sai primeiro nao pode reprovar os outros.
const END_GRACE_MS := 9000

var game: Node
var role := ""
var scenario := "world"
var relay_host := "127.0.0.1"
var port := 24522
var duration_s := 120
var seed_value := 7
var result_dir := ""
var peers_expected := 2
## Quando informados, o peer usa o heartbeat HTTP de verdade do jogo contra o
## manager de staging: a sobrevivencia da sala vira parte do teste.
var relay_base_url := ""
var room_code := ""

var started_ms := 0
var failed := false
var connected_ms := 0
var match_started_ms := 0

# --------------------------------------------------------------- telemetria
var telemetry: FileAccess = null
var window_started_ms := 0
var window_index := 0
## Intervalos entre geracoes de mundo aplicadas, da janela atual.
var world_gaps_ms: Array[int] = []
var world_last_applied_ms := 0
var world_last_sequence := -1
var world_applied_total := 0
var window_pings: Array[int] = []
var ping_all: Array[int] = []
var gap_all: Array[int] = []
var worst_gap_ms := 0
var disconnects := 0
var saw_connection := false
var rss_first_kb := 0
var rss_last_kb := 0
## Eventos confiaveis disparados e confirmados durante o trafego pesado.
var control_sent := 0
var control_seen := 0

# ------------------------------------------------------------------ fluxo mp
var ready_sent := false
var start_requested := false
var manifest_reveal_requested := false
var spectrum_ready_sent := false
var manifest_start_requested := false
var henry_effect_selection_opened := false
var henry_ready_sent := false
var load_applied := false
var stage_index := 0
var stage_started_ms := 0


func _initialize() -> void:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with("--role="):
			role = arg.trim_prefix("--role=")
		elif arg.begins_with("--host="):
			relay_host = arg.trim_prefix("--host=")
		elif arg.begins_with("--port="):
			port = int(arg.trim_prefix("--port="))
		elif arg.begins_with("--duration="):
			duration_s = maxi(10, int(arg.trim_prefix("--duration=")))
		elif arg.begins_with("--scenario="):
			scenario = arg.trim_prefix("--scenario=")
		elif arg.begins_with("--seed="):
			seed_value = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--peers="):
			peers_expected = maxi(2, int(arg.trim_prefix("--peers=")))
		elif arg.begins_with("--result-dir="):
			result_dir = arg.trim_prefix("--result-dir=")
		elif arg.begins_with("--relay-base-url="):
			relay_base_url = arg.trim_prefix("--relay-base-url=")
		elif arg.begins_with("--room-code="):
			room_code = arg.trim_prefix("--room-code=")
	if not ROLES.has(role):
		_fail("missing or invalid --role")
		return
	if not SCENARIOS.has(scenario):
		_fail("invalid --scenario=%s" % scenario)
		return
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	started_ms = Time.get_ticks_msec()
	window_started_ms = started_ms
	stage_started_ms = started_ms
	_open_telemetry()
	call_deferred("_start_role")


# ================================================================ telemetria
func _open_telemetry() -> void:
	if result_dir == "":
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(result_dir))
	telemetry = FileAccess.open(result_dir.path_join("%s.jsonl" % role), FileAccess.WRITE)


func _emit(kind: String, data: Dictionary) -> void:
	if telemetry == null:
		return
	data["kind"] = kind
	data["role"] = role
	data["scenario"] = scenario
	data["at_ms"] = Time.get_ticks_msec() - started_ms
	telemetry.store_line(JSON.stringify(data))
	telemetry.flush()


func _rss_kb() -> int:
	var file := FileAccess.open("/proc/self/status", FileAccess.READ)
	if file == null:
		return 0
	while not file.eof_reached():
		var line := file.get_line()
		if line.begins_with("VmRSS:"):
			file.close()
			return int(line.split(":")[1].strip_edges().split(" ")[0])
	file.close()
	return 0


static func _percentile(values: Array, ratio: float) -> int:
	if values.is_empty():
		return 0
	var sorted := values.duplicate()
	sorted.sort()
	var index: int = clampi(int(floor(float(sorted.size() - 1) * ratio)), 0, sorted.size() - 1)
	return int(sorted[index])


static func _largest(values: Array) -> int:
	var top := 0
	for value in values:
		top = maxi(top, int(value))
	return top


## Mede o que importa: quando uma geracao NOVA do mundo foi aplicada aqui.
func _sample_world_progress(now_ms: int) -> void:
	var sequence: int = int(game.net_world_last_sequence)
	if sequence <= world_last_sequence:
		return
	world_last_sequence = sequence
	world_applied_total += 1
	if world_last_applied_ms > 0:
		var gap: int = now_ms - world_last_applied_ms
		world_gaps_ms.append(gap)
		gap_all.append(gap)
		worst_gap_ms = maxi(worst_gap_ms, gap)
	world_last_applied_ms = now_ms


func _close_window(now_ms: int) -> void:
	window_index += 1
	var rss: int = _rss_kb()
	if rss_first_kb == 0:
		rss_first_kb = rss
	rss_last_kb = rss
	var silence_ms: int = 0 if world_last_applied_ms <= 0 else now_ms - world_last_applied_ms
	_emit("window", {
		"window": window_index,
		"world_applied": world_applied_total,
		"world_sequence_produced": int(game.net_world_sequence),
		"world_sequence_applied": int(game.net_world_last_sequence),
		"world_updates_in_window": world_gaps_ms.size(),
		"world_gap_p50_ms": _percentile(world_gaps_ms, 0.5),
		"world_gap_p95_ms": _percentile(world_gaps_ms, 0.95),
		"world_gap_max_ms": _largest(world_gaps_ms),
		"world_silence_ms": silence_ms,
		"ping_ms": int(game.net_ping_ms),
		"ping_p95_ms": _percentile(window_pings, 0.95),
		"jitter_ms": float(game.net_world_jitter_ms),
		"bytes_in": int(game.net_report_total_bytes_in),
		"bytes_out": int(game.net_report_total_bytes_out),
		"packets_in": int(game.net_report_total_packets_in),
		"packets_out": int(game.net_report_total_packets_out),
		"outgoing_chunks_pending": int(game.net_world_outgoing_chunk_count) - int(game.net_world_outgoing_chunk_index),
		"pending_chunks_held": int(game.net_world_pending_chunks.size()),
		"pending_sequence": int(game.net_world_pending_sequence),
		"enemies": int(game.enemies.size()),
		"enemy_bullets": int(game.enemy_bullets.size()),
		"connected": bool(game.online_connected),
		"peers": int(game.online_lobby_connected_count),
		"mode": String(game.mode),
		"rss_kb": rss,
		"control_sent": control_sent,
		"control_seen": control_seen,
		# Heartbeat HTTP de sala: se parar de bater, o manager mata a sala.
		"hb_last_sent_ms": int(game.online_heartbeat_last_sent_ms),
		"hb_age_ms": int(game._online_heartbeat_age_ms()),
		"hb_in_flight": bool(game.online_heartbeat_in_flight),
		"hb_fails": int(game.online_heartbeat_fail_count),
		"hb_error": String(game.online_heartbeat_last_error),
		"hb_expires_ms": int(game.online_heartbeat_last_expires_ms),
		"hb_active": bool(game._online_room_heartbeat_active()),
	})
	world_gaps_ms.clear()
	window_pings.clear()
	window_started_ms = now_ms


# ================================================================ papeis
func _start_role() -> void:
	game.startup_thanks_done = true
	game.run_tutorial_enabled = false
	game.player_profile_id = "tunnel-soak-smoke"
	game.player_identity_auth_token = "local-smoke-token"
	game.player_progress_sync_timer = INF
	game.player_progress_pending_events.clear()
	game.rng.seed = seed_value
	for index in [1, 2]:
		game.unlocked_manifestation_ids[game.MANIFESTATIONS[index]["key"]] = true
	for index in [1, 3]:
		game.unlocked_spectrum_ids[game.AURAS[index]["key"]] = true
	game.player_nickname = role.to_upper()
	game.is_multiplayer = true
	game.is_host = false
	game.online_room_owner = role == "host"
	if relay_base_url != "":
		game.ONLINE_RELAY_BASE_URL = relay_base_url
	if room_code != "":
		game.online_room_code = room_code
	game.mode = "lobby_online_host" if role == "host" else "lobby_online_client"
	game._connect_to_online_host(relay_host, port)
	_emit("start", {"host": relay_host, "port": port, "duration_s": duration_s, "peers": peers_expected})
	call_deferred("_run")


func _run() -> void:
	var deadline_ms: int = started_ms + duration_s * 1000
	while Time.get_ticks_msec() < deadline_ms and not failed:
		await process_frame
		var now_ms: int = Time.get_ticks_msec()
		if game.online_connected:
			if not saw_connection:
				saw_connection = true
				connected_ms = now_ms
				_emit("connected", {})
		elif saw_connection:
			# Os peers nao terminam no mesmo milissegundo; quem sai primeiro
			# derruba os outros. So conta como falha fora da reta final.
			if now_ms >= deadline_ms - END_GRACE_MS:
				_emit("peer_left_at_end", {})
				break
			disconnects += 1
			_emit("disconnected", {"total": disconnects})
			_finish(false, "peer desconectou no meio da partida")
			return
		if int(game.net_ping_ms) >= 0:
			window_pings.append(int(game.net_ping_ms))
			ping_all.append(int(game.net_ping_ms))
		_keep_alive()
		_sample_world_progress(now_ms)
		_drive_flow(now_ms)
		if now_ms - window_started_ms >= WINDOW_MS:
			_close_window(now_ms)
	_close_window(Time.get_ticks_msec())
	_finish(true, "")


## O soak mede transporte, nao sobrevivencia: um game_over pararia o mundo e
## falsificaria a medicao como se o tunel tivesse travado.
func _keep_alive() -> void:
	if game.mode != "game":
		return
	game.player_hp_max = 1000000.0
	game.player_hp = 1000000.0
	game.is_dead = false


## Lobby, manifestacao e, depois, a carga do cenario.
func _drive_flow(now_ms: int) -> void:
	if not game.online_connected:
		return
	if game.mode in ["lobby_online_host", "lobby_online_client"]:
		if role != "host":
			if not ready_sent:
				ready_sent = true
				game._set_lobby_ready(true)
			return
		if not start_requested and game.online_lobby_connected_count >= peers_expected and game.online_lobby_ready_count >= peers_expected - 1:
			start_requested = true
			game._send_host_start_request()
		return
	if game.mode in ["manifest_mp", "mutation_select_mp", "effect_select_mp"]:
		_manifest_flow()
		return
	if game.mode == "game":
		if match_started_ms == 0:
			match_started_ms = now_ms
			stage_started_ms = now_ms
			_emit("match_started", {})
		_drive_scenario(now_ms)


func _manifest_flow() -> void:
	var manifestation: int = 1 if role == "host" else 2
	var aura: int = 1 if role == "host" else 3
	if game.active_character_key == game.CHARACTER_HENRY:
		if game.mode == "mutation_select_mp" and not henry_effect_selection_opened:
			henry_effect_selection_opened = true
			game.mode = "effect_select_mp"
			game.manifest_select_stage = game.MANIFEST_STAGE_AURA
			game._sync_manifest_mp_selection(true)
		elif game.mode == "effect_select_mp" and not henry_ready_sent:
			henry_ready_sent = true
			game._toggle_henry_multiplayer_ready()
		return
	if game.mode == "manifest_mp" and game.manifest_select_stage == game.MANIFEST_STAGE_MANIFESTATION and not manifest_reveal_requested:
		manifest_reveal_requested = true
		game._set_selected_manifestation(manifestation, false)
		game._confirm_manifest_mp_selection()
	elif game.mode == "manifest_mp" and game.manifest_select_stage == game.MANIFEST_STAGE_AURA and not spectrum_ready_sent:
		spectrum_ready_sent = true
		game._set_selected_aura(aura, false)
		game._confirm_manifest_mp_selection()
	elif spectrum_ready_sent and role == "host" and not manifest_start_requested and game._manifest_all_players_ready():
		manifest_start_requested = true
		game._request_manifest_mp_start()


# ================================================================ cenarios
## So o host produz carga: ele e a autoridade do mundo.
func _drive_scenario(now_ms: int) -> void:
	if role != "host":
		return
	match scenario:
		"lobby":
			return
		"world":
			_load_world(120, 80)
		"saturation":
			_load_world(220, 160)
		"boss":
			_load_world(90, 60)
			_load_boss()
		"transition":
			_load_world(90, 60)
			_cycle_phase(now_ms)
		"shop":
			_load_world(60, 40)
			_cycle_control(now_ms)
		"recovery":
			_load_world(140, 100)
			_cycle_control(now_ms)
		"full_flow":
			_full_flow(now_ms)


## Enche o mundo uma vez e repoe o que morrer: carga constante e comparavel.
func _load_world(enemy_target: int, bullet_target: int) -> void:
	if game.enemies.size() < enemy_target:
		for i in range(mini(12, enemy_target - game.enemies.size())):
			var angle: float = game.rng.randf() * TAU
			var distance: float = 260.0 + game.rng.randf() * 520.0
			game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(angle) * distance)
	while game.enemy_bullets.size() < bullet_target:
		var bullet_angle: float = game.rng.randf() * TAU
		# Mesmo formato que o jogo usa: a apresentacao le dir, phase e type.
		game.enemy_bullets.append({
			"pos": game.player_pos + Vector2.from_angle(bullet_angle) * (180.0 + game.rng.randf() * 420.0),
			"dir": Vector2.from_angle(bullet_angle),
			"life": 6.0,
			"damage": 1,
			"phase": game.rng.randf_range(0.0, TAU),
			"type": "projetador",
			"speed_mult": 1.0,
		})
	load_applied = true


func _load_boss() -> void:
	if game.boss_active:
		return
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 90000.0
	game.boss_hp = 90000.0
	game.boss_pos = game.player_pos + Vector2(400.0, 0.0)
	_emit("boss_started", {})


## Evento confiavel repetido durante o trafego pesado: prova que o canal de
## controle nao morre junto com o canal do mundo.
func _cycle_control(now_ms: int) -> void:
	if now_ms - stage_started_ms < 4000:
		return
	stage_started_ms = now_ms
	control_sent += 1
	if game._shop_rpc_available():
		game.rpc("_rpc_shop_ready")
	_emit("control_sent", {"total": control_sent})


func _cycle_phase(now_ms: int) -> void:
	if now_ms - stage_started_ms < 12000:
		return
	stage_started_ms = now_ms
	stage_index += 1
	var next_phase: int = 1 + (stage_index % 4)
	game._advance_to_phase(next_phase)
	_emit("phase_changed", {"phase": next_phase})


func _full_flow(now_ms: int) -> void:
	var elapsed: int = now_ms - match_started_ms
	if elapsed < 20000:
		_load_world(90, 60)
	elif elapsed < 40000:
		_load_world(120, 80)
		_load_boss()
	elif elapsed < 60000:
		_load_world(120, 80)
		_cycle_phase(now_ms)
	else:
		_load_world(140, 100)
		_cycle_control(now_ms)


# ================================================================ resultado
func _fail(reason: String) -> void:
	failed = true
	push_error("PUBLIC_TUNNEL_SOAK_FAIL role=%s %s" % [role, reason])
	_emit("fail", {"reason": reason})
	if telemetry != null:
		telemetry.close()
	quit(1)


func _finish(ok: bool, reason: String) -> void:
	var summary := {
		"role": role,
		"scenario": scenario,
		"duration_s": duration_s,
		"disconnects": disconnects,
		"world_applied": world_applied_total,
		"world_sequence_produced": int(game.net_world_sequence),
		"world_gap_p95_ms": _percentile(gap_all, 0.95),
		"world_gap_p99_ms": _percentile(gap_all, 0.99),
		"world_gap_max_ms": worst_gap_ms,
		"ping_p95_ms": _percentile(ping_all, 0.95),
		"rss_first_kb": rss_first_kb,
		"rss_last_kb": rss_last_kb,
		"rss_growth_mb": float(rss_last_kb - rss_first_kb) / 1024.0,
		"control_sent": control_sent,
		"connected": bool(game.online_connected),
		"peers": int(game.online_lobby_connected_count),
		"match_started": match_started_ms > 0,
		"ok": ok,
		"reason": reason,
	}
	_emit("summary", summary)
	if result_dir != "":
		var file := FileAccess.open(result_dir.path_join("%s_summary.json" % role), FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(summary, "  "))
			file.close()
	if telemetry != null:
		telemetry.close()
	if not ok:
		push_error("PUBLIC_TUNNEL_SOAK_FAIL role=%s %s" % [role, reason])
		quit(1)
		return
	# Nunca emitir OK so porque conectou: o teste tem que ter rodado a partida.
	if not saw_connection:
		push_error("PUBLIC_TUNNEL_SOAK_FAIL role=%s nunca conectou" % role)
		quit(1)
		return
	if scenario != "lobby" and match_started_ms == 0:
		push_error("PUBLIC_TUNNEL_SOAK_FAIL role=%s a partida nunca comecou" % role)
		quit(1)
		return
	print("PUBLIC_TUNNEL_SOAK_OK role=%s duration=%d disconnects=%d world_applied=%d world_gap_p95_ms=%d world_gap_max_ms=%d ping_p95_ms=%d rss_growth_mb=%.1f" % [
		role, duration_s, disconnects, world_applied_total,
		_percentile(gap_all, 0.95), worst_gap_ms, _percentile(ping_all, 0.95),
		float(rss_last_kb - rss_first_kb) / 1024.0,
	])
	quit(0)
