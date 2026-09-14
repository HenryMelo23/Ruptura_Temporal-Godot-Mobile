extends "res://tests/multiplayer_lobby_integration_smoke.gd"

var opened_ms := 0
var requested_exit := false
var saw_waiting := false
var purchase_started := false


func _result_path(result_role: String) -> String:
	return "res://.codex/shop_wire_%s.txt" % result_role


func _run() -> void:
	while Time.get_ticks_msec() - started_ms < TIMEOUT_MS:
		await process_frame
		if role != "server" and _result_exists(role) and _result_exists("server"):
			print("SHOP_WIRE_OK role=%s score=%d consensus=true" % [role, game.score])
			await _finish()
			return
		if role == "server":
			if _result_exists("host") and _result_exists("client"):
				_write_result("server")
				await _finish()
				return
			continue
		if not game.online_connected or game.online_lobby_connected_count != 2:
			continue
		if opened_ms == 0:
			game.run_tutorial_enabled = false
			game._open_shop(false)
			game.shop_cards = [game.CARDS[2].duplicate(true), game.CARDS[3].duplicate(true), game.CARDS[9].duplicate(true)]
			game.score = 5000
			game.card_cost = 500
			opened_ms = Time.get_ticks_msec()
		if role == "host" and not purchase_started:
			purchase_started = true
			game._buy_selected_card()
		if not requested_exit and not game._shop_purchase_animating():
			if role == "host" or Time.get_ticks_msec() - opened_ms >= 2200:
				requested_exit = true
				game._request_shop_exit_or_finish()
		if game.mode == "shop_mp_waiting":
			saw_waiting = true
		if game.mode == "shop_return":
			if role == "host" and (game.score != 4500 or not saw_waiting):
				_fail("host purchase or waiting contract failed")
				return
			if role == "client" and game.score != 5000:
				_fail("host spending changed client balance")
				return
			_write_result(role)
			if _result_exists("server"):
				print("SHOP_WIRE_OK role=%s score=%d consensus=true" % [role, game.score])
				await _finish()
				return
	_fail("shop network timeout role=%s mode=%s ready=%d/%d" % [role, game.mode, game.shop_mp_ready_count, game.shop_mp_expected_count])
