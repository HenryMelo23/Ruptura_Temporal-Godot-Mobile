extends SceneTree

const OUTPUT := "res://.agent_logs/player_fire"
const DIRECTIONS := [Vector2.DOWN, Vector2.UP, Vector2(1, -1), Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1)]
var game: Node
var comparison_layer: Node2D
var board: bool = true
var failed: bool = false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("DIRECTIONAL_FIRE_VISUAL_FAIL " + message)


func _draw_board() -> void:
	if not board:
		return
	comparison_layer.draw_rect(Rect2(0, 0, 1280, 720), Color("101820"))
	comparison_layer.draw_string(ThemeDB.fallback_font, Vector2(30, 30), "REFERÊNCIA STOP  /  DISPARO DIRECIONAL — tamanho de jogo e ampliação 2x", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	for frame in range(2):
		for column in range(7):
			var x: float = 96.0 + column * 180.0
			var y: float = 62.0 + frame * 325.0
			var label: String = "STOP " + str(frame) if column == 0 else String(game.PLAYER_FIRE_DIRECTIONS[column - 1]) + " " + str(frame)
			comparison_layer.draw_string(ThemeDB.fallback_font, Vector2(x - 65, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("79dada"))
			var tex: Texture2D
			var size: Vector2
			if column == 0:
				tex = game.textures["player_idle"][frame]
				size = game.PLAYER_DRAW_STOP_SIZE
			else:
				game._set_player_attack_visual_dir(DIRECTIONS[column - 1])
				tex = game._player_fire_texture_for_current_attack(frame * game.PLAYER_FIRE_FRAME_SECONDS + 0.005)
				size = tex.get_size() * game.PLAYER_FIRE_CANVAS_HEIGHT / tex.get_height()
			for scale_factor in [1.0, 2.0]:
				var bottom: float = y + (105.0 if scale_factor == 1.0 else 292.0)
				comparison_layer.draw_line(Vector2(x - 75, bottom), Vector2(x + 75, bottom), Color("29494b"), 1.0)
				comparison_layer.draw_texture_rect(tex, Rect2(Vector2(x - size.x * scale_factor * 0.5, bottom - size.y * scale_factor), size * scale_factor), false)


func _capture(name: String) -> void:
	game.queue_redraw()
	comparison_layer.queue_redraw()
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	_check(screenshot.save_png(OUTPUT + "/" + name + ".png") == OK, "capture " + name)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.orientation_poll_timer = 9999.0
	game._start_game(false)
	game.set_process(false)
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(640, 420)
	game.last_damage_time = -100.0
	game.last_dash_time = -100.0
	game.manifestation_key = "eletrica"
	game.move_touch_index = -1
	game.touch_move = Vector2.ZERO
	comparison_layer = Node2D.new()
	root.add_child(comparison_layer)
	comparison_layer.draw.connect(_draw_board)
	await _capture("comparison")
	board = false
	for viewport in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = viewport
		game.ui_platform_override_unlocked = true
		game.ui_platform_override = "desktop" if viewport.x == 1280 else "android"
		for i in range(DIRECTIONS.size()):
			game.time_alive = 20.0
			game.last_attack_time = -100.0
			game.last_facing = DIRECTIONS[i].normalized()
			game.bullets.clear()
			game.attack_dragging = true
			game.attack_drag_direction = DIRECTIONS[i].normalized()
			game._try_attack()
			game.attack_dragging = false
			_check(not game.bullets.is_empty(), "real attack did not emit a projectile")
			_check(game.player_attack_visual_dir.dot(DIRECTIONS[i].normalized()) > 0.999, "real shot lost aim direction")
			for frame in range(2):
				game.time_alive = 20.0 + frame * game.PLAYER_FIRE_FRAME_SECONDS + 0.005
				await _capture("%dx%d_%s_%d" % [viewport.x, viewport.y, game.PLAYER_FIRE_DIRECTIONS[i], frame])
	game.move_touch_index = 0
	game.touch_move = Vector2.RIGHT
	await _capture("moving_attack")
	_check(game.textures["player_right"].has(game._player_texture()), "moving attack replaced walk")
	game.queue_free()
	comparison_layer.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	if not failed:
		print("DIRECTIONAL_FIRE_VISUAL_OK desktop=true mobile=true directions=6 frames=2 moving=true comparison=true")
	quit(1 if failed else 0)
