extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.current_phase = 4
	game.mode = "game"
	game.player_pos = Vector2(960, 540)
	game.enemies.clear()
	game.phase4_enemy_hazards.clear()
	var kinds = [game.ENEMY_NEXUS_CARTOGRAPHER, game.ENEMY_NEXUS_CHRONOPHAGE, game.ENEMY_NEXUS_REFRACTOR, game.ENEMY_NEXUS_WEAVER, game.ENEMY_NEXUS_ECHO]
	var positions = [Vector2(520, 310), Vector2(780, 260), Vector2(1040, 320), Vector2(650, 610), Vector2(1080, 650)]
	for i in range(kinds.size()):
		game._spawn_enemy(String(kinds[i]), Vector2(positions[i]))
		game.enemies.back()["nexus_cast_cd"] = 0.0
		game._update_phase4_enemy(game.enemies.back(), 0.01)
	for hazard in game.phase4_enemy_hazards:
		if String(hazard.get("kind", "")) in ["rift", "chrono", "echo"]:
			hazard["age"] = max(0.45, float(hazard.get("warning", game.PHASE4_RIFT_WARNING)) * 0.72)
	await process_frame
	await process_frame
	var image := game.get_viewport().get_texture().get_image()
	var output := "res://.codex/phase4_enemy_ecosystem_1280x720.png"
	assert(image.save_png(output) == OK)
	print("PHASE4_ECOSYSTEM_VISUAL_OK " + ProjectSettings.globalize_path(output))
	quit(0)
