extends SceneTree

const Neural = preload("res://scripts/systems/umbra_neural_runtime.gd")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("UMBRA_NEURAL_RUNTIME_FAIL " + message)
	quit(1)


func _array(count: int, seed: float) -> Array:
	var values: Array = []
	for index in range(count):
		values.append(sin(float(index) * 0.13 + seed) * 0.08)
	return values


func _matrix(rows: int, cols: int, seed: float) -> Array:
	var values: Array = []
	for row in range(rows):
		values.append(_array(cols, seed + float(row) * 0.07))
	return values


func _flatten(matrix: Array) -> Array:
	var flat: Array = []
	for row in matrix:
		for value in Array(row):
			flat.append(value)
	return flat


func _reference(features: Array, legacy: Dictionary) -> Array:
	var source := features
	for pair in [["net.0.weight", "net.0.bias"], ["net.2.weight", "net.2.bias"], ["net.4.weight", "net.4.bias"]]:
		var output: Array = []
		var matrix: Array = Array(legacy[pair[0]])
		var bias: Array = Array(legacy[pair[1]])
		for row in range(matrix.size()):
			var total := float(bias[row])
			for column in range(source.size()):
				total += float(source[column]) * float(Array(matrix[row])[column])
			if pair[0] != "net.4.weight" and total < 0.0:
				total *= 0.01
			output.append(total)
		source = output
	return source


func _model() -> Dictionary:
	var actions: Array = []
	var features: Array = []
	for index in range(23): actions.append("a%d" % index)
	for index in range(24): features.append("f%d" % index)
	var legacy := {"net.0.weight": _matrix(128, 24, 0.1), "net.0.bias": _array(128, 0.2), "net.2.weight": _matrix(64, 128, 0.3), "net.2.bias": _array(64, 0.4), "net.4.weight": _matrix(23, 64, 0.5), "net.4.bias": _array(23, 0.6)}
	var tensors := {
		"layers.0.weight": {"shape": [128, 24], "data": _flatten(legacy["net.0.weight"])}, "layers.0.bias": {"shape": [128], "data": legacy["net.0.bias"]},
		"layers.1.weight": {"shape": [64, 128], "data": _flatten(legacy["net.2.weight"])}, "layers.1.bias": {"shape": [64], "data": legacy["net.2.bias"]},
		"layers.2.weight": {"shape": [23, 64], "data": _flatten(legacy["net.4.weight"])}, "layers.2.bias": {"shape": [23], "data": legacy["net.4.bias"]}
	}
	var model := {"format": Neural.FORMAT, "format_version": Neural.FORMAT_VERSION, "precision": Neural.PRECISION, "model_version": "test_v1", "action_schema_version": 1, "feature_schema_version": 1, "input_size": 24, "output_size": 23, "action_schema": actions, "feature_schema": features, "normalization": {"kind": "test"}, "architecture": {"layers": [{"input_size": 24, "output_size": 128}, {"input_size": 128, "output_size": 64}, {"input_size": 64, "output_size": 23}]}, "runtime": {"brain_tick_seconds": 0.1}, "tensors": tensors, "legacy": legacy}
	model["integrity"] = {"algorithm": "sha256-fp32le", "tensors_sha256": Neural._tensors_sha256(tensors, 3)}
	return model


func _initialize() -> void:
	var model := _model()
	var actions: Array = Array(model["action_schema"])
	var features_schema: Array = Array(model["feature_schema"])
	_check(Neural.contract_error(model, actions, features_schema, "test_v1", 1, 1) == "", "valid versioned model rejected")
	var runtime = Neural.create(model, actions, features_schema, "test_v1", 1, 1)
	_check(runtime != null, "runtime not created")
	var input := _array(24, 0.9)
	var reference := _reference(input, Dictionary(model["legacy"]))
	var packed: PackedFloat32Array = runtime.forward(input)
	_check(packed.size() == reference.size(), "output shape")
	for index in range(reference.size()):
		_check(is_equal_approx(packed[index], float(reference[index])), "forward diverged at %d" % index)
	var broken: Dictionary = model.duplicate(true)
	broken["integrity"]["tensors_sha256"] = "bad"
	_check(Neural.contract_error(broken, actions, features_schema, "test_v1", 1, 1).contains("integrity"), "bad checksum accepted")
	_check(runtime.should_tick(0.0) and not runtime.should_tick(0.05) and runtime.should_tick(0.1), "brain tick interval")
	var loops := 100
	var start := Time.get_ticks_usec()
	for _i in range(loops):
		_reference(input, Dictionary(model["legacy"]))
	var reference_usec := Time.get_ticks_usec() - start
	start = Time.get_ticks_usec()
	for _i in range(loops):
		runtime.forward(input)
	var packed_usec := Time.get_ticks_usec() - start
	print("UMBRA_NEURAL_RUNTIME_OK format=%s fp32=true outputs=%d reference_usec=%d packed_usec=%d loops=%d" % [Neural.FORMAT, packed.size(), reference_usec, packed_usec, loops])
	quit(0)
