extends RefCounted

var core


func configure(runtime_core) -> void:
	core = runtime_core


func points_for_enemy(enemy: Dictionary) -> int:
	var mult = long_run_point_multiplier()
	var base_points: = float(enemy.get("points", 20)) * elite_point_multiplier(enemy)
	return max(int(enemy.get("points", 20)), int(round(base_points * mult)))


func long_run_point_multiplier() -> float:
	var minutes: float = maxf(0.0, core.time_alive / 60.0)
	var mult: float = core.POINT_REWARD_BASE_MULT + minutes * core.POINT_REWARD_PER_MINUTE
	if minutes > core.POINT_REWARD_LATE_START_MINUTES:
		mult += (minutes - core.POINT_REWARD_LATE_START_MINUTES) * core.POINT_REWARD_LATE_PER_MINUTE
	return clampf(mult, core.POINT_REWARD_BASE_MULT, core.POINT_REWARD_MAX_MULT)


func long_run_curve_progress(start_time: float, end_time: float) -> float:
	return clampf((core.time_alive - start_time) / maxf(1.0, end_time - start_time), 0.0, 1.0)


func long_run_enemy_hp_growth_multiplier() -> float:
	if core.time_alive <= core.LONG_RUN_RUPTURE_TIME:
		return 1.0
	if core.time_alive < core.LONG_RUN_BROKEN_BUILD_TIME:
		return lerpf(1.0, core.LONG_RUN_ENEMY_HP_GROWTH_BROKEN_MULT, long_run_curve_progress(core.LONG_RUN_RUPTURE_TIME, core.LONG_RUN_BROKEN_BUILD_TIME))
	if core.time_alive < core.LONG_RUN_ENDLESS_TIME:
		return lerpf(core.LONG_RUN_ENEMY_HP_GROWTH_BROKEN_MULT, core.LONG_RUN_ENEMY_HP_GROWTH_ENDLESS_MULT, long_run_curve_progress(core.LONG_RUN_BROKEN_BUILD_TIME, core.LONG_RUN_ENDLESS_TIME))
	return core.LONG_RUN_ENEMY_HP_GROWTH_ENDLESS_MULT


func long_run_spawn_interval_multiplier() -> float:
	if core.time_alive <= core.LONG_RUN_RUPTURE_TIME:
		return 1.0
	if core.time_alive < core.LONG_RUN_BROKEN_BUILD_TIME:
		return lerpf(1.0, core.LONG_RUN_SPAWN_INTERVAL_BROKEN_MULT, long_run_curve_progress(core.LONG_RUN_RUPTURE_TIME, core.LONG_RUN_BROKEN_BUILD_TIME))
	if core.time_alive < core.LONG_RUN_ENDLESS_TIME:
		return lerpf(core.LONG_RUN_SPAWN_INTERVAL_BROKEN_MULT, core.LONG_RUN_SPAWN_INTERVAL_ENDLESS_MULT, long_run_curve_progress(core.LONG_RUN_BROKEN_BUILD_TIME, core.LONG_RUN_ENDLESS_TIME))
	return core.LONG_RUN_SPAWN_INTERVAL_ENDLESS_MULT


func long_run_enemy_limit_bonus() -> int:
	if core.time_alive < core.LONG_RUN_RUPTURE_TIME:
		return 0
	if core.time_alive < core.LONG_RUN_BROKEN_BUILD_TIME:
		return int(floor(lerpf(0.0, float(core.LONG_RUN_ENEMY_LIMIT_BROKEN_BONUS), long_run_curve_progress(core.LONG_RUN_RUPTURE_TIME, core.LONG_RUN_BROKEN_BUILD_TIME))))
	if core.time_alive < core.LONG_RUN_ENDLESS_TIME:
		return int(floor(lerpf(float(core.LONG_RUN_ENEMY_LIMIT_BROKEN_BONUS), float(core.LONG_RUN_ENEMY_LIMIT_ENDLESS_BONUS), long_run_curve_progress(core.LONG_RUN_BROKEN_BUILD_TIME, core.LONG_RUN_ENDLESS_TIME))))
	return core.LONG_RUN_ENEMY_LIMIT_ENDLESS_BONUS


func next_score_event_id() -> String:
	core.score_event_sequence += 1
	return "%d:%d" % [core._mp_unique_id(), core.score_event_sequence]


func mark_score_event_applied(event_id: String) -> bool:
	if event_id == "":
		return true
	if core.applied_score_event_ids.has(event_id):
		return false
	core.applied_score_event_ids[event_id] = Time.get_ticks_msec()
	if core.applied_score_event_ids.size() > 256:
		var keys: Array = core.applied_score_event_ids.keys()
		keys.sort()
		while core.applied_score_event_ids.size() > 192 and not keys.is_empty():
			core.applied_score_event_ids.erase(keys.pop_front())
	return true


func apply_score_delta(amount: int, broadcast: = true, event_id: String = "") -> void:
	if amount == 0:
		return
	# Replicas request local rewards; confirmed RPC credits apply without rebroadcast.
	if core.is_multiplayer and core._is_world_replica() and broadcast:
		if amount > 0 and broadcast and core._shop_rpc_available():
			core.rpc("_rpc_request_score_delta", amount, event_id if event_id != "" else next_score_event_id())
		return
	if not mark_score_event_applied(event_id):
		return
	core.score = max(0, core.score + amount)
	core.score_total = max(0, core.score_total + amount)
	if amount > 0:
		core.run_points_earned += amount
	else:
		core.run_points_spent += abs(amount)
	core._record_telemetry_score_delta(amount, "score_delta")
	if amount > 0 and broadcast and core.is_multiplayer and core._is_world_authority() and core._shop_rpc_available():
		core.rpc("_rpc_add_score", amount, event_id if event_id != "" else next_score_event_id())


func elite_point_multiplier(enemy: Dictionary) -> float:
	match String(enemy.get("type", core.ENEMY_COMMON)):
		core.ENEMY_AGGLOMERATOR:
			return 1.55
		core.ENEMY_CURATER:
			return 1.38
		core.ENEMY_CRYSTAL:
			return 1.32
		core.ENEMY_PROJECTOR:
			return 1.26
		core.ENEMY_STALKER:
			return 1.18
		core.ENEMY_LARAPIO:
			return 1.45
		core.ENEMY_KAMIKAZE, core.ENEMY_ATIRADOR:
			return 1.12
	if core._is_uncommon_enemy(enemy):
		return 1.22
	return 1.0


func card_id(card: Dictionary) -> String:
	return String(card.get("id", String(card.get("name", ""))))


func card_counter_key(card: Dictionary) -> String:
	return card_id(card)


func card_count(card: Dictionary) -> int:
	return int(core.cards_bought.get(card_counter_key(card), 0))


func card_count_by_id(card_id: String) -> int:
	return int(core.cards_bought.get(card_id, 0))


func consume_card_count(card_id: String, amount: = 1) -> bool:
	if amount <= 0:
		return true
	var current: = card_count_by_id(card_id)
	if current < amount:
		return false
	core.cards_bought[card_id] = current - amount
	core._recalculate_common_card_stat_bonuses()
	core._sync_deck_network()
	return true


func card_max_count(_card: Dictionary) -> int:
	return core.CARD_UNLIMITED_COUNT


func card_at_max(_card: Dictionary) -> bool:
	return false


func find_card_by_id(target_card_id: String) -> Dictionary:
	for card in core.CARDS:
		if card_id(card) == target_card_id:
			return card
	return {}


func is_common_card(card: Dictionary) -> bool:
	return not core._is_rare_card(card)


func new_common_card_count(card_id: String) -> float:
	return core._effective_card_count(card_id)


func rare_card_count(card_id: String) -> int:
	return card_count_by_id(card_id)


func rare_sqrt_extra(card_id: String) -> float:
	return sqrt(float(max(0, rare_card_count(card_id) - 1)))


func rare_log_count(card_id: String) -> float:
	return log(float(max(2, rare_card_count(card_id) + 1))) / log(2.0)


func carta_zero_multiplier() -> float:
	var count: int = rare_card_count("carta_zero")
	if count <= 0:
		return 1.0
	return 1.0 + 0.06 * sqrt(float(count))


func shop_price_increment_after_purchase() -> int:
	return max(64, 100 - int(round(core._apply_carta_zero_to_common_value("moeda_estavel", "economy", new_common_card_count("moeda_estavel") * 6.0))))


func card_discount_rate(card: Dictionary) -> float:
	if core._is_empty_shop_slot(card):
		return 0.0
	if not is_common_card(card):
		return core.shop_endurance_discount
	var pacto_discount: = 0.0
	if card_count(card) <= 0:
		pacto_discount = min(0.2, core._apply_carta_zero_to_common_value("pacto_possibilidades", "discount", new_common_card_count("pacto_possibilidades") * 0.04))
	return min(0.45, core.shop_endurance_discount + pacto_discount)


func shop_endurance_discount_from_elapsed(elapsed: float) -> float:
	if elapsed < 180.0:
		return 0.0
	var steps: = int(elapsed / 180.0)
	var base_discount: float = min(0.36, float(steps) * 0.06)
	var late_minutes: float = maxf(0.0, elapsed / 60.0 - 30.0)
	return min(0.55, base_discount + late_minutes * 0.008)


func effective_card_price(card: Dictionary, base_cost: = -1) -> int:
	if core._is_empty_shop_slot(card):
		return 999999999
	if base_cost < 0 and card.has("locked_price"):
		return int(card.get("locked_price", core.card_cost))
	var cost: int = core.card_cost if base_cost < 0 else base_cost
	return max(1, int(round(float(cost) * (1.0 - card_discount_rate(card)))))


func support_card_count(card_id: String) -> int:
	return new_common_card_count(card_id)


func support_sqrt_extra(card_id: String) -> float:
	return sqrt(float(max(0, support_card_count(card_id) - 1)))


func support_log2_count(card_id: String) -> float:
	return log(float(max(2, support_card_count(card_id) + 1))) / log(2.0)


func affordable_card_count() -> int:
	var temp_score = core.score
	var temp_cost = core.card_cost
	var count = 0
	while temp_score > 0:
		var cheapest: = INF
		for card in core.CARDS:
			if card_at_max(card):
				continue
			cheapest = min(cheapest, float(effective_card_price(card, temp_cost)))
		if cheapest == INF or float(temp_score) < cheapest:
			break
		temp_score -= int(cheapest)
		temp_cost += shop_price_increment_after_purchase()
		count += 1
	return count
