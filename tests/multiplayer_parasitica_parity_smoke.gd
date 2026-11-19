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
	push_error("MULTIPLAYER_PARASITICA_PARITY_FAIL " + message)
	quit(1)


func _setup(game: Node, authority: bool) -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = true
	game.is_host = authority
	game.online_room_owner = authority
	game.online_connected = false
	game.manifestation_key = "parasitica"
	game.active_character_key = game.CHARACTER_GEOVANA


func _enemy(uid: int) -> Dictionary:
	return {
		"uid": uid,
		"type": host.ENEMY_COMMON,
		"pos": Vector2(720, 360),
		"hp": 500.0,
		"max_hp": 500.0,
		"points": 10,
	}


func _run() -> void:
	await process_frame
	_setup(host, true)
	_setup(client, false)

	var peer_id := 42
	host.net_players_by_peer = {
		peer_id: {
			"manifestation_key": "parasitica",
			"manifestation": host._manifestation_index_for_key("parasitica"),
			"alive": true,
			"dead": false,
			"eliminated": false,
			"hp": 450.0,
			"pos": Vector2(640, 360),
		}
	}
	var enemy := _enemy(8801)
	host.enemies = [enemy]
	var manifestation_index: int = host._manifestation_index_for_key("parasitica")
	host._client_damage_request(host.NET_DAMAGE_ENEMY, "8801", 10.0, "parasite_bite", Vector2(640, 360), true, "skill_q", peer_id, manifestation_index)
	_check(int(enemy.get("seeds", 0)) == 1, "authority did not register the remote bite larva")
	_check(int(enemy.get("parasite_owner_peer_id", 0)) == peer_id, "authority lost infestation ownership")
	host._client_damage_request(host.NET_DAMAGE_ENEMY, "8801", 10.0, "parasite_king", Vector2(700, 360), true, "skill_e", peer_id, manifestation_index)
	_check(int(enemy.get("seeds", 0)) == 2, "authority did not register the remote king larva")
	host._client_damage_request(host.NET_DAMAGE_ENEMY, "8801", 10.0, "parasite_devour", Vector2(700, 360), true, "skill_e", peer_id, manifestation_index)
	_check(int(enemy.get("seeds", -1)) == 0 and bool(enemy.get("parasite_devoured", false)), "authority did not consume larvae on remote Devour")
	_check(int(enemy.get("parasite_devoured_by_peer_id", 0)) == peer_id, "authority lost remote Devour ownership")

	client._parasitica().activate_symbiosis()
	var sym_before: float = client._parasitica().sym_left
	_check(client._parasitica().apply_confirmed_infested_kill("parasite_kill:8801"), "client rejected confirmed infested kill")
	_check(client._parasitica().sym_left > sym_before, "confirmed kill did not extend client Symbiosis")
	var sym_after: float = client._parasitica().sym_left
	_check(not client._parasitica().apply_confirmed_infested_kill("parasite_kill:8801"), "duplicate kill confirmation was replayed")
	_check(is_equal_approx(client._parasitica().sym_left, sym_after), "duplicate confirmation extended Symbiosis twice")

	host._parasitica().activate_symbiosis()
	host._parasitica().king = {
		"active": true, "pos": Vector2(700, 360), "state": "attack", "state_t": 0.2,
		"consumed": 2, "perfect": false, "fed": 1,
		"life": 5.0, "max_life": 8.0, "bite": 0.1, "devour": 0.0,
		"facing": 1.0, "trail": [Vector2(680, 360)], "target": {}, "seed": 99,
	}
	var visual: Dictionary = host.RTManifestationVisualSnapshotScript.capture(host, host.NET_ABILITY_SECONDARY, "parasitica")
	_check(Dictionary(visual.get("parasitica_visual", {})).has("king"), "public snapshot omitted Verme-Rei")

	print("MULTIPLAYER_PARASITICA_PARITY_OK authority_larvae=true devour=true owner=true kill_confirmation=true duplicate=false visual_king=true")
	_cleanup(client)
	_cleanup(host)
	client = null
	host = null
	for _frame in range(4):
		await process_frame
	quit(0)


func _cleanup(game: Node) -> void:
	if game == null or not is_instance_valid(game):
		return
	root.remove_child(game)
	game._cleanup_runtime_resources()
	game.free()
