extends SceneTree

## Ajustes de 2026-11-18 da Lacerante: alcance do corte x execucao, Reforco com
## alcance leve, teleporte consumindo Laceracao, pose de dano so parada e quadros
## da queda pela Fenda do Mercador.

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("LACERANTE_FEEDBACK_FAIL " + message)


func _e(pos: Vector2, hp: float) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var e: Dictionary = game.enemies[-1]
	e["pos"] = pos
	e["hp"] = hp
	e["max_hp"] = 1000.0
	e["speed"] = 0.0
	return e


func _run() -> void:
	game.startup_thanks_done = true
	game.unlocked_manifestation_ids["lacerante"] = true
	game.qa_data_unlocked = true
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i]["key"]) == "lacerante":
			game.selected_manifestation = i
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.enemies.clear()
	game.player_damage = 40.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	_check(game.manifestation_key == "lacerante", "not lacerante")
	var ex: RTLaceranteExecutionController = game._lacerante_exec()

	# Alcance: corte x execucao, e Reforco alonga levemente a lamina.
	var reach: float = game._lacerante_hit_reach(false)
	var reach_empowered: float = game._lacerante_hit_reach(true)
	_check(absf(reach - RTLaceranteExecutionController.EXECUTE_REACH) >= 8.0, "corte e execucao iguais: indicador duplo nao apareceria")
	_check(reach_empowered > reach and reach_empowered - reach <= 30.0, "Reforco deveria aumentar o alcance levemente")
	game.lacerante_empowered_ready = false
	var auto_plain: float = game._auto_attack_range()
	game.lacerante_empowered_ready = true
	_check(game._auto_attack_range() > auto_plain, "auto-alvo nao cresceu com Reforco")
	game.lacerante_empowered_ready = false
	var plain_pts: Array = game._lacerante_stage_points(Vector2.ZERO, Vector2.RIGHT, 2, false)
	var strong_pts: Array = game._lacerante_stage_points(Vector2.ZERO, Vector2.RIGHT, 2, true)
	_check(Vector2(strong_pts.back()).x > Vector2(plain_pts.back()).x, "lamina reforcada nao alongou")

	# Teleporte consome Laceracao de quem esta no caminho.
	var origin: Vector2 = game.player_pos
	var on_path := _e(origin + Vector2(80, 0), 1000.0)
	var off_path := _e(origin + Vector2(80, 300), 1000.0)
	ex.apply_laceration(on_path, 3)
	ex.apply_laceration(off_path, 3)
	game._execute_teleport(origin + Vector2(160, 0))
	_check(ex.stacks(on_path) == 0, "teleporte nao consumiu os stacks")
	_check(float(on_path["hp"]) < 1000.0, "consumo do teleporte nao causou dano")
	_check(ex.stacks(off_path) == 3, "teleporte consumiu stacks fora do caminho")
	game.enemies.clear()

	# Pose de dano: so com a personagem parada.
	game.last_damage_time = game.time_alive
	game.move_touch_index = -1
	game.touch_move = Vector2.ZERO
	_check(game.LaceranteSprites.snapshot(game, 0).x == game.NET_ANIM_DAMAGE, "parada deveria mostrar dano")
	game.move_touch_index = 0
	game.touch_move = Vector2.RIGHT
	_check(game.LaceranteSprites.snapshot(game, 0).x != game.NET_ANIM_DAMAGE, "andando nao pode usar o quadro de dano")
	_check(not game._player_damage_pose_active(), "pose de dano ativa andando")
	game.move_touch_index = -1
	game.touch_move = Vector2.ZERO

	# Quadros da queda pela fenda: todo humor/fase tem quadro da Lacerante.
	for mood in ["scared", "resigned", "stylish", "ejected"]:
		for phase in ["dive", "land", "exit_dive", "emerge"]:
			for p in [0.1, 0.5, 0.95]:
				_check(game.LaceranteSprites.rift_texture(game, mood, phase, p, 0.4) != null, "sem quadro %s/%s p=%.2f" % [mood, phase, p])
	if not failed:
		print("LACERANTE_FEEDBACK_OK reach=%.0f empowered=%.0f execute=%.0f" % [reach, reach_empowered, RTLaceranteExecutionController.EXECUTE_REACH])
	quit(1 if failed else 0)
