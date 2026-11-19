extends SceneTree

const ObservationSchema = preload("res://scripts/systems/umbra_observation_schema.gd")
const MultiheadPolicy = preload("res://scripts/systems/umbra_multihead_policy.gd")
const PROTOCOL := "ruptura_umbra_rl"
const PROTOCOL_VERSION := 2
const FIXED_DT := 1.0 / 60.0
const ACTIONS = ObservationSchema.TRAINING_ACTIONS
const ApoloObservation = preload("res://tools/apolo_observation.gd")
const CURRICULUM_PATH := "res://tools/config/umbra_rl_curriculum_v2.json"

var game: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var request_path := _argument("--request")
	var response_path := _argument("--response")
	var request := _read_json(request_path)
	if response_path == "" or request.is_empty():
		_write_response(response_path, {"ok": false, "error": "missing or invalid request"})
		quit(2)
		return
	if String(request.get("protocol", "")) != PROTOCOL or int(request.get("protocol_version", -1)) != PROTOCOL_VERSION:
		_write_response(response_path, {"ok": false, "error": "protocol mismatch"})
		quit(2)
		return
	var seed := int(request.get("seed", 1))
	var max_steps := clampi(int(request.get("max_steps", 24)), 1, 240)
	var substeps := maxi(1, int(round(clampf(float(request.get("step_seconds", 0.16)), 0.04, 0.5) / FIXED_DT)))
	var step_seconds := substeps * FIXED_DT
	var curriculum := _load_curriculum()
	var scenario := _scenario_from_request(request, curriculum)
	if scenario.is_empty():
		_write_response(response_path, {"ok": false, "error": "invalid curriculum or scenario"})
		quit(2)
		return
	var sampling_rng := RandomNumberGenerator.new()
	sampling_rng.seed = seed ^ 0x51A7
	RTUmbraMind.training_mode = true
	game = load("res://tools/umbra_rl_scene.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var setup_error := _configure_episode(seed, scenario, request)
	if setup_error != "":
		_write_response(response_path, {"ok": false, "error": setup_error})
		await _cleanup()
		quit(2)
		return
	var policy = _load_policy(request)
	if String(request.get("policy_mode", "legal_cycle")) == "model" and policy == null:
		_write_response(response_path, {"ok": false, "error": "model policy rejected"})
		await _cleanup()
		quit(2)
		return
	var reward_state := _new_reward_state()
	var transitions: Array = []
	for step in range(max_steps):
		var observation := ObservationSchema.build_training(game)
		var action_mask := _action_mask(step_seconds)
		var target_mask: Array = Array(observation.get("valid_player_mask", []))
		var command := _command_for_step(request, policy, observation, action_mask, target_mask, step, sampling_rng)
		if command.has("error"):
			_write_response(response_path, {"ok": false, "error": command["error"]})
			await _cleanup()
			quit(2)
			return
		var validated := _validate_command(command, action_mask, target_mask)
		var hp_before := float(game.player_hp)
		var boss_before := float(game.boss_hp)
		var event_start: int = game.damage_events.size()
		var command_start: int = game.applied_commands.size()
		var tick_start: int = game.training_tick
		var time_start: float = game.time_alive
		game.external_command = validated.duplicate(true)
		for _tick in range(substeps):
			game.advance_training_tick(FIXED_DT)
			if _terminated():
				break
			if game.mode != "game":
				_write_response(response_path, {"ok": false, "error": "unexpected paused/non-combat mode: " + String(game.mode)})
				await _cleanup()
				quit(2)
				return
		var events: Array = game.damage_events.slice(event_start)
		if not _terminated() and absf(float(game.time_alive) - time_start - substeps * FIXED_DT) > 0.00001:
			_write_response(response_path, {"ok": false, "error": "world paused or failed to advance fixed simulation time"})
			await _cleanup()
			quit(2)
			return
		var executed: Array = game.applied_commands.slice(command_start)
		var player_damage := 0.0
		var boss_damage := 0.0
		for event in events:
			if event["recipient"] == "player":
				player_damage += float(event["amount"])
			else:
				boss_damage += float(event["amount"])
		var terminated := _terminated()
		var truncated := step == max_steps - 1 and not terminated
		var done := terminated or truncated
		validated["effect_started"] = not executed.is_empty()
		validated["decision_opportunity"] = action_mask.count(1.0) > 1
		var reward_result := _reward_for_transition(curriculum, reward_state, validated, player_damage, boss_damage, done)
		var reward := float(reward_result.get("total", 0.0))
		var next_observation := ObservationSchema.build_training(game)
		var perception := ApoloObservation.build(game)
		if not bool(perception["coverage_complete"]):
			_write_response(response_path, {"ok": false, "error": "unknown Apolo threat", "perception": perception})
			await _cleanup()
			quit(2)
			return
		transitions.append({
			"observation": observation.get("values", []), "next_observation": next_observation["values"],
			"action_mask": action_mask, "target_mask": target_mask, "action": validated,
			"reward": snappedf(reward, 0.000001), "done": done, "terminated": terminated, "truncated": truncated,
			"info": {"player_damage": player_damage, "boss_damage": boss_damage, "damage_events": events,
				"player_healing": maxf(0.0, float(game.player_hp) - hp_before + player_damage),
				"boss_healing": maxf(0.0, float(game.boss_hp) - boss_before + boss_damage),
				"executor_action": String(executed.back()["action"]) if not executed.is_empty() else "NENHUMA",
				"executed_commands": executed, "target_slot": validated.get("target_slot", 0), "space": validated.get("space", {}),
				"opponent": game.opponent_mode, "target_space_binding": "bound_by_real_ability_executor_solo_target",
				"simulation_tick": game.training_tick, "simulation_time": game.time_alive, "ticks_advanced": game.training_tick - tick_start,
				"player_pos": [game.player_pos.x, game.player_pos.y], "boss_pos": [game.boss_pos.x, game.boss_pos.y],
				"enemy_projectiles": game.enemy_bullets.size(), "player_projectiles": game.bullets.size(),
				"apolo_perception": perception, "reward": reward_result, "anti_exploit": reward_result.get("anti_exploit", {})}
		})
		if done:
			break
	var total_reward := 0.0
	for transition in transitions:
		total_reward += float(Dictionary(transition).get("reward", 0.0))
	_write_response(response_path, {"ok": true, "protocol": PROTOCOL, "protocol_version": PROTOCOL_VERSION, "seed": seed, "transitions": transitions, "summary": {"steps": transitions.size(), "total_reward": snappedf(total_reward, 0.000001), "terminal": _terminated(), "truncated": not _terminated(), "simulation_ticks": game.training_tick, "step_seconds": step_seconds, "fixed_tick_seconds": FIXED_DT, "observation_schema_version": 3, "action_schema_version": 3, "policy_mode": String(request.get("policy_mode", "legal_cycle")), "scenario_id": String(scenario.get("id", "")), "scenario_split": String(scenario.get("split", "")), "curriculum_version": int(curriculum.get("curriculum_version", 0)), "reward_version": int(curriculum.get("reward_version", 0)), "reward_shaping_total": snappedf(float(reward_state.get("episode_shaping", 0.0)), 0.000001)}})
	await _cleanup()
	quit(0)


func _terminated() -> bool:
	return bool(game.is_dead) or bool(game.boss_dead) or float(game.player_hp) <= 0.0 or float(game.boss_hp) <= 0.0


func _configure_episode(seed: int, scenario: Dictionary, request: Dictionary) -> String:
	_apply_scenario_player(scenario)
	game.rng.seed = seed
	game.start_apolo_phase5_exhibition(game.selected_manifestation)
	game.rng.seed = seed
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.shop_auto_enabled = false
	game.run_report_sent = true
	game.boss5_multihead_policy = null
	game.boss5_dqn_weights.clear()
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	var difficulty: Dictionary = scenario.get("difficulty", {})
	var player: Dictionary = scenario.get("player", {})
	game.boss_hp_max = float(difficulty.get("boss_hp", 22000.0))
	game.boss_hp = game.boss_hp_max
	game.boss5_cadence_bonus = clampf(float(difficulty.get("cadence_bonus", 0.0)), 0.0, 0.25)
	var center: Vector2 = game.experimental_phase_controller.boss_encounter_center()
	game.reference_center = center
	game.boss_pos = center + Vector2(180, -40)
	game.player_pos = center + Vector2(-280, 80)
	game.phase5_player_history.clear()
	for _i in range(10):
		game.phase5_player_history.append(game.player_pos)
	game.boss5_authoritative_decision.clear()
	game.player_hp_max = int(player.get("hp", 1000.0))
	game.player_hp = game.player_hp_max
	game.player_damage = float(player.get("damage", game.player_damage))
	game.player_speed = float(player.get("speed", game.player_speed))
	game.player_defense = 0.0
	game.cards_bought.clear()
	for card_name in Dictionary(scenario.get("cards", {})):
		var found := false
		for card in game.CARDS:
			if String(card.get("name", "")) == card_name:
				found = true
				for _copy in range(int(scenario["cards"][card_name])):
					game._apply_card(card)
				break
		if not found:
			return "unknown scenario card: " + String(card_name)
	game.player_hp = game.player_hp_max
	game.reference_movement = Dictionary(scenario.get("movement", {})).duplicate()
	game.opponent_mode = String(request.get("opponent", "scripted_reference"))
	if game.opponent_mode not in ["scripted_reference", "heuristic_reference"]:
		return "unsupported opponent"
	game.player_auto_attack = bool(request.get("player_auto_attack", true))
	game.phase5_hazards.clear()
	game.phase5_rats.clear()
	game.phase5_telegraphs.clear()
	game.bullets.clear()
	game.enemy_bullets.clear()
	game._umbra_base_skills().reset_encounter()
	game._umbra_mind().begin_encounter()
	game.damage_events.clear()
	game.applied_commands.clear()
	return ""


func _apply_scenario_player(scenario: Dictionary) -> void:
	var manifestation := String(scenario.get("manifestation", "eletrica"))
	var spectrum := String(scenario.get("spectrum", "racional"))
	for index in range(game.MANIFESTATIONS.size()):
		var key := String(Dictionary(game.MANIFESTATIONS[index]).get("key", ""))
		game.unlocked_manifestation_ids[key] = true
		if key == manifestation:
			game.selected_manifestation = index
			game.manifestation_key = key
	for index in range(game.AURAS.size()):
		var key := String(Dictionary(game.AURAS[index]).get("key", ""))
		game.unlocked_spectrum_ids[key] = true
		if key == spectrum:
			game.selected_aura = index
	game.cards_bought.clear()
	for card_name in Dictionary(scenario.get("cards", {})).keys():
		game.cards_bought[String(card_name)] = int(Dictionary(scenario.get("cards", {}))[card_name])


func _load_curriculum() -> Dictionary:
	var file := FileAccess.open(CURRICULUM_PATH, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK or not json.data is Dictionary:
		return {}
	var curriculum: Dictionary = json.data
	if String(curriculum.get("format", "")) != "ruptura_umbra_curriculum":
		return {}
	return curriculum


func _scenario_from_request(request: Dictionary, curriculum: Dictionary) -> Dictionary:
	if curriculum.is_empty():
		return {}
	if int(request.get("curriculum_version", curriculum.get("curriculum_version", -1))) != int(curriculum.get("curriculum_version", -2)):
		return {}
	if int(request.get("reward_version", curriculum.get("reward_version", -1))) != int(curriculum.get("reward_version", -2)):
		return {}
	var requested_id := String(request.get("scenario_id", "eletrica_racional_orbit"))
	for row_value in Array(curriculum.get("scenarios", [])):
		var row: Dictionary = Dictionary(row_value)
		if String(row.get("id", "")) == requested_id:
			return row.duplicate(true)
	return {}


func _new_reward_state() -> Dictionary:
	return {"last_action": "", "same_action_steps": 0, "no_effect_steps": 0, "episode_shaping": 0.0}


func _reward_for_transition(curriculum: Dictionary, state: Dictionary, command: Dictionary, player_damage: float, boss_damage: float, done: bool) -> Dictionary:
	var reward_config: Dictionary = Dictionary(curriculum.get("reward", {}))
	var principal_config: Dictionary = Dictionary(reward_config.get("principal", {}))
	var shaping_config: Dictionary = Dictionary(reward_config.get("shaping", {}))
	var action := String(command.get("action", "ATAQUE"))
	var no_effect_threshold := float(shaping_config.get("no_effect_damage_threshold", 0.5))
	var no_effect := player_damage < no_effect_threshold and boss_damage < no_effect_threshold
	var opportunity := bool(command.get("decision_opportunity", true))
	var ineffective_attempt := no_effect and opportunity and not bool(command.get("effect_started", false))
	state["same_action_steps"] = int(state.get("same_action_steps", 0)) + 1 if action == String(state.get("last_action", "")) else 1
	state["no_effect_steps"] = int(state.get("no_effect_steps", 0)) + 1 if ineffective_attempt else 0
	state["last_action"] = action
	var repeat_without_effect := ineffective_attempt and int(state["same_action_steps"]) >= int(shaping_config.get("repeat_window", 3))
	var passive_streak := ineffective_attempt and int(state["no_effect_steps"]) >= int(shaping_config.get("passive_window", 8))
	var shaping_components := {
		"player_damage": player_damage / maxf(1.0, float(game.player_hp_max)) * float(shaping_config.get("player_damage_ratio", 0.0)),
		"umbra_damage": -boss_damage / maxf(1.0, float(game.boss_hp_max)) * absf(float(shaping_config.get("umbra_damage_ratio", 0.0))),
		"step_cost": float(shaping_config.get("step_cost", 0.0)),
		"repeat_without_effect": float(shaping_config.get("repeat_without_effect", 0.0)) if repeat_without_effect else 0.0,
		"passive_streak": float(shaping_config.get("passive_streak", 0.0)) if passive_streak else 0.0
	}
	var raw_shaping := 0.0
	for value in shaping_components.values():
		raw_shaping += float(value)
	var shaping := clampf(raw_shaping, float(shaping_config.get("per_step_min", -0.04)), float(shaping_config.get("per_step_max", 0.18)))
	var prior_episode_shaping := float(state.get("episode_shaping", 0.0))
	var capped_episode_shaping := clampf(prior_episode_shaping + shaping, float(shaping_config.get("episode_min", -0.65)), float(shaping_config.get("episode_max", 0.65)))
	shaping = capped_episode_shaping - prior_episode_shaping
	state["episode_shaping"] = capped_episode_shaping
	var outcome := "ongoing"
	var principal := 0.0
	if done:
		if bool(game.is_dead) or float(game.player_hp) <= 0.0:
			outcome = "umbra_win"
			principal = float(principal_config.get("player_eliminated", 1.0))
		elif bool(game.boss_dead) or float(game.boss_hp) <= 0.0:
			outcome = "umbra_loss"
			principal = float(principal_config.get("umbra_eliminated", -1.0))
		else:
			outcome = "timeout"
			principal = float(principal_config.get("timeout", 0.0))
	return {"version": int(curriculum.get("reward_version", 0)), "principal": principal, "shaping": shaping, "total": principal + shaping, "outcome": outcome, "components": shaping_components, "anti_exploit": {"repeat_without_effect": repeat_without_effect, "passive_streak": passive_streak, "same_action_steps": int(state["same_action_steps"]), "no_effect_steps": int(state["no_effect_steps"])}}


func _command_for_step(request: Dictionary, policy, observation: Dictionary, action_mask: Array, target_mask: Array, step: int, sampling_rng: RandomNumberGenerator) -> Dictionary:
	if String(request.get("policy_mode", "legal_cycle")) == "fixed_action":
		return {"action_index": ACTIONS.find(String(request.get("fixed_action", "ATAQUE"))), "target_slot": 0, "space": Dictionary(request.get("space", {}))}
	if String(request.get("policy_mode", "legal_cycle")) == "model":
		var decision: Dictionary = policy.step(observation, action_mask, target_mask)
		if decision.has("error"):
			return {"error": "policy inference failed: " + String(decision["error"])}
		if not decision.has("error"):
			var action_index := int(decision.get("action_index", 0))
			var target_slot := int(decision.get("target_slot", 0))
			if bool(request.get("sample_actions", false)):
				var action_logits: PackedFloat32Array = decision.get("action_logits", PackedFloat32Array())
				var target_logits: PackedFloat32Array = decision.get("target_logits", PackedFloat32Array())
				action_index = _sample_masked_logits(action_logits, action_mask, sampling_rng)
				target_slot = _sample_masked_logits(target_logits, target_mask, sampling_rng)
			return {"action_index": action_index, "target_slot": target_slot, "space": Dictionary(decision.get("spatial", {})) if bool(request.get("use_spatial_head", false)) else {}}
	var valid: Array = []
	for index in range(action_mask.size()):
		if float(action_mask[index]) > 0.0:
			valid.append(index)
	var action_index := int(valid[step % valid.size()]) if not valid.is_empty() else 4
	return {"action_index": action_index, "target_slot": 0, "space": {}}


func _sample_masked_logits(logits: PackedFloat32Array, mask: Array, sampling_rng: RandomNumberGenerator) -> int:
	var max_logit := -INF
	for index in range(mini(logits.size(), mask.size())):
		if float(mask[index]) > 0.0:
			max_logit = maxf(max_logit, logits[index])
	if max_logit == -INF:
		return 0
	var total := 0.0
	var weights: Array = []
	for index in range(logits.size()):
		var weight := exp(logits[index] - max_logit) if index < mask.size() and float(mask[index]) > 0.0 else 0.0
		weights.append(weight)
		total += weight
	var roll := sampling_rng.randf() * total
	for index in range(weights.size()):
		roll -= float(weights[index])
		if roll <= 0.0 and float(weights[index]) > 0.0:
			return index
	return weights.find(weights.max())


func _validate_command(command: Dictionary, action_mask: Array, target_mask: Array) -> Dictionary:
	var requested_index := int(command.get("action_index", -1))
	var index := requested_index
	var rejected := ""
	if index < 0 or index >= ACTIONS.size():
		rejected = "unknown_action"
	elif index >= action_mask.size() or float(action_mask[index]) <= 0.0:
		rejected = "not_legal_or_cadence_wait"
	if rejected != "":
		index = ACTIONS.find("NENHUMA")
	var space: Dictionary = command.get("space", {})
	var default_point: Vector2 = game.player_pos / game.WORLD_SIZE
	return {"action_index": index, "action": String(ACTIONS[index]), "requested_action_index": requested_index,
		"rejection_reason": rejected, "target_slot": 0,
		"space": {"x": clampf(float(space.get("x", default_point.x)), 0.0, 1.0), "y": clampf(float(space.get("y", default_point.y)), 0.0, 1.0),
			"direction_x": clampf(float(space.get("direction_x", 0.0)), -1.0, 1.0), "direction_y": clampf(float(space.get("direction_y", 0.0)), -1.0, 1.0)}}


func _action_mask(horizon: float) -> Array:
	var available: Array = game._umbra_available_actions() if game.command_ready_within(horizon) else []
	var mask: Array = []
	for action in ACTIONS:
		mask.append(1.0 if action == "NENHUMA" or available.has(action) else 0.0)
	return mask


func _read_json(path: String) -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	return Dictionary(json.data) if error == OK and json.data is Dictionary else {}


func _write_response(path: String, payload: Dictionary) -> void:
	if path == "":
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload))
		file.close()


func _argument(flag: String) -> String:
	var arguments := OS.get_cmdline_user_args()
	for index in range(arguments.size() - 1):
		if String(arguments[index]) == flag:
			return String(arguments[index + 1])
	return ""


func _load_policy(request: Dictionary):
	var path := String(request.get("policy_model", ""))
	var model := _read_json(path)
	return MultiheadPolicy.create(model, 3) if not model.is_empty() else null


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
	game = null
	for _i in range(4):
		await process_frame
