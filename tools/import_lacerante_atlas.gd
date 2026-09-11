extends SceneTree

# Technical packing only; the original generated artwork is not repainted.
# Measured gutters and foot pivots: the source sheets are not exact grids.
const SPECS := {
	"core": {
		"columns": 6, "scale": 0.88,
		"ys": [0, 266, 515, 767, 1024],
		"xs": [
			[0, 256, 505, 752, 1017, 1280, 1536],
			[0, 256, 512, 768, 1024, 1280, 1536],
			[0, 256, 512, 790, 1024, 1250, 1536],
			[0, 240, 530, 750, 1024, 1264, 1536]],
		"feet": [
			Vector2i(150, 256), Vector2i(397, 256), Vector2i(639, 256), Vector2i(885, 256), Vector2i(1158, 256), Vector2i(1399, 256),
			Vector2i(145, 500), Vector2i(394, 500), Vector2i(631, 500), Vector2i(898, 500), Vector2i(1128, 500), Vector2i(1387, 500),
			Vector2i(130, 756), Vector2i(387, 756), Vector2i(638, 756), Vector2i(891, 756), Vector2i(1145, 756), Vector2i(1415, 756),
			Vector2i(129, 996), Vector2i(357, 996), Vector2i(646, 996), Vector2i(893, 996), Vector2i(1142, 996), Vector2i(1380, 996)]
	},
	"extra": {
		"columns": 4, "scale": 0.72,
		"ys": [0, 312, 607, 917, 1254],
		"xs": [[0, 313, 625, 941, 1254], [0, 313, 627, 941, 1254], [0, 310, 638, 960, 1254], [0, 313, 627, 941, 1254]],
		"feet": [
			Vector2i(153, 278), Vector2i(434, 287), Vector2i(800, 298), Vector2i(1090, 297),
			Vector2i(149, 596), Vector2i(466, 599), Vector2i(786, 599), Vector2i(1114, 599),
			Vector2i(153, 886), Vector2i(480, 887), Vector2i(808, 891), Vector2i(1095, 896),
			Vector2i(158, 1209), Vector2i(480, 1209), Vector2i(802, 1209), Vector2i(1117, 1209)]
	}
}


func _initialize() -> void:
	for name in SPECS:
		var spec: Dictionary = SPECS[name]
		var source := Image.load_from_file("res://art_sources/lacerante/%s_keyed.png" % name)
		if source == null:
			push_error("Missing generated source " + name)
			quit(1)
			return
		source.convert(Image.FORMAT_RGBA8)
		for y in range(source.get_height()):
			for x in range(source.get_width()):
				var pixel := source.get_pixel(x, y)
				if pixel.g > 0.28 and pixel.g > pixel.r * 1.35 and pixel.g > pixel.b * 1.35:
					source.set_pixel(x, y, Color.TRANSPARENT)
		var columns: int = spec.columns
		var rows: int = 4
		var atlas := Image.create(columns * 320, rows * 256, false, Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		for row in range(rows):
			for col in range(columns):
				var start := Vector2i(spec.xs[row][col], spec.ys[row])
				var end := Vector2i(spec.xs[row][col + 1], spec.ys[row + 1])
				var cell := source.get_region(Rect2i(start, end - start))
				var used := cell.get_used_rect()
				var art := cell.get_region(used)
				var factor: float = spec.scale
				art.resize(roundi(art.get_width() * factor), roundi(art.get_height() * factor), Image.INTERPOLATE_NEAREST)
				var feet: Vector2i = spec.feet[row * columns + col]
				var local_feet := Vector2(feet - start - used.position) * factor
				var offset := Vector2i(160 - roundi(local_feet.x), 240 - roundi(local_feet.y))
				if not Rect2i(2, 2, 316, 252).encloses(Rect2i(offset, art.get_size())):
					push_error("Lacerante frame would clip: %s/%d" % [name, row * columns + col])
					quit(1)
					return
				atlas.blit_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), Vector2i(col * 320, row * 256) + offset)
		var result := atlas.save_png("res://assets/sprites/player/lacerante/%s.png" % name)
		if result != OK:
			push_error("Unable to save atlas " + name)
			quit(1)
			return
		print("LACERANTE_ATLAS_IMPORTED ", name, " frames=", columns * rows, " uniform_scale=true foot_pivots=true")
	quit()
