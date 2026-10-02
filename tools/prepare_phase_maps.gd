extends SceneTree

# Mechanical atlas extraction only; artwork is generated separately.
func _initialize() -> void:
	var sources: Array[String] = []
	for argument in OS.get_cmdline_user_args():
		sources.append(argument)
	if sources.size() != 2:
		push_error("Expected the two generated atlas PNG paths.")
		quit(1)
		return
	var destination := "res://assets/maps/calm"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
	for atlas_index in range(2):
		var source := Image.load_from_file(sources[atlas_index])
		if source == null or source.get_size() != Vector2i(1254, 1254):
			push_error("Unexpected atlas dimensions; inspect boundaries before extracting.")
			quit(1)
			return
		var split_y := 627 if atlas_index == 0 else 612
		var phases := [1, 2, 3, 4] if atlas_index == 0 else [5, 6, 7, 9]
		for cell in range(4):
			var cell_origin := Vector2i((cell % 2) * 627, 0 if cell < 2 else split_y)
			var cell_size := Vector2i(627, split_y if cell < 2 else 1254 - split_y)
			# Equal square crops exclude the adjacent quadrant without stretching pixels.
			var origin := cell_origin + (cell_size - Vector2i(592, 592)) / 2
			var tile := source.get_region(Rect2i(origin, Vector2i(592, 592)))
			var path := "%s/phase_%d.png" % [destination, phases[cell]]
			if tile.save_png(path) != OK:
				push_error("Cannot save " + path)
				quit(1)
				return
			print("PHASE_MAP_ASSET ", path, " 592x592")
	quit(0)
