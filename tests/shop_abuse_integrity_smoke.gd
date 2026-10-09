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
	game.shop_auto_enabled = false
	game.shop_tutorial_seen = true
	game.run_tutorial_enabled = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0


func _open_manual_via_button() -> void:
	_force_game_mode()
	game._try_open_manual_shop()
	_check(game.mode == "shop_opening", "manual shop did not start opening")
	game._update_shop_opening(game.SHOP_OPENING_ANIM_TIME + 0.01)
	_check(game.mode == "shop", "manual shop did not finish opening")


func _run() -> void:
	game._start_game()
	game.score = 3200
	game.score_total = 3200
	game.card_cost = 500
	game.time_alive = 100.0

	_open_manual_via_button()
	_check(game.shop_recent_manual_open_count == 1, "first manual open not tracked")
	var score_before_first_close: int = game.score
	game._finish_shop()
	_check(game.score == score_before_first_close, "closing manual shop removed points")
	_check(game._manual_shop_grace_active(), "accidental close grace did not start")
	_check(is_equal_approx(game._manual_shop_cooldown_remaining(), 0.0), "grace should allow immediate reopen")

	_force_game_mode()
	game.time_alive += 2.0
	_open_manual_via_button()
	_check(game.shop_recent_manual_open_count == 2, "second rapid manual open not tracked")
	_check(not game._manual_shop_grace_active(), "grace was not consumed by reopen")
	game._finish_shop()
	_check(not game._manual_shop_grace_active(), "second close should not start another grace")
	_check(game._manual_shop_cooldown_remaining() > 29.8, "second close did not start 30s cooldown")

	_force_game_mode()
	var score_before_blocked: int = game.score
	game.time_alive += 3.0
	game._try_open_manual_shop()
	_check(game.mode == "game", "manual cooldown attempt opened shop early")
	_check(game.score == score_before_blocked, "manual cooldown attempt removed points")
	var remaining_after_spam: float = game._manual_shop_cooldown_remaining()
	game._try_open_manual_shop()
	_check(abs(game._manual_shop_cooldown_remaining() - remaining_after_spam) < 0.01, "blocked attempts reset manual cooldown")

	game.time_alive += remaining_after_spam + 0.1
	_open_manual_via_button()
	game._finish_shop()

	game.score = 2600
	game.card_cost = 600
	game.time_alive = 300.0
	game.shop_manual_cooldown_until = -999.0
	game.shop_manual_grace_until = -999.0
	game.shop_manual_grace_reopen_available = false
	_open_manual_via_button()
	game.shop_purchases_this_visit = 1
	game._finish_shop()
	_force_game_mode()
	var score_before_post_purchase: int = game.score
	game.time_alive += 8.0
	game._try_open_manual_shop()
	_check(game.mode == "game", "post-purchase cooldown attempt opened shop early")
	_check(game.score == score_before_post_purchase, "post-purchase cooldown attempt removed points")

	game.time_alive = 500.0
	game.shop_manual_cooldown_until = -999.0
	game.shop_manual_grace_until = -999.0
	game.shop_manual_grace_reopen_available = false
	_open_manual_via_button()
	game._finish_shop()
	_force_game_mode()
	game.time_alive += 4.9
	_check(game._manual_shop_grace_active(), "grace ended before 4.9s")
	_check(is_equal_approx(game._manual_shop_cooldown_remaining(), 0.0), "grace should not report blocking cooldown")
	game.time_alive += 0.1
	_check(not game._manual_shop_grace_active(), "grace still active at 5.0s boundary")
	_check(game._manual_shop_cooldown_remaining() <= 25.1 and game._manual_shop_cooldown_remaining() >= 24.9, "cooldown did not keep total 30s after grace expiry")
	var score_before_expired_grace_attempt: int = game.score
	game._try_open_manual_shop()
	_check(game.mode == "game", "expired grace attempt opened during cooldown")
	_check(game.score == score_before_expired_grace_attempt, "expired grace attempt removed points")
	game.time_alive += 0.1
	_check(game._manual_shop_cooldown_remaining() <= 24.9, "cooldown boundary at 5.1s ambiguous")

	game.time_alive += game._manual_shop_cooldown_remaining() + 0.1
	_open_manual_via_button()
	var score_before_reroll: int = game.score
	game.shop_rerolls = 0
	game.shop_paid_rerolls_this_visit = 0
	game._reroll_shop()
	_check(game.score < score_before_reroll, "paid reroll no longer charges points")

	var payload: Dictionary = game._build_run_report_payload("Smoke")
	var integrity: Dictionary = payload.get("integrity", {})
	var signature := String(integrity.get("signature", ""))
	_check(int(payload.get("version_code", 0)) == game.GAME_VERSION_CODE, "payload version code missing")
	_check(int(integrity.get("version", 0)) == game.RUN_REPORT_INTEGRITY_VERSION, "integrity version missing")
	_check(signature.length() == 64 and signature.is_valid_hex_number(false), "signature is not a sha256 hex")
	_check(signature == game._run_report_signature(payload), "signature is not deterministic")
	print("SHOP_ABUSE_INTEGRITY_SMOKE_OK penalty_removed=true grace=true cooldown=true integrity=true")
	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	quit(0)
