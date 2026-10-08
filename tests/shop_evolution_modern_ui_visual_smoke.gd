extends SceneTree

const OUT_DIR := "res://.codex"

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("SHOP_EVOLUTION_MODERN_UI_VISUAL_FAIL " + message)
	quit(1)


func _capture(label: String, size: Vector2i) -> void:
	root.size = size
	root.content_scale_size = size
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "%s/shop_evolution_%s_%dx%d.png" % [OUT_DIR, label, size.x, size.y]
	var viewport_texture := root.get_texture()
	_check(viewport_texture != null, "viewport texture unavailable for " + label)
	var image := viewport_texture.get_image()
	_check(image != null, "viewport image unavailable for " + label)
	var error := image.save_png(ProjectSettings.globalize_path(path))
	_check(error == OK, "could not save " + path)


func _prepare_shop() -> void:
	game.mode = "game"
	game.previous_mode = "game"
	game.is_multiplayer = false
	game.is_dead = false
	game.run_tutorial_enabled = false
	game._reset_card_counts()
	game._reset_card_proc_state()
	game.shop_locked_slots.clear()
	game._open_shop(false)
	game.shop_cards = [game.CARDS[2].duplicate(true), game.CARDS[3].duplicate(true), game.CARDS[9].duplicate(true)]
	game.shop_selected = 0
	game.score = 5000
	game.card_cost = 500
	game.shop_rerolls = game.SHOP_FREE_REROLLS_PER_VISIT
	game.shop_paid_rerolls_this_visit = 0
	game.shop_presentation.update(1.0)


func _prepare_paid_shop() -> void:
	_prepare_shop()
	game.shop_rerolls = 0
	game.shop_paid_rerolls_this_visit = 4
	game.score = game.shop_controller.next_paid_reroll_cost() - 1


func _prepare_manifest_evolution() -> void:
	game.mode = "game"
	game.previous_mode = "game"
	game.is_multiplayer = false
	game.is_dead = false
	game._reset_manifest_evolution_state()
	game._open_manifest_evolution_choice(Vector2(700, 400))
	_check(game.mode == "manifest_evolution", "manifest evolution did not open")
	_check(game.manifest_evolution_options.size() == 3, "manifest evolution options missing")


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	game._start_game()
	game.startup_thanks_done = true
	if game.startup_thanks_frame_view != null:
		game.startup_thanks_frame_view.visible = false
	game.set_process(false)
	_prepare_shop()
	await _capture("shop_free_desktop", Vector2i(1280, 720))
	_prepare_paid_shop()
	await _capture("shop_paid_mobile_landscape", Vector2i(800, 450))
	_prepare_manifest_evolution()
	await _capture("manifest_evolution_desktop", Vector2i(1280, 720))
	await _capture("manifest_evolution_mobile_landscape", Vector2i(800, 450))
	game._cleanup_runtime_resources()
	game.free()
	await process_frame
	print("SHOP_EVOLUTION_MODERN_UI_VISUAL_OK shop_desktop=true shop_mobile=true manifest=true")
	quit(0)
