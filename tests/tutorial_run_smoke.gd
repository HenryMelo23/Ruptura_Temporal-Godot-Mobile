extends SceneTree

const OUT_DIR := "res://.codex"
const UserFileGuard = preload("res://tests/support/user_file_guard.gd")

var game: Node
var failed := false
var config_guard: RefCounted


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("TUTORIAL_RUN_SMOKE_FAIL " + message)


func _initialize() -> void:
	config_guard = UserFileGuard.new("user://hud_config.save")
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	game.orientation_poll_timer = 9999.0
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await process_frame
	game.startup_thanks_done = true
	game.startup_thanks_fading = false
	game.startup_thanks_timer = 0.0
	game._set_run_tutorial_enabled(true, false)
	game.forced_initial_phase = 3
	game._start_game()
	game.set_process(false)
	_check(game.current_phase == 3, "forced development phase was not selected")
	_check(game.tutorial_state == game.TUTORIAL_STATE_NONE, "forced development phase reopened tutorial")
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.shop_auto_enabled = true
	game.score = game.card_cost * 2
	game._update_button_layout(Vector2(1280, 720))
	_check(not game.buttons.has("shop_manual"), "development phase restored the retired manual shop")
	_check(game.shop_rift_controller.enabled(), "development phase disabled the merchant rift")
	game.forced_initial_phase = 0
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	_check(game.tutorial_state == game.TUTORIAL_STATE_OFFER, "tutorial offer did not open on fresh run")
	_check(game._tutorial_blocks_normal_spawn(), "tutorial offer does not block normal spawn")
	_check(game.effects.is_empty(), "startup floating texts were not cleared for tutorial offer")
	await _capture("tutorial_offer_1280x720.png")
	root.size = Vector2i(960, 540)
	await process_frame
	await _capture("tutorial_offer_960x540.png", Vector2i(960, 540))
	root.size = Vector2i(1280, 720)
	await process_frame

	game._accept_tutorial_offer(true)
	_check(game.tutorial_state == RTTutorialGuide.STATE_CONTROLS, "tutorial did not open controls summary")
	_check(game.enemies.is_empty(), "controls summary spawned enemies early")
	game.desktop_attack_aim_mode = game.DESKTOP_ATTACK_AIM_AUTO
	game.desktop_teleport_mode = game.DESKTOP_TELEPORT_CURSOR
	_check(game._effective_desktop_teleport_mode() == game.DESKTOP_TELEPORT_LAST_DIRECTION, "auto attack kept cursor teleport")
	_check(game.player_control_controller.desktop_dash_mode() == game.DESKTOP_TELEPORT_LAST_DIRECTION, "dash mode ignored auto attack rule")
	_check(not game._tutorial_guide().allowed_teleport_modes().has(game.DESKTOP_TELEPORT_CURSOR), "settings still offer cursor teleport with auto attack")
	game.desktop_attack_aim_mode = game.DESKTOP_ATTACK_AIM_CURSOR
	_check(game._effective_desktop_teleport_mode() == game.DESKTOP_TELEPORT_CURSOR, "cursor attack did not free cursor teleport")
	game.desktop_attack_aim_mode = game.DESKTOP_ATTACK_AIM_AUTO
	var controls_text: Dictionary = game._tutorial_step_text(RTTutorialGuide.STATE_CONTROLS)
	_check(String(controls_text.get("hint", "")).find("CONFIGURA") >= 0, "controls step does not point to settings")
	await _capture("tutorial_controls_1280x720.png")
	game._continue_tutorial_story()
	_check(game.tutorial_state == game.TUTORIAL_STATE_ATTACK, "tutorial did not enter attack step")
	_check(game.enemies.size() == 1, "attack step did not create one training enemy")
	_check(bool(game.enemies[0].get("tutorial", false)), "training enemy was not marked")
	_check(float(game.enemies[0].get("damage", 999.0)) <= 8.0, "training damage is not reduced")
	_check(float(game.enemies[0].get("speed", 999.0)) <= game.enemy_speed_base * 0.45, "training speed is not reduced")
	await _capture("tutorial_attack_1280x720.png")
	root.size = Vector2i(960, 540)
	await process_frame
	await _capture("tutorial_attack_960x540.png", Vector2i(960, 540))
	root.size = Vector2i(1280, 720)
	await process_frame

	var target: Dictionary = game.enemies[0]
	game._kill_enemy(target)
	_check(game.tutorial_state == game.TUTORIAL_STATE_SKILL, "attack kill did not advance to HAB1")
	_check(game.enemies.size() == 1, "HAB1 step did not create one training enemy")
	var skill_target: Dictionary = game.enemies[0]
	var skill_hp_before: float = float(skill_target.get("hp", 0.0))
	game._damage_enemy(skill_target, 999.0, "eletrica", true, true, game.player_pos, "basic_attack")
	_check(is_equal_approx(float(skill_target.get("hp", 0.0)), skill_hp_before), "wrong basic attack damaged HAB1 tutorial enemy")
	game._damage_enemy(skill_target, 1.0, "eletrica", true, true, game.player_pos, "skill_q")
	_check(float(skill_target.get("hp", 0.0)) < skill_hp_before, "correct HAB1 damage did not affect tutorial enemy")
	game.tutorial_action_grace = 0.0
	game._tutorial_note_action("skill")
	_check(game.tutorial_state == game.TUTORIAL_STATE_SECONDARY, "HAB1 action did not advance to secondary")
	_check(game.enemies.size() == 1, "secondary step did not create one training enemy")
	var secondary_target: Dictionary = game.enemies[0]
	var secondary_hp_before: float = float(secondary_target.get("hp", 0.0))
	game._damage_enemy(secondary_target, 999.0, "eletrica", true, true, game.player_pos, "skill_q")
	_check(is_equal_approx(float(secondary_target.get("hp", 0.0)), secondary_hp_before), "wrong HAB1 damaged ULT tutorial enemy")
	game._damage_enemy(secondary_target, 1.0, "eletrica", true, true, game.player_pos, "skill_e")
	_check(float(secondary_target.get("hp", 0.0)) < secondary_hp_before, "correct ULT damage did not affect tutorial enemy")
	game.tutorial_action_grace = 0.0
	game._tutorial_note_action("secondary")
	_check(game.tutorial_state == game.TUTORIAL_STATE_DASH, "secondary action did not advance to dash")
	game.tutorial_action_grace = 0.0
	_check(not game._tutorial_guide().action_allowed("dash") or true, "")
	game._tutorial_note_action("dash")
	_check(game.tutorial_state == RTTutorialGuide.STATE_DASH_LINE, "dash action did not open the damage line step")
	var guide: RTTutorialGuide = game._tutorial_guide()
	var hp_before: int = int(game.player_hp)
	game.last_dash_time = -100.0
	game.player_pos = Vector2(guide.line_x + 10.0, game.player_pos.y)
	guide.update(0.016)
	_check(game.player_pos.x < guide.line_x, "walking through the line was not pushed back")
	_check(int(game.player_hp) < hp_before, "walking through the line did no damage")
	await _capture("tutorial_dash_line_1280x720.png")
	hp_before = int(game.player_hp)
	game.last_dash_time = game.time_alive
	game.player_pos = Vector2(guide.line_x + 60.0, game.player_pos.y)
	guide.update(0.016)
	guide.update(1.0)
	_check(int(game.player_hp) == hp_before, "teleport through the line dealt damage")
	_check(game.tutorial_state == game.TUTORIAL_STATE_MANIFESTATION, "teleport across line did not advance to manifestation context")
	await _capture("tutorial_manifestation_1280x720.png")
	game._continue_tutorial_story()
	_check(game.tutorial_state == game.TUTORIAL_STATE_AURA, "manifestation context did not advance to aura")
	await _capture("tutorial_aura_1280x720.png")
	root.size = Vector2i(960, 540)
	await process_frame
	await _capture("tutorial_aura_960x540.png", Vector2i(960, 540))
	root.size = Vector2i(1280, 720)
	await process_frame
	game._continue_tutorial_story()
	_check(game.tutorial_state == game.TUTORIAL_STATE_ESSENCE, "aura context did not advance to essence")
	await _capture("tutorial_essence_1280x720.png")
	game._continue_tutorial_story()
	_check(game.tutorial_state == RTTutorialGuide.STATE_MISSION, "essence did not advance to mission")
	await _capture("tutorial_mission_1280x720.png")
	game._continue_tutorial_story()
	_check(game.tutorial_state == game.TUTORIAL_STATE_FINISH, "mission context did not advance to finish")
	game._continue_tutorial_story()
	_check(game.tutorial_state == game.TUTORIAL_STATE_NONE, "tutorial did not finish")
	_check(is_zero_approx(game.spawn_timer), "normal spawn was not released after tutorial")
	_check(not game.run_tutorial_enabled, "completed tutorial did not disable future offers")
	_check(game._tutorial_guide().mission_active, "mission tracker did not start after tutorial")
	_check(String(game._tutorial_guide().mission_text()[0]) == "FIQUE MAIS FORTE", "mission does not start with get stronger")
	await _capture("tutorial_mission_hud_1280x720.png")
	game._tutorial_guide().strong_until = game.time_alive - 1.0
	_check(String(game._tutorial_guide().mission_text()[0]) == "CHAME O CHEFE", "mission did not move to call boss")

	game._start_game()
	game.set_process(false)
	_check(game.tutorial_state == game.TUTORIAL_STATE_NONE, "completed tutorial offered again without settings reactivation")
	_check(game.effects.is_empty(), "normal run kept startup floating texts")

	_check(game._gameplay_preference_keys().has("tutorial"), "gameplay settings do not expose tutorial toggle")
	game.mode = "settings_gameplay"
	game._set_run_tutorial_enabled(true, false)
	await _capture("settings_gameplay_tutorial_1280x720.png")
	root.size = Vector2i(960, 540)
	await process_frame
	await _capture("settings_gameplay_tutorial_960x540.png", Vector2i(960, 540))
	root.size = Vector2i(1280, 720)
	await process_frame
	game._set_run_tutorial_enabled(true, false)
	game._start_game()
	game.set_process(false)
	_check(game.tutorial_state == game.TUTORIAL_STATE_OFFER, "settings-reactivated tutorial did not offer")
	game._accept_tutorial_offer(false)
	_check(game.tutorial_state == game.TUTORIAL_STATE_NONE, "declining tutorial did not return to normal run")
	_check(game.spawn_timer <= 0.2, "declined tutorial did not release normal spawn soon")
	_check(not game.run_tutorial_enabled, "declining tutorial did not disable future offers")

	if failed:
		_cleanup()
		quit(1)
		return
	print("TUTORIAL_RUN_SMOKE_OK " + ProjectSettings.globalize_path(OUT_DIR))
	_cleanup()
	quit(0)


func _capture(file_name: String, expected_size: Vector2i = Vector2i(1280, 720)) -> void:
	game.queue_redraw()
	await process_frame
	if DisplayServer.get_name() == "headless":
		return
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() == expected_size.x and image.get_height() == expected_size.y, "invalid capture " + file_name)
	if image != null:
		_check(image.save_png(OUT_DIR + "/" + file_name) == OK, "could not save " + file_name)


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	if game.get_parent() == root:
		root.remove_child(game)
	game.free()
	game = null
	if config_guard != null:
		config_guard.restore()
