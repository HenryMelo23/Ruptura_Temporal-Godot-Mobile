extends SceneTree

var game: Node
var request_done := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.player_nickname = "CodexSmoke"
	game._reset_run_report_stats()
	game.run_report_request.request_completed.connect(func(_result, _code, _headers, _body):
		request_done = true
	)
	game.current_phase = 1
	game.time_alive = 12.0
	game.selected_manifestation = 0
	game.selected_aura = 0
	game.enemies_killed = 1
	game.run_points_earned = 10
	game.run_points_spent = 0
	game.run_report_webhook_url = ""

	var payload: Dictionary = game._build_run_report_payload("Smoke")
	game._send_run_report_to_discord(payload)
	assert(game.run_report_webhook_url == game.DEFAULT_DISCORD_WEBHOOK_URL)
	assert(game.run_report_status != "Webhook nao configurado")

	var deadline := Time.get_ticks_msec() + 12000
	while not request_done and Time.get_ticks_msec() < deadline:
		await process_frame

	assert(request_done)
	print("RUN_REPORT_DEFAULT_WEBHOOK_SMOKE_SENT status=%s" % game.run_report_status)
	quit(0)
