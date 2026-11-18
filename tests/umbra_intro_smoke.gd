extends SceneTree

## Cena de chegada da UMBRA (RTUmbraIntro): roteiro inteiro, baloes, QTE de
## meteoros (acerto e erro), pular, e a passagem direta para a batalha.
## Com "capture" nos argumentos (e janela), salva quadros-chave em .codex/umbra_intro/.
var game: Node
var failed := false
var capture := false
var shots: Dictionary = {}


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("UMBRA_INTRO_FAIL " + msg)


func _initialize() -> void:
	capture = "capture" in OS.get_cmdline_user_args()
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _beat_kind(intro: RTUmbraIntro) -> String:
	if intro.beat >= intro.beats.size():
		return ""
	return String(intro.beats[intro.beat].get("k", ""))


func _shot(name: String) -> void:
	if not capture or shots.has(name):
		return
	shots[name] = true
	game.queue_redraw()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.codex/umbra_intro/%02d_%s.png" % [shots.size(), name])


func _run() -> void:
	await process_frame
	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.codex/umbra_intro"))
		root.size = Vector2i(1280, 720)
	game.startup_thanks_done = true
	game._start_game()
	game._story().queue.clear()
	game._advance_to_phase(5)
	game._story().queue.clear()
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	_check(game.enemies.is_empty(), "fase 5 nao deveria ter inimigos comuns")
	var intro: RTUmbraIntro = game._umbra_intro()
	_check(not intro.plays_cutscene(), "em teste automatizado a cena nao deveria disparar sozinha")
	var hp_before: int = game.player_hp
	intro.start()
	_check(game.mode == RTUmbraIntro.MODE, "modo da cena")
	_check(not game._can_use_combat_input() if game.has_method("_can_use_combat_input") else true, "controles deveriam travar")
	var seen := {}
	var balloons := []
	var qte_presses := 0
	var guard := 0
	var dt := 1.0 / 30.0
	while intro.active and guard < 30 * 120:
		guard += 1
		if capture:
			await process_frame
		else:
			intro.update(dt)
		var k := _beat_kind(intro)
		seen[k] = true
		if not intro.balloon.is_empty():
			var key := String(intro.balloon.get("who", "")) + ":" + String(intro.balloon.get("text", "")).left(16)
			if not balloons.has(key):
				balloons.append(key)
			if not capture and float(intro.balloon.get("hold", 0.0)) > 0.2:
				intro.advance_balloon()
		if intro.qte_waiting():
			# Acerta os 3 primeiros e erra o ultimo.
			if capture:
				await _shot("qte_%d" % intro.qte_index)
			var right := intro.qte_dir()
			var wrong := "up" if right != "up" else "down"
			intro.press(right if intro.qte_index < 3 else wrong)
			qte_presses += 1
		if capture:
			match k:
				"geo_run":
					if intro.t > 0.8: await _shot("geo231_correndo")
				"say":
					await _shot("fala_" + String(intro.balloon.get("who", "")) + "_%d" % intro.beat) if intro.balloon_visible_text().length() > 12 or String(intro.balloon.get("text", "")).length() <= 12 and float(intro.balloon.get("hold", 0.0)) > 0.1 else null
				"boom":
					if intro.t > 0.35: await _shot("estrondo")
				"blast":
					if intro.t > 0.1: await _shot("rajada")
				"erase":
					if intro.t > 0.8: await _shot("apagada")
				"absorb":
					if intro.t > 0.7: await _shot("absorve")
				"summon":
					if intro.t > 1.2: await _shot("meteoro")
				"title":
					if intro.t > 0.8: await _shot("titulo")
	_check(not intro.active, "cena nao terminou")
	for k in ["pan", "portal", "geo_run", "geo_fall", "say", "boom", "chase", "charge", "blast", "erase", "absorb", "turn", "laugh", "summon", "qte", "aftermath", "title"]:
		_check(seen.has(k), "etapa nunca rodou: " + k)
	_check(balloons.size() >= 9, "faltaram baloes: %d" % balloons.size())
	_check(qte_presses == RTUmbraIntro.QTE_COUNT, "qte deveria pedir 4 desvios, pediu %d" % qte_presses)
	_check(intro.qte_dodges == 3 and intro.qte_hits == 1, "resultado do qte %d/%d" % [intro.qte_dodges, intro.qte_hits])
	_check(int(game.player_hp) < hp_before and int(game.player_hp) >= 1, "o meteoro errado deveria machucar sem matar")
	_check(game.mode == "game", "deveria voltar ao jogo")
	_check(game.boss_active and game.boss_name == "UMBRA", "a batalha deveria comecar")
	_check(Vector2(game.boss_pos).distance_to(Vector2(intro.umbra["pos"])) < 2.0, "a UMBRA deveria lutar onde terminou a cena")
	_check(game.enemies.is_empty(), "sem inimigos comuns na batalha")
	# Pular: so depois de ter visto; termina direto na batalha.
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game.mode = "game"
	game._story().seen[RTUmbraIntro.SEEN_KEY] = true
	intro.reset_for_phase()
	intro.start()
	_check(intro.can_skip, "deveria poder pular depois de ver")
	intro.skip()
	_check(not intro.active and game.mode == "game" and game.boss_active, "pular deveria ir direto para a batalha")
	# Resposta da Geovana muda a cada run (rodizio das 5).
	game._story().seen[RTUmbraIntro.REPLY_KEY] = 3
	intro.reset_for_phase()
	intro.start()
	var reply_found := false
	for b in intro.beats:
		if String(b.get("text", "")) == RTUmbraIntro.REPLIES[3]:
			reply_found = true
	_check(reply_found, "resposta da run deveria ser a do rodizio")
	intro.skip()
	if not failed:
		print("UMBRA_INTRO_SMOKE_OK balloons=%d shots=%d" % [balloons.size(), shots.size()])
	quit(1 if failed else 0)
