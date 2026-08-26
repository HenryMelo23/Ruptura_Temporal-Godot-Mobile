extends SceneTree

const SelfplayCore = preload("res://tools/umbra_selfplay_core.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = _parse_options()
	var core := SelfplayCore.new()
	var result: Dictionary = core.run_training(options)
	var output_dir: String = String(options.get("out", "user://umbra_selfplay"))
	var write_error: int = _write_outputs(output_dir, result)
	if write_error != OK:
		push_error("UMBRA_SELFPLAY: failed to write output files in %s error=%d" % [output_dir, write_error])
		quit(1)
		return
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	var winners: Dictionary = Dictionary(summary.get("winners", {}))
	print("UMBRA_SELFPLAY_OK episodes=%d umbra_wins=%d apolo_wins=%d draws=%d out=%s" % [
		int(summary.get("episodes", 0)),
		int(winners.get("UMBRA", 0)),
		int(winners.get("APOLO", 0)),
		int(winners.get("DRAW", 0)),
		output_dir
	])
	quit(0)


func _parse_options() -> Dictionary:
	var options: Dictionary = {
		"episodes": 64,
		"max_steps": 1800,
		"seed": 7705,
		"out": "user://umbra_selfplay"
	}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--episodes="):
			options["episodes"] = max(1, int(argument.trim_prefix("--episodes=")))
		elif argument.begins_with("--generations="):
			options["episodes"] = max(1, int(argument.trim_prefix("--generations=")))
		elif argument.begins_with("--max-steps="):
			options["max_steps"] = max(60, int(argument.trim_prefix("--max-steps=")))
		elif argument.begins_with("--seed="):
			options["seed"] = int(argument.trim_prefix("--seed="))
		elif argument.begins_with("--out="):
			options["out"] = argument.trim_prefix("--out=")
		elif argument.begins_with("--manifestation="):
			options["manifestation"] = argument.trim_prefix("--manifestation=")
		elif argument.begins_with("--spectrum="):
			options["spectrum"] = argument.trim_prefix("--spectrum=")
	return options


func _write_outputs(output_dir: String, result: Dictionary) -> int:
	var absolute_dir: String = ProjectSettings.globalize_path(output_dir)
	var dir_error: int = DirAccess.make_dir_recursive_absolute(absolute_dir)
	if dir_error != OK:
		return dir_error
	var report: Dictionary = {
		"schema_version": int(result.get("schema_version", 1)),
		"summary": Dictionary(result.get("summary", {})),
		"generated_unix": int(Time.get_unix_time_from_system())
	}
	var files: Dictionary = {
		"umbra_selfplay_report.json": report,
		"umbra_selfplay_memory.json": Dictionary(result.get("memory", {})),
		"umbra_selfplay_episodes.json": Array(result.get("episodes", []))
	}
	for file_name in files.keys():
		var path: String = output_dir.path_join(String(file_name))
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			return FileAccess.get_open_error()
		file.store_string(JSON.stringify(files[file_name], "\t"))
		file.store_string("\n")
	return OK
