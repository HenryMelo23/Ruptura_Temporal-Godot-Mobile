extends SceneTree

const MapLayer = preload("res://scripts/presentation/phase_map_presentation.gd")
const PHASES := [1, 2, 3, 4, 5, 6, 7, 9]
const OUT := "res://.agent_logs/phase_maps/motion"
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("PHASE_MAP_ANIMATION_FAIL " + message)


func _capture(viewport: SubViewport) -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("PHASE_MAP_ANIMATION_FAIL rendering display required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(592, 592)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var layer := MapLayer.new()
	viewport.add_child(layer)
	for low_resource in [false, true]:
		for phase in PHASES:
			var texture: Texture2D = load("res://assets/maps/calm/phase_%d.png" % phase)
			_check(texture.get_size() == Vector2(592, 592), "unexpected texture size")
			layer.present(texture, Rect2(0, 0, 592, 592), phase, 8.0, low_resource)
			var first: Image = await _capture(viewport)
			layer.present(texture, Rect2(0, 0, 592, 592), phase, 12.5, low_resource)
			var second: Image = await _capture(viewport)
			var moving := 0
			var center_changed := 0
			var brightness_delta := 0.0
			var samples := 0
			var center_bright := 0
			var center_samples := 0
			var center_luminance := 0.0
			for y in range(0, 592, 3):
				for x in range(0, 592, 3):
					var a := first.get_pixel(x, y)
					var b := second.get_pixel(x, y)
					var difference := absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
					var central := Vector2(x - 296, y - 296).length() < 85.0
					if difference > 0.009:
						moving += 1
						if central:
							center_changed += 1
					if central and a.get_luminance() > 0.65:
						center_bright += 1
					if central:
						center_samples += 1
						center_luminance += a.get_luminance()
					brightness_delta += b.get_luminance() - a.get_luminance()
					samples += 1
			_check(moving > 15, "phase %d is static (low=%s)" % [phase, low_resource])
			_check(center_changed == 0, "central masonry moves in phase %d" % phase)
			# Sparse stone bevels are acceptable; broad luminous areas are not.
			_check(float(center_bright) / center_samples < 0.02 and center_luminance / center_samples < 0.40, "central hotspot in phase %d" % phase)
			_check(absf(brightness_delta / samples) < 0.003, "global brightness pulses in phase %d" % phase)
			var frozen: Image = await _capture(viewport)
			_check(second.get_data() == frozen.get_data(), "animation advances without gameplay time")
			_check(viewport.get_child_count() == 1, "animation leaked nodes")
			if not low_resource:
				_check(first.save_png("%s/phase_%d_a.png" % [OUT, phase]) == OK, "save frame A")
				_check(second.save_png("%s/phase_%d_b.png" % [OUT, phase]) == OK, "save frame B")
			print("PHASE_MAP_MOTION phase=%d low=%s changed_samples=%d center_changed=%d mean_delta=%.6f" % [phase, low_resource, moving, center_changed, brightness_delta / samples])
	viewport.queue_free()
	await process_frame
	print("PHASE_MAP_ANIMATION_", "FAIL" if failed else "OK", " surfaces=8 profiles=2 frozen_time=verified")
	quit(1 if failed else 0)
