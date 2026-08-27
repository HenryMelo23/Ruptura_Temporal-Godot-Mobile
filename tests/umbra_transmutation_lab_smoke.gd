extends SceneTree

const OUTPUT_DIR := "res://.codex/umbra_lab"

var target_case := "ressonancia"


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--umbra-case="):
			target_case = argument.trim_prefix("--umbra-case=").strip_edges().to_lower()
		elif argument.begins_with("--case="):
			target_case = argument.trim_prefix("--case=").strip_edges().to_lower()
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://debug/UmbraTransmutationLab.tscn") as PackedScene
	if packed == null:
		push_error("UMBRA_TRANSMUTATION_LAB_SMOKE failed to load lab scene")
		quit(1)
		return

	var lab := packed.instantiate()
	lab.autoplay_on_ready = false
	root.add_child(lab)
	await process_frame
	await process_frame
	await process_frame

	if lab.game == null:
		push_error("UMBRA_TRANSMUTATION_LAB_SMOKE lab did not instantiate Main.tscn")
		quit(1)
		return

	var skill_preview_seconds := 3.1 if target_case == "hemorragia" else 0.02
	lab.set_preview_timing(0.02, skill_preview_seconds, 0.01)
	var completed := {"value": false}
	lab.case_finished.connect(func(_case_key: String) -> void:
		completed["value"] = true
	)

	if not lab.play_case_by_key(target_case, false):
		push_error("UMBRA_TRANSMUTATION_LAB_SMOKE could not select " + target_case)
		quit(1)
		return

	var max_frames := 260 if target_case == "hemorragia" else 90
	for _i in range(max_frames):
		await process_frame
		if bool(completed["value"]):
			break

	if not bool(completed["value"]):
		push_error("UMBRA_TRANSMUTATION_LAB_SMOKE case did not finish bootstrap=%s active=%s stage=%s dim=%s hazards=%d" % [
			str(lab._bootstrap_done),
			str(lab._playback_active),
			String(lab._current_stage),
			String(lab.game.boss5_dimension) if lab.game != null else "none",
			lab.game.phase5_hazards.size() if lab.game != null else -1,
		])
		quit(1)
		return

	var expected_dimension := "hemorragia" if target_case == "hemorragia" else "ressonancia"
	if String(lab.game.boss5_dimension) != expected_dimension:
		push_error("UMBRA_TRANSMUTATION_LAB_SMOKE wrong dimension: " + String(lab.game.boss5_dimension))
		quit(1)
		return

	var found_expected := false
	for hazard in lab.game.phase5_hazards:
		var data := Dictionary(hazard)
		var kind := String(data.get("kind", ""))
		if expected_dimension == "hemorragia" and kind == "thorns":
			found_expected = true
			break
		if expected_dimension == "ressonancia" and kind == "discharge":
			found_expected = true
			break

	if not found_expected:
		push_error("UMBRA_TRANSMUTATION_LAB_SMOKE did not spawn expected hazard for " + expected_dimension)
		quit(1)
		return

	var display_name := DisplayServer.get_name().to_lower()
	if display_name.contains("headless"):
		print("UMBRA_TRANSMUTATION_LAB_SCREENSHOT_SKIP display=" + display_name)
	else:
		DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
		await process_frame
		await process_frame
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			push_error("UMBRA_TRANSMUTATION_LAB_SMOKE could not capture lab viewport")
			quit(1)
			return
		var screenshot_path := OUTPUT_DIR + "/" + expected_dimension + "_lab_smoke.png"
		if image.save_png(ProjectSettings.globalize_path(screenshot_path)) != OK:
			push_error("UMBRA_TRANSMUTATION_LAB_SMOKE could not save screenshot")
			quit(1)
			return
		print("IMAGE_SAVED: ", ProjectSettings.globalize_path(screenshot_path), " size: ", image.get_size())

	print("UMBRA_TRANSMUTATION_LAB_SMOKE_OK case=" + expected_dimension)
	lab.queue_free()
	for _i in range(4):
		await process_frame
	quit(0)
