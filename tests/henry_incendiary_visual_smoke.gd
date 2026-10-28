extends SceneTree

const OUT_DIR := "res://.codex"

var game: Node


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("HENRY_INCENDIARY_VISUAL_FAIL " + message)
	quit(1)


func _run() -> void:
	await process_frame
	game.set_process(false)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	game.card_unlock_progress["umbra_victories"] = 1.0
	game.mode = "character_select"
	game.character_select_index = 1
	await _capture("henry_character_select_1280x720.png", "orange")

	game.active_character_key = game.CHARACTER_HENRY
	game._start_game()
	game.henry_incendiary_ability_controller.cancel_entrance()
	game.set_process(false)
	game.mode = "game"
	game.startup_thanks_done = true
	game.startup_thanks_timer = 0.0
	game.startup_thanks_fading = false
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.gfx_screen_shake = false
	game.gfx_particles = true
	game.player_pos = Vector2(640.0, 390.0)
	game.last_facing = Vector2.RIGHT
	game.henry_entry_timer = game.HENRY_ENTRY_DURATION * 0.88
	await _capture("henry_entry_materializing_1280x720.png", "cyan")
	game.henry_entry_timer = game.HENRY_ENTRY_DURATION * 0.27
	await _capture("henry_entry_sunglasses_1280x720.png", "")
	game.henry_entry_timer = game.HENRY_ENTRY_DURATION * 0.04
	await _capture("henry_entry_ready_1280x720.png", "")
	game.henry_entry_timer = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.henry_idle_elapsed = 1.70
	game.henry_idle_beard_timer = 0.0
	await _capture("henry_idle_foot_tap_1280x720.png", "")
	game.henry_idle_beard_side = 0
	game.henry_idle_beard_timer = game.HENRY_IDLE_BEARD_DURATION * 0.62
	await _capture("henry_idle_beard_left_1280x720.png", "")
	game.henry_idle_beard_side = 1
	await _capture("henry_idle_beard_right_1280x720.png", "")
	game.henry_idle_beard_timer = 0.0
	game.mode = "shop_opening"
	game.shop_opening_timer = game.SHOP_OPENING_ANIM_TIME * 0.86
	await _capture("henry_shop_entry_flash_1280x720.png", "cyan")
	game.shop_opening_timer = game.SHOP_OPENING_ANIM_TIME * 0.61
	await _capture("henry_shop_entry_impact_1280x720.png", "cyan")
	game.shop_opening_timer = game.SHOP_OPENING_ANIM_TIME * 0.34
	await _capture("henry_shop_entry_tie_1280x720.png", "")
	root.size = Vector2i(800, 450)
	game.shop_opening_timer = game.SHOP_OPENING_ANIM_TIME * 0.02
	await _capture("henry_shop_entry_ready_mobile_800x450.png", "")
	root.size = Vector2i(1280, 720)
	game.mode = "game"
	game.move_touch_index = 1
	game.touch_move = Vector2.DOWN
	await _capture("henry_walk_down_1280x720.png", "")
	game.touch_move = Vector2.RIGHT
	await _capture("henry_walk_right_1280x720.png", "")
	game.touch_move = Vector2.LEFT
	await _capture("henry_walk_left_mirrored_1280x720.png", "")
	game.touch_move = Vector2.UP
	await _capture("henry_walk_up_1280x720.png", "")
	game.move_touch_index = -1
	game.touch_move = Vector2.ZERO
	game.last_attack_time = game.time_alive
	game.player_attack_visual_dir = Vector2.DOWN
	game.henry_attack_visual_stage = 0
	await _capture("henry_fire_south_first_1280x720.png", "")
	game.henry_attack_visual_stage = 2
	await _capture("henry_fire_south_third_1280x720.png", "")
	game.player_attack_visual_dir = Vector2(1.0, -1.0).normalized()
	game.henry_attack_visual_stage = 1
	await _capture("henry_fire_northeast_second_1280x720.png", "")
	game.last_attack_time = -99.0
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(120.0, -20.0))
	game._spawn_enemy(game.ENEMY_STALKER, game.player_pos + Vector2(250.0, 64.0))
	for enemy in game.enemies:
		enemy["hp"] = 2000.0
		enemy["max_hp"] = 2000.0
		enemy["stun"] = 999.0
	_check(game.henry_incendiary_ability_controller.begin_skill(game.player_pos + Vector2.RIGHT * 400.0), "could not begin cone cast")
	game.henry_skill_cast_elapsed = 0.08
	await _capture("henry_basic_skill_windup_1280x720.png", "")
	for skill_step in range(25):
		game.henry_incendiary_ability_controller.update(0.02)
	await _capture("henry_incendiary_cone_1280x720.png", "orange")
	game.henry_flame_cones.clear()
	await _capture("henry_hab1_guard_bursts_1280x720.png", "orange")

	game.henry_incendiary_ability_controller.update(game.HENRY_SKILL_CAST_DURATION)
	_check(game.henry_incendiary_ability_controller.cast_ultimate(), "could not cast heat wave")
	game.henry_ultimate_cast_elapsed = 0.05
	await _capture("henry_ultimate_crouch_1280x720.png", "")
	game.henry_ultimate_cast_elapsed = 0.30
	await _capture("henry_ultimate_absorb_1280x720.png", "orange")
	game.henry_ultimate_cast_elapsed = 0.55
	await _capture("henry_ultimate_fire_rising_1280x720.png", "orange")
	game.henry_ultimate_cast_elapsed = 0.78
	await _capture("henry_ultimate_fully_charged_1280x720.png", "orange")
	game.henry_incendiary_ability_controller.update(0.03)
	game.henry_incendiary_ability_controller.update(0.18)
	await _capture("henry_incandescence_wave_1280x720.png", "orange")
	game.henry_incendiary_ability_controller.update(0.60)
	await _capture("henry_ultimate_second_cycle_1280x720.png", "orange")
	game.henry_incendiary_ability_controller.update(0.80)
	await _capture("henry_ultimate_third_cycle_1280x720.png", "orange")

	game.henry_incendiary_ability_controller.reset()
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(126.0, 0.0))
	var spin_target: Dictionary = game.enemies[-1]
	spin_target["hp"] = 5000.0
	spin_target["max_hp"] = 5000.0
	spin_target["stun"] = 999.0
	for stack_index in range(5):
		game._damage_enemy(spin_target, 10.0, "henry_spark", false, false, game.player_pos, "basic_attack")
	await _capture("henry_burn_five_stacks_1280x720.png", "")
	game._execute_teleport(game.player_pos + Vector2.RIGHT * 400.0)
	game.henry_incendiary_ability_controller.update(0.36)
	await _capture("henry_spin_fast_1280x720.png", "orange")
	game.henry_incendiary_ability_controller.update(1.34)
	await _capture("henry_spin_mid_1280x720.png", "orange")
	game.henry_incendiary_ability_controller.update(1.05)
	await _capture("henry_spin_slowdown_1280x720.png", "orange")
	root.size = Vector2i(960, 540)
	await _capture("henry_spin_slowdown_mobile_960x540.png", "orange_low")
	root.size = Vector2i(1280, 720)
	for spin_step in range(5):
		game.henry_incendiary_ability_controller.update(0.05)
	game.henry_incendiary_ability_controller.update(0.18)
	await _capture("henry_spin_final_explosion_1280x720.png", "orange")

	game.henry_heat_waves.clear()
	game.henry_incendiary_ability_controller.reset()
	game.gfx_low_resource = true
	root.size = Vector2i(960, 540)
	_check(game.henry_incendiary_ability_controller.cast_ultimate(), "could not cast low-resource heat wave")
	game.henry_ultimate_cast_elapsed = 0.55
	await _capture("henry_ultimate_fire_rising_low_960x540.png", "orange_low")
	game.henry_incendiary_ability_controller.reset()
	game.gfx_low_resource = false
	root.size = Vector2i(1280, 720)
	game.henry_incendiary_ability_controller.on_player_damaged(180)
	game.henry_incendiary_ability_controller.update(game.HENRY_FRICTION_RELEASE_INTERVAL + 0.01)
	game.henry_incendiary_ability_controller.update(0.36)
	await _capture("henry_incandescence_passive_1280x720.png", "orange")

	game.gfx_low_resource = true
	root.size = Vector2i(960, 540)
	await _capture("henry_incandescence_passive_low_960x540.png", "orange")

	print("HENRY_INCENDIARY_VISUAL_OK selection=true intro=materialize_glasses_ready_equal_scale shop_entry=flash_impact_tie_ready_mobile idle=pocket_tap beard=left_right walk=down_right_left_mirror_up fire=dedicated_equal_scale basic_skill=cone_plus_3_guard_bursts ultimate=3x_800ms spin=8_authored_frames_dual_arm_fire_slowdown_final_burst burn_stacks=5 desktop=true mobile=true passive=true low=true " + ProjectSettings.globalize_path(OUT_DIR))
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	await process_frame
	quit(0)


func _capture(file_name: String, required_signal: String) -> void:
	game.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and not image.is_empty(), "invalid capture " + file_name)
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var output := OUT_DIR.path_join(file_name)
	_check(image.save_png(output) == OK, "could not save " + file_name)
	if required_signal == "orange":
		_check(_orange_signal_count(image) > 45, "Incendiario orange signal is not readable in " + file_name)
	elif required_signal == "orange_low":
		_check(_orange_signal_count(image) > 18, "Incendiario low-resource orange signal is not readable in " + file_name)
	elif required_signal == "cyan":
		_check(_cyan_signal_count(image) > 18, "Henry materialization signal is not readable in " + file_name)


func _orange_signal_count(image: Image) -> int:
	var count := 0
	for y in range(0, image.get_height(), 7):
		for x in range(0, image.get_width(), 7):
			var color := image.get_pixel(x, y)
			if color.r > 0.62 and color.r > color.g * 1.2 and color.g > color.b * 1.35:
				count += 1
	return count


func _cyan_signal_count(image: Image) -> int:
	var count := 0
	for y in range(0, image.get_height(), 5):
		for x in range(0, image.get_width(), 5):
			var color := image.get_pixel(x, y)
			if color.b > 0.62 and color.g > 0.42 and color.b > color.r * 1.28:
				count += 1
	return count
