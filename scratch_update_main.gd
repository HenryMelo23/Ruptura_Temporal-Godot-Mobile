extends SceneTree

func _init():
	var packed_scene = load("res://scenes/Main.tscn")
	var root = packed_scene.instantiate()
	
	var container = Node2D.new()
	container.name = "PlayersContainer"
	root.add_child(container)
	container.owner = root
	
	var spawner = MultiplayerSpawner.new()
	spawner.name = "MultiplayerSpawner"
	spawner.spawn_path = root.get_path_to(container)
	spawner.add_spawnable_scene("res://scenes/Player.tscn")
	root.add_child(spawner)
	spawner.owner = root
	
	var new_scene = PackedScene.new()
	new_scene.pack(root)
	ResourceSaver.save(new_scene, "res://scenes/Main.tscn")
	
	print("Main.tscn updated successfully.")
	quit()
