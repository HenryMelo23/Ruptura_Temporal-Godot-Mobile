extends SceneTree

## Treino headless da mente base da UMBRA por estrategia evolutiva (ES).
## Oponente: bot Apolo (desvia de hazards, sigilos do eco e foge do rebobinar
## com reflexo variavel), com build de fim de run. Sem Python, sem PyTorch.
##
## godot --headless --path . --script res://tools/umbra_mind_train.gd -- \
##   --generations=30 --pairs=6 --episodes=2 --seconds=60 [--fresh] [--seed=7]
##
## Saidas:
##   res://assets/data/umbra_mind_base.json   (mente base que vai no jogo)
##   res://.agent_logs/umbra_train/log.jsonl  (uma linha por geracao)
## Retoma do arquivo base existente, a menos que --fresh.

const OUT_PATH := "res://assets/data/umbra_mind_base.json"
const LOG_DIR := "res://.agent_logs/umbra_train/"
const DT := 1.0 / 30.0
const SIGMA := 0.18
const LR := 0.09
const DECAY := 0.004

var game: Node
var mind: RTUmbraMind
var args := {"generations": 20, "pairs": 6, "episodes": 2, "seconds": 60.0, "seed": 7705, "fresh": false, "verbose": 0, "budget": 0}
var rng := RandomNumberGenerator.new()
var episodes_run := 0


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var a: String = String(raw)
		if a == "--fresh":
			args["fresh"] = true
		elif a.begins_with("--") and a.contains("="):
			var kv: PackedStringArray = a.substr(2).split("=", true, 1)
			args[kv[0]] = float(kv[1]) if kv[0] == "seconds" else int(kv[1])
	RTUmbraMind.training_mode = true
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


## Perfil do oponente para uma semente (igual para todos os candidatos da geracao).
func _opponent(seed: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	return {
		"manifestation": r.randi_range(0, 5),
		"reflex": r.randf_range(0.25, 0.95),
		"hp": r.randf_range(2000.0, 3400.0),
		"ttk": r.randf_range(140.0, 260.0),
		"seed": seed,
	}


func _episode(params: PackedFloat32Array, opp: Dictionary) -> float:
	game.rng.seed = int(opp["seed"])
	game.start_apolo_phase5_exhibition(int(opp["manifestation"]))
	game.set_process(false)
	game.set_physics_process(false)
	game.mode = "game"
	for k in game.boss5_mobile_weights.keys():
		game.boss5_mobile_weights[k] = 0.0
	game.boss5_predatory_mods.clear()
	game.boss5_profile_confidence = 0.0
	mind = game._umbra_mind()
	mind.from_params(params)
	var skills: RTUmbraBaseSkills = game._umbra_base_skills()
	skills.reset_encounter()
	skills.bot_rewind_reflex = float(opp["reflex"])
	game.player_hp_max = int(opp["hp"])
	game.player_hp = game.player_hp_max
	var interval: float = maxf(0.08, float(game._current_attack_interval()))
	game.player_damage = float(game.boss_hp_max) / float(opp["ttk"]) * interval / 0.55
	var hp0: float = float(game.player_hp)
	var boss0: float = float(game.boss_hp)
	var limit: int = int(float(args["seconds"]) / DT)
	var frames := 0
	var hp_low: float = hp0
	var dealt := 0.0
	while frames < limit and not game.is_dead and float(game.boss_hp) > 0.0 and int(game.player_hp) > 0:
		var before: float = float(game.player_hp)
		game._process(DT)
		var after: float = float(game.player_hp)
		if after < before:
			dealt += before - after
		frames += 1
	episodes_run += 1
	var t_frac: float = float(frames) / float(limit)
	var dmg_frac: float = dealt / maxf(1.0, hp0)
	var taken_frac: float = (boss0 - float(game.boss_hp)) / maxf(1.0, float(game.boss_hp_max))
	# Esperado sem reacao: o bot tiraria ~seconds/ttk da vida dela.
	var expected_taken: float = float(args["seconds"]) / float(opp["ttk"])
	var f: float = 1.6 * dmg_frac - 1.0 * taken_frac / maxf(0.05, expected_taken)
	if game.is_dead or int(game.player_hp) <= 0:
		f += 0.8 + 0.8 * (1.0 - t_frac)
	if float(game.boss_hp) <= 0.0:
		f -= 1.0
	if int(args["verbose"]) > 0:
		print("UMBRA_EP manif=%d reflex=%.2f t=%.1fs dealt=%.2f taken=%.3f/%.3f dead=%s f=%.3f" % [int(opp["manifestation"]), float(opp["reflex"]), float(frames) * DT, dmg_frac, taken_frac, expected_taken, str(game.is_dead or int(game.player_hp) <= 0), f])
	return f


func _evaluate(params: PackedFloat32Array, opps: Array) -> float:
	var total := 0.0
	for opp in opps:
		total += _episode(params, opp)
	return total / float(opps.size())


func _centered_ranks(values: Array) -> Array:
	var idx: Array = range(values.size())
	idx.sort_custom(func(a, b): return float(values[a]) < float(values[b]))
	var out: Array = []
	out.resize(values.size())
	for r in range(idx.size()):
		out[idx[r]] = float(r) / float(maxi(1, idx.size() - 1)) - 0.5
	return out


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LOG_DIR))
	rng.seed = int(args["seed"])
	game.start_apolo_phase5_exhibition(0)
	mind = game._umbra_mind()
	var meta := {"generation": 0, "trained_episodes": 0}
	var theta: PackedFloat32Array
	var existing: Dictionary = RTUmbraMind._read(OUT_PATH)
	if not bool(args["fresh"]) and not existing.is_empty():
		mind.reset_weights()
		mind.apply_layer(existing, 1.0)
		meta["generation"] = int(existing.get("generation", 0))
		meta["trained_episodes"] = int(existing.get("trained_episodes", 0))
	else:
		mind.reset_weights()
	theta = mind.to_params()
	rng.seed = int(args["seed"]) * 31 + int(meta["generation"])
	var n: int = theta.size()
	var scale := PackedFloat32Array()
	scale.resize(n)
	scale.fill(1.0)
	scale[n - 1] = 0.25  # aim_lead varia menos
	var t_start := Time.get_ticks_msec()
	var pairs: int = int(args["pairs"])
	var log_file := FileAccess.open(ProjectSettings.globalize_path(LOG_DIR + "log.jsonl"), FileAccess.READ_WRITE if FileAccess.file_exists(ProjectSettings.globalize_path(LOG_DIR + "log.jsonl")) else FileAccess.WRITE)
	log_file.seek_end()
	for g in range(int(args["generations"])):
		var gen: int = int(meta["generation"]) + 1
		var opps: Array = []
		for e in range(int(args["episodes"])):
			opps.append(_opponent(int(args["seed"]) * 1000 + gen * 17 + e))
		var noises: Array = []
		var fits: Array = []
		for p in range(pairs):
			var eps := PackedFloat32Array()
			eps.resize(n)
			for i in range(n):
				eps[i] = rng.randfn(0.0, 1.0) * scale[i]
			noises.append(eps)
			var plus := PackedFloat32Array(theta)
			var minus := PackedFloat32Array(theta)
			for i in range(n):
				plus[i] += SIGMA * eps[i]
				minus[i] -= SIGMA * eps[i]
			fits.append(_evaluate(plus, opps))
			fits.append(_evaluate(minus, opps))
		var ranks: Array = _centered_ranks(fits)
		var grad := PackedFloat32Array()
		grad.resize(n)
		for p in range(pairs):
			var w: float = float(ranks[p * 2]) - float(ranks[p * 2 + 1])
			var eps2: PackedFloat32Array = noises[p]
			for i in range(n):
				grad[i] += w * eps2[i]
		for i in range(n):
			theta[i] = theta[i] * (1.0 - DECAY) + LR / (float(pairs) * SIGMA) * grad[i] * SIGMA
		var center_fit: float = _evaluate(theta, opps)
		meta["generation"] = gen
		meta["trained_episodes"] = int(meta["trained_episodes"]) + pairs * 2 * opps.size() + opps.size()
		mind.from_params(theta)
		var layer: Dictionary = mind.export_layer()
		layer["version"] = "umbra-base-g%d" % gen
		layer["generation"] = gen
		layer["trained_episodes"] = meta["trained_episodes"]
		layer["fitness"] = snappedf(center_fit, 0.0001)
		layer["opponent"] = "apolo_bot"
		layer["trained_at_unix"] = int(Time.get_unix_time_from_system())
		var f := FileAccess.open(ProjectSettings.globalize_path(OUT_PATH), FileAccess.WRITE)
		f.store_string(JSON.stringify(layer, "\t"))
		f.close()
		var mean: float = 0.0
		var best: float = -INF
		for v in fits:
			mean += float(v)
			best = maxf(best, float(v))
		mean /= float(fits.size())
		var line := {"gen": gen, "center": snappedf(center_fit, 0.001), "mean": snappedf(mean, 0.001), "best": snappedf(best, 0.001), "aim_lead": snappedf(mind.aim_lead, 0.001), "secs": int((Time.get_ticks_msec() - t_start) / 1000)}
		log_file.store_line(JSON.stringify(line))
		log_file.flush()
		print("UMBRA_TRAIN ", JSON.stringify(line))
		# --budget=S: para depois da geracao que passar de S segundos (retoma na proxima chamada).
		if int(args["budget"]) > 0 and (Time.get_ticks_msec() - t_start) / 1000 >= int(args["budget"]):
			break
	print("UMBRA_TRAIN_DONE episodes=%d" % episodes_run)
	quit(0)
