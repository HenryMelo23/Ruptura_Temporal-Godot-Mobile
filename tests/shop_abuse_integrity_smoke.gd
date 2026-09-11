extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("SHOP_ABUSE_INTEGRITY_SMOKE_FAIL " + message)
	quit(1)


func _force_game_mode() -> void:
	game.mode = "game"
	game.previous_mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0


func _run() -> void:
	game._start_game()
	game.score = 3200
	game.score_total = 3200
	game.card_cost = 500
	game.time_alive = 100.0
	_force_game_mode()
	game._open_shop(false)
	_check(game.shop_recent_manual_open_count == 1, "first manual open not tracked")
	game._finish_shop()
	_force_game_mode()
	game.time_alive += 3.0
	game._open_shop(false)
	_check(game.shop_recent_manual_open_count == 2, "second rapid manual open not tracked")
	game._finish_shop()
	_force_game_mode()
	var score_before_penalty: int = game.score
	game.time_alive += 3.0
	game._open_shop(false)
	_check(game.score < score_before_penalty, "rapid shop reopen did not charge penalty")
	_check(game.shop_abuse_penalty_count >= 1, "rapid shop penalty was not counted")
	game._finish_shop()

	game.shop_recent_manual_open_count = 0
	game.shop_last_manual_open_time = -999.0
	game.shop_abuse_penalty_count = 0
	game.score = 2600
	game.card_cost = 600
	_force_game_mode()
	game._open_shop(false)
	game.shop_purchases_this_visit = 1
	game._finish_shop()
	_force_game_mode()
	var score_before_reroll_penalty: int = game.score
	game.time_alive += 8.0
	game._open_shop(false)
	_check(game.score < score_before_reroll_penalty, "post-purchase reopen did not charge reroll penalty")
	game._finish_shop()

	game.shop_recent_manual_open_count = 2
	game.shop_last_manual_open_time = game.time_alive - 3.0
	game.shop_abuse_penalty_count = 0
	game.score = 1800
	game.card_cost = 500
	_force_game_mode()
	game._try_open_manual_shop()
	_check(game.mode == "game", "manual reopen warning should not open shop on first tap")
	_check(game._manual_shop_reopen_warning_active(), "manual reopen warning was not armed")
	var score_before_confirm: int = game.score
	game._try_open_manual_shop()
	_check(game.mode == "shop_opening", "second quick tap did not start shop opening")
	_check(game.score < score_before_confirm, "second quick tap did not apply shop penalty")
	game._update_shop_opening(game.SHOP_OPENING_ANIM_TIME + 0.01)
	_check(game.mode == "shop", "confirmed manual reopen did not finish in shop")

	var payload: Dictionary = game._build_run_report_payload("Smoke")
	var integrity: Dictionary = payload.get("integrity", {})
	var signature := String(integrity.get("signature", ""))
	_check(int(payload.get("version_code", 0)) == game.GAME_VERSION_CODE, "payload version code missing")
	_check(int(integrity.get("version", 0)) == game.RUN_REPORT_INTEGRITY_VERSION, "integrity version missing")
	_check(signature.length() == 64 and signature.is_valid_hex_number(false), "signature is not a sha256 hex")
	_check(signature == game._run_report_signature(payload), "signature is not deterministic")
	print("SHOP_ABUSE_INTEGRITY_SMOKE_OK penalties=true warning=true integrity=true")
	quit(0)
