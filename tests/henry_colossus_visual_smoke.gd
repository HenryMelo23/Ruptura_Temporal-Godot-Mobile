extends SceneTree

const OUTPUT := "res://.codex/henry_colossus/"
const Presentation = preload("res://scripts/presentation/henry_colossus_presentation.gd")

var canvas: SubViewport
var game: Node
var failed := false
var captures := 0


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("HENRY_COLOSSUS_VISUAL_FAIL requires rendered frames")
		quit(1)
		return
	canvas = SubViewport.new()
	canvas.size = Vector2i(1280, 720)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	game = load("res://scenes/Main.tscn").instantiate()
	canvas.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		printerr("HENRY_COLOSSUS_VISUAL_FAIL " + message)


func _run() -> void:
	await process_frame
	game.set_process(false)
	game.forced_initial_phase = 1
	game.active_character_key = game.CHARACTER_HENRY
	game.selected_mutation = 2
	game.selected_effect = 2
	game._start_game()
	game.henry_incendiary_ability_controller.cancel_entrance()
	game.set_process(false)
	game.mode = "game"
	game.startup_thanks_done = true
	game.vol_master = 0.0
	game.is_multiplayer = false
	game.gfx_screen_shake = false
	game.gfx_particles = true
	game.gfx_low_resource = false
	game.show_fps_counter = false
	game.henry_entry_timer = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(640.0, 390.0)
	game.last_facing = Vector2.RIGHT
	game.player_attack_visual_dir = Vector2.RIGHT
	game.player_damage = 100.0
	game.enemies.clear()
	for offset in [Vector2(92.0, 0.0), Vector2(178.0, 38.0), Vector2(-150.0, 54.0)]:
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + offset)
		game.enemies[-1]["hp"] = 5000.0
		game.enemies[-1]["max_hp"] = 5000.0
		game.enemies[-1]["stun"] = 999.0
	var owner = game.henry_colossus_ability_controller
	Presentation.warmup()
	var mesh_ids: Array[int] = []
	for mesh in Presentation._meshes:
		mesh_ids.append(mesh.get_instance_id())

	owner.fire_auto_attack()
	game.last_attack_time = game.time_alive - 0.10
	game.henry_attack_visual_stage = 1
	await _capture("01_normal_combo_1280x720.png", Vector2i(1280, 720))
	owner.begin_skill(game.player_pos + Vector2.RIGHT * 100.0)
	owner.guard_elapsed = owner.GUARD_WINDOW * 0.38
	game.henry_skill_cast_elapsed = owner.guard_elapsed
	await _capture("02_normal_guard_1280x720.png", Vector2i(1280, 720))
	owner.modify_incoming_damage(100.0, "visual_fixture")
	await _capture("02b_guard_contact_1280x720.png", Vector2i(1280, 720))
	owner.update(0.02)
	await _capture("02c_counter_1280x720.png", Vector2i(1280, 720))
	owner.reset()
	game.player_pos = Vector2(640.0, 390.0)

	owner.cast_ultimate()
	for capture in [["03_growth_early_1280x720.png", 0.14], ["04_growth_mid_1280x720.png", 0.52], ["05_growth_final_1280x720.png", 0.94]]:
		owner.transform_elapsed = owner.TRANSFORM_DURATION * float(capture[1])
		game.henry_ultimate_cast_elapsed = owner.transform_elapsed
		await _capture(String(capture[0]), Vector2i(1280, 720))
	if "--vfx-motion" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT + "motion/"))
		for index in range(24):
			owner.transform_elapsed = owner.TRANSFORM_DURATION * float(index) / 23.0
			game.henry_ultimate_cast_elapsed = owner.transform_elapsed
			await _capture("motion/growth_%02d.png" % index, Vector2i(1280, 720))
	owner.update(owner.TRANSFORM_DURATION + 0.01)
	game.move_touch_index = 1
	game.touch_move = Vector2.RIGHT
	await _capture("06_giant_walk_side_1280x720.png", Vector2i(1280, 720))
	game.touch_move = Vector2.UP
	await _capture("07_giant_walk_back_1280x720.png", Vector2i(1280, 720))
	await _capture_nearest("08_giant_back_nearest_x4.png")
	game.move_touch_index = -1
	game.touch_move = Vector2.ZERO
	game.last_attack_time = game.time_alive - 0.12
	game.henry_attack_visual_stage = 2
	await _capture("09_giant_combo_1280x720.png", Vector2i(1280, 720))
	owner.begin_skill(game.player_pos + Vector2.RIGHT * 300.0)
	owner.update(owner.CHARGE_DURATION * 0.5)
	await _capture("10_giant_charge_1280x720.png", Vector2i(1280, 720))
	await _capture_nearest("10b_charge_nearest_x4.png")
	game._update_effects(0.4)
	owner.charge_active = false
	game.henry_skill_cast_active = false

	for index in range(owner.LASTRO_REQUIRED - 1):
		game.enemies[0]["henry_lastro_stacks"] = index + 1
	game.enemies[1]["henry_lastro_anchor"] = owner.LASTRO_ENEMY_ANCHOR
	await _capture("11_lastro_marks_1280x720.png", Vector2i(1280, 720))

	game.gfx_low_resource = true
	canvas.size = Vector2i(960, 540)
	game.player_pos = Vector2(480.0, 300.0)
	owner.giant_active = true
	owner.giant_elapsed = 14.0
	await _capture("12_giant_low_960x540.png", Vector2i(960, 540))
	game.gfx_particles = false
	owner.charge_active = true
	owner.charge_origin = game.player_pos - Vector2(110, 0)
	owner.charge_elapsed = owner.CHARGE_DURATION * 0.5
	game.henry_skill_cast_active = true
	game.henry_skill_cast_elapsed = owner.charge_elapsed
	await _capture("12b_charge_low_no_particles_960x540.png", Vector2i(960, 540))
	owner.charge_active = false
	game.henry_skill_cast_active = false
	owner.giant_active = false
	owner.shrinking = true
	owner.transform_elapsed = owner.TRANSFORM_DURATION * 0.5
	game.henry_ultimate_cast_active = true
	game.henry_ultimate_cast_elapsed = owner.transform_elapsed
	await _capture("12c_shrink_low_960x540.png", Vector2i(960, 540))
	game.gfx_particles = true

	game.gfx_low_resource = false
	canvas.size = Vector2i(1280, 720)
	owner.reset()
	game.is_multiplayer = true
	game.player_pos = Vector2(930.0, 590.0)
	game.net_players_by_peer[22] = {
		"pos": Vector2(640.0, 430.0), "render_pos": Vector2(640.0, 430.0),
		"manifestation": game.HENRY_SELECTION_INDEX, "manifestation_key": "colosso", "aura": 2,
		"visual_flags": 4, "has_snapshot": true, "alive": true, "hp": 450.0, "hp_max": 450.0,
		"name": "HENRY REMOTO", "anim_state": game.NET_ANIM_RIGHT, "frame_idx": 1,
	}
	game.net_ability_visuals = [{
		"schema": 3, "source": 22, "sequence": 1, "action": game.NET_ABILITY_SECONDARY,
		"manifestation": game.HENRY_SELECTION_INDEX, "manifestation_key": "colosso",
		"origin": Vector2(640.0, 430.0), "target": Vector2(640.0, 430.0),
		"life": 20.0, "max": 32.4, "extra": 1.2,
		"canonical_state": {"manifestation_key": "colosso"},
	}]
	await _capture("13_remote_giant_1280x720.png", Vector2i(1280, 720))
	game.net_ability_visuals.clear()
	game.net_players_by_peer[22]["anim_state"] = game.NET_ANIM_FIRE
	game.net_players_by_peer[22]["frame_idx"] = 1
	await _capture("14_remote_punch_1280x720.png", Vector2i(1280, 720))
	game.net_players_by_peer[22]["anim_state"] = game.NET_ANIM_RIGHT
	game.net_ability_visuals = [{
		"schema": 3, "source": 22, "sequence": 2, "action": game.NET_ABILITY_SKILL,
		"manifestation": game.HENRY_SELECTION_INDEX, "manifestation_key": "colosso",
		"origin": Vector2(480.0, 430.0), "target": Vector2(700.0, 430.0),
		"life": 0.13, "max": 0.44, "extra": 0.0,
		"canonical_state": {"manifestation_key": "colosso"},
	}]
	await _capture("15_remote_charge_late_1280x720.png", Vector2i(1280, 720))
	_check(Presentation._meshes.size() == mesh_ids.size(), "mesh pool grew during rendering")
	for index in range(mesh_ids.size()):
		_check(Presentation._meshes[index].get_instance_id() == mesh_ids[index], "mesh recreated during rendering")

	print("HENRY_COLOSSUS_VISUAL_OK captures=%d desktop=1280x720 low=960x540 nearest_x4=true growth=true normal_giant=true local_remote=true mesh_pool_stable=true output=" % captures + ProjectSettings.globalize_path(OUTPUT))
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	canvas.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _capture(file_name: String, expected_size: Vector2i) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = canvas.get_texture().get_image()
	_check(image != null and not image.is_empty(), "invalid capture " + file_name)
	_check(image.get_size() == expected_size, "wrong capture size for " + file_name)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	_check(image.save_png(OUTPUT + file_name) == OK, "could not save " + file_name)
	captures += 1


func _capture_nearest(file_name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = canvas.get_texture().get_image()
	var closeup := image.get_region(Rect2i(520, 280, 240, 220))
	closeup.resize(960, 880, Image.INTERPOLATE_NEAREST)
	_check(closeup.save_png(OUTPUT + file_name) == OK, "could not save nearest closeup")
	captures += 1
