extends SceneTree

func _init() -> void:
	print("--- TEST BOMBASTICA VFX LOGIC START ---")
	var root = Node2D.new()
	root.name = "RootVFXTest"
	
	var explosion_scene = load("res://vfx/bombastica/BombasticaExplosionVFX.tscn")
	var mine_scene = load("res://vfx/bombastica/BombasticaMineExplosionVFX.tscn")
	var ignition_scene = load("res://vfx/bombastica/BombasticaIgnitionVFX.tscn")
	
	assert(explosion_scene != null, "Explosion scene must load")
	assert(mine_scene != null, "Mine scene must load")
	assert(ignition_scene != null, "Ignition scene must load")
	
	# Test Q Explosion Instance
	var exp_inst = explosion_scene.instantiate()
	root.add_child(exp_inst)
	exp_inst.play_at(Vector2(200, 200), 1.2, "HIGH", 2, 12345, false, false)
	assert(exp_inst.visible == true, "Explosion VFX should be visible")
	
	# Test Mine Explosion Instance
	var mine_inst = mine_scene.instantiate()
	root.add_child(mine_inst)
	mine_inst.play_at(Vector2(400, 200), "HIGH", 54321)
	assert(mine_inst.visible == true, "Mine VFX should be visible")
	
	# Test Ignition Instance
	var igni_inst = ignition_scene.instantiate()
	root.add_child(igni_inst)
	igni_inst.play_at(Vector2(600, 200), "HIGH")
	assert(igni_inst.visible == true, "Ignition VFX should be visible")
	
	# Test Quality degradation (LOW quality)
	var exp_low = explosion_scene.instantiate()
	root.add_child(exp_low)
	exp_low.play_at(Vector2(200, 400), 1.0, "LOW", 0, 9999, true, true)
	
	print("--- TEST BOMBASTICA VFX LOGIC SUCCESSFUL ---")
	quit(0)
