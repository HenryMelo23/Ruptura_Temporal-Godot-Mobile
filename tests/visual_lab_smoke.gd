extends SceneTree

const OUTPUT_DIR := "res://dev/visual_lab/screenshots"

var lab: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	lab = load("res://dev/visual_lab/visual_lab.tscn").instantiate()
	root.add_child(lab)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await process_frame
	await process_frame
	if lab.has_method("_play_current_demo"):
		lab.call("_play_current_demo")
	await create_timer(0.35).timeout
	_save_view("visual_lab_desktop.png")
	root.size = Vector2i(960, 540)
	if lab.has_method("_set_demo"):
		lab.call("_set_demo", 2)
	await process_frame
	await create_timer(0.25).timeout
	_save_view("visual_lab_mobile_landscape.png")
	print("VISUAL_LAB_SMOKE_OK desktop=true mobile_landscape=true")
	quit(0)


func _save_view(name: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("VISUAL_LAB_SMOKE failed to capture image for " + name)
		return
	var path := OUTPUT_DIR + "/" + name
	var err := image.save_png(path)
	if err != OK:
		push_error("VISUAL_LAB_SMOKE failed to save " + name + ": " + error_string(err))
		return
	print("IMAGE_SAVED: ", ProjectSettings.globalize_path(path), " size: ", image.get_size())
