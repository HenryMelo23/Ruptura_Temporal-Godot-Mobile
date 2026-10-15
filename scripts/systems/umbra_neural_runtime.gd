extends RefCounted
class_name RTUmbraNeuralRuntime

const FORMAT := "ruptura_neural_model"
const FORMAT_VERSION := 1
const PRECISION := "fp32"
const LEAKY_RELU_SLOPE := 0.01

var input_size := 0
var output_size := 0
var layer_sizes := PackedInt32Array()
var weights: Array[PackedFloat32Array] = []
var biases: Array[PackedFloat32Array] = []
var buffers: Array[PackedFloat32Array] = []
var input_buffer := PackedFloat32Array()
var brain_tick_seconds := 0.1
var last_tick_seconds := -INF


static func contract_error(model: Dictionary, expected_actions: Array, expected_features: Array, expected_model_version: String, expected_action_schema_version: int, expected_feature_schema_version: int) -> String:
	var metadata_error := _metadata_error(model, expected_actions, expected_features, expected_model_version, expected_action_schema_version, expected_feature_schema_version)
	if metadata_error != "":
		return metadata_error
	var tensors := _tensor_records(model)
	if tensors.is_empty():
		return "tensors missing"
	var architecture: Dictionary = Dictionary(model.get("architecture", {}))
	var layers: Array = Array(architecture.get("layers", []))
	if layers.size() < 1:
		return "architecture.layers missing"
	var previous_size := expected_features.size()
	for index in range(layers.size()):
		var layer: Dictionary = Dictionary(layers[index])
		var layer_input := int(layer.get("input_size", -1))
		var layer_output := int(layer.get("output_size", -1))
		if layer_input != previous_size or layer_output <= 0:
			return "architecture layer %d invalid expected_input=%d actual_input=%d output=%d" % [index, previous_size, layer_input, layer_output]
		var weight_error := _tensor_shape_error(tensors, "layers.%d.weight" % index, [layer_output, layer_input])
		if weight_error != "":
			return weight_error
		var bias_error := _tensor_shape_error(tensors, "layers.%d.bias" % index, [layer_output])
		if bias_error != "":
			return bias_error
		previous_size = layer_output
	if previous_size != expected_actions.size() or int(model.get("output_size", -1)) != expected_actions.size() or int(model.get("input_size", -1)) != expected_features.size():
		return "model IO shape mismatch input=%d output=%d" % [int(model.get("input_size", -1)), int(model.get("output_size", -1))]
	if model.has("format"):
		if String(model.get("format", "")) != FORMAT or int(model.get("format_version", -1)) != FORMAT_VERSION:
			return "model format expected=%s@%d" % [FORMAT, FORMAT_VERSION]
		if String(model.get("precision", "")) != PRECISION:
			return "precision expected=%s actual=%s" % [PRECISION, String(model.get("precision", ""))]
		var integrity: Dictionary = Dictionary(model.get("integrity", {}))
		var expected_digest := String(integrity.get("tensors_sha256", ""))
		if expected_digest == "":
			return "integrity.tensors_sha256 missing"
		if expected_digest != _tensors_sha256(tensors, layers.size()):
			return "integrity.tensors_sha256 mismatch"
	return ""


static func create(model: Dictionary, expected_actions: Array, expected_features: Array, expected_model_version: String, expected_action_schema_version: int, expected_feature_schema_version: int):
	if contract_error(model, expected_actions, expected_features, expected_model_version, expected_action_schema_version, expected_feature_schema_version) != "":
		return null
	var runtime = load("res://scripts/systems/umbra_neural_runtime.gd").new()
	runtime.input_size = expected_features.size()
	runtime.output_size = expected_actions.size()
	runtime.input_buffer.resize(runtime.input_size)
	runtime.brain_tick_seconds = maxf(0.0, float(Dictionary(model.get("runtime", {})).get("brain_tick_seconds", 0.1)))
	var tensors := _tensor_records(model)
	var layers: Array = Array(Dictionary(model.get("architecture", {})).get("layers", []))
	for index in range(layers.size()):
		var layer: Dictionary = Dictionary(layers[index])
		var out_size := int(layer["output_size"])
		runtime.layer_sizes.append(out_size)
		runtime.weights.append(_packed_data(Dictionary(tensors["layers.%d.weight" % index])))
		runtime.biases.append(_packed_data(Dictionary(tensors["layers.%d.bias" % index])))
		var buffer := PackedFloat32Array()
		buffer.resize(out_size)
		runtime.buffers.append(buffer)
	return runtime


func forward(features: Array) -> PackedFloat32Array:
	if features.size() != input_size:
		return PackedFloat32Array()
	for index in range(input_size):
		input_buffer[index] = float(features[index])
	var source := input_buffer
	var source_size := input_size
	for layer_index in range(weights.size()):
		var destination: PackedFloat32Array = buffers[layer_index]
		var layer_weights: PackedFloat32Array = weights[layer_index]
		var layer_biases: PackedFloat32Array = biases[layer_index]
		var destination_size := layer_sizes[layer_index]
		for row in range(destination_size):
			var sum := layer_biases[row]
			var offset := row * source_size
			for column in range(source_size):
				sum += source[column] * layer_weights[offset + column]
			if layer_index < weights.size() - 1 and sum < 0.0:
				sum *= LEAKY_RELU_SLOPE
			destination[row] = sum
		source = destination
		source_size = destination_size
	return source


func should_tick(now_seconds: float) -> bool:
	if now_seconds - last_tick_seconds < brain_tick_seconds:
		return false
	last_tick_seconds = now_seconds
	return true


static func _metadata_error(model: Dictionary, expected_actions: Array, expected_features: Array, expected_model_version: String, expected_action_schema_version: int, expected_feature_schema_version: int) -> String:
	if String(model.get("model_version", "")) != expected_model_version:
		return "model_version expected=%s actual=%s" % [expected_model_version, String(model.get("model_version", "<missing>"))]
	if int(model.get("action_schema_version", -1)) != expected_action_schema_version or int(model.get("feature_schema_version", -1)) != expected_feature_schema_version:
		return "schema version mismatch"
	if not _array_matches(expected_actions, Array(model.get("action_schema", []))) or not _array_matches(expected_features, Array(model.get("feature_schema", []))):
		return "action or feature schema mismatch"
	return ""


static func _array_matches(expected: Array, actual: Array) -> bool:
	if expected.size() != actual.size():
		return false
	for index in range(expected.size()):
		if String(expected[index]) != String(actual[index]):
			return false
	return true


static func _tensor_records(model: Dictionary) -> Dictionary:
	if model.has("tensors"):
		return Dictionary(model.get("tensors", {}))
	# Read-only adapter for the existing JSON. Exporters emit the versioned
	# tensor format; this branch keeps the known baseline/dummy usable.
	var records := {}
	var legacy_layers := [["net.0.weight", "net.0.bias"], ["net.2.weight", "net.2.bias"], ["net.4.weight", "net.4.bias"]]
	for index in range(legacy_layers.size()):
		var pair: Array = legacy_layers[index]
		var weight: Array = Array(model.get(pair[0], []))
		var bias: Array = Array(model.get(pair[1], []))
		if weight.is_empty() or bias.is_empty() or not weight[0] is Array:
			return {}
		records["layers.%d.weight" % index] = {"shape": [weight.size(), Array(weight[0]).size()], "data": _flatten_nested(weight)}
		records["layers.%d.bias" % index] = {"shape": [bias.size()], "data": bias}
	var architecture: Array = []
	for index in range(legacy_layers.size()):
		var shape: Array = Array(Dictionary(records["layers.%d.weight" % index]).get("shape", []))
		architecture.append({"input_size": int(shape[1]), "output_size": int(shape[0])})
	model["architecture"] = {"layers": architecture}
	return records


static func _flatten_nested(matrix: Array) -> Array:
	var flat: Array = []
	for row_value in matrix:
		for value in Array(row_value):
			flat.append(float(value))
	return flat


static func _tensor_shape_error(tensors: Dictionary, key: String, expected_shape: Array) -> String:
	var tensor: Dictionary = Dictionary(tensors.get(key, {}))
	var shape: Array = Array(tensor.get("shape", []))
	if shape != expected_shape:
		return "%s shape expected=%s actual=%s" % [key, expected_shape, shape]
	var expected_values := 1
	for size_value in shape:
		expected_values *= int(size_value)
	if Array(tensor.get("data", [])).size() != expected_values:
		return "%s data size mismatch" % key
	return ""


static func _packed_data(tensor: Dictionary) -> PackedFloat32Array:
	var packed := PackedFloat32Array()
	var data: Array = Array(tensor.get("data", []))
	packed.resize(data.size())
	for index in range(data.size()):
		packed[index] = float(data[index])
	return packed


static func _tensors_sha256(tensors: Dictionary, layer_count: int) -> String:
	var bytes := PackedByteArray()
	for layer_index in range(layer_count):
		for suffix in ["weight", "bias"]:
			bytes.append_array(_packed_data(Dictionary(tensors["layers.%d.%s" % [layer_index, suffix]])).to_byte_array())
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish().hex_encode()
