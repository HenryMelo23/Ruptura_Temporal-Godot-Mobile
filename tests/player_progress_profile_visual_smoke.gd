extends SceneTree

const OUT_DIR := "res://.agent_logs/player_progress_profile"

var game: Node
var failed := false


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("PLAYER_PROGRESS_PROFILE_VISUAL_FAIL " + message)


func _capture(viewport: Vector2i, name: String) -> void:
	root.size = viewport
	game.mode = "progress_profile"
	game.queue_redraw()
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_size() == viewport, "invalid capture " + name)
	_check(image.get_used_rect().size.x > viewport.x * 0.62 and image.get_used_rect().size.y > viewport.y * 0.54, "blank capture " + name)
	_check(image.save_png(OUT_DIR + "/" + name + ".png") == OK, "could not save " + name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i.ZERO
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.player_identity_auth_token = ""
	game.player_identity_recovery_code = ""
	game.player_progress_sync_status = "identity_choice_required"
	await _capture(Vector2i(1280, 720), "recover_desktop")
	_check(game.player_progress_recovery_edit.visible, "recovery input hidden without an identity")
	_check(game.player_progress_profile_buttons.has("recover") and game.player_progress_profile_buttons.has("create"), "recovery actions missing")
	await _capture(Vector2i(960, 540), "recover_mobile")

	game.player_identity_auth_token = "fixture_token"
	game.player_identity_recovery_code = "A1B2-C3D4-E5F6-0718-1920-ABCD-EF12-3456"
	game.player_progress_recovery_revealed = true
	game.player_progress_sync_status = "synced"
	game.player_progress_last_remote_confirmation = "2026-10-14T12:00:00Z"
	await _capture(Vector2i(1280, 720), "identity_created_desktop")
	_check(not game.player_progress_recovery_edit.visible, "recovery input remained visible after identity creation")
	_check(game.player_progress_profile_buttons.has("show_code") and game.player_progress_profile_buttons.has("copy_code"), "recovery code actions missing")

	print("PLAYER_PROGRESS_PROFILE_VISUAL_OK captures=3 desktop=true mobile=true recovery=true code=true")
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failed else 0)
