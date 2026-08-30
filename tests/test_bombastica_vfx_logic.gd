extends SceneTree

var holder: Node2D = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("--- TEST BOMBASTICA VFX LOGIC START ---")
	holder = Node2D.new()
	holder.name = "RootVFXTest"
	root.add_child(holder)
	
	var explosion_scene = load("res://vfx/bombastica/BombasticaExplosionVFX.tscn")
	var mine_scene = load("res://vfx/bombastica/BombasticaMineExplosionVFX.tscn")
	var ignition_scene = load("res://vfx/bombastica/BombasticaIgnitionVFX.tscn")
	
	assert(explosion_scene != null, "Explosion scene must load")
	assert(mine_scene != null, "Mine scene must load")
	assert(ignition_scene != null, "Ignition scene must load")
	
	# Test Q Explosion Instance
	var exp_inst = explosion_scene.instantiate()
	holder.add_child(exp_inst)
	await process_frame
	exp_inst.play_at(Vector2(200, 200), 1.2, "HIGH", 2, 12345, false, false)
	assert(exp_inst.visible == true, "Explosion VFX should be visible")
	assert(exp_inst.position == Vector2(200, 200), "Explosion VFX must keep local world position")
	
	# Test Mine Explosion Instance
	var mine_inst = mine_scene.instantiate()
	holder.add_child(mine_inst)
	await process_frame
	mine_inst.play_at(Vector2(400, 200), "HIGH", 54321)
	assert(mine_inst.visible == true, "Mine VFX should be visible")
	assert(mine_inst.position == Vector2(400, 200), "Mine VFX must keep local world position")
	
	# Test Ignition Instance
	var igni_inst = ignition_scene.instantiate()
	holder.add_child(igni_inst)
	await process_frame
	igni_inst.play_at(Vector2(600, 200), "HIGH")
	assert(igni_inst.visible == true, "Ignition VFX should be visible")
	assert(igni_inst.position == Vector2(600, 200), "Ignition VFX must keep local world position")
	
	# Test Quality degradation (LOW quality)
	var exp_low = explosion_scene.instantiate()
	holder.add_child(exp_low)
	await process_frame
	exp_low.play_at(Vector2(200, 400), 1.0, "LOW", 0, 9999, true, true)
	assert(exp_low.position == Vector2(200, 400), "Low quality VFX must keep local world position")
	
	print("--- TEST BOMBASTICA VFX LOGIC SUCCESSFUL ---")
	root.remove_child(holder)
	holder.free()
	quit(0)
