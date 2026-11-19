extends SceneTree

var game: Node
var failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.camera_comfort_enabled = true
	game.camera_follow_initialized = false
	game.player_pos = Vector2(900.0, 520.0)
	game._update_comfort_camera(0.016)
	_check(game.camera_follow_center == game.player_pos, "camera did not initialize on the player")

	var stable_center: Vector2 = game.camera_follow_center
	game.player_pos += Vector2(60.0, 30.0)
	game._update_comfort_camera(0.016)
	_check(game.camera_follow_center.is_equal_approx(stable_center), "movement inside the comfort dead zone dragged the screen")

	game.player_pos = stable_center + Vector2(360.0, 0.0)
	game._update_comfort_camera(1.0 / 60.0)
	_check(game.camera_follow_center.x > stable_center.x and game.camera_follow_center.x < game.player_pos.x, "camera did not follow smoothly outside the dead zone")
	var first_follow: Vector2 = game.camera_follow_center
	for _frame in range(60):
		game._update_comfort_camera(1.0 / 60.0)
	_check(game.camera_follow_center.x > first_follow.x, "camera smoothing stopped before restoring framing")
	_check(game.player_pos.x - game.camera_follow_center.x >= 85.0, "camera erased the horizontal comfort margin")

	game.camera_comfort_enabled = false
	game.player_pos = Vector2(1200.0, 700.0)
	game._update_comfort_camera(0.016)
	_check(game.camera_follow_center == game.player_pos, "disabled comfort mode did not preserve exact legacy tracking")
	_check(game._graphics_setting_keys().has("camera_comfort"), "camera comfort toggle is missing from settings")
	_check(game._graphics_setting_value("camera_comfort") == "OFF", "camera comfort setting did not expose its state")
	for viewport_size in [Vector2(960.0, 540.0), Vector2(540.0, 960.0)]:
		var rects: Dictionary = game._graphics_settings_rects(viewport_size)
		_check(rects.has("camera_comfort") and rects.has("back"), "camera comfort layout is incomplete")
		_check(Rect2(rects.get("back", Rect2())).end.y <= viewport_size.y + 0.1, "graphics settings overflow the mobile viewport")

	game.camera_comfort_enabled = true
	game.camera_follow_initialized = false
	game.player_pos = Vector2(40.0, 40.0)
	game._update_comfort_camera(0.016)
	var camera: Vector2 = game._camera(Vector2(1280.0, 720.0))
	var overscan: Vector2 = game._map_camera_overscan(Vector2(1280.0, 720.0))
	_check(camera.x >= -overscan.x and camera.y >= -overscan.y, "comfort camera escaped map overscan bounds")

	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _frame in range(3):
		await process_frame
	if not failures.is_empty():
		for failure in failures:
			printerr("CAMERA_COMFORT_SMOKE_FAIL " + failure)
		quit(1)
		return
	print("CAMERA_COMFORT_SMOKE_OK dead_zone=true smoothing=true legacy_toggle=true bounds=true")
	quit(0)
