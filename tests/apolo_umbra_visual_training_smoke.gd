extends SceneTree

const OUTPUT_DIR := "res://.codex/apolo_umbra_visual_training"


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://debug/ApoloUmbraVisualTraining.tscn") as PackedScene
	if packed == null:
		_fail("failed to load visual training scene")
		return
	var lab := packed.instantiate()
	lab.autoplay = false
	root.add_child(lab)
	await process_frame
	await process_frame
	lab.configure_for_smoke(3, 90, 45)

	var snap: Dictionary = {}
	for _i in range(16):
		snap = lab.step_visual_training(45)
		await process_frame
		if int(snap.get("completed_episodes", 0)) >= 2:
			break

	if int(snap.get("completed_episodes", 0)) < 2:
		_fail("visual training did not complete two generations")
		return
	snap = lab.step_visual_training(24)
	await process_frame
	var state: Dictionary = Dictionary(snap.get("state", {}))
	if state.is_empty():
		_fail("snapshot state is empty")
		return
	if not state.has("player_pos") or not state.has("umbra_pos"):
		_fail("snapshot missing actor positions")
		return
	if Array(snap.get("top_umbra_memory", [])).is_empty():
		_fail("top UMBRA memory is empty")
		return
	if Array(snap.get("top_apolo_memory", [])).is_empty():
		_fail("top APOLO memory is empty")
		return
	var winners: Dictionary = Dictionary(snap.get("winners", {}))
	var total_winners := int(winners.get("UMBRA", 0)) + int(winners.get("APOLO", 0)) + int(winners.get("DRAW", 0))
	if total_winners < 2:
		_fail("winner accounting did not advance")
		return

	var display_name := DisplayServer.get_name().to_lower()
	if display_name.contains("headless"):
		print("APOLO_UMBRA_VISUAL_TRAINING_SCREENSHOT_SKIP display=" + display_name)
	else:
		DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
		await process_frame
		await process_frame
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			_fail("could not capture visual training viewport")
			return
		var screenshot_path := OUTPUT_DIR + "/apolo_umbra_visual_training_smoke.png"
		if image.save_png(ProjectSettings.globalize_path(screenshot_path)) != OK:
			_fail("could not save visual training screenshot")
			return
		print("IMAGE_SAVED: ", ProjectSettings.globalize_path(screenshot_path), " size: ", image.get_size())

	print("APOLO_UMBRA_VISUAL_TRAINING_SMOKE_OK completed=%d winners=%s" % [
		int(snap.get("completed_episodes", 0)),
		str(winners)
	])
	lab.queue_free()
	for _i in range(4):
		await process_frame
	quit(0)


func _fail(message: String) -> void:
	push_error("APOLO_UMBRA_VISUAL_TRAINING_SMOKE_FAIL: " + message)
	quit(1)
