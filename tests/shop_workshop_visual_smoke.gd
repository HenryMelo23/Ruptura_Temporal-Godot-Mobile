extends SceneTree

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func capture(label: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://.codex/shop_%s_%dx%d.png" % [label, root.size.x, root.size.y]
	assert(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)) == OK)


func _run() -> void:
	game._start_game()
	game.set_process(false)
	game.run_tutorial_enabled = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.codex"))
	for size in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(800, 450)]:
		root.size = size
		root.content_scale_size = size
		game.mode = "game"
		game.is_multiplayer = false
		game.is_dead = false
		game._reset_card_counts()
		game._reset_card_proc_state()
		game.shop_locked_slots.clear()
		game._open_shop(false)
		game.shop_cards = [game.CARDS[2].duplicate(true), game.CARDS[3].duplicate(true), game.CARDS[9].duplicate(true)]
		game.score = 5000
		game.card_cost = 500
		game.cards_bought[game.CARD_ESCOLHA_ADIADA_ID] = 1
		game.cards_bought[game.CARD_CINZAS_ID] = 2
		game.shop_presentation.update(1.0)
		var areas: Dictionary = game.shop_presentation.layout(Vector2(size))
		var bounds := Rect2(Vector2.ZERO, Vector2(size))
		for key in ["detail", "buy", "exit", "reroll", "deck", "burn", "reserve"]:
			assert(bounds.encloses(areas[key]), "shop area outside viewport: " + key)
		for card_rect in areas.cards:
			assert(not Rect2(card_rect).intersects(areas.detail))
			assert(not Rect2(card_rect).intersects(areas.exit))
		assert(not Rect2(areas.burn).intersects(areas.reserve))
		assert(not Rect2(areas.buy).intersects(areas.exit))
		await capture("workshop")
		for field in ["name", "desc"]:
			var longest: Dictionary = game.CARDS[0]
			for candidate in game.CARDS:
				if String(candidate.get(field, "")).length() > String(longest.get(field, "")).length():
					longest = candidate
			game.shop_cards[2] = longest.duplicate(true)
			game.shop_selected = 2
			await capture("long_" + field)
		game.shop_cards[2] = game.CARDS[9].duplicate(true)
		game.shop_selected = 0
		game._reserve_shop_card(0)
		assert(game._shop_slot_locked(0))
		game.shop_presentation.update(0.18)
		await capture("reserve")
		game.shop_presentation.update(1.0)
		var locked_id: String = game._card_id(game.shop_cards[0])
		game._reroll_shop()
		game.shop_presentation.update(0.28)
		assert(game._card_id(game.shop_cards[0]) == locked_id)
		var rolls: int = game.shop_rerolls
		game._reroll_shop()
		assert(game.shop_rerolls == rolls, "double reroll consumed another charge")
		await capture("reroll")
		game.shop_presentation.update(1.0)
		game.shop_selected = 0
		assert(game._burn_shop_card(0))
		assert(not game._shop_slot_locked(0), "burned card was still reserved")
		game.shop_presentation.update(0.38)
		await capture("burn")
		game.shop_presentation.update(1.0)
		game.shop_selected = 1
		var before: int = game.score
		var paid: int = game._effective_card_price(game.shop_cards[1])
		game._buy_selected_card()
		game._request_shop_exit_or_finish()
		assert(game.mode == "shop", "exit interrupted an uncommitted purchase")
		game._update_shop(0.28)
		await capture("purchase")
		game._update_shop(1.0)
		assert(game.score == before - paid)
		game.is_multiplayer = true
		game.shop_mp_ready_count = 1
		game.shop_mp_expected_count = 3
		await capture("team")
		game.mode = "shop_mp_waiting"
		await capture("waiting")
		game._finish_shop()
		game._update_shop_return(0.25)
		await capture("return")
	game._cleanup_runtime_resources()
	game.free()
	await process_frame
	print("SHOP_WORKSHOP_VISUAL_OK desktop=true mobile=true purchase=true reroll=true reserve=true burn=true waiting=true exit=true")
	quit(0)
