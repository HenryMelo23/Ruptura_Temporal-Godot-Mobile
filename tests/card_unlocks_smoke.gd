extends SceneTree

var game: Node
var unlock_save_existed: bool = false
var unlock_save_text: String = ""
var progress_cache_existed: bool = false
var progress_cache_bytes: PackedByteArray = PackedByteArray()


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("CARD_UNLOCKS_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_backup_unlock_save()
	_backup_progress_cache()
	game.unlocked_card_ids.clear()
	game.card_unlock_progress.clear()
	game.unlock_notifications.clear()
	game.vol_master = 1.0
	game.vol_sfx = 1.0
	game.vol_shots = 1.0
	game._ensure_card_unlock_defaults()
	game._ensure_card_unlock_rule_metric_index()
	game._rebuild_card_unlock_next_thresholds()
	_check(not Array(game.card_unlock_rules_by_metric.get("survive_seconds", [])).is_empty(), "survival unlock rules were not indexed")
	_check(not Array(game.card_unlock_rules_by_metric.get("enemy_kills", [])).is_empty(), "enemy-kill unlock rules were not indexed")
	game.time_alive = game.CARD_UNLOCK_RUNTIME_SAMPLE_INTERVAL - 0.1
	game._update_card_unlock_runtime(game.CARD_UNLOCK_RUNTIME_SAMPLE_INTERVAL - 0.1)
	_check(not game.card_unlock_progress.has("survive_seconds"), "runtime progress wrote a one-second survival event")
	game.time_alive = game.CARD_UNLOCK_RUNTIME_SAMPLE_INTERVAL
	game._update_card_unlock_runtime(0.1)
	_check(is_equal_approx(float(game.card_unlock_progress.get("survive_seconds", 0.0)), game.CARD_UNLOCK_RUNTIME_SAMPLE_INTERVAL), "runtime progress lost the five-second survival checkpoint")
	game.card_unlock_progress.clear()
	_check(game.audio_streams.has("unlock_notification"), "unlock notification sfx was not registered")
	game.player_progress_pending_events.clear()
	game.player_progress_sync_sent_event_ids.clear()
	for _shot_index in range(1200):
		game._queue_player_progress_unlock_event("shots_fired", 1.0, false)
	_check(game.player_progress_pending_events.size() == 1, "runtime shot progress queue was not compacted")
	var batched_shot_total := 0.0
	for event in game.player_progress_pending_events:
		batched_shot_total += float(event.get("amount", 0.0))
	_check(is_equal_approx(batched_shot_total, 1200.0), "runtime shot batching changed the progress total")
	var last_batch_id := String(game.player_progress_pending_events[-1].get("event_id", ""))
	game.player_progress_sync_sent_event_ids[last_batch_id] = true
	game._queue_player_progress_unlock_event("shots_fired", 1.0, false)
	_check(game.player_progress_pending_events.size() == 2, "runtime mutated a shot batch already in flight")
	game.player_progress_pending_events.clear()
	game.player_progress_sync_sent_event_ids.clear()
	game.player_progress_pending_unlock_index.clear()
	game.player_progress_deferred_unlock_progress.clear()
	game.player_progress_sync_in_flight = true
	game._queue_player_progress_unlock_event("survive_seconds", 45.0, true)
	_check(game.player_progress_pending_events.is_empty(), "runtime appended to the immutable in-flight queue")
	_check(game.player_progress_deferred_unlock_progress.size() == 1, "in-flight progress was not coalesced")
	game.player_progress_sync_in_flight = false
	game._flush_deferred_player_progress_unlocks()
	_check(game.player_progress_deferred_unlock_progress.is_empty(), "coalesced progress remained deferred after sync")
	_check(game.player_progress_pending_events.size() == 1 and is_equal_approx(float(game.player_progress_pending_events[0].get("amount", 0.0)), 45.0), "coalesced progress changed while returning to the durable queue")
	game.player_progress_pending_events.clear()
	game.player_progress_pending_unlock_index.clear()

	var base_card: Dictionary = game._find_card_by_id("Speed Boost")
	var locked_card: Dictionary = game._find_card_by_id("Poison")
	var ashes_card: Dictionary = game._find_card_by_id(game.CARD_CINZAS_ID)
	_check(not base_card.is_empty(), "base card was not registered")
	_check(not locked_card.is_empty(), "locked test card was not registered")
	_check(not ashes_card.is_empty(), "Cinzas card was not registered")
	_check(game._card_unlocked(base_card), "base cards should start unlocked")
	_check(not game._card_unlocked(locked_card), "Poison should start locked")
	_check(not game._card_unlocked(ashes_card), "Cinzas should start locked")
	_check(not game._shop_card_eligible_for_roll(locked_card, {}), "locked cards should not roll in shop")
	_check(not game._card_available_for_reward(locked_card, true, false), "locked cards should not drop as reward")

	game._add_card_unlock_progress("enemy_kills", 29.0)
	game._add_card_unlock_progress("shop_purchases", 5.0)
	game._add_card_unlock_progress("teleports_used", 20.0)
	game._add_card_unlock_progress("abilities_used", 35.0)
	game._add_card_unlock_progress("shots_fired", 220.0)
	game._add_card_unlock_progress("damage_taken_events", 15.0)
	game._set_card_unlock_progress_max("survive_seconds", 119.0)
	var early_unlocks: int = game.unlock_notifications.size()
	_check(early_unlocks == 0, "short first-run activity unlocked items too early")
	_check(not game._card_unlocked(locked_card), "Poison unlocked before its challenge target")
	game._add_card_unlock_progress("enemy_kills", 151.0)
	_check(game._card_unlocked(locked_card), "Poison did not unlock after enemy-kill challenge")
	_check(game.unlock_notifications.size() == 1, "card unlock notification was not queued")
	_check(String(game.unlock_notifications[0].get("title", "")) == "CARTA DESBLOQUEADA", "card unlock title mismatch")
	_check(String(game.unlock_notifications[0].get("challenge", "")).contains("Eliminar 180/180"), "card unlock challenge text mismatch")
	var sfx_was_played: bool = false
	for player in game.sfx_players:
		if player != null and player.stream == game.audio_streams["unlock_notification"]:
			sfx_was_played = true
			break
	_check(sfx_was_played, "unlock notification sfx did not play")

	game._add_card_unlock_progress("shop_purchases", 25.0)
	_check(not game._card_unlocked(ashes_card), "Cinzas unlocked without survival requirement")
	game._set_card_unlock_progress_max("survive_seconds", 900.0)
	_check(game._card_unlocked(ashes_card), "Cinzas did not unlock after purchase challenge")
	game._flush_card_unlocks_if_dirty()
	_check(not game.card_unlocks_dirty, "card unlock save dirty flag did not flush")
	_restore_unlock_save()
	_restore_progress_cache()

	print("CARD_UNLOCKS_SMOKE_OK base_unlocked=true locked_filter=true challenge_unlock=true notification=true save_flush=true shots=1200_batches_1 in_flight=immutable")
	root.remove_child(game)
	game._cleanup_runtime_resources()
	await process_frame
	game.queue_free()
	for i in range(3):
		await process_frame
	quit(0)


func _backup_unlock_save() -> void:
	unlock_save_existed = FileAccess.file_exists(game.CARD_UNLOCK_SAVE_PATH)
	unlock_save_text = ""
	if unlock_save_existed:
		var file := FileAccess.open(game.CARD_UNLOCK_SAVE_PATH, FileAccess.READ)
		if file != null:
			unlock_save_text = file.get_as_text()
			file.close()


func _restore_unlock_save() -> void:
	if unlock_save_existed:
		var file := FileAccess.open(game.CARD_UNLOCK_SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(unlock_save_text)
			file.close()
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.CARD_UNLOCK_SAVE_PATH))


func _backup_progress_cache() -> void:
	progress_cache_existed = FileAccess.file_exists(game.PLAYER_PROGRESS_CACHE_PATH)
	progress_cache_bytes = FileAccess.get_file_as_bytes(game.PLAYER_PROGRESS_CACHE_PATH) if progress_cache_existed else PackedByteArray()


func _restore_progress_cache() -> void:
	game.save_controller._poll_card_unlock_save(true)
	var absolute_path := ProjectSettings.globalize_path(game.PLAYER_PROGRESS_CACHE_PATH)
	if progress_cache_existed:
		var file := FileAccess.open(absolute_path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(progress_cache_bytes)
			file.close()
		return
	DirAccess.remove_absolute(absolute_path)
