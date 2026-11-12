extends SceneTree

## Mente da UMBRA: camada base, camada coletiva (blend), priors, encontro
## (estatisticas para a VPS), camada do jogador, observador de fases e
## campo umbra_combat no relatorio da run.

var game: Node
var checks := 0


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		push_error("UMBRA_MIND_LAYERS_FAIL " + msg)
		quit(1)


func _write(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()


func _run() -> void:
	await process_frame
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	var mind: RTUmbraMind = game._umbra_mind()
	_check(mind.user_dir == "user://umbra_mind_test/", "teste usando pasta real do usuario")
	for f in [mind.collective_path(), mind.player_path()]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))

	# Base treinada carregada.
	mind.load_layers(true)
	_check(mind.layers.has("base"), "camada base nao carregou")
	var base_w: float = float(mind.weights["REBOBINAR"][0])
	_check(absf(base_w) > 0.001, "pesos da base vazios")

	# Coletiva em blend: anda metade do caminho ate o valor da camada.
	var w := {}
	var row: Array = []
	row.resize(RTUmbraMind.FEATURES.size())
	row.fill(0.0)
	row[0] = 2.0
	w["REBOBINAR"] = row
	_write(mind.collective_path(), {"schema_version": 1, "mode": "blend", "confidence": 0.5, "weights": w, "runs": 12, "skill_priors": {"eco_along": [0.4, 30], "rewind_escape": [0.8, 10]}, "aim_lead": 0.6})
	mind.load_layers(true)
	_check(mind.layers.has("coletiva"), "camada coletiva nao carregou")
	_check(absf(float(mind.weights["REBOBINAR"][0]) - lerpf(base_w, 2.0, 0.5)) < 0.01, "blend da coletiva errado")
	_check(absf(mind.aim_lead - 0.6) < 0.001, "aim_lead da coletiva nao aplicado")
	_check(mind.skill_priors.has("eco_along") and absf(float(mind.skill_priors["eco_along"][0]) - 0.4) < 0.001, "prior coletivo ausente")

	# Fases: observador mede desvio quando um tiro vem na direcao do jogador.
	var obs: RTUmbraPhaseObserver = game._umbra_phase_observer()
	obs.reset_run()
	game.mode = "game"
	game.current_phase = 1
	game.is_multiplayer = false
	game.set_process(false)
	var vel := Vector2(200, 0)
	for rep in range(4):
		game.enemy_bullets.clear()
		obs.cooldown = 0.0
		obs.history.clear()
		for i in range(6):
			game.time_alive += 0.1
			game.player_pos += vel * 0.1
			obs.sample_timer = 0.0
			obs.update(0.1)
		game.enemy_bullets.append({"pos": game.player_pos + Vector2(0, -180), "dir": Vector2(0, 1), "type": "probe", "life": 2.0})
		game.time_alive += 0.1
		game.player_pos += vel * 0.1
		obs.sample_timer = 0.0
		obs.update(0.1)
		_check(not obs.probe.is_empty(), "observador nao abriu sonda (rep %d)" % rep)
		# Desvia para a esquerda da corrida (-orthogonal de +x = (0,-1)? orthogonal(1,0) = (0,-1)).
		var side_dir: Vector2 = -vel.normalized().orthogonal()
		for i in range(12):
			game.time_alive += 0.1
			game.player_pos += (vel * 0.4 + side_dir * 160.0) * 0.1
			obs.sample_timer = 0.0
			obs.update(0.1)
	_check(obs.samples("side") >= 4, "amostras de desvio nao contadas")
	_check(obs.mean("side", 0.0) < -0.5, "lado do desvio errado (%.2f)" % obs.mean("side", 0.0))
	_check(obs.mean("along", 1.0) < 0.6, "along nao refletiu a freada (%s)" % str(obs.stats))
	var pri: Dictionary = obs.priors()
	_check(pri.has("eco_side") and pri.has("eco_along"), "priors do observador ausentes")
	game._advance_to_phase(2)
	_check(obs.pending_text.contains("ESQUERDA"), "licao da fase nao saiu: " + obs.pending_text)
	var texts_before: int = game.floating_texts.size() if "floating_texts" in game else 0
	game.mode = "game"
	obs.update(2.0)
	_check(obs.pending_text == "", "licao nao foi mostrada")
	_check(obs.lessons.size() == 1, "licao nao registrada")

	# Encontro: priors entram no kit base e as decisoes viram estatistica.
	game._advance_to_phase(5)
	game.mode = "game"
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 30000.0
	game.boss_hp = 30000.0
	game.player_hp_max = 1000
	game.player_hp = 1000
	game._reset_phase5_state()
	var learned: Dictionary = game._umbra_base_skills().learned
	_check(float(learned["eco_side"]) < -0.4, "prior das fases nao entrou no eco (%.2f)" % float(learned["eco_side"]))
	# Coletivo diz 0.8 (10 amostras); as fases viram 0 teleportes em 4 sustos (peso 2) -> mistura.
	_check(float(learned["rewind_escape"]) > 0.3 and float(learned["rewind_escape"]) < 0.6, "prior do rebobinar nao misturou coletivo+fases (%.2f)" % float(learned["rewind_escape"]))
	_check(mind.enc_active, "encontro nao comecou")
	for k in range(6):
		mind.on_decision("ATAQUE" if k % 2 == 0 else "REBOBINAR")
		for i in range(30):
			if i == 10:
				game.player_hp -= 40
			mind.track(0.1)
	mind.note_player_damage("umbra_plasma")
	mind.finish_encounter("umbra_defeated", learned)
	var rep: Dictionary = mind.last_report
	_check(rep.has("actions") and Dictionary(rep["actions"]).has("ATAQUE"), "relatorio sem acoes")
	var at: Dictionary = rep["actions"]["ATAQUE"]
	_check(Array(at["xtx"]).size() == RTUmbraMind.FEATURES.size() * RTUmbraMind.FEATURES.size(), "xtx com tamanho errado")
	_check(int(at["n"]) == 3, "contagem de decisoes errada (%d)" % int(at["n"]))
	_check(int(rep["plasma"]["shots"]) == 3 and int(rep["plasma"]["hits"]) == 1, "contagem de plasma errada")
	_check(FileAccess.file_exists(mind.player_path()), "camada do jogador nao gravada")
	mind.load_layers(true)
	_check(mind.layers.has("jogador"), "camada do jogador nao carregou")

	# Relatorio da run leva umbra_combat (VPS).
	var payload: Dictionary = game._build_run_report_payload("victory")
	_check(payload.has("umbra_combat") and Dictionary(payload["umbra_combat"]).has("actions"), "payload sem umbra_combat")
	_check(payload.has("umbra_phase_lessons") and Array(payload["umbra_phase_lessons"]).size() >= 1, "payload sem licoes")
	for f in [mind.collective_path(), mind.player_path()]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	print("UMBRA_MIND_LAYERS_OK checks=%d layers=%s aim=%.3f" % [checks, str(mind.layers), mind.aim_lead])
	quit(0)
