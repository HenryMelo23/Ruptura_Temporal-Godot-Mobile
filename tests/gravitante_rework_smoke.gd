extends SceneTree

## Gravitante rework: limite de 3 orbitas, Estrela puxa vizinhos, Q puxa suave e escala
## com massa, Poco de Partida puxa/marca/colapsa.

var game: Node
const DT := 1.0 / 60.0


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("GRAVITANTE_REWORK_FAIL " + message)
	quit(1)


func _e(pos: Vector2) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var e: Dictionary = game.enemies[-1]
	e["pos"] = pos
	e["hp"] = 1.0e6
	e["max_hp"] = 1.0e6
	e["speed"] = 0.0
	return e


func _sim(seconds: float) -> void:
	for _i in range(int(round(seconds / DT))):
		game._gravitante().update(DT)


func _run() -> void:
	game.startup_thanks_done = true
	for i in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[i]["key"]) == "gravitante":
			game.selected_manifestation = i
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.enemies.clear()
	game.orbitals.clear()
	game.player_damage = 100.0
	_check(game.manifestation_key == "gravitante", "not gravitante")
	var g: RTGravitanteController = game._gravitante()
	var c := Vector2(1200, 1200)
	var star := _e(c)
	for i in range(5):
		g.attach_orbital("enemy", int(star["uid"]), c)
	_check(int(g.mass_by_uid().get(int(star["uid"]), 0)) == 3 and game.orbitals.size() == 3, "orbital cap failed (%d)" % game.orbitals.size())
	_check(g.stars().size() == 1, "critical mass did not create a star")
	var near := _e(c + Vector2(100, 0))
	var far := _e(c + Vector2(260, 0))
	_sim(0.6)
	_check(Vector2(near["pos"]).distance_to(c) < 75.0, "star did not pull neighbor (%.1f)" % Vector2(near["pos"]).distance_to(c))
	_check(is_equal_approx(Vector2(far["pos"]).x, c.x + 260.0), "star pulled out of range")
	# Q: alvo com 3 orbitas leva mais que alvo com 1.
	var light := _e(c + Vector2(0, 180))
	g.attach_orbital("enemy", int(light["uid"]), Vector2(light["pos"]))
	var hp_star: float = float(star["hp"])
	var hp_light: float = float(light["hp"])
	var light_from: Vector2 = Vector2(light["pos"])
	game._trigger_gravitante_mark_collision()
	_check(game.orbitals.is_empty() or game.orbitals.all(func(o): return float(o["life"]) <= 0.0), "collision did not consume orbitals")
	_sim(DT)
	_check(Vector2(light["pos"]).distance_to(light_from) < 30.0, "collision teleported targets")
	_sim(0.4)
	var dmg_star: float = hp_star - float(star["hp"])
	var dmg_light: float = hp_light - float(light["hp"])
	_check(dmg_star > dmg_light and dmg_light > 0.0, "mass did not scale collision (%.0f vs %.0f)" % [dmg_star, dmg_light])
	_check(Vector2(light["pos"]).distance_to(Vector2(star["pos"])) < 60.0, "targets did not converge")
	# TP: poco.
	game.enemies.clear()
	game.orbitals.clear()
	var w := _e(c + Vector2(170, 0))
	var whp: float = float(w["hp"])
	g.begin_well(c)
	_sim(1.0)
	_check(Vector2(w["pos"]).distance_to(c) < 130.0, "well did not pull")
	_check(int(g.mass_by_uid().get(int(w["uid"]), 0)) >= 1, "well did not mark")
	_sim(1.8)
	_check(g.wells.is_empty() and float(w["hp"]) < whp, "well did not collapse")
	print("GRAVITANTE_REWORK_OK cap=3 star_pull=true q_smooth=true q_mass=%.0f/%.0f well=true" % [dmg_star, dmg_light])
	game._cleanup_runtime_resources()
	game.free()
	quit(0)
