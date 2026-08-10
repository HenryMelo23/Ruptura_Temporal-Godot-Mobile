extends SceneTree

const SCREENSHOT_PATH := "res://.agent_logs/phase7_pangoliro_side_by_side.png"

var game: Node


func _fail(message: String) -> void:
	push_error("PHASE7_PANGOLIRO_COMPARE_FAIL " + message)
	_cleanup()
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.gameplay_cheat_text = "FASE7"
	game._try_unlock_retornante_cheat()
	game.selected_manifestation = 0
	game.selected_aura = 0
	game._start_game()
	game.startup_thanks_done = true
	game.mode = "game"
	game.current_phase = 7
	game.player_pos = game.WORLD_SIZE * 0.5
	game.enemies.clear()
	game.effects.clear()
	game.phase7_ember_patches.clear()

	var walk_pos: Vector2 = game.player_pos + Vector2(-250.0, -20.0)
	var roll_pos: Vector2 = game.player_pos + Vector2(250.0, -20.0)
	game._spawn_enemy(game.ENEMY_PANGOLIRO, walk_pos)
	game._spawn_enemy(game.ENEMY_PANGOLIRO, roll_pos)

	var walk_enemy: Dictionary = game.enemies[0]
	walk_enemy["phase7_state"] = "walk"
	walk_enemy["phase"] = 0.0
	walk_enemy["facing_dir"] = Vector2.RIGHT

	var roll_enemy: Dictionary = game.enemies[1]
	roll_enemy["phase7_state"] = "roll"
	roll_enemy["phase"] = 0.0
	roll_enemy["phase7_timer"] = game.PHASE7_PANGOLIRO_ROLL_TIME * 0.38
	roll_enemy["phase7_roll_dir"] = Vector2.RIGHT
	roll_enemy["facing_dir"] = Vector2.RIGHT

	var walk_size: Vector2 = game._enemy_draw_size(walk_enemy)
	var roll_size: Vector2 = walk_size * game.PHASE7_PANGOLIRO_ROLL_VISUAL_SCALE
	print("PHASE7_PANGOLIRO_COMPARE_SIZES walk=", walk_size, " roll=", roll_size, " scale=", game.PHASE7_PANGOLIRO_ROLL_VISUAL_SCALE)

	game._add_text("ANDANDO " + str(walk_size), walk_pos + Vector2(0, -74), Color(0.92, 0.95, 1.0), 4.0, 22)
	game._add_text("GIRANDO " + str(roll_size), roll_pos + Vector2(0, -82), Color(1.0, 0.62, 0.22), 4.0, 22)
	game.queue_redraw()

	await process_frame
	await process_frame
	await process_frame

	if DisplayServer.get_name() == "headless":
		print("PHASE7_PANGOLIRO_COMPARE_OK logic_only=true screenshot_skipped=headless")
		_cleanup()
		quit(0)
		return

	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		_fail("viewport texture unavailable")
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		_fail("viewport image unavailable")
		return
	var path := ProjectSettings.globalize_path(SCREENSHOT_PATH)
	if image.save_png(path) != OK:
		_fail("could not save screenshot")
		return
	print("PHASE7_PANGOLIRO_COMPARE_OK screenshot=", path)
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
