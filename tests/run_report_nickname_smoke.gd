extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	assert(game._sanitize_player_nickname("  @Geo QA!!\n") == "Geo QA")
	assert(game._is_allowed_discord_webhook("https://discord.com/api/webhooks/1/token"))
	assert(not game._is_allowed_discord_webhook("https://example.com/hook"))
	game.gameplay_cheat_text = "QA231021"
	assert(game._try_unlock_retornante_cheat())
	assert(game.qa_data_unlocked)
	game.run_report_webhook_url = ""
	game.webhook_edit.text = "https://discord.com/api/webhooks/123456789/test_token"
	game._save_webhook_from_input()
	assert(game.run_report_webhook_url.contains("/api/webhooks/123456789/"))
	game._clear_run_report_webhook()
	assert(game.run_report_webhook_url == game.DEFAULT_DISCORD_WEBHOOK_URL)

	game.player_nickname = "GeoQA"
	game.player_profile_id = "qa-profile-1"
	game.selected_manifestation = 0
	game.selected_aura = 0
	game._start_game()
	game.player_nickname = "GeoQA"
	game.player_profile_id = "qa-profile-1"
	game.player_damage = 48.0
	game.run_start_damage = 32.0
	game._track_enemy_damage({"type": game.ENEMY_STALKER}, 120.0)
	game._track_enemy_damage({"type": game.ENEMY_STALKER}, 30.0)
	game.current_phase = 2
	game.time_alive = 80.0
	game._mark_boss_reached(2)
	game.time_alive = 95.0
	game._track_boss_damage(444.0)
	game._finish_boss_timer(2)
	game.cards_bought["Petro"] = 2
	game.cards_bought["Disparo crescente"] = 1
	game.enemies_killed = 7
	game.run_points_earned = 900
	game.run_points_spent = 500
	var payload: Dictionary = game._build_run_report_payload("Derrota")
	assert(payload["player"] == "GeoQA")
	assert(String(payload["profile_id"]) != "")
	assert(payload.has("player_stats"))
	assert(payload.has("enemy_scaling"))
	assert(payload.has("network"))
	assert(payload.has("settings"))
	assert(int(payload["leaderboard_score"]) > 0)
	assert(int(payload["kills"]) == 7)
	assert(String(payload["enemy_damage_breakdown"]).contains("Espreitador: 150"))
	assert(String(payload["boss_report"]).contains("Boss 2: tempo 00:15 | dano 444"))
	assert(String(payload["cards"]).contains("Petro x2"))
	assert(Array(payload["cards_detail"]).size() >= 2)
	assert(int(payload["cards_total"]) == 3)
	print("RUN_REPORT_NICKNAME_SMOKE_OK nick=true report=true discord_guard=true qa_gate=true")
	quit()
