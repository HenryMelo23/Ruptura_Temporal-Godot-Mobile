extends SceneTree

var game: Node


func _initialize() -> void:
	var low := "--low" in OS.get_cmdline_user_args()
	root.size = Vector2i(960, 540) if low else Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.gfx_low_resource = "--low" in OS.get_cmdline_user_args()
	game._advance_to_phase(4)
	game.mode = "game"
	game.current_phase = 4
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp = maxf(1.0, game.boss_hp_max)
	game.boss_entry_timer = 0.0
	game.boss4_ultimate_active = false
	game.boss4_stun_timer = 0.0
	game.player_pos = Vector2(620.0, 430.0)
	game.phase4_enemy_hazards.clear()
	game.boss4_instability_fissure_controller.reset()
	for index in range(8):
		game.player_pos += Vector2(14.0, -3.0)
		game.boss4_instability_fissure_controller.update(0.17, true)
	assert(game.boss4_instability_fissure_controller.force_cast_for_test() == 2)
	var fissures: Array = game.phase4_enemy_hazards.filter(func(value): return String(Dictionary(value).get("source", "")) == "boss4_instability_fissure")
	assert(fissures.size() == 2)
	Dictionary(fissures[0])["age"] = 0.72
	Dictionary(fissures[1])["age"] = 1.18
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	assert(image != null and image.get_width() == root.size.x and image.get_height() == root.size.y)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs/boss4_instability_fissures"))
	var suffix := "_low" if game.gfx_low_resource else ""
	var output := "res://.agent_logs/boss4_instability_fissures/fissures%s.png" % suffix
	assert(image.save_png(output) == OK)
	print("BOSS4_INSTABILITY_FISSURES_VISUAL_OK output=%s" % ProjectSettings.globalize_path(output))
	game.boss4_instability_fissure_controller.reset()
	game.mode = "menu"
	game.visible = false
	game.set_process(false)
	game.set_physics_process(false)
	game._cleanup_runtime_resources()
	for _frame in range(4):
		await process_frame
	root.remove_child(game)
	game.free()
	game = null
	for _frame in range(3):
		await process_frame
	quit(0)
