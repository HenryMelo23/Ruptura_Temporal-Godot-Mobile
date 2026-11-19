extends RefCounted

var core
var recomputes: int = 0
var _cache_score: int = -1
var _cache_cost: int = -1
var _cache_endurance_discount: float = -1.0
var _cache_cards_hash: int = -1
var _cache_cinzas_hash: int = -1
var _cache_bargain_hash: int = -1
var _cache_value: int = 0


func configure(runtime_core) -> void:
	core = runtime_core


func _price_profiles() -> Array[Vector2]:
	var profiles: Array[Vector2] = []
	for card in core.CARDS:
		if core._card_at_max(card) or core._is_empty_shop_slot(card):
			continue
		var bargain_rate := 0.0
		if core.has_method("_bargain_card_discount_rate"):
			bargain_rate = core._bargain_card_discount_rate(card)
		var profile := Vector2(core._card_discount_rate(card), bargain_rate)
		if not profiles.has(profile):
			profiles.append(profile)
	return profiles


func _price(cost: int, profile: Vector2) -> int:
	var base_price := maxi(1, int(round(float(cost) * (1.0 - profile.x))))
	if profile.y > 0.0 and core.has_method("_bargain_discounted_price"):
		return int(core._bargain_discounted_price(base_price, profile.y))
	return base_price


func count() -> int:
	var score_value: int = int(core.score)
	var cost_value: int = int(core.card_cost)
	var endurance_discount: float = float(core.shop_endurance_discount)
	var cards_hash: int = hash(core.cards_bought)
	var cinzas_hash: int = hash(core.cinzas_card_bonuses)
	var bargain_hash: int = hash(core.shop_bargain_discount_session)
	if score_value == _cache_score and cost_value == _cache_cost \
		and endurance_discount == _cache_endurance_discount \
		and cards_hash == _cache_cards_hash and cinzas_hash == _cache_cinzas_hash \
		and bargain_hash == _cache_bargain_hash:
		return _cache_value
	_cache_score = score_value
	_cache_cost = cost_value
	_cache_endurance_discount = endurance_discount
	_cache_cards_hash = cards_hash
	_cache_cinzas_hash = cinzas_hash
	_cache_bargain_hash = bargain_hash
	recomputes += 1
	var profiles := _price_profiles()
	var temp_score := score_value
	var temp_cost := cost_value
	var increment: int = int(core._shop_price_increment_after_purchase())
	var affordable := 0
	while temp_score > 0 and not profiles.is_empty():
		var cheapest := 999999999
		for profile in profiles:
			cheapest = mini(cheapest, _price(temp_cost, profile))
		if temp_score < cheapest:
			break
		temp_score -= cheapest
		temp_cost += increment
		affordable += 1
	_cache_value = affordable
	return _cache_value
