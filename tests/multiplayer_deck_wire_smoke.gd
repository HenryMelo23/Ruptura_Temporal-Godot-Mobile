extends "res://tests/multiplayer_lobby_integration_smoke.gd"

var stage := 0
var copies := 0
var card: Dictionary


func _run() -> void:
	while Time.get_ticks_msec() - started_ms < TIMEOUT_MS:
		await process_frame
		if role != "server" and stage == 3 and _result_exists("server"):
			print("MULTIPLAYER_DECK_WIRE_OK role=%s purchase=true effects=true consumption=true ownership=true" % role)
			await _finish()
			return
		if role == "server":
			if _result_exists("host") and _result_exists("client"):
				_write_result(role)
				await _finish()
				return
			continue
		if not game.online_connected or game.online_lobby_connected_count != 2:
			continue
		if stage == 0:
			game.set_process(false)
			game.cards_bought.clear()
			game.cinzas_card_bonuses.clear()
			card = game._find_card_by_id("Disparo crescente")
			copies = 2 if role == "host" else 1
			if role == "host":
				game._apply_card(game._find_card_by_id("carta_zero"))
			for i in range(copies):
				game._apply_card(card)
			stage = 1
		var remote_id := 0
		for peer_id in game.net_decks_by_peer:
			remote_id = int(peer_id)
		if remote_id == 0:
			continue
		game.deck_view_peer_id = remote_id
		var remote: Dictionary = game.net_decks_by_peer[remote_id]
		var expected := 1 if role == "host" else 2
		if stage == 1 and int(remote.counts.get("Disparo crescente", 0)) == expected:
			var line: String = game._deck_effect_text(card)
			var expected_percent := "15.0%" if role == "host" else "34.2%"
			if not line.contains(expected_percent):
				_fail("remote deck used local effects: %s expected=%s" % [line, expected_percent])
				return
			if game._card_count(card) != copies:
				_fail("viewing remote deck mutated local counts")
				return
			_write_result(role + "_purchased")
			stage = 4
		if stage == 4 and _result_exists("host_purchased") and _result_exists("client_purchased"):
			# Consumption must replace the remote snapshot, including a zero count.
			game._consume_card_count("Disparo crescente", 1)
			stage = 2
		if stage == 2 and int(remote.counts.get("Disparo crescente", 0)) == expected - 1:
			if game._card_count(card) != copies - 1:
				_fail("remote consumption changed local deck")
				return
			_write_result(role)
			stage = 3
	_fail("deck sync timeout role=%s stage=%d" % [role, stage])
