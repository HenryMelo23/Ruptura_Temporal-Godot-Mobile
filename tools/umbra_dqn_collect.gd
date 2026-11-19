extends SceneTree

## Coleta de transicoes para a DQN da UMBRA (24 entradas -> 23 acoes) no
## simulador real da fase 5 (headless), contra o bot Apolo.
## Cada decisao da UMBRA vira (s, mascara, a, r, s', mascara', fim):
##   s  = _umbra_discretizar_estado() no quadro da decisao (o mesmo vetor que a
##        rede recebe no jogo), mascara = acoes legais naquele instante;
##   r  = 10*(dano causado / vida max do jogador) - 30*(dano sofrido / vida max
##        da UMBRA) ate a decisao seguinte (o mesmo retorno da mente da UMBRA).
## Politica de coleta: a decisao normal do jogo (heuristica + mente + DQN se
## --dqn for passado) com exploracao epsilon entre acoes legais.
##
## godot --headless --path . --script res://tools/umbra_dqn_collect.gd -- \
##   --episodes=20 --seconds=60 --epsilon=0.3 --seed=1 --out=res://.agent_logs/umbra_dqn/t_01.jsonl [--dqn=res://...json] [--nodqn=1]

const DT := 1.0 / 30.0

var game: Node
var args := {"episodes": 10, "seconds": 60.0, "epsilon": 0.3, "seed": 1, "out": "res://.agent_logs/umbra_dqn/transitions.jsonl", "dqn": "", "nodqn": 1, "lead_jitter": 0.2, "eval": 0}


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var a: String = String(raw)
		if a.begins_with("--") and a.contains("="):
			var kv: PackedStringArray = a.substr(2).split("=", true, 1)
			match kv[0]:
				"seconds", "epsilon", "lead_jitter":
					args[kv[0]] = float(kv[1])
				"out", "dqn":
					args[kv[0]] = kv[1]
				_:
					args[kv[0]] = int(kv[1])
	RTUmbraMind.training_mode = true
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.run_security_start_request = null
	game.run_report_request = null
	game.run_leaderboard_request = null
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.run_security_start_request = null
	game.run_report_request = null
	game.run_leaderboard_request = null
	var dqn: Dictionary = {}
	if String(args["dqn"]) != "":
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(String(args["dqn"])))
		if not parsed is Dictionary or game._umbra_dqn_contract_error(parsed) != "":
			push_error("UMBRA_DQN_COLLECT: modelo invalido " + String(args["dqn"]))
			quit(2)
			return
		dqn = parsed
	var out_path: String = ProjectSettings.globalize_path(String(args["out"]))
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	var r := RandomNumberGenerator.new()
	r.seed = int(args["seed"])
	var t0 := Time.get_ticks_msec()
	var totals := {"dealt": 0.0, "taken": 0.0, "kills": 0, "umbra_deaths": 0, "transitions": 0, "score": 0.0}
	for ep in range(int(args["episodes"])):
		var seed: int = int(args["seed"]) * 100003 + ep
		var res: Dictionary = _episode(seed, r, file, dqn)
		res["record_type"] = "episode"
		res["episode"] = seed
		res["policy"] = "dqn" if not dqn.is_empty() else "fallback"
		file.store_line(JSON.stringify(res))
		totals["dealt"] = float(totals["dealt"]) + float(res["dealt"])
		totals["taken"] = float(totals["taken"]) + float(res["taken"])
		totals["kills"] = int(totals["kills"]) + (1 if bool(res["player_dead"]) else 0)
		totals["umbra_deaths"] = int(totals["umbra_deaths"]) + (1 if bool(res["umbra_dead"]) else 0)
		totals["transitions"] = int(totals["transitions"]) + int(res["transitions"])
		totals["score"] = float(totals["score"]) + float(res["score"])
	file.close()
	var n: float = maxf(1.0, float(args["episodes"]))
	print("UMBRA_DQN_COLLECT episodes=%d transitions=%d mean_dealt=%.4f mean_taken=%.4f kills=%d umbra_deaths=%d mean_score=%.4f secs=%d policy=%s" % [int(args["episodes"]), int(totals["transitions"]), float(totals["dealt"]) / n, float(totals["taken"]) / n, int(totals["kills"]), int(totals["umbra_deaths"]), float(totals["score"]) / n, (Time.get_ticks_msec() - t0) / 1000, "dqn" if not dqn.is_empty() else "fallback"])
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	quit(0)


func _mask(available: Array) -> Array:
	var m: Array = []
	for a in game.BOSS5_ACTIONS:
		m.append(1 if available.has(a) else 0)
	return m


func _round(values: Array) -> Array:
	var out: Array = []
	for v in values:
		out.append(snappedf(float(v), 0.0001))
	return out


func _episode(seed: int, r: RandomNumberGenerator, file: FileAccess, dqn: Dictionary) -> Dictionary:
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
	game.boss5_multihead_policy = null
	game.boss5_dqn_weights = dqn.duplicate(true)
	game.boss5_neural_runtime = null
	mind.aim_lead = clampf(mind.aim_lead + snappedf(opp.randf_range(-1.0, 1.0) * float(args["lead_jitter"]), 0.05), 0.2, 1.1)
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
	var dealt := 0.0
	var taken := 0.0
	var frames := 0
	var transitions := 0
	var open: Dictionary = {}
	var action_counts: Dictionary = {}
	var skill: float = opp.randf_range(0.5, 0.95)
	var freeze := 0
	var last_seq: int = int(game.umbra_authority_controller.next_sequence)
	var feats: Array = []
	var avail: Array = []
	while frames < limit and not game.is_dead and float(game.boss_hp) > 0.0 and int(game.player_hp) > 0:
		feats = game._umbra_discretizar_estado()
		avail = game._umbra_available_actions()
		var hp_b: float = float(game.player_hp)
		var boss_b: float = float(game.boss_hp)
		if freeze > 0:
			freeze -= 1
			if freeze == 0:
				game.apolo_phase5_exhibition_enabled = true
		elif frames % 15 == 0 and opp.randf() > skill:
			freeze = 12
			game.apolo_phase5_exhibition_enabled = false
			game.apolo_phase5_exhibition_move = Vector2.ZERO
		game._process(DT)
		frames += 1
		dealt += maxf(0.0, hp_b - float(game.player_hp)) / hp_max
		taken += maxf(0.0, boss_b - float(game.boss_hp)) / boss_max
		var seq: int = int(game.umbra_authority_controller.next_sequence)
		if seq != last_seq:
			last_seq = seq
			var action: String = String(game.boss5_current_action)
			var ai: int = game.BOSS5_ACTIONS.find(action)
			if ai < 0:
				continue
			action_counts[action] = int(action_counts.get(action, 0)) + 1
			if not open.is_empty():
				_close(file, open, feats, _mask(avail), dealt, taken, false, false)
				transitions += 1
			open = {"s": _round(feats), "m": _mask(avail), "a": ai, "d0": dealt, "k0": taken, "x": RTUmbraMind.last_explored, "dim": String(game.boss5_dimension), "ep": seed, "t": frames}
	var terminal: bool = game.is_dead or int(game.player_hp) <= 0 or float(game.boss_hp) <= 0.0
	if not open.is_empty():
		_close(file, open, game._umbra_discretizar_estado(), _mask(game._umbra_available_actions()), dealt, taken, terminal, not terminal)
		transitions += 1
	RTUmbraMind.explore_epsilon = 0.0
	return {"dealt": dealt, "taken": taken, "transitions": transitions, "frames": frames, "player_dead": game.is_dead or int(game.player_hp) <= 0,
		"umbra_dead": float(game.boss_hp) <= 0.0, "manifestation_index": manif, "actions": action_counts, "score": 10.0 * dealt - 30.0 * taken}


func _close(file: FileAccess, open: Dictionary, next_feats: Array, next_mask: Array, dealt: float, taken: float, done: bool, truncated: bool) -> void:
	var rew: float = 10.0 * (dealt - float(open["d0"])) - 30.0 * (taken - float(open["k0"]))
	file.store_line(JSON.stringify({"s": open["s"], "m": open["m"], "a": open["a"], "r": snappedf(rew, 0.00001),
		"s2": _round(next_feats), "m2": next_mask, "done": done, "trunc": truncated, "x": open["x"], "dim": open["dim"], "ep": open["ep"]}))
