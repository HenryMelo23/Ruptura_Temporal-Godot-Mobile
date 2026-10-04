extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("UMBRA_DQN_CONTRACT_FAIL " + message)
	quit(1)


func _zeros(count: int) -> Array:
	var result: Array = []
	for _i in range(count):
		result.append(0.0)
	return result


func _matrix(rows: int, cols: int) -> Array:
	var result: Array = []
	var row_template: Array = _zeros(cols)
	for _i in range(rows):
		result.append(row_template.duplicate())
	return result


func _valid_model() -> Dictionary:
	return {
		"model_version": game.BOSS5_DQN_MODEL_VERSION,
		"action_schema_version": game.BOSS5_DQN_ACTION_SCHEMA_VERSION,
		"feature_schema_version": game.BOSS5_DQN_FEATURE_SCHEMA_VERSION,
		"input_size": game.BOSS5_DQN_FEATURES.size(),
		"output_size": game.BOSS5_ACTIONS.size(),
		"feature_schema": game.BOSS5_DQN_FEATURES.duplicate(),
		"action_schema": game.BOSS5_ACTIONS.duplicate(),
		"acoes_base": game.BOSS5_ACTIONS.duplicate(),
		"net.0.weight": _matrix(game.BOSS5_DQN_HIDDEN1_SIZE, game.BOSS5_DQN_FEATURES.size()),
		"net.0.bias": _zeros(game.BOSS5_DQN_HIDDEN1_SIZE),
		"net.2.weight": _matrix(game.BOSS5_DQN_HIDDEN2_SIZE, game.BOSS5_DQN_HIDDEN1_SIZE),
		"net.2.bias": _zeros(game.BOSS5_DQN_HIDDEN2_SIZE),
		"net.4.weight": _matrix(game.BOSS5_ACTIONS.size(), game.BOSS5_DQN_HIDDEN2_SIZE),
		"net.4.bias": _zeros(game.BOSS5_ACTIONS.size())
	}


func _contract_error(model: Dictionary) -> String:
	return String(game._umbra_dqn_contract_error(model))


func _run() -> void:
	await process_frame
	_check(game.BOSS5_DQN_WEIGHTS_PATH.ends_with(game.BOSS5_DQN_MODEL_VERSION + ".json"), "runtime model path is not versioned")
	var legacy: Dictionary = game._read_json_dict("res://assets/weights/umbra_dqn_weights.json")
	_check(not legacy.is_empty() and _contract_error(legacy) != "", "preserved legacy artifact must remain rejected")
	var valid: Dictionary = _valid_model()
	_check(_contract_error(valid) == "", "valid contract was rejected: " + _contract_error(valid))
	game.boss5_dqn_weights = valid
	var features: Array = _zeros(game.BOSS5_DQN_FEATURES.size())
	var q_values: Array = game._umbra_dqn_forward(features)
	_check(q_values.size() == game.BOSS5_ACTIONS.size(), "valid forward output size mismatch")

	var wrong_version: Dictionary = valid.duplicate(true)
	wrong_version["model_version"] = "umbra_dqn_legacy_22_outputs"
	_check(_contract_error(wrong_version).contains("model_version"), "wrong model version was not rejected clearly")

	var wrong_action_schema_version: Dictionary = valid.duplicate(true)
	wrong_action_schema_version["action_schema_version"] = game.BOSS5_DQN_ACTION_SCHEMA_VERSION - 1
	_check(_contract_error(wrong_action_schema_version).contains("action_schema_version"), "wrong action schema version was not rejected clearly")

	var wrong_feature_schema_version: Dictionary = valid.duplicate(true)
	wrong_feature_schema_version["feature_schema_version"] = game.BOSS5_DQN_FEATURE_SCHEMA_VERSION + 1
	_check(_contract_error(wrong_feature_schema_version).contains("feature_schema_version"), "wrong feature schema version was not rejected clearly")

	var bad_input_size: Dictionary = valid.duplicate(true)
	bad_input_size["input_size"] = game.BOSS5_DQN_FEATURES.size() - 1
	_check(_contract_error(bad_input_size).contains("input_size"), "bad input size was not rejected clearly")

	var bad_output_size: Dictionary = valid.duplicate(true)
	bad_output_size["output_size"] = game.BOSS5_ACTIONS.size() - 1
	_check(_contract_error(bad_output_size).contains("output_size"), "bad output size was not rejected clearly")

	var missing_action_schema: Dictionary = valid.duplicate(true)
	missing_action_schema.erase("action_schema")
	_check(_contract_error(missing_action_schema).contains("action_schema missing"), "missing action schema was not rejected clearly")

	var missing_action: Dictionary = valid.duplicate(true)
	var missing_actions: Array = Array(missing_action["action_schema"])
	missing_actions.erase("TELEPORTE_JUKE")
	missing_action["action_schema"] = missing_actions
	missing_action["acoes_base"] = missing_actions
	_check(_contract_error(missing_action).contains("missing"), "missing action was not rejected clearly")

	var extra_action: Dictionary = valid.duplicate(true)
	var extra_actions: Array = Array(extra_action["action_schema"])
	extra_actions.append("ACAO_FANTASMA")
	extra_action["action_schema"] = extra_actions
	extra_action["acoes_base"] = extra_actions
	_check(_contract_error(extra_action).contains("extra"), "extra action was not rejected clearly")

	var reordered: Dictionary = valid.duplicate(true)
	var reordered_actions: Array = Array(reordered["action_schema"])
	var first_action = reordered_actions[0]
	reordered_actions[0] = reordered_actions[1]
	reordered_actions[1] = first_action
	reordered["action_schema"] = reordered_actions
	reordered["acoes_base"] = reordered_actions
	_check(_contract_error(reordered).contains("order differs"), "action order drift was not rejected clearly")

	var bad_features: Dictionary = valid.duplicate(true)
	var feature_schema: Array = Array(bad_features["feature_schema"])
	var first_feature = feature_schema[0]
	feature_schema[0] = feature_schema[1]
	feature_schema[1] = first_feature
	bad_features["feature_schema"] = feature_schema
	_check(_contract_error(bad_features).contains("feature_schema mismatch"), "feature order drift was not rejected clearly")

	var bad_shape: Dictionary = valid.duplicate(true)
	bad_shape["net.4.weight"] = _matrix(game.BOSS5_ACTIONS.size() - 1, game.BOSS5_DQN_HIDDEN2_SIZE)
	_check(_contract_error(bad_shape).contains("net.4.weight"), "bad output shape was not rejected clearly")

	var bad_input_shape: Dictionary = valid.duplicate(true)
	bad_input_shape["net.0.weight"] = _matrix(game.BOSS5_DQN_HIDDEN1_SIZE, game.BOSS5_DQN_FEATURES.size() - 1)
	_check(_contract_error(bad_input_shape).contains("net.0.weight"), "bad input shape was not rejected clearly")

	print("UMBRA_DQN_CONTRACT_SMOKE_OK actions=%d features=%d model=%s" % [
		game.BOSS5_ACTIONS.size(),
		game.BOSS5_DQN_FEATURES.size(),
		game.BOSS5_DQN_MODEL_VERSION
	])
	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for _i in range(3):
		await process_frame
	quit(0)
