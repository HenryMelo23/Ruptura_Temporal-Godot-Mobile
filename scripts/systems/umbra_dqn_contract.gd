extends RefCounted


static func _string_array(value) -> Array[String]:
	var result: Array[String] = []
	if not value is Array:
		return result
	for entry in Array(value):
		result.append(String(entry))
	return result


static func _arrays_match(expected: Array, actual: Array) -> bool:
	if expected.size() != actual.size():
		return false
	for i in range(expected.size()):
		if String(expected[i]) != String(actual[i]):
			return false
	return true


static func _missing_extra_report(expected: Array, actual: Array) -> String:
	var missing: Array[String] = []
	var extra: Array[String] = []
	for entry in expected:
		if not actual.has(entry):
			missing.append(String(entry))
	for entry in actual:
		if not expected.has(entry):
			extra.append(String(entry))
	var parts: Array[String] = []
	if not missing.is_empty():
		parts.append("missing=%s" % str(missing))
	if not extra.is_empty():
		parts.append("extra=%s" % str(extra))
	return ", ".join(parts)


static func _shape_error(weights: Dictionary, key: String, rows: int, cols: int = -1) -> String:
	if not weights.has(key) or not weights[key] is Array:
		return "%s missing or not an array" % key
	var value: Array = Array(weights[key])
	if value.size() != rows:
		return "%s rows expected=%d actual=%d" % [key, rows, value.size()]
	if cols < 0:
		return ""
	for row_idx in range(value.size()):
		if not value[row_idx] is Array:
			return "%s row %d is not an array" % [key, row_idx]
		var row: Array = Array(value[row_idx])
		if row.size() != cols:
			return "%s row %d cols expected=%d actual=%d" % [key, row_idx, cols, row.size()]
	return ""


static func contract_error(
	weights: Dictionary,
	expected_actions: Array,
	expected_features: Array,
	expected_model_version: String,
	expected_action_schema_version: int,
	expected_feature_schema_version: int,
	hidden1_size: int,
	hidden2_size: int
) -> String:
	if String(weights.get("model_version", "")) != expected_model_version:
		return "model_version expected=%s actual=%s" % [expected_model_version, String(weights.get("model_version", "<missing>"))]
	if int(weights.get("action_schema_version", -1)) != expected_action_schema_version:
		return "action_schema_version expected=%d actual=%d" % [expected_action_schema_version, int(weights.get("action_schema_version", -1))]
	if int(weights.get("feature_schema_version", -1)) != expected_feature_schema_version:
		return "feature_schema_version expected=%d actual=%d" % [expected_feature_schema_version, int(weights.get("feature_schema_version", -1))]
	if int(weights.get("input_size", -1)) != expected_features.size():
		return "input_size expected=%d actual=%d" % [expected_features.size(), int(weights.get("input_size", -1))]
	if int(weights.get("output_size", -1)) != expected_actions.size():
		return "output_size expected=%d actual=%d" % [expected_actions.size(), int(weights.get("output_size", -1))]
	if not weights.has("action_schema"):
		return "action_schema missing"
	var action_schema: Array[String] = _string_array(weights.get("action_schema", []))
	if not _arrays_match(expected_actions, action_schema):
		var action_report: String = _missing_extra_report(expected_actions, action_schema)
		if action_report == "":
			action_report = "order differs"
		return "action_schema mismatch expected=%d actual=%d %s" % [expected_actions.size(), action_schema.size(), action_report]
	var feature_schema: Array[String] = _string_array(weights.get("feature_schema", []))
	if not _arrays_match(expected_features, feature_schema):
		var feature_report: String = _missing_extra_report(expected_features, feature_schema)
		if feature_report == "":
			feature_report = "order differs"
		return "feature_schema mismatch expected=%d actual=%d %s" % [expected_features.size(), feature_schema.size(), feature_report]
	for check in [
		["net.0.weight", hidden1_size, expected_features.size()],
		["net.0.bias", hidden1_size, -1],
		["net.2.weight", hidden2_size, hidden1_size],
		["net.2.bias", hidden2_size, -1],
		["net.4.weight", expected_actions.size(), hidden2_size],
		["net.4.bias", expected_actions.size(), -1],
	]:
		var error: String = _shape_error(weights, String(check[0]), int(check[1]), int(check[2]))
		if error != "":
			return error
	return ""
