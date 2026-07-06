extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PHASE4_ECOSYSTEM_FAIL " + message)
	quit(1)


func _spawn(kind: String, pos: Vector2) -> Dictionary:
	game._spawn_enemy(kind, pos)
	var enemy: Dictionary = game.enemies.back()
	enemy["nexus_cast_cd"] = 0.0
	return enemy


func _hazard(kind: String) -> Dictionary:
	for hazard in game.phase4_enemy_hazards:
		if String(hazard.get("kind", "")) == kind:
			return hazard
	return {}


func _run() -> void:
	game._start_game()
	game.current_phase = 4
	game.mode = "game"
	game.player_pos = Vector2(720, 420)
	game.enemies.clear()
	game.phase4_enemy_hazards.clear()
	var kinds = [game.ENEMY_NEXUS_CARTOGRAPHER, game.ENEMY_NEXUS_CHRONOPHAGE, game.ENEMY_NEXUS_REFRACTOR, game.ENEMY_NEXUS_WEAVER, game.ENEMY_NEXUS_ECHO]
	for i in range(kinds.size()):
		_spawn(String(kinds[i]), Vector2(300 + i * 150, 250 + (i % 2) * 220))
	_check(game.enemies.size() == 5, "five thematic enemies were not created")
	_check(game.enemies.all(func(enemy): return String(enemy["type"]) != game.ENEMY_COMMON), "phase4 ecosystem still uses a generic common enemy")

	game.phase4_enemy_hazards.clear()
	var cartographer: Dictionary = game.enemies[0]
	game._update_phase4_enemy(cartographer, 0.01)
	var rift := _hazard("rift")
	_check(not rift.is_empty(), "cartographer did not draw a rift")
	game.player_pos = Vector2(rift["a"]).lerp(Vector2(rift["b"]), 0.5)
	rift["age"] = game.PHASE4_RIFT_WARNING
	var before_rift: Vector2 = game.player_pos
	game._update_phase4_enemy_hazards(0.01)
	_check(game.player_pos.distance_to(before_rift) > 100.0, "crossing the cartographer rift did not displace the player")

	game.phase4_enemy_hazards.clear()
	var chronophage: Dictionary = game.enemies[1]
	chronophage["nexus_cast_cd"] = 0.0
	game.player_pos = Vector2(chronophage["pos"])
	game.last_skill_time = 2.0
	game._update_phase4_enemy(chronophage, 0.01)
	var chrono := _hazard("chrono")
	chrono["age"] = game.PHASE4_CHRONO_WARNING
	game._update_phase4_enemy_hazards(0.01)
	_check(game.last_skill_time > 3.0, "chronophage did not consume cooldown progress")

	game.phase4_enemy_hazards.clear()
	game.enemy_bullets.clear()
	var refractor: Dictionary = game.enemies[2]
	refractor["nexus_cast_cd"] = 0.0
	game._update_phase4_enemy(refractor, 0.01)
	var prism := _hazard("hostile_prism")
	_check(not prism.is_empty(), "refractor did not install a hostile prism")
	prism["shot_cd"] = 0.0
	game._update_phase4_enemy_hazards(0.01)
	_check(game.enemy_bullets.size() == 3 and game.enemy_bullets.all(func(bullet): return String(bullet["type"]) == "nexus_refracted"), "hostile prism did not split its volley into three")

	game.phase4_enemy_hazards.clear()
	var weaver: Dictionary = game.enemies[3]
	weaver["nexus_cast_cd"] = 0.0
	game.player_pos = Vector2(weaver["pos"])
	game._update_phase4_enemy(weaver, 0.01)
	_check(not is_zero_approx(game._phase4_vector_rotation()), "vector weaver field did not bend movement")

	game.phase4_enemy_hazards.clear()
	game.phase4_player_history = [Vector2(540, 380), Vector2(580, 390), Vector2(620, 400), Vector2(660, 410), Vector2(700, 420), Vector2(740, 430), Vector2(780, 440), Vector2(820, 450), Vector2(860, 460)]
	var echo: Dictionary = game.enemies[4]
	echo["nexus_cast_cd"] = 0.0
	game._update_phase4_enemy(echo, 0.01)
	var echoes = game.phase4_enemy_hazards.filter(func(hazard): return String(hazard.get("kind", "")) == "echo")
	_check(echoes.size() == 3, "entropic echo did not record three past positions")
	game.player_pos = Vector2(echoes[0]["pos"])
	var hp_before: int = game.player_hp
	echoes[0]["age"] = float(echoes[0]["warning"])
	game._update_phase4_enemy_hazards(0.01)
	_check(game.player_hp < hp_before, "recorded position did not detonate")
	game._despawn_enemies_for_boss_call()
	_check(game.phase4_enemy_hazards.is_empty() and game.enemies.is_empty(), "phase4 anomalies survived the boss call")

	print("PHASE4_ECOSYSTEM_OK cartographer=rift chronophage=cooldown refractor=triple weaver=vectors echo=memory")
	quit(0)
