extends SceneTree

const OUTPUT := "res://.codex/henry_barometric/"
const Presentation = preload("res://scripts/presentation/henry_barometric_presentation.gd")

var canvas: SubViewport
var game: Node
var failed := false
var captures := 0


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("HENRY_BAROMETRIC_VISUAL_FAIL requires rendered frames")
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
	if condition:
		return
	failed = true
	printerr("HENRY_BAROMETRIC_VISUAL_FAIL " + message)


func _run() -> void:
	await process_frame
	game.set_process(false)
	game.forced_initial_phase = 1
	game.card_unlock_progress["umbra_victories"] = 1.0
	game.active_character_key = game.CHARACTER_HENRY
	game.selected_mutation = 1
	game.selected_effect = 1
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
	for offset in [Vector2(185.0, -55.0), Vector2(280.0, 52.0), Vector2(-210.0, 90.0)]:
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + offset)
		game.enemies[-1]["hp"] = 5000.0
		game.enemies[-1]["max_hp"] = 5000.0
		game.enemies[-1]["stun"] = 999.0
	var owner = game.henry_barometric_ability_controller
	Presentation.warmup()
	var initial_mesh_ids := PackedInt64Array()
	for mesh in Presentation._meshes:
		initial_mesh_ids.append(mesh.get_instance_id())
	game.move_touch_index = 1
	game.touch_move = Vector2.RIGHT
	await _capture("barometric_walk_side_1280x720.png", Vector2i(1280, 720), 0)
	game.touch_move = Vector2.UP
	await _capture("barometric_walk_back_1280x720.png", Vector2i(1280, 720), 0)
	await _capture_nearest_closeup("barometric_walk_back_nearest_x4.png")
	game.move_touch_index = -1
	game.touch_move = Vector2.ZERO

	for index in range(3):
		owner.fire_auto_attack()
		owner.on_henry_auto_fired()
	game.last_attack_time = game.time_alive
	game.henry_attack_visual_stage = 2
	# Separate the authored projectile stages so the capture can expose their
	# silhouettes; frozen game processing otherwise stacks them at the muzzle.
	for index in range(game.bullets.size()):
		game.bullets[index]["pos"] = game.player_pos + Vector2(80 + index * 76, -28 + index * 24)
		game.bullets[index]["dir"] = Vector2.RIGHT
		game.bullets[index]["age"] = 0.18
	await _capture("barometric_auto_nimbo_1280x720.png", Vector2i(1280, 720), 42)

	game.bullets.clear()
	owner.begin_skill(game.player_pos + Vector2.RIGHT * 500.0)
	game.henry_skill_cast_elapsed = owner.CORRIDOR_WINDUP * 0.62
	await _capture("barometric_hab1_pose_1280x720.png", Vector2i(1280, 720), 20)
	owner.update(owner.CORRIDOR_WINDUP + 0.48)
	await _capture("barometric_corridor_1280x720.png", Vector2i(1280, 720), 80)

	owner.update(owner.CORRIDOR_DURATION)
	owner.cast_ultimate()
	for capture in [
		["barometric_ultimate_compression_1280x720.png", 0.02],
		["barometric_ultimate_gathering_1280x720.png", 0.34],
		["barometric_ultimate_release_1280x720.png", 0.62],
		["barometric_ultimate_stabilization_1280x720.png", 0.96],
	]:
		game.henry_ultimate_cast_elapsed = owner.STORM_WINDUP * float(capture[1])
		owner.storm_elapsed = game.henry_ultimate_cast_elapsed
		await _capture(String(capture[0]), Vector2i(1280, 720), 0)
	await _capture_nearest_closeup("barometric_ultimate_stabilization_nearest_x4.png")
	owner.update(owner.STORM_WINDUP + 0.01)
	owner.update(1.25)
	await _capture("barometric_eye_storm_1280x720.png", Vector2i(1280, 720), 115)
	await _capture_nearest_closeup("barometric_eye_storm_nearest_x4.png")
	if OS.get_cmdline_user_args().has("--vfx-motion"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT + "motion"))
		for index in range(24):
			owner.storm_elapsed = 1.25 + index * 0.1
			owner.nimbo_phase += 0.18
			game.time_alive += 0.1
			await _capture("motion/storm_%02d.png" % index, Vector2i(1280, 720), 0)
	owner.storm_elapsed = owner.STORM_DURATION * 0.97
	await _capture("barometric_storm_dissipating_1280x720.png", Vector2i(1280, 720), 0)

	game.gfx_low_resource = true
	canvas.size = Vector2i(960, 540)
	game.player_pos = Vector2(480.0, 300.0)
	owner.storm_elapsed = 2.4
	await _capture("barometric_eye_storm_low_960x540.png", Vector2i(960, 540), 48)
	game.gfx_particles = false
	await _capture("barometric_eye_storm_no_particles_960x540.png", Vector2i(960, 540), 48)
	game.gfx_particles = true
	owner.reset()
	owner.cast_ultimate()
	game.henry_ultimate_cast_elapsed = owner.STORM_WINDUP * 0.96
	owner.storm_elapsed = game.henry_ultimate_cast_elapsed
	await _capture("barometric_ultimate_stabilization_low_960x540.png", Vector2i(960, 540), 0)

	game.gfx_low_resource = false
	canvas.size = Vector2i(1280, 720)
	owner.reset()
	game.is_multiplayer = true
	game.player_pos = Vector2(920.0, 600.0)
	game.net_players_by_peer[22] = {"pos": Vector2(680.0, 480.0), "render_pos": Vector2(680.0, 480.0), "manifestation": game.HENRY_SELECTION_INDEX, "manifestation_key": "barometrico", "has_snapshot": true, "alive": true, "hp": 450.0, "hp_max": 450.0, "name": "HENRY REMOTO", "anim_state": game.NET_ANIM_IDLE, "frame_idx": 0}
	game.net_ability_visuals = [{
		"schema": 3,
		"source": 22,
		"sequence": 1,
		"action": game.NET_ABILITY_SKILL,
		"manifestation": game.HENRY_SELECTION_INDEX,
		"manifestation_key": "barometrico",
		"origin": Vector2(680.0, 480.0),
		"target": Vector2(1070.0, 480.0),
		"life": 2.05,
		"max": 3.2,
		"extra": 0.0,
		"canonical_state": {"manifestation_key": "barometrico", "barometric": {"corridor_active": true}},
	}]
	await _capture("barometric_remote_corridor_1280x720.png", Vector2i(1280, 720), 48)
	game.net_ability_visuals = [{
		"schema": 3,
		"source": 22,
		"sequence": 2,
		"action": game.NET_ABILITY_SECONDARY,
		"manifestation": game.HENRY_SELECTION_INDEX,
		"manifestation_key": "barometrico",
		"origin": Vector2(680.0, 480.0),
		"target": Vector2(680.0, 480.0),
		"life": 4.8,
		"max": 7.05,
		"extra": 0.55,
		"canonical_state": {"manifestation_key": "barometrico", "barometric": {"storm_active": true}},
	}]
	await _capture("barometric_remote_storm_1280x720.png", Vector2i(1280, 720), 68)
	game.net_ability_visuals.clear()
	game.net_players_by_peer.erase(22)
	game.is_multiplayer = false
	game.mode = "mutation_select"
	game.selected_mutation = 1
	await _capture("barometric_mutation_select_1280x720.png", Vector2i(1280, 720), 0)
	game.mode = "effect_select"
	game.selected_effect = 1
	await _capture("nimbo_effect_select_1280x720.png", Vector2i(1280, 720), 0)

	_check(Presentation._meshes.size() == 3, "unexpected growth of the VFX mesh cache")
	for index in range(Presentation._meshes.size()):
		_check(Presentation._meshes[index].get_instance_id() == initial_mesh_ids[index], "VFX mesh rebuilt during drawing")
	print("HENRY_BAROMETRIC_VISUAL_OK captures=%d desktop=1280x720 low=960x540 nearest_x4=true local_remote=true particles_off=true stable_meshes=3 output=%s" % [captures, ProjectSettings.globalize_path(OUTPUT)])
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	canvas.queue_free()
	await process_frame
	quit(1 if failed else 0)


func _capture(file_name: String, expected_size: Vector2i, minimum_cyan_samples: int) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = canvas.get_texture().get_image()
	_check(image != null and not image.is_empty(), "invalid capture " + file_name)
	_check(image.get_size() == expected_size, "wrong capture size for " + file_name)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	_check(image.save_png(OUTPUT + file_name) == OK, "could not save " + file_name)
	captures += 1
	if minimum_cyan_samples > 0:
		_check(_cyan_signal_count(image) >= minimum_cyan_samples, "pressure VFX is not readable in " + file_name)


func _capture_nearest_closeup(file_name: String) -> void:
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = canvas.get_texture().get_image()
	var source_rect := Rect2i(480, 300, 320, 200)
	var closeup := image.get_region(source_rect)
	closeup.resize(1280, 800, Image.INTERPOLATE_NEAREST)
	_check(closeup.save_png(OUTPUT + file_name) == OK, "could not save nearest-neighbor closeup")
	captures += 1


func _cyan_signal_count(image: Image) -> int:
	var count := 0
	for y in range(0, image.get_height(), 6):
		for x in range(0, image.get_width(), 6):
			var color := image.get_pixel(x, y)
			if color.g > 0.56 and color.b > 0.62 and color.b > color.r * 1.18:
				count += 1
	return count
