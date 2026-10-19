extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("ANCORADA_MULTIPLAYER_CONTRACT_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	game.mode = "game"
	game.manifestation_key = "ancorada"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	var ancorada_index := -1
	for index in range(game.MANIFESTATIONS.size()):
		if String(game.MANIFESTATIONS[index].get("key", "")) == "ancorada":
			ancorada_index = index
			break
	_check(ancorada_index >= 0, "manifestation index missing")

	var remote_peer := 23
	game.net_players_by_peer[remote_peer] = {"pos": Vector2(420, 360), "render_pos": Vector2(420, 360), "hp": 100.0, "eliminated": false}
	var visual := {
		"source": remote_peer,
		"action": game.NET_ABILITY_SECONDARY,
		"manifestation": ancorada_index,
		"center": Vector2(420, 360),
		"origin": Vector2(420, 360),
		"life": game.SECONDARY_ANCORADA_DURATION,
		"max": game.SECONDARY_ANCORADA_DURATION,
		"latency": 0.0,
		"seed": 77,
	}
	game._initialize_network_ability_replica(visual)
	_check(String(visual.get("kind", "")) == "ancorada", "replica kind mismatch")
	_check(Array(visual.get("trail", [])).size() == 1, "replica trail must initialize once")
	game.net_players_by_peer[remote_peer]["render_pos"] = Vector2(720, 360)
	game._update_network_ability_replica(visual, 0.1)
	_check(Vector2(visual.get("center", Vector2.ZERO)) == Vector2(720, 360), "remote ultimate must follow its owning peer")
	_check(float(visual.get("momentum", 0.0)) > 0.5, "remote movement must reproduce marching momentum")
	_check(Array(visual.get("trail", [])).size() == 2, "remote trail must append one bounded sample")
	_check(Array(visual.get("drops", [])).size() >= 2, "remote ultimate must reproduce falling anchor VFX")

	var local_hp_before := float(game.player_hp)
	game._update_network_ability_replica(visual, game.ANCORADA_ULTIMATE_FALL_TIME + 0.02)
	_check(is_equal_approx(float(game.player_hp), local_hp_before), "visual replica must never apply gameplay damage")
	_check(not Array(visual.get("impacts", [])).is_empty(), "remote anchor VFX must produce impact feedback")
	_check(Array(visual.get("trail", [])).size() <= game.ANCORADA_ULTIMATE_TRAIL_POINTS, "remote trail must remain bounded")

	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	await process_frame
	print("ANCORADA_MULTIPLAYER_CONTRACT_OK owner_follow=true visual_only=true bounded=true")
	quit(0)
