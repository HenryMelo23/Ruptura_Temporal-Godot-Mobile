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


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 100.0
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
				var bullet := {"pos": game.player_pos, "dir": Vector2.RIGHT, "damage": 50.0, "life": 1.0, "max_life": 1.0, "hits": {}, "color": Color.WHITE, "kind": key}
				game._apply_manifest_evolution_to_bullet(bullet)
				game._manifest_evolution_on_projectile_hit(bullet, {"uid": "combo_target", "kind": "enemy", "pos": game.player_pos + Vector2(80, 0), "hp": 100.0, "stun": 0.0}, game.player_pos + Vector2(80, 0))
				game._manifest_evolution_on_skill(game.player_pos + Vector2(24, 0))
				game._manifest_evolution_on_teleport(game.player_pos, game.player_pos + Vector2(96, 0))
				_check(game._manifest_evolution_choices().size() == 2, key + " handlers removed a choice")
				game._reset_manifest_evolution_state()
				_check(game._manifest_evolution_choices().is_empty(), key + " reset did not clear choices")
				pairs += 1
	print("MANIFEST_EVOLUTION_540_OK pairs=%d" % pairs)
	quit(0)
