extends RefCounted

# Host-owned state and compatibility wrappers are retained during extraction.


static func _spawn_bombastica_explosion_vfx(game: Node2D, center: Vector2, radius: float, source: String) -> void :
	var chain_depth: = 1 if source == "bombastic_chain_explosion" else 0
	var seed_val: int = game.rng.randi()
	var world_root: Node2D = game._ensure_bombastica_world_vfx_root()
	
	# Register shockwave for physical collision visual wave
	game.shockwaves.append({"pos": center, "radius": 12.0, "max": radius * 1.1, "life": 0.32, "damage": 0.0, "hit": {}, "visual_only": true, "kind": "bombastica"})
	
	# Determine Graphic Quality Profile
	var quality: String = "HIGH"
	if game._memory_saver_active() or game.gfx_low_resource:
		quality = "LOW"
	elif not game.gfx_particles:
		quality = "MEDIUM"
		
	var scale_mult: float = radius / game.BOMBASTICA_Q_RADIUS
	
	# Dispatch to specialized 2D Engine VFX Scenes
	if source == "bombastic_field_mine":
		var inst: Node2D = null
		for node in game.bombastica_mine_pool:
			if is_instance_valid(node) and not node.visible:
				inst = node
				break
		if not inst and game.bombastica_mine_vfx_scene:
			inst = game.bombastica_mine_vfx_scene.instantiate()
			world_root.add_child(inst)
			game.bombastica_mine_pool.append(inst)
		if inst and inst.has_method("play_at"):
			game._prepare_bombastica_scene_vfx(inst, center)
			inst.play_at(center, quality, seed_val)
	elif source == "bombastic_powder_ignition":
		var inst: Node2D = null
		for node in game.bombastica_ignition_pool:
			if is_instance_valid(node) and not node.visible:
				inst = node
				break
		if not inst and game.bombastica_ignition_vfx_scene:
			inst = game.bombastica_ignition_vfx_scene.instantiate()
			world_root.add_child(inst)
			game.bombastica_ignition_pool.append(inst)
		if inst and inst.has_method("play_at"):
			game._prepare_bombastica_scene_vfx(inst, center)
			inst.play_at(center, quality)
	else:
		# Main Bombástica Q Explosion / Chain Reaction Explosion
		var inst: Node2D = null
		for node in game.bombastica_explosion_pool:
			if is_instance_valid(node) and not node.visible:
				inst = node
				break
		if not inst and game.bombastica_explosion_vfx_scene:
			inst = game.bombastica_explosion_vfx_scene.instantiate()
			world_root.add_child(inst)
			game.bombastica_explosion_pool.append(inst)
		if inst and inst.has_method("play_at"):
			game._prepare_bombastica_scene_vfx(inst, center)
			var red_flashes: bool = (game.get("gfx_reduced_flashes") == true)
			var red_motion: bool = not game.gfx_screen_shake
			inst.play_at(center, scale_mult, quality, chain_depth, seed_val, red_flashes, red_motion)
			
	var life: = 0.58 if chain_depth > 0 else 0.52
	game.bombastica_vfx.append({"kind": "explosion", "pos": center, "radius": radius, "life": life, "max": life, "source": source, "chain_depth": chain_depth, "seed": seed_val})
	if game.bombastica_use_old_vfx:
		game._spawn_radial_particles(center, Color(1.0, 0.5, 0.1), 26 if chain_depth == 0 else 32)


static func _ensure_bombastica_world_vfx_root(game: Node2D) -> Node2D:
	if is_instance_valid(game.bombastica_world_vfx_root):
		game._sync_bombastica_scene_vfx_positions()
		return game.bombastica_world_vfx_root
	game.bombastica_world_vfx_root = Node2D.new()
	game.bombastica_world_vfx_root.name = "BombasticaWorldVFX"
	game.bombastica_world_vfx_root.z_as_relative = false
	game.bombastica_world_vfx_root.z_index = 18
	game.add_child(game.bombastica_world_vfx_root)
	game._sync_bombastica_scene_vfx_positions()
	return game.bombastica_world_vfx_root


static func _prepare_bombastica_scene_vfx(game: Node2D, inst: Node2D, world_origin: Vector2) -> void:
	var world_root: Node2D = game._ensure_bombastica_world_vfx_root()
	if inst.get_parent() != world_root:
		if inst.get_parent() != null:
			inst.get_parent().remove_child(inst)
		world_root.add_child(inst)
	inst.position = world_origin
	inst.rotation = 0.0
	inst.scale = Vector2.ONE
	inst.set_meta("bombastica_world_origin", world_origin)
	inst.set_meta("bombastica_origin_space", "world")


static func _bombastica_vfx_camera(game: Node2D) -> Vector2:
	return game._camera(game.get_viewport_rect().size) + game._screen_shake_offset()


static func _bombastica_vfx_canvas_pos(game: Node2D, world_pos: Vector2) -> Vector2:
	return world_pos - game._bombastica_vfx_camera()


static func _sync_bombastica_scene_vfx_positions(game: Node2D) -> void:
	if not is_instance_valid(game.bombastica_world_vfx_root):
		return
	game.bombastica_world_vfx_root.position = -game._bombastica_vfx_camera()
	game.bombastica_world_vfx_root.rotation = 0.0
	game.bombastica_world_vfx_root.scale = Vector2.ONE
