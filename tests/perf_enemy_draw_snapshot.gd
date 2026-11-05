extends SceneTree

## Deterministic crowd snapshot used to compare the enemy renderer visually.
## Uso: ... --script res://tests/perf_enemy_draw_snapshot.gd -- --out=/abs/path.png --phase=1
var game: Node
var out := "user://enemy_snapshot.png"
var phase := 1


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--phase="): phase = int(a.substr(8))
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.startup_thanks_done = true
	game._apply_character_identity(game.CHARACTER_GEOVANA)
	game.forced_initial_phase = phase
	game.run_tutorial_enabled = false
	game._start_game()
	game.mode = "game"
	game.vol_master = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	for _w in range(20):
		await process_frame
	game.enemies.clear()
	var kinds: Array = [game.ENEMY_COMMON, game.ENEMY_COMMON, game.ENEMY_COMMON, game.ENEMY_AGGLOMERATOR, game.ENEMY_PROJECTOR, game.ENEMY_CRYSTAL, game.ENEMY_STALKER, game.ENEMY_LARAPIO]
	for i in range(24):
		var a := float(i) / 24.0 * TAU
		var r := 180.0 + float(i % 3) * 70.0
		game._spawn_enemy(kinds[i % kinds.size()], game.player_pos + Vector2.from_angle(a) * r)
	for i in range(game.enemies.size()):
		var e: Dictionary = game.enemies[i]
		e["pos"] = game.player_pos + Vector2.from_angle(float(i) / 24.0 * TAU) * (180.0 + float(i % 3) * 70.0)
		e["facing_dir"] = Vector2.RIGHT if i % 2 == 0 else Vector2.LEFT
		e["phase"] = 0.0
		if i % 4 == 1:
			e["hp"] = float(e["max_hp"]) * 0.5
	game.time_alive = 10.0
	game.set_process(false)
	game.queue_redraw()
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("SNAPSHOT_SAVED ", out)
	quit()
