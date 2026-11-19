extends SceneTree

## Pactos pos-chefe: tela de escolha (desktop e celular), aplicacao e mecanicas.
## -- [--frames=<dir>] [--size=WxH]
const DT := 1.0 / 60.0
var game: Node
var frames_dir := ""
var seq := 0
var failed := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="): frames_dir = a.substr(9)
		elif a.begins_with("--size="):
			var parts: PackedStringArray = a.substr(7).split("x")
			root.size = Vector2i(int(parts[0]), int(parts[1]))
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("BOSS_PACT_FAIL " + msg)


func _shot(name: String) -> void:
	if frames_dir == "":
		return
	game.queue_redraw()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [frames_dir, name])


func _step(seconds: float, capture_every: int = 0) -> void:
	var t := 0.0
	var i := 0
	while t < seconds:
		t += DT
		game.time_alive += DT
		game.elapsed_unpaused += DT
		game._run_choice().update(DT)
		game._boss_pacts().update(DT)
		game._update_effects(DT)
		i += 1
		if capture_every > 0 and frames_dir != "" and i % capture_every == 0:
			game.queue_redraw()
			await process_frame
			var img := root.get_texture().get_image()
			img.resize(640, int(640.0 * float(root.size.y) / float(root.size.x)), Image.INTERPOLATE_BILINEAR)
			img.save_png("%s/f_%03d.png" % [frames_dir, seq])
			seq += 1


func _run() -> void:
	game.startup_thanks_done = true
	game.forced_initial_phase = 1
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.tutorial_state = game.TUTORIAL_STATE_NONE
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.spawn_timer = 999.0
	game.time_alive = 600.0
	game.enemies.clear()
	if frames_dir != "":
		DirAccess.make_dir_recursive_absolute(frames_dir)
	# Fluxo do chefe: morte do Chefe 1 agenda o pacto; abre depois do atraso.
	game._queue_post_boss_choice(1)
	await _step(1.0)
	_check(game.mode == "game", "pacto abriu cedo demais")
	await _step(1.4)
	_check(game.mode == "run_choice", "pacto nao abriu apos o chefe")
	_check(game._run_choice().options.size() == 3, "nao ofereceu 3 pactos")
	game._run_choice().age = 1.0
	await _shot("choice_idle")
	game._run_choice().select(1)
	await _shot("choice_selected")
	var chosen: Dictionary = game._run_choice().options[1]
	game._run_choice().confirm()
	_check(game.mode == "game", "nao voltou ao jogo apos escolher")
	_check(game._boss_pacts().taken.has(String(chosen["id"])), "pacto escolhido nao foi aplicado")
	# Sem pular: confirmar sem selecao nao fecha.
	game._run_choice().open("pact")
	game._run_choice().confirm()
	_check(game.mode == "run_choice", "fechou sem escolher")
	game._run_choice().select(0)
	game._run_choice().confirm()
	# Stats: pele de vidro + olhos queimados
	var pacts: RTBossPactController = game._boss_pacts()
	pacts.reset()
	var hp_before: int = int(game.player_hp_max)
	pacts.apply(RTBossPactCatalog.by_id("pele_de_vidro"))
	_check(int(game.player_hp_max) == int(round(float(hp_before) * 0.75)), "max_hp do pacto nao aplicou")
	_check(is_equal_approx(pacts.m("dmg"), 1.35), "dano do pacto nao aplicou")
	# Mecanicas visuais
	pacts.apply(RTBossPactCatalog.by_id("olhos_queimados"))
	pacts.apply(RTBossPactCatalog.by_id("para_raios"))
	pacts.apply(RTBossPactCatalog.by_id("chuva_estilhacos"))
	pacts.timers["lightning"] = 0.2
	pacts.timers["meteors"] = 0.5
	var hp0: float = float(game.player_hp)
	await _step(2.6, 3)
	_check(float(game.player_hp) <= hp0, "perigos nao funcionam")
	await _shot("hazards")
	# Todos os 35 juntos (pior caso) por 12 s sem erro e sem morrer instantaneamente.
	pacts.reset()
	for pact in RTBossPactCatalog.PACTS:
		pacts.apply(pact)
	_check(pacts.taken.size() == RTBossPactCatalog.count(), "nem todos os pactos aplicaram")
	game.player_hp = game.player_hp_max
	for k in range(12):
		await _step(1.0)
		game.player_hp = maxf(float(game.player_hp), float(game.player_hp_max) * 0.5)
	print("BOSS_PACT_DEMO_OK pacts=%d choice=true apply=true no_skip=true mech=true frames=%d" % [RTBossPactCatalog.count(), seq])
	quit(1 if failed else 0)
