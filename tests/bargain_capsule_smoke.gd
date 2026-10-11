extends SceneTree

var game: Node
var failures: Array[String] = []


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
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


func _capture(label: String, size: Vector2i) -> void:
	if DisplayServer.get_name() == "headless":
		return
	root.size = size
	root.content_scale_size = size
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_size() == size, "invalid visual capture " + label)
	if image != null:
		_check(image.save_png(ProjectSettings.globalize_path("res://.agent_logs/bargain_%s_%dx%d.png" % [label, size.x, size.y])) == OK, "could not save visual capture " + label)


func _exercise_discount_categories() -> void:
	var duplicate_card: Dictionary = game.CARDS[2].duplicate(true)
	for category_index in range(game.BARGAIN_CAPSULE_DISCOUNT_RANGES.size()):
		var category: Dictionary = game.BARGAIN_CAPSULE_DISCOUNT_RANGES[category_index]
		var min_rate: float = float(category.get("min", 0.0))
		var max_rate: float = float(category.get("max", min_rate))
		game.shop_visit_index = 100 + category_index
		game.shop_generation_index = 200 + category_index
		var found_distinct: bool = false
		for seed in range(1, 96):
			game.shop_bargain_discount_session = {
				"active": true,
				"id": String(category.get("id", "")),
				"rate": min_rate,
				"min": min_rate,
				"max": max_rate,
				"seed": seed,
				"event_id": "category_%d" % category_index,
				"visit_index": game.shop_visit_index
			}
			var offers: Array = game._apply_bargain_discount_to_shop_picks([duplicate_card.duplicate(true), duplicate_card.duplicate(true)], "reroll")
			_check(offers.size() == 2, "category did not preserve duplicate offers")
			var first: Dictionary = offers[0]
			var second: Dictionary = offers[1]
			var first_rate: float = float(first.get("bargain_discount_rate", 0.0))
			var second_rate: float = float(second.get("bargain_discount_rate", 0.0))
			_check(first_rate >= min_rate and first_rate <= max_rate, "first offer escaped category bounds")
			_check(second_rate >= min_rate and second_rate <= max_rate, "second offer escaped category bounds")
			_check(String(first.get("bargain_discount_offer_key", "")) != String(second.get("bargain_discount_offer_key", "")), "duplicate cards collided on offer identity")
			var repeated: Array = game._apply_bargain_discount_to_shop_picks([duplicate_card.duplicate(true), duplicate_card.duplicate(true)], "reroll")
			_check(float(Dictionary(repeated[0]).get("bargain_discount_rate", -1.0)) == first_rate, "same offer was not deterministic")
			if not is_equal_approx(first_rate, second_rate):
				found_distinct = true
				break
		_check(found_distinct, "category never produced distinct per-card discounts")
	var reroll_category: Dictionary = game.BARGAIN_CAPSULE_DISCOUNT_RANGES[2]
	var reroll_changed: bool = false
	game.shop_visit_index = 180
	for seed in range(1, 96):
		game.shop_bargain_discount_session = {
			"active": true,
			"id": String(reroll_category.get("id", "")),
			"category_id": String(reroll_category.get("id", "")),
			"rate": float(reroll_category.get("min", 0.0)),
			"min": float(reroll_category.get("min", 0.0)),
			"max": float(reroll_category.get("max", 0.0)),
			"seed": seed,
			"event_id": "reroll_refresh",
			"visit_index": game.shop_visit_index
		}
		game.shop_generation_index = 400
		var before_reroll: Array = game._apply_bargain_discount_to_shop_picks([duplicate_card.duplicate(true), duplicate_card.duplicate(true)], "reroll")
		game.shop_generation_index = 401
		var after_reroll: Array = game._apply_bargain_discount_to_shop_picks([duplicate_card.duplicate(true), duplicate_card.duplicate(true)], "reroll")
		if float(Dictionary(before_reroll[0]).get("bargain_discount_rate", 0.0)) != float(Dictionary(after_reroll[0]).get("bargain_discount_rate", 0.0)):
			reroll_changed = true
			break
	_check(reroll_changed, "reroll generation did not refresh per-card percentages")
	game.shop_bargain_discount_session.clear()


func _exercise_bargain_draw_states() -> void:
	var states: Array[String] = [
		game.BARGAIN_CAPSULE_STATE_PREPARING,
		game.BARGAIN_CAPSULE_STATE_FALLING,
		game.BARGAIN_CAPSULE_STATE_ACTIVE,
		game.BARGAIN_CAPSULE_STATE_SUCCESS,
		game.BARGAIN_CAPSULE_STATE_FAIL,
		game.BARGAIN_CAPSULE_STATE_CLEANUP
	]
	game.gfx_low_resource = true
	for state in states:
		game.bargain_capsule = {
			"id": "draw_" + state,
			"state": state,
			"pos": game.player_pos + Vector2(120.0, 0.0),
			"timer": 0.4,
			"hp": 100.0,
			"max_hp": 170.0,
			"collapse_time": 5.0,
			"collapse_max": 13.0,
			"seed": 41
		}
		game.queue_redraw()
		await process_frame
		if state in [game.BARGAIN_CAPSULE_STATE_SUCCESS, game.BARGAIN_CAPSULE_STATE_FAIL]:
			await _capture(state, Vector2i(1280, 720))
			await _capture(state, Vector2i(960, 540))
	game.bargain_capsule.clear()
	game.queue_redraw()
	await process_frame


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.agent_logs"))
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
	var pending_min: float = float(game.bargain_capsule_pending_discount.get("min", 0.0))
	var pending_max: float = float(game.bargain_capsule_pending_discount.get("max", 0.0))
	_check(pending_rate >= pending_min and pending_rate <= pending_max, "category result outside allowed range")
	game.bargain_capsule.clear()
	game._open_shop(false)
	_check(game.mode == "shop", "shop did not open after capsule")
	_check(game.bargain_capsule_pending_discount.is_empty(), "pending discount was not consumed by next shop visit")
	_check(game._bargain_discount_active_for_shop(), "shop session did not activate bargain discount")
	var discounted: Array = _discounted_cards()
	_check(discounted.size() > 0, "shop generated no discounted cards")
	for card in discounted:
		var card_rate: float = float(card.get("bargain_discount_rate", 0.0))
		var base_price: int = int(card.get("bargain_base_price", 0))
		var price: int = game._effective_card_price(card)
		_check(card_rate >= pending_min and card_rate <= pending_max, "per-card discount escaped category")
		_check(base_price > price, "discounted card price was not below base")
		_check(price == game._bargain_discounted_price(base_price, card_rate), "discounted card price formula drifted")
		_check(int(card.get("bargain_final_price", 0)) == price, "stored final price drifted from canonical price")
		_check(String(card.get("bargain_discount_category_id", "")) != "", "card metadata lost category id")
		var tampered: Dictionary = card.duplicate(true)
		tampered["bargain_discount_rate"] = 0.75
		tampered["bargain_final_price"] = 1
		_check(game._bargain_card_discount_rate(tampered) == 0.0 or is_equal_approx(card_rate, 0.75), "tampered discount rate was trusted")
		_check(game._effective_card_price(tampered) != 1, "forged final price was trusted")
	for i in range(1, min(3, game.shop_cards.size())):
		game.shop_cards[i].erase("bargain_discount_rate")
		game.shop_cards[i].erase("bargain_base_price")
	game._refill_shop_slot_after_purchase(0)
	for i in range(1, min(3, game.shop_cards.size())):
		_check(float(game.shop_cards[i].get("bargain_discount_rate", 0.0)) <= 0.0, "refill reapplied discount to existing offer")
	var paid_reroll_cost: int = game.shop_controller.next_paid_reroll_cost()
	game.shop_rerolls = 0
	_check(game.shop_controller.next_paid_reroll_cost() == paid_reroll_cost, "bargain discount changed reroll cost")
	game._request_shop_exit_or_finish()
	_check(game.mode == "shop", "promotional shop exited without confirmation")
	_check(game.shop_controller.bargain_exit_confirmation_active(), "promotional exit warning did not open")
	await _capture("exit_warning", Vector2i(1280, 720))
	await _capture("exit_warning", Vector2i(960, 540))
	game.shop_controller.cancel_bargain_exit()
	_check(game.mode == "shop" and not game.shop_mp_ready_to_leave, "cancel marked the player ready")
	game._request_shop_exit_or_finish()
	game.shop_controller.confirm_bargain_exit()
	_check(game.mode == "shop_return", "confirmed promotional exit did not continue normal flow")
	_check(game.shop_bargain_discount_session.is_empty(), "closing shop did not consume bargain session")
	game.mode = "game"
	game.shop_manual_grace_reopen_available = true
	game.shop_manual_grace_until = game.time_alive + game.SHOP_MANUAL_ACCIDENTAL_CLOSE_GRACE
	game._open_shop(false)
	_check(game.shop_bargain_discount_session.is_empty(), "grace reopen restored consumed bargain discount")
	game._finish_shop()
	game.mode = "game"
	game.bargain_capsule_pending_discount = {
		"id": "bom", "category_id": "bom", "rate": 0.20, "min": 0.15, "max": 0.25,
		"seed": 880, "event_id": "forced_shop_discount"
	}
	game._open_shop(true)
	game._request_shop_exit_or_finish()
	_check(game.shop_controller.bargain_exit_confirmation_active(), "automatic shop bypassed promotional warning")
	game.shop_controller.cancel_bargain_exit()
	game._finish_shop()
	_exercise_discount_categories()

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
	await _exercise_bargain_draw_states()

	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("BARGAIN_CAPSULE_SMOKE_OK states=6 category_bounds=5 per_card=true exit_warning=true multiplayer_authority=true")
	quit(0 if failures.is_empty() else 1)
