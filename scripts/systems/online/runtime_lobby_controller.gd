extends Node
class_name RTLobbyController

# Owns lobby-ready/session snapshot application. RPC entrypoints intentionally
# remain on Main so their node path and Godot RPC configuration never change.
var game: Node = null


func bind_game(root: Node) -> void:
	game = root


func character_assignment(roster: Array, local_peer_id: int, local_name: String, room_owner: bool) -> Dictionary:
	if room_owner:
		return {"slot": 1, "character": game.CHARACTER_GEOVANA}
	var normalized_name := local_name.strip_edges().to_lower()
	var local_slot := 0
	var peer_match_found := false
	var name_match_count := 0
	var matched_name_slot := 0
	var fallback_entries: Array[Dictionary] = []
	for entry_value in roster:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry := Dictionary(entry_value)
		if bool(entry.get("spectator", false)):
			continue
		var entry_slot := int(entry.get("slot", 0))
		var entry_peer := int(entry.get("peer_id", entry.get("id", 0)))
		var entry_name := String(entry.get("name", "")).strip_edges().to_lower()
		var matches_peer := local_peer_id > 0 and entry_peer == local_peer_id
		var matches_name := normalized_name != "" and entry_name == normalized_name
		if matches_peer:
			local_slot = entry_slot
			peer_match_found = true
		if matches_name:
			name_match_count += 1
			matched_name_slot = entry_slot
		fallback_entries.append({"peer_id": entry_peer, "owner": bool(entry.get("owner", false)), "name": entry_name})
	if not peer_match_found and name_match_count == 1:
		local_slot = matched_name_slot
	if local_slot <= 0:
		fallback_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if bool(a.get("owner", false)) != bool(b.get("owner", false)):
				return bool(a.get("owner", false))
			return int(a.get("peer_id", 0)) < int(b.get("peer_id", 0))
		)
		for index in range(fallback_entries.size()):
			var fallback_entry := fallback_entries[index]
			var matches_peer := local_peer_id > 0 and int(fallback_entry.get("peer_id", 0)) == local_peer_id
			var matches_unique_name := not peer_match_found and name_match_count == 1 and String(fallback_entry.get("name", "")) == normalized_name
			if matches_peer or matches_unique_name:
				local_slot = index + 1
				break
	if local_slot <= 0:
		local_slot = 2
	return {
		"slot": local_slot,
		"character": game.CHARACTER_HENRY if local_slot == 2 else game.CHARACTER_GEOVANA
	}


func apply_lobby_ready_request(ready: bool, sequence: int) -> void:
	game._net_report_count_in("control", 32)
	game._net_report_event("toggle_ready_in", "ready=%s sender=%d dedicated=%s seq=%d" % [str(ready), game._mp_sender_id(), str(game.dedicated_server_mode), sequence])
	if game.dedicated_server_mode:
		var sender: int = game._mp_sender_id()
		if sender != 0:
			if game._is_dedicated_spectator(sender):
				game.dedicated_ready_by_peer[sender] = true
				game.dedicated_ready_seq_by_peer[sender] = maxi(sequence, int(game.dedicated_ready_seq_by_peer.get(sender, 0)))
				if sequence > 0:
					game._net_report_count_out("control", 40)
					game.rpc_id(sender, "_online_lobby_ready_ack", sequence, true, true, game.dedicated_room_code)
				game._sync_dedicated_lobby_state()
				return
			game.dedicated_ready_by_peer[sender] = ready
			game.dedicated_ready_seq_by_peer[sender] = maxi(sequence, int(game.dedicated_ready_seq_by_peer.get(sender, 0)))
			if sequence > 0:
				game._net_report_count_out("control", 40)
				game.rpc_id(sender, "_online_lobby_ready_ack", sequence, ready, true, game.dedicated_room_code)
			game._sync_dedicated_lobby_state()
		return
	game.net_player_ready = ready


func apply_online_lobby_ready_ack(sequence: int, confirmed_ready: bool, accepted: bool, room_code: String = "") -> void:
	game._net_report_count_in("control", 40)
	game._net_report_event("online_lobby_ready_ack_in", "seq=%d confirmed=%s accepted=%s current=%d" % [sequence, str(confirmed_ready), str(accepted), game.online_ready_request_seq])
	if sequence <= 0 or sequence < game.online_ready_confirmed_seq:
		return
	if game.online_ready_request_seq > 0 and sequence != game.online_ready_request_seq:
		return
	game.online_ready_confirmed_seq = sequence
	game.online_lobby_ready_pending = false
	game.online_ready_pending_started_ms = 0
	if room_code != "":
		game.online_room_code = room_code
	if accepted:
		game.local_player_ready = confirmed_ready
		game.online_local_ready_confirmed = confirmed_ready
		game.online_lobby_server_confirmed_ready = confirmed_ready
		game.online_status = "PRONTO CONFIRMADO" if confirmed_ready else "PRONTO REMOVIDO"
	else:
		game.local_player_ready = game.online_local_ready_confirmed
		game.online_status = "HOST RECUSOU CONFIRMACAO"


func apply_online_start_ack(sequence: int, accepted: bool, reason: String = "") -> void:
	game._net_report_count_in("control", 32)
	game._net_report_event("online_start_ack_in", "seq=%d accepted=%s reason=%s current=%d" % [sequence, str(accepted), reason, game.online_start_request_seq])
	if sequence <= 0 or sequence < game.online_start_confirmed_seq:
		return
	if game.online_start_request_seq > 0 and sequence != game.online_start_request_seq:
		return
	game.online_start_confirmed_seq = sequence
	game.online_status = "INICIO CONFIRMADO" if accepted else "AGUARDANDO JOGADORES PRONTOS"


func apply_online_lobby_state(room_code: String, connected: int, ready: int) -> void:
	game._net_report_count_in("control", 64)
	game._net_report_event("online_lobby_state_in", "room=%s connected=%d ready=%d" % [room_code, connected, ready])
	game.online_room_code = room_code
	game.online_lobby_connected_count = connected
	game.online_lobby_ready_count = ready
	game.net_player_ready = ready >= 1
	game.net_player_name = "%d/%d jogadores" % [connected, game.ONLINE_MAX_PLAYERS]
	game.online_lobby_owner_ready = game.online_room_owner and ready > 0
	game.online_lobby_client_ready = (not game.online_room_owner and ready > 0) or (game.online_room_owner and ready > 0)
	if not game.online_room_owner:
		game.online_local_ready_confirmed = game.local_player_ready and ready > 0
		if game.online_local_ready_confirmed:
			game.online_lobby_ready_pending = false
			game.online_ready_pending_started_ms = 0


func apply_online_lobby_roster(roster: Array) -> void:
	game._net_report_count_in("control", 96 + roster.size() * 48)
	game.online_lobby_roster = []
	var connected: int = 0
	var active_players: int = 0
	var spectators: int = 0
	var ready_clients: int = 0
	game.online_lobby_owner_ready = false
	game.online_lobby_client_ready = false
	var local_peer: int = game._mp_unique_id()
	var local_nick: String = game.player_nickname.strip_edges().to_lower()
	var local_roster_ready_seen: bool = false
	var local_roster_ready: bool = false
	for entry in roster:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = Dictionary(entry)
		var peer_id: int = int(item.get("peer_id", item.get("id", 0)))
		var entry_name: String = String(item.get("name", "Player %d" % peer_id))
		var spectator: bool = bool(item.get("spectator", false))
		var item_ready: bool = bool(item.get("ready", false))
		var is_owner_entry: bool = bool(item.get("owner", false))
		var player_slot: int = int(item.get("slot", 0))
		game.online_lobby_roster.append({
			"peer_id": peer_id,
			"name": entry_name,
			"owner": is_owner_entry,
			"slot": player_slot,
			"ready": item_ready,
			"spectator": spectator
		})
		if not game.online_room_owner and not is_owner_entry:
			var matches_local_peer: bool = local_peer != 0 and peer_id == local_peer
			var matches_local_name: bool = local_nick != "" and entry_name.strip_edges().to_lower() == local_nick
			if matches_local_peer or matches_local_name:
				local_roster_ready_seen = true
				local_roster_ready = item_ready or spectator
		connected += 1
		if spectator:
			spectators += 1
		else:
			active_players += 1
		if item_ready and not is_owner_entry and not spectator:
			ready_clients += 1
		if is_owner_entry:
			game.online_lobby_owner_ready = item_ready
		elif not spectator:
			game.online_lobby_client_ready = game.online_lobby_client_ready or item_ready
	game.online_lobby_connected_count = connected
	game.online_lobby_active_player_count = active_players
	game.online_lobby_spectator_count = spectators
	game.online_lobby_ready_count = ready_clients
	if local_roster_ready_seen and local_roster_ready == game.local_player_ready:
		game.online_lobby_ready_pending = false
		game.online_local_ready_confirmed = local_roster_ready
		game.online_ready_pending_started_ms = 0
	game.net_player_name = "%d jogadores / %d espectador%s" % [active_players, spectators, "" if spectators == 1 else "es"]
	game._apply_multiplayer_character_from_roster(game.online_lobby_roster)


func apply_online_lobby_state_v2(room_code: String, connected: int, ready: int, local_ready_confirmed: bool, remote_client_ready = null) -> void:
	game._net_report_count_in("control", 72)
	var confirmed_ready: bool = bool(local_ready_confirmed)
	if typeof(remote_client_ready) == TYPE_BOOL:
		if game.online_room_owner:
			game.online_lobby_client_ready = bool(remote_client_ready)
		else:
			confirmed_ready = bool(remote_client_ready)
	game._net_report_event("online_lobby_state_v2_in", "room=%s connected=%d ready=%d local_confirmed=%s remote_client=%s" % [room_code, connected, ready, str(confirmed_ready), str(remote_client_ready)])
	game.online_room_code = room_code
	game.online_lobby_connected_count = connected
	game.online_lobby_ready_count = ready
	game.online_lobby_server_confirmed_ready = confirmed_ready
	if not game.online_room_owner:
		if game.online_lobby_ready_pending:
			if confirmed_ready == game.local_player_ready:
				game.local_player_ready = confirmed_ready
				game.online_lobby_ready_pending = false
				game.online_ready_pending_started_ms = 0
				game.online_local_ready_confirmed = confirmed_ready
		else:
			game.local_player_ready = confirmed_ready
			game.online_lobby_ready_pending = false
			game.online_ready_pending_started_ms = 0
			game.online_local_ready_confirmed = confirmed_ready
	game.net_player_ready = ready >= 1
	game.online_lobby_owner_ready = game.online_room_owner and ready > 0
	game.online_lobby_client_ready = game.online_lobby_client_ready or (not game.online_room_owner and ready > 0) or (game.online_room_owner and ready > 0)
	game.net_player_name = "%d/%d jogadores" % [connected, game.ONLINE_MAX_PLAYERS]


func apply_online_lobby_state_v3(room_code: String, connected: int, active_players: int, spectators: int, ready: int, local_ready_confirmed: bool, remote_client_ready = null, local_spectator_confirmed: bool = false) -> void:
	game._net_report_count_in("control", 88)
	game.online_room_code = room_code
	game.online_lobby_connected_count = connected
	game.online_lobby_active_player_count = maxi(0, active_players)
	game.online_lobby_spectator_count = maxi(0, spectators)
	game.online_lobby_ready_count = ready
	var confirmed_spectator: bool = bool(local_spectator_confirmed)
	var confirmed_ready: bool = bool(local_ready_confirmed)
	if not game.online_room_owner:
		if game.online_spectator_request_pending:
			if confirmed_spectator == game.online_local_spectator:
				game.online_spectator_request_pending = false
				game.online_local_spectator_confirmed = confirmed_spectator
		else:
			game.online_local_spectator = confirmed_spectator
			game.online_local_spectator_confirmed = confirmed_spectator
		if game.online_local_spectator:
			game.local_player_ready = true
			game.online_lobby_ready_pending = false
			game.online_ready_pending_started_ms = 0
			game.online_local_ready_confirmed = true
		elif game.online_lobby_ready_pending:
			if confirmed_ready == game.local_player_ready:
				game.online_lobby_ready_pending = false
				game.online_ready_pending_started_ms = 0
				game.online_local_ready_confirmed = confirmed_ready
			elif game.local_player_ready and typeof(remote_client_ready) == TYPE_BOOL and bool(remote_client_ready) and ready > 0:
				game.online_lobby_ready_pending = false
				game.online_ready_pending_started_ms = 0
				game.online_local_ready_confirmed = true
		else:
			game.local_player_ready = confirmed_ready
			game.online_local_ready_confirmed = confirmed_ready
	game.online_lobby_server_confirmed_ready = confirmed_ready
	if typeof(remote_client_ready) == TYPE_BOOL:
		game.online_lobby_client_ready = bool(remote_client_ready)
	else:
		game.online_lobby_client_ready = game._online_client_ready()
	game.net_player_ready = game.online_lobby_ready_count >= maxi(0, game.online_lobby_active_player_count - 1)
	game.net_player_name = "%d jogadores / %d espectador%s" % [game.online_lobby_active_player_count, game.online_lobby_spectator_count, "" if game.online_lobby_spectator_count == 1 else "es"]
