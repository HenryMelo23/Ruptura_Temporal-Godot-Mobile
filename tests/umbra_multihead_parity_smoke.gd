extends SceneTree

const Fixture = preload("res://tests/fixtures/umbra_multihead_parity_fixture.gd")
const Policy = preload("res://scripts/systems/umbra_multihead_policy.gd")
const SAMPLES := 600
const WARMUP := 120
const FRAME_BUDGET_USEC := 16667.0


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("UMBRA_MULTIHEAD_PARITY_FAIL " + message)
	quit(1)


func _initialize() -> void:
	var model := Fixture.model()
	_check(Policy.contract_error(model) == "", "fixture model rejected")
	var policy = Policy.create(model)
	_check(policy != null, "fixture policy was not created")
	var static_before := OS.get_static_memory_usage()
	var results: Array = []
	for fixture_value in Fixture.cases():
		var fixture: Dictionary = fixture_value
		_check(policy.set_hidden_state(Array(fixture.hidden)), "hidden fixture shape")
		var output: Dictionary = policy.step_values(Array(fixture.values), Array(fixture.action_mask), Array(fixture.target_mask))
		_check(not output.has("error"), String(fixture.id) + " inference failed")
		var logits: PackedFloat32Array = output.action_logits
		var target_logits: PackedFloat32Array = output.target_logits
		var spatial: Dictionary = output.spatial
		results.append({
			"id": fixture.id,
			"action_logits": Array(logits.duplicate()),
			"action_probabilities": Array(Policy.logits_to_probabilities(logits)),
			"target_logits": Array(target_logits.duplicate()),
			"target_probabilities": Array(Policy.logits_to_probabilities(target_logits)),
			"action_index": int(output.action_index), "target_slot": int(output.target_slot),
			"spatial": {"x": float(spatial.x), "y": float(spatial.y), "direction_x": float(spatial.direction_x), "direction_y": float(spatial.direction_y)},
			"next_hidden": Array(policy.hidden_state_snapshot())
		})
	var performance := _benchmark(policy)
	var model_bytes := JSON.stringify(model).to_utf8_buffer().size()
	var report := {
		"report_version": 1,
		"platform": OS.get_name(), "engine": Engine.get_version_info().get("string", ""),
		"precision": Policy.PRECISION, "model_hash": Dictionary(model.integrity).get("tensors_sha256", ""),
		"observation_schema_version": model.observation_schema_version,
		"action_schema_version": model.action_schema_version,
		"brain_hz": 1.0 / policy.brain_tick_seconds,
		"model_serialized_bytes": model_bytes, "runtime_buffer_bytes": policy.estimated_memory_bytes(),
		"static_memory_delta_bytes": maxi(0, OS.get_static_memory_usage() - static_before),
		"forward": performance, "fixture_results": results
	}
	_write_report(report)
	_check(float(performance.get("p95_usec", INF)) <= 2000.0, "P95 exceeds 2ms FP32 budget")
	_check(float(performance.get("frame_budget_percent", INF)) <= 12.0, "single brain tick exceeds 12% of 60 FPS budget")
	_check(model_bytes <= 524288 and policy.estimated_memory_bytes() <= 131072, "model or runtime buffers exceed mobile budget")
	print("UMBRA_MULTIHEAD_PARITY_OK platform=%s fixtures=%d mean_usec=%.3f p95_usec=%.3f brain_hz=%.1f model_bytes=%d runtime_bytes=%d" % [OS.get_name(), results.size(), float(performance.mean_usec), float(performance.p95_usec), float(report.brain_hz), model_bytes, policy.estimated_memory_bytes()])
	quit(0)


func _benchmark(policy) -> Dictionary:
	var cases: Array = Fixture.cases()
	for index in range(WARMUP):
		var warmup: Dictionary = cases[index % cases.size()]
		policy.set_hidden_state(Array(warmup.hidden))
		policy.step_values(Array(warmup.values), Array(warmup.action_mask), Array(warmup.target_mask))
	var samples: Array = []
	for index in range(SAMPLES):
		var fixture: Dictionary = cases[index % cases.size()]
		policy.set_hidden_state(Array(fixture.hidden))
		var started := Time.get_ticks_usec()
		policy.step_values(Array(fixture.values), Array(fixture.action_mask), Array(fixture.target_mask))
		samples.append(float(Time.get_ticks_usec() - started))
	samples.sort()
	var total := 0.0
	for sample in samples:
		total += float(sample)
	var mean := total / float(samples.size())
	var p95 := float(samples[mini(samples.size() - 1, int(ceil(float(samples.size()) * 0.95)) - 1)])
	return {"samples": samples.size(), "mean_usec": mean, "p95_usec": p95, "max_usec": float(samples[-1]), "frame_budget_percent": p95 / FRAME_BUDGET_USEC * 100.0}


func _write_report(report: Dictionary) -> void:
	var destination := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			destination = argument.trim_prefix("--report=")
	if destination == "":
		destination = "user://umbra_multihead_parity_%s.json" % OS.get_name().to_lower()
	var file := FileAccess.open(destination, FileAccess.WRITE)
	_check(file != null, "could not write report " + destination)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("UMBRA_MULTIHEAD_PARITY_REPORT " + destination)
