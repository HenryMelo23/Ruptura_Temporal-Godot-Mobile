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
	return not purchase_animating() and not presentation.busy()


func update_countdown(delta: float) -> void:
	if not game.boss1_rewind_sequence.is_empty() or not game.boss1_time_wave.is_empty():
		game._update_audio_volumes()
		game._update_game(delta)
		return
	game.forced_shop_timer -= delta
	if game.forced_shop_timer <= 0.0:
		start_opening_animation(true)
		return
	game._update_audio_volumes()
	update_countdown_tick()
	game._update_game(delta * countdown_time_scale())


func start_opening_animation(forced: bool) -> void:
	if not game.boss1_rewind_sequence.is_empty() or not game.boss1_time_wave.is_empty():
		return
	clear_mp_request()
	game.forced_shop_timer = 0.0
	game.shop_opening_timer = game.SHOP_OPENING_ANIM_TIME
	game.shop_opening_forced = forced
	game.mode = "shop_opening"
	game._update_audio_volumes()
	game.screen_shake_timer = max(game.screen_shake_timer, 0.42)
	game.screen_shake_strength = max(game.screen_shake_strength, 18.0)
	game._vibrate(460, 0.88)
	game._play_sfx("shop_countdown_tick", 0.0, 0.7, 0.72)


func update_opening(delta: float) -> void:
	game.shop_opening_timer -= delta
	if game.shop_opening_timer <= 0.0:
		game.shop_opening_timer = 0.0
		open_shop(game.shop_opening_forced)
		return
	game.screen_shake_timer = max(0.0, game.screen_shake_timer - delta)
	if game.shop_opening_timer <= game.SHOP_OPENING_ANIM_TIME * 0.42 and game.shop_opening_timer + delta > game.SHOP_OPENING_ANIM_TIME * 0.42:
		game._vibrate(240, 0.62)
		game._play_sfx("shop_countdown_tick", 0.0, 0.46, 1.08)
	game._update_effects(delta)
	game._update_audio_volumes()


func countdown_time_scale() -> float:
	if game.forced_shop_timer > game.FORCED_SHOP_SLOW_START:
		return 1.0
	var slow_progress: float = clamp(1.0 - game.forced_shop_timer / game.FORCED_SHOP_SLOW_START, 0.0, 1.0)
	return lerp(1.0, game.FORCED_SHOP_MIN_TIME_SCALE, slow_progress)


func countdown_visible_second() -> int:
	return int(ceil(max(0.01, game.forced_shop_timer)))


func countdown_tick_volume() -> float:
	var progress: float = clamp(1.0 - (game.forced_shop_timer - game.FORCED_SHOP_SLOW_START) / max(0.01, game.FORCED_SHOP_WARNING - game.FORCED_SHOP_SLOW_START), 0.0, 1.0)
	return lerp(0.1, 0.7, progress)


func countdown_audio_duck() -> float:
	if game.mode == "shop_opening":
		return 0.28
	if game.mode != "shop_countdown" or game.forced_shop_timer <= 0.0:
		return 1.0
	var progress: float = clamp(1.0 - game.forced_shop_timer / game.FORCED_SHOP_WARNING, 0.0, 1.0)
	return lerp(1.0, 0.32, progress)


func update_countdown_tick() -> void:
	var second: int = countdown_visible_second()
	if second == game.shop_countdown_last_second:
		return
	game.shop_countdown_last_second = second
	game._play_sfx("shop_countdown_tick", 0.0, countdown_tick_volume())


func purchase_animating() -> bool:
	return game.shop_purchase_anim_timer > 0.0 and not game.shop_purchase_pending_card.is_empty()


func rpc_available() -> bool:
	return game._multiplayer_peer_active()


func clear_mp_request() -> void:
	game.shop_mp_request_timer = 0.0
	game.shop_mp_request_incoming = false
	game.shop_mp_request_outgoing = false
	game.buttons.erase("shop_mp_accept")


func start_mp_request_overlay(incoming: bool) -> void:
	if not game.is_multiplayer:
		return
	game.shop_mp_request_timer = game.SHOP_MP_REQUEST_TIME
	game.shop_mp_request_incoming = incoming
	game.shop_mp_request_outgoing = not incoming
	if game.mode == "shop_mp_waiting" or game.mode == "shop_mp_requested":
		game.mode = "game"


func mp_request_visible() -> bool:
	return game.is_multiplayer and game.mode == "game" and game.shop_mp_request_timer > 0.0 and (game.shop_mp_request_incoming or game.shop_mp_request_outgoing)


func update_mp_request(delta: float) -> void:
	if not mp_request_visible():
		return
	game.shop_mp_request_timer = max(0.0, game.shop_mp_request_timer - delta)
	if game.shop_mp_request_timer <= 0.0:
		clear_mp_request()


func begin_mp_open_locally() -> void:
	clear_mp_request()
	game.shop_mp_ready_count = 0
	game.shop_mp_expected_count = maxi(1, game._living_run_player_peer_ids().size())
	game.shop_mp_partner_ready = false
	game.shop_mp_ready_to_leave = false
	if game.is_dead or game.online_local_spectator:
		game.mode = "shop_mp_waiting"
		game._update_audio_volumes()
		return
	start_opening_animation(false)


func accept_mp_request() -> void:
	if not game.shop_mp_request_incoming:
		return
	if rpc_available():
		game.rpc("_rpc_accept_shop")
	game.shop_mp_request_incoming = false
	game.shop_mp_request_outgoing = true


func request_exit_or_finish() -> void:
	if not can_exit():
		return
	if game.is_multiplayer:
		if game.is_dead or game.online_local_spectator:
			game.mode = "shop_mp_waiting"
			game._update_audio_volumes()
			return
		game.shop_mp_ready_to_leave = true
		if rpc_available():
			game.rpc("_rpc_shop_ready")
		if not game._check_shop_mp_exit():
			game.mode = "shop_mp_waiting"
			game._update_audio_volumes()
	else:
		finish()


func open_shop(forced: bool) -> void:
	if game.mode == "shop":
		return
	if not forced:
		if game.shop_opening_manual_already_tracked:
			game.shop_opening_manual_already_tracked = false
		else:
			track_manual_opening()
	else:
		game.shop_opening_manual_already_tracked = false
	game.shop_manual_reopen_warning_until_ms = 0
	game.shop_manual_reopen_warning_text = ""
	game.shop_endurance_discount = game._shop_endurance_discount_from_elapsed(game.shop_auto_elapsed)
	game.previous_mode = "game"
	game.mode = "shop"
	game._update_audio_volumes()
	game.shop_rerolls = 3
	reset()
	game.shop_mp_ready_count = 0
	game.shop_mp_expected_count = maxi(1, game._living_run_player_peer_ids().size())
	game.shop_purchase_anim_timer = 0.0
	game.shop_purchase_pending_card = {}
	game.shop_purchase_pending_can_continue = false
	game.shop_purchase_pending_price = 0
	game.shop_spend_anim_timer = 0.0
	game.shop_spend_anim_amount = 0
	game.shop_purchases_this_visit = 0
	game.shop_mp_ready_to_leave = false
	game.shop_mp_partner_ready = false
	clear_mp_request()
	game._begin_shop_visit()
	game.shop_cards = game._roll_shop_cards("open")
	game.shop_selected = 0
	game.shop_select_pulse_index = 0
	game.shop_select_pulse_timer = 0.2
	game.shop_last_tap_index = -1
	game.shop_last_tap_msec = 0
	if forced:
		game._add_text("Loja forcada", game.player_pos + Vector2(0, -92), Color(0.0, 1.0, 0.82), 1.4, 26)
	if game.shop_endurance_discount > 0.0:
		game._add_text("RESISTENCIA: -%d%%" % int(round(game.shop_endurance_discount * 100.0)), game.player_pos + Vector2(0, -128), Color(1.0, 0.86, 0.28), 1.6, 24)


func track_manual_opening() -> void:
	var rapid: bool = game.time_alive - game.shop_last_manual_open_time <= 12.0
	if rapid:
		game.shop_recent_manual_open_count += 1
	else:
		game.shop_recent_manual_open_count = 1
	game.shop_last_manual_open_time = game.time_alive
	if game.shop_recent_manual_open_count > 2:
		apply_abuse_penalty("abertura rapida")
	if game.shop_last_exit_had_purchase and game.time_alive - game.shop_last_exit_time <= 35.0:
		apply_abuse_penalty("reroll por saida")


func apply_abuse_penalty(reason: String) -> void:
	if game.score <= 0:
		return
	var penalty: int = min(game.score, max(game.CARD_COST_BASE, game.card_cost))
	game.score = max(0, game.score - penalty)
	game.run_points_spent += penalty
	game.shop_abuse_penalty_count += 1
	game._add_text("TAXA DA LOJA -%d" % penalty, game.player_pos + Vector2(0, -116), Color(1.0, 0.38, 0.18), 1.35, 22)
	if game.shop_abuse_penalty_count <= 2:
		game._add_text(reason.to_upper(), game.player_pos + Vector2(0, -146), Color(1.0, 0.78, 0.24), 1.2, 17)
	game._vibrate(95, 0.4)


func manual_reopen_would_penalize() -> bool:
	if game.score <= 0:
		return false
	var rapid: bool = game.time_alive - game.shop_last_manual_open_time <= 12.0
	if rapid and game.shop_recent_manual_open_count >= 2:
		return true
	return game.shop_last_exit_had_purchase and game.time_alive - game.shop_last_exit_time <= 35.0


func manual_penalty_value() -> int:
	return min(game.score, max(game.CARD_COST_BASE, game.card_cost))


func manual_reopen_warning_active() -> bool:
	return game.shop_manual_reopen_warning_until_ms > Time.get_ticks_msec()


func warn_manual_reopen_penalty() -> void:
	var penalty: int = manual_penalty_value()
	game.shop_manual_reopen_warning_until_ms = Time.get_ticks_msec() + game.SHOP_MANUAL_REOPEN_CONFIRM_MS
	game.shop_manual_reopen_warning_text = "ABRIR AGORA COBRA TAXA DE %d PONTOS. TOQUE DE NOVO PARA CONFIRMAR." % penalty
	game._add_text("LOJA PUNITIVA -%d" % penalty, game.player_pos + Vector2(0, -112), Color(1.0, 0.72, 0.16), 1.0, 20)
	game._add_text("TOQUE DE NOVO PARA ABRIR", game.player_pos + Vector2(0, -140), Color(0.0, 1.0, 0.82), 0.9, 17)
	game._vibrate(45, 0.22)


func buy_selected_card() -> void:
	if busy() or game.mode != "shop":
		return
	if game.shop_cards.is_empty():
		return
	if purchase_animating():
		return
	var card: Dictionary = game.shop_cards[game.shop_selected]
	if game._is_empty_shop_slot(card):
		game._add_text("VAGA VAZIA", game.player_pos + Vector2(0, -92), Color(0.72, 0.46, 0.32), 0.7, 17)
		return
	var price: int = game._effective_card_price(card)
	if game.score < price:
		game._add_text("PONTOS INSUFICIENTES", game.player_pos + Vector2(0, -92), Color(1.0, 0.56, 0.28), 0.8, 18)
		return
	var next_score: int = game.score - price
	game.shop_purchase_pending_card = card.duplicate(true)
	game.shop_purchase_pending_price = price
	game.shop_purchase_pending_can_continue = next_score > 0
	game.shop_purchase_anim_timer = game.SHOP_PURCHASE_ANIM_TIME
	game.shop_select_pulse_index = game.shop_selected
	game.shop_select_pulse_timer = 0.26


func set_selection(index: int) -> void:
	if purchase_animating() or busy():
		return
	if index < 0 or index >= game.shop_cards.size():
		return
	if game.shop_selected == index:
		return
	game.shop_selected = index
	game.shop_select_pulse_index = index
	game.shop_select_pulse_timer = 0.26


func touch_card(index: int) -> void:
	if purchase_animating() or busy():
		return
	var now_msec: int = Time.get_ticks_msec()
	var is_double_tap: bool = game.shop_last_tap_index == index and now_msec - game.shop_last_tap_msec <= 360
	set_selection(index)
	if is_double_tap:
		game.shop_selected = index
		game.shop_select_pulse_index = index
		game.shop_select_pulse_timer = 0.36
		game._vibrate(42, 0.22)
	game.shop_last_tap_index = index
	game.shop_last_tap_msec = now_msec


func reserve_card(index: int) -> void:
	if purchase_animating() or busy() or index < 0 or index >= game.shop_cards.size():
		return
	var card: Dictionary = game.shop_cards[index]
	if game._shop_slot_locked(index):
		begin("unlock", game.shop_cards, index)
		game.shop_locked_slots.erase(game._shop_locked_key(index))
		if game.shop_cards.size() > index:
			game.shop_cards[index].erase("locked_slot")
			game.shop_cards[index].erase("locked_price")
		game._add_text("RESERVA SOLTA", game.player_pos + Vector2(-90, -92), Color(0.4, 0.94, 1.0), 0.9, 17)
		game._vibrate(32, 0.14)
		return
	if not game._can_reserve_shop_card(card):
		return
	if not game._consume_card_count(game.CARD_ESCOLHA_ADIADA_ID):
		return
	begin("lock", game.shop_cards, index)
	var locked: Dictionary = card.duplicate(true)
	var locked_price: int = game._effective_card_price(card)
	locked["locked_slot"] = true
	locked["locked_price"] = locked_price
	game.shop_locked_slots[game._shop_locked_key(index)] = {"card": locked.duplicate(true), "price": locked_price, "locked_at_cost": game.card_cost}
	game.shop_cards[index] = locked
	game.shop_reserved_card_id = ""
	game._add_text("TRAVADA: %s" % String(card.get("nick", card.get("name", ""))), game.player_pos + Vector2(-90, -92), Color(card.get("color", Color.WHITE)), 1.1, 18)
	game._vibrate(44, 0.2)


func reroll() -> void:
	if purchase_animating() or busy():
		return
	if game.shop_rerolls > 0:
		begin("reroll", game.shop_cards)
		game.shop_rerolls -= 1
		game.shop_reroll_index += 1
		game._add_card_unlock_progress("shop_rerolls", 1.0)
		game.shop_cards = game._roll_shop_cards("reroll")
		game.shop_selected = 0
		game.shop_select_pulse_index = 0
		game.shop_select_pulse_timer = 0.2
		game.shop_last_tap_index = -1
		game.shop_last_tap_msec = 0


func finish() -> void:
	game.shop_last_exit_had_purchase = game.shop_purchases_this_visit > 0
	game.shop_last_exit_time = game.time_alive
	game.shop_manual_reopen_warning_until_ms = 0
	game.shop_manual_reopen_warning_text = ""
	game.shop_purchase_anim_timer = 0.0
	game.shop_purchase_pending_card = {}
	game.shop_purchase_pending_can_continue = false
	game.shop_purchase_pending_price = 0
	clear_mp_request()
	game.shop_mp_ready_to_leave = false
	game.shop_mp_partner_ready = false
	game.shop_mp_ready_count = 0
	game.shop_mp_expected_count = maxi(1, game._active_run_player_count())
	game.mode = "shop_return"
	game.shop_return_timer = game.SHOP_RETURN_TIME
	game.shop_return_visual_timer = game.SHOP_RETURN_VISUAL_TIME
	game.forced_shop_timer = -1.0
	game.forced_shop_triggered = false
	game.shop_opening_timer = 0.0
	game.shop_opening_forced = false
	game.shop_last_tap_index = -1
	game.shop_last_tap_msec = 0
	game.shop_auto_elapsed = 0.0
	game.shop_endurance_discount = 0.0
	game.next_forced_shop_time = game.shop_auto_interval if game.shop_auto_enabled else INF
	game._update_audio_volumes()
	game._block_ui_input()


func update_return(delta: float) -> void:
	game.shop_return_timer -= delta
	game.shop_return_visual_timer = maxf(0.0, game.shop_return_visual_timer - delta)
	game._update_effects(delta)
	if game.shop_return_timer <= 0.0:
		game.mode = game.previous_mode if game.previous_mode != "" else "game"
		game.shop_return_timer = 0.0


func update_waiting(delta: float) -> void:
	game._update_effects(delta)
	game._check_shop_mp_exit()


func should_trigger_forced() -> bool:
	if not game.shop_auto_enabled or game.forced_shop_triggered or game.forced_shop_timer >= 0.0 or game.shop_opening_timer > 0.0:
		return false
	return game.shop_auto_elapsed >= game.shop_auto_interval


func set_auto_enabled(enabled: bool) -> void:
	game.shop_auto_enabled = enabled
	game.forced_shop_enabled = enabled
	game.forced_shop_timer = -1.0
	game.forced_shop_triggered = false
	game.shop_opening_timer = 0.0
	game.shop_opening_forced = false
	game.shop_countdown_last_second = -1
	game.shop_auto_elapsed = 0.0
	if enabled:
		game.next_forced_shop_time = game.shop_auto_interval
	else:
		game.next_forced_shop_time = INF
		if game.mode == "shop_countdown" or game.mode == "shop_opening":
			game.mode = "game"
		if game.previous_mode == "shop_countdown":
			game.previous_mode = "game"
		if game.settings_previous_mode == "shop_countdown":
			game.settings_previous_mode = "game"


func try_open_manual() -> void:
	if game._local_player_controls_locked():
		return
	if game.shop_auto_enabled or game.mode != "game":
		return
	if game._affordable_card_count() <= 0:
		game._add_text("FALTAM PONTOS", game.player_pos + Vector2(0, -96), Color(1.0, 0.56, 0.28), 0.9, 20)
		return
	if manual_reopen_would_penalize() and not manual_reopen_warning_active():
		warn_manual_reopen_penalty()
		return
	if not manual_reopen_warning_active() and game._maybe_start_context_tutorial(game.TUTORIAL_STATE_SHOP):
		return
	if game.is_multiplayer:
		if mp_request_visible():
			return
		start_mp_request_overlay(false)
		if rpc_available():
			game.rpc("_rpc_request_shop")
		return
	if manual_reopen_would_penalize() and manual_reopen_warning_active():
		track_manual_opening()
		game.shop_opening_manual_already_tracked = true
	start_opening_animation(false)


func start_forced_countdown() -> void:
	if game._local_player_controls_locked():
		return
	if not game.shop_auto_enabled:
		return
	if game.is_multiplayer and not game._is_world_authority():
		return
	if game.is_multiplayer and game._is_world_authority():
		game.rpc("_rpc_trigger_shop", true)
	game.forced_shop_triggered = true
	game.forced_shop_timer = game.FORCED_SHOP_WARNING
	game.shop_countdown_last_second = -1
	game.mode = "shop_countdown"


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
