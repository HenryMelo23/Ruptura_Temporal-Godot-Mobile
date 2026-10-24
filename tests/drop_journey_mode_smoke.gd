extends SceneTree

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("DROP_JOURNEY_MODE_FAIL " + message)


func _run() -> void:
	await process_frame
	game._start_game()
	game.set_process(false)
	game._set_run_mode_local(game.RUN_MODE_DROP)
	game.mode = "game"
	game.player_pos = Vector2(640.0, 360.0)
	game.arauto_card_drops.clear()
	game.net_collected_drop_ids.clear()

	var start_chance: float = game._drop_mode().drop_chance(0.0, 1)
	var reference_chance: float = game._drop_mode().drop_chance(75.0 * 60.0, 1)
	var late_chance: float = game._drop_mode().drop_chance(120.0 * 60.0, 1)
	_check(is_equal_approx(start_chance, 0.015), "initial chance is not 1.5 percent")
	_check(absf(reference_chance - 0.35) < 0.0001, "75 minute chance is not 35 percent")
	_check(late_chance > reference_chance and late_chance < 1.0, "chance stopped growing after 75 minutes")
	_check(game._drop_mode().drop_chance(75.0 * 60.0, 2) < reference_chance, "two player balance did not reduce chance")
	_check(game._drop_mode().drop_chance(75.0 * 60.0, 3) < game._drop_mode().drop_chance(75.0 * 60.0, 2), "three player balance did not reduce chance")
	_check(game._drop_mode().can_lobby_peer_select_mode(22, 22), "lobby owner was denied mode selection")
	_check(not game._drop_mode().can_lobby_peer_select_mode(33, 22), "non-owner was allowed to select lobby mode")

	game._open_shop(false)
	_check(game.mode == "game", "shop opened during Drop mode")
	_check(not game._should_trigger_forced_shop(), "forced shop remained enabled")
	_check(not game._manual_shop_available(), "manual shop remained enabled")
	game.shop_controller.start_opening_animation(true)
	_check(game.mode == "game", "shop controller bypass opened the shop")

	game.time_alive = 1000000000.0
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(260.0, 0.0))
	var killed_enemy: Dictionary = game.enemies.back()
	killed_enemy["killed_by_peer_id"] = game._mp_unique_id()
	game._kill_enemy(killed_enemy)
	_check(game.arauto_card_drops.size() == 1, "real enemy kill path did not create a card")
	game.arauto_card_drops.clear()
	game.time_alive = 0.0

	var enemy := {"killed_by_peer_id": game._mp_unique_id()}
	_check(game._drop_mode().on_enemy_killed(enemy, game.player_pos + Vector2(180.0, 0.0), 0.0), "forced successful roll did not create a card")
	_check(game.arauto_card_drops.size() == 1, "enemy did not create exactly one card")
	var drop: Dictionary = game.arauto_card_drops[0]
	_check(bool(drop.get("drop_mode", false)), "drop was not marked as Drop mode reward")
	_check(is_equal_approx(float(drop.get("life", 0.0)), 5.0), "drop lifetime is not five seconds")
	_check(int(drop.get("owner_peer", 0)) == game._mp_unique_id(), "drop owner is not the killer")
	_check(String(drop.get("owner_name", "")) != "", "drop owner label is missing")

	var card: Dictionary = drop.get("card", {})
	game._append_owned_card_drop(card, game.player_pos + Vector2(220.0, 0.0), 0.0, 77, 5.0, 0.0, 0.0, 0.0, 0.0, {"drop_mode": true})
	var foreign_drop: Dictionary = game.arauto_card_drops.back()
	_check(not game._reward_owned_by_local(foreign_drop), "foreign card became locally collectible")
	_check(not game._drop_mode().confirm_collect(String(foreign_drop["drop_id"]), 66), "non-owner collected another player's card")

	drop["pos"] = game.player_pos + Vector2(300.0, 0.0)
	foreign_drop["pos"] = game.player_pos + Vector2(300.0, 0.0)
	game._update_arauto_card_drops(5.01)
	_check(game.arauto_card_drops.is_empty(), "uncollected cards did not disappear after five seconds")
	_check(game.drop_mode_controller.DROP_BLINK_WINDOW == 2.0, "expiry blink window changed")

	game._set_run_mode_local("invalid")
	_check(game.selected_run_mode == game.RUN_MODE_SHOP, "invalid mode did not fall back to Shop")
	game.online_room_owner = false
	game._request_lobby_run_mode(game.RUN_MODE_DROP)
	_check(game.selected_run_mode == game.RUN_MODE_SHOP, "non-host changed the lobby mode")
	game.online_room_owner = true
	game._request_lobby_run_mode(game.RUN_MODE_DROP)
	_check(game.selected_run_mode == game.RUN_MODE_DROP, "host could not change the lobby mode")
	game._online_run_mode_state(game.RUN_MODE_SHOP)
	_check(game.selected_run_mode == game.RUN_MODE_SHOP, "authoritative lobby mode state was not applied")

	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	await process_frame
	if failed:
		quit(1)
	else:
		print("DROP_JOURNEY_MODE_SMOKE_OK chance_0m=1.5pct chance_75m=35pct multiplayer_scaled=true owner_locked=true lifetime=5s blink=2s shop_disabled=true")
		quit(0)
