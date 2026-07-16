extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.selected_manifestation = 0
	game.selected_aura = 0
	game._start_game()
	game.mode = "game"
	game.manifestation_key = "eletrica"
	game.player_nickname = "EletricaQA"
	game.player_profile_id = "qa-eletrica"
	game.player_pos = Vector2(640, 360)
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.enemies.clear()
	game.enemies.append({
		"type": game.ENEMY_COMMON,
		"uid": 999,
		"pos": game.player_pos + Vector2(40, 0),
		"hp": 100.0,
		"max_hp": 100.0,
		"speed": game.enemy_speed_base,
		"stun": 0.0
	})
	var secondary := {
		"kind": "eletrica",
		"life": 10.0,
		"max": 10.0,
		"tick": 999.0,
		"active_time": 14.9,
		"empty_time": 0.0,
		"health_drain_timer": 0.0,
		"health_drain_carry": 0.0
	}
	game._update_secondary_eletrica(secondary, 0.2)
	assert(game.player_hp == 1000)
	game._update_secondary_eletrica(secondary, 1.0)
	assert(game.player_hp <= 990 and game.player_hp >= 989)
	secondary["active_time"] = game.SECONDARY_ELETRICA_DRAIN_DELAY + game.SECONDARY_ELETRICA_DRAIN_TIER_SECONDS + 0.2
	secondary["health_drain_timer"] = 0.0
	var before_hp := int(game.player_hp)
	game._update_secondary_eletrica(secondary, 1.0)
	assert(before_hp - int(game.player_hp) >= 18)
	game.cards_bought["Petro"] = 1
	game.enemies_killed = 3
	var payload: Dictionary = game._build_run_report_payload("Smoke")
	assert(payload.has("cards_detail"))
	assert(payload.has("leaderboard_score"))
	assert(String(payload["profile_id"]) != "")
	print("ELETRICA_DRAIN_AND_REPORT_SMOKE_OK drain=true report=true")
	quit(0)
