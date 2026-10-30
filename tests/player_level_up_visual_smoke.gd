extends SceneTree

const OUT_DESKTOP := "res://.codex/geovana_level_up_1280x720.png"
const OUT_MOBILE := "res://.codex/geovana_level_up_960x540.png"

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PLAYER_LEVEL_UP_VISUAL_FAIL " + message)
	quit(1)


func _capture(path: String, size: Vector2i) -> void:
	root.size = size
	game.queue_redraw()
	for _frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image != null and image.get_size() == size, "invalid_capture=" + path)
	_check(image.save_png(path) == OK, "save_failed=" + path)


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	game._start_game()
	game.mode = "game"
	game.preview_capture_mode = true
	game.active_character_key = game.CHARACTER_GEOVANA
	game.player_pos = game.WORLD_SIZE * 0.5
	game.boss_ready = true
	game.heal_orbs.clear()
	game.player_run_level = 1
	game.player_run_xp = 0
	game.effects.clear()
	var gained: int = game._player_run_level_controller().grant_xp(40)
	_check(gained == 1, "level_not_gained")
	var found := false
	for effect_value in game.effects:
		var effect: Dictionary = effect_value
		if String(effect.get("kind", "")) == "geovana_level_up" and int(effect.get("level", 0)) == 2:
			found = true
			effect["life"] = 0.92
			game._update_effects(0.0)
			break
	_check(found, "effect_missing")
	await _capture(OUT_DESKTOP, Vector2i(1280, 720))
	await _capture(OUT_MOBILE, Vector2i(960, 540))
	print("PLAYER_LEVEL_UP_VISUAL_OK level=2 captures=2")
	print(ProjectSettings.globalize_path(OUT_DESKTOP))
	print(ProjectSettings.globalize_path(OUT_MOBILE))
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	game = null
	for _frame in range(3):
		await process_frame
	quit(0)
