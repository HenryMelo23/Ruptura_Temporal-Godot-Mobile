extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		return
	printerr("SPECTER_UPGRADE_SCREEN_SMOKE_FAIL " + message)
	_cleanup(1)


func _cleanup(code := 0) -> void:
	if game != null:
		game.mode = "menu"
		game.enemies.clear()
		game.enemy_bullets.clear()
		game.visible = false
		game.set_process(false)
		game.set_physics_process(false)
		game._cleanup_runtime_resources()
		root.remove_child(game)
		game.free()
		game = null
	quit(code)


func _run() -> void:
	game.is_multiplayer = false
	game.dedicated_server_mode = false
	game.selected_aura = 0
	game.unlocked_spectrum_ids["racional"] = true
	game._start_game()
	game.mode = "game"
	game.unlocked_spectrum_ids["racional"] = true
	game.specter_levels["racional"] = 1
	game.selected_aura = 0
	game.spectral_coins = 5
	game.spectral_coins_collected = 5
	game.persistent_spectral_coins = 5
	game._rt_adopt_current_state("specter_upgrade_screen_smoke")

	game._open_specter_upgrade("game_over")
	_check(game.mode == "specter_upgrade", "screen did not open")
	_check(game.specter_upgrade_previous_mode == "game_over", "previous mode was not preserved")
	_check(game._specter_can_upgrade(), "upgrade should be available with two spectral coins")
	var effect_lines: Array = game._specter_upgrade_effect_lines()
	_check(effect_lines.size() >= 2, "upgrade effect lines were not populated")
	_check(String(effect_lines[0]).find("Assinatura") >= 0 and String(effect_lines[1]).find("Dilatacao") >= 0, "upgrade text did not expose the real Racional level change")

	game._confirm_specter_upgrade()
	_check(int(game.aura_state.get("level", 0)) == 2, "confirm did not raise specter to level 2")
	_check(game.spectral_coins == 0, "confirm did not spend the level 2 cost")
	_check(game.spectral_coins_spent == 5, "spent counter was not updated")
	_check(not game._specter_can_upgrade(), "upgrade stayed available without coins")
	_check(game._content_is_unread("specter", "racional") and game._content_is_unread("catalog_spectrum", "racional"), "specter upgrade did not queue stable unread entries")
	var snapshot: Dictionary = game._card_unlock_snapshot()
	_check(Array(snapshot.get("content_unread", [])).has("specter:racional"), "unread entry was not included in saved progress")
	game.content_unread_ids.clear()
	game._apply_player_progress_snapshot(snapshot, false, false)
	_check(game._content_is_unread("specter", "racional") and game._content_is_unread("catalog_spectrum", "racional"), "saved unread entries were not restored")
	var legacy_snapshot := snapshot.duplicate(true)
	legacy_snapshot.erase("content_unread")
	game._apply_player_progress_snapshot(legacy_snapshot, false, true)
	_check(game._content_is_unread("specter", "racional"), "legacy snapshot erased local unread entries")
	game._mark_content_seen("specter", "racional")
	_check(not game._content_is_unread("specter", "racional") and game._content_is_unread("catalog_spectrum", "racional"), "viewing one entry cleared unrelated unread content")

	game._return_from_specter_upgrade()
	_check(game.mode == "game_over", "screen did not return to the previous mode")

	game.mode = "shop"
	game.spectral_coins = 3
	game._open_specter_upgrade("shop")
	_check(game.mode == "shop", "shop should not open specter screen during a run")

	print("SPECTER_UPGRADE_SCREEN_SMOKE_OK open=true confirm=true return=true")
	_cleanup(0)
