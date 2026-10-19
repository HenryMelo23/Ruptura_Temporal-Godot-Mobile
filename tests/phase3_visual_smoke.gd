extends SceneTree

var game: Node
var qa_size := Vector2i(1280, 720)


func _initialize() -> void:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	if "--qa-mobile" in args:
		qa_size = Vector2i(960, 540)
	root.size = qa_size
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._advance_to_phase(3)
	game.player_pos = Vector2(800, 660)
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_DEVOTO, Vector2(390, 470))
	game._spawn_enemy(game.ENEMY_FLAGELANTE, Vector2(650, 470))
	game._spawn_enemy(game.ENEMY_GUARDIAO, Vector2(910, 470))
	game._spawn_enemy(game.ENEMY_INCENSARIO, Vector2(390, 640))
	game._spawn_enemy(game.ENEMY_RELICARIO, Vector2(650, 640))
	game._spawn_enemy(game.ENEMY_SALMODIANTE, Vector2(910, 640))
	var flagelante: Dictionary = game.enemies.filter(func(enemy): return String(enemy.get("type", "")) == game.ENEMY_FLAGELANTE)[0]
	var salmodiante: Dictionary = game.enemies.filter(func(enemy): return String(enemy.get("type", "")) == game.ENEMY_SALMODIANTE)[0]
	var relicario: Dictionary = game.enemies.filter(func(enemy): return String(enemy.get("type", "")) == game.ENEMY_RELICARIO)[0]
	flagelante["phase3_surge_timer"] = 0.5
	salmodiante["phase3_chant_prepare"] = 0.45
	salmodiante["phase3_chant_target"] = Vector2(1120, 610)
	relicario["phase3_relic_pulse"] = 0.55
	game.enemies[0]["phase3_fervor_timer"] = 2.0
	game.queue_redraw()
	await process_frame
	await process_frame
	if root.size != qa_size:
		root.size = qa_size
		game.queue_redraw()
		await process_frame
		await process_frame
	var image = root.get_texture().get_image()
	assert(image != null and image.get_width() == qa_size.x and image.get_height() == qa_size.y)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output := "res://.codex/phase3_enemy_variety_qa_%dx%d.png" % [qa_size.x, qa_size.y]
	assert(image.save_png(output) == OK)
	print("PHASE3_VISUAL_OK " + ProjectSettings.globalize_path(output))
	game.mode = "menu"
	game.enemies.clear()
	game.visible = false
	game.set_process(false)
	game.set_physics_process(false)
	game._cleanup_runtime_resources()
	for i in range(4):
		await process_frame
	root.remove_child(game)
	game.free()
	game = null
	await process_frame
	await process_frame
	quit(0)
