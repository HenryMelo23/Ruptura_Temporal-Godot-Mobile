extends SceneTree

const OUT_MANIFEST := "res://.codex/hidden_manifestations_1280x720.png"
const OUT_SPECTER := "res://.codex/hidden_specters_1280x720.png"
const OUT_MANIFEST_MOBILE := "res://.codex/hidden_manifestations_mobile_960x540.png"
const OUT_SPECTER_MOBILE := "res://.codex/hidden_specters_mobile_960x540.png"

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("HIDDEN_SELECTION_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _capture(path: String, size: Vector2i) -> void:
	root.size = size
	for _frame in range(12):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_size() == size, "invalid_capture=" + path)
	_check(image.save_png(path) == OK, "save_failed=" + path)


func _index_for_key(items: Array, key: String) -> int:
	for index in range(items.size()):
		if String(Dictionary(items[index]).get("key", "")) == key:
			return index
	return -1


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	await process_frame
	game.startup_thanks_done = true
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	game.ui_platform_override_unlocked = true
	for item_value in game._manifest_selection_visible_items(false):
		game.unlocked_manifestation_ids[String(Dictionary(item_value).get("key", ""))] = true
	for item_value in game._manifest_selection_visible_items(true):
		game.unlocked_spectrum_ids[String(Dictionary(item_value).get("key", ""))] = true

	game.selected_manifestation = _index_for_key(game.MANIFESTATIONS, "ancorada")
	game.selected_aura = _index_for_key(game.AURAS, "voraz")
	game.ui_platform_override = game.UI_PLATFORM_DESKTOP
	game._open_manifest_select()
	game.manifest_scroll_pos = float(game._manifest_selection_slot_for_index(game.selected_manifestation, false))
	await _capture(OUT_MANIFEST, Vector2i(1280, 720))

	game._start_spectrum_reveal()
	game.manifest_transition_elapsed = game.MANIFEST_SPECTRUM_TRANSITION_TIME
	game._update_manifest_selection_flow(0.016)
	game.aura_scroll_pos = float(game._manifest_selection_slot_for_index(game.selected_aura, true))
	await _capture(OUT_SPECTER, Vector2i(1280, 720))

	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	game._reset_manifest_selection_stage()
	await _capture(OUT_MANIFEST_MOBILE, Vector2i(960, 540))
	game._start_spectrum_reveal()
	game.manifest_transition_elapsed = game.MANIFEST_SPECTRUM_TRANSITION_TIME
	game._update_manifest_selection_flow(0.016)
	await _capture(OUT_SPECTER_MOBILE, Vector2i(960, 540))

	print("HIDDEN_SELECTION_VISUAL_OK")
	print(ProjectSettings.globalize_path(OUT_MANIFEST))
	print(ProjectSettings.globalize_path(OUT_SPECTER))
	print(ProjectSettings.globalize_path(OUT_MANIFEST_MOBILE))
	print(ProjectSettings.globalize_path(OUT_SPECTER_MOBILE))
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	game = null
	for _frame in range(4):
		await process_frame
	quit(0)
