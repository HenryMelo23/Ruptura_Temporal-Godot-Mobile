extends SceneTree

# Run with an isolated XDG_DATA_HOME: this exercises real local persistence.
var game: Node
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("BACKUP_RECONCILIATION_FAIL " + message)


func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player_identity_auth_token = "reconciliation_test_token"
	game.player_identity_recovery_code = "RECOVERYTEST001"
	game._save_player_profile()
	game.player_identity_auth_token = ""
	game.player_identity_recovery_code = ""
	game._load_player_profile()
	_check(game.player_identity_auth_token == "reconciliation_test_token", "profile auth lost by save owner")
	_check(game.player_identity_recovery_code == "RECOVERYTEST001", "recovery identity lost by save owner")

	game.card_unlock_progress["enemy_kills"] = 123.0
	game.player_progress_pending_events = [{"id": "fixture", "type": "unlock_progress"}]
	game.player_progress_event_sequence = 7
	game._save_card_unlocks()
	game.card_unlock_progress.clear()
	game.player_progress_pending_events.clear()
	game._load_card_unlocks()
	_check(game.player_progress_cache_trusted, "save owner failed signed-cache validation")
	_check(float(game.card_unlock_progress.get("enemy_kills", 0.0)) == 123.0, "cache progress lost")
	_check(game.player_progress_pending_events.size() == 1 and game.player_progress_event_sequence == 7, "offline queue lost")
	var file := FileAccess.open(game.PLAYER_PROGRESS_CACHE_PATH, FileAccess.WRITE)
	file.store_string('{"snapshot":{"progress":{"enemy_kills":999999}}}')
	file.close()
	game._load_card_unlocks()
	_check(not game.player_progress_cache_trusted, "unsigned cache accepted by owner")
	_check(float(game.card_unlock_progress.get("enemy_kills", 0.0)) == 0.0, "unsigned cache elevated progress")

	game._start_game()
	game.mode = "shop"
	game.shop_paid_rerolls_this_visit = 3
	game.cinzas_card_bonuses = {"Speed Boost": 2}
	game.manifest_evolution_fragment_claim_count = 2
	game._save_interrupted_run(true)
	var saved: Dictionary = game._load_interrupted_run_snapshot()
	_check(int(saved.get("schema", 0)) == 1, "snapshot schema changed")
	game.shop_paid_rerolls_this_visit = 0
	game.cinzas_card_bonuses.clear()
	game.manifest_evolution_fragment_claim_count = 0
	_check(game._resume_interrupted_run(), "resume rejected backup fields")
	_check(game.shop_paid_rerolls_this_visit == 3, "resume lost paid reroll count")
	_check(game.cinzas_card_bonuses.get("Speed Boost", 0) == 2, "resume lost burn attributes")
	_check(game.manifest_evolution_fragment_claim_count == 2, "resume lost evolution claims")
	game._capture_retry_run_snapshot()
	game.shop_paid_rerolls_this_visit = 0
	game.cinzas_card_bonuses.clear()
	game.is_dead = true
	game.player_hp = 0
	game.mode = "game_over"
	_check(game._use_run_retry(), "retry failed after reconciliation")
	_check(game.shop_paid_rerolls_this_visit == 3 and game.cinzas_card_bonuses.get("Speed Boost", 0) == 2, "retry lost backup fields")

	# Long-run pressure must be included in the previous effective cap, not
	# applied again after taking its 70% at the new phase entry.
	game._start_game()
	game.time_alive = 45.0 * 60.0
	game.enemies_killed = 5000
	game.phase1_limit_break_kills_start = 0
	_check(game._long_run_enemy_limit_bonus() > 0, "long-run baseline missing")
	for phase in [2, 3, 4, 6, 7]:
		var previous_cap: int = game._enemy_limit()
		game._advance_to_phase(phase)
		_check(game._enemy_limit() == maxi(1, int(floor(previous_cap * 0.70))), "density carry double counted long-run bonus at phase %d" % phase)
	game.mode = "manifest_evolution_waiting"
	_check(game._interrupted_run_saved_mode() == "manifest_evolution_waiting", "evolution waiting mode missing from save owner")
	game._clear_interrupted_run_save()
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	if not failed:
		print("BACKUP_RECONCILIATION_OK identity cache tamper queue resume retry evolution density long_run")
	quit(1 if failed else 0)
