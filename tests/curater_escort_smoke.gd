extends SceneTree

## Curater e suporte: procura um aliado, fica ATRAS dele (do lado oposto ao
## jogador) e nao parte para cima do jogador. Sozinho, mantem distancia.

var game: Node
var failed := false


func _check(cond: bool, msg: String) -> void:
	if cond:
		return
	failed = true
	push_error("CURATER_ESCORT_FAIL " + msg)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _curater() -> Dictionary:
	for enemy in game.enemies:
		if String(enemy.get("type", "")) == game.ENEMY_CURATER:
			return enemy
	return {}


func _run() -> void:
	await process_frame
	game._start_game()
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.set_process(false)
	game.mode = "game"
	game.spawn_timer = 99999.0
	game.enemies.clear()
	game.player_pos = Vector2(1200.0, 900.0)

	# 1) Com aliado: termina atras dele.
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(220.0, 0.0))
	var ally: Dictionary = game.enemies[-1]
	ally["speed"] = 0.0 # o aliado segura a posicao para medir a escolta
	game._spawn_enemy(game.ENEMY_CURATER, game.player_pos + Vector2(380.0, 260.0))
	var cur: Dictionary = _curater()
	_check(not cur.is_empty(), "curater did not spawn")
	var closest := INF
	for i in range(240):
		game._move_enemy(cur, 1.0 / 30.0)
		closest = minf(closest, Vector2(cur["pos"]).distance_to(game.player_pos))
	var ally_pos: Vector2 = Vector2(ally["pos"])
	var cur_pos: Vector2 = Vector2(cur["pos"])
	var shield_dir: Vector2 = (ally_pos - game.player_pos).normalized()
	_check((cur_pos - ally_pos).normalized().dot(shield_dir) > 0.8, "curater is not behind its ally (dot=%.2f)" % (cur_pos - ally_pos).normalized().dot(shield_dir))
	_check(cur_pos.distance_to(ally_pos) < 130.0, "curater did not stay close to its ally (%.0f)" % cur_pos.distance_to(ally_pos))
	_check(cur_pos.distance_to(game.player_pos) > ally_pos.distance_to(game.player_pos), "curater is closer to the player than its shield")
	_check(cur_pos.distance_to(ally_pos) <= 210.0, "curater left its heal range")

	# 2) Sozinho: nao avanca no jogador.
	game.enemies.erase(ally)
	cur["curater_escort_timer"] = 0.0
	for i in range(300):
		game._move_enemy(cur, 1.0 / 30.0)
		closest = minf(closest, Vector2(cur["pos"]).distance_to(game.player_pos))
	var alone_dist: float = Vector2(cur["pos"]).distance_to(game.player_pos)
	_check(alone_dist >= game.CURATER_ALONE_MIN_DISTANCE - 40.0, "lonely curater approached the player (%.0f)" % alone_dist)

	# 3) Jogador colado: foge.
	cur["pos"] = game.player_pos + Vector2(80.0, 0.0)
	var before: float = Vector2(cur["pos"]).distance_to(game.player_pos)
	for i in range(20):
		game._move_enemy(cur, 1.0 / 30.0)
	_check(Vector2(cur["pos"]).distance_to(game.player_pos) > before, "curater did not flee from a close player")

	print("CURATER_ESCORT_SMOKE_%s closest=%.0f" % ["FAIL" if failed else "OK", closest])
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
