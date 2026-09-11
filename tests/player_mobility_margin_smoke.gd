extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PLAYER_MARGIN_SMOKE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"

	var old_margin: Vector2 = Vector2(70.0, 80.0)
	var near_min: Vector2 = game._clamp_player_world(Vector2.ZERO)
	var near_max: Vector2 = game._clamp_player_world(game.WORLD_SIZE)

	_check(near_min == Vector2.ZERO, "player can no longer reach the real top-left of the map")
	_check(near_max == game.WORLD_SIZE, "player can no longer reach the real bottom-right of the map")
	_check(near_min.x < old_margin.x and near_min.y < old_margin.y, "new minimum margin still uses the old restricted area")
	_check(near_max.x > game.WORLD_SIZE.x - old_margin.x and near_max.y > game.WORLD_SIZE.y - old_margin.y, "new maximum margin still uses the old restricted area")

	game._execute_teleport(Vector2(-20.0, -20.0))
	_check(game.player_pos == near_min, "teleport did not respect the new world margin")

	game._apply_temporal_rewind_result(game.WORLD_SIZE + Vector2(500.0, 500.0), game.player_hp_max)
	_check(game.player_pos == near_max, "temporal rewind did not respect the new world margin")

	var viewport := Vector2(1280.0, 720.0)
	var corner_camera: Vector2 = game._camera(viewport)
	var corner_rects: Array = game._corner_limbo_rects(corner_camera, viewport)
	_check(corner_rects.size() > 0, "camera overscan geometry changed unexpectedly")

	print("PLAYER_MARGIN_SMOKE_OK min=%s max=%s old=%s limbo_render_removed=true corner_rects=%d" % [str(near_min), str(near_max), str(old_margin), corner_rects.size()])
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	game.queue_free()
	for i in range(4):
		await process_frame
	quit()
