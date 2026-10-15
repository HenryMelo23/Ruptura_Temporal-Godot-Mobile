extends SceneTree

var game: Node
var original_max_fps: int
var original_config_exists: bool
var original_config: PackedByteArray


func _initialize() -> void:
	original_max_fps = Engine.max_fps
	original_config_exists = FileAccess.file_exists("user://hud_config.save")
	if original_config_exists:
		original_config = FileAccess.get_file_as_bytes("user://hud_config.save")
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.ui_platform_override_unlocked = true
	game.gfx_low_resource = false
	game.gfx_memory_saver = false
	game.gfx_fps_limit = 60
	var expected: Array[int] = [120, 0, 30, 60]
	for value in expected:
		game._cycle_graphics_fps_limit()
		game._apply_graphics_settings()
		assert(game.gfx_fps_limit == value)
		assert(Engine.max_fps == value)

	game.gfx_fps_limit = 999
	game._apply_graphics_settings()
	assert(game.gfx_fps_limit == game.GRAPHICS_FPS_LIMIT_DEFAULT)
	assert(Engine.max_fps == game.GRAPHICS_FPS_LIMIT_DEFAULT)

	game.show_fps_counter = false
	game.ui_platform_override = "desktop"
	assert(not game._should_draw_desktop_fps_counter())
	assert(not game._should_draw_compact_fps_counter())
	game.show_fps_counter = true
	assert(game._should_draw_desktop_fps_counter())
	assert(not game._should_draw_compact_fps_counter())
	game.ui_platform_override = "android"
	assert(not game._should_draw_desktop_fps_counter())
	assert(game._should_draw_compact_fps_counter())

	game.gfx_fps_limit = 120
	game._save_config()
	game.gfx_fps_limit = 30
	game._load_config()
	var loaded_fps_limit: int = game.gfx_fps_limit
	_restore_original_config()
	assert(loaded_fps_limit == 120)
	game._apply_graphics_settings()
	assert(Engine.max_fps == 120)

	print("FPS_LIMIT_SETTINGS_SMOKE_OK options=30,60,120,unlimited counter=exclusive persistence=true mobile=true desktop=true")
	_cleanup()
	await process_frame
	quit(0)


func _cleanup() -> void:
	_restore_original_config()
	Engine.max_fps = original_max_fps
	if game != null:
		game._cleanup_runtime_resources()
		game.textures.clear()
		game.audio_streams.clear()
		root.remove_child(game)
		game.free()


func _restore_original_config() -> void:
	if original_config_exists:
		var file := FileAccess.open("user://hud_config.save", FileAccess.WRITE)
		if file:
			file.store_buffer(original_config)
			file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://hud_config.save"))
