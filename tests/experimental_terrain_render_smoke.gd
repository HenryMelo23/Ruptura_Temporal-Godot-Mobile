extends SceneTree

const MapLayer = preload("res://scripts/presentation/phase_map_presentation.gd")
var layer: Node2D


func _initialize() -> void:
	root.size = Vector2i(384, 384)
	layer = MapLayer.new()
	root.add_child(layer)
	call_deferred("_run")


func _capture(texture: Texture2D, camera: Vector2, anchor: Vector2, surface: int) -> Image:
	var chunks: Array[Dictionary] = [{"rect": Rect2(Vector2.ZERO, Vector2(384, 384)), "tile": 5}]
	layer.present_chunks(texture, chunks, camera, Vector2(192, 192), anchor, surface, 0.0, false)
	layer.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _run() -> void:
	for phase in [1, 2, 3, 4, 5, 6, 7]:
		var path := "res://assets/sprites/experimental/phase_ex%s_terrain_atlas.png" % (str(phase) if phase > 1 else "")
		var texture: Texture2D = load(path)
		var anchor: Vector2 = RTExperimentalPhaseController.PHASES[phase]["altar_uv"]
		var original: Image = await _capture(texture, Vector2.ZERO, anchor, phase)
		var moved: Image = await _capture(texture, Vector2(16, 16), anchor, phase)
		var largest_error := 0.0
		for y in range(24, 344, 4):
			for x in range(24, 344, 4):
				var a := original.get_pixel(x + 16, y + 16)
				var b := moved.get_pixel(x, y)
				largest_error = maxf(largest_error, maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b))))
		assert(largest_error < 0.01, "Terrain moved relative to world when camera moved")
		# The rendered interaction center must sample the authored source anchor.
		var source: Image = texture.get_image()
		var source_pos := Vector2i((Vector2.ONE + anchor) * Vector2(source.get_size()) / 4.0)
		var expected := source.get_pixelv(source_pos)
		var center := original.get_pixel(192, 192)
		var center_error := maxf(absf(center.r - expected.r), maxf(absf(center.g - expected.g), absf(center.b - expected.b)))
		assert(center_error < 0.08, "Altar artwork is offset from the interaction center")
		print("EXPERIMENTAL_TERRAIN_RENDER_PHASE_OK phase=%d camera_error=%.5f altar_center=true" % [phase, largest_error])
	layer.free()
	await process_frame
	print("EXPERIMENTAL_TERRAIN_RENDER_OK")
	quit(0)
