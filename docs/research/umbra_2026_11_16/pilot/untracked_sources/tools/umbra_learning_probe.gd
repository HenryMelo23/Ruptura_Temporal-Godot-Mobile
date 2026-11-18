extends SceneTree

const ObservationSchema = preload("res://scripts/systems/umbra_observation_schema.gd")
## Synthetic causality and perception probes, NOT learning-performance evidence.
var game: Node
var out_dir := ""
var checks := 0
var failed := false
var collective_path := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--collective="):
			collective_path = arg.trim_prefix("--collective=")
	if out_dir == "":
		push_error("UMBRA_LEARNING_PROBE requires --out=absolute-directory")
		quit(2)
		return
	RTUmbraMind.training_mode = true
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("UMBRA_LEARNING_PROBE_FAIL " + message)
		quit(1)


func _write(name: String, data: Dictionary) -> void:
	var file := FileAccess.open(out_dir.path_join(name), FileAccess.WRITE)
	_check(file != null, "cannot write " + name)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func _run() -> void:
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.run_security_start_request = null
	game.run_report_request = null
	game.run_leaderboard_request = null
	DirAccess.make_dir_recursive_absolute(out_dir)
	game.start_apolo_phase5_exhibition(0)
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.run_report_sent = true
	game.boss5_multihead_policy = null
	var report := {"kind": "synthetic_contract_probe_not_training", "learning_improvement_proven": false}
	report["perception"] = _perception()
	report["rollout_boundary"] = _rollout_boundary()
	report["local_memory"] = _local_memory()
	if collective_path != "":
		report["delivery"] = _delivery()
	_write("probe.json", report)
	print("UMBRA_LEARNING_PROBE_OK checks=%d out=%s" % [checks, out_dir])
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	quit(1 if failed else 0)


func _perception() -> Dictionary:
	var result: Dictionary = {}
	# Spawn real ability payloads, then query the same danger function used by
	# the Godot exhibition bot. A positive signal proves presence, not evasion.
	for action in ["SIFON", "VORTICE", "PRISAO", "MIASMA", "DESCARGA_ELETRICA", "CAMINHO_ESPINHOS", "LASER_SOBRECARGA"]:
		game.phase5_hazards.clear()
		game.boss5_authoritative_decision = {}
		game._spawn_umbra_action(action)
		_check(not game.phase5_hazards.is_empty(), action + " did not spawn")
		var peak := 0.0
		var kinds: Array = []
		for hazard in game.phase5_hazards:
			kinds.append(String(hazard.get("kind", "")))
			for x in range(20):
				for y in range(12):
					var pos: Vector2 = Vector2(game.WORLD_SIZE) * Vector2(float(x) / 19.0, float(y) / 11.0)
					peak = maxf(peak, game._apolo_phase5_hazard_danger(pos, hazard, 0.0))
		result[action] = {"spawned_kinds": kinds, "danger_peak": peak, "has_signal": peak > 0.0}
		if action == "PRISAO":
			var observation := ObservationSchema.build_from_runtime(game)
			var idx := ObservationSchema.feature_names().find("space.hazard.prison")
			result[action]["neural_prison_feature"] = observation["values"][idx]
		_check(peak > 0.0, action + " invisible on sampled grid")
	game.phase5_hazards.clear()
	game.enemy_bullets.clear()
	game.phase5_rats.clear()
	game._umbra_base_skills().reset_encounter()
	game._spawn_umbra_action("ATAQUE")
	_check(not game.enemy_bullets.is_empty(), "plasma did not spawn")
	var bullet_pos: Vector2 = game.enemy_bullets[0]["pos"]
	result["ATAQUE"] = {"has_signal": game._apolo_phase5_danger_at(bullet_pos, 0.0) > 0.0}
	_check(result["ATAQUE"]["has_signal"], "plasma invisible")
	game.enemy_bullets.clear()
	game._spawn_umbra_action("PRAGA_RATOS")
	_check(not game.phase5_rats.is_empty(), "rats did not spawn")
	var rat_pos: Vector2 = game.phase5_rats[0]["pos"]
	result["PRAGA_RATOS"] = {"has_signal": game._apolo_phase5_danger_at(rat_pos, 0.0) > 0.0}
	_check(result["PRAGA_RATOS"]["has_signal"], "rats invisible")
	game.phase5_rats.clear()
	var skills: RTUmbraBaseSkills = game._umbra_base_skills()
	skills.cooldowns["ECO_PROFETICO"] = 0.0
	game._spawn_umbra_action("ECO_PROFETICO")
	_check(not skills.ecos.is_empty(), "eco did not spawn")
	skills.ecos[0]["timer"] = 0.5
	var eco_pos: Vector2 = skills.ecos[0]["pos"]
	result["ECO_PROFETICO"] = {"has_signal": game._apolo_phase5_danger_at(eco_pos, 0.0) > 0.0}
	_check(result["ECO_PROFETICO"]["has_signal"], "eco invisible")
	skills.cooldowns["REBOBINAR"] = 0.0
	game._spawn_umbra_action("REBOBINAR")
	_check(not skills.rewinds.is_empty(), "rewind did not spawn")
	skills.rewinds[0]["timer"] = 0.4
	skills.bot_rewind_reflex = 1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 27
	result["REBOBINAR"] = {"has_signal": skills.bot_should_escape(rng), "channel": "dedicated_escape_gate"}
	_check(result["REBOBINAR"]["has_signal"], "rewind escape gate invisible")
	skills.reset_encounter()
	var dimension_index := ObservationSchema.feature_names().find("space.dimension")
	game.boss5_dimension = "base"
	var base_obs := ObservationSchema.build_from_runtime(game)
	game.boss5_dimension = "vortice"
	var vortex_obs := ObservationSchema.build_from_runtime(game)
	game.boss5_dimension = "base"
	result["neural_contract_gaps"] = {
		"rewind_in_action_schema": ObservationSchema.ACTIONS.has("REBOBINAR"),
		"eco_in_action_schema": ObservationSchema.ACTIONS.has("ECO_PROFETICO"),
		"base_dimension_feature": base_obs["values"][dimension_index],
		"vortex_dimension_feature": vortex_obs["values"][dimension_index],
	}
	result["limitations"] = "Presence of oracle state only; reaction latency, safe routes, hidden information and damage-source attribution are not verified."
	return result


func _rollout_boundary() -> Dictionary:
	game.enemy_bullets.clear()
	game.phase5_hazards.clear()
	game.phase5_rats.clear()
	game.boss5_siphon_timer = 0.0
	game.boss_entry_timer = 0.0
	game.boss5_action_timer = 999.0
	game.boss5_decision_timer = 999.0
	game._spawn_umbra_action("ATAQUE")
	var before: Vector2 = game.enemy_bullets[0]["pos"]
	game._update_boss_phase5(0.16)
	var after_boss_only: Vector2 = game.enemy_bullets[0]["pos"]
	game._update_enemy_bullets(0.16)
	var after_projectile_update: Vector2 = game.enemy_bullets[0]["pos"]
	_check(before == after_boss_only, "boss-only boundary unexpectedly advanced plasma")
	_check(before != after_projectile_update, "normal projectile update did not move plasma")
	game.enemy_bullets.clear()
	return {"boss_only_moves_projectile": before != after_boss_only,
		"normal_projectile_update_moves_projectile": before != after_projectile_update,
		"limitation": "Counterexample to full combat simulation in the existing PPO rollout; no PPO update was run."}


func _local_memory() -> Dictionary:
	var mind: RTUmbraMind = game._umbra_mind()
	mind.user_dir = out_dir.path_join("local_memory") + "/"
	# No real saves or opponent are involved: construct known counterfactual
	# returns to test that persistence and reload causally change preferences.
	mind.reset_weights()
	game.player_hp_max = 10000
	game.player_hp = 10000
	game.boss_hp_max = 10000.0
	game.boss_hp = 10000.0
	mind.begin_encounter()
	for i in range(12):
		var action := "ATAQUE" if i % 2 == 0 else "REBOBINAR"
		mind.on_decision(action)
		if action == "REBOBINAR":
			game.player_hp -= 100
		mind.track(3.1)
	RTUmbraMind.training_mode = false
	mind.finish_encounter("synthetic_fixture", {})
	RTUmbraMind.training_mode = true
	_write("combat_fixture.json", mind.last_report)
	_check(FileAccess.file_exists(mind.player_path()), "personal layer not persisted")
	var layer: Dictionary = RTUmbraMind._read(mind.player_path())
	mind.reset_weights()
	var before := {"ATAQUE": 0.0, "REBOBINAR": 0.0}
	mind.apply(before, ["ATAQUE", "REBOBINAR"])
	mind.apply_layer(layer, 1.0)
	var after := {"ATAQUE": 0.0, "REBOBINAR": 0.0}
	mind.apply(after, ["ATAQUE", "REBOBINAR"])
	_check(float(after["REBOBINAR"]) > float(after["ATAQUE"]), "reload did not favor known advantageous action")
	_check(after != before, "persisted layer had no causal score effect")
	return {"before_scores": before, "after_scores": after, "layer_sha256": FileAccess.get_sha256(mind.player_path()),
		"combat_sha256": FileAccess.get_sha256(out_dir.path_join("combat_fixture.json")), "synthetic": true}


func _delivery() -> Dictionary:
	var layer: Dictionary = RTUmbraMind._read(collective_path)
	_check(not layer.is_empty(), "missing synthetic collective layer")
	var mind: RTUmbraMind = game._umbra_mind()
	mind.load_layers(false)
	var before := {"ATAQUE": 0.0, "REBOBINAR": 0.0}
	mind.apply(before, ["ATAQUE", "REBOBINAR"])
	game._apply_umbra_mind_payload({"ok": true, "mind_version": "synthetic-offline-only", "files": {"umbra_collective_mind.json": layer}})
	mind.user_dir = "user://umbra_mind/"
	_check(RTUmbraMind._read(mind.collective_path()) == layer, "delivered file differs from payload")
	mind.load_layers(true)
	_check(mind.layers.has("coletiva"), "delivery did not enter inference layers")
	var after := {"ATAQUE": 0.0, "REBOBINAR": 0.0}
	mind.apply(after, ["ATAQUE", "REBOBINAR"])
	_check(before != after, "collective delivery had no score effect")
	return {"synthetic": true, "actual_client_payload_method": true, "file_equal_to_payload": true,
		"loaded_layers": mind.layers.duplicate(), "before_scores": before, "after_scores": after, "live_vps_verified": false}
