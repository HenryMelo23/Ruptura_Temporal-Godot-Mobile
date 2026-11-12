extends SceneTree

## Coleta de experiencia da UMBRA contra o bot Apolo (headless).
## Cada decisao vira uma amostra: contexto (RTUmbraMind.FEATURES), acao e
## resultado nos 3 s seguintes (dano causado ao jogador - dano sofrido).
## Explora com probabilidade --epsilon escolhendo uma acao legal aleatoria.
## O ajuste (regressao) e feito por tools/umbra_mind_fit.py.
##
## godot --headless --path . --script res://tools/umbra_mind_collect.gd -- \
##   --budget=150 --seconds=45 --epsilon=0.3 --seed=1 --out=res://.agent_logs/umbra_train/samples_01.jsonl

const DT := 1.0 / 30.0
const WINDOW := 3.0

var game: Node
var args := {"budget": 150, "seconds": 45.0, "epsilon": 0.3, "seed": 1, "out": "res://.agent_logs/umbra_train/samples.jsonl", "lead_jitter": 0.25, "nomind": 0, "episodes": 0}


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var a: String = String(raw)
		if a.begins_with("--") and a.contains("="):
			var kv: PackedStringArray = a.substr(2).split("=", true, 1)
			match kv[0]:
				"seconds", "epsilon", "lead_jitter":
					args[kv[0]] = float(kv[1])
				"out":
					args[kv[0]] = kv[1]
				_:
					args[kv[0]] = int(kv[1])
	RTUmbraMind.training_mode = true
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var out_path: String = ProjectSettings.globalize_path(String(args["out"]))
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	var r := RandomNumberGenerator.new()
	r.seed = int(args["seed"])
	var t0 := Time.get_ticks_msec()
	var episodes := 0
	var samples := 0
	var summary := {"lead": {}}
	var tot_dealt := 0.0
	var tot_taken := 0.0
	var kills := 0
	while (Time.get_ticks_msec() - t0) / 1000 < int(args["budget"]) and (int(args["episodes"]) <= 0 or episodes < int(args["episodes"])):
		var ep_seed: int = int(args["seed"]) * 100003 + episodes
		var res: Dictionary = _episode(ep_seed, r, file)
		samples += int(res["samples"])
		tot_dealt += float(res["dealt"])
		tot_taken += float(res["taken"])
		kills += 1 if bool(res["dead"]) else 0
		var lk: String = "%.2f" % float(res["lead"])
		var row: Dictionary = summary["lead"].get(lk, {"shots": 0, "hits": 0})
		row["shots"] = int(row["shots"]) + int(res["shots"])
		row["hits"] = int(row["hits"]) + int(res["hits"])
		summary["lead"][lk] = row
		file.store_line(JSON.stringify({"episode": ep_seed, "lead": res["lead"], "shots": res["shots"], "plasma_hits": res["hits"], "dead": res["dead"], "t": res["t"]}))
		episodes += 1
	file.close()
	print("UMBRA_EVAL episodes=%d mean_dealt=%.4f mean_taken=%.4f kills=%d score=%.4f" % [episodes, tot_dealt / maxf(1.0, episodes), tot_taken / maxf(1.0, episodes), kills, (10.0 * tot_dealt - 30.0 * tot_taken) / maxf(1.0, episodes)])
	print("UMBRA_COLLECT episodes=%d samples=%d secs=%d lead=%s" % [episodes, samples, (Time.get_ticks_msec() - t0) / 1000, JSON.stringify(summary["lead"])])
	quit(0)


func _episode(seed: int, r: RandomNumberGenerator, file: FileAccess) -> Dictionary:
	var opp := RandomNumberGenerator.new()
	opp.seed = seed
	var manif: int = opp.randi_range(0, 5)
	game.rng.seed = seed
	game.start_apolo_phase5_exhibition(manif)
	game.set_process(false)
	game.set_physics_process(false)
	game.mode = "game"
	for k in game.boss5_mobile_weights.keys():
		game.boss5_mobile_weights[k] = 0.0
	game.boss5_predatory_mods.clear()
	game.boss5_profile_confidence = 0.0
	var mind: RTUmbraMind = game._umbra_mind()
	mind.load_layers(false)
	if int(args["nomind"]) > 0:
		mind.reset_weights()
	var lead: float = clampf(mind.aim_lead + snappedf(opp.randf_range(-1.0, 1.0) * float(args["lead_jitter"]), 0.05), 0.2, 1.1)
	mind.aim_lead = lead
	RTUmbraMind.explore_epsilon = float(args["epsilon"])
	RTUmbraMind.explore_rng = r
	var skills: RTUmbraBaseSkills = game._umbra_base_skills()
	skills.reset_encounter()
	skills.bot_rewind_reflex = opp.randf_range(0.25, 0.95)
	game.player_hp_max = int(opp.randf_range(2000.0, 3400.0))
	game.player_hp = game.player_hp_max
	var ttk: float = opp.randf_range(140.0, 260.0)
	var interval: float = maxf(0.08, float(game._current_attack_interval()))
	game.player_damage = float(game.boss_hp_max) / ttk * interval / 0.55
	var hp_max: float = float(game.player_hp_max)
	var boss_max: float = float(game.boss_hp_max)
	var limit: int = int(float(args["seconds"]) / DT)
	var pending: Array = []
	var dealt_acc := 0.0
	var taken_acc := 0.0
	var frames := 0
	var samples := 0
	var shots := 0
	var hits := 0
	# Bot "humano": de vez em quando demora a reagir (fica parado ~0,4 s).
	var skill: float = opp.randf_range(0.5, 0.95)
	var freeze := 0
	var last_seq: int = int(game.umbra_authority_controller.next_sequence)
	while frames < limit and not game.is_dead and float(game.boss_hp) > 0.0 and int(game.player_hp) > 0:
		var hp_b: float = float(game.player_hp)
		var boss_b: float = float(game.boss_hp)
		var feats: PackedFloat32Array = mind.features().duplicate()
		if freeze > 0:
			freeze -= 1
			if freeze == 0:
				game.apolo_phase5_exhibition_enabled = true
		elif frames % 15 == 0 and opp.randf() > skill:
			freeze = 12
			game.apolo_phase5_exhibition_enabled = false
			game.apolo_phase5_exhibition_move = Vector2.ZERO
		var plasma: Array = []
		for b in game.enemy_bullets:
			if String(b.get("type", "")) == "umbra_plasma" and float(b.get("life", 0.0)) > 0.15:
				plasma.append(b)
		game._process(DT)
		# Plasma que sumiu antes da hora perto do jogador = acerto.
		for b in plasma:
			if (float(b.get("life", 0.0)) <= 0.0 or not game.enemy_bullets.has(b)) and Vector2(b["pos"]).distance_to(game.player_pos) < 90.0:
				hits += 1
		frames += 1
		dealt_acc += maxf(0.0, hp_b - float(game.player_hp)) / hp_max
		taken_acc += maxf(0.0, boss_b - float(game.boss_hp)) / boss_max
		var seq: int = int(game.umbra_authority_controller.next_sequence)
		if seq != last_seq:
			last_seq = seq
			var action: String = String(game.boss5_current_action)
			if action == "ATAQUE":
				shots += 1
			if RTUmbraMind.ACTIONS.has(action):
				pending.append({"a": action, "f": feats, "t": frames, "d0": dealt_acc, "k0": taken_acc, "x": RTUmbraMind.last_explored})
		while not pending.is_empty() and frames - int(pending[0]["t"]) >= int(WINDOW / DT):
			_flush(file, pending.pop_front(), dealt_acc, taken_acc, seed)
			samples += 1
	for p in pending:
		_flush(file, p, dealt_acc, taken_acc, seed)
		samples += 1
	RTUmbraMind.explore_epsilon = 0.0
	return {"dealt": dealt_acc, "taken": taken_acc, "samples": samples, "lead": lead, "shots": shots, "hits": hits, "dead": game.is_dead or int(game.player_hp) <= 0, "t": float(frames) * DT}


func _flush(file: FileAccess, p: Dictionary, dealt: float, taken: float, seed: int) -> void:
	var f: Array = []
	for v in PackedFloat32Array(p["f"]):
		f.append(snappedf(v, 0.001))
	file.store_line(JSON.stringify({
		"a": p["a"], "f": f, "dealt": snappedf(dealt - float(p["d0"]), 0.0001),
		"taken": snappedf(taken - float(p["k0"]), 0.0001), "x": p["x"], "ep": seed,
	}))
