extends SceneTree

## MISSA DO NINHO (Necrose da UMBRA): incenso evitavel, desajuste, velas,
## coroinhas, comunhao, sino e a ligacao com a rede (feat_miasma / schema).
## Com "capture" (e janela) salva quadros em .codex/necrose/.
var game: Node
var failed := false
var capture := false
var shots := 0


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("NECROSE_MASS_FAIL " + msg)


func _initialize() -> void:
	capture = "capture" in OS.get_cmdline_user_args()
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _new_mass(at: Vector2) -> Dictionary:
	game.phase5_hazards.clear()
	game.boss5_ability_cooldowns["MIASMA"] = 0.0
	game.boss5_authoritative_decision = {}
	game.player_pos = at
	game._spawn_umbra_action("MIASMA")
	var h: Dictionary = RTUmbraNecroseMass.active(game)
	return h


func _step(h: Dictionary, seconds: float, dt: float = 1.0 / 30.0) -> void:
	var n: int = int(round(seconds / dt))
	for i in n:
		h["life"] = float(h["life"]) - dt
		RTUmbraNecroseMass.update(game, h, dt)


func _shot(name: String) -> void:
	if not capture:
		return
	shots += 1
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.codex/necrose/%02d_%s.png" % [shots, name])


func _run() -> void:
	await process_frame
	game.startup_thanks_done = true
	game._start_game()
	game._story().queue.clear()
	game._advance_to_phase(5)
	game._story().queue.clear()
	game.mode = "game"
	game._story().seen[RTUmbraIntro.SEEN_KEY] = true
	var intro: RTUmbraIntro = game._umbra_intro()
	intro.start()
	intro.skip()
	_check(game.boss_active, "batalha")
	game.boss5_dimension = "necrose"
	game.boss5_transmute_hangover = 0.0
	game.boss5_ability_cooldowns["MIASMA"] = 0.0
	_check(game._umbra_available_actions().has("MIASMA"), "MIASMA disponivel na necrose")
	var center: Vector2 = game.experimental_phase_controller.boss_encounter_center()
	game.boss_pos = center + Vector2(-420, -60)
	var at: Vector2 = center + Vector2(120, 80)
	game.player_hp = game.player_hp_max
	game.run_retry_invulnerability_timer = 0.0

	# 1) Criacao e baforadas deterministicas.
	var h := _new_mass(at)
	_check(not h.is_empty() and String(h["kind"]) == "missa", "missa criada")
	_check(Array(h["candles"]).size() == 4 and Array(h["censers"]).size() == 2, "4 velas e 2 turibulos")
	_check(RTUmbraNecroseMass.puffs(h, 0.5).is_empty(), "sem incenso durante o aviso")
	_check(RTUmbraNecroseMass.puffs(h, 3.0).size() > 20, "incenso depois do aviso")
	_check(RTUmbraNecroseMass.puffs(h, 3.0) == RTUmbraNecroseMass.puffs(h, 3.0), "baforadas deterministicas")
	# Rede: a missa acende a entrada do miasma na DQN e no schema.
	var feats: Array = game._umbra_discretizar_estado()
	_check(float(feats[game.BOSS5_DQN_FEATURES.find("hazard_miasma")]) > 0.5, "feat_miasma da DQN")
	var obs: Dictionary = RTUmbraObservationSchema.build_from_runtime(game)
	var idx: int = RTUmbraObservationSchema.feature_names().find("space.hazard.miasma")
	_check(float(obs["values"][idx]) > 0.0, "schema space.hazard.miasma")

	# 2) Ficar no incenso enche o desajuste e inverte os controles.
	_step(h, 1.0)
	var t: float = RTUmbraNecroseMass.elapsed(h)
	var puff: Dictionary = {}
	for p in RTUmbraNecroseMass.live_puffs(h, t + 0.2):
		puff = p
		break
	_check(not puff.is_empty(), "ha incenso vivo para testar")
	var hp0: int = game.player_hp
	var inverted_seen := false
	for i in 60:
		var ps: Array = RTUmbraNecroseMass.live_puffs(h, RTUmbraNecroseMass.elapsed(h))
		if not ps.is_empty():
			game.player_pos = Vector2(ps[ps.size() / 2]["pos"]) - RTUmbraHitbox.FEET
		_step(h, 1.0 / 30.0)
		inverted_seen = inverted_seen or float(game.controls_inverted_timer) > 0.0
	_check(float(h["desajuste"]) > 0.3 or int(h["communions"]) > 0, "incenso enche o desajuste (%.2f)" % float(h["desajuste"]))
	_check(inverted_seen, "desajuste >= 0.5 inverte os controles")
	_check(int(game.player_hp) == hp0 or int(h["communions"]) > 0, "incenso sozinho nao tira vida")

	# 3) A luz das velas limpa e apaga o incenso.
	var candle: Dictionary = h["candles"][0]
	candle["lit"] = true
	game.player_pos = Vector2(candle["pos"]) - RTUmbraHitbox.FEET
	var before: float = float(h["desajuste"])
	_step(h, 0.6)
	_check(float(h["desajuste"]) < before or before <= 0.0, "luz limpa o desajuste")
	for p in RTUmbraNecroseMass.live_puffs(h, RTUmbraNecroseMass.elapsed(h)):
		_check(Vector2(p["pos"]).distance_to(Vector2(candle["pos"])) > RTUmbraNecroseMass.CANDLE_RADIUS, "incenso dentro da luz deveria sumir")

	# 4) Comunhao quando o desajuste enche.
	h["desajuste"] = 0.99
	game.player_pos = at + Vector2(900, 900)
	var hp1: int = game.player_hp
	var boss1: float = game.boss_hp
	game.boss_hp = game.boss_hp_max * 0.5
	boss1 = game.boss_hp
	var ps2: Array = RTUmbraNecroseMass.live_puffs(h, RTUmbraNecroseMass.elapsed(h))
	if not ps2.is_empty():
		game.player_pos = Vector2(ps2[0]["pos"]) - RTUmbraHitbox.FEET
	game.run_retry_invulnerability_timer = 0.0
	_step(h, 0.2)
	_check(int(h["communions"]) >= 1, "comunhao com desajuste cheio")
	_check(game.boss_hp > boss1, "comunhao cura a UMBRA")

	# 5) Coroinhas apagam velas, fogem da Geovana e morrem com tiro.
	var h2 := _new_mass(at)
	game.player_pos = at + Vector2(2000, 2000)
	_step(h2, 4.5)
	var snuffed := 0
	for c in h2["candles"]:
		snuffed += 0 if bool(c["lit"]) else 1
	_check(snuffed >= 1, "coroinhas apagam velas sem protecao")
	var h3 := _new_mass(at)
	_step(h3, 1.3)
	var rats: Array = h3["rats"]
	_check(not rats.is_empty(), "coroinha nasceu")
	if not rats.is_empty():
		var r: Dictionary = rats[0]
		game.player_pos = Vector2(r["pos"]) + Vector2(60, 0) - RTUmbraHitbox.FEET
		var d0: float = Vector2(r["pos"]).distance_to(RTUmbraHitbox.feet(game.player_pos))
		_step(h3, 0.3)
		_check(Vector2(r["pos"]).distance_to(RTUmbraHitbox.feet(game.player_pos)) > d0, "coroinha foge da Geovana")
		_check(RTUmbraNecroseMass.bullet_hit(game, Vector2(r["pos"])), "tiro mata coroinha")
	# Reacender: ficar ao lado da vela apagada.
	var off: Dictionary = h3["candles"][1]
	off["lit"] = false
	game.player_pos = Vector2(off["pos"]) - RTUmbraHitbox.FEET
	_step(h3, RTUmbraNecroseMass.RELIGHT_TIME + 0.1)
	_check(bool(off["lit"]), "vela reacende com a Geovana ao lado")

	# 6) Sino: na luz nao toma dano; fora toma proporcional ao desajuste.
	var h4 := _new_mass(at)
	var c4: Dictionary = h4["candles"][2]
	for c in h4["candles"]:
		c["lit"] = true
	h4["rat_timer"] = 999.0
	_step(h4, 8.0)
	game.player_pos = Vector2(c4["pos"]) - RTUmbraHitbox.FEET
	game.player_hp = game.player_hp_max
	game.run_retry_invulnerability_timer = 0.0
	_step(h4, 0.7)
	_check(float(h4["bell_hit"]) == 0.0 and int(game.player_hp) == int(game.player_hp_max), "sino nao fere na luz")
	var h5 := _new_mass(at)
	h5["rat_timer"] = 999.0
	_step(h5, 8.0)
	game.player_pos = at + Vector2(0, 700)
	h5["desajuste"] = 0.5
	game.player_hp = game.player_hp_max
	game.run_retry_invulnerability_timer = 0.0
	_step(h5, 0.7)
	_check(float(h5["bell_hit"]) > 0.05, "sino fere fora da luz")
	# 7) Apolo enxerga a luz como segura.
	var danger_light: float = RTUmbraNecroseMass.danger_at(h5, Vector2(h5["candles"][0]["pos"]) - RTUmbraHitbox.FEET, 0.0) if bool(h5["candles"][0]["lit"]) else 0.0
	var danger_out: float = RTUmbraNecroseMass.danger_at(h5, at + Vector2(0, 700), 0.0)
	_check(danger_light <= danger_out, "perigo menor na luz")
	game.phase5_hazards.clear()
	game.controls_inverted_timer = 0.0

	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.codex/necrose"))
		root.size = Vector2i(1280, 720)
		game.set_process(false)
		game.effects.clear()
		game.player_hp = game.player_hp_max
		var hc := _new_mass(at)
		game.player_pos = at + Vector2(-40, 30)
		game.camera_follow_center = at
		for mark in [0.5, 2.2, 4.0, 5.5, 6.8, 8.62]:
			_step(hc, mark - RTUmbraNecroseMass.elapsed(hc))
			game.time_alive += 0.5
			if mark > 5.0:
				hc["desajuste"] = 0.62
				hc["inverted"] = true
			game.effects.clear()
			game.player_hp = game.player_hp_max
			await _shot("missa_%.1f" % mark)
	if not failed:
		print("NECROSE_MASS_SMOKE_OK shots=%d" % shots)
	quit(1 if failed else 0)
