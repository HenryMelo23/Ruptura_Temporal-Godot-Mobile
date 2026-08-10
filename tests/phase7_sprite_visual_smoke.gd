extends SceneTree

const SCREENSHOT_PATH := "res://.agent_logs/phase7_sprite_flip_size_after.png"

var game: Node


func _fail(message: String) -> void:
	push_error("PHASE7_SPRITE_VISUAL_FAIL " + message)
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
	game.phase7_ember_patches.clear()

	var left_pos: Vector2 = game.player_pos + Vector2(-270.0, -80.0)
	var right_pos: Vector2 = game.player_pos + Vector2(270.0, -80.0)
	var roll_pos: Vector2 = game.player_pos + Vector2(-220.0, 110.0)
	game._spawn_enemy(game.ENEMY_CINERIDO, left_pos)
	game._spawn_enemy(game.ENEMY_CINERIDO, right_pos)
	game._spawn_enemy(game.ENEMY_CORVOL, game.player_pos + Vector2(-300.0, 60.0))
	game._spawn_enemy(game.ENEMY_CORVOL, game.player_pos + Vector2(300.0, 60.0))
	game._spawn_enemy(game.ENEMY_PANGOLIRO, roll_pos)

	for enemy in game.enemies:
		var enemy_pos: Vector2 = Vector2(enemy.get("pos", Vector2.ZERO))
		enemy["facing_dir"] = (game.player_pos - enemy_pos).normalized()
		if String(enemy.get("type", "")) == game.ENEMY_PANGOLIRO:
			enemy["phase7_state"] = "roll"
			enemy["phase7_timer"] = game.PHASE7_PANGOLIRO_ROLL_TIME * 0.38
			enemy["phase7_roll_dir"] = Vector2.RIGHT
			enemy["facing_dir"] = Vector2.RIGHT

	var pangoliro: Dictionary = game.enemies.filter(func(enemy): return String(enemy.get("type", "")) == game.ENEMY_PANGOLIRO)[0]
	var pangoliro_size: Vector2 = game._enemy_draw_size(pangoliro)
	if not is_equal_approx(pangoliro_size.x, 144.0) or not is_equal_approx(pangoliro_size.y, 90.0):
		_fail("Pangoliro walking draw size should be tripled for phase 7 readability: " + str(pangoliro_size))
		return
	var pangoliro_roll_size: Vector2 = pangoliro_size * game.PHASE7_PANGOLIRO_ROLL_VISUAL_SCALE
	if not is_equal_approx(pangoliro_roll_size.x, 115.2) or not is_equal_approx(pangoliro_roll_size.y, 72.0):
		_fail("Pangoliro rolling visual size should be 20 percent smaller than the enlarged walking body: " + str(pangoliro_roll_size))
		return
	var cinerido: Dictionary = game.enemies.filter(func(enemy): return String(enemy.get("type", "")) == game.ENEMY_CINERIDO)[0]
	var cinerido_size: Vector2 = game._enemy_draw_size(cinerido)
	if not is_equal_approx(cinerido_size.x, 115.0) or not is_equal_approx(cinerido_size.y, 52.5):
		_fail("Cinerido draw size was not increased by 25 percent: " + str(cinerido_size))
		return
	if not is_equal_approx(float(game.PHASE7_PANGOLIRO_ROLL_VISUAL_TURNS), 4.2):
		_fail("Pangoliro roll visual turns should be 40 percent faster")
		return
	if not is_equal_approx(float(game.PHASE7_PANGOLIRO_ROLL_VISUAL_SCALE), 0.8):
		_fail("Pangoliro roll visual scale should be 20 percent smaller than walking")
		return
	if not game._enemy_should_flip({"type": game.ENEMY_CINERIDO, "facing_dir": Vector2.RIGHT}):
		_fail("Phase 7 right-facing enemy should be flipped because source sprites face left")
		return
	if game._enemy_should_flip({"type": game.ENEMY_CINERIDO, "facing_dir": Vector2.LEFT}):
		_fail("Phase 7 left-facing enemy should use source orientation")
		return

	game.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless":
		print("PHASE7_SPRITE_VISUAL_OK logic_only=true screenshot_skipped=headless pangoliro_size=", pangoliro_size)
		_cleanup()
		quit(0)
		return
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		print("PHASE7_SPRITE_VISUAL_OK logic_only=true screenshot_skipped=headless pangoliro_size=", pangoliro_size)
		_cleanup()
		quit(0)
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		print("PHASE7_SPRITE_VISUAL_OK logic_only=true screenshot_skipped=empty_viewport pangoliro_size=", pangoliro_size)
		_cleanup()
		quit(0)
		return
	var path := ProjectSettings.globalize_path(SCREENSHOT_PATH)
	if image.save_png(path) != OK:
		_fail("could not save screenshot")
		return
	print("PHASE7_SPRITE_VISUAL_OK ", path, " pangoliro_size=", pangoliro_size)
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
