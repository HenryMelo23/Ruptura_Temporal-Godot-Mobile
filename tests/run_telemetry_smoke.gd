extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("RUN_TELEMETRY_SMOKE_FAIL " + message)
	quit(1)


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
	game.player_nickname = "TelemetryQA"
	game.player_profile_id = "telemetry-qa"
	game.player_pos = Vector2(800, 450)
	game._update_run_telemetry(0.6)
	game._damage_player(35, game.ENEMY_STALKER)
	var payload: Dictionary = game._build_run_report_payload("Smoke")
	_check(int(payload.get("damage_taken_total", 0)) > 0, "damage taken was not recorded")
	var threats: Array = payload.get("damage_taken_detail", [])
	_check(threats.size() == 1, "damage source aggregation is missing")
	_check(String(threats[0].get("name", "")) == "Espreitador", "enemy report name is incorrect")
	_check(String(threats[0].get("icon", "")) == "espreitador1.png", "enemy sprite path is incorrect")
	var events: Array = payload.get("damage_events", [])
	_check(events.size() == 1, "damage point was not recorded")
	_check(is_equal_approx(float(events[0].get("x", 0.0)), 0.5), "damage x coordinate is not normalized")
	_check(is_equal_approx(float(events[0].get("y", 0.0)), 0.5), "damage y coordinate is not normalized")
	var heatmap: Dictionary = payload.get("position_heatmap", {})
	_check(int(heatmap.get("columns", 0)) == 16 and int(heatmap.get("rows", 0)) == 9, "heatmap grid size is incorrect")
	_check(Array(heatmap.get("cells", [])).size() == 1, "position sample was not aggregated")
	_check(int(payload.get("ended_unix", 0)) > 0 and String(payload.get("date", "")) != "", "run date and time are missing")
	print("RUN_TELEMETRY_SMOKE_OK heatmap=true damage_points=true threats=true datetime=true")
	quit(0)
