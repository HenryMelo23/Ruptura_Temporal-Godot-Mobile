extends SceneTree

const ObservationSchema = preload("res://scripts/systems/umbra_observation_schema.gd")
const MultiheadPolicy = preload("res://scripts/systems/umbra_multihead_policy.gd")
const PROTOCOL := "ruptura_umbra_rl"
const PROTOCOL_VERSION := 1
const CURRICULUM_PATH := "res://tools/config/umbra_rl_curriculum_v1.json"

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
	var step_seconds := clampf(float(request.get("step_seconds", 0.16)), 0.04, 0.5)
	var curriculum := _load_curriculum()
	var scenario := _scenario_from_request(request, curriculum)
	if scenario.is_empty():
		_write_response(response_path, {"ok": false, "error": "invalid curriculum or scenario"})
		quit(2)
		return
	var sampling_rng := RandomNumberGenerator.new()
	sampling_rng.seed = seed ^ 0x51A7
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	_configure_episode(seed, scenario)
	var policy = _load_policy(request)
	if String(request.get("policy_mode", "legal_cycle")) == "model" and policy == null:
		_write_response(response_path, {"ok": false, "error": "model policy rejected"})
		_cleanup()
		quit(2)
		return
	var reward_state := _new_reward_state()
	var transitions: Array = []
	for step in range(max_steps):
		var observation := ObservationSchema.build_from_runtime(game)
		var action_mask := _action_mask()
		var target_mask: Array = Array(observation.get("valid_player_mask", []))
		var command := _command_for_step(request, policy, observation, action_mask, target_mask, step, sampling_rng)
		var validated := _validate_command(command, action_mask, target_mask)
		var hp_before := float(game.player_hp)
		var boss_before := float(game.boss_hp)
		_move_reference_player(step, step_seconds, Dictionary(scenario.get("movement", {})))
		game._spawn_umbra_action(String(validated.get("action", "ATAQUE")))
		# Prevent the legacy chooser from injecting a second action during this
		# externally controlled transition. The normal ability executor still runs.
		game.boss5_action_timer = 999.0
		game.boss5_decision_timer = 999.0
		game._update_boss_phase5(step_seconds)
		var player_damage := maxf(0.0, hp_before - float(game.player_hp))
		var boss_damage := maxf(0.0, boss_before - float(game.boss_hp))
		var done := bool(game.is_dead) or bool(game.boss_dead) or step == max_steps - 1
		var reward_result := _reward_for_transition(curriculum, reward_state, validated, player_damage, boss_damage, done)
		var reward := float(reward_result.get("total", 0.0))
		transitions.append({
			"observation": observation.get("values", []), "action_mask": action_mask, "target_mask": target_mask,
			"action": validated, "reward": snappedf(reward, 0.000001), "done": done,
			"info": {"player_damage": player_damage, "boss_damage": boss_damage, "executor_action": validated.get("action", "ATAQUE"), "target_slot": validated.get("target_slot", 0), "space": validated.get("space", {}), "opponent": "scripted_reference", "target_space_binding": "validated_for_contract_not_yet_bound_to_ability_executor", "reward": reward_result, "anti_exploit": Dictionary(reward_result.get("anti_exploit", {}))}
		})
		if done:
			break
	var total_reward := 0.0
	for transition in transitions:
		total_reward += float(Dictionary(transition).get("reward", 0.0))
	_write_response(response_path, {"ok": true, "protocol": PROTOCOL, "protocol_version": PROTOCOL_VERSION, "seed": seed, "transitions": transitions, "summary": {"steps": transitions.size(), "total_reward": snappedf(total_reward, 0.000001), "terminal": bool(Dictionary(transitions.back()).get("done", false)), "policy_mode": String(request.get("policy_mode", "legal_cycle")), "scenario_id": String(scenario.get("id", "")), "scenario_split": String(scenario.get("split", "")), "curriculum_version": int(curriculum.get("curriculum_version", 0)), "reward_version": int(curriculum.get("reward_version", 0)), "reward_shaping_total": snappedf(float(reward_state.get("episode_shaping", 0.0)), 0.000001)}})
	_cleanup()
	quit(0)


func _configure_episode(seed: int, scenario: Dictionary) -> void:
	game._start_game()
	game.rng.seed = seed
	_apply_scenario_player(scenario)
	game._advance_to_phase(5)
	game.mode = "game"
	game.current_phase = 5
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	var difficulty: Dictionary = Dictionary(scenario.get("difficulty", {}))
	var player: Dictionary = Dictionary(scenario.get("player", {}))
	game.boss_hp_max = float(difficulty.get("boss_hp", 22000.0))
	game.boss_hp = game.boss_hp_max
	game.boss5_cadence_bonus = clampf(float(difficulty.get("cadence_bonus", 0.0)), 0.0, 0.25)
	game.boss_pos = Vector2(1050, 430)
	game.player_pos = Vector2(620, 450)
	game.player_hp_max = float(player.get("hp", 1000.0))
	game.player_hp = game.player_hp_max
	game.player_damage = float(player.get("damage", game.player_damage))
	game.player_speed = float(player.get("speed", game.player_speed))
	game.player_defense = 0.0
	game.phase5_hazards.clear()
	game.phase5_rats.clear()
	game.phase5_telegraphs.clear()
	game._load_umbra_mobile_memory()


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
	state["same_action_steps"] = int(state.get("same_action_steps", 0)) + 1 if action == String(state.get("last_action", "")) else 1
	state["no_effect_steps"] = int(state.get("no_effect_steps", 0)) + 1 if no_effect else 0
	state["last_action"] = action
	var repeat_without_effect := no_effect and int(state["same_action_steps"]) >= int(shaping_config.get("repeat_window", 3))
	var passive_streak := no_effect and int(state["no_effect_steps"]) >= int(shaping_config.get("passive_window", 8))
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
		if bool(game.is_dead):
			outcome = "umbra_win"
			principal = float(principal_config.get("player_eliminated", 1.0))
		elif bool(game.boss_dead):
			outcome = "umbra_loss"
			principal = float(principal_config.get("umbra_eliminated", -1.0))
		else:
			outcome = "timeout"
			principal = float(principal_config.get("timeout", 0.0))
	return {"version": int(curriculum.get("reward_version", 0)), "principal": principal, "shaping": shaping, "total": principal + shaping, "outcome": outcome, "components": shaping_components, "anti_exploit": {"repeat_without_effect": repeat_without_effect, "passive_streak": passive_streak, "same_action_steps": int(state["same_action_steps"]), "no_effect_steps": int(state["no_effect_steps"])}}


func _command_for_step(request: Dictionary, policy, observation: Dictionary, action_mask: Array, target_mask: Array, step: int, sampling_rng: RandomNumberGenerator) -> Dictionary:
	if String(request.get("policy_mode", "legal_cycle")) == "fixed_action":
		return {"action_index": ObservationSchema.ACTIONS.find(String(request.get("fixed_action", "ATAQUE"))), "target_slot": 0, "space": {}}
	if String(request.get("policy_mode", "legal_cycle")) == "model":
		var decision: Dictionary = policy.step(observation, action_mask, target_mask)
		if not decision.has("error"):
			var action_index := int(decision.get("action_index", 0))
			var target_slot := int(decision.get("target_slot", 0))
			if bool(request.get("sample_actions", false)):
				var action_logits: PackedFloat32Array = decision.get("action_logits", PackedFloat32Array())
				var target_logits: PackedFloat32Array = decision.get("target_logits", PackedFloat32Array())
				action_index = _sample_masked_logits(action_logits, action_mask, sampling_rng)
				target_slot = _sample_masked_logits(target_logits, target_mask, sampling_rng)
			return {"action_index": action_index, "target_slot": target_slot, "space": Dictionary(decision.get("spatial", {}))}
	var valid: Array = []
	for index in range(action_mask.size()):
		if float(action_mask[index]) > 0.0:
			valid.append(index)
	var action_index := int(valid[step % valid.size()]) if not valid.is_empty() else 4
	return {"action_index": action_index, "target_slot": 0, "space": {"x": 0.5, "y": 0.5, "direction_x": -1.0, "direction_y": 0.0}}


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
	var action_index := clampi(int(command.get("action_index", 4)), 0, ObservationSchema.ACTIONS.size() - 1)
	if action_index >= action_mask.size() or float(action_mask[action_index]) <= 0.0:
		action_index = ObservationSchema.ACTIONS.find("ATAQUE")
	var target_slot := clampi(int(command.get("target_slot", 0)), 0, MultiheadPolicy.TARGET_SCHEMA.size() - 1)
	if target_slot >= target_mask.size() or float(target_mask[target_slot]) <= 0.0:
		target_slot = 0
	var space: Dictionary = Dictionary(command.get("space", {}))
	return {"action_index": action_index, "action": String(ObservationSchema.ACTIONS[action_index]), "target_slot": target_slot, "space": {"x": clampf(float(space.get("x", 0.5)), 0.0, 1.0), "y": clampf(float(space.get("y", 0.5)), 0.0, 1.0), "direction_x": clampf(float(space.get("direction_x", 0.0)), -1.0, 1.0), "direction_y": clampf(float(space.get("direction_y", 0.0)), -1.0, 1.0)}}


func _action_mask() -> Array:
	var available: Array = game._umbra_available_actions()
	var mask: Array = []
	for action in ObservationSchema.ACTIONS:
		mask.append(1.0 if available.has(action) else 0.0)
	return mask


func _move_reference_player(step: int, delta: float, movement_config: Dictionary) -> void:
	var style := String(movement_config.get("style", "orbit"))
	var radius := float(movement_config.get("radius", 260.0))
	var angular_speed := float(movement_config.get("angular_speed", 0.66))
	var t := float(step) * angular_speed * delta
	var desired: Vector2 = game.player_pos
	match style:
		"strafe":
			desired = Vector2(800.0 + sin(t * 3.1) * radius, 450.0 + cos(t * 1.2) * radius * 0.32)
		"edge_weave":
			desired = Vector2(100.0 + fposmod(t * 160.0, 1400.0), 130.0 + absf(sin(t * 1.7)) * 640.0)
		"zigzag":
			desired = Vector2(800.0 + sin(t * 4.4) * radius, 450.0 + sin(t * 2.0) * radius * 0.55)
		"anchor_pulse":
			desired = Vector2(760.0 + cos(t * 1.2) * radius * 0.32, 450.0 + sin(t * 1.2) * radius * 0.32)
		"feint":
			desired = Vector2(800.0 + signf(sin(t * 2.2)) * radius * 0.72, 450.0 + sin(t * 3.7) * radius * 0.42)
		"breakout":
			desired = Vector2(800.0 + cos(t * 0.8) * radius, 450.0 + sin(t * 1.9) * radius * 0.5)
		_:
			desired = Vector2(800.0 + cos(t) * radius, 450.0 + sin(t * 1.37) * radius * 0.62)
	var distance: float = game.player_pos.distance_to(desired)
	var advance := minf(distance, maxf(1.0, float(game.player_speed) * delta))
	if distance > 0.01:
		game.player_pos += game.player_pos.direction_to(desired) * advance
	game.player_pos = game.player_pos.clamp(Vector2(60, 60), game.WORLD_SIZE - Vector2(60, 60))


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
	return MultiheadPolicy.create(model) if not model.is_empty() else null


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	game = null
