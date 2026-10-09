extends SceneTree

var game: Node
var failures: Array[String] = []


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.hide()
	game.set_process(false)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _start_clean_game() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.shop_telemetry_enabled = false
	game.score = 2000
	game.card_cost = 500


func _discounted_cards() -> Array:
	var cards: Array = []
	for card in game.shop_cards:
		if float(card.get("bargain_discount_rate", 0.0)) > 0.0:
			cards.append(card)
	return cards


func _run() -> void:
	await process_frame
	_start_clean_game()

	var capsule: Dictionary = game._spawn_bargain_capsule(game.PLAYER_START + Vector2(180, 0))
	_check(not capsule.is_empty(), "forced capsule did not spawn")
	_check(String(game.bargain_capsule.get("state", "")) == game.BARGAIN_CAPSULE_STATE_PREPARING, "capsule did not start in preparing")
	game._update_bargain_capsule(game.BARGAIN_CAPSULE_PREPARE_TIME + 0.01)
	_check(String(game.bargain_capsule.get("state", "")) == game.BARGAIN_CAPSULE_STATE_FALLING, "capsule did not enter falling")
	game._update_bargain_capsule(game.BARGAIN_CAPSULE_FALL_TIME + 0.01)
	_check(String(game.bargain_capsule.get("state", "")) == game.BARGAIN_CAPSULE_STATE_ACTIVE, "capsule did not become active")
	_check(float(game.bargain_capsule.get("hp", 0.0)) > 0.0, "capsule active with no HP")
	_check(float(game.bargain_capsule.get("collapse_time", 0.0)) > 0.0, "capsule active with no collapse timer")

	game.bargain_capsule["collapse_time"] = 0.0
	game._damage_bargain_capsule(float(game.bargain_capsule.get("hp", 0.0)) + 10.0, "smoke", false)
	_check(String(game.bargain_capsule.get("result", "")) == "success", "same-frame zero hp/timer should resolve success priority")
	_check(not game.bargain_capsule_pending_discount.is_empty(), "success did not create pending discount")
	_check(game.bargain_capsule_pending_discount.has("rate"), "pending discount missing rate")

	var pending_rate: float = float(game.bargain_capsule_pending_discount.get("rate", 0.0))
	_check(pending_rate >= 0.05 and pending_rate <= 0.65, "discount outside allowed range")
	game.bargain_capsule.clear()
	game._open_shop(false)
	_check(game.mode == "shop", "shop did not open after capsule")
	_check(game.bargain_capsule_pending_discount.is_empty(), "pending discount was not consumed by next shop visit")
	_check(game._bargain_discount_active_for_shop(), "shop session did not activate bargain discount")
	var discounted: Array = _discounted_cards()
	_check(discounted.size() > 0, "shop generated no discounted cards")
	for card in discounted:
		var base_price: int = int(card.get("bargain_base_price", 0))
		var price: int = game._effective_card_price(card)
		_check(base_price > price, "discounted card price was not below base")
		_check(price == game._bargain_discounted_price(base_price, pending_rate), "discounted card price formula drifted")
	for i in range(1, min(3, game.shop_cards.size())):
		game.shop_cards[i].erase("bargain_discount_rate")
		game.shop_cards[i].erase("bargain_base_price")
	game._refill_shop_slot_after_purchase(0)
	for i in range(1, min(3, game.shop_cards.size())):
		_check(float(game.shop_cards[i].get("bargain_discount_rate", 0.0)) <= 0.0, "refill reapplied discount to existing offer")
	var paid_reroll_cost: int = game.shop_controller.next_paid_reroll_cost()
	game.shop_rerolls = 0
	_check(game.shop_controller.next_paid_reroll_cost() == paid_reroll_cost, "bargain discount changed reroll cost")
	game._finish_shop()
	_check(game.shop_bargain_discount_session.is_empty(), "closing shop did not consume bargain session")
	game.mode = "game"
	game.shop_manual_grace_reopen_available = true
	game.shop_manual_grace_until = game.time_alive + game.SHOP_MANUAL_ACCIDENTAL_CLOSE_GRACE
	game._open_shop(false)
	_check(game.shop_bargain_discount_session.is_empty(), "grace reopen restored consumed bargain discount")
	game._finish_shop()

	game.mode = "game"
	game.bargain_capsule.clear()
	game.bargain_capsule_pending_discount.clear()
	game.shop_bargain_discount_session.clear()
	game.enemies.clear()
	game._spawn_bargain_capsule(game.PLAYER_START + Vector2(220, 0))
	game._update_bargain_capsule(game.BARGAIN_CAPSULE_PREPARE_TIME + 0.05)
	game._update_bargain_capsule(game.BARGAIN_CAPSULE_FALL_TIME + 0.05)
	game.bargain_capsule["collapse_time"] = 0.0
	game._update_bargain_capsule(0.01)
	_check(String(game.bargain_capsule.get("result", "")) == "fail", "collapse did not resolve failure")
	_check(game.bargain_capsule_pending_discount.is_empty(), "failure created discount")
	_check(not game.enemies.is_empty(), "failure did not spawn pressure enemies")
	for enemy in game.enemies:
		_check(bool(enemy.get("skip_rewards", false)), "failure enemy can still reward/farm")

	game.mode = "game"
	game.enemies.clear()
	game.bargain_capsule.clear()
	game.bargain_capsule_pending_discount = {"rate": 0.25}
	var blocked: Dictionary = game._spawn_bargain_capsule()
	_check(blocked.is_empty(), "capsule spawned while pending discount existed")
	game.bargain_capsule_pending_discount.clear()

	game.is_multiplayer = true
	game.is_host = true
	game.online_room_owner = true
	game.online_connected = true
	game.online_lobby_active_player_count = 2
	var hp_duo: float = game._bargain_capsule_hp_for_party()
	_check(hp_duo > game.BARGAIN_CAPSULE_BASE_HP, "duo capsule HP did not scale")
	game._spawn_bargain_capsule(game.PLAYER_START + Vector2(260, 0))
	game.bargain_capsule["state"] = game.BARGAIN_CAPSULE_STATE_ACTIVE
	var before_hp: float = float(game.bargain_capsule.get("hp", 0.0))
	game._damage_bargain_capsule(17.0, "remote_smoke", false, 2)
	_check(float(game.bargain_capsule.get("hp", 0.0)) == before_hp - 17.0, "host did not apply authoritative remote damage")
	_check(int(game.bargain_capsule.get("last_hit_peer", 0)) == 2, "capsule did not preserve damage peer id")

	game._cleanup_bargain_capsule("test_cleanup")
	_check(game.bargain_capsule.is_empty(), "cleanup did not clear active capsule")

	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("BARGAIN_CAPSULE_SMOKE_OK success_priority=true discount_session=true failure_pressure=true multiplayer_authority=true")
	quit(0 if failures.is_empty() else 1)
