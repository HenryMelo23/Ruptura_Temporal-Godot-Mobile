extends SceneTree

const ObservationSchema = preload("res://scripts/systems/umbra_observation_schema.gd")
const MultiheadPolicy = preload("res://scripts/systems/umbra_multihead_policy.gd")


func _init() -> void:
	var output_path := _argument("--out")
	if output_path == "":
		push_error("UMBRA_RL_CONTRACT_FAIL missing --out")
		quit(2)
		return
	var payload := {
		"protocol": "ruptura_umbra_rl", "protocol_version": 1,
		"observation_schema_version": ObservationSchema.SCHEMA_VERSION,
		"feature_schema": ObservationSchema.feature_names(),
		"action_schema": ObservationSchema.ACTIONS,
		"target_schema": MultiheadPolicy.TARGET_SCHEMA,
		"spatial_schema": MultiheadPolicy.SPATIAL_SCHEMA,
		"model_format": MultiheadPolicy.FORMAT,
		"model_version": MultiheadPolicy.MODEL_VERSION,
		"action_schema_version": MultiheadPolicy.ACTION_SCHEMA_VERSION
	}
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("UMBRA_RL_CONTRACT_FAIL cannot write " + output_path)
		quit(2)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	print("UMBRA_RL_CONTRACT_OK features=%d actions=%d" % [ObservationSchema.feature_names().size(), ObservationSchema.ACTIONS.size()])
	quit(0)


func _argument(flag: String) -> String:
	var arguments := OS.get_cmdline_user_args()
	for index in range(arguments.size() - 1):
		if String(arguments[index]) == flag:
			return String(arguments[index + 1])
	return ""
