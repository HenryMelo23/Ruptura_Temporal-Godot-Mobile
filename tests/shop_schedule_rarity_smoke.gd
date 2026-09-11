extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.shop_auto_enabled = true
	game.shop_auto_interval = 180.0
	game.shop_auto_elapsed = 120.0
	game._advance_to_phase(2)
	_check(is_equal_approx(game.shop_auto_elapsed, 120.0), "phase transition reset the automatic shop cadence")

	game.shop_auto_elapsed = 179.9
	game._update_game(0.2)
	_check(game.mode == "shop_countdown", "automatic shop did not start at the configured three-minute cadence")
	_check(game.forced_shop_timer > 0.0, "automatic shop countdown was not initialized")
	game.score = game.card_cost
	game.forced_shop_timer = 0.04
	game._update_shop_countdown(0.05)
	_check(game.mode == "shop_opening", "shop countdown did not enter Geovana upgrade opening animation")
	_check(game.shop_opening_timer > 0.0, "shop opening animation timer was not initialized")
	game.queue_redraw()
	await process_frame
	game._update_shop_opening(game.SHOP_OPENING_ANIM_TIME + 0.02)
	_check(game.mode == "shop", "shop did not open after Geovana upgrade animation")

	var common_card: Dictionary = game.CARDS[0]
	var rare_card: Dictionary = game.CARDS[4]
	_check(game._card_rarity_label(common_card) == "COMUM", "common card rarity label is incorrect")
	_check(game._card_rarity_label(rare_card) == "RARA", "rare card rarity label is incorrect")
	_check(game._card_rarity_color(common_card).is_equal_approx(game.CARD_RARITY_COMMON_COLOR), "common card color is not white")
	_check(game._card_rarity_color(rare_card).is_equal_approx(game.CARD_RARITY_RARE_COLOR), "rare card color is not golden yellow")

	print("SHOP_SCHEDULE_RARITY_SMOKE_OK cadence=180 phase_persistent=true opening_anim=true common=white rare=gold")
	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	quit(0)
