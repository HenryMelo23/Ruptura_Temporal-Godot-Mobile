class_name RTRuntimeDropModeController
extends RefCounted

const MODE_SHOP := "shop"
const MODE_DROP := "drop"

const DROP_LIFETIME := 5.0
const DROP_BLINK_WINDOW := 2.0
const BASE_DROP_CHANCE := 0.015
const REFERENCE_MINUTES := 75.0
const REFERENCE_DROP_CHANCE := 0.35

const OWNER_COLORS := [
	Color(0.18, 0.92, 1.0),
	Color(1.0, 0.48, 0.12),
	Color(0.78, 0.42, 1.0),
]

var core: Node = null


func configure(root: Node) -> void:
	core = root


func sanitize_mode(value: String) -> String:
	return MODE_DROP if value.strip_edges().to_lower() == MODE_DROP else MODE_SHOP


func is_drop_mode() -> bool:
	return core != null and sanitize_mode(String(core.selected_run_mode)) == MODE_DROP


func can_lobby_peer_select_mode(sender_peer_id: int, owner_peer_id: int) -> bool:
	return sender_peer_id > 0 and owner_peer_id > 0 and sender_peer_id == owner_peer_id


func drop_chance(elapsed_seconds: float, party_size: int = 1) -> float:
	var minutes := maxf(0.0, elapsed_seconds) / 60.0
	var growth := -log((1.0 - REFERENCE_DROP_CHANCE) / (1.0 - BASE_DROP_CHANCE)) / REFERENCE_MINUTES
	var solo_chance := 1.0 - (1.0 - BASE_DROP_CHANCE) * exp(-growth * minutes)
	return solo_chance / sqrt(float(maxi(1, party_size)))


func active_party_size() -> int:
	if core == null or not core.is_multiplayer:
		return 1
	if core.online_lobby_active_player_count > 0:
		return maxi(1, core.online_lobby_active_player_count)
	return maxi(1, core._reward_peer_ids().size())


func on_enemy_killed(enemy: Dictionary, pos: Vector2, forced_roll: float = -1.0) -> bool:
	if core == null or not is_drop_mode() or not core._is_world_authority():
		return false
	var owner_peer := int(enemy.get("killed_by_peer_id", core._mp_unique_id()))
	if owner_peer <= 0:
		owner_peer = core._mp_unique_id()
	var roll: float = forced_roll if forced_roll >= 0.0 else core.rng.randf()
	if roll >= drop_chance(core.time_alive, active_party_size()):
		return false
	var card := _pick_card_for_owner(owner_peer)
	if card.is_empty():
		return false
	var identity := owner_identity(owner_peer)
	core._append_owned_card_drop(
		card,
		pos,
		core.rng.randf_range(-PI, PI),
		owner_peer,
		DROP_LIFETIME,
		18.0,
		42.0,
		24.0,
		48.0,
		{
			"drop_mode": true,
			"owner_name": identity["name"],
			"owner_color": identity["color"],
			"max_life": DROP_LIFETIME,
		}
	)
	return true


func owner_identity(peer_id: int) -> Dictionary:
	var fallback_name := "VOCE" if core == null or not core.is_multiplayer else "JOGADOR %d" % peer_id
	var slot := 1
	if core != null:
		if peer_id == core._mp_unique_id() or not core.is_multiplayer:
			fallback_name = core.player_nickname if String(core.player_nickname).strip_edges() != "" else fallback_name
		for value in core.online_lobby_roster:
			if value is Dictionary and int(value.get("peer_id", value.get("id", 0))) == peer_id:
				fallback_name = String(value.get("name", fallback_name))
				slot = maxi(1, int(value.get("slot", slot)))
				break
		if core.net_players_by_peer.has(peer_id):
			var state := Dictionary(core.net_players_by_peer.get(peer_id, {}))
			fallback_name = String(state.get("name", fallback_name))
		if core.net_decks_by_peer.has(peer_id):
			var deck := Dictionary(core.net_decks_by_peer.get(peer_id, {}))
			fallback_name = String(deck.get("name", fallback_name))
	return {
		"name": fallback_name.to_upper(),
		"color": OWNER_COLORS[clampi(slot - 1, 0, OWNER_COLORS.size() - 1)],
		"slot": slot,
	}


func confirm_collect(drop_id: String, collector_peer_id: int, remote_request: bool = false) -> bool:
	if core == null or drop_id == "" or collector_peer_id <= 0:
		return false
	for drop in core.arauto_card_drops:
		if String(drop.get("drop_id", "")) != drop_id or not bool(drop.get("drop_mode", false)):
			continue
		if int(drop.get("owner_peer", 0)) != collector_peer_id:
			return false
		if remote_request:
			var state := Dictionary(core.net_players_by_peer.get(collector_peer_id, {}))
			if not core._remote_player_state_targetable(state):
				return false
			var remote_pos := Vector2(state.get("pos", Vector2.ZERO))
			var pickup_radius: float = core._neutral_pickup_radius_for_peer(50.0, collector_peer_id) + 36.0
			if remote_pos.distance_to(Vector2(drop.get("pos", remote_pos))) > pickup_radius:
				return false
		drop["life"] = 0.0
		remember_collected(drop_id)
		core.arauto_card_drops = core.arauto_card_drops.filter(func(item): return float(item.get("life", 0.0)) > 0.0)
		return true
	return false


func remember_collected(drop_id: String) -> void:
	if core == null or drop_id == "":
		return
	core.net_collected_drop_ids[drop_id] = Time.get_ticks_msec()
	while core.net_collected_drop_ids.size() > 512:
		core.net_collected_drop_ids.erase(core.net_collected_drop_ids.keys()[0])


func _pick_card_for_owner(owner_peer: int) -> Dictionary:
	var pools := {
		core.CARD_RARITY_COMMON: [],
		core.CARD_RARITY_UNCOMMON: [],
		core.CARD_RARITY_RARE: [],
		core.CARD_RARITY_LEGENDARY: [],
	}
	for value in core.CARDS:
		var card := Dictionary(value)
		if not _card_available_for_owner(card, owner_peer):
			continue
		pools[core._card_rarity_key(card)].append(card)
	var weighted: Array = core._progression().temporal_luck_controller.drop_mode_rarity_weights()
	var available_weight := 0.0
	for entry in weighted:
		if not Array(pools[entry[0]]).is_empty():
			available_weight += float(entry[1])
	if available_weight <= 0.0:
		return {}
	var rarity_roll: float = core.rng.randf_range(0.0, available_weight)
	var chosen_rarity: String = core.CARD_RARITY_COMMON
	for entry in weighted:
		var rarity_pool: Array = pools[entry[0]]
		if rarity_pool.is_empty():
			continue
		rarity_roll -= float(entry[1])
		chosen_rarity = String(entry[0])
		if rarity_roll <= 0.0:
			break
	var pool: Array = pools[chosen_rarity]
	return Dictionary(pool[core.rng.randi_range(0, pool.size() - 1)]).duplicate(true) if not pool.is_empty() else {}


func _card_available_for_owner(card: Dictionary, owner_peer: int) -> bool:
	if not core._card_unlocked(card) or not core._card_drop_texture_available(card):
		return false
	var counts: Dictionary = core.cards_bought
	if core.is_multiplayer and owner_peer != core._mp_unique_id():
		var remote_deck := Dictionary(core.net_decks_by_peer.get(owner_peer, {}))
		counts = Dictionary(remote_deck.get("counts", remote_deck))
	var sorte_count := int(counts.get("Sorte", 0))
	var rarity: String = core._card_rarity_key(card)
	if rarity == core.CARD_RARITY_RARE and sorte_count <= 0:
		return false
	if rarity == core.CARD_RARITY_LEGENDARY and (core.current_phase < 2 or sorte_count <= 0):
		return false
	var card_key: String = core._card_counter_key(card)
	var pending_count := 0
	for value in core.arauto_card_drops:
		var pending := Dictionary(value)
		if bool(pending.get("drop_mode", false)) and int(pending.get("owner_peer", 0)) == owner_peer and float(pending.get("life", 0.0)) > 0.0:
			if core._card_counter_key(Dictionary(pending.get("card", {}))) == card_key:
				pending_count += 1
	return int(counts.get(card_key, 0)) + pending_count < core._card_max_count(card)
