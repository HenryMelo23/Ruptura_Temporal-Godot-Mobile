extends SceneTree

## Microbenchmark of the per-enemy helpers used by the crowd renderer.
var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _bench(label: String, fn: Callable) -> void:
	var started := Time.get_ticks_usec()
	for _r in range(20):
		for e in game.enemies:
			fn.call(e)
	var us := float(Time.get_ticks_usec() - started) / 20.0
	print("MICRO %-28s %.3fms per frame (%d enemies)" % [label, us / 1000.0, game.enemies.size()])


func _run() -> void:
	game.startup_thanks_done = true
	game._apply_character_identity(game.CHARACTER_GEOVANA)
	game.forced_initial_phase = 1
	game.run_tutorial_enabled = false
	game._start_game()
	game.mode = "game"
	for _w in range(10):
		await process_frame
	while game.enemies.size() < 150:
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2.from_angle(randf() * TAU) * randf_range(260.0, 620.0))
	var cam: Vector2 = game._camera(Vector2(1280, 720))
	_bench("empty_callable", func(e): pass)
	_bench("texture", func(e): game._enemy_texture(e))
	_bench("draw_size", func(e): game._enemy_draw_size(e))
	_bench("visual_offset", func(e): game._enemy_visual_offset(e))
	_bench("should_flip", func(e): game._enemy_should_flip(e))
	_bench("in_view", func(e): game._world_point_in_view(e["pos"], cam, 180.0))
	_bench("attack_target", func(e): game._attack_target_is_enemy(int(e["uid"])))
	_bench("bar_style", func(e): game._enemy_health_bar_style(e))
	_bench("phase7_vfx", func(e): game._draw_phase7_enemy_vfx(e, cam, Vector2.ZERO, Vector2.ZERO, Vector2.ONE))
	_bench("dict_record", func(e): var d := {"a": e, "b": 1, "c": 2, "d": 3, "e": 4, "f": 5, "g": 6, "h": 7, "i": 8, "j": 9, "k": 10, "l": 11, "m": 12, "n": 13, "o": 14, "p": 15, "q": 16})
	var S = load("res://scripts/main_runtime_state.gd")
	_bench("10x game.CONST", func(e): for i in 10: var x = game.ENEMY_COMMON)
	_bench("10x game.var", func(e): for i in 10: var x = game.current_phase)
	_bench("10x e.get", func(e): for i in 10: var x = e.get("type", ""))
	_bench("10x method call", func(e): for i in 10: game._attack_target_is_enemy(1))
	var typed: Node2D = game
	_bench("10x typed Node2D CONST", func(e): for i in 10: var x = typed.ENEMY_COMMON)
	quit()
