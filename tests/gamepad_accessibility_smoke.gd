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
	var viewport = Vector2(1280, 720)
	game._start_game()
	game._update_button_layout(viewport)

	var actions: Array = game._gamepad_action_order()
	_check(actions.size() == 8, "gamepad bindings must include combat, pause, shop and boss actions")
	var rects: Dictionary = game._gamepad_settings_rects(viewport)
	_check(rects.has("shop") and rects.has("boss") and rects.has("back"), "gamepad settings are missing shop/boss/back rows")

	game._load_gamepad_bindings(PackedStringArray(["2", "3", "1", "0", "7"]))
	_check(game.gamepad_bindings.has("shop") and game.gamepad_bindings.has("boss"), "old five-button saves did not receive shop/boss defaults")

	game.mode = "game"
	game.previous_mode = "game"
	game._handle_gamepad_virtual_button(str(game.gamepad_bindings["pause"]), true, viewport)
	_check(game.mode == "paused", "pause binding did not open pause")
	game._handle_gamepad_virtual_button(str(game.gamepad_bindings["pause"]), true, viewport)
	_check(game.mode == "game", "pause binding did not resume from pause")

	game.shop_auto_enabled = false
	game.mode = "game"
	game.score = game.card_cost
	game._handle_gamepad_virtual_button(str(game.gamepad_bindings["shop"]), true, viewport)
	_check(game.mode == "shop_opening" or game.mode == "shop", "shop binding did not start manual shop")

	game.previous_mode = "game"
	game._open_shop(false)
	game._handle_gamepad_virtual_button(str(game.gamepad_bindings["secondary"]), true, viewport)
	_check(game.mode == "pause_deck" and game.deck_previous_mode == "shop", "secondary binding did not open deck from shop")
	game._return_from_deck()
	game._handle_gamepad_virtual_button(str(game.gamepad_bindings["shop"]), true, viewport)
	_check(game.mode == "game", "shop binding did not exit shop")

	game.mode = "game"
	game.boss_ready = true
	game.boss_active = false
	game.boss_dead = false
	game.boss_call_timer = -1.0
	game._handle_gamepad_virtual_button(str(game.gamepad_bindings["boss"]), true, viewport)
	_check(game.mode == "boss_call", "boss binding did not start boss call")

	_check(game._compact_binding_name("skill") != "--", "skill HUD binding label is empty")

	print("GAMEPAD_ACCESSIBILITY_SMOKE_OK bindings=8 pause=true shop=true boss=true skill_badge=true")
	quit(0)
