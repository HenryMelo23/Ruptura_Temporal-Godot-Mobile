extends SceneTree

var game: Node

const OUTPUT := "res://.codex/cinzas_card_visual_1280x720.png"


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("CINZAS_CARD_VISUAL_FAIL " + message)
	quit(1)


func _visible_cinzas_holders() -> int:
	var total := 0
	for holder in game.cinzas_burn_texture_nodes:
		if is_instance_valid(holder) and holder.visible:
			total += 1
	return total


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	await process_frame
	game._start_game()
	game.score = 7615
	game.card_cost = 1700
	game.shop_rerolls = 3
	game._open_shop(false)

	var left_card: Dictionary = game._find_card_by_id("escolha_adiada").duplicate(true)
	var buffed_card: Dictionary = game._find_card_by_id("passagem_intangivel").duplicate(true)
	var right_card: Dictionary = game._find_card_by_id("escolha_adiada").duplicate(true)
	_check(not left_card.is_empty(), "left card was not found")
	_check(not buffed_card.is_empty(), "Passagem Intangivel was not found")
	_check(not right_card.is_empty(), "right card was not found")

	buffed_card["cinzas_return_buff"] = true
	buffed_card["cinzas_buff_stacks"] = 3
	buffed_card["cinzas_burn_seed"] = 49975293
	buffed_card["desc"] = String(buffed_card.get("desc", "")) + "\nRetorno das Cinzas x3: esta compra vem chamuscada com um bonus unico."

	game.shop_cards = [left_card, buffed_card, right_card]
	game.shop_selected = 1
	game.shop_select_pulse_index = 1
	game.shop_select_pulse_timer = 0.0
	await process_frame
	await process_frame
	await process_frame

	_check(bool(buffed_card.get("cinzas_return_buff", false)), "Cinzas return buff property flag not set on card")
	_check(int(buffed_card.get("cinzas_buff_stacks", 0)) == 3, "Cinzas buff stacks missing on card")
	_check(_visible_cinzas_holders() == 1, "Cinzas shader nodes should draw exactly one buffed card in the shop")

	for loop in range(5):
		game.queue_redraw()
		await process_frame
		_check(_visible_cinzas_holders() == 1, "Cinzas shader nodes accumulated after repeated redraw %d" % loop)

	game.mode = "game"
	game.queue_redraw()
	await process_frame
	_check(_visible_cinzas_holders() == 0, "Cinzas shader nodes remained visible after leaving the shop")

	game.mode = "shop"
	game.queue_redraw()
	await process_frame
	_check(_visible_cinzas_holders() == 1, "Cinzas shader nodes did not recover cleanly after reopening the shop")

	if DisplayServer.get_name() != "headless":
		var viewport_texture: ViewportTexture = root.get_texture()
		var image: Image = viewport_texture.get_image()
		if image != null:
			if image.save_png(OUTPUT) != OK:
				push_error("CINZAS_CARD_VISUAL_FAIL could not save screenshot")
		image = null
		viewport_texture = null

	print("CINZAS_CARD_VISUAL_SMOKE_OK " + ProjectSettings.globalize_path(OUTPUT))
	root.remove_child(game)
	game.queue_free()
	for i in range(4):
		await process_frame
	quit(0)
