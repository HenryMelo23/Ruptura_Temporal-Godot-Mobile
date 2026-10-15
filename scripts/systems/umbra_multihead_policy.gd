extends RefCounted
class_name RTUmbraMultiheadPolicy

# Contract-only inference runtime for UMBRA 2.0.  It deliberately has no
# gameplay side effects: the authoritative executor still validates cooldowns,
# targets, geometry and damage before applying a selected command.
const ObservationSchema = preload("res://scripts/systems/umbra_observation_schema.gd")

const FORMAT := "ruptura_umbra_multihead_policy"
const FORMAT_VERSION := 1
const MODEL_VERSION := "umbra_2_0_multihead_gru"
const ACTION_SCHEMA_VERSION := 2
const PRECISION := "fp32"
const TARGET_SCHEMA := ["slot_0", "slot_1", "slot_2"]
const SPATIAL_SCHEMA := ["x", "y", "direction_x", "direction_y"]
const NEGATIVE_INFINITY := -1000000000.0

var input_size := 0
var encoder_size := 0
var hidden_size := 0
var action_size := 0
var target_size := 0
var brain_tick_seconds := 0.1

var encoder_weight := PackedFloat32Array()
var encoder_bias := PackedFloat32Array()
var gru_z_input := PackedFloat32Array()
var gru_z_hidden := PackedFloat32Array()
var gru_z_bias := PackedFloat32Array()
var gru_r_input := PackedFloat32Array()
var gru_r_hidden := PackedFloat32Array()
var gru_r_bias := PackedFloat32Array()
var gru_n_input := PackedFloat32Array()
var gru_n_hidden := PackedFloat32Array()
var gru_n_bias := PackedFloat32Array()
var action_weight := PackedFloat32Array()
var action_bias := PackedFloat32Array()
var target_weight := PackedFloat32Array()
var target_bias := PackedFloat32Array()
var spatial_weight := PackedFloat32Array()
var spatial_bias := PackedFloat32Array()
var value_weight := PackedFloat32Array()
var value_bias := PackedFloat32Array()

# Persistent buffers make recurrence explicit and avoid allocating model state
# every brain tick. Returned logits point to these buffers until the next step.
var encoder_buffer := PackedFloat32Array()
var hidden_state := PackedFloat32Array()
var next_hidden := PackedFloat32Array()
var update_gate := PackedFloat32Array()
var reset_gate := PackedFloat32Array()
var action_logits := PackedFloat32Array()
var target_logits := PackedFloat32Array()
var spatial_raw := PackedFloat32Array()
var value_raw := PackedFloat32Array()


static func contract_error(model: Dictionary) -> String:
	if String(model.get("format", "")) != FORMAT or int(model.get("format_version", -1)) != FORMAT_VERSION:
		return "model format expected=%s@%d" % [FORMAT, FORMAT_VERSION]
	if String(model.get("model_version", "")) != MODEL_VERSION:
		return "model_version expected=%s actual=%s" % [MODEL_VERSION, String(model.get("model_version", "<missing>"))]
	if int(model.get("observation_schema_version", -1)) != ObservationSchema.SCHEMA_VERSION:
		return "observation_schema_version mismatch"
	if int(model.get("action_schema_version", -1)) != ACTION_SCHEMA_VERSION:
		return "action_schema_version mismatch"
	if String(model.get("precision", "")) != PRECISION:
		return "precision expected=%s" % PRECISION
	if not _array_matches(ObservationSchema.feature_names(), Array(model.get("feature_schema", []))):
		return "feature schema mismatch"
	if not _array_matches(ObservationSchema.ACTIONS, Array(model.get("action_schema", []))):
		return "action schema mismatch"
	if not _array_matches(TARGET_SCHEMA, Array(model.get("target_schema", []))):
		return "target schema mismatch"
	if not _array_matches(SPATIAL_SCHEMA, Array(model.get("spatial_schema", []))):
		return "spatial schema mismatch"
	var architecture: Dictionary = Dictionary(model.get("architecture", {}))
	var checked_sizes := _checked_sizes(architecture)
	if checked_sizes.is_empty():
		return "architecture sizes invalid"
	var tensors: Dictionary = Dictionary(model.get("tensors", {}))
	var shapes := {
		"encoder.weight": [checked_sizes.encoder, checked_sizes.input], "encoder.bias": [checked_sizes.encoder],
		"gru.z_input": [checked_sizes.hidden, checked_sizes.encoder], "gru.z_hidden": [checked_sizes.hidden, checked_sizes.hidden], "gru.z_bias": [checked_sizes.hidden],
		"gru.r_input": [checked_sizes.hidden, checked_sizes.encoder], "gru.r_hidden": [checked_sizes.hidden, checked_sizes.hidden], "gru.r_bias": [checked_sizes.hidden],
		"gru.n_input": [checked_sizes.hidden, checked_sizes.encoder], "gru.n_hidden": [checked_sizes.hidden, checked_sizes.hidden], "gru.n_bias": [checked_sizes.hidden],
		"heads.action.weight": [checked_sizes.action, checked_sizes.hidden], "heads.action.bias": [checked_sizes.action],
		"heads.target.weight": [checked_sizes.target, checked_sizes.hidden], "heads.target.bias": [checked_sizes.target],
		"heads.spatial.weight": [SPATIAL_SCHEMA.size(), checked_sizes.hidden], "heads.spatial.bias": [SPATIAL_SCHEMA.size()],
		"heads.value.weight": [1, checked_sizes.hidden], "heads.value.bias": [1]
	}
	for key_value in shapes.keys():
		var shape_error := _tensor_shape_error(tensors, String(key_value), Array(shapes[key_value]))
		if shape_error != "":
			return shape_error
	var integrity: Dictionary = Dictionary(model.get("integrity", {}))
	var expected_hash := String(integrity.get("tensors_sha256", ""))
	if expected_hash == "":
		return "integrity.tensors_sha256 missing"
	if expected_hash != compute_tensor_sha256(model):
		return "integrity.tensors_sha256 mismatch"
	return ""


static func create(model: Dictionary):
	if contract_error(model) != "":
		return null
	var policy = load("res://scripts/systems/umbra_multihead_policy.gd").new()
	var sizes := _checked_sizes(Dictionary(model.get("architecture", {})))
	policy.input_size = sizes.input
	policy.encoder_size = sizes.encoder
	policy.hidden_size = sizes.hidden
	policy.action_size = sizes.action
	policy.target_size = sizes.target
	policy.brain_tick_seconds = clampf(float(Dictionary(model.get("runtime", {})).get("brain_tick_seconds", 0.1)), 0.02, 1.0)
	var tensors: Dictionary = Dictionary(model.get("tensors", {}))
	policy.encoder_weight = _packed(tensors, "encoder.weight")
	policy.encoder_bias = _packed(tensors, "encoder.bias")
	policy.gru_z_input = _packed(tensors, "gru.z_input")
	policy.gru_z_hidden = _packed(tensors, "gru.z_hidden")
	policy.gru_z_bias = _packed(tensors, "gru.z_bias")
	policy.gru_r_input = _packed(tensors, "gru.r_input")
	policy.gru_r_hidden = _packed(tensors, "gru.r_hidden")
	policy.gru_r_bias = _packed(tensors, "gru.r_bias")
	policy.gru_n_input = _packed(tensors, "gru.n_input")
	policy.gru_n_hidden = _packed(tensors, "gru.n_hidden")
	policy.gru_n_bias = _packed(tensors, "gru.n_bias")
	policy.action_weight = _packed(tensors, "heads.action.weight")
	policy.action_bias = _packed(tensors, "heads.action.bias")
	policy.target_weight = _packed(tensors, "heads.target.weight")
	policy.target_bias = _packed(tensors, "heads.target.bias")
	policy.spatial_weight = _packed(tensors, "heads.spatial.weight")
	policy.spatial_bias = _packed(tensors, "heads.spatial.bias")
	policy.value_weight = _packed(tensors, "heads.value.weight")
	policy.value_bias = _packed(tensors, "heads.value.bias")
	policy._allocate_buffers()
	return policy


func reset_recurrence() -> void:
	hidden_state.fill(0.0)
	next_hidden.fill(0.0)


# Fixture and platform-parity tooling may seed recurrence explicitly. This is
# local model state only: it is never serialized into multiplayer snapshots.
func set_hidden_state(values: Array) -> bool:
	if values.size() != hidden_size:
		return false
	for index in range(hidden_size):
		hidden_state[index] = float(values[index])
		next_hidden[index] = hidden_state[index]
	return true


func hidden_state_snapshot() -> PackedFloat32Array:
	return hidden_state.duplicate()


func estimated_memory_bytes() -> int:
	var total := 0
	for tensor in [encoder_weight, encoder_bias, gru_z_input, gru_z_hidden, gru_z_bias, gru_r_input, gru_r_hidden, gru_r_bias, gru_n_input, gru_n_hidden, gru_n_bias, action_weight, action_bias, target_weight, target_bias, spatial_weight, spatial_bias, value_weight, value_bias, encoder_buffer, hidden_state, next_hidden, update_gate, reset_gate, action_logits, target_logits, spatial_raw, value_raw]:
		total += PackedFloat32Array(tensor).size() * 4
	return total


func step(observation: Dictionary, action_mask: Array = [], target_mask: Array = []) -> Dictionary:
	var observation_error := ObservationSchema.validate_observation(observation)
	if observation_error != "":
		return {"error": observation_error}
	var values: Array = Array(observation.get("values", []))
	var resolved_targets: Array = target_mask
	if resolved_targets.is_empty():
		resolved_targets = Array(observation.get("valid_player_mask", []))
	return step_values(values, action_mask, resolved_targets)


func step_values(values: Array, action_mask: Array = [], target_mask: Array = []) -> Dictionary:
	if values.size() != input_size:
		return {"error": "input shape mismatch"}
	var action_mask_error := _mask_error(action_mask, action_size, "action")
	if action_mask_error != "":
		return {"error": action_mask_error}
	var target_mask_error := _mask_error(target_mask, target_size, "target")
	if target_mask_error != "":
		return {"error": target_mask_error}
	_encode(values)
	_update_gru()
	_linear(hidden_state, hidden_size, action_weight, action_bias, action_logits)
	_linear(hidden_state, hidden_size, target_weight, target_bias, target_logits)
	_linear(hidden_state, hidden_size, spatial_weight, spatial_bias, spatial_raw)
	_linear(hidden_state, hidden_size, value_weight, value_bias, value_raw)
	_apply_mask(action_logits, action_mask)
	_apply_mask(target_logits, target_mask)
	return {
		"action_index": _argmax(action_logits),
		"target_slot": _argmax(target_logits),
		"spatial": _decode_spatial(),
		"value": value_raw[0],
		"action_logits": action_logits,
		"target_logits": target_logits,
		"hidden_state": hidden_state
	}


static func logits_to_probabilities(logits_value) -> PackedFloat32Array:
	var logits: PackedFloat32Array = logits_value
	var result := PackedFloat32Array()
	result.resize(logits.size())
	var maximum := NEGATIVE_INFINITY
	for value in logits:
		if value > maximum:
			maximum = value
	if maximum <= NEGATIVE_INFINITY * 0.5:
		return result
	var total := 0.0
	for index in range(logits.size()):
		if logits[index] <= NEGATIVE_INFINITY * 0.5:
			result[index] = 0.0
			continue
		result[index] = exp(logits[index] - maximum)
		total += result[index]
	if total > 0.0:
		for index in range(result.size()):
			result[index] /= total
	return result


static func compute_tensor_sha256(model: Dictionary) -> String:
	var tensors: Dictionary = Dictionary(model.get("tensors", {}))
	var order := ["encoder.weight", "encoder.bias", "gru.z_input", "gru.z_hidden", "gru.z_bias", "gru.r_input", "gru.r_hidden", "gru.r_bias", "gru.n_input", "gru.n_hidden", "gru.n_bias", "heads.action.weight", "heads.action.bias", "heads.target.weight", "heads.target.bias", "heads.spatial.weight", "heads.spatial.bias", "heads.value.weight", "heads.value.bias"]
	var bytes := PackedByteArray()
	for key in order:
		var tensor: Dictionary = Dictionary(tensors.get(key, {}))
		var packed := PackedFloat32Array()
		var data: Array = Array(tensor.get("data", []))
		packed.resize(data.size())
		for index in range(data.size()):
			packed[index] = float(data[index])
		bytes.append_array(packed.to_byte_array())
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish().hex_encode()


func _allocate_buffers() -> void:
	encoder_buffer.resize(encoder_size)
	hidden_state.resize(hidden_size)
	next_hidden.resize(hidden_size)
	update_gate.resize(hidden_size)
	reset_gate.resize(hidden_size)
	action_logits.resize(action_size)
	target_logits.resize(target_size)
	spatial_raw.resize(SPATIAL_SCHEMA.size())
	value_raw.resize(1)


func _encode(values: Array) -> void:
	for row in range(encoder_size):
		var sum := encoder_bias[row]
		var offset := row * input_size
		for column in range(input_size):
			sum += float(values[column]) * encoder_weight[offset + column]
		encoder_buffer[row] = tanh(sum)


func _update_gru() -> void:
	for row in range(hidden_size):
		update_gate[row] = _sigmoid(_row_dot(gru_z_input, row, encoder_size, encoder_buffer) + _row_dot(gru_z_hidden, row, hidden_size, hidden_state) + gru_z_bias[row])
		reset_gate[row] = _sigmoid(_row_dot(gru_r_input, row, encoder_size, encoder_buffer) + _row_dot(gru_r_hidden, row, hidden_size, hidden_state) + gru_r_bias[row])
	for row in range(hidden_size):
		var candidate := tanh(_row_dot(gru_n_input, row, encoder_size, encoder_buffer) + _row_dot_gated_hidden(gru_n_hidden, row) + gru_n_bias[row])
		next_hidden[row] = (1.0 - update_gate[row]) * candidate + update_gate[row] * hidden_state[row]
	for row in range(hidden_size):
		hidden_state[row] = next_hidden[row]


func _row_dot(weights: PackedFloat32Array, row: int, width: int, source: PackedFloat32Array) -> float:
	var result := 0.0
	var offset := row * width
	for column in range(width):
		result += weights[offset + column] * source[column]
	return result


func _row_dot_gated_hidden(weights: PackedFloat32Array, row: int) -> float:
	var result := 0.0
	var offset := row * hidden_size
	for column in range(hidden_size):
		result += weights[offset + column] * (reset_gate[column] * hidden_state[column])
	return result


func _linear(source: PackedFloat32Array, source_size: int, weights: PackedFloat32Array, bias: PackedFloat32Array, destination: PackedFloat32Array) -> void:
	for row in range(destination.size()):
		destination[row] = bias[row] + _row_dot(weights, row, source_size, source)


func _apply_mask(logits: PackedFloat32Array, mask: Array) -> void:
	if mask.is_empty():
		return
	for index in range(logits.size()):
		if float(mask[index]) <= 0.0:
			logits[index] = NEGATIVE_INFINITY


func _decode_spatial() -> Dictionary:
	return {
		"x": clampf((tanh(spatial_raw[0]) + 1.0) * 0.5, 0.0, 1.0),
		"y": clampf((tanh(spatial_raw[1]) + 1.0) * 0.5, 0.0, 1.0),
		"direction_x": tanh(spatial_raw[2]),
		"direction_y": tanh(spatial_raw[3])
	}


static func _checked_sizes(architecture: Dictionary) -> Dictionary:
	var sizes := {
		"input": int(architecture.get("input_size", -1)), "encoder": int(architecture.get("encoder_size", -1)),
		"hidden": int(architecture.get("hidden_size", -1)), "action": int(architecture.get("action_head_size", -1)),
		"target": int(architecture.get("target_head_size", -1))
	}
	if sizes.input != ObservationSchema.feature_names().size() or sizes.action != ObservationSchema.ACTIONS.size() or sizes.target != TARGET_SCHEMA.size() or sizes.encoder <= 0 or sizes.hidden <= 0:
		return {}
	return sizes


static func _tensor_shape_error(tensors: Dictionary, key: String, expected_shape: Array) -> String:
	var tensor: Dictionary = Dictionary(tensors.get(key, {}))
	var shape: Array = Array(tensor.get("shape", []))
	if shape != expected_shape:
		return "%s shape expected=%s actual=%s" % [key, expected_shape, shape]
	var count := 1
	for size_value in shape:
		count *= int(size_value)
	if Array(tensor.get("data", [])).size() != count:
		return "%s data size mismatch" % key
	return ""


static func _packed(tensors: Dictionary, key: String) -> PackedFloat32Array:
	var data: Array = Array(Dictionary(tensors[key]).get("data", []))
	var result := PackedFloat32Array()
	result.resize(data.size())
	for index in range(data.size()):
		result[index] = float(data[index])
	return result


static func _array_matches(expected: Array, actual: Array) -> bool:
	if expected.size() != actual.size():
		return false
	for index in range(expected.size()):
		if String(expected[index]) != String(actual[index]):
			return false
	return true


static func _mask_error(mask: Array, expected_size: int, label: String) -> String:
	if mask.is_empty():
		return ""
	if mask.size() != expected_size:
		return "%s mask shape mismatch" % label
	for value in mask:
		if float(value) > 0.0:
			return ""
	return "%s mask has no valid option" % label


static func _argmax(values: PackedFloat32Array) -> int:
	if values.is_empty():
		return -1
	var best_index := 0
	var best_value := values[0]
	for index in range(1, values.size()):
		if values[index] > best_value:
			best_value = values[index]
			best_index = index
	return best_index


static func _sigmoid(value: float) -> float:
	return 1.0 / (1.0 + exp(-clampf(value, -60.0, 60.0)))
