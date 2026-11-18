extends SceneTree

## Geovana base v2: instalacao das texturas, escala unica (80 px de pe, pes em
## player_pos + 40) e captura de todas as poses em .codex/geovana_v2/poses.png.
var game: Node
var failed := false
var crops: Array = []
var labels: Array = []


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("GEOVANA_V2_FAIL " + msg)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _state(move: Vector2, fire_dir: Vector2 = Vector2.ZERO, fire_t: float = -1.0, damage_t: float = -1.0) -> void:
	game.manifestation_key = "eletrica"
	game.player_freeze_visual_timer = 0.0
	game.lacerante_preparing = false
	game.last_dash_time = -10.0
	game.move_touch_index = 0 if move.length() > 0.0 else -1
	game.touch_move = move
	game.last_attack_time = game.time_alive - fire_t if fire_t >= 0.0 else -10.0
	if fire_dir.length() > 0.0:
		game._set_player_attack_visual_dir(fire_dir)
	game.last_damage_time = game.time_alive - damage_t if damage_t >= 0.0 else -10.0
	game.enemies.clear()
	game.enemy_bullets.clear()


func _grab(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var vp: Vector2 = Vector2(root.size)
	var p: Vector2 = game.player_pos - game._camera(vp)
	crops.append(img.get_region(Rect2i(Vector2i(p) - Vector2i(80, 110), Vector2i(160, 170))))
	labels.append(label)


func _pose(label: String, move: Vector2, fire_dir := Vector2.ZERO, fire_t := -1.0, damage_t := -1.0, clock := 0.0) -> void:
	# Jogo parado: so o desenho le o estado, entao a pose fica exata.
	game.time_alive = 100.0 + clock
	_state(move, fire_dir, fire_t, damage_t)
	game.queue_redraw()
	await process_frame
	await _grab(label)


func _run() -> void:
	await process_frame
	_check(RTGeovanaV2.available(), "arte v2 ausente")
	var capture: bool = DisplayServer.get_name() != "headless"
	game.startup_thanks_done = true
	game._start_game()
	game._story().queue.clear()
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	# Texturas instaladas e escala.
	for key in ["player_idle", "player_right", "player_up", "player_down", "player_fire", "player_fire_north", "player_fire_south", "player_damage", "player_start_down"]:
		var list: Array = game.textures.get(key, [])
		_check(not list.is_empty() and RTGeovanaV2.is_v2(list[0]), key + " nao e v2")
	_check(game.textures["player_start_down"].size() == 8, "queda deveria ter 8 quadros")
	_check(is_equal_approx(RTGeovanaV2.DRAW_HEIGHT * RTGeovanaV2.STAND_H / RTGeovanaV2.CANVAS, 80.0), "pose de pe deveria medir 80 px")
	var prof: Dictionary = game._player_draw_profile()
	_check(bool(prof.get("preserve_height", false)) and is_equal_approx(float(prof["height"]), RTGeovanaV2.DRAW_HEIGHT), "perfil de desenho v2")
	if not capture:
		if not failed:
			print("GEOVANA_V2_SMOKE_OK headless")
		quit(1 if failed else 0)
		return
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.codex/geovana_v2"))
	await process_frame
	game.set_process(false)
	await _pose("repouso", Vector2.ZERO)
	for i in 6:
		await _pose("direita %d" % i, Vector2.RIGHT, Vector2.ZERO, -1.0, -1.0, 0.105 * i)
	await _pose("esquerda", Vector2.LEFT)
	for i in [0, 2, 4]:
		await _pose("baixo %d" % i, Vector2.DOWN, Vector2.ZERO, -1.0, -1.0, 0.12 * i)
	for i in [0, 2, 4]:
		await _pose("cima %d" % i, Vector2.UP, Vector2.ZERO, -1.0, -1.0, 0.12 * i)
	for i in 4:
		await _pose("tiro L %d" % i, Vector2.ZERO, Vector2.RIGHT, 0.01 + 0.045 * i)
	for d in [["O", Vector2.LEFT], ["S", Vector2.DOWN], ["N", Vector2.UP], ["NE", Vector2(1, -1)], ["NO", Vector2(-1, -1)], ["SE", Vector2(1, 1)], ["SO", Vector2(-1, 1)]]:
		await _pose("tiro " + String(d[0]), Vector2.ZERO, d[1], 0.1)
	for i in 4:
		await _pose("dano %d" % i, Vector2.ZERO, Vector2.ZERO, -1.0, 0.01 + 0.07 * i)
	# Queda inicial: timers postos a mao (jogo parado).
	game._begin_player_start_down_intro()
	for k in [0.15, 0.5, 0.85]:
		game.player_start_down_fall_timer = game.PLAYER_START_DOWN_FALL_TIME * (1.0 - k)
		game.player_start_down_landing_timer = game.PLAYER_START_DOWN_LAND_TIME
		_state(Vector2.ZERO)
		game.queue_redraw()
		await process_frame
		await _grab("queda %.2f" % k)
	for k in [0.05, 0.3, 0.5, 0.7, 0.95]:
		game.player_start_down_fall_timer = 0.0
		game.player_start_down_landing_timer = game.PLAYER_START_DOWN_LAND_TIME * (1.0 - k)
		_state(Vector2.ZERO)
		game.queue_redraw()
		await process_frame
		await _grab("pouso %.2f" % k)
	var cols := 8
	var rows: int = int(ceil(float(crops.size()) / float(cols)))
	var sheet := Image.create(160 * cols, 170 * rows, false, Image.FORMAT_RGBA8)
	for i in crops.size():
		var c: Image = crops[i]
		c.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i((i % cols) * 160, (i / cols) * 170))
	sheet.save_png("res://.codex/geovana_v2/poses.png")
	print("GEOVANA_V2_SMOKE_OK poses=%d labels=%s" % [crops.size(), ", ".join(labels)])
	quit(1 if failed else 0)
