extends SceneTree

var host: Node
var client: Node


func _initialize() -> void:
	host = load("res://scenes/Main.tscn").instantiate()
	client = load("res://scenes/Main.tscn").instantiate()
	root.add_child(host)
	root.add_child(client)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("BOSS4_MULTIPLAYER_SYNC_FAIL " + message)
	quit(1)


func _setup_peer(game: Node, host_mode: bool) -> void:
	game._start_game()
	game.set_process(false)
	game._advance_to_phase(4)
	game.mode = "game"
	game.is_multiplayer = true
	game.online_connected = false
	game.is_host = host_mode
	game.online_room_owner = host_mode
	game.online_lobby_connected_count = 3
	game.current_phase = 4
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 4200.0
	game.boss_hp = 820.0
	game.boss_pos = Vector2(1120.0, 430.0)
	game.player_hp = 2000.0
	game.player_hp_max = 2000.0
	game.player_pos = Vector2(560.0, 450.0)
	game.boss4_controller.reset()


func _run() -> void:
	_setup_peer(host, true)
	_setup_peer(client, false)
	host.net_players_by_peer.clear()
	_check(host._combat_targets().size() == 1, "solo target inventory was not one")
	host.net_players_by_peer[2] = {"has_snapshot": true, "dead": false, "hp": 1000.0, "hp_max": 1000.0, "pos": Vector2(700.0, 420.0)}
	_check(host._combat_targets().size() == 2, "duo target inventory was not two")
	host.net_players_by_peer[3] = {"has_snapshot": true, "dead": false, "hp": 1000.0, "hp_max": 1000.0, "pos": Vector2(760.0, 500.0)}
	_check(host._combat_targets().size() == 3, "trio target inventory was not three")

	host.boss4_stage = 4
	host.boss4_ai_state["state"] = "windup"
	host.boss4_ai_state["action"] = "gravity"
	host.boss4_ai_state["action_elapsed"] = 0.31
	host.boss4_last_attack = "gravity"
	host._start_boss4_ultimate()
	var packet: Dictionary = host._pack_net_boss_visuals()
	_check(packet.has("boss4_controller"), "host packet omitted controller state")
	_check(Array(packet.get("boss4_rupture_anchors", [])).size() == 3, "host packet omitted exact anchor set")
	client._apply_remote_boss_visual_snapshot(packet)
	_check(client.boss4_stage == 4, "client did not apply stage")
	_check(client.boss4_ultimate_active, "client did not apply ultimate state")
	_check(client.boss4_rupture_anchors.size() == 3, "client did not receive three anchors")
	_check(String(client.boss4_ai_state.get("state", "")) == "windup", "client did not apply authoritative FSM state")
	_check(String(client.boss4_ai_state.get("action", "")) == "gravity", "client did not apply authoritative action")
	_check(client.boss4_last_attack == "gravity", "client did not apply last attack")

	var first_anchor: Dictionary = host.boss4_rupture_anchors[0]
	host._damage_boss4_anchor_at(Vector2(first_anchor["pos"]), 99999.0, 8.0)
	var damaged_packet: Dictionary = host._pack_net_boss_visuals()
	client._apply_remote_boss_visual_snapshot(damaged_packet)
	_check(client.boss4_ultimate_destroyed == 1, "client anchor counter diverged")
	_check(bool(client.boss4_rupture_anchors[0].get("destroyed", false)), "client anchor destruction diverged")

	print("BOSS4_MULTIPLAYER_SYNC_OK authority=true replica=true solo_duo_trio=true fsm=true anchors=true")
	_cleanup_game(client)
	_cleanup_game(host)
	client = null
	host = null
	for frame in range(4):
		await process_frame
	quit(0)


func _cleanup_game(game: Node) -> void:
	if game == null or not is_instance_valid(game):
		return
	game._cleanup_runtime_resources()
	if game.music_player != null:
		game.music_player.stop()
		game.music_player.stream = null
	if game.rain_audio_player != null:
		game.rain_audio_player.stop()
		game.rain_audio_player.stream = null
	for player in game.sfx_players:
		if player != null:
			player.stop()
			player.stream = null
	game.textures.clear()
	game.audio_streams.clear()
	root.remove_child(game)
	game.free()
