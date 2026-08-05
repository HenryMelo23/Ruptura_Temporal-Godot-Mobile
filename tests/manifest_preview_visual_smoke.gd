extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.startup_thanks_done = true
	call_deferred("_run")


func _save_view(name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	assert(image != null and image.get_width() > 0 and image.get_height() > 0)
	var output := "res://.codex/" + name
	assert(image.save_png(output) == OK)
	print("MANIFEST_PREVIEW_VISUAL_OK " + ProjectSettings.globalize_path(output))


func _manifest_index(key: String) -> int:
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i].get("key", "")) == key:
			return i
	return -1


func _open_preview(key: String, kind: String, time: float) -> void:
	var index := _manifest_index(key)
	assert(index >= 0)
	game.selected_manifestation = index
	game._open_manifest_select()
	game.manifest_preview_open = true
	game.manifest_details_open = false
	game.manifest_preview_kind = kind
	game.manifest_preview_time = time


func _open_details(key: String) -> void:
	var index := _manifest_index(key)
	assert(index >= 0)
	game.selected_manifestation = index
	game._open_manifest_select()
	game.manifest_preview_open = false
	game.manifest_details_open = true


func _run() -> void:
	if DisplayServer.get_name().to_lower().contains("headless"):
		print("MANIFEST_PREVIEW_VISUAL_OK headless_layout_only")
		quit(0)
		return
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	game.startup_thanks_done = true
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	game.selected_aura = 0
	_open_preview("prismatica", "ultimate", 0.42)
	await _save_view("manifest_preview_prismatica_1280x720.png")
	_open_preview("bombastica", "skill", 0.84)
	await _save_view("manifest_preview_bombastica_skill_1280x720.png")
	_open_preview("necronada", "ultimate", 1.08)
	await _save_view("manifest_preview_necronada_ultimate_1280x720.png")
	_open_details("necronada")
	await _save_view("manifest_details_necronada_1280x720.png")
	quit(0)
