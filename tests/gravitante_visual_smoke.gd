extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.manifestation_key = "gravitante"
	game.selected_manifestation = 5
	game.player_pos = Vector2(640, 520)
	game.enemies.clear()
	game.bullets.clear()
	var center = Vector2(780, 455)
	for pos in [center + Vector2(-210, -80), center + Vector2(260, -35), center + Vector2(-120, 135), center + Vector2(290, 135)]:
		game._spawn_enemy(game.ENEMY_COMMON, pos)
		var enemy = game.enemies[game.enemies.size() - 1]
		enemy["hp"] = 1000.0
		enemy["max_hp"] = 1000.0
	game.manifestation_secondaries.clear()
	game.manifestation_secondaries.append({
		"kind": "gravitante",
		"life": game.SECONDARY_GRAVITANTE_DURATION * 0.46,
		"max": game.SECONDARY_GRAVITANTE_DURATION,
		"center": center,
		"pulse_tick": 0.0,
		"captured": 4,
		"orbital_bonus": 2,
		"capture_power": 0.95,
		"spin_speed": 420.0,
		"edge_damage": 1.4,
		"finalized": false
	})

	game.queue_redraw()
	await process_frame
	await process_frame
	var image = root.get_texture().get_image()
	_check(image != null and image.get_width() == 1280 and image.get_height() == 720, "invalid gravitante visual capture")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output = "res://.codex/gravitante_mask_qa_1280x720.png"
	_check(image.save_png(output) == OK, "could not save gravitante visual capture")
	print("GRAVITANTE_VISUAL_OK " + ProjectSettings.globalize_path(output))
	quit(0)
