extends SceneTree

# Technical import only: generated artwork is never painted or recolored.
# Key out the generator's green backdrop, pack equal cells and align the ground.
func _initialize() -> void:
	for entry in [["core", 6, 4], ["extra", 4, 4]]:
		var source := Image.load_from_file("res://art_sources/lacerante/%s_keyed.png" % entry[0])
		if source == null:
			push_error("Missing generated source " + entry[0])
			quit(1)
			return
		source.convert(Image.FORMAT_RGBA8)
		for y in range(source.get_height()):
			for x in range(source.get_width()):
				var pixel := source.get_pixel(x, y)
				if pixel.g > 0.28 and pixel.g > pixel.r * 1.35 and pixel.g > pixel.b * 1.35:
					source.set_pixel(x, y, Color.TRANSPARENT)
		var columns: int = entry[1]
		var rows: int = entry[2]
		var atlas := Image.create(columns * 256, rows * 256, false, Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		for row in range(rows):
			for col in range(columns):
				var start := Vector2i(roundi(float(col) * source.get_width() / columns), roundi(float(row) * source.get_height() / rows))
				var end := Vector2i(roundi(float(col + 1) * source.get_width() / columns), roundi(float(row + 1) * source.get_height() / rows))
				var cell := source.get_region(Rect2i(start, end - start))
				cell.resize(256, 256, Image.INTERPOLATE_NEAREST)
				var used := cell.get_used_rect()
				var offset := Vector2i(0, 240 - used.end.y)
				# Keep raised blades inside the cell even during the overhead poses.
				offset.y = maxi(offset.y, -used.position.y)
				var aligned := Image.create(256, 256, false, Image.FORMAT_RGBA8)
				aligned.fill(Color.TRANSPARENT)
				aligned.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), offset)
				atlas.blit_rect(aligned, Rect2i(Vector2i.ZERO, aligned.get_size()), Vector2i(col, row) * 256)
		var result := atlas.save_png("res://assets/sprites/player/lacerante/%s.png" % entry[0])
		if result != OK:
			push_error("Unable to save atlas " + entry[0])
			quit(1)
			return
		print("LACERANTE_ATLAS_IMPORTED ", entry[0], " frames=", columns * rows)
	quit()
