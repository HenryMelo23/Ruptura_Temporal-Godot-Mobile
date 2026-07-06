extends SceneTree

var game: Node
var booted := false


func _init() -> void:
	call_deferred("_bootstrap")


func _initialize() -> void:
	call_deferred("_bootstrap")


func _process(_delta: float) -> bool:
	if not booted:
		_bootstrap()
	return false


func _bootstrap() -> void:
	if booted:
		return
	booted = true
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("BOSS2_ULTIMATE_VISUAL_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()
	game.mode = "game"
	game.current_phase = 2
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 6000.0
	game.boss_hp = game.boss_hp_max * game.BOSS2_ULTIMATE_HP_THRESHOLD
	game.player_hp = game.player_hp_max
	game.player_pos = game.WORLD_SIZE * 0.5 + Vector2(-95, 40)
	game.boss_pos = game.WORLD_SIZE * 0.5 + Vector2(470, -40)
	game.enemies.clear()
	game.bullets.clear()
	game.enemy_bullets.clear()
	game.boss_attacks.clear()
	game._reset_boss2_state()
	game._start_boss2_ultimate()
	game.time_alive = 18.35
	game.boss2_ultimate_timer = 24.0
	game.boss2_ultimate_spit_timer = 0.65
	game.boss2_ultimate_wind_timer = 0.95
	for i in range(4):
		game._spawn_boss2_frost_particle(game.player_pos + Vector2(120 - i * 80, -100 + i * 45), Vector2.RIGHT.rotated(i * 0.35))

	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == 1280 and image.get_height() == 720, "invalid_capture")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output := "res://.codex/boss2_ultimate_blizzard_qa_1280x720.png"
	_check(image.save_png(output) == OK, "save_failed")
	print("BOSS2_ULTIMATE_VISUAL_OK " + ProjectSettings.globalize_path(output))
	quit(0)
