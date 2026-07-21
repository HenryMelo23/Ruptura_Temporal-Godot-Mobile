extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._clear_interrupted_run_save()
	game._start_game()
	game.time_alive = 375.0
	game.elapsed_unpaused = 375.0
	game.current_phase = 2
	game.phase_started_at = 240.0
	game.score = 4321
	game.run_points_earned = 5000
	game.run_points_spent = 679
	game.player_pos = Vector2(777, 333)
	game.player_hp = 321.0
	game.cards_bought["Petro"] = 2
	game.cards_bought["Speed Boost"] = 1
	game.enemies = [{
		"uid": 9101,
		"type": game.ENEMY_STALKER,
		"pos": Vector2(620, 410),
		"hp": 88.0,
		"max_hp": 120.0,
		"speed": 110.0
	}]
	game.bullets = [{
		"pos": Vector2(720, 330),
		"vel": Vector2(300, 0),
		"damage": 44.0,
		"life": 0.8
	}]
	game.boss_ready = true
	game.boss_active = true
	game.boss_hp_max = 12000.0
	game.boss_hp = 8765.0
	game.boss_pos = Vector2(1100, 420)
	game._save_interrupted_run(true)
	assert(FileAccess.file_exists(game.INTERRUPTED_RUN_SAVE_PATH))
	assert(game.interrupted_run_available)
	assert(int(game.interrupted_run_summary.get("phase", 0)) == 2)
	assert(game._menu_rects(Vector2(1280, 720)).has("continue"))
	assert(game._menu_index_for("continue") == 0)
	assert(game._menu_index_for("start") == 1)

	game.player_pos = Vector2(10, 10)
	game.score = 0
	game.enemies.clear()
	game.bullets.clear()
	game.boss_active = false
	assert(game._resume_interrupted_run())
	assert(game.mode == "game")
	assert(game.current_phase == 2)
	assert(abs(game.time_alive - 375.0) < 0.01)
	assert(game.score == 4321)
	assert(game.player_pos == Vector2(777, 333))
	assert(abs(float(game.player_hp) - 321.0) < 0.01)
	assert(int(game.cards_bought.get("Petro", 0)) == 2)
	assert(game.enemies.size() == 1)
	assert(Vector2(game.enemies[0]["pos"]) == Vector2(620, 410))
	assert(game.bullets.size() == 1)
	assert(Vector2(game.bullets[0]["vel"]) == Vector2(300, 0))
	assert(game.boss_active)
	assert(abs(float(game.boss_hp) - 8765.0) < 0.01)

	game._clear_interrupted_run_save()
	game.mode = "menu"
	print("INTERRUPTED_RUN_RESUME_SMOKE_OK save=true resume=true actors=true cards=true boss=true")
	quit(0)
