extends SceneTree

const ObservationSchema = preload("res://scripts/systems/umbra_observation_schema.gd")
const MultiheadPolicy = preload("res://scripts/systems/umbra_multihead_policy.gd")


func _init() -> void:
	var model := _model()
	_expect(MultiheadPolicy.contract_error(model) == "", "valid multi-head contract")
	var policy = MultiheadPolicy.create(model)
	_expect(policy != null, "policy creates")
	var observation := ObservationSchema.build_from_snapshot({
		"umbra_hp_ratio": 0.75,
		"players": [
			{"valid": true, "alive": true, "pos": Vector2(100, 200), "hp": 100.0, "hp_max": 100.0},
			{"valid": true, "alive": true, "pos": Vector2(300, 200), "hp": 100.0, "hp_max": 100.0}
		]
	})
	var first: Dictionary = policy.step(observation, _mask(ObservationSchema.ACTIONS.size(), [1, 4]), [1, 1, 0])
	_expect(not first.has("error"), "step accepts observation v2")
	_expect(int(first.action_index) == 4, "action head selects best real option")
	_expect(int(first.target_slot) == 1, "target head selects valid slot")
	var spatial: Dictionary = Dictionary(first.spatial)
	_expect(float(spatial.x) >= 0.0 and float(spatial.x) <= 1.0 and float(spatial.y) >= 0.0 and float(spatial.y) <= 1.0, "spatial point is bounded")
	_expect(absf(float(spatial.direction_x)) <= 1.0 and absf(float(spatial.direction_y)) <= 1.0, "spatial direction is bounded")
	var first_hidden: Array = Array(first.hidden_state)
	var second: Dictionary = policy.step(observation, _mask(ObservationSchema.ACTIONS.size(), [1, 4]), [1, 1, 0])
	_expect(not _arrays_approximately_equal(first_hidden, Array(second.hidden_state)), "recurrent state changes after sequence step")
	policy.reset_recurrence()
	var replay: Dictionary = policy.step(observation, _mask(ObservationSchema.ACTIONS.size(), [1, 4]), [1, 1, 0])
	_expect(int(replay.action_index) == int(first.action_index) and int(replay.target_slot) == int(first.target_slot), "reset makes recurrence deterministic")
	var masked: Dictionary = policy.step(observation, _mask(ObservationSchema.ACTIONS.size(), [1]), [1, 0, 0])
	_expect(int(masked.action_index) == 1 and int(masked.target_slot) == 0, "masks remove only impossible choices")
	var invalid_mask: Dictionary = policy.step(observation, [0], [1, 0, 0])
	_expect(String(invalid_mask.get("error", "")) == "action mask shape mismatch", "invalid masks reject clearly")
	var wrong_schema: Dictionary = model.duplicate(true)
	wrong_schema["feature_schema"] = ["not-the-observation-schema"]
	_expect(MultiheadPolicy.contract_error(wrong_schema).contains("feature schema"), "schema mismatch rejects")
	var wrong_shape: Dictionary = model.duplicate(true)
	Dictionary(wrong_shape.tensors["heads.target.bias"])["shape"] = [2]
	_expect(MultiheadPolicy.contract_error(wrong_shape).contains("heads.target.bias shape"), "head shape mismatch rejects")
	var tampered: Dictionary = model.duplicate(true)
	Dictionary(tampered.tensors["heads.action.bias"])["data"][4] = 99.0
	_expect(MultiheadPolicy.contract_error(tampered).contains("integrity.tensors_sha256 mismatch"), "tampered tensors reject")
	print("UMBRA_MULTIHEAD_POLICY_OK input=%d actions=%d targets=%d spatial=%d deterministic=true" % [ObservationSchema.feature_names().size(), ObservationSchema.ACTIONS.size(), MultiheadPolicy.TARGET_SCHEMA.size(), MultiheadPolicy.SPATIAL_SCHEMA.size()])
	quit(0)


func _model() -> Dictionary:
	var input_size := ObservationSchema.feature_names().size()
	var encoder_size := 4
	var hidden_size := 3
	var tensors := {}
	_add_tensor(tensors, "encoder.weight", [encoder_size, input_size], 0.01)
	_add_tensor(tensors, "encoder.bias", [encoder_size], 0.02)
	for gate in ["z", "r", "n"]:
		_add_tensor(tensors, "gru.%s_input" % gate, [hidden_size, encoder_size], 0.03)
		_add_tensor(tensors, "gru.%s_hidden" % gate, [hidden_size, hidden_size], 0.04)
		_add_tensor(tensors, "gru.%s_bias" % gate, [hidden_size], 0.01)
	_add_tensor(tensors, "heads.action.weight", [ObservationSchema.ACTIONS.size(), hidden_size], 0.0)
	_add_tensor(tensors, "heads.action.bias", [ObservationSchema.ACTIONS.size()], 0.0)
	Dictionary(tensors["heads.action.bias"])["data"][1] = 1.0
	Dictionary(tensors["heads.action.bias"])["data"][4] = 4.0
	_add_tensor(tensors, "heads.target.weight", [MultiheadPolicy.TARGET_SCHEMA.size(), hidden_size], 0.0)
	_add_tensor(tensors, "heads.target.bias", [MultiheadPolicy.TARGET_SCHEMA.size()], 0.0)
	Dictionary(tensors["heads.target.bias"])["data"][0] = 1.0
	Dictionary(tensors["heads.target.bias"])["data"][1] = 3.0
	_add_tensor(tensors, "heads.spatial.weight", [MultiheadPolicy.SPATIAL_SCHEMA.size(), hidden_size], 0.02)
	_add_tensor(tensors, "heads.spatial.bias", [MultiheadPolicy.SPATIAL_SCHEMA.size()], 0.1)
	_add_tensor(tensors, "heads.value.weight", [1, hidden_size], 0.02)
	_add_tensor(tensors, "heads.value.bias", [1], 0.1)
	var model := {
		"format": MultiheadPolicy.FORMAT, "format_version": MultiheadPolicy.FORMAT_VERSION,
		"model_version": MultiheadPolicy.MODEL_VERSION, "observation_schema_version": ObservationSchema.SCHEMA_VERSION,
		"action_schema_version": MultiheadPolicy.ACTION_SCHEMA_VERSION, "precision": MultiheadPolicy.PRECISION,
		"feature_schema": ObservationSchema.feature_names(), "action_schema": ObservationSchema.ACTIONS,
		"target_schema": MultiheadPolicy.TARGET_SCHEMA, "spatial_schema": MultiheadPolicy.SPATIAL_SCHEMA,
		"architecture": {"input_size": input_size, "encoder_size": encoder_size, "hidden_size": hidden_size, "action_head_size": ObservationSchema.ACTIONS.size(), "target_head_size": MultiheadPolicy.TARGET_SCHEMA.size()},
		"tensors": tensors, "integrity": {}
	}
	Dictionary(model.integrity)["tensors_sha256"] = MultiheadPolicy.compute_tensor_sha256(model)
	return model


func _add_tensor(tensors: Dictionary, key: String, shape: Array, start: float) -> void:
	var count := 1
	for value in shape:
		count *= int(value)
	var data: Array = []
	for index in range(count):
		data.append(start + float(index % 5) * 0.001)
	tensors[key] = {"shape": shape, "data": data}


func _mask(size: int, valid_indexes: Array) -> Array:
	var result: Array = []
	for index in range(size):
		result.append(1.0 if valid_indexes.has(index) else 0.0)
	return result


func _arrays_approximately_equal(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for index in range(left.size()):
		if not is_equal_approx(float(left[index]), float(right[index])):
			return false
	return true


func _expect(condition: bool, label: String) -> void:
	if not condition:
		push_error("UMBRA_MULTIHEAD_POLICY_FAIL: " + label)
		quit(1)
