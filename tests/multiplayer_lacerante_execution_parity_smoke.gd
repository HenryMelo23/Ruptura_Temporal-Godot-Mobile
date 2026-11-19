extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("MULTIPLAYER_LACERANTE_EXECUTION_FAIL " + message)
	game._cleanup_runtime_resources()
	game.free()
	quit(1)


func _spawn_target(pos: Vector2, hp: float) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies[-1]
	enemy["pos"] = pos
	enemy["hp"] = hp
	enemy["max_hp"] = 100.0
	enemy["speed"] = 0.0
	return enemy


func _run() -> void:
	game.startup_thanks_done = true
	game.qa_data_unlocked = true
	game.unlocked_manifestation_ids["lacerante"] = true
	for index in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[index].get("key", "")) == "lacerante":
			game.selected_manifestation = index
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.enemies.clear()
	var remote_peer := 22
	var remote_pos: Vector2 = Vector2(game.player_pos) + Vector2(30.0, 0.0)
	game.net_players_by_peer[remote_peer] = {
		"has_snapshot": true,
		"alive": true,
		"dead": false,
		"eliminated": false,
		"hp": 100.0,
		"hp_max": 100.0,
		"pos": remote_pos,
		"manifestation": game.selected_manifestation,
	}
	var target := _spawn_target(remote_pos + Vector2(105.0, 0.0), 18.0)
	var uid := str(target.get("uid", ""))
	var accepted: bool = game._authority_start_remote_lacerante_execution(
		"lacerante:22:1", uid, remote_pos, remote_pos + Vector2(180.0, 0.0), 52.0, 24.0, 12.0, remote_peer, game.selected_manifestation
	)
	_check(accepted, "authority rejected a valid client execution")
	_check(bool(target.get("lacerante_exec", false)), "target was not reserved")
	_check(game.net_remote_lacerante_execution_jobs.size() == 1, "execution job was not scheduled exactly once")
	_check(not game._authority_start_remote_lacerante_execution("lacerante:22:1", uid, remote_pos, remote_pos + Vector2(180.0, 0.0), 52.0, 24.0, 12.0, remote_peer, game.selected_manifestation), "duplicate request was accepted")
	game._update_remote_lacerante_executions(1.0)
	_check(game.net_remote_lacerante_execution_jobs.is_empty(), "authority did not finish the execution")
	_check(not game.enemies.has(target) or float(target.get("hp", 0.0)) <= 0.0, "authority did not kill the reserved target")

	var visual_target := _spawn_target(game.player_pos + Vector2(90.0, 0.0), 10.0)
	var ex: RTLaceranteExecutionController = game._lacerante_exec()
	ex.pending_remote_event_id = "lacerante:local:2"
	ex.pending_remote_since = game.time_alive
	var coagula_before := int(game.lacerante_coagula)
	_check(ex.apply_remote_confirmation("lacerante:local:2", int(visual_target.get("uid", -1)), Vector2(visual_target["pos"]), 3, false), "owner did not start confirmed execution visual")
	_check(ex.is_active() and not bool(ex.active.get("authority_finish", true)), "client visual tried to own the lethal hit")
	_check(ex.apply_remote_finished("lacerante:local:2", int(visual_target.get("uid", -1)), Vector2(visual_target["pos"]), true), "owner did not accept finish confirmation")
	_check(int(game.lacerante_coagula) == coagula_before + 1, "confirmed owner did not receive coagulum")
	_check(not ex.apply_remote_finished("lacerante:local:2", int(visual_target.get("uid", -1)), Vector2(visual_target["pos"]), true), "duplicate finish granted twice")
	_check(int(game.lacerante_coagula) == coagula_before + 1, "duplicate finish duplicated reward")

	print("MULTIPLAYER_LACERANTE_EXECUTION_OK request=validated reserve=single authority_kill=true owner_visual=true owner_reward=once")
	root.remove_child(game)
	game._cleanup_runtime_resources()
	game.free()
	game = null
	for _frame in range(4):
		await process_frame
	quit(0)
