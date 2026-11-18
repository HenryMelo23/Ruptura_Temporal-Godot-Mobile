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
var args := {"budget": 150, "seconds": 45.0, "epsilon": 0.3, "seed": 1, "out": "res://.agent_logs/umbra_train/samples.jsonl", "lead_jitter": 0.25, "nomind": 0, "episodes": 0, "mind": ""}
var candidate: Dictionary = {}
var candidate_sha256 := ""


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var a: String = String(raw)
		if a.begins_with("--") and a.contains("="):
			var kv: PackedStringArray = a.substr(2).split("=", true, 1)
			match kv[0]:
				"seconds", "epsilon", "lead_jitter":
					args[kv[0]] = float(kv[1])
				"out", "mind":
					args[kv[0]] = kv[1]
				_:
					args[kv[0]] = int(kv[1])
	RTUmbraMind.training_mode = true
	if String(args["mind"]) != "":
		var path := String(args["mind"])
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary or not _valid_candidate(parsed) or int(args["nomind"]) != 0:
			push_error("UMBRA_COLLECT: invalid candidate or conflicting --nomind")
			quit(2)
			return
		candidate = parsed
		candidate_sha256 = FileAccess.get_sha256(path)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	# A laboratory episode must never start a ranked security/upload session.
	game.set_process(false)
	game.set_physics_process(false)
	game.run_security_start_request = null
	game.run_report_request = null
	game.run_leaderboard_request = null
	call_deferred("_run")


func _run() -> void:
	await process_frame
	# Main._ready can run after SceneTree._initialize; isolate after readiness.
	game.set_process(false)
	game.set_physics_process(false)
	game.run_security_start_request = null
	game.run_report_request = null
	game.run_leaderboard_request = null
	var out_path: String = ProjectSettings.globalize_path(String(args["out"]))
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		push_error("UMBRA_COLLECT: cannot open output")
		quit(2)
		return
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
		res["episode"] = ep_seed
		res["plasma_hits"] = res["hits"]
		res["record_type"] = "episode"
		res["opponent"] = "godot_exhibition_heuristic_not_python_dqn"
		res["candidate_sha256"] = candidate_sha256
		res["policy_source"] = "candidate" if not candidate.is_empty() else ("zero" if int(args["nomind"]) > 0 else "bundled_base")
		file.store_line(JSON.stringify(res))
		episodes += 1
	file.close()
	print("UMBRA_EVAL episodes=%d mean_dealt=%.4f mean_taken=%.4f kills=%d score=%.4f" % [episodes, tot_dealt / maxf(1.0, episodes), tot_taken / maxf(1.0, episodes), kills, (10.0 * tot_dealt - 30.0 * tot_taken) / maxf(1.0, episodes)])
	print("UMBRA_COLLECT episodes=%d samples=%d secs=%d lead=%s" % [episodes, samples, (Time.get_ticks_msec() - t0) / 1000, JSON.stringify(summary["lead"])])
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	quit(0)


func _episode(seed: int, r: RandomNumberGenerator, file: FileAccess) -> Dictionary:
	var opp := RandomNumberGenerator.new()
	opp.seed = seed
	var manif: int = opp.randi_range(0, 5)
	game.rng.seed = seed
	game.start_apolo_phase5_exhibition(manif)
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.shop_auto_enabled = false
	game.run_report_sent = true
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
	elif not candidate.is_empty():
		mind.reset_weights()
		mind.apply_layer(candidate, 1.0)
		mind.version = String(candidate.get("version", "candidate"))
	# Isolate the fitted linear mind: a production neural policy may override it.
	game.boss5_multihead_policy = null
	game.boss5_dqn_weights.clear()
	game.boss5_neural_runtime = null
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
	var simulation_start: float = float(game.time_alive)
	var limit: int = int(float(args["seconds"]) / DT)
	var pending: Array = []
	var dealt_acc := 0.0
	var taken_acc := 0.0
	var frames := 0
	var samples := 0
	var shots := 0
	var hits := 0
	var action_counts: Dictionary = {}
	var bonus_l1 := 0.0
	# Bot "humano": de vez em quando demora a reagir (fica parado ~0,4 s).
	var skill: float = opp.randf_range(0.5, 0.95)
	var freeze := 0
	var last_seq: int = int(game.umbra_authority_controller.next_sequence)
	while frames < limit and not game.is_dead and float(game.boss_hp) > 0.0 and int(game.player_hp) > 0:
		var hp_b: float = float(game.player_hp)
		var boss_b: float = float(game.boss_hp)
		var feats: PackedFloat32Array = mind.features().duplicate()
		for action in RTUmbraMind.ACTIONS:
			var bonus := 0.0
			var row: Array = mind.weights[action]
			for i in range(feats.size()):
				bonus += float(row[i]) * feats[i]
			bonus_l1 += absf(clampf(bonus, -RTUmbraMind.MAX_BONUS, RTUmbraMind.MAX_BONUS))
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
			action_counts[action] = int(action_counts.get(action, 0)) + 1
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
	return {"dealt": dealt_acc, "taken": taken_acc, "samples": samples, "lead": lead, "shots": shots, "hits": hits, "dead": game.is_dead or int(game.player_hp) <= 0, "t": float(frames) * DT,
		"simulation_seconds": float(game.time_alive) - simulation_start,
		"umbra_dead": float(game.boss_hp) <= 0.0, "player_hp_final": game.player_hp, "boss_hp_final": game.boss_hp,
		"manifestation_index": manif, "actions": action_counts, "bonus_l1": snappedf(bonus_l1, 0.0001),
		"score": 10.0 * dealt_acc - 30.0 * taken_acc}


func _valid_candidate(data: Dictionary) -> bool:
	if int(data.get("schema_version", -1)) != RTUmbraMind.SCHEMA_VERSION or Array(data.get("features", [])) != RTUmbraMind.FEATURES:
		return false
	if String(data.get("mode", "add")) != "add":
		return false
	if data.has("aim_lead"):
		var aim = data["aim_lead"]
		if not (aim is float or aim is int) or not is_finite(float(aim)) or float(aim) < 0.2 or float(aim) > 1.1:
			return false
	var w: Dictionary = Dictionary(data.get("weights", {}))
	if w.is_empty():
		return false
	for action in w:
		if not RTUmbraMind.ACTIONS.has(action) or not w[action] is Array or Array(w[action]).size() != RTUmbraMind.FEATURES.size():
			return false
		for value in w[action]:
			if not (value is float or value is int) or not is_finite(float(value)):
				return false
	return true


func _flush(file: FileAccess, p: Dictionary, dealt: float, taken: float, seed: int) -> void:
	var f: Array = []
	for v in PackedFloat32Array(p["f"]):
		f.append(snappedf(v, 0.001))
	file.store_line(JSON.stringify({
		"a": p["a"], "f": f, "dealt": snappedf(dealt - float(p["d0"]), 0.0001),
		"taken": snappedf(taken - float(p["k0"]), 0.0001), "x": p["x"], "ep": seed,
	}))
