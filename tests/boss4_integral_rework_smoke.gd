extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("BOSS4_INTEGRAL_REWORK_FAIL " + message)
	_cleanup()
	quit(1)


func _setup() -> void:
	game._start_game()
	game.set_process(false)
	game._advance_to_phase(4)
	game.mode = "game"
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_hp_max = 4000.0
	game.boss_hp = 4000.0
	game.boss_pos = game.boss4_entry_target
	game.player_hp_max = 3000.0
	game.player_hp = 3000.0
	game.player_defense = 0.0
	game.player_pos = Vector2(540.0, 450.0)
	game.boss4_controller.reset()
	game.boss4_attack_timer = 99.0


func _settle_transition() -> void:
	for step in range(12):
		game.boss4_controller.update(0.1)


func _normal_action_for_stage(stage: int, hp_ratio: float, distance: float) -> String:
	game.boss_hp = game.boss_hp_max * hp_ratio
	game.player_pos = game.boss_pos + Vector2(distance, 0.0)
	game.boss4_ai_state["state"] = "walk"
	game.boss4_ai_state["action"] = ""
	game.boss4_ai_state["cooldowns"] = {}
	game.boss4_attack_timer = 0.0
	game.boss4_controller.update(0.01)
	if String(game.boss4_ai_state.get("state", "")) == "transition":
		_settle_transition()
	game.boss4_ai_state["state"] = "walk"
	game.boss4_ai_state["action"] = ""
	game.boss4_attack_timer = 0.0
	game.boss4_controller.update(0.01)
	return game.boss4_last_attack


func _run() -> void:
	_setup()
	var start_pos: Vector2 = game.boss_pos
	for step in range(20):
		game.boss4_controller.update(0.05)
	_check(game.boss_pos.distance_to(start_pos) > 8.0, "FSM did not move the boss")
	_check(String(game.boss4_ai_state.get("state", "")) in ["walk", "idle"], "locomotion state was not active")

	game.boss4_ai_state["state"] = "idle"
	game.boss4_ai_state["contact_cooldowns"] = {}
	game.player_pos = game.boss_pos
	var hp_before: float = game.player_hp
	game.boss4_controller._update_contact(0.0)
	var hp_after_first: float = game.player_hp
	_check(hp_after_first < hp_before, "contact did not damage local player")
	game.player_pos = game.boss_pos
	game.boss4_controller._update_contact(0.0)
	_check(is_equal_approx(game.player_hp, hp_after_first), "contact ignored per-player cooldown")
	game.boss4_controller._tick_cooldowns(1.0)
	game.player_pos = game.boss_pos
	game.boss4_controller._update_contact(0.0)
	_check(game.player_hp < hp_after_first, "contact did not recover after cooldown")

	var actions: Array[String] = []
	var action1 := _normal_action_for_stage(1, 0.90, 150.0)
	actions.append(action1)
	_check(action1 in ["slam", "tongue", "comet"], "stage 1 chose invalid action: " + action1)
	var action2 := _normal_action_for_stage(2, 0.70, 315.0)
	actions.append(action2)
	_check(action2 in ["slam", "tongue", "comet", "jump", "fissure", "leak"], "stage 2 chose invalid action: " + action2)
	var action3 := _normal_action_for_stage(3, 0.45, 230.0)
	actions.append(action3)
	_check(action3 in ["slam", "tongue", "comet", "jump", "fissure", "leak", "prison", "clone", "combo"], "stage 3 chose invalid action: " + action3)
	var action4 := _normal_action_for_stage(4, 0.20, 360.0)
	actions.append(action4)
	_check(action4 in ["slam", "tongue", "comet", "jump", "fissure", "leak", "prison", "clone", "combo", "fragments", "gravity", "collapse", "meteor"], "stage 4 chose invalid action: " + action4)
	var distinct_actions: Dictionary = {}
	for action in actions:
		distinct_actions[action] = true
	print("BOSS4_ACTION_TRACE ", actions)
	_check(distinct_actions.size() >= 2, "contextual selector repeated only one attack")

	game.phase4_enemy_hazards.clear()
	game.boss4_ultimate_active = false
	game.boss4_ultimate_used = false
	game.boss4_stun_timer = 0.0
	game._start_boss4_ultimate()
	_check(game.boss4_rupture_anchors.size() == 3, "ultimate did not create exactly three anchors")
	for anchor in game.boss4_rupture_anchors.duplicate(true):
		game._damage_boss4_anchor_at(Vector2(anchor["pos"]), 99999.0, 8.0)
	game._update_boss4_ultimate(0.01)
	_check(not game.boss4_ultimate_active, "destroying three anchors did not interrupt ultimate")
	_check(game.boss4_stun_timer > 0.0 and game.boss4_vulnerable_timer > 0.0, "successful interrupt did not stun/expose")

	game.phase4_enemy_hazards.clear()
	game.boss4_ultimate_active = false
	game.boss4_ultimate_used = false
	game.boss4_stun_timer = 0.0
	game.boss4_vulnerable_timer = 0.0
	game._start_boss4_ultimate()
	game.boss4_ultimate_timer = 0.01
	game._update_boss4_ultimate(0.02)
	_check(not game.boss4_ultimate_active, "timed-out ultimate stayed active")
	_check(game.boss4_stun_timer <= 0.0 and game.boss4_vulnerable_timer <= 0.0, "timeout incorrectly granted success exposure")
	_check(game.phase4_enemy_hazards.filter(func(h): return String(h.get("kind", "")) == "boss4_gravity_well").size() == 3, "timeout did not create three dodgeable wells")
	_check(game.phase4_enemy_hazards.any(func(h): return String(h.get("kind", "")) == "boss4_gravity_laser"), "timeout omitted telegraphed laser counterplay")

	game.boss4_ai_state["state"] = "windup"
	game.boss4_ai_state["action"] = "tongue"
	_check(game.boss4_controller.visual_state() == "tongue", "tongue state did not resolve correct sprite state")
	game.boss4_ai_state["state"] = "jump"
	_check(game.boss4_controller.visual_state() == "jump", "jump state did not resolve correct sprite state")
	game.boss4_ai_state["state"] = "transition"
	game.boss4_stage = 3
	_check(game.boss4_controller.visual_state() == "transition_3", "HP transition did not resolve correct sprite state")

	game.is_multiplayer = false
	game.mode = "game"
	var save_snapshot: Dictionary = game.save_controller._build_interrupted_run_snapshot()
	var fields: Dictionary = save_snapshot.get("fields", {})
	_check(fields.has("boss4_ai_state") and fields.has("boss4_last_attack"), "save snapshot omitted Boss 4 FSM")
	_check(Dictionary(fields.get("boss4_ai_state", {})).has("state"), "save snapshot lost Boss 4 state")

	print("BOSS4_INTEGRAL_REWORK_OK movement=true contact_cooldown=true stages=4 contextual_actions=%s ultimate_interrupt=true ultimate_failure=true save=true" % str(actions))
	_cleanup()
	for frame in range(4):
		await process_frame
	quit(0)


func _cleanup() -> void:
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
	game = null
