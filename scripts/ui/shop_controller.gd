extends Node
class_name RTShopController

## Local controller for the shop screen.
##
## The main game still owns shop rules, economy, multiplayer and card effects.
## This node owns the shop presentation lifecycle and translates input into
## calls to that game contract. Keeping the boundary here lets the UI move out
## of main.gd incrementally without introducing a second source of truth.

signal purchase_committed(card: Dictionary, paid_price: int)
signal interaction_changed(kind: String)

const AuraSystem = preload("res://scripts/aura_system.gd")
const SHOP_SPEND_ANIM_TIME: float = 0.72

var game: Object
var presentation = preload("res://scripts/ui/shop_presentation.gd").new()


func configure(game_owner: Object) -> void:
	game = game_owner


func reset() -> void:
	presentation.reset()


func begin(kind: String, cards: Array, index: int = -1) -> void:
	presentation.begin(kind, cards, index)
	interaction_changed.emit(kind)


func busy() -> bool:
	return presentation.busy()


func can_exit() -> bool:
	if game == null:
		return not presentation.busy()
	return not game._shop_purchase_animating() and not presentation.busy()


func update(delta: float) -> void:
	if game == null:
		return
	presentation.update(delta)
	game.shop_select_pulse_timer = max(0.0, game.shop_select_pulse_timer - delta)
	game.shop_spend_anim_timer = max(0.0, game.shop_spend_anim_timer - delta)
	game._update_effects(delta)
	if not game._shop_purchase_animating():
		return
	game.shop_purchase_anim_timer = max(0.0, game.shop_purchase_anim_timer - delta)
	if game.shop_purchase_anim_timer > 0.0:
		return
	var card: Dictionary = game.shop_purchase_pending_card
	var paid_price: int = game.shop_purchase_pending_price
	game.shop_purchase_pending_card = {}
	game.shop_purchase_pending_price = 0
	game.shop_purchases_this_visit += 1
	game.run_points_spent += paid_price
	game._apply_aura_events(AuraSystem.on_points_spent(game.aura_state, paid_price, game.player_hp_max))
	game.score -= paid_price
	game.shop_spend_anim_amount = paid_price
	game.shop_spend_anim_timer = SHOP_SPEND_ANIM_TIME
	game._apply_card(card)
	game._register_card_purchase_unlock_progress(card)
	game.card_cost += game._shop_price_increment_after_purchase()
	game._clear_locked_shop_slot_for_card(card)
	game._refill_shop_slot_after_purchase(game.shop_selected)
	game.shop_selected = clamp(game.shop_selected, 0, max(0, game.shop_cards.size() - 1))
	game.shop_select_pulse_index = game.shop_selected
	game.shop_select_pulse_timer = 0.22
	game.shop_last_tap_index = -1
	game.shop_last_tap_msec = 0
	game.shop_purchase_pending_can_continue = false
	purchase_committed.emit(card, paid_price)
	interaction_changed.emit("purchase_committed")


func draw(viewport: Vector2) -> void:
	if game == null:
		return
	presentation.draw(game, viewport)


func draw_exit(viewport: Vector2) -> void:
	if game == null:
		return
	presentation.draw_exit(game, viewport)


func draw_waiting(viewport: Vector2) -> void:
	if game == null:
		return
	presentation.draw_waiting(game, viewport)


func layout(viewport: Vector2) -> Dictionary:
	return presentation.layout(viewport)


func handle_touch(pos: Vector2, viewport: Vector2) -> void:
	if game == null or game._shop_purchase_animating() or presentation.busy():
		return
	if not game._is_portrait(viewport):
		var areas: Dictionary = presentation.layout(viewport)
		if Rect2(areas.buy).has_point(pos):
			game._buy_selected_card()
		elif Rect2(areas.exit).has_point(pos):
			game._request_shop_exit_or_finish()
		elif Rect2(areas.reroll).has_point(pos):
			game._reroll_shop()
		elif Rect2(areas.deck).has_point(pos) and game._deck_total_cards() > 0:
			game._open_deck("shop")
		elif Rect2(areas.burn).has_point(pos):
			game._burn_shop_card(game.shop_selected)
		elif Rect2(areas.reserve).has_point(pos):
			game._reserve_shop_card(game.shop_selected)
		else:
			for i in range(mini(3, game.shop_cards.size())):
				if Rect2(areas.cards[i]).has_point(pos):
					game._touch_shop_card(i)
		return
	for i in range(game.shop_cards.size()):
		var burn_key: = "shop_burn_%d" % i
		if game.buttons.has(burn_key) and Rect2(game.buttons[burn_key]).has_point(pos):
			game._burn_shop_card(i)
			return
		var reserve_key: = "shop_reserve_%d" % i
		if game.buttons.has(reserve_key) and Rect2(game.buttons[reserve_key]).has_point(pos):
			game._reserve_shop_card(i)
			return
	var round_r: float = game._shop_round_button_radius(viewport) + 10.0
	if pos.distance_to(game._shop_reroll_center(viewport)) <= round_r:
		game._reroll_shop()
		return
	if pos.distance_to(game._shop_deck_center(viewport)) <= round_r and game._deck_total_cards() > 0:
		game._open_deck("shop")
		return
	if game._is_portrait(viewport):
		var card_w: float = viewport.x * 0.74
		var card_h: float = min(242.0, viewport.y * 0.19)
		for i in range(game.shop_cards.size()):
			var card_x: float = viewport.x * 0.5 - card_w * 0.5
			var card_y: float = 188.0 + i * (card_h + 22.0)
			if Rect2(card_x, card_y, card_w, card_h).has_point(pos):
				game._touch_shop_card(i)
				return

		var portrait_btn_h: float = 44.0
		var portrait_btn_w: float = viewport.x * 0.4
		var portrait_btn_y: float = viewport.y - portrait_btn_h - 24.0
		var portrait_buy_rect: = Rect2(viewport.x * 0.25 - portrait_btn_w * 0.5, portrait_btn_y, portrait_btn_w, portrait_btn_h)
		var portrait_exit_rect: = Rect2(viewport.x * 0.75 - portrait_btn_w * 0.5, portrait_btn_y, portrait_btn_w, portrait_btn_h)
		if portrait_buy_rect.has_point(pos):
			game._buy_selected_card()
		elif portrait_exit_rect.has_point(pos) and can_exit():
			game._request_shop_exit_or_finish()
		return

	var btn_w: float = 220.0
	var btn_h: float = 42.0
	var btn_y: float = viewport.y - btn_h - 24.0
	var btn_buy_rect: = Rect2(viewport.x * 0.38 - btn_w * 0.5, btn_y, btn_w, btn_h)
	var btn_exit_rect: = Rect2(viewport.x * 0.62 - btn_w * 0.5, btn_y, btn_w, btn_h)
	if btn_buy_rect.has_point(pos):
		game._buy_selected_card()
		return
	if btn_exit_rect.has_point(pos):
		if can_exit():
			game._request_shop_exit_or_finish()
		return

	var card_w: float = 150.0
	var card_h: float = 200.0
	var card_y: float = 158.0
	for i in range(game.shop_cards.size()):
		var is_selected: bool = i == game.shop_selected
		var card_scale: float = 1.15 if is_selected else 0.85
		var current_w: float = card_w * card_scale
		var current_h: float = card_h * card_scale
		var card_x: float = viewport.x * 0.5 + (i - 1) * 200.0 - current_w * 0.5
		var current_y: float = card_y - 10.0 if is_selected else card_y + 15.0
		if Rect2(card_x, current_y, current_w, current_h).has_point(pos):
			game._touch_shop_card(i)
			return
