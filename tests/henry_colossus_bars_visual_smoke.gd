extends SceneTree

## Barras do Colosso (impacto, vida temporaria, armadura) acima da cabeca, normal e gigante.
const DT := 1.0 / 60.0
var game: Node
var out_dir := "user://henry_colossus_bars"


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out_dir = a.substr(6)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _crop() -> Image:
	var img := root.get_texture().get_image()
	var c := Vector2i(game.player_pos - game._camera(Vector2(1280, 720)))
	return img.get_region(Rect2i(c - Vector2i(90, 150), Vector2i(180, 210)))


func _run() -> void:
	game.startup_thanks_done = true
	game.active_character_key = game.CHARACTER_HENRY
	game.selected_mutation = 2
	game.selected_effect = 2
	game.forced_initial_phase = 1
	game.run_tutorial_enabled = false
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.henry_incendiary_ability_controller.cancel_entrance()
	game.henry_entry_timer = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.enemies.clear()
	var owner = game.henry_colossus_ability_controller
	var board := Image.create(180 * 2, 210, false, Image.FORMAT_RGBA8)
	owner.impact_armor = owner._impact_armor_cap() * 0.7
	game.queue_redraw()
	await process_frame
	await process_frame
	board.blit_rect(_crop(), Rect2i(0, 0, 180, 210), Vector2i(0, 0))
	owner.fury = owner.FURY_MAX
	owner.cast_ultimate()
	for _i in range(int((owner.TRANSFORM_DURATION + 0.3) / DT)):
		game.time_alive += DT
		owner.update(DT)
	owner.impact_armor = owner._impact_armor_cap() * 0.7
	owner.giant_temp_hp = game.player_hp_max * owner.GIANT_TEMP_HP_RATIO * 0.6
	owner.giant_armor = game.player_hp_max * owner.GIANT_ARMOR_RATIO * 0.8
	game.queue_redraw()
	await process_frame
	await process_frame
	board.blit_rect(_crop(), Rect2i(0, 0, 180, 210), Vector2i(180, 0))
	DirAccess.make_dir_recursive_absolute(out_dir)
	board.save_png(out_dir + "/henry_colossus_bars.png")
	print("HENRY_COLOSSUS_BARS_OK giant=%s board=%s" % [owner.giant_active, out_dir + "/henry_colossus_bars.png"])
	quit(0)
