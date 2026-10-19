extends SceneTree
const Gravity = preload("res://scripts/presentation/gravitante_vfx_presentation.gd")

class Gallery extends Node2D:
	var reference := false
	var submit_us := 0
	func _draw() -> void:
		var start := Time.get_ticks_usec()
		draw_rect(Rect2(0, 0, 960, 540), Color(0.08, 0.09, 0.12))
		for detail in range(4):
			for front in [false, true]:
				var center := Vector2(130 + detail * 235, 150 if front else 380)
				if not reference:
					Gravity.disk(self, center, 46.0, detail, front)
				else:
					for layer in range(2 if detail < 2 else 3):
						var key: int = detail * 10 + layer + (100 if front else 0)
						var mesh: ArrayMesh = Gravity.disk_geometry[key]
						var arrays := mesh.surface_get_arrays(0)
						draw_set_transform(center, -0.22, Vector2.ONE * 46.0)
						draw_polygon(arrays[Mesh.ARRAY_VERTEX], arrays[Mesh.ARRAY_COLOR])
						draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		submit_us = Time.get_ticks_usec() - start

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("GRAVITANTE_GEOMETRY_CACHE requires a real renderer")
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i(960, 540)
	root.size = root.content_scale_size
	var gallery := Gallery.new()
	root.add_child(gallery)
	await process_frame
	await RenderingServer.frame_post_draw
	var meshes := Gravity.disk_geometry.duplicate()
	var captures: Array[Image] = []
	for reference in [true, false]:
		gallery.reference = reference
		for frame in range(3):
			gallery.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
		captures.append(root.get_texture().get_image())
	var equal_pixels := captures[0].get_data() == captures[1].get_data()
	var cache_reused := meshes.size() == 20 and meshes == Gravity.disk_geometry
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.codex/render_optimization"))
	for index in range(2):
		captures[index].save_png("res://.codex/render_optimization/gravity_disk_%s.png" % ["before" if index == 0 else "after"])
	if not equal_pixels or not cache_reused:
		push_error("GRAVITANTE_GEOMETRY_CACHE_FAIL pixels=%s reused=%s" % [equal_pixels, cache_reused])
	else:
		print("GRAVITANTE_GEOMETRY_CACHE_OK pixel_equal=true lods=4 meshes=20 reused=true")
	gallery.free()
	quit(0 if equal_pixels and cache_reused else 1)
