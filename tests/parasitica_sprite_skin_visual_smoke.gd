extends SceneTree

const OUT_MOVE := "res://.agent_logs/parasitica_skin_move_1280x720.png"
const OUT_IDLE := "res://.agent_logs/parasitica_skin_idle_1280x720.png"
const OUT_FIRE := "res://.agent_logs/parasitica_skin_fire_1280x720.png"
const OUT_FIRE_EAST := "res://.agent_logs/parasitica_skin_fire_east_1280x720.png"
const OUT_FIRE_NORTH := "res://.agent_logs/parasitica_skin_fire_north_1280x720.png"
const OUT_FIRE_SOUTH := "res://.agent_logs/parasitica_skin_fire_south_1280x720.png"
const OUT_DESCENT := "res://.agent_logs/parasitica_skin_entry_descent_960x540.png"
const OUT_IMPACT := "res://.agent_logs/parasitica_skin_entry_impact_960x540.png"
const OUT_OPENING := "res://.agent_logs/parasitica_skin_entry_opening_960x540.png"
const OUT_MOUTH := "res://.agent_logs/parasitica_skin_entry_mouth_960x540.png"
const OUT_EMERGE := "res://.agent_logs/parasitica_skin_entry_emerge_960x540.png"
const OUT_RELEASE := "res://.agent_logs/parasitica_skin_entry_release_960x540.png"
const OUT_RETREAT := "res://.agent_logs/parasitica_skin_entry_retreat_960x540.png"
const OUT_EXIT := "res://.agent_logs/parasitica_skin_entry_exit_960x540.png"
const OUT_ELETRICA_REFERENCE := "res://.agent_logs/eletrica_entry_scale_reference_960x540.png"

var game: Node2D
var caption: Label


func _initialize() -> void:
	call_deferred("_run")


func _capture(path: String, expected_size: Vector2i) -> void:
	for frame in range(6):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != expected_size or image.save_png(path) != OK:
		push_error("PARASITICA_SPRITE_SKIN_VISUAL_FAIL capture " + path)
		quit(1)


func _prepare_game() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.run_tutorial_enabled = false
	game._start_game()
	game.shop_tutorial_seen = true
	game.boss_call_tutorial_seen = true
	game._reset_tutorial_state()
	game._finish_startup_thanks()
	game.startup_thanks_teaser_available = false
	game.mode = "game"
	game.manifestation_key = "parasitica"
	game.selected_manifestation = game._manifestation_index_for_key("parasitica", -1)
	game.player_pos = Vector2(640, 390)
	game.last_facing = Vector2.RIGHT
	game.gfx_screen_shake = false
	game.gfx_particles = true
	game.gfx_low_resource = false
	game.gfx_memory_saver = false
	game.mobile_adaptive_visual_budget = false
	game.time_alive = 25.0
	game.last_attack_time = -999.0
	game.last_damage_time = -999.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.process_mode = Node.PROCESS_MODE_DISABLED
	var layer := CanvasLayer.new()
	root.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(24, 24)
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_color_override("font_color", Color(1.0, 0.62, 0.78))
	caption.add_theme_color_override("font_shadow_color", Color(0.05, 0.01, 0.03, 1.0))
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(caption)
func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("PARASITICA_SPRITE_SKIN_VISUAL requires a renderer")
		quit(1)
		return
	_prepare_game()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)

	caption.text = "PARASITICA / HOSPEDEIRA EM MOVIMENTO"
	game.move_touch_index = 0
	game.touch_move = Vector2.RIGHT
	await _capture(OUT_MOVE, Vector2i(1280, 720))
	game.move_touch_index = -1
	game.touch_move = Vector2.ZERO

	caption.text = "PARASITICA / ESCALA PARADA"
	await _capture(OUT_IDLE, Vector2i(1280, 720))

	caption.text = "PARASITICA / DISPARO LESTE"
	game.player_attack_visual_dir = Vector2.RIGHT
	game.last_attack_time = game.time_alive
	await _capture(OUT_FIRE_EAST, Vector2i(1280, 720))

	caption.text = "PARASITICA / DISPARO NORTE"
	game.player_attack_visual_dir = Vector2.UP
	game.last_attack_time = game.time_alive
	await _capture(OUT_FIRE_NORTH, Vector2i(1280, 720))

	caption.text = "PARASITICA / DISPARO SUL"
	game.player_attack_visual_dir = Vector2.DOWN
	game.last_attack_time = game.time_alive
	await _capture(OUT_FIRE_SOUTH, Vector2i(1280, 720))

	caption.text = "PARASITICA / DISPARO DIAGONAL"
	game.player_attack_visual_dir = Vector2(1.0, -1.0).normalized()
	game.last_attack_time = game.time_alive
	await _capture(OUT_FIRE, Vector2i(1280, 720))

	game.last_attack_time = -999.0

	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(960, 540)
	game.player_pos = Vector2(480, 320)
	caption.text = "PARASITICA / A CRIATURA DESCE DO TOPO"
	game.player_start_down_fall_timer = game.PLAYER_START_DOWN_FALL_TIME * 0.78
	await _capture(OUT_DESCENT, Vector2i(960, 540))

	caption.text = "PARASITICA / IMPACTO NO CHAO"
	game.player_start_down_fall_timer = game.PLAYER_START_DOWN_FALL_TIME * 0.35
	await _capture(OUT_IMPACT, Vector2i(960, 540))

	caption.text = "PARASITICA / A MANDIBULA COMECA A ABRIR"
	game.player_start_down_fall_timer = game.PLAYER_START_DOWN_FALL_TIME * 0.16
	await _capture(OUT_OPENING, Vector2i(960, 540))

	caption.text = "PARASITICA / A BOCA REVELA A HOSPEDEIRA"
	game.player_start_down_fall_timer = game.PLAYER_START_DOWN_FALL_TIME * 0.06
	await _capture(OUT_MOUTH, Vector2i(960, 540))

	caption.text = "PARASITICA / A HOSPEDEIRA EMERGE"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = game.PLAYER_START_DOWN_LAND_TIME * 0.82
	await _capture(OUT_EMERGE, Vector2i(960, 540))

	caption.text = "PARASITICA / A MANDIBULA LIBERA A HOSPEDEIRA"
	game.player_start_down_landing_timer = game.PLAYER_START_DOWN_LAND_TIME * 0.52
	await _capture(OUT_RELEASE, Vector2i(960, 540))

	caption.text = "PARASITICA / A CRIATURA RECUA"
	game.player_start_down_landing_timer = game.PLAYER_START_DOWN_LAND_TIME * 0.35
	await _capture(OUT_RETREAT, Vector2i(960, 540))

	caption.text = "PARASITICA / SAIDA PELO TOPO"
	game.player_start_down_landing_timer = game.PLAYER_START_DOWN_LAND_TIME * 0.12
	await _capture(OUT_EXIT, Vector2i(960, 540))

	caption.text = "ELETRICA / REFERENCIA DE ESCALA"
	game.manifestation_key = "eletrica"
	game.selected_manifestation = game._manifestation_index_for_key("eletrica", -1)
	game.player_start_down_landing_timer = game.PLAYER_START_DOWN_LAND_TIME * 0.12
	await _capture(OUT_ELETRICA_REFERENCE, Vector2i(960, 540))

	print("PARASITICA_SPRITE_SKIN_VISUAL_OK move=1280x720 idle=1280x720 fire_east=1280x720 fire_north=1280x720 fire_south=1280x720 fire_diagonal=1280x720 descent=960x540 impact=960x540 opening=960x540 mouth=960x540 emerge=960x540 release=960x540 retreat=960x540 exit=960x540 eletrica_reference=960x540")
	game._cleanup_runtime_resources()
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
