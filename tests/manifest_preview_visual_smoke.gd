extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _save_view(name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 1280 and image.get_height() == 720)
	var output := "res://.codex/" + name
	assert(image.save_png(output) == OK)
	print("MANIFEST_PREVIEW_VISUAL_OK " + ProjectSettings.globalize_path(output))


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	game.selected_manifestation = 2
	game.selected_aura = 0
	game._open_manifest_select()
	game.manifest_preview_open = true
	game.manifest_preview_kind = "ultimate"
	game.manifest_preview_time = 0.42
	await _save_view("manifest_preview_prismatica_1280x720.png")
	quit(0)
