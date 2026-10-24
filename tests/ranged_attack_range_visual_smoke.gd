extends SceneTree

const OUT_GAMEPLAY := "res://.agent_logs/ranged_attack_range_960x540.png"
const OUT_PRISMATICA := "res://.agent_logs/prismatica_uncapped_range_960x540.png"
const OUT_CARD := "res://.agent_logs/horizonte_ruptura_card_960x540.png"

var game: Node2D


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("RANGED_ATTACK_RANGE_VISUAL_FAIL " + message)
	quit(1)


func _capture(path: String) -> void:
	for frame in range(6):
		game.queue_redraw()
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image != null, "missing_image")
	_check(image.get_size() == Vector2i(960, 540), "wrong_size_%s" % image.get_size())
	_check(image.save_png(ProjectSettings.globalize_path(path)) == OK, "save_failed_%s" % path)


func _visual_bullet(offset: Vector2, traveled: float) -> Dictionary:
	return {
		"uid": "visual:%d" % int(traveled),
		"pos": game.player_pos + offset,
		"origin": game.player_pos,
		"source_category": "basic_attack",
		"dir": offset.normalized(),
		"speed": 0.0,
		"life": 2.0,
		"max_life": 2.0,
		"age": 0.18,
		"phase": traveled * 0.01,
		"trail_cd": 10.0,
		"damage": 10.0,
		"kind": "eletrica",
		"pierce": false,
		"hits": {},
		"color": Color(0.32, 1.0, 0.96),
		"max_range": 300.0,
		"range_traveled": traveled,
		"range_presence": 1.0 - smoothstep(game.RangedAttackRange.FADE_START_RATIO, 1.0, traveled / 300.0),
	}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("RANGED_ATTACK_RANGE_VISUAL requires a renderer")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs"))
	root.size = Vector2i(960, 540)
	root.content_scale_size = root.size
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_size(root.size)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.run_tutorial_enabled = false
	game._start_game()
	game._finish_startup_thanks()
	game.set_process(false)
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(800.0, 450.0)
	game.player_attack_visual_dir = Vector2.RIGHT
	game.last_facing = Vector2.RIGHT
	game.manifestation_key = "eletrica"
	game.cards_bought[game.CARD_RANGE_ID] = 0
	game.attack_holding = true
	game.enemies.clear()
	game.bullets = [
		_visual_bullet(Vector2(118.0, 0.0), 118.0),
		_visual_bullet(Vector2(242.0, -38.0), 245.0),
		_visual_bullet(Vector2(292.0, 34.0), 294.0),
	]
	await create_timer(0.35).timeout
	print("RANGED_ATTACK_RANGE_VISUAL_GEOMETRY viewport=%s player=%s camera=%s bullets=%s" % [game.get_viewport_rect().size, game.player_pos, game._camera(game.get_viewport_rect().size), game.bullets.map(func(b): return b["pos"])])
	await _capture(OUT_GAMEPLAY)

	game.manifestation_key = "prismatica"
	game.selected_manifestation = game._manifestation_index_for_key("prismatica", game.selected_manifestation)
	game.cards_bought[game.CARD_RANGE_ID] = 20
	game.bullets.clear()
	game._add_bullet({
		"uid": "visual:prismatica:uncapped",
		"pos": game.player_pos + Vector2(390.0, -18.0),
		"origin": game.player_pos,
		"source_category": "basic_attack",
		"dir": Vector2.RIGHT,
		"speed": 0.0,
		"life": 2.0,
		"max_life": 2.0,
		"age": 0.18,
		"phase": 0.4,
		"trail_cd": 10.0,
		"damage": 10.0,
		"kind": "prismatica",
		"pierce": true,
		"hits": {},
		"color": Color(0.32, 1.0, 0.96),
	})
	_check(is_equal_approx(game._ranged_primary_attack_range(), 300.0), "prismatica_target_ring_not_fixed_at_300")
	_check(not game.bullets[0].has("max_range"), "prismatica_visual_projectile_received_range_cap")
	await _capture(OUT_PRISMATICA)

	game.mode = "shop"
	game.score = 9999
	game.card_cost = 650
	var range_card: Dictionary = game._find_card_by_id(game.CARD_RANGE_ID).duplicate(true)
	game.shop_cards = [range_card, range_card.duplicate(true), range_card.duplicate(true)]
	game.shop_selected = 1
	game.shop_select_pulse_index = 1
	game.shop_select_pulse_timer = 0.18
	await _capture(OUT_CARD)

	print("RANGED_ATTACK_RANGE_VISUAL_OK gameplay=960x540 prismatica=960x540 card=960x540 ring=true fade_samples=3 prismatica_uncapped=true")
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for frame in range(4):
		await process_frame
	quit(0)
