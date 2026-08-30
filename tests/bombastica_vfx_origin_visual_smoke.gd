extends SceneTree

const SCREENSHOT_PATH := "res://.agent_logs/bombastica_vfx_origin_after.png"

var game: Node


func _fail(message: String) -> void:
	push_error("BOMBASTICA_VFX_ORIGIN_VISUAL_FAIL " + message)
	_cleanup()
	quit(1)


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	game._start_game()
	game.startup_thanks_done = true
	game.mode = "game"
	game.current_phase = 2
	game.manifestation_key = "bombastica"
	game.gfx_particles = true
	game.gfx_low_resource = false
	game.gfx_screen_shake = false
	game.player_damage = 100.0
	game.player_pos = (game.WORLD_SIZE * 0.5 + Vector2(260.0, 110.0)).clamp(Vector2(220.0, 220.0), game.WORLD_SIZE - Vector2(220.0, 220.0))
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.bullets.clear()
	game.bombastica_bombs.clear()
	game.bombastica_vfx.clear()
	game.bombastica_explosion_pool.clear()
	game.bombastica_mine_pool.clear()
	game.bombastica_ignition_pool.clear()
	game.screen_shake_timer = 0.0
	game.screen_shake_strength = 0.0

	var q_center: Vector2 = game.player_pos + Vector2(190.0, 50.0)
	var mine_center: Vector2 = game.player_pos + Vector2(-180.0, 70.0)
	var ignition_center: Vector2 = game.player_pos + Vector2(20.0, -120.0)
	var ultimate_center: Vector2 = game.player_pos + Vector2(110.0, -35.0)

	game._spawn_bombastica_explosion_vfx(q_center, game.BOMBASTICA_Q_RADIUS, "bombastic_q_explosion")
	game._spawn_bombastica_explosion_vfx(mine_center, game.BOMBASTICA_E_MINE_RADIUS, "bombastic_field_mine")
	game._spawn_bombastica_explosion_vfx(ignition_center, game.BOMBASTICA_IGNITION_RADIUS, "bombastic_powder_ignition")
	game.bombastica_ult_reverse_anchors = [ultimate_center, q_center]
	game._trigger_trail_segment_detonation(ultimate_center, 0)
	await process_frame

	var q_node := _find_vfx_node(game.bombastica_explosion_pool, q_center)
	var mine_node := _find_vfx_node(game.bombastica_mine_pool, mine_center)
	var ignition_node := _find_vfx_node(game.bombastica_ignition_pool, ignition_center)
	var ultimate_node := _find_vfx_node(game.bombastica_explosion_pool, ultimate_center)
	if q_node == null:
		_fail("Q explosion VFX node was not tagged with its world origin")
		return
	if mine_node == null:
		_fail("mine explosion VFX node was not tagged with its world origin")
		return
	if ignition_node == null:
		_fail("powder ignition VFX node was not tagged with its world origin")
		return
	if ultimate_node == null:
		_fail("ultimate detonation VFX node was not tagged with its world origin")
		return

	_check_canvas_alignment(q_node, q_center, "q")
	_check_canvas_alignment(mine_node, mine_center, "mine")
	_check_canvas_alignment(ignition_node, ignition_center, "ignition")
	_check_canvas_alignment(ultimate_node, ultimate_center, "ultimate")

	game.player_pos = (game.player_pos + Vector2(160.0, -60.0)).clamp(Vector2(220.0, 220.0), game.WORLD_SIZE - Vector2(220.0, 220.0))
	game._sync_bombastica_scene_vfx_positions()
	_check_canvas_alignment(q_node, q_center, "q_after_camera_move")
	_check_canvas_alignment(ultimate_node, ultimate_center, "ultimate_after_camera_move")

	game.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() == "headless":
		print("BOMBASTICA_VFX_ORIGIN_VISUAL_OK logic_only=true screenshot_skipped=headless")
		_cleanup()
		quit(0)
		return
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		print("BOMBASTICA_VFX_ORIGIN_VISUAL_OK logic_only=true screenshot_skipped=no_viewport")
		_cleanup()
		quit(0)
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		print("BOMBASTICA_VFX_ORIGIN_VISUAL_OK logic_only=true screenshot_skipped=empty_viewport")
		_cleanup()
		quit(0)
		return
	var path := ProjectSettings.globalize_path(SCREENSHOT_PATH)
	if image.save_png(path) != OK:
		_fail("could not save screenshot")
		return
	print("BOMBASTICA_VFX_ORIGIN_VISUAL_OK " + path)
	_cleanup()
	quit(0)


func _find_vfx_node(pool: Array, world_pos: Vector2) -> Node2D:
	for node in pool:
		if not is_instance_valid(node) or not node.has_meta("bombastica_world_origin"):
			continue
		if Vector2(node.get_meta("bombastica_world_origin")).distance_to(world_pos) <= 0.5:
			return node
	return null


func _check_canvas_alignment(node: Node2D, world_pos: Vector2, label: String) -> void:
	var expected: Vector2 = game._bombastica_vfx_canvas_pos(world_pos)
	if node.global_position.distance_to(expected) > 0.75:
		_fail("%s VFX at %s, expected %s" % [label, str(node.global_position), str(expected)])


func _cleanup() -> void:
	if game == null:
		return
	game._cleanup_runtime_resources()
	game.textures.clear()
	game.audio_streams.clear()
	if game.get_parent() == root:
		root.remove_child(game)
	game.free()
