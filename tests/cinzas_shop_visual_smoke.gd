extends SceneTree

const OUTPUT_PATH := "res://.agent_logs/cinzas_shop_bonus_1280x720.png"

var game: Node
var failures: Array[String] = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _card(card_id: String) -> Dictionary:
	return game._find_card_by_id(card_id).duplicate(true)


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs"))
	game.run_tutorial_enabled = false
	game._start_game()
	game.mode = "shop"
	game.score = 2400
	game.card_cost = 500
	var burned: Dictionary = _card("Disparo crescente")
	game.cinzas_burn_marks = [{
		"card_id": game._card_id(burned),
		"stacks": 2,
		"return_buff": true,
		"eligible_misses": 0,
		"holes_seed": 19
	}]
	var offers := [burned, _card("Speed Boost"), _card("Defesa")]
	game._update_burned_card_marks_after_shop(offers)
	game.shop_cards = offers
	game.shop_selected = 0
	_check(not String(Dictionary(game.shop_cards[0]).get("cinzas_bonus_summary", "")).is_empty(), "burned card lost its visible bonus summary")
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() != "headless":
		var image: Image = root.get_texture().get_image()
		_check(image != null and image.get_size() == Vector2i(1280, 720), "invalid Cinzas shop capture")
		if image != null:
			_check(image.save_png(OUTPUT_PATH) == OK, "could not save Cinzas shop capture")
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	for _frame in range(2):
		await process_frame
	if not failures.is_empty():
		for failure in failures:
			printerr("CINZAS_SHOP_VISUAL_FAIL " + failure)
		quit(1)
		return
	print("CINZAS_SHOP_VISUAL_OK callout=true capture=1280x720")
	quit(0)
