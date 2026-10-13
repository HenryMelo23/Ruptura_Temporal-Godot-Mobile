extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MANIFEST_EVOLUTION_540_FAIL " + message)
	quit(1)


func _activate(entry: Dictionary) -> void:
	game.manifest_evolution_options = [entry]
	game._choose_manifest_evolution(0)


func _exercise_pair_through_public_flow(key: String) -> void:
	# Do not invoke evolution callbacks here.  The purpose of this matrix is to
	# prove that both real choices survive actual combat entry points together.
	game.effects.clear()
	game.bullets.clear()
	game.return_bullets.clear()
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(108.0, 0.0))
	game.enemies[0]["hp"] = 100000.0
	game.enemies[0]["max_hp"] = 100000.0
	game.time_alive += 10.0
	game.last_attack_time = -1000.0
	if key == "eclipsada":
		game.eclipsada_form = game.ECLIPSADA_FORM_SOL
		game.eclipsada_next_attack_time = 0.0
	game._try_attack()
	if key == "lacerante":
		game._update_lacerante_prepare(1.0)
	for _frame in range(60 if key == "acorrentada" else 16):
		game._update_bullets(0.03)
		game._update_return_bullets(0.03)
		game._update_acorrentada_state(0.03)
	game.time_alive += 10.0
	game.last_skill_time = -1000.0
	if key == "necronada":
		game.necronada_vestiges = [{"id": 905, "enemy_type": game.ENEMY_COMMON, "pos": game.player_pos, "profile": game._necronada_profile(game.ENEMY_COMMON), "depth": 1}]
	game._use_skill(game.player_pos + Vector2(112.0, 0.0))
	game._execute_teleport(game.player_pos + Vector2(124.0, 0.0))
	for _frame in range(8):
		game._update_manifest_evolution_effects(0.05)
	_check(not game.manifest_evolution_combat_event_log.is_empty(), key + " public flow emitted no combat event")


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 100.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	var pairs := 0
	for item in game.MANIFESTATIONS:
		var key := String(item.get("key", ""))
		var ev1_entries: Array = game._manifest_evolution_entries(key, "ev1")
		var ev2_entries: Array = game._manifest_evolution_entries(key, "ev2")
		_check(ev1_entries.size() == 6, key + " needs 6 EV1")
		_check(ev2_entries.size() == 6, key + " needs 6 EV2")
		for ev1 in ev1_entries:
			for ev2 in ev2_entries:
				game.manifestation_key = key
				game._reset_manifest_evolution_state()
				game.mode = "game"
				_activate(Dictionary(ev1))
				_activate(Dictionary(ev2))
				var choices: Array = game._manifest_evolution_choices()
				_check(choices.size() == 2, key + " did not preserve EV1+EV2")
				_check(String(choices[0].get("stage", "")) == "ev1", key + " first choice lost EV1")
				_check(String(choices[1].get("stage", "")) == "ev2", key + " second choice lost EV2")
				_check(String(choices[0].get("evolution", "")) == String(Dictionary(ev1).get("id", "")), key + " EV1 id changed")
				_check(String(choices[1].get("evolution", "")) == String(Dictionary(ev2).get("id", "")), key + " EV2 id changed")
				_exercise_pair_through_public_flow(key)
				_check(game._manifest_evolution_choices().size() == 2, key + " handlers removed a choice")
				game._reset_manifest_evolution_state()
				_check(game._manifest_evolution_choices().is_empty(), key + " reset did not clear choices")
				pairs += 1
	print("MANIFEST_EVOLUTION_540_OK pairs=%d" % pairs)
	quit(0)
