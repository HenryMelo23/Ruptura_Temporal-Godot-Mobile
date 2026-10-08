extends SceneTree

var game: Node


func _fail(message: String) -> void:
	push_error("BOSS3_MIASMA_VISUAL_FAIL " + message)
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _save(name: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		_fail("capture image is empty")
		return
	var output := "res://.codex/" + name
	var err := image.save_png(output)
	if err != OK:
		_fail("could not save capture %s err=%d" % [output, err])
		return
	print("BOSS3_MIASMA_VISUAL_OK " + ProjectSettings.globalize_path(output))


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	game._start_game()
	game._advance_to_phase(3)
	game.mode = "game"
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 8000.0
	game.boss_hp = 6200.0
	game.boss_pos = Vector2(900, 420)
	game.player_pos = Vector2(690, 470)
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(530, 350))
	game._spawn_enemy(game.ENEMY_GUARDIAO, Vector2(1070, 520))

	game._start_boss3_miasma(1)
	game.boss3_miasma_clone_timer = 0.72
	await _save("boss3_miasma_1_clones_1280x720.png")
	game._end_boss3_miasma(true)

	game._start_boss3_miasma(2)
	game.boss3_miasma_spit_timer = 0.0
	game._update_boss3_miasma(0.01)
	if not game.boss_attacks.is_empty():
		game.boss_attacks[0]["age"] = 0.58
	await _save("boss3_miasma_2_darkness_1280x720.png")
	game._end_boss3_miasma(true)

	game._start_boss3_miasma(4)
	game.boss3_miasma_qte_required = 30
	game.boss3_miasma_qte_taps = 12
	game.boss3_miasma_qte_time_left = 4.3
	game.boss3_miasma_qte_elapsed = game.BOSS3_MIASMA_QTE_DURATION - game.boss3_miasma_qte_time_left
	game.boss3_miasma_qte_tutorial = 2.0
	await _save("boss3_miasma_4_qte_1280x720.png")
	quit(0)
