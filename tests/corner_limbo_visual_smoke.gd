extends SceneTree

const OUTPUT := "res://.agent_logs/corner_limbo_visual_smoke.png"

var game: Node


func _fail(message: String) -> void:
	push_error("CORNER_LIMBO_VISUAL_FAIL " + message)
	_cleanup()
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.agent_logs"))
	await process_frame
	game.startup_thanks_done = true
	game._start_game()
	game.mode = "game"
	game.player_pos = Vector2.ZERO
	game.enemies.clear()
	game.effects.clear()
	game.queue_redraw()

	await process_frame
	await process_frame
	await process_frame

	var viewport := Vector2(root.size)
	var camera: Vector2 = game._camera(viewport)
	var rects: Array = game._corner_limbo_rects(camera, viewport)
	if rects.is_empty():
		_fail("expected corner limbo rects at top-left map corner")
		return

	if DisplayServer.get_name() == "headless":
		print("CORNER_LIMBO_VISUAL_OK logic_only=true rects=", rects.size(), " camera=", camera)
		_cleanup()
		quit(0)
		return

	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("viewport image unavailable")
		return
	var output_path := ProjectSettings.globalize_path(OUTPUT)
	if image.save_png(output_path) != OK:
		_fail("could not save screenshot")
		return
	print("CORNER_LIMBO_VISUAL_OK screenshot=", output_path, " rects=", rects.size(), " camera=", camera)
	_cleanup()
	quit(0)


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	if game.get_parent() == root:
		root.remove_child(game)
	game.free()
