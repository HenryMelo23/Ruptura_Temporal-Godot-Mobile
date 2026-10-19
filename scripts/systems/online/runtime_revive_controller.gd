class_name RTRuntimeReviveController
extends RefCounted

# Runtime owner for the revive lifecycle. The main runtime intentionally keeps
# public/RPC facades so existing callers and network method names remain stable.

func sync_team_state_from_legacy(game) -> void:
	game.team_revival_state.load_legacy_state(
		game.revival_active, game.revival_dead_peers, game.revival_dead_names,
		game.revival_dead_positions, game.revival_fragments, game.revival_fragments_collected,
		game.revival_timer, game.revival_total_time, game.revival_altars_active,
		game.revival_altar_life_pos, game.revival_altar_points_pos, game.revival_notice,
		game.revival_fragments_suspended, game.revival_fragment_respawn_timer,
		game.revival_state_sync_timer
	)


func sync_team_state_to_legacy(game) -> void:
	var state: Dictionary = game.team_revival_state.export_legacy_state()
	game.revival_active = bool(state.get("active", false))
	game.revival_dead_peers = Array(state.get("dead_peers", []))
	game.revival_dead_names = Dictionary(state.get("dead_names", {}))
	game.revival_dead_positions = Dictionary(state.get("dead_positions", {}))
	game.revival_fragments = Array(state.get("fragments", []))
	game.revival_fragments_collected = int(state.get("fragments_collected", 0))
	game.revival_timer = float(state.get("timer", 0.0))
	game.revival_total_time = float(state.get("total_time", 0.0))
	game.revival_altars_active = bool(state.get("altars_active", false))
	game.revival_altar_life_pos = Vector2(state.get("altar_life_pos", Vector2.ZERO))
	game.revival_altar_points_pos = Vector2(state.get("altar_points_pos", Vector2.ZERO))
	game.revival_notice = String(state.get("notice", ""))
	game.revival_fragments_suspended = bool(state.get("fragments_suspended", false))
	game.revival_fragment_respawn_timer = float(state.get("fragment_respawn_timer", 0.0))
	game.revival_state_sync_timer = float(state.get("state_sync_timer", 0.0))


func clear_team_state(game) -> void:
	game.team_revival_state.clear()
	sync_team_state_to_legacy(game)
	game.revival_mobile_confirm_method = ""
	game.revival_mobile_confirm_until_ms = 0
	game.buttons.erase("revival_mobile")


func register_team_dead(game, dead_peer_id: int, dead_pos: Vector2, dead_name: String) -> void:
	if not game.is_multiplayer or dead_peer_id <= 0 or game.online_local_spectator:
		return
	sync_team_state_from_legacy(game)
	game.team_revival_state.register_dead(dead_peer_id, dead_pos, dead_name, game.WORLD_SIZE, game.REVIVAL_SINGLE_TIME, game.REVIVAL_MULTI_TIME)
	sync_team_state_to_legacy(game)


func generate_fragments_for_dead(game, dead_peer_id: int, dead_pos: Vector2) -> void:
	sync_team_state_from_legacy(game)
	game.team_revival_state.generate_fragments_for_dead(dead_peer_id, dead_pos, game.WORLD_SIZE, game.REVIVAL_FRAGMENTS_PER_DEAD, game.time_alive, game.rng)
	sync_team_state_to_legacy(game)


func start_team_revival_for_dead(game, dead_peer_id: int, dead_pos: Vector2, dead_name: String, broadcast: bool = true) -> void:
	register_team_dead(game, dead_peer_id, dead_pos, dead_name)
	sync_team_state_from_legacy(game)
	if game.team_revival_state.has_fragments_for_dead(dead_peer_id):
		if broadcast:
			broadcast_team_state(game)
		return
	game.team_revival_state.generate_fragments_for_dead(dead_peer_id, dead_pos, game.WORLD_SIZE, game.REVIVAL_FRAGMENTS_PER_DEAD, game.time_alive, game.rng)
	sync_team_state_to_legacy(game)
	refresh_collection_state(game)
	if broadcast:
		broadcast_team_state(game)


func reset_fragments_for_active_dead(game) -> void:
	sync_team_state_from_legacy(game)
	game.team_revival_state.reset_fragments_for_active_dead(game.WORLD_SIZE, game.REVIVAL_FRAGMENTS_PER_DEAD, game.REVIVAL_SINGLE_TIME, game.REVIVAL_MULTI_TIME, game.time_alive, game.rng)
	sync_team_state_to_legacy(game)


func suspend_fragments(game) -> void:
	sync_team_state_from_legacy(game)
	game.team_revival_state.suspend_fragments(game.REVIVAL_FRAGMENT_RESPAWN_TIME)
	sync_team_state_to_legacy(game)


func update_fragment_drift(game, delta: float) -> void:
	if not game._is_world_authority() or game.revival_fragments_suspended or game.revival_altars_active:
		return
	sync_team_state_from_legacy(game)
	game.team_revival_state.update_fragment_drift(delta, game.WORLD_SIZE, game.REVIVAL_FRAGMENT_DRIFT_SPEED, game.rng)
	sync_team_state_to_legacy(game)


func announce_team_death(game, dead_peer_id: int, dead_pos: Vector2, dead_name: String) -> void:
	if not game.is_multiplayer:
		return
	if game._is_world_authority():
		start_team_revival_for_dead(game, dead_peer_id, dead_pos, dead_name, true)
	else:
		register_team_dead(game, dead_peer_id, dead_pos, dead_name)
	if game._shop_rpc_available():
		game.rpc("_rpc_revival_player_down", dead_peer_id, dead_pos, dead_name)


func refresh_collection_state(game) -> void:
	sync_team_state_from_legacy(game)
	game.team_revival_state.refresh_collection_state(game.WORLD_SIZE, game.REVIVAL_ALTAR_SPACING)
	sync_team_state_to_legacy(game)


func activate_altars(game) -> void:
	sync_team_state_from_legacy(game)
	game.team_revival_state.activate_altars(game.WORLD_SIZE, game.REVIVAL_ALTAR_SPACING)
	sync_team_state_to_legacy(game)


func team_dead_count(game) -> int:
	sync_team_state_from_legacy(game)
	return game.team_revival_state.dead_count()


func life_sacrifice_rate(game) -> float:
	sync_team_state_from_legacy(game)
	return game.team_revival_state.life_sacrifice_rate(game.REVIVE_LIFE_SACRIFICE_BASE_RATE, game.REVIVE_LIFE_SACRIFICE_PER_ADDITIONAL_FALLEN_RATE, game.REVIVE_LIFE_SACRIFICE_MAX_RATE, game.REVIVE_LIFE_SACRIFICE_REDUCTION)


func life_sacrifice_rate_for_dead_count(game, dead_count: int) -> float:
	return game.team_revival_state.life_sacrifice_rate_for_dead_count(dead_count, game.REVIVE_LIFE_SACRIFICE_BASE_RATE, game.REVIVE_LIFE_SACRIFICE_PER_ADDITIONAL_FALLEN_RATE, game.REVIVE_LIFE_SACRIFICE_MAX_RATE, game.REVIVE_LIFE_SACRIFICE_REDUCTION)


func points_cost(game) -> int:
	sync_team_state_from_legacy(game)
	return game.team_revival_state.points_cost(revive_cost(game))


func revive_cost(game) -> int:
	return max(1, game.card_cost * game.REVIVE_CARD_COST_MULT)


func local_altar_method(game) -> String:
	sync_team_state_from_legacy(game)
	return game.team_revival_state.altar_method(game.player_pos, game.is_dead, game.online_local_spectator, game.REVIVAL_ALTAR_RADIUS, game.REVIVE_PAY_LIFE, game.REVIVE_PAY_POINTS)


func method_label(game, method: String) -> String:
	return "VIDA" if method == game.REVIVE_PAY_LIFE else "PONTOS"


func apply_team_life_sacrifice(game, rate: float) -> float:
	var loss: float = maxf(1.0, float(game.player_hp) * clampf(rate, 0.0, 0.95))
	game.player_hp = maxf(1.0, float(game.player_hp) - loss)
	game.revive_heal_penalty_timer = maxf(game.revive_heal_penalty_timer, game.REVIVE_HEAL_PENALTY_DURATION)
	game.damage_flash_timer = maxf(game.damage_flash_timer, 0.18)
	game._spawn_radial_particles(game.player_pos, Color(1.0, 0.18, 0.3), 26)
	game._add_text("SACRIFICIO %.0f%% DA VIDA" % (rate * 100.0), game.player_pos + Vector2(0, -96), Color(1.0, 0.34, 0.42), 1.2, 18)
	return loss


func try_interact_altar(game, method: String = "") -> void:
	if not game.revival_active or not game.revival_altars_active or game.is_dead or game.online_local_spectator:
		return
	var selected_method: String = method if method != "" else local_altar_method(game)
	if selected_method == "":
		return
	var revive_hp: float = game.player_hp_max * 0.5
	if selected_method == game.REVIVE_PAY_POINTS:
		var cost: int = points_cost(game)
		if not game._spend_local_score(cost):
			game._add_text("PONTOS INSUFICIENTES", game.player_pos + Vector2(0, -92), Color(1.0, 0.56, 0.28), 0.8, 18)
			return
		game.revival_notice = "ALTAR AZUL: %d pontos gastos" % cost
	else:
		var rate: float = life_sacrifice_rate(game)
		var loss: float = apply_team_life_sacrifice(game, rate)
		revive_hp = maxf(1.0, loss / float(team_dead_count(game)))
		game.revival_notice = "ALTAR VERMELHO: vida dividida entre os caidos"
		sync_team_state_from_legacy(game)
	if game._is_world_authority():
		complete_team_revival(game, selected_method, revive_hp, game._mp_unique_id())
	elif game._shop_rpc_available():
		game.rpc("_rpc_complete_team_revival_request", selected_method, revive_hp, game._mp_unique_id())


func handle_mobile_altar_tap(game) -> bool:
	var method: String = local_altar_method(game)
	if method == "":
		return false
	var now_ms: int = Time.get_ticks_msec()
	if game.revival_mobile_confirm_method == method and now_ms <= game.revival_mobile_confirm_until_ms:
		game.revival_mobile_confirm_method = ""
		game.revival_mobile_confirm_until_ms = 0
		try_interact_altar(game, method)
	else:
		game.revival_mobile_confirm_method = method
		game.revival_mobile_confirm_until_ms = now_ms + game.REVIVAL_MOBILE_DOUBLE_TAP_MS
		game._add_text("TOQUE DE NOVO: ALTAR " + method_label(game, method), game.player_pos + Vector2(0, -92), Color(0.0, 1.0, 0.82), 0.8, 16)
	return true


func update_team_revival(game, delta: float) -> void:
	sync_team_state_from_legacy(game)
	if not game.revival_active:
		return
	if not game.is_multiplayer:
		clear_team_state(game)
		return
	if game.revival_fragments_suspended:
		if game._is_world_authority():
			game.revival_fragment_respawn_timer = maxf(0.0, game.revival_fragment_respawn_timer - delta)
			if game.revival_fragment_respawn_timer <= 0.0:
				reset_fragments_for_active_dead(game)
				broadcast_team_state(game)
				return
			game.revival_state_sync_timer += delta
			sync_team_state_from_legacy(game)
			if game.revival_state_sync_timer >= 1.0:
				game.revival_state_sync_timer = 0.0
				sync_team_state_from_legacy(game)
				broadcast_team_state(game)
		return
	game.revival_timer = maxf(0.0, game.revival_timer - delta)
	sync_team_state_from_legacy(game)
	if game.revival_timer <= 0.0 and not game.revival_altars_active:
		if game._is_world_authority():
			suspend_fragments(game)
			broadcast_team_state(game)
		return
	update_fragment_drift(game, delta)
	if game._is_world_authority() and not game.revival_altars_active:
		game.revival_state_sync_timer += delta
		sync_team_state_from_legacy(game)
		if game.revival_state_sync_timer >= game.REVIVAL_FRAGMENT_SYNC_INTERVAL:
			game.revival_state_sync_timer = 0.0
			sync_team_state_from_legacy(game)
			broadcast_team_state(game)
	if not game.is_dead and not game.online_local_spectator and not game.revival_altars_active:
		for fragment_value in game.revival_fragments:
			var fragment: Dictionary = fragment_value
			if bool(fragment.get("collected", false)):
				continue
			if game.player_pos.distance_to(Vector2(fragment.get("pos", Vector2.ZERO))) <= game.REVIVAL_FRAGMENT_PICKUP_RADIUS:
				request_fragment_collect(game, int(fragment.get("id", 0)))
				break


func request_fragment_collect(game, fragment_id: int) -> void:
	if fragment_id == 0:
		return
	if game._is_world_authority():
		collect_fragment(game, fragment_id, game._mp_unique_id())
	elif game._shop_rpc_available():
		game.rpc("_rpc_collect_revival_fragment", fragment_id, game._mp_unique_id())


func collector_world_pos(game, peer_id: int) -> Vector2:
	if peer_id == game._mp_unique_id():
		return game.player_pos
	var state: Dictionary = game.net_players_by_peer.get(peer_id, {})
	return Vector2(state.get("pos", Vector2(-999999.0, -999999.0)))


func collect_fragment(game, fragment_id: int, collector_peer_id: int) -> void:
	if not game._is_world_authority() or not game.revival_active or game.revival_altars_active or game.revival_fragments_suspended:
		return
	var collector_pos: Vector2 = collector_world_pos(game, collector_peer_id)
	sync_team_state_from_legacy(game)
	var result: Dictionary = game.team_revival_state.try_collect_fragment(fragment_id, collector_pos, game.REVIVAL_FRAGMENT_PICKUP_RADIUS, 34.0)
	sync_team_state_to_legacy(game)
	if not bool(result.get("collected", false)):
		return
	var fragment_pos: Vector2 = Vector2(result.get("pos", Vector2.ZERO))
	game._spawn_radial_particles(fragment_pos, Color(0.72, 0.95, 1.0), 14)
	game._add_text("+FRAGMENTO", fragment_pos + Vector2(0, -34), Color(0.74, 0.96, 1.0), 0.65, 14)
	refresh_collection_state(game)
	broadcast_team_state(game)


func apply_team_state(game, dead_ids: Array, names: Dictionary, positions: Dictionary, fragments: Array, timer: float, altars_active: bool, notice: String, suspended: bool = false, respawn_timer: float = 0.0) -> void:
	game.team_revival_state.apply_network_state(dead_ids, names, positions, fragments, timer, altars_active, notice, suspended, respawn_timer, game.REVIVAL_SINGLE_TIME, game.REVIVAL_MULTI_TIME, game.WORLD_SIZE, game.REVIVAL_ALTAR_SPACING)
	sync_team_state_to_legacy(game)


func broadcast_team_state(game) -> void:
	if not game.is_multiplayer or not game._shop_rpc_available():
		return
	sync_team_state_from_legacy(game)
	var snapshot: Dictionary = game.team_revival_state.rpc_snapshot()
	game.rpc("_rpc_team_revival_state", Array(snapshot.get("dead_ids", [])), Dictionary(snapshot.get("names", {})), Dictionary(snapshot.get("positions", {})), Array(snapshot.get("fragments", [])), float(snapshot.get("timer", 0.0)), bool(snapshot.get("altars_active", false)), String(snapshot.get("notice", "")), bool(snapshot.get("suspended", false)), float(snapshot.get("respawn_timer", 0.0)))


func handle_revive_with_hp(game, hp_amount: float, revive_pos: Vector2 = Vector2.INF) -> void:
	if revive_pos != Vector2.INF:
		game.player_pos = revive_pos.clamp(Vector2(70.0, 80.0), game.WORLD_SIZE - Vector2(70.0, 80.0))
	game.is_dead = false
	game.player_hp = clampf(hp_amount, 1.0, game.player_hp_max)
	game.revive_request_cooldown = 0.0
	clear_revive_request(game)
	clear_team_state(game)
	game._spawn_radial_particles(game.player_pos, Color(0.2, 1.0, 0.5), 42)
	game.mode = "game"


func revive_position_for_peer(game, peer_id: int, actor_peer_id: int) -> Vector2:
	if peer_id == game._mp_unique_id():
		return game.player_pos
	var state: Dictionary = game.net_players_by_peer.get(peer_id, {})
	if state.has("pos"):
		return Vector2(state.get("pos", game.player_pos)).clamp(Vector2(70.0, 80.0), game.WORLD_SIZE - Vector2(70.0, 80.0))
	var actor_pos: Vector2 = collector_world_pos(game, actor_peer_id)
	if actor_pos.x > -900000.0 and actor_pos.y > -900000.0:
		return actor_pos.clamp(Vector2(70.0, 80.0), game.WORLD_SIZE - Vector2(70.0, 80.0))
	return Vector2(game.revival_dead_positions.get(peer_id, game.player_pos)).clamp(Vector2(70.0, 80.0), game.WORLD_SIZE - Vector2(70.0, 80.0))


func revive_positions_for_peers(game, dead_ids: Array, actor_peer_id: int) -> Dictionary:
	var revive_positions: Dictionary = {}
	for dead_peer_id in dead_ids:
		var peer_id: int = int(dead_peer_id)
		revive_positions[peer_id] = revive_position_for_peer(game, peer_id, actor_peer_id)
	return revive_positions


func complete_team_revival(game, method: String, revive_hp: float, actor_peer_id: int) -> void:
	if not game._is_world_authority() or not game.revival_active or not game.revival_altars_active:
		return
	sync_team_state_from_legacy(game)
	var dead_ids: Array = game.team_revival_state.dead_peers.duplicate()
	var revive_positions: Dictionary = revive_positions_for_peers(game, dead_ids, actor_peer_id)
	for dead_peer_id in dead_ids:
		var peer_id: int = int(dead_peer_id)
		var revive_pos: Vector2 = Vector2(revive_positions.get(peer_id, revive_position_for_peer(game, peer_id, actor_peer_id)))
		if peer_id == game._mp_unique_id():
			if game.is_dead:
				handle_revive_with_hp(game, revive_hp, revive_pos)
		else:
			game._apply_remote_player_revive(peer_id, revive_hp, revive_pos)
	if game._shop_rpc_available():
		game.rpc("_rpc_team_revival_complete", dead_ids, revive_hp, method, actor_peer_id, revive_positions)
	var label: String = "REVIVE POR SACRIFICIO" if method == game.REVIVE_PAY_LIFE else "REVIVE POR PONTOS"
	game._add_text(label, game.player_pos + Vector2(0, -96), Color(0.2, 1.0, 0.5), 1.0, 20)
	clear_team_state(game)


func clear_revive_request(game) -> void:
	game.revive_request_timer = 0.0
	game.revive_request_outgoing = false
	game.revive_request_incoming = false
	game.revive_request_from_peer = 0
	game.revive_request_target_peer = 0
	game.revive_request_cost = 0
	game.revive_request_method = game.REVIVE_PAY_POINTS
	for button_id in ["revive_request", "revive_accept", "revive_accept_points", "revive_accept_life", "revive_reject"]:
		game.buttons.erase(button_id)


func update_revive_request(game, delta: float) -> void:
	game.revive_request_cooldown = maxf(0.0, game.revive_request_cooldown - delta)
	if game.revive_request_timer > 0.0:
		game.revive_request_timer = maxf(0.0, game.revive_request_timer - delta)
		if game.revive_request_timer <= 0.0:
			clear_revive_request(game)
	if not game.is_dead and game.revive_request_outgoing:
		clear_revive_request(game)


func request_team_revive(game) -> void:
	if game.online_local_spectator or not game.is_multiplayer or not game.is_dead or game.revive_request_cooldown > 0.0 or game.revive_request_outgoing:
		return
	var cost: int = revive_cost(game)
	game.revive_request_outgoing = true
	game.revive_request_incoming = false
	game.revive_request_timer = game.REVIVE_REQUEST_TIMEOUT
	game.revive_request_cost = cost
	game.revive_request_target_peer = game._mp_unique_id()
	game.revive_request_notice = "Pedido de revive enviado"
	if game._shop_rpc_available():
		game.rpc("_rpc_request_team_revive", game._mp_unique_id(), cost)


func payment_method(game, method: String) -> String:
	return game.REVIVE_PAY_LIFE if method == game.REVIVE_PAY_LIFE else game.REVIVE_PAY_POINTS


func apply_request_life_sacrifice(game) -> void:
	var rate: float = life_sacrifice_rate_for_dead_count(game, 1)
	var loss: float = maxf(1.0, float(game.player_hp) * rate)
	game.player_hp = maxf(1.0, float(game.player_hp) - loss)
	game.revive_heal_penalty_timer = maxf(game.revive_heal_penalty_timer, game.REVIVE_HEAL_PENALTY_DURATION)
	game.damage_flash_timer = maxf(game.damage_flash_timer, 0.18)
	game._spawn_radial_particles(game.player_pos, Color(1.0, 0.18, 0.3), 24)
	game._add_text("SACRIFICIO %.0f%%: CURAS -50%% POR 60s" % (rate * 100.0), game.player_pos + Vector2(0, -96), Color(1.0, 0.34, 0.42), 1.2, 18)


func accept_team_request(game, payment_method_value: String = "") -> void:
	if game.online_local_spectator or not game.revive_request_incoming or game.revive_request_target_peer == 0:
		return
	var cost: int = maxi(1, game.revive_request_cost)
	var method: String = payment_method(game, payment_method_value)
	if method == game.REVIVE_PAY_POINTS:
		if game.score < cost:
			game._add_text("PONTOS INSUFICIENTES", game.player_pos + Vector2(0, -92), Color(1.0, 0.56, 0.28), 0.8, 18)
			return
		game._apply_score_delta(-cost)
	else:
		apply_request_life_sacrifice(game)
	var target_peer: int = game.revive_request_target_peer
	game.revive_request_method = method
	clear_revive_request(game)
	if game._shop_rpc_available():
		game.rpc("_rpc_accept_team_revive", target_peer, cost, method, revive_position_for_peer(game, target_peer, game._mp_unique_id()))


func reject_team_request(game) -> void:
	if not game.revive_request_incoming or game.revive_request_target_peer == 0:
		return
	var target_peer: int = game.revive_request_target_peer
	clear_revive_request(game)
	if game._shop_rpc_available():
		game.rpc("_rpc_reject_team_revive", target_peer)


func receive_team_request(game, dead_peer_id: int, cost: int) -> void:
	if dead_peer_id == game._mp_unique_id() or game.is_dead:
		return
	game.revive_request_incoming = true
	game.revive_request_outgoing = false
	game.revive_request_timer = game.REVIVE_REQUEST_TIMEOUT
	game.revive_request_from_peer = dead_peer_id
	game.revive_request_target_peer = dead_peer_id
	game.revive_request_cost = maxi(1, cost)
	game.revive_request_method = game.REVIVE_PAY_POINTS
	game.revive_request_notice = "Aliado pediu revive"


func apply_accepted_request(game, dead_peer_id: int, method: String, revive_pos: Vector2) -> void:
	var resolved_pos: Vector2 = revive_pos if revive_pos != Vector2.INF else revive_position_for_peer(game, dead_peer_id, game._mp_unique_id())
	if dead_peer_id == game._mp_unique_id():
		handle_revive_with_hp(game, max(1.0, game.player_hp_max * 0.5), resolved_pos)
	else:
		var state: Dictionary = game.net_players_by_peer.get(dead_peer_id, {})
		if not state.is_empty() and not game._remote_player_state_targetable(state):
			game._apply_remote_player_revive(dead_peer_id, max(1.0, float(state.get("hp_max", 1.0)) * 0.5), resolved_pos)
	clear_revive_request(game)
	var label: String = "REVIVE POR SACRIFICIO" if payment_method(game, method) == game.REVIVE_PAY_LIFE else "REVIVE POR PONTOS"
	game._add_text(label, game.player_pos + Vector2(0, -96), Color(0.2, 1.0, 0.5), 1.0, 20)


func receive_rejected_request(game, dead_peer_id: int) -> void:
	if dead_peer_id != game._mp_unique_id():
		clear_revive_request(game)
		return
	game.revive_request_cooldown = game.REVIVE_REQUEST_COOLDOWN
	game.revive_request_notice = "Pedido recusado. Aguarde %.0fs" % game.REVIVE_REQUEST_COOLDOWN
	clear_revive_request(game)


func revive_multiplayer_team_after_boss_kill(game) -> void:
	if not any_multiplayer_player_dead(game):
		return
	var dead_ids: Array = []
	if game.is_dead:
		dead_ids.append(game._mp_unique_id())
	for peer_key in game.net_players_by_peer.keys():
		var peer_id: int = int(peer_key)
		var state: Dictionary = game.net_players_by_peer.get(peer_id, {})
		if bool(state.get("dead", false)) or bool(state.get("eliminated", false)) or float(state.get("hp", 0.0)) <= 0.0:
			dead_ids.append(peer_id)
	var revive_positions: Dictionary = revive_positions_for_peers(game, dead_ids, game._mp_unique_id())
	if game._shop_rpc_available():
		game.rpc("_rpc_revive_player", true, revive_positions)
	if game.is_dead:
		handle_revive_with_hp(game, max(1.0, game.player_hp_max * 0.5), Vector2(revive_positions.get(game._mp_unique_id(), game.player_pos)))
	for peer_key in game.net_players_by_peer.keys():
		var peer_id: int = int(peer_key)
		if dead_ids.has(peer_id):
			var hp_max: float = float(Dictionary(game.net_players_by_peer.get(peer_id, {})).get("hp_max", game.player_hp_max))
			game._apply_remote_player_revive(peer_id, max(1.0, hp_max * 0.5), Vector2(revive_positions.get(peer_id, revive_position_for_peer(game, peer_id, game._mp_unique_id()))))
	clear_team_state(game)
	broadcast_team_state(game)
	game._add_text("EQUIPE REERGUIDA", game.boss_pos + Vector2(0, -176), Color(0.2, 1.0, 0.5), 1.4, 22)


func all_remote_players_dead(game) -> bool:
	if game.net_players_by_peer.is_empty():
		return game.partner_is_dead
	for state_value in game.net_players_by_peer.values():
		if game._remote_player_state_targetable(Dictionary(state_value)):
			return false
	return true


func all_multiplayer_players_dead(game) -> bool:
	if not game.is_multiplayer or not game.is_dead:
		return false
	var expected_remote_count: int = maxi(0, game._active_run_player_count() - (1 if game._local_counts_as_player() else 0))
	if expected_remote_count <= 0:
		return true
	if game.online_connected and game.net_players_by_peer.size() < expected_remote_count:
		return false
	return all_remote_players_dead(game)


func any_multiplayer_player_dead(game) -> bool:
	if game.is_dead:
		return true
	for state_value in game.net_players_by_peer.values():
		var state: Dictionary = state_value
		if bool(state.get("has_snapshot", false)) and not game._remote_player_state_targetable(state):
			return true
	return game.partner_is_dead
