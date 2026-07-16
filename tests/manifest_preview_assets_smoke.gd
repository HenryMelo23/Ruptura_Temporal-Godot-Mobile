extends SceneTree

const MIN_FRAME_SIZE := Vector2i(1280, 720)
const MAX_PREVIEW_DIR_BYTES := 170 * 1024 * 1024
const PREVIEW_DIR := "res://assets/previews/manifestations"

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFEST_PREVIEW_ASSETS_FAIL " + message)
	quit(1)


func _run() -> void:
	await process_frame
	var clips := 0
	var total_bytes := 0
	var rows := int(ceil(float(game.MANIFEST_PREVIEW_FRAME_COUNT) / float(game.MANIFEST_PREVIEW_ATLAS_COLS)))
	for item in game.MANIFESTATIONS:
		var key := String(item.get("key", ""))
		for kind in game.MANIFEST_PREVIEW_KINDS:
			var path := "%s/%s_%s.webp" % [PREVIEW_DIR, key, String(kind)]
			_check(FileAccess.file_exists(path), "missing preview atlas: " + path)
			total_bytes += FileAccess.get_file_as_bytes(path).size()
			var image := Image.new()
			var err := image.load(ProjectSettings.globalize_path(path))
			_check(err == OK, "could not load preview atlas file: " + path)
			var frame_size := Vector2i(image.get_width() / game.MANIFEST_PREVIEW_ATLAS_COLS, image.get_height() / rows)
			_check(frame_size.x >= MIN_FRAME_SIZE.x and frame_size.y >= MIN_FRAME_SIZE.y, "preview too small: %s frame=%dx%d" % [path, frame_size.x, frame_size.y])
			var texture: Texture2D = game._manifest_preview_atlas(key, String(kind))
			_check(texture != null, "could not load imported preview texture: " + path)
			var texture_frame_size := Vector2i(texture.get_width() / game.MANIFEST_PREVIEW_ATLAS_COLS, texture.get_height() / rows)
			_check(texture_frame_size.x >= MIN_FRAME_SIZE.x and texture_frame_size.y >= MIN_FRAME_SIZE.y, "imported preview too small: %s frame=%dx%d" % [path, texture_frame_size.x, texture_frame_size.y])
			game.manifest_preview_atlases.erase(key + "_" + String(kind))
			_check(_has_visible_content(image), "preview atlas looks blank: " + path)
			clips += 1
	_check(total_bytes <= MAX_PREVIEW_DIR_BYTES, "preview atlases too large: %.1fMB" % (float(total_bytes) / 1048576.0))
	print("MANIFEST_PREVIEW_ASSETS_SMOKE_OK clips=%d min_frame=%dx%d size=%.1fMB" % [clips, MIN_FRAME_SIZE.x, MIN_FRAME_SIZE.y, float(total_bytes) / 1048576.0])
	game.queue_free()
	await process_frame
	quit(0)


func _has_visible_content(image: Image) -> bool:
	var bright_samples := 0
	var sample_count := 0
	for y in range(0, image.get_height(), 151):
		for x in range(0, image.get_width(), 173):
			var color := image.get_pixel(x, y)
			var luma := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			if color.a > 0.20 and luma > 0.045:
				bright_samples += 1
			sample_count += 1
	return bright_samples >= max(12, int(sample_count * 0.03))
