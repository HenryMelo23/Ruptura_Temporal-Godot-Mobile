extends RefCounted

const CYAN := Color(0.35, 0.9, 1.0, 0.9)
const GOLD := Color(1.0, 0.77, 0.28, 0.9)
const RED := Color(1.0, 0.25, 0.32, 0.9)
const GREEN := Color(0.45, 1.0, 0.72, 0.85)


static func draw(game: Node2D, center: Vector2) -> void:
	if game.is_dead or game._spectator_controls_locked():
		return
	_draw_manifestation(game, center)
	_draw_aura(game, center)
	_draw_card_readiness(game, center)
	_draw_contract(game, center)
	if game.revive_heal_penalty_timer > 0.0 or game._is_player_calcified():
		for side in [-1.0, 1.0]:
			var wound := center + Vector2(side * 25.0, -16.0)
			stroke(game, wound + Vector2(-3, -8), wound + Vector2(3, 8), RED)
			stroke(game, wound + Vector2(-5, -2), wound + Vector2(5, 2), RED)


static func stroke(game: Node2D, start: Vector2, end: Vector2, color: Color, width: float = 1.8) -> void:
	game.draw_line(start, end, Color(0.015, 0.025, 0.035, color.a * 0.8), width + 2.0, true)
	game.draw_line(start, end, color, width, true)


static func shard(game: Node2D, center: Vector2, direction: Vector2, size: float, color: Color) -> void:
	var side := direction.orthogonal() * size * 0.36
	game.draw_colored_polygon(PackedVector2Array([center + direction * size, center + side, center - direction * size * 0.6, center - side]), Color(0.025, 0.04, 0.055, 0.8))
	stroke(game, center - direction * size * 0.6, center + direction * size, color, 2.0)
	stroke(game, center - side, center + side, Color(color, color.a * 0.65), 1.0)


static func _draw_manifestation(game: Node2D, center: Vector2) -> void:
	var clock: float = game.time_alive
	match String(game.manifestation_key):
		"ancorada":
			for index in range(5):
				var strength := clampf(float(game.lastro_stacks) + float(game.lastro_points) / 4.0 - index, 0.0, 1.0)
				if strength <= 0.0:
					continue
				var position := center + Vector2((index - 2) * 13.0, 39.0 + absf(index - 2) * 2.0)
				var color := GREEN.lerp(Color.WHITE, 0.7 if game.lastro_stacks == 5 else 0.0)
				shard(game, position, Vector2.UP, 5.0 + strength * 5.0, Color(color, 0.35 + strength * 0.6))
		"acorrentada":
			var tension := clampf(game.acorrentada_tension / 100.0, 0.0, 1.0)
			for index in range(3):
				var angle := PI * 0.25 + index * PI * 0.25
				var position := center + Vector2.from_angle(angle) * (43.0 - tension * 9.0)
				var color := RED if tension >= 1.0 else CYAN
				var strength := 1.0 if index < game.acorrentada_combo_step else tension * 0.55
				if strength > 0.0:
					game.draw_arc(position, 5.0, 0.0, TAU, 10, Color(color, strength), 2.5, true)
			if tension > 0.0:
				game.draw_arc(center + Vector2(0, 8), 35.0, PI * 0.12, PI * (0.12 + tension * 0.76), 18, Color(RED if tension >= 1.0 else CYAN, 0.8), 2.0, true)
		"bombastica":
			for index in range(mini(game.BOMBASTICA_Q_CHARGES, game.bombastica_q_recharges.size())):
				var charge := 1.0 - clampf(float(game.bombastica_q_recharges[index]) / game.BOMBASTICA_Q_RECHARGE, 0.0, 1.0)
				var position := center + Vector2(34.0, -20.0 + index * 15.0)
				game.draw_circle(position, 4.0, Color(0.12, 0.075, 0.04, 0.9))
				game.draw_arc(position, 4.0, -PI * 0.5, -PI * 0.5 + TAU * charge, 12, GOLD, 2.0, true)
				stroke(game, position + Vector2(0, -3), position + Vector2(3, -7), GOLD, 1.0)
				if charge >= 1.0:
					shard(game, position + Vector2(3, -8), Vector2.UP, 2.5 + sin(clock * 6.0 + index), GOLD)
		"necronada":
			var progress := clampf(float(game.necronada_horde_progress) / maxf(1.0, game.NECRONADA_ULTIMATE_REQUIRED_REVIVES), 0.0, 1.0)
			for index in range(6):
				if float(index) / 6.0 >= progress:
					continue
				var direction := Vector2.from_angle(index * TAU / 6.0 + clock * 0.35)
				shard(game, center + Vector2(-34, -15) + direction * 8.0, direction, 5.0, Color(0.7, 0.55, 1.0, 0.9))


static func _draw_aura(game: Node2D, center: Vector2) -> void:
	if game.aura_state.is_empty():
		return
	var name := String(game.aura_state.get("name", ""))
	var strength: float = clampf(game._aura_hud_ratio(), 0.0, 1.0)
	if float(game.aura_state.get("impulsive_active", 0.0)) > 0.0 or float(game.aura_state.get("vanguard_guard", 0.0)) > 0.0:
		strength = 1.0
	if strength <= 0.0:
		return
	var color: Color = game._aura_color()
	var clock: float = game.time_alive
	var count := 3 if name == "Devota" else 5
	for index in range(count):
		var amount := clampf(strength * count - index, 0.0, 1.0)
		if amount <= 0.0:
			continue
		var angle := PI * 0.12 + float(index + 1) / float(count + 1) * PI * 0.76
		var position := center + Vector2(cos(angle) * 49.0, 32.0 + sin(angle) * 23.0)
		color.a = 0.35 + amount * 0.5
		match name:
			"Incandescência", "Vanguarda", "Impulsiva":
				var height := 6.0 + amount * 6.0 + sin(clock * 6.0 + index) * 2.0
				shard(game, position - Vector2(0, height * 0.4), Vector2(0.2, -1).normalized(), height * 0.6, color)
			"Devota", "Avarento":
				stroke(game, position + Vector2(-5, -4), position + Vector2(0, 5), color, 2.5)
				stroke(game, position + Vector2(0, 5), position + Vector2(5, -4), color, 2.5)
			"Nula", "Abissal":
				var drift := Vector2(sin(clock * 1.5 + index) * 2.0, 0)
				stroke(game, position + drift + Vector2(-5, -3), position - drift + Vector2(5, 3), color)
			"Voraz", "Sanguinaria":
				shard(game, position, Vector2.DOWN, 6.0 + amount * 3.0, color)
			_:
				shard(game, position + Vector2(0, sin(clock * 2.0 + index) * 2.0), Vector2.UP, 5.0, color)


static func _draw_card_readiness(game: Node2D, center: Vector2) -> void:
	var clock: float = game.time_alive
	if game.reserva_pulso_stored > 0.0:
		var stored := clampf(game.reserva_pulso_stored / maxf(1.0, game.player_hp_max), 0.0, 1.0)
		var position := center + Vector2(-30, 4)
		var direction := Vector2.RIGHT if game.reserva_pulso_releasing else Vector2.UP
		shard(game, position + direction * sin(clock * 3.0) * 2.0, direction, 5.0 + stored * 9.0, CYAN)
	if game.margem_debt > 0.0 or game.margem_window_timer > 0.0:
		var danger := RED if game.margem_debt > 0.0 else GOLD
		for side in [-1.0, 1.0]:
			var position := center + Vector2(side * 40.0, 0)
			stroke(game, position + Vector2(side * 3, -15), position + Vector2(-side * 3, 0), danger)
			stroke(game, position + Vector2(-side * 3, 0), position + Vector2(side * 3, 15), danger)
	if game.impulso_charges > 0:
		for index in range(mini(3, game.impulso_charges)):
			var position := center + Vector2(24.0 + index * 6.0, 20.0)
			stroke(game, position, position + Vector2(4, -9), CYAN)
	if game.folego_charge > 0.0:
		for side in [-1.0, 1.0]:
			var position := center + Vector2(side * 14.0, 31.0)
			stroke(game, position, position + Vector2(side * 14.0 * game.folego_charge, 4.0), GOLD)
	if game.ressonancia_ready_timer > 0.0 or not game.ressonancia_symbols.is_empty():
		var count := 4 if game.ressonancia_ready_timer > 0.0 else mini(4, game.ressonancia_symbols.size())
		for index in range(count):
			var direction := Vector2.from_angle(PI * 0.25 + index * PI * 0.5)
			shard(game, center + direction * (28.0 + sin(clock * 3.0) * 2.0), direction, 4.0, GREEN)
	if game._mandamento_count() > 0:
		for index in range(clampi(game.mandamento_skill_uses, 0, 3)):
			var position := center + Vector2(-8 + index * 8, -43)
			shard(game, position, Vector2.UP, 4.0, GOLD)
	if int(game.cards_bought.get("Mercenaria", 0)) > 0:
		for index in range(posmod(game.combo_kills, 5)):
			var position := center + Vector2(-38, 14.0 - index * 6.0)
			stroke(game, position, position + Vector2(5, -2), GOLD)
	if game.collector_hud_pulse > 0.0:
		var position := center + Vector2(29, -27)
		stroke(game, position, position + Vector2(-8, -6), Color(RED, clampf(game.collector_hud_pulse, 0.0, 1.0)))
	if game.paradox_charge_hits > 0 and not game.paradox_ready and game.paradox_active_timer <= 0.0:
		var charge := clampf(float(game.paradox_charge_hits) / maxf(1.0, game.PARADOX_HITS_REQUIRED), 0.0, 1.0)
		stroke(game, center + Vector2(-27, -30), center + Vector2(-27 + charge * 18, -42), GOLD)
	if game._rare_card_count("necrocronismo") > 0 and game.necro_kill_counter > 0:
		var charge := clampf(float(game.necro_kill_counter) / maxf(1.0, game._necro_kills_required()), 0.0, 1.0)
		shard(game, center + Vector2(-22, 28), Vector2.UP, 3.0 + charge * 7.0, GREEN)
	if game._support_card_count(game.CARD_TREGUA_ID) > 0 and not game.tregua_regenerativa_active:
		var charge := clampf(game.tregua_regenerativa_timer / maxf(0.01, game._tregua_delay()), 0.0, 1.0)
		if charge > 0.0:
			stroke(game, center + Vector2(-18, 27), center + Vector2(-18, 27 - charge * 14), GREEN)
	if game._support_card_count(game.CARD_ESTASE_ID) > 0 and not game.estase_reparadora_active:
		var charge := clampf(game.estase_reparadora_timer / 5.0, 0.0, 1.0)
		if charge > 0.0:
			stroke(game, center + Vector2(18, 27), center + Vector2(18, 27 - charge * 14), GREEN)
	if game.casulo_reativo_cooldown > 0.0 and game.casulo_reativo_timer <= 0.0:
		var charge := 1.0 - clampf(game.casulo_reativo_cooldown / maxf(0.01, game.CASULO_INTERNAL_COOLDOWN), 0.0, 1.0)
		game.draw_arc(center + Vector2(0, 16), 26.0, PI * 0.15, PI * (0.15 + charge * 0.7), 16, Color(GREEN, 0.55), 1.5, true)


static func _draw_contract(game: Node2D, center: Vector2) -> void:
	if not game.contractual_order_rewards.is_empty():
		shard(game, center + Vector2(-18, -38), Vector2.UP, 7.0, GOLD)
	if not game.contractual_order_penalties.is_empty():
		stroke(game, center + Vector2(14, -43), center + Vector2(22, -33), RED)
		stroke(game, center + Vector2(22, -43), center + Vector2(14, -33), RED)
	if game.contractual_order.is_empty():
		return
	var order: Dictionary = game.contractual_order
	if float(order.get("real_age", order.get("age", 0.0))) < game.CONTRACT_ORDER_EXECUTION_START_TIME:
		return
	var label := "%s  %d/%d  %.0fs" % [String(order.get("label", "ORDEM")), int(order.get("progress", 0)), maxi(1, int(order.get("goal", 1))), ceil(float(order.get("time_left", 0.0)))]
	var position := center + Vector2(-140, -64)
	game.draw_string_outline(game.font, position, label, HORIZONTAL_ALIGNMENT_CENTER, 280.0, 11, 4, Color(0.02, 0.02, 0.025, 0.95))
	game.draw_string(game.font, position, label, HORIZONTAL_ALIGNMENT_CENTER, 280.0, 11, GOLD)
