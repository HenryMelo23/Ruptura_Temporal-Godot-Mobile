extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error(message)
	print("ALL_CARD_FRAMES_SMOKE_FAIL %s" % message)
	quit(1)


func _run() -> void:
	game._start_game()
	for card in game.CARDS:
		var name := String(card.get("name", ""))
		if not card.has("frame_2"):
			_fail("missing_frame_2_%s" % name)
		var key := "card_" + name
		if not game.textures.has(key) or game.textures[key] == null:
			_fail("missing_frame_1_texture_%s" % name)
		if not game.textures.has(key + "_2") or game.textures[key + "_2"] == null:
			_fail("missing_frame_2_texture_%s" % name)
	print("ALL_CARD_FRAMES_SMOKE_OK cards=%d" % game.CARDS.size())
	quit(0)
