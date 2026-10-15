extends RefCounted
class_name RTUmbraMultiheadParityFixture

const ObservationSchema = preload("res://scripts/systems/umbra_observation_schema.gd")
const Policy = preload("res://scripts/systems/umbra_multihead_policy.gd")

# These normalized vectors and recurrent states are literal, versioned fixtures.
# They intentionally exercise masks, negative values and a non-zero recurrence.
static var OPENING_VALUES := PackedFloat32Array([
	0.0, 0.15, -0.15, 0.3, -0.3, 0.45, -0.45, 0.6, -0.6,
	0.0, 0.15, -0.15, 0.3, -0.3, 0.45, -0.45, 0.6, -0.6,
	0.0, 0.15, -0.15, 0.3, -0.3, 0.45, -0.45, 0.6, -0.6,
	0.0, 0.15, -0.15, 0.3, -0.3, 0.45, -0.45, 0.6, -0.6,
	0.0, 0.15, -0.15, 0.3, -0.3, 0.45, -0.45, 0.6, -0.6,
	0.0, 0.15, -0.15, 0.3, -0.3, 0.45, -0.45, 0.6, -0.6,
	0.0, 0.15, -0.15, 0.3, -0.3, 0.45, -0.45, 0.6, -0.6,
	0.0, 0.15, -0.15, 0.3, -0.3, 0.45, -0.45, 0.6, -0.6,
	0.0, 0.15, -0.15, 0.3, -0.3, 0.45, -0.45, 0.6, -0.6,
	0.12, -0.12
])
static var PRESSURE_VALUES := PackedFloat32Array([
	-0.5, 0.42, -0.36, 0.31, -0.27, 0.24, -0.21, 0.18, -0.15,
	0.13, -0.11, 0.09, -0.08, 0.07, -0.06, 0.05, -0.04, 0.03,
	-0.02, 0.01, -0.5, 0.42, -0.36, 0.31, -0.27, 0.24, -0.21,
	0.18, -0.15, 0.13, -0.11, 0.09, -0.08, 0.07, -0.06, 0.05,
	-0.04, 0.03, -0.02, 0.01, -0.5, 0.42, -0.36, 0.31, -0.27,
	0.24, -0.21, 0.18, -0.15, 0.13, -0.11, 0.09, -0.08, 0.07,
	-0.06, 0.05, -0.04, 0.03, -0.02, 0.01, -0.5, 0.42, -0.36,
	0.31, -0.27, 0.24, -0.21, 0.18, -0.15, 0.13, -0.11, 0.09,
	-0.08, 0.07, -0.06, 0.05, -0.04, 0.03, -0.02, 0.01, -0.5,
	0.42, -0.36
])


static func model() -> Dictionary:
	var input_size := ObservationSchema.feature_names().size()
	var encoder_size := 8
	var hidden_size := 6
	var tensors := {}
	_add_tensor(tensors, "encoder.weight", [encoder_size, input_size], 0.002)
	_add_tensor(tensors, "encoder.bias", [encoder_size], 0.004)
	for gate in ["z", "r", "n"]:
		_add_tensor(tensors, "gru.%s_input" % gate, [hidden_size, encoder_size], 0.003)
		_add_tensor(tensors, "gru.%s_hidden" % gate, [hidden_size, hidden_size], 0.005)
		_add_tensor(tensors, "gru.%s_bias" % gate, [hidden_size], 0.001)
	_add_tensor(tensors, "heads.action.weight", [ObservationSchema.ACTIONS.size(), hidden_size], 0.006)
	_add_tensor(tensors, "heads.action.bias", [ObservationSchema.ACTIONS.size()], 0.002)
	_add_tensor(tensors, "heads.target.weight", [Policy.TARGET_SCHEMA.size(), hidden_size], 0.007)
	_add_tensor(tensors, "heads.target.bias", [Policy.TARGET_SCHEMA.size()], 0.003)
	_add_tensor(tensors, "heads.spatial.weight", [Policy.SPATIAL_SCHEMA.size(), hidden_size], 0.004)
	_add_tensor(tensors, "heads.spatial.bias", [Policy.SPATIAL_SCHEMA.size()], 0.002)
	_add_tensor(tensors, "heads.value.weight", [1, hidden_size], 0.005)
	_add_tensor(tensors, "heads.value.bias", [1], 0.002)
	var model := {
		"format": Policy.FORMAT, "format_version": Policy.FORMAT_VERSION,
		"model_version": Policy.MODEL_VERSION, "observation_schema_version": ObservationSchema.SCHEMA_VERSION,
		"action_schema_version": Policy.ACTION_SCHEMA_VERSION, "precision": Policy.PRECISION,
		"feature_schema": ObservationSchema.feature_names(), "action_schema": ObservationSchema.ACTIONS,
		"target_schema": Policy.TARGET_SCHEMA, "spatial_schema": Policy.SPATIAL_SCHEMA,
		"architecture": {"input_size": input_size, "encoder_size": encoder_size, "hidden_size": hidden_size, "action_head_size": ObservationSchema.ACTIONS.size(), "target_head_size": Policy.TARGET_SCHEMA.size()},
		"runtime": {"brain_tick_seconds": 0.1}, "tensors": tensors, "integrity": {}
	}
	Dictionary(model.integrity)["tensors_sha256"] = Policy.compute_tensor_sha256(model)
	return model


static func cases() -> Array:
	return [
		{"id": "opening_duo", "values": OPENING_VALUES, "hidden": PackedFloat32Array([0.12, -0.07, 0.21, -0.14, 0.05, 0.09]), "action_mask": _mask(ObservationSchema.ACTIONS.size(), [0, 4, 6, 7, 15]), "target_mask": [1.0, 1.0, 0.0]},
		{"id": "pressure_revive", "values": PRESSURE_VALUES, "hidden": PackedFloat32Array([-0.11, 0.08, -0.19, 0.23, -0.04, 0.16]), "action_mask": _mask(ObservationSchema.ACTIONS.size(), [4, 8, 9, 17, 20]), "target_mask": [0.0, 1.0, 1.0]}
	]


static func _add_tensor(tensors: Dictionary, key: String, shape: Array, base: float) -> void:
	var count := 1
	for value in shape:
		count *= int(value)
	var data: Array = []
	for index in range(count):
		data.append(base + float((index * 7) % 17 - 8) * 0.001)
	tensors[key] = {"shape": shape, "data": data}


static func _mask(size: int, enabled: Array) -> Array:
	var result: Array = []
	for index in range(size):
		result.append(1.0 if enabled.has(index) else 0.0)
	return result
