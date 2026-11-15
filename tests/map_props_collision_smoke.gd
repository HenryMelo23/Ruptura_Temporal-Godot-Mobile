extends SceneTree

## Fisica dos objetos do mapa (RTMapPropColliders, SDF por atlas) em todas as fases
## que tem objetos solidos. Com "capture" nos argumentos salva prints com o contorno.
const PHASES := {2: [0, 10, 12, 14], 6: [0, 7, 12, 15], 7: [3, 8, 11, 15], 8: [1, 3, 9, 11]}
var game: Node
var failed := false
var shots := 0


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failed = true
		push_error("MAP_PROPS_FAIL " + msg)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _find_cell(tile: int) -> Vector2i:
	var ctrl = game.experimental_phase_controller
	for y in range(1, 5):
		for x in range(1, 8):
			if ctrl.tile_at_cell(Vector2i(x, y)) == tile:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


## Ponto mais "fundo" dentro do objeto do ladrilho.
func _deepest(cell: Vector2i) -> Vector2:
	var size: float = game.experimental_phase_controller.CHUNK_SIZE
	var best := Vector2.ZERO
	var best_d := INF
	for j in range(40):
		for i in range(40):
			var p := (Vector2(cell) + Vector2((i + 0.5) / 40.0, (j + 0.5) / 40.0)) * size
			var d := RTMapPropColliders.distance_at(game, p)
			if d < best_d:
				best_d = d
				best = p
	return best


func _run() -> void:
	await process_frame
	var capture := "capture" in OS.get_cmdline_user_args()
	game.startup_thanks_done = true
	game._start_game()
	for phase in PHASES.keys():
		game._story().queue.clear()
		game._advance_to_phase(phase)
		game._story().queue.clear()
		game.mode = "game"
		game.enemies.clear()
		_check(RTMapPropColliders.active(game), "fisica inativa na fase %d" % phase)
		for tile in PHASES[phase]:
			var cell := _find_cell(tile)
			if cell.x < 0:
				_check(false, "fase %d ladrilho %d nao encontrado" % [phase, tile])
				continue
			var core_pt := _deepest(cell)
			_check(RTMapPropColliders.distance_at(game, core_pt) < 0.0, "fase %d ladrilho %d sem objeto" % [phase, tile])
			# Dentro: empurra para fora.
			var feet: Vector2 = RTMapPropColliders.PLAYER_FEET
			var out: Vector2 = game._clamp_player_world(core_pt - feet) + feet
			_check(RTMapPropColliders.distance_at(game, out) >= RTMapPropColliders.PLAYER_RADIUS - 1.0, "fase %d ladrilho %d nao saiu de dentro" % [phase, tile])
			# Andando de 4 lados em direcao ao miolo: nunca entra.
			for side in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
				var p: Vector2 = core_pt + side * 260.0 - feet
				for k in range(90):
					p = game._clamp_player_world(p - side * 6.0)
					_check(RTMapPropColliders.distance_at(game, p + feet) >= RTMapPropColliders.PLAYER_RADIUS - 1.5, "fase %d ladrilho %d atravessou pelo lado %s" % [phase, tile, str(side)])
				if side == Vector2.DOWN and capture:
					game.player_pos = p
					await _shot(phase, tile)
			# Inimigo no chao tambem e empurrado.
			var enemy_kind: String = RTSertaoController.JABUTI if phase == 8 else game.ENEMY_COMMON
			game._spawn_enemy(enemy_kind, core_pt)
			if not game.enemies.is_empty():
				var e: Dictionary = game.enemies.back()
				e["pos"] = core_pt
				e["s8_cd"] = 99.0
				game._update_enemies(0.016)
				_check(RTMapPropColliders.distance_at(game, Vector2(e["pos"])) >= 0.0, "fase %d inimigo ficou dentro do ladrilho %d" % [phase, tile])
			game.enemies.clear()
	# Fases de piso liso nao tem fisica de objetos.
	game._advance_to_phase(3)
	_check(not RTMapPropColliders.active(game), "fase 3 nao deveria ter objetos solidos")
	if not failed:
		print("MAP_PROPS_SMOKE_OK shots=%d" % shots)
	quit(1 if failed else 0)


func _shot(phase: int, tile: int) -> void:
	game.camera_follow_initialized = false
	for i in range(6):
		await process_frame
	game.queue_redraw()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.codex/phase8/coll_%d_%d.png" % [phase, tile])
	var cam: Vector2 = game._camera(Vector2(root.size))
	var pts := ""
	for y in range(0, root.size.y, 5):
		for x in range(0, root.size.x, 5):
			var d := RTMapPropColliders.distance_at(game, cam + Vector2(x, y))
			if absf(d) < 2.6:
				pts += "%d,%d;" % [x, y]
	var f: Vector2 = game.player_pos + RTMapPropColliders.PLAYER_FEET - cam
	print("CONTOUR %d %d FEET %d %d PTS %s" % [phase, tile, int(f.x), int(f.y), pts])
	shots += 1
