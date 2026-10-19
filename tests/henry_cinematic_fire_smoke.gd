extends SceneTree

var game: Node
var failures := 0

func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("HENRY_CINEMATIC_FAIL " + message)

func run() -> void:
	await process_frame
	game.set_process(false)
	game.active_character_key = game.CHARACTER_HENRY
	game.run_tutorial_enabled = false
	game.forced_initial_phase = 1
	game._start_game()
	game.mode = "game"
	var owner = game.henry_incendiary_ability_controller
	check(owner.entrance_active, "new Henry run did not start cinematic")
	check(not game._run_can_be_saved(), "transient cinematic can be saved")
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(500, 400))
	var enemy: Dictionary = game.enemies[-1]
	var original := Vector2(enemy["pos"])
	var hp: float = game.player_hp
	game._update_game(0.6)
	check(not Vector2(enemy["pos"]).is_equal_approx(original), "enemies did not wander before Henry")
	check(is_equal_approx(owner.entrance_world_speed(), 1.0), "first 1.2 seconds are not full speed")
	game._update_game(0.9)
	check(owner.entrance_world_speed() > 0 and owner.entrance_world_speed() < 1, "missing gradual slowdown")
	game._update_game(0.4)
	var frozen := Vector2(enemy["pos"])
	var animation_before: float = game.henry_entry_timer
	game._update_game(0.6)
	check(Vector2(enemy["pos"]).is_equal_approx(frozen), "enemy moved in frozen interval")
	check(game.henry_entry_timer < animation_before, "Henry froze with the world")
	check(game.time_alive == 0.0 and game.player_hp == hp, "intro advanced combat time or damage")
	check(game._local_player_controls_locked(), "controls unlocked before final glasses frame")
	game._update_game(3.0)
	check(not owner.entrance_active and not game._local_player_controls_locked(), "authority did not release controls")
	check(game._run_can_be_saved(), "saving stayed locked after intro")

	# Actual gameplay update, held move and teleport during the one-second Q.
	game.enemies.clear()
	game.spawn_timer = 999.0
	var move_key := InputEventKey.new()
	move_key.keycode = KEY_D
	move_key.pressed = true
	Input.parse_input_event(move_key)
	await process_frame
	game.player_pos = Vector2(800, 450)
	var position: Vector2 = game.player_pos
	check(owner.begin_skill(position + Vector2.RIGHT * 400), "Q did not start")
	game._try_dash()
	check(game.player_pos == position, "teleport interrupted Q")
	game._update_game(0.3)
	check(game.player_pos == position and game.henry_skill_cast_active, "movement interrupted Q windup")
	game._update_game(0.3)
	check(game.player_pos == position and game.henry_skill_damage_applied, "movement interrupted Q release")
	check(not owner.cast_ultimate(), "E interrupted Q")
	game._update_game(0.41)
	check(not game.henry_skill_cast_active, "Q did not release after 1 second")
	game._update_game(0.1)
	check(game.player_pos.x > position.x, "movement did not resume after Q")
	move_key.pressed = false
	Input.parse_input_event(move_key)

	# Same snapshot path as host/client; two and three slots, client-only Henry.
	for count in [2, 3]:
		game.time_alive = 0.0
		game.is_multiplayer = true
		game.is_host = true
		game.active_character_key = game.CHARACTER_GEOVANA
		game.mp_manifest_state_by_peer = {2: {"manifestation": game.HENRY_SELECTION_INDEX}}
		if count == 3:
			game.mp_manifest_state_by_peer[3] = {"manifestation": 0}
		game._begin_player_start_down_intro()
		check(owner.entrance_active and owner.entrance_peers == [2], "remote Henry did not freeze whole team")
		game._update_game(2.0)
		var packet: Dictionary = game._pack_net_boss_visuals()
		game.is_host = false
		owner.entrance_elapsed = 0.0
		game._apply_remote_boss_visual_snapshot(packet)
		check(owner.entrance_active and game._local_player_controls_locked(), "replica did not enter shared pause")
		var remote_position := Vector2(enemy["pos"])
		game._update_game(50.0)
		check(owner.entrance_active, "replica released itself without authority")
		check(Vector2(enemy["pos"]) == remote_position, "replica mutated enemies")
		game.is_host = true
		game._update_game(0.1)
		var release: Dictionary = game._pack_net_boss_visuals()
		game.is_host = false
		owner.entrance_finished = false
		game._apply_remote_boss_visual_snapshot(release)
		check(not owner.entrance_active, "authoritative release not consumed")
		game._apply_remote_boss_visual_snapshot(packet)
		check(not owner.entrance_active, "stale active snapshot reopened cinematic")
	game.is_multiplayer = true
	game.is_host = true
	game.active_character_key = game.CHARACTER_GEOVANA
	game.time_alive = 0.0
	game.mp_manifest_state_by_peer = {2: {"manifestation": game.HENRY_SELECTION_INDEX}}
	game._begin_player_start_down_intro()
	game._rpc_remove_remote_player(2)
	check(not owner.entrance_active, "disconnect of sole Henry left shared pause active")
	game.is_multiplayer = false
	game.is_host = false
	game.active_character_key = game.CHARACTER_HENRY
	game._begin_player_start_down_intro()
	game.mode = "menu"
	owner.maintain_entrance_lifecycle()
	check(not owner.entrance_active and game.henry_entry_timer == 0, "menu did not clean cinematic")
	game._start_game(false)
	check(not owner.entrance_active, "resume/retry restarted opening cinematic")
	print("HENRY_CINEMATIC_FIRE_SMOKE failures=%d wander=1.2 brake=0.65 freeze=true control_lock=true snapshot=duo_trio stale=true cleanup=true" % failures)
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
