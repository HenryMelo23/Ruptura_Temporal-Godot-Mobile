extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("MULTIPLAYER_CHARACTER_ASSIGNMENT_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game.online_mode_unlocked = true
	game.henry_cheat_unlocked = true
	game._apply_character_identity(game.CHARACTER_HENRY)
	game.mode = "menu"
	game._activate_menu_option("multiplayer")
	_check(game.mode == "multiplayer_menu", "multiplayer still opened character selection")
	_check(game.active_character_key == game.CHARACTER_GEOVANA, "multiplayer entry did not default to Geovana")
	game._open_character_select("multiplayer")
	_check(game.mode == "multiplayer_menu", "legacy multiplayer character-selection entry was not blocked")

	game._open_character_select("solo")
	_check(game.mode == "character_select", "solo no longer opens character selection")
	game._select_character(game.CHARACTER_HENRY)
	_check(game.mode == "mutation_select" and game.active_character_key == game.CHARACTER_HENRY, "solo Henry selection stopped working")

	var roster := [
		{"peer_id": 20, "name": "HOST", "owner": true, "slot": 1, "spectator": false},
		{"peer_id": 30, "name": "SEGUNDO", "owner": false, "slot": 2, "spectator": false},
		{"peer_id": 10, "name": "TERCEIRO", "owner": false, "slot": 3, "spectator": false},
		{"peer_id": 99, "name": "ESPECTADOR", "owner": false, "slot": 0, "spectator": true}
	]
	var host_assignment: Dictionary = game.lobby_controller.character_assignment(roster, 20, "HOST", true)
	var second_assignment: Dictionary = game.lobby_controller.character_assignment(roster, 30, "SEGUNDO", false)
	var third_assignment: Dictionary = game.lobby_controller.character_assignment(roster, 10, "TERCEIRO", false)
	_check(int(host_assignment.get("slot", 0)) == 1 and String(host_assignment.get("character", "")) == game.CHARACTER_GEOVANA, "host was not assigned Geovana")
	_check(int(second_assignment.get("slot", 0)) == 2 and String(second_assignment.get("character", "")) == game.CHARACTER_HENRY, "second player was not assigned Henry")
	_check(int(third_assignment.get("slot", 0)) == 3 and String(third_assignment.get("character", "")) == game.CHARACTER_GEOVANA, "third player was not assigned Geovana")
	var duplicate_name_roster := roster.duplicate(true)
	duplicate_name_roster[1]["name"] = "MESMO NOME"
	duplicate_name_roster[2]["name"] = "MESMO NOME"
	var duplicate_name_third: Dictionary = game.lobby_controller.character_assignment(duplicate_name_roster, 10, "MESMO NOME", false)
	_check(int(duplicate_name_third.get("slot", 0)) == 3 and String(duplicate_name_third.get("character", "")) == game.CHARACTER_GEOVANA, "peer id did not win over a duplicated nickname")

	game.dedicated_room_owner_peer_id = 20
	game.dedicated_ready_by_peer = {20: false, 10: false, 30: false}
	game.dedicated_spectator_by_peer = {}
	game.dedicated_join_order = [20, 30, 10]
	_check(game._dedicated_multiplayer_slot_for_peer(20) == 1, "server did not reserve slot 1 for host")
	_check(game._dedicated_multiplayer_slot_for_peer(30) == 2 and game._dedicated_multiplayer_slot_for_peer(10) == 3, "server did not preserve client join order when assigning slots")

	game.dedicated_server_mode = false
	game.online_room_owner = false
	game.is_host = false
	game.player_nickname = "SEGUNDO"
	game.henry_cheat_unlocked = false
	game.online_lobby_roster = roster
	game._apply_multiplayer_character_from_roster()
	_check(game.active_character_key == game.CHARACTER_HENRY, "slot 2 did not force Henry independently of unlocks")
	_check(game.selected_manifestation == game.HENRY_SELECTION_INDEX and game.selected_aura == game.HENRY_SELECTION_INDEX, "Henry multiplayer loadout was not prepared")

	game.player_nickname = "TERCEIRO"
	game._apply_multiplayer_character_from_roster()
	_check(game.active_character_key == game.CHARACTER_GEOVANA, "slot 3 did not return to Geovana")
	_check(game.selected_manifestation != game.HENRY_SELECTION_INDEX and game.selected_aura != game.HENRY_SELECTION_INDEX, "Geovana retained Henry selection indices")

	game.player_nickname = "SEGUNDO"
	game.mode = "multiplayer_preload"
	game._start_multiplayer_manifest()
	_check(game.mode == "mutation_select_mp" and game.active_character_key == game.CHARACTER_HENRY, "slot 2 did not enter Henry multiplayer preparation")

	game.mode = "multiplayer_preload"
	game.online_room_owner = true
	game.player_nickname = "HOST"
	game._start_multiplayer_manifest()
	_check(game.mode == "manifest_mp" and game.active_character_key == game.CHARACTER_GEOVANA, "host did not enter Geovana multiplayer preparation")

	print("MULTIPLAYER_CHARACTER_ASSIGNMENT_OK solo_select=true multiplayer_select=false host=geovana player2=henry player3=geovana")
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	quit(0)
