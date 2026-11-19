extends SceneTree

## Prova ou derruba o travamento do heartbeat de sala.
##
## Suspeita: `_send_online_room_heartbeat` marca `online_heartbeat_in_flight`
## como verdadeiro quando o HTTPRequest nao esta DISCONNECTED, e volta SEM
## disparar requisicao. Como so `request_completed` limpa essa flag, e esse
## sinal nunca vem para uma requisicao que nao aconteceu, o dono da sala
## pararia de bater para sempre e o manager encerraria a sala em 75 s.
##
## O teste nao simula nada: fala com um manager de verdade (o de staging) e
## observa a maquina de estado real.
##
## uso: godot --headless --path . --script res://tests/online_heartbeat_deadlock_smoke.gd -- \
##        --relay-base-url=http://127.0.0.1:18090 --room-code=ABC123

var game: Node
var relay_base_url := ""
var room_code := ""
var checks := 0


func _initialize() -> void:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	for arg in args:
		if arg.begins_with("--relay-base-url="):
			relay_base_url = arg.trim_prefix("--relay-base-url=")
		elif arg.begins_with("--room-code="):
			room_code = arg.trim_prefix("--room-code=")
	if relay_base_url == "" or room_code == "":
		push_error("HEARTBEAT_DEADLOCK_FAIL faltou --relay-base-url ou --room-code")
		quit(1)
		return
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		return
	push_error("HEARTBEAT_DEADLOCK_FAIL " + message)
	quit(1)


func _await_idle(timeout_ms: int) -> bool:
	var deadline: int = Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if not bool(game.online_heartbeat_in_flight):
			return true
	return false


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	# Estado minimo para `_online_room_heartbeat_active()` valer.
	game.ONLINE_RELAY_BASE_URL = relay_base_url
	game.is_multiplayer = true
	game.online_connected = true
	game.online_room_owner = true
	game.online_room_code = room_code
	game.player_nickname = "HEARTBEAT_PROBE"
	_check(game._online_room_heartbeat_active(), "o heartbeat nao ficou ativo com o estado montado")
	print("ALVO url=%s%s timeout=%s" % [game.ONLINE_RELAY_BASE_URL, "/rooms/" + room_code + "/heartbeat", str(game.online_heartbeat_request.timeout)])

	# 1) Primeira batida de verdade.
	game._send_online_room_heartbeat("probe_1")
	_check(int(game.online_heartbeat_last_sent_ms) > 0, "a primeira batida nem saiu")
	var first_sent_ms: int = int(game.online_heartbeat_last_sent_ms)
	_check(await _await_idle(15000), "a primeira batida nunca completou")
	_check(int(game.online_heartbeat_last_ok_ms) > 0, "a primeira batida falhou (erro=%s)" % String(game.online_heartbeat_last_error))

	# 2) O estado do cliente HTTP logo depois da resposta e o que decide tudo.
	var busy_after_ok: bool = game._http_request_busy(game.online_heartbeat_request)
	var status_after_ok: int = game.online_heartbeat_request.get_http_client_status()
	print("ESTADO_POS_RESPOSTA busy=%s status=%d" % [str(busy_after_ok), status_after_ok])

	# 3) Passou o intervalo: o jogo deveria bater de novo.
	game.online_heartbeat_last_sent_ms = Time.get_ticks_msec() - int(game.ONLINE_ROOM_HEARTBEAT_INTERVAL_MS) - 1000
	var before_second: int = int(game.online_heartbeat_last_sent_ms)
	game._update_online_room_heartbeat(0.1)
	var sent_second: bool = int(game.online_heartbeat_last_sent_ms) != before_second
	var wedged: bool = not sent_second and bool(game.online_heartbeat_in_flight)

	if wedged:
		# 4) Confirma que nao e so atraso: nenhuma passagem futura recupera.
		var recovered := false
		for i in range(600):
			await process_frame
			game._update_online_room_heartbeat(0.1)
			if int(game.online_heartbeat_last_sent_ms) != before_second:
				recovered = true
				break
		print("HEARTBEAT_DEADLOCK_CONFIRMADO travou=true recuperou=%s status=%d checks=%d" % [str(recovered), status_after_ok, checks])
		_check(false, "o heartbeat travou: marcou in_flight sem disparar requisicao e %s" % ("recuperou depois" if recovered else "nunca mais bateu"))
		return

	_check(sent_second, "a segunda batida nao saiu, mas tambem nao ficou marcada como em voo")
	_check(await _await_idle(15000), "a segunda batida nunca completou")
	_check(int(game.online_heartbeat_fail_count) == 0, "a segunda batida falhou (erro=%s)" % String(game.online_heartbeat_last_error))

	# 5) Terceira batida, agora pelo caminho normal do jogo.
	game.online_heartbeat_last_sent_ms = Time.get_ticks_msec() - int(game.ONLINE_ROOM_HEARTBEAT_INTERVAL_MS) - 1000
	var before_third: int = int(game.online_heartbeat_last_sent_ms)
	game._update_online_room_heartbeat(0.1)
	_check(int(game.online_heartbeat_last_sent_ms) != before_third, "a terceira batida nao saiu")
	_check(await _await_idle(15000), "a terceira batida nunca completou")
	print("HEARTBEAT_DEADLOCK_SMOKE_OK batidas=3 busy_pos_resposta=%s status=%d primeira_ms=%d checks=%d" % [
		str(busy_after_ok), status_after_ok, first_sent_ms, checks,
	])
	quit(0)
